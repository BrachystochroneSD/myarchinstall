#!/bin/sh

# location of this file : https://raw.githubusercontent.com/BrachystochroneSD/myarchinstall/master/myarchinstall.sh

# TODO LIST
#create option to launch install efore and after arch-chroot
# set up dotfile with git init and git pull
# locale-gen
# efi boot (optional)
# create ssh and upload it to github with api.
# setup default wallpaper
# Nextcloud link
# emacs dotfiles

makingGRUBGPTPartitionTable () {
    swapsize=$(grep MemTotal /proc/meminfo | awk '{print int($2/1000000+0.5)*1.5}' | bc)G

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
    pacstrap /mnt base base-devel linux linux-firmware i3-gaps git xorg-xinit xorg-server emacs python python-gobject man firefox w3m ncmpcpp mpd mpv mpd dunst unzip bc openssh xclip imagemagick feh fzf python-pip vim emacs networkmanager grub picom fzf
}

generateFSTab () {
    genfstab -U /mnt > /mnt/etc/fstab
}

setupLocalandTimeZone () {
    echo Setup local
    sed -i 's/#\(\(fr_BE\|en_US\).*\)/\1/' /mnt/etc/locale.gen
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

pipinstall () {
	sudo pip install $1
}

allpipinstalls () {
	pipinstall wpgtk
}

installGrub () {
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
    sed -i 's/# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers
    chsh -s /bin/zsh sam
}

# Install Function GIT PIP and AUR

installGIT () {
    lastdir="$PWD"
    repo="$1"
    [[ -z "$2" ]] && dir="$2" || dir="${HOME}/.config"
    [[ -z "$3" ]] && user="$3" || user="BrachystochroneSD"

    cd "$dir"
    git clone --depth 1 "git@github.com:$user/$repo.git"
    cd "$repo"
    make
    sudo make install
    cd "$lastdir"
}

installPIP () {
    echo Installing "$1"...
    sudo pip install "$1"
}

installAUR () {
    lastdir="$PWD"
    aurdir="${HOME}/aur_install_dir"
    [[ ! -d "$aurdir" ]] && mkdir "$aurdirflkdj"
    echo "Installing $1 in $aurdir"...
    cd "$aurdir"
    git clone "https://aur.archlinux.org/$1.git"
    cd "$1"
    makepkg -si
    cd "$lastdir"
}

installdotfiles () {
    dotgitdir="${HOME}/.dotfiles"
    mkdir "$dotgitdir"
    cd "$dotgitdir"
    /bin/git init --bare
    /bin/git remote add "git@github.com:BrachystochroneSD/dotfiles.git" # possible problem : ssh key
    cd "${HOME}"
    /bin/git --git-dir="$dotgitdir" --work-tree="${HOME}" pull origin master
}

installfromAUR () {
    mkdir ${HOME}/AURinstall && cd ${HOME}/AURinstall
    installAUR polybar
    installAUR cava
    installAUR networkmanager-dmenu-git
    rm -rf ${HOME}/AURinstall
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

case $1 in
    --first)
        makingGRUBGPTPartitionTable
        installArch
        generateFSTab
        setupLocalandTimeZone
        setupHostname
        changeRoot
        ;;
    --tworst)
        # To be launched avfter the arch-chroot, in root
        clock
        installGrub
        systemctlConfig
        setupPassAndUser
        CreateUser
        ;;
    --thirst)
       # to be launched with the user name
        ;;
    *)
        printf "Need options \n    --first\n     --tworst\n     --thirst\n"
esac
