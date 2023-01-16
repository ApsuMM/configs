#!/bin/sh

loadkeys de-latin1

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
) | fdisk /dev/sda

mkfs.fat -F 32 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

mount /dev/sda3 /mnt
mount --mkdir /dev/sda1 /mnt/boot
swapon /dev/sda2

pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base linux linux-firmware vim tldr man-db man-pages
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash<<END
mkdir -p /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

locale-gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
echo "workstation" >> /etc/hostname

echo "root:P@ssw0rd" | chpasswd
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
options root="/dev/sda3" rw
EOF
END
reboot



