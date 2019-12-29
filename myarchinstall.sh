#!/bin/sh

# # Load keys
# echo Load keys
# loadkeys be-latin1

# # set timedate
# echo set timedate
# timedatectl set-ntp true

# check if uefi boot
echo Check if uefi boot
checkefi=$(ls /sys/firmware/efi/efivars/ | wc -l)

#check connection
checkping=$(ping )
if ! ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1;then
    echo No internet Connection
    exit
fi

grubPartitionTable () {
    swapsize=$(grep MemTotal /proc/meminfo | awk '{print int($2/1000000+0.5)*1.5}' | bc)G

    echo "label: gpt
unit: sectors

/dev/sda1 : size=       +250M,   type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name=\"boot\"
/dev/sda2 : size= +$swapsize,   type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, name=\"swap\"
/dev/sda3 : size=        +25G,   type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709, name=\"root\"
/dev/sda4 : type=33AC7E1-2EB4-4F13-B844-0E14E2AEF915, name=\"home\"" > part_table
    sfdisk /dev/sda < part_table
    rm part_table
}

makeFileSystem () {
    echo making filesystem
    mkfs.ext4 /dev/sda1
    mkfs.ext4 /dev/sda3
    mkfs.ext4 /dev/sda4
    echo making swappartition
    mkswap /dev/sda2
    swapon /dev/sda2
}

mountTemp () {
    mount /dev/sda3 /mnt
    mount /dev/sda1 /mnt/boot
    mount /dev/sda4 /mnt/home
}

installArch () {
    echo Installing arch linux and packages
    # TODO: Set up the complete list
    pacstrap /mnt base base-devel vim emacs networkmanager grub
}

generateFSTab () {
    genfstab -U /mnt > /mnt/etc/fstab
}

changeRoot () {
    arch-chroot /mnt
}

systemctlConfig () {
    systemctl enable NetworkManager
}

installGrub () {
    echo Installing Grub
    grub-install --target=i386-pc /dev/sda
    echo creating config file
    grub-mkconfig -o /boot/grub/grub.cfg
}

setupPassAndUser () {
    echo Create Root Password
    passwd
}

setupLocalandTimeZone () {
    echo Setup local
    sed -i 's/#\(\(fr_BE\|en_US\).*\)/\1/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo Setup Timezone
    ln -sf /user/share/zoneinfo/Europe/Brussels /etc/localtime
}

setupHostname () {
    echo Choose hostname:
    read hostname
    echo $hostname > /etc/hostname
}

# ------------

createuser () {
    echo Add sam user
    useradd -m -g wheel sam
    echo Editting sudoers TODO
}

installWM () {
    #TODO
    pacman -S i3-gaps
    pacman -S xorg-server xorg-xinit
}


installdotfiles () {
    #TODO
    git clone mydotfiles
}

installFonts () {
    pacman -S ttf-linux-libertine ttf-inconsolata
}

if [ $checkefi = 0 ];then
    #grub boot loader
    grubPartitionTable
    makeFileSystem
    installArch
    generate
else
    #TODO
    echo efi install not configured yet
    exit
fi
# create partition table with sfdisk
