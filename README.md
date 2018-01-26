# linux_devbox

Cookbook for setting up a Linux development box.

Right now this assumes an arch linux system but my tastes change frequently.

# Prerequisites

Arch should be installed, and basics like disk encryption, boot loaders, network configs should be done.  A non-privileged user should be created with sudo privileges, and the running of the Ansible playbooks should be done by that user.

# Initial setup

To start with, clone this repo somewhere.

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



