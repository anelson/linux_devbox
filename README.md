# linux_devbox

Cookbook for setting up a Linux development box.

Right now this assumes an arch linux system but my tastes change frequently.

# Prerequisites

Arch should be installed, and basics like disk encryption, boot loaders, network configs should be done.  A non-privileged user should be created with sudo privileges, and the running of the Ansible playbooks should be done by that user.

Some reminders about the setup process:

* Start with the [ install guide ](https://wiki.archlinux.org/index.php/Installation_guide) which covers things in some detail
* If this is a HiDPI system the console fonts are painfully small.  Run this command to temporarily fix: `setfont latarcyrheb-sun32 -m 8859-2`
* Setting up wifi is not straightfoward:
  * `iw dev` to see the list of wireless devices.  This obviously assumes the LiveCD kernel includes support for your card.
  * `ip link set (interface) up` to bring the wireless interface online
  * `iw dev (interface) scan | less` to scan for APs where `(interface)` is the device name from the previous step
  *  `wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)` to connect to a WPA-secured AP.  Note the shell trickery used here, so weird characters in `passphrase` will need to be quoted or use herestrings.  There's a [wiki page about WPA](https://wiki.archlinux.org/index.php/WPA_supplicant#Connecting_with_wpa_passphrase) with more details.
  * Get a DHCP lease with `dhcpcd (interface)`.  Note that is D-H-C-P-C-D, I always mess it up and type D-H-C-P-D which won't work.
  * Sync the system clock with `timedatectl set-ntp true`
* Pro-tip: You can use `Alt-RightArrow` to switch to another virtual TTY and use `elinks` to view this guide in a text-based web browser for easy reference as you switch back and forth between it and the install console.  Use `g` to go to a URL and vi navigation keys to move around.
* Disk partitioning is tricky because we will use LUKS to encrypt the disk and LVM on top
  * Use `gdisk` for partioning the GPT disk we always use.  Use `lsblk` to see the block devices available.  Create one
    250MB EFI partition and one with the rest of the space for our data
  * In case you forget the approach we use is [LVM on LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS ) for the root partition.
  * Read that page for more details and the latest thinking, but in summary:
    * `cryptsetup luksFormat --type luks2 /dev/(block device)`
    * `cryptsetup open /dev(blockdev) cryptolvm` this will open the encrypted block dev and make the decrypted block dev available at `/dev/mapper/cryptolvm`
    * `pvcreate /dev/mapper/cryptolvm` initializes an LVM physical volume on top of the encrypted LUKS volume
    * `vgcreate MyVol /dev/mapper/cryptolvm` creates a volume group called `MyVol` (can be called anything but we use `MyVol`)
    * `lvcreate -l 100%FREE MyVol -n root` creates a logical volume `MyVol-root` using all free space on the volume group `MyVol`.  Read the guide for options if you want to create multiple logical volumes.  I find it's hard to predict in advance what the right size for the various volumes should be.
    * NOTE: I don't create a swap partition.  Later on we'll create a swap file on the root partition which works fine and is more flexible.
    * `mkfs.ext4 /dev/mapper/MyVol-root` to format the root partition EXT4.  `btrfs` as the root volume isn't ready for prime time.
    * `mount /dev/mapper/MyVol-root /mnt` to mount.  If you made other partitions mount them under `mnt` as appropriate.
    * If there isn't already a UEFI boot partition created and initialized you need to do that also.  Read the guide.  Assuming it already exists:
      * `mkdir /mnt/boot` && `mount /dev/(EFI partition) /mnt/boot`
    * If it doesn't already exist, make sure you format it as FAT32 with `mkfs.fat -F32 /dev/(whatever)`
    * `fallocate -l 32G /mnt/swapfile` to allocate a swapfile on the root filesystem
    * `chmod 600 /mnt/swapfile` for security
    * `mkswap /mnt/swapfile` to initialize
    * `swapon /mnt/swapfile` to actiate
* Once the disks are configured it's time to install packages
  * I don't usually bother editing the `/etc/pacman.d/mirrorlist` file it defaults to use all the mirrors in the world.  Maybe tweak it if you're in a place with weak internet
  * `pacstrap /mnt base` to install the base packages over the network.  I don't like to install other packages here, because there's an Ansible playbook for that which also tweaks the `mirrorlist`
  *  `genfstab -U /mnt >> /mnt/etc/fstab` to generate an `/etc/fstab` file to preserve the current mount config.  Double
     check that the path to the swap file doesn't have a `/mnt` prefix; I've seen that happen once
* `arch-chroot /mnt` to chroot into the new system and begin setting it up
  * `pacman -Sy vim` to get an editor installed right away
  * Set the time zone with `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`.  Eastern is usually `US/NewYork` or some such.
  * Set the system clock to UTC.  This is a Linux convention not Windows so be careful if you dual boot.  `hwclock --systohc`
  * Ensure the system clock is synchronized with `timedatectl set-ntp true`
  * Edit `/etc/locale.gen` and uncomment the locales to use.  I only ever use `en_US.UTF-8` but maybe `es_ES.UTF-8` and `ru-RU.UTF-8` might come in handy.
  * Run `locale-gen` to generate those locales
  * Edit `/etc/locale.conf` to set `LANG=en_US.UTF-8` to make sure US English is the default locale.
  * I never have to edit the keyboard layout since US English is the default, but that's in `/etc/vconsole.conf`
  * Choose a hostname and put it in `/etc/hostname`
  * Populate `/etc/hosts` accordingly with that new hostname:

            127.0.0.1	localhost
            ::1		localhost
            127.0.1.1	myhostname.localdomain	myhostname

  * You'll need the wireless utilities you used in the LiveCD when you reboot in order to get the new system on the network.  `pacman -S iw wpa_supplicant networkmanager dialog` at the least.  I don't have to manually install firmware but that will depend upon the system.
  * `pacman -S intel-ucode` to install the latest Intel microcode updates
  * Now it's time to configure the boot loader.  I use `systemd-boot`:
    * Assuming not dual-booting windows:
    * `bootctl --path=/boot install` installs the boot loader into the UEFI system partition
    * edit `/boot/loader/loader.conf` to adjust the default entry to boot and the timeout.  Normally the default entry is `arch`
    * Created or edit `/boot/loader/entries/arch.conf` to configure how arch is booted.  In particular some changes are needed to support the encrypted filesystem.  There's a sample at `/usr/share/systemd/bootctl/arch.conf` to use as a starting point:
    * Here's an example config:

            title Arch Linux Encrypted LVM
            linux /vmlinuz-linux
            initrd /intel-ucode.img
            initrd /initramfs-linux.img
            options cryptdevice=UUID=device-UUID:cryptolvm root=/dev/mapper/MyVol-root  quiet rw

     Note the `device-UUID` is the UUID of the encrypted physical block device.  The command to get this is `blkid -s UUID -o value /dev/(partition)`.  A fun trick in `vi` when editing this file if you want to insert this UUID is to put the cursor where you want the ID inserted and run an Ex command `:r ! blkid -S ....` filling out the entire `blkid` command listed earlier.
     Note also the `/intel-ucode.img` use this only on Intel systems and only if the `intel_ucode` package is installed.
    * For the XPS 13 add some options to configure the Intel graphics: `i915 enable_guc_loading=-1 enable_guc_submission=-1`
    * NB: Based on [this patch](https://patchwork.freedesktop.org/patch/191386/) it appears use of `enable_rc6` is unwise so it's removed from the options listed abjove
  * Add `keyboard`, `encrypt`, and `lvm2` HOOKS to `/etc/mkinitcpio.conf`.  Be advised order is important.  NOTE:
    technically Ansible will do this for you as part of the setup process
  * For XPS systems: Add `nvme i915 intel_agp` MODULES to `/etc/mkinitcpio.conf`.  NOTE: technically Ansible will do
    this for you as part of the setup process
  * Regenerate the `initramfs` with `mkinitcpio -p linux`
  * `passwd` to set a root password
  * Create an unprivileged user that can use `sudo` with `useradd -m -G wheel -s /bin/zsh sumd00d`
  * Set a password for that user with `passwd sumd00d`
  * Install the sudo package with `pacman -S sudo`
  * Run `visudo` and uncomment the line that allows all `sudo` commands for members of `wheel`
  * Exit the chroot with `exit` and then `reboot` to boot into the live system.

## Suspend/Hibernate for laptops

On laptops some additional configuration is needed to support hibernating to disk.

The [Arch wiki](https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate) as usual is the definitive source of information.  Some summary items based on my prefered config:

* I use a swap file not a swap partition, therefore the instructions for a swap file apply
* When using a swap file, the `resume` kernel parameter specifies the /device/ where the swap file is located, /not/ the swap file itself.
* You need to specify the physical offset on the device where the swap file lives.  `filefrag -v /swapfile` will show this.  You want the physical offset of the first extent.
* Use the following kernel parameters:
  * `resume=/dev/mapper/MyVol-root`
  * `resume_offset=swapfileoffset` where /swapfileoffset/ is the starting offset of the swapfile on the device
* Update `/etc/mkinitcpio.conf` to add a `resume` hook. _IMPORTANT_: Put the `resume` hook /after/ `lvm2`


# Initial setup

If this is a fresh system also make sure you have the minimal dependencies that are required to run ansible:

    $ sudo pacman -S git git-lfs ansible python

To start with, clone this repo somewhere. *IMPORTANT*: make sure you remember to run the `git submodule` and `git lfs` steps also or the playbook won't work!

    $ git clone https://github.com/anelson/linux_devbox .
    $ cd linux_devbox
    $ git submodule update --recursive --init
    $ git lfs pull

# Running

## Install dependencies

The ansible playbooks depend on some roles in Ansible Galaxy which need to be installed.  Install them once with

    $ ansible-galaxy install -r requirements.yml

run from the `playbooks/` directory.

## System-wide setup

There are two setup scripts, `playbooks/devbox.yml` is for a generic system, and `playbooks/xps-devbox.yml` is specific to the XPS 13/15 laptops and adds some additional configuration specific to those models.

_NB_: In this repo there is a `playbooks` directory containing the playbooks.  You must `cd` into this directory before running `ansible-playbook`, because the `ansible.cfg` file must be in the current directory and must be relative to the `library` subdirectory due to a bug in Ansible module discovery logic as of version 2.4.

Ansible normally assumes it can SSH into the target host using SSH keys.  If instead you want to run it on the local host, run it (as a non-privileged user with sudo permissions) as:

    $ cd playbooks
    $ ansible-playbook -c local --inventory localhost, --ask-become-pass devbox.yml

    OR for XPS systems...

    $ ansible-playbook -c local --inventory localhost, --ask-become-pass xps-devbox.yml

After running this the first time, reboot the system.  It should come up with GDM and prompt you to log in.  `i3` will be an option, and `sway` also.  For now I'm sticking to Xorg so the Wayland-based configs are not tested as of now.

## User-specific setup

Once the system-wide setup is completed, there's another playbook that runs as the non-privileged user you set up at install time, and configures that user's home directory the way I like.  That runs the same way:

    $ ansible-playbook -c local --inventory localhost,  devuser.yml

    OR for XPS...
    
    $ ansible-playbook -c local --inventory localhost,  xps-devuser.yml

As with the system setup, there's also an XPS variant `playbooks/xps-devuser.yml` that also configures some HiDPI settings that I can't figure out how to set at the system level.

Both of those install IntelliJ.  If you haven't done an install lately, edit the `playbooks/roles/user-intellij/vars/main.yml` file and make sure the most recent version is downloaded.  If you want to upgrade IntelliJ later, you can also update var and re-run the `devuser.yml` playbook.

# Manual Setup Steps

Unfortunately there are some steps that it't not practical or possible to automate, or that I haven't figured out yet.  They are recoreded here so I don't forget to do them:

* The ansible scripts take care of installing `tmux` and pulling in the custom `.tmux.conf` I use, and `.tmux.conf` will automatically install `tpm`, the tmux plugin manager.  However it's not obvious how to make it install the missing plugins automatically.  To do that, start a `tmux` session and press `Ctrl-A` and then `I`.  That will force tpm to install the missing plugins.  
* The vim plugin `YouCompleteMe` is a real pain in the ass.  Start `vim` once to download the plugin, you'll probably get some error about the server shutting down, quite vim and then:
      
      $ cd ~/.vim/plugged/YouCompleteMe
      $ ./install.py --all
  
  This will configure YCM with all possible completion options, probably including some languages you don't need.  It's easier to pay this price once than to mess with it later.  Note you may have to repeat this if YCM is updated sometime in the future.  It's not ideal I know
* Firefox and Chrome configs are not easily automated.  Log into them using the respective login accounts and they will automatically configure the appropriate extensions and settings.
* The `devuser.yml` playbook will download and "install" IntelliJ but it still needs some manual configuration:
  * Obviously you have to connect the JetBrains account to establish license entitlement to use Ultimate
  * I have a github repo with IntelliJ settings, so first thing configure IntelliJ to use that repo.  The repo URL is `https://github.com/anelson/intellij-settings.git`
  * Install the IdeaVim plugin.  The config file is part of the `dotfiles` repo, you'll find it on your system at `~/.ideavimrc`.  Point the IdeaVim plugin there and restart.
  * Install the Scala and Ruby plugins
  * Configure the fonts.  The HiDPI screen might need bigger fonts, or JetBrains may have fixed HiDPI support as of the version you're running, you just don't know until you try.
* Dropbox is installed by Ansible but it must be configured manually.  Run `dropbox` to start the GUI. The Arch Wiki
  [Dropbox](https://wiki.archlinux.org/index.php/Dropbox) page has more details
* VMWare Workstation is installed automatically but the Windows VM to use for work email and such is not.  You'll have to build that manually.  I know it sucks.  A few reminders:
  * Install Office 2016
  * Install [ShutUp 10](https://www.oo-software.com/en/shutup10)
* Create a symlink from `~/Dropbox/Documents/vimwiki` to `~/vimwiki` so the VimWiki data is always synchornized with
  Dropbox
* Installing the VirtualBox extensions is possible with an AUR package, but it breaks often and since this can be downloaded and upgraded from within VirtualBox, I have opted to use that flow.  So you need to install the extensions from withint he VirtualBox GUI after the initial setup


# Notes

In general, you should _never_ use `pip` or `gem` to install system packages.  Installing them as user packages into your home directory is fine, but if you ever find yourself typing `sudo pip...` or `sudo gem...`, slap yourself on the wrist and see if there's an Arch official or AUR package for what you're trying to install.  In almost all cases, you don't mean to install systemwide but for a specific user account or perhaps even a specific project.  Always prefer that.

