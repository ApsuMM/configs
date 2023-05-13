#!/usr/bin/zsh

HOSTNAME="workstation"
PASSWD="P@ssw0rd"

loadkeys de-latin1
DISK=$(lsblk -ln | awk '$6=="disk" { print $1; exit}')
[[ -z "$DISK" ]] && { echo "Error: No disk found"; exit 1; }

DEV="/dev/${DISK}"
shred -v -n1 $DEV

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

echo $PASSWD | cryptsetup -y -v -q luksFormat $PDATA
echo $PASSWD | cryptsetup open $PDATA root
UUID=$(blkid -s UUID -o value $PDATA)

mkfs.ext4 /dev/mapper/root

mkfs.fat -F 32 $PBOOT
mkswap $PSWAP

mount /dev/mapper/root /mnt
mount --mkdir $PBOOT /mnt/boot
swapon $PSWAP

pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base linux linux-firmware vim tldr man-db man-pages
genfstab -U /mnt >> /mnt/etc/fstab

# OLDHOOKS=$(grep '^HOOKS' /mnt/etc/mkinitcpio.conf)
# NEWHOOKS=$(echo $OLDHOOKS | sed 's/.$//' | echo "$(cat -) encrypt)")
# sed -i "s/^HOOKS\=.*/$NEWHOOKS/" /mnt/etc/mkinitcpio.conf

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
sed -i "s/^HOOKS\=.*/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)/" /etc/mkinitcpio.conf
mkinitcpio -p linux

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
options cryptdevice=UUID=$UUID:root root=/dev/mapper/root rw
EOF
END
umount -R /mnt
reboot



