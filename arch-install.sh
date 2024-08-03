#!/bin/bash
set -euo pipefail

source variables.sh
source utils.sh

echo -e "=== Welcome to ${BCyan}Arch Installer${RESET} ==="

# Handle the input arguments
handle_options "$@"

# Connect to WiFi
if [ "$use_wifi" = true ]; then
    log "Connecting to $ssid using $interface..."
    log $(iwctl station $interface connect $ssid --passphrase $wifi_passphrase 2>&1)
fi

log "Updating clock..."
log $(timedatectl set-ntp true 2>&1)

make_partitions () {
    log "Partitioning disk $disk..."
    
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$disk
	 g # Erase disk and creates a GPT partition table
	 n # [EFI] Creates a new partition
	 1 # [EFI] Partition N1
	 # [EFI] Start at the beginning of disk
	 +$efi_size # [EFI] Defines the size of the partition
	 t # [EFI] Partition type
	 1 # [EFI] Set partition type as UEFI
	 n # [BOOT] Creates boot partition
	 2 # [BOOT] Partition N2
	 # [BOOT] Start at the end of partition N1
	 +$boot_size # [BOOT] Defines the size of the partition
	 t # [BOOT] Partition type
	 2 # [BOOT] Select partition 2
	 20 # [BOOT] Linux filesystem (ext4)
	 n # [LUKS] Create a new partition
	 3 # [LUKS] Partition N3
	 # [LUKS] Start at the end of partition N2
	 # [LUKS] Takes fullsize
	 t # [LUKS] Partition type
	 3 # [LUKS] Select partition 3
	 20 #[LUKS] Linux filesystem (ext4)
	 w # Finishes partition creation
EOF
    sleep 5s
    EFI_PARTITION=$(ls /dev/$disk* | sed '2q;d' | sed 's#^/dev/##g')
    BOOT_PARTITION=$(ls /dev/$disk* | sed '3q;d' | sed 's#^/dev/##g')
    ROOT_PARTITION=$(ls /dev/$disk* | sed '4q;d' | sed 's#^/dev/##g')
    
    log "Making EFI partition at /dev/$EFI_PARTITION"
    log $(echo "y" | mkfs.fat -F32 /dev/$EFI_PARTITION 2>&1)
    
    log "Making BOOT partition at /dev/$BOOT_PARTITION"
    log $(echo "y" | mkfs.ext4 /dev/$BOOT_PARTITION 2>&1)
    
    if [ "$enable_encrypt" = true ]; then
        log "Creating LUKS partition at /dev/${ROOT_PARTITION}"
        log $(echo -n $luks_password | cryptsetup --use-random luksFormat "/dev/${ROOT_PARTITION}" 2>&1 )
        log $(echo -n $luks_password | cryptsetup luksOpen "/dev/${ROOT_PARTITION}" cryptlvm 2>&1)
        
        log $(pvcreate /dev/mapper/cryptlvm 2>&1)
        log $(vgcreate vg0 /dev/mapper/cryptlvm 2>&1)
        
        log $(lvcreate --size $home_size vg0 --name root 2>&1)
        log $(lvcreate -l +100%FREE vg0 --name home 2>&1)
        log $(lvreduce --size -256M vg0/home 2>&1)
        
        log $(echo "y" | mkfs.ext4 /dev/vg0/root 2>&1)
        log $(echo "y" | mkfs.ext4 /dev/vg0/home 2>&1)
        
        log $(mount /dev/vg0/root /mnt 2>&1)
    else
        
        log "Making BOOT partition at /dev/$ROOT_PARTITION"
        log $(echo "y" | mkfs.ext4 /dev/$ROOT_PARTITION 2>&1)
        
        log "Mounting /dev/${ROOT_PARTITION}"
        log $(mount --mkdir "/dev/${ROOT_PARTITION}" /mnt 2>&1)
    fi
    
    log "Mounting /dev/${EFI_PARTITION}"
    log $(mount --mkdir "/dev/${EFI_PARTITION}" /mnt/efi 2>&1)
    
    log "Mounting /dev/${BOOT_PARTITION}"
    log $(mount --mkdir "/dev/${BOOT_PARTITION}" /mnt/boot 2>&1)
    
    if [ "$enable_encrypt" = true ]; then
        log $(mount --mkdir /dev/vg0/home /mnt/home 2>&1)
    fi
    
    log "Disk partitioned!"
    log "EFI set at ${EFI_PARTITION}"
    log "BOOT set at ${BOOT_PARTITION}"
    log "SYSTEM set at ${ROOT_PARTITION}"
}

execute_initial_setup () {
    log "Installing base packages..."
    log $(pacstrap -K /mnt base base-devel linux linux-firmware linux-headers openssh git nano sudo networkmanager 2>&1)
    
    log "Generating fstab..."
    log $(genfstab -U -p /mnt >> /mnt/etc/fstab 2>&1)
}

make_partitions
execute_initial_setup

cat <<EOF > /mnt/root/arch-install.sh
#!/bin/bash
set -euo pipefail

log () {
    status=\$?
    output=""

    if [ "$verbose" = true ]; then
        for message in "\$@"
        do
            output="\$output \$message"
        done
    else
        if [ "\$#" -gt 0 ]; then
            if [ -n "\$1" ]; then
                output=\$1
            fi
        fi
    fi

    if [ -n "\$output" ]; then
        date_time=\$(date "+%Y/%m/%d %H:%M:%S")
        echo -e "${BYellow}[\$date_time]${RESET} \$output"
    fi

    if [ \$status -ne 0 ]; then
        exit $?
    fi
}

