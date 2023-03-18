#!/usr/bin/zsh

HOSTNAME="workstation"
PASSWD="P@ssw0rd"

loadkeys de-latin1
DISK=$(lsblk -ln | awk '$6=="disk" { print $1}') | head -n 1
DEV="/dev/${DISK}"

(
echo g
echo n
echo
echo
echo +512M
echo t
echo
echo 1
echo n
echo
echo
echo +1G
echo t
echo
echo 19
echo n
echo
echo
echo
echo w
) | fdisk $DEV

PBOOT="${DEV}1"
PSWAP="${DEV}2"
PDATA="${DEV}3"

mkfs.fat -F 32 $PBOOT
mkswap $PSWAP
mkfs.ext4 $PDATA

mount $PDATA /mnt
mount --mkdir $PBOOT /mnt/boot
swapon $PSWAP

pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base linux linux-firmware vim tldr man-db man-pages
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash<<END
mkdir -p /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
echo $HOSTNAME >> /etc/hostname

echo "root:$PASSWD" | chpasswd
bootctl install

cat <<EOF >> /boot/loader/loader.conf
default  arch.conf
timeout  4
console-mode max
editor   no
EOF

cat <<EOF >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=$PDATA rw
EOF
END
reboot



