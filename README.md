# linux_devbox

Cookbook for setting up a Linux development box.

Right now this assumes an arch linux system but my tastes change frequently.

# Prerequisites

Arch should be installed, and basics like disk encryption, boot loaders, network configs should be done.  A non-privileged user should be created with sudo privileges, and the running of the Ansible playbooks should be done by that user.

Some reminders about the setup process:

* Start with the [ install guide ](https://wiki.archlinux.org/index.php/Installation_guide) which covers things in some detail
* If this is a HiDPI system the console fonts are painfully small.  Run this command to temporarily fix: `setfont lat2-32 -m 8859-2`
* Setting up wifi is not straightfoward:
  * `iw dev` to see the list of wireless devices.  This obviously assumes the LiveCD kernel includes support for your card.
  * `iw dev (interface) scan | less` to scan for APs where `(interface)` is the device name from the previous step
  *  `wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)` to connect to a WPA-secured AP.  Note the shell trickery used here, so weird characters in `passphrase` will need to be quoted or use herestrings.  There's a [wiki page about WPA](https://wiki.archlinux.org/index.php/WPA_supplicant#Connecting_with_wpa_passphrase) with more details.
  * Get a DHCP lease with `dhcpcd (interface)`.  Note that is D-H-C-P-C-D, I always mess it up and type D-H-C-P-D which won't work.
  * Sync the system clock with `timedatectl set-ntp true`
* Disk partitioning is tricky because we will use LUKS to encrypt the disk and LVM on top
  * Use `gdisk` for partioning the GPT disk we always use
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
    * `fallocate -l 32G /mnt/swapfile` to allocate a swapfile on the root filesystem
    * `chmod 600 /mnt/swapfile` for security
    * `mkswap /mnt/swapfile` to initialize
    * `swapon /mnt/swapfile` to actiate
* Once the disks are configured it's time to install packages
  * I don't usually bother editing the `/etc/pacman.d/mirrorlist` file it defaults to use all the mirrors in the world.  Maybe tweak it if you're in a place with weak internet
  * `pacstrap /mnt base` to install the base packages over the network.  I don't like to install other packages here, because there's an Ansible playbook for that which also tweaks the `mirrorlist`
  *  `genfstab -U /mnt >> /mnt/etc/fstab` to generate an `/etc/fstab` file to preserve the current mount config.
* `arch-chroot /mnt` to chroot into the new system and begin setting it up
  * Set the time zone with `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`.  Eastern is usually `US/NewYork` or some such.
  * Set the system clock to UTC.  This is a Linux convention not Windows to be careful if you dual boot.  `hwclock --systohc`
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
        initrd /intel-ucode.img /initramfs-linux.img
        options cryptdevice=UUID=device-UUID:cryptolvm root=/dev/mapper/MyVol-root  quiet rw
     Note the `device-UUID` is the UUID of the encrypted physical block device.  The command to get this is `blkid -s UUID -o value /dev/(partition)`
     Note also the `/intel-ucode.img` use this only on Intel systems and only if the `intel_ucode` package is installed.
    * For the XPS 13 add some options to configure the Intel graphics: `modeset=1 enable_rc6=1 enable_fbc=1 enable_guc_loading=1 enable_guc_submission=1 enable_psr=1`
  * Add `keyboard`, `encrypt`, and `lvm2` hooks to `/etc/mkinitcpio.conf`
  * For XPS systems: Add `intel_agp` followed by `i915` modules to `/etc/mkinitcpio.conf`
  * Regenerate the `initramfs` with `mkinitcpio -p linux`
  * `passwd` to set a root password
  * Create an unprivileged user that can use `sudo` with `useradd -m -G wheel sumd00d`
  * Run `visudo` and uncomment the line that allows all `sudo` commands for members of `wheel`
  * Exit the chroot with `exit` and then `reboot` to boot into the live system.

# Initial setup

To start with, clone this repo somewhere.  If this is a fresh system you may need `sudo pacman -S git ansible` to ensure you have Git and Ansible installed.

# Running

Ansible normally assumes it can SSH into the target host using SSH keys.  If instead you want to run it on the local host, run it (as a non-privileged user with sudo permissions) as:
    $ ansible-playbook -c local --inventory localhost, --ask-become-pass playbooks/devbox.yml

# Notes

In general, you should _never_ use `pip` or `gem` to install system packages.  Installing them as user packages into your home directory is fine, but if you ever find yourself typing `sudo pip...` or `sudo gem...`, slap yourself on the wrist and see if there's an Arch official or AUR package for what you're trying to install.  In almost all cases, you don't mean to install systemwide but for a specific user account or perhaps even a specific project.  Always prefer that.

# System setup

Most of the code in this cookbook sets up the Linux system, and thus needs to run as root.  To perform the system setup:

    $ sudo chef-client -z -o linux_devbox

# User setup

A few elements of this cookbook are concerned with setting up the user's environment.  Those need to be run as the login user you are setting up for development work.  For a variety of reasons, which I think are bullshit but I digress, you can't mix runs of `chef-client` as `root` and as an unprivileged user.  Nonetheless, the recipe to set up the current user with my development environment needs to be run separately, and still as `sudo`.  Whatever non-privileged user is invoking `sudo` is the user who is set up.

    $ sudo chef-client -z -o linux_devbox::setup_user


# Fonts setup

For best results the terminal and vim configs I like require the powerline patched fonts.  There's usually a package called something like `powerline-fonts` for this.  Please install it.



