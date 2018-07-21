
# Buildroot config for AWS EC2

This is a basic [Buildroot](https://buildroot.org/) "board" config for
Amazon EC2, with ssh. 

The Linux kernel config comes from NixOS Linux 4.14.32 AWS.

Check out this repo on an EC2 build server. I used Ubuntu 18.04, t2.xlarge
instance. The build generates a lot of files, so I added a 100GB gp2 disk,
mounted under my home directory. Add a volume to your build server, I used
a 1GB gp2 volume, mounted under `/dev/sdf`.

## Install build deps

```shell
sudo apt install sed make binutils gcc g++ bash patch gzip bzip2 perl tar cpio python unzip rsync wget libncurses-dev libelf-dev
```

## Download this external tree

```shell
git clone buildroot_ec2
```

# Allow your user to log in via ssh

```shell
cp ~/.ssh/authorized_keys buildroot_ec2/board/ec2/rootfs_overlay/root/.ssh/
```

## Download buildroot

```shell
wget https://buildroot.org/downloads/buildroot-2018.05.tar.bz2
mkdir work
cd work
bzip -dc buildroot-2018.05.tar.bz2 | tar xvf -
ln -s buildroot-2018.05 buildroot
```

## Build

```shell
cd buildroot
make BR2_EXTERNAL=../buildroot_ec2 ec2_defconfig
```

    make list-defconfigs

## Write disk image to mounted volume

```shell
sudo dd if=output/images/disk.img of=/dev/xvdf
```

## Launch an EC2 instance

The `board/ec2/launch-instance-from-volume.sh` launches an instance
by making a snapshot of the volume, turning the snapshot into an AMI,
then launching it. I normally run it from my local machine, not the build
instance. 

Set up an AWS profile in `~/.aws/credentials`

    [cogini-dev]
    aws_access_key_id = XXX
    aws_secret_access_key = YYY

Edit the script to match your environment:

    SECURITY_GROUP=sg-94bafcec
    NAME=buildroot
    TAG_OWNER=jake
    KEYPAIR=cogini-jake

Run it, specifying your volume:

```shell
AWS_PROFILE=cogini-dev ./launch-instance-from-volume.sh vol-abc123
```

## Docs

https://buildroot.org/downloads/manual/manual.html
https://bootlin.com/doc/training/buildroot/buildroot-labs.pdf
http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Buildroot.html
https://dzone.com/articles/building-embedded-linux-with-buildroot

## Useful commands

Configure buildroot:

    make menuconfig

Save buildroot config to `buildroot_ec2/configs/ec2_defconfig`:

    make savedefconfig

Use a different kernel config:

    cp ~/nixos-4.14.32.config output/build/linux-4.16.13/.config

Configure Linux kernel

    make linux-menuconfig

Save to `.config`, then save the kernel config back to `buildroot_ec2/board/ec2/linux.config`:

    make linux-savedefconfig

## Qemu

    sudo apt install qemu

    qemu-system-x86_64 -nographic -M pc -kernel output/images/bzImage -drive file=output/images/rootfs.ext2,if=virtio,format=raw -append "root=/dev/vda console=ttyS0" -net nic,model=virtio -net user


    qemu-system-x86_64 -curses -M pc -m 128 -drive file=output/images/disk.img,if=virtio,format=raw
    qemu-system-x86_64 -curses -M pc -m 128 -drive file=output/images/disk.img,format=raw -net nic -net user
    qemu-system-x86_64 -nographic -serial mon:stdio -M pc -m 128 -drive file=output/images/disk.img,if=virtio,format=raw

    Linux config for qemu: `board/qemu/x86_64/linux-4.15.config`

Set root password:

Enable password under "System configuration | Enable root login with password".
Set password under "System configuration | Root password"

## systemd-nspawn

    sudo apt install systemd-container
    sudo systemd-nspawn -b -i output/images/rootfs.ext2 -n

Doesn't work, because kernel in image is newer than host

Look at partitions in image:

    sudo losetup -v -f --show `pwd`/output/images/disk.img
    sudo fdisk /dev/loop2

## Notes

### Configs

    configs/pc_x86_64_bios_defconfig
    output/build/linux-4.16.13/arch/x86/configs/x86_64_defconfig
    output/build/linux-4.16.13/arch/x86/configs/xen.config

### Grub

Current config comes from `board/pc`

https://github.com/buildroot/buildroot/tree/master/boot/grub2
https://www.systutorials.com/docs/linux/man/8-grub-bios-setup/
https://git.busybox.net/buildroot/tree/boot/grub2/Config.in#n69

Most of the space is in linux kernel modules that we probably don't need.
Reduce config.
