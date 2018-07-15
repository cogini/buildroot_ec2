
# Buildroot config for AWS EC2

This is a basic [Buildroot](https://buildroot.org/) "board" config for
Amazon EC2, with ssh. 

The Linux kernel config comes from NixOS, 4.14.32 AWS.

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

## Useful commands

Configure buildroot

    make menuconfig

Save buildroot config to buildroot_ec2/configs/ec2_defconfig

    make savedefconfig

Use a different kernel config:

    cp ~/nixos-4.14.32.config output/build/linux-4.16.13/.config

Configure Linux kernel

    make linux-menuconfig

Save to `.config`, then save the kernel config back to `buildroot_ec2/board/ec2/linux.config`:

    make linux-savedefconfig