configure_pacman () {
	sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
	sed -i 's/#Color/Color/g' /etc/pacman.conf
}

install_packages () {
	pacman --noconfirm -Sy archlinux-keyring
	pacman --noconfirm -S $(load_pacman_packages)
}

install_kde () {
	pacman --noconfirm -S plasma ark colord-kde dolphin dolphin-plugins \\
		ffmpegthumbs filelight gwenview isoimagewriter juk kalk kamera \\
		kamoso kate kcharselect kclock kcolorchooser kcron kdeconnect \\
		kdegraphics-thumbnailers kdenetwork-filesharing kdesdk-thumbnailers \\
		kdf kdialog kfind kget kgpg kio-zeroconf kjournald kleopatra kmix \\
		kmousetool knotes kolourpaint kompare krdc krfb ksystemlog \\
		kwalletmanager okular partitionmanager markdownpart svgpart \\
		spectacle yakuake

    systemctl enable sddm
}

install_gnome () {
	pacman --noconfirm -S gnome
}

install_cinnamon () {
    pacman --noconfirm -S cinnamon lightdm lightdm-gtk-greeter lightdm-slick-greeter xed xreader xreader
    systemctl enable lightdm
}

setup_plymouth () {
	git clone https://github.com/murkl/plymouth-theme-arch-os.git
	cd plymouth-theme-arch-os && cp -r ./src /usr/share/plymouth/themes/arch-os
	plymouth-set-default-theme -R arch-os
	cd .. && rm -r plymouth-theme-arch-os
}

adjust_clock () {
	ln -s /usr/share/zoneinfo/${time_zone} /etc/localtime
	hwclock --systohc
}

setup_locale () {
	sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
	locale-gen
	echo LANG=en_US.UTF-8 > /etc/locale.conf
}

setup_users () {
	echo $hostname > /etc/hostname
	useradd -m -G wheel --shell /bin/zsh $username
	echo "root:$password" | chpasswd
	echo "$username:$password" | chpasswd

	sed -i 's/^# %wheel/%wheel/' /etc/sudoers
}

install_yay () {
	if test /home/$username/yay-bin; then
	   rm -rf /home/$username/yay-bin
	fi
	runuser -l $username -c "git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin"
}

setup_mkinitcpio () {
	sed -i 's/^MODULES=.*/MODULES=($(load_modules))/' /etc/mkinitcpio.conf
	sed -i 's/^HOOKS=.*/HOOKS=($(load_hooks))/' /etc/mkinitcpio.conf
	mkinitcpio -P
}

setup_grub () {
	grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB

    if [ "$enable_encrypt" = true ]; then
        sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/${ROOT_PARTITION}:cryptlvm root=\/dev\/vg0\/root quiet splash ibt=off"/' /etc/default/grub
	    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
	    grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

setup_shell () {
	runuser -l $username -c "curl -L https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh"
}

setup_services () {
    services=($(load_services))
    for service in "\${services[@]}"; do
        systemctl enable \$service
    done
}

install_aur_packages () {
    su $username <<'COMMAND'
cd /home/$username/
packages=($(load_aur_packages))
for package in "\${packages[@]}"; do
    git clone \$package package
    cd package
    makepkg -si --noconfirm
    cd ..
    rm -rf package
done
COMMAND
}

log 'Configuring pacman...'
log \$(configure_pacman 2>&1)

log 'Installing packages...'
log \$(install_packages 2>&1)

if [ "$desktop_environment" = "kde" ]; then
    log 'Installing KDE Plasma...'
    log \$(install_kde 2>&1)
elif [ "$desktop_environment" = "gnome" ]; then
    log 'Installing Gnome...'
    log \$(install_gnome 2>&1)
elif [ "$desktop_environment" = "cinnamon" ]; then
    log 'Installing Cinnamon...'
    log \$(install_cinnamon 2>&1)
else
    log 'No Desktop Envirionment defined. Continuing without it...'
fi

log 'Setting up Plymouth...'
log \$(setup_plymouth 2>&1)

log 'Setting up Time Zone...'
log \$(adjust_clock 2>&1)

log 'Setting up locale...'
log \$(setup_locale 2>&1)

log 'Setting up user...'
log \$(setup_users 2>&1)

log 'Installing yay...'
log \$(install_yay 2>&1)

log 'Generating Initramfs...'
log \$(setup_mkinitcpio 2>&1)

log 'Installing GRUB...'
log \$(setup_grub 2>&1)

log 'Installing AUR packages...'
log \$(install_aur_packages 2>&1)

log 'Updating Shell...'
log \$(setup_shell 2>&1)

log 'Setting up services...'
log \$(setup_services 2>&1)

if [ -f "/root/post-install.sh" ]; then
    log "Running post install script"
    /root/post-install.sh $username
    rm /root/post-install.sh
fi

exit
EOF

if [ -f "post-install.sh" ]; then
    log "Copying post install script"
    cp post-install.sh /mnt/root/post-install.sh
fi

chmod +x /mnt/root/arch-install.sh
arch-chroot /mnt /root/arch-install.sh

log "Finisihing install..."
log $(umount -R /mnt 2>&1)

if [ "$auto_reboot" = true ]; then
    log "Rebooting..."
    reboot
fi
