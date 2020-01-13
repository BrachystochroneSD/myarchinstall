#!/bin/sh

# location of this file : https://raw.githubusercontent.com/BrachystochroneSD/myarchinstall/master/myarchinstall.sh

# TODO LIST
# ask for prompt shits first
# mpd server config
# create makefile for keepmenu
# efi boot
# add emacs.d colors.sh and offlineimaprc to the dotfiles
# polybar battery config tweaks
# check gtk options https://github.com/deviantfero/wpgtk/wiki/Installation

#########
# FIRST #
#########

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
    # TODO: Set up the complete list and sort it (it's a mess!)
    pacstrap /mnt base base-devel linux linux-firmware i3-gaps git xorg-xinit xorg-server emacs python python-gobject man firefox w3m ncmpcpp mpd mpv mpc dunst libnotify unzip bc openssh xclip imagemagick feh fzf python-pip vim emacs networkmanager grub picom fzf ttf-linux-libertine ttf-inconsolata redshift jq offlineimap davfs2 xdotool zsh # nextcloud-client
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
    printf "192.168.0.102 www.zenocyne.com\n192.168.0.102 nextcloud.zenocyne.com\n" >> /mnt/etc/hosts
}

changeRoot () {
    arch-chroot /mnt
}

##########
# TWORST #
##########

clockandlocale () {
    locale-gen
    hwclock --systohc
}

installGrub () {
    echo Installing Grub
    grub-install --target=i386-pc /dev/sda
    echo creating config file
    sed -i 's/\(GRUB_GFXMODE=\)/\1640x480,/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
}

systemctlConfig () {
    systemctl enable NetworkManager
}

setupPassAndUser () {
    echo Create Root Password
    passwd
    chsh -s /bin/zsh
}

createUser () {
    echo Add sam user
    useradd -m -g wheel sam
    echo Editting sudoers TODO
    sed -i 's/# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers
    chsh -s /bin/zsh sam
    passwd sam
}

createssh () {
    ssh-keygen -f "${HOME}/.ssh/id_rsa" -N ""
    sshkey=$(cat "${HOME}/.ssh/id_rsa.pub")
    title=$(whoami)@$(cat /etc/hostname)
    token=$(awk '($1=="sshadmin"){print $2}' "${HOME}/.authentification/tokengit" )
    json=$(printf '{"title": "%s", "key": "%s"}' "$title" "$sshkey" )
    curl -d "$json" -H "Authorization: token $token" https://api.github.com/user/keys
}

# Install Function GIT PIP and AUR

installGIT () {
    lastdir="$PWD"
    repo="$1"
    [[ -n "$2" ]] && dir="$2" || dir="${HOME}/.config"
    [[ -n "$3" ]] && user="$3" || user="BrachystochroneSD"

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
    mkdir -p "$aurdir"
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
    /bin/git remote add "git@github.com:BrachystochroneSD/dotfiles.git"
    cd "${HOME}"
    /bin/git --git-dir="$dotgitdir" --work-tree="${HOME}" pull origin master
}

installNC () {
    zenomount="${HOME}/zenocloud"
    zenodir="$1"
    installdir="$2"
    echo Installing $zenomount/$zenodir in $installdir
    mkdir -p "$zenomount"
    mkdir -p "$installdir"
    if ! grep -qs "$zenomount " "/proc/mounts";then
        sudo mount -t davfs https://nextcloud.zenocyne.com/remote.php/webdav/ "$zenomount" || exit
    else
	echo $zenomount already mounted
    fi
    [[ ! -d "$zenomount/$zenodir" ]] && exit

    echo copy
    sudo cp -rv "$zenomount"/"$zenodir"/* "$installdir"/
}

# MAIN SHIT
case $1 in
    --first) # to be launched first (duh)
        timedatectl set-ntp true
        makingGRUBGPTPartitionTable
        installArch
        generateFSTab
        setupLocalandTimeZone
        setupHostname
        #copy the script in home
        cp myarchinstall.sh /mnt/home
        changeRoot
        ;;
    --tworst) # To be launched after the arch-chroot, in root
        clockandlocale
        installGrub
        systemctlConfig
        setupPassAndUser
        createUser
        # move the script in home of sam
        mv /home/myarchinstall.sh /home/sam/
        ;;
    --thirst) # to be launched with the user name
        installNC "authentificationfiles" "${HOME}/.authentification"
        installNC "keepassDBs" "${HOME}/.keepassdb"
        installNC "Images/wallpapers" "${HOME}/Images/wallpapers"
	umount ${HOME}/zenocloud
        createssh
        #install dotfiles first
        installdotfiles
        # install from AUR
        installAUR polybar
        installAUR cava
	installAUR xwinwrap-git
        installAUR networkmanager-dmenu-git
        installAUR ttf-monofur
        installAUR mu
	installAUR keepmenu
        rm -rf ${HOME}/AURinstall
        # Install from pip
        installPIP wpgtk
        # Install from my git
        installGIT st
        installGIT dmenu
        # install from NC
        wpg -m
        echo Everything works!!! Hooray!!!
        reboot
        ;;
    *)
        printf "Need options\n     --first\n     --tworst\n     --thirst\n"
esac
