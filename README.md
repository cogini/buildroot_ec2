# Buildroot config for AWS EC2

This is an example of using the [Buildroot](https://buildroot.org/) embedded
Linux build system to create a custom AMI for Amazon.

It is a basic Buildroot "board" config, with ssh and a few utilities.

The Linux kernel config comes from NixOS Linux 4.14.32 AWS.

The general approach is to build on an EC2 instance and create an
image on an EBS volume, then create a snapshot of the volume and turn it into an AMI.

Check out this repo on an EC2 build server. I used a t2.xlarge instance running
Ubuntu 18.04. The build generates a lot of files, so I added a 100GB gp2 EBS
volume, mounted under my home directory.

I used a 1GB gp2 volume for the target system, mounted under `/dev/sdf`.

## Install build deps

```shell
sudo apt install sed make binutils gcc g++ bash patch gzip bzip2 perl tar cpio python unzip rsync wget libncurses-dev libelf-dev
```

## Check out this repo

```shell
git clone https://github.com/cogini/buildroot_ec2
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
bzip2 -dc buildroot-2018.05.tar.bz2 | tar xvf -
ln -s buildroot-2018.05 buildroot
```

## Build

```shell
cd buildroot
make BR2_EXTERNAL=../buildroot_ec2 ec2_defconfig
```

This will take a while, so you may want to run it under tmux.

## Write disk image to mounted volume

```shell
sudo dd if=output/images/disk.img of=/dev/xvdf
```

## Configure AWS

At this point, the new system is all set up on the EBS volume.
Now we need to launch an instance from it. We do that using the AWS API, so
it can run from anywhere. I normally run it from my dev machine, but you
can do it from the build server as well.

In order to talk to the API, we need permissions. When you create an AWS
account, you get a "root" account with full permissions, but you should
not use it for for everyday operations. You should create an admin user
for yourself and a role for your app to run under which gives it access
to specific resources.

Go to [IAM](https://console.aws.amazon.com/iam/home) in the AWS console.

Create a group called `Admins` and attach policy `AdministratorAccess`, giving members full access.

Create a user for yourself, e.g. `cogini-jake`. Under "Access type," check
"Programmatic access" and "AWS Management Console access." Set your login password.
Click "Next: Permissions" and then "Add user to group", selecting the `Admins` group.
Record the "Access key id" and "Secret access key" now, this is your only chance.

On your local dev machine, set up an AWS profile in `~/.aws/credentials` with the keys:

    [buildroot-dev]
    aws_access_key_id = XXX
    aws_secret_access_key = YYY

Most AWS client tools will automatically look up the access keys using the profile,
so you can control keys on a per-project basis by setting the profile in the environment.

```shell
export AWS_PROFILE=buildroot-dev
```

Install the [AWS Command Line Interface](https://aws.amazon.com/cli/):

```shell
pip install awscli
```

Create an ssh [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).
Run `create-key-pair.sh`

```shell
board/ec2/create-key-pair.sh buildroot
```

Copy the output to `~/.ssh/buildroot.pem` and `chmod 0600 buildroot.pem`.

Create an AWS security group (like a firewall) which allows access to the ports on the instance from the Internet.
`create-security-group.sh`
opens port 22 for the IEx console and port 80 for HTTP.

```shell
board/ec2/create-security-group.sh buildroot
```

## Launch the instance

`launch-instance-from-volume.sh` takes a snapshot of the volume, builds an AMI,
then launches an EC2 instance with it.

Edit the script to match your details:

```shell
# Name of security group
SECURITY_GROUP=buildroot
# Name of instance to create
NAME=buildroot
KEYPAIR=buildroot
# Tag instance with owner so admins can clean up stray instances
TAG_OWNER=jake
```

Run the script, specifying your volume:

```shell
board/ec2/launch-instance-from-volume.sh vol-abc123
```

The script will print the IP of the new instance, or you can get it from the AWS console.

## Launch an EC2 instance

The `board/ec2/launch-instance-from-volume.sh` script launches an instance
by making a snapshot of the volume, turning the snapshot into an AMI,
then starting it. I normally run it from my local machine, not the build
instance.

Edit the script to match your environment:

    SECURITY_GROUP=buildroot
    NAME=buildroot
    TAG_OWNER=jake
    KEYPAIR=buildroot

Run it, specifying your volume:

```shell
board/ec2/launch-instance-from-volume.sh vol-abc123
```

## Docs

* https://buildroot.org/downloads/manual/manual.html
* https://bootlin.com/doc/training/buildroot/buildroot-labs.pdf
* http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Buildroot.html
* https://dzone.com/articles/building-embedded-linux-with-buildroot

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

See the available buildroot configs

```shell
make list-defconfigs
```

## Qemu

Install
```shell
sudo apt install qemu
```

Run with text UI
```shell
qemu-system-x86_64 -nographic -serial mon:stdio -M pc -m 128 -drive file=output/images/disk.img,if=virtio,format=raw -net nic,model=virtio -net user,hostfwd=tcp::10022-:22
```
To quit: CTRL-A, x

Run with curses UI
```shell
qemu-system-x86_64 -curses -M pc -m 128 -drive file=output/images/disk.img,if=virtio,format=raw -net nic,model=virtio -net user,hostfwd=tcp::10022-:22
```
To quit: ESC-2, quit

Run without grub bootloader

```shell
qemu-system-x86_64 -nographic -M pc -kernel output/images/bzImage -drive file=output/images/rootfs.ext2,if=virtio,format=raw -append "root=/dev/vda console=ttyS0" -net nic,model=virtio -net user
```

Connect via ssh
```shell
ssh -p10022 root@localhost
```
Connect to build server using `ssh -A build-server` to use your workstation's keys.

Enable password under "System configuration | Enable root login with password".
Set password under "System configuration | Root password"

Linux config for qemu: `board/qemu/x86_64/linux-4.15.config`

## systemd-nspawn

```shell
sudo apt install systemd-container
sudo systemd-nspawn -b -i output/images/rootfs.ext2 -n
```

Doesn't work unless kernel in image matches host

View partitions in image

```
sudo losetup -v -f --show `pwd`/output/images/disk.img
sudo fdisk /dev/loop2
```

## Notes

### Configs

Buildroot
    Started with `board/pc`
    configs/pc_x86_64_bios_defconfig

    output/build/linux-4.16.13/arch/x86/configs/x86_64_defconfig
    output/build/linux-4.16.13/arch/x86/configs/xen.config
    board/qemu/x86_64/linux-4.15.config

### Grub

* https://github.com/buildroot/buildroot/tree/master/boot/grub2
* https://www.systutorials.com/docs/linux/man/8-grub-bios-setup/
* https://git.busybox.net/buildroot/tree/boot/grub2/Config.in#n69

Most of the space is in linux kernel modules that we probably don't need.
Reduce config.
