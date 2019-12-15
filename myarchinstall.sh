#!/bin/sh

# location of this file : https://raw.githubusercontent.com/BrachystochroneSD/myarchinstall/master/myarchinstall.sh

makingGRUBGPTPartitionTable () {
    swapsize=$(grep MemTotal /proc/meminfo | awk '{print int($2/1000000+0.5)*1.5}' | bc)G

    # check if uefi boot TODO when useful
    # echo Check Boot system
    # checkefi=$(ls /sys/firmware/efi/efivars/ | wc -l)

    # if [ $checkefi = 0 ];then
    #     boottype="21686148-6449-6E6F-744E-656564454649"
    # else
    #     boottype="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
    # fi

    echo "label: gpt
unit: sectors

/dev/sda1 : size= +2M,        type=21686148-6449-6E6F-744E-656564454649
/dev/sda2 : size= +$swapsize, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
/dev/sda3 : size= +25G,       type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709, attrs=\"LegacyBIOSBootable\"
/dev/sda4 : type=933AC7E1-2EB4-4F13-B844-0E14E2AEF915" > part_table
    sfdisk /dev/sda < part_table
    rm part_table

    echo making filesystem
    mkfs.ext4 /dev/sda3
    mkfs.ext4 /dev/sda4

    echo making swappartition
    mkswap /dev/sda2
    swapon /dev/sda2

    mount /dev/sda3 /mnt

    mkdir /mnt/home

    mount /dev/sda4 /mnt/home
}

installArch () {
    echo Installing arch linux and packages
    # TODO: Set up the complete list
    pacstrap /mnt base base-devel linux linux-firmware # vim emacs networkmanager grub
}

generateFSTab () {
    genfstab -U /mnt > /mnt/etc/fstab
}

setupLocalandTimeZone () {
    echo Setup local
    sed -i 's/#\(\(fr_BE\|en_US\).*\)/\1/' /mnt/etc/locale.gen
    # locale-gen TODO need to be done in the root of the pc
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    echo Setup Timezone
    ln -sf /mnt/user/share/zoneinfo/Europe/Brussels /mnt/etc/localtime
    echo "KEYMAP=be-latin1" > /mnt/etc/vconsole.conf
}

setupHostname () {
    echo Choose hostname:
    read hostname
    echo $hostname > /mnt/etc/hostname
}

# ------------
# The rest Need to be done manually (for now)
changeRoot () {
    arch-chroot /mnt
}

clock () {
    hwclock --systohc
}

installGrub () {
    pacman -S grub
    # TODO : for now, need to be done inside the "mounted root"
    # Problem : Grub loop of the dead
    echo Installing Grub
    grub-install --target=i386-pc /dev/sda
    echo creating config file
    grub-mkconfig -o /boot/grub/grub.cfg
}

systemctlConfig () {
    systemctl enable NetworkManager
}

setupPassAndUser () {
    echo Create Root Password
    passwd
}

CreateUser () {
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

# MAIN SHIT

# set timedate
echo set timedate
timedatectl set-ntp true

#check connection
checkping=$(ping )
if ! ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1;then
    echo No internet Connection
    exit
fi

makingGRUBGPTPartitionTable
installArch
generateFSTab
setupLocalandTimeZone
setupHostname
changeRoot
# installGrub
# systemctlConfig
# setupPassAndUser
# CreateUser
