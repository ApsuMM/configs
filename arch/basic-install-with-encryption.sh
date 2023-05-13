#!/usr/bin/zsh

HOSTNAME="workstation"
PASSWD="P@ssw0rd"

loadkeys de-latin1
DISK=$(lsblk -ln | awk '$6=="disk" { print $1; exit}')
[[ -z "$DISK" ]] && { echo "Error: No disk found"; exit 1; }

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

cryptsetup -y -v luksFormat $PDATA
cryptsetup open $PDATA root
mkfs.ext4 /dev/mapper/root

mkfs.fat -F 32 $PBOOT
mkswap $PSWAP

mount /dev/mapper/root /mnt
mount --mkdir $PBOOT /mnt/boot
swapon $PSWAP

pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base linux linux-firmware vim tldr man-db man-pages
genfstab -U /mnt >> /mnt/etc/fstab

$OLDHOOKS=$(grep '^HOOKS' /mnt/etc/mkinitcpio.conf)
$NEWHOOKS=$(echo $OLDHOOKS | sed 's/.$//' | echo "$(cat-) encrypt)")
sed -i 's/^HOOKS\=.*/$NEWHOOKS/' /mnt/etc/mkinitcpio.conf

arch-chroot /mnt /bin/bash<<END
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
mandb

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
echo $HOSTNAME >> /etc/hostname

echo "root:$PASSWD" | chpasswd
bootctl install
mkinitcpio -P

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
cryptdevice=UUID=$PDATA:root root=/dev/mapper/root
options root=$PDATA rw
EOF
END
reboot



