# linux_devbox

Cookbook for setting up a Linux development box.

This branch is for Fedora Workstation (version 31 at the time of this writing).

# Prerequisites

Fedora should be installed with the normal install process, and basics like disk encryption, boot loaders, network configs should be done. A
non-privileged user should be created with sudo privileges, and the running of the Ansible playbooks should be done by
that user.  The initial setup flow that creates the first user automatically enables sudo so this should be easy.

After initial setup you're in GNOME.  Open a terminal and:

    sudo dnf upgrade
    sudo dnf install git git-lfs ansible

As the non-priviledged user, make sure zsh is installed and the default shell:

    sudo dnf install zsh util-linux-user
    chsh -s /usr/bin/zsh

# Initial setup

If this is a fresh system also make sure you have the minimal dependencies that are required to run ansible.  See the
PrePrerequisites section.

To start with, clone this repo somewhere. _IMPORTANT_: make sure you remember to run the `git submodule` and `git lfs`
steps also or the playbook won't work!

    $ git clone https://github.com/anelson/linux_devbox .
    $ cd linux_devbox
    $ git submodule update --recursive --init
    $ git lfs pull

# Running

## Install dependencies

The ansible playbooks depend on some roles in Ansible Galaxy which need to be installed. Install them once with

    $ ansible-galaxy install -r requirements.yml

run from the `playbooks/` directory.

## System-wide setup

There are a few versions of the setup script:

* `devbox.yml` is the base version and I never use this one directly
* `xps-devbox.yml` sets up an XPS 13/15 HiDPI laptop system
* `desktop-devbox.yml` sets up a desktop system assumed to have a HiDPI monitor and not use battery power
* `headless-devbox.yml` sets up a headless system like a server or cloud instance, without X or any power management

As per Ansible convention, all of these are located in the  `playbooks/` directory.

_NB_: In this repo there is a `playbooks` directory containing the playbooks. You must `cd` into this directory before
running `ansible-playbook`, because the `ansible.cfg` file must be in the current directory and must be relative to the
`library` subdirectory due to a bug in Ansible module discovery logic as of version 2.4.

Ansible normally assumes it can SSH into the target host using SSH keys. If instead you want to run it on the local
host, run it (as a non-privileged user with sudo permissions) as:

    $ cd playbooks
    $ ansible-playbook -c local --inventory localhost, --ask-become-pass desktop-devbox.yml

    OR for XPS systems...

    $ ansible-playbook -c local --inventory localhost, --ask-become-pass xps-devbox.yml

After running this the first time, reboot the system. It should come up with GDM and prompt you to log in. `i3` will be
an option, and `sway` also. For now I'm sticking to Xorg so the Wayland-based configs are not tested as of now.

## Setting up a remote system

If you're setting up a remote system over SSH, there are some changes to the command line:

    $ ansible-playbook --inventory <remote host>, --user <probably root> headless-devbox.yml

NOTE: Just because you're doing a remote setup doesn't mean you can ignore the pre-reqs that normally apply to a local
install. Make sure you have at least these:

    $ sudo pacman -S python sudo

If you're doing the user-specific setup also, you'll probably want to configure SSH certificate auth for that user. If
you're still using the Yubikey-based auth approach, you'll need to do this:

    $ ssh-copy-id -f -i ~/Dropbox/Documents/gpg/yubikey_auth_cert_for_ssh.pub username@hostname

## User-specific setup

Once the system-wide setup is completed, there's another playbook that runs as the non-privileged user you set up at
install time, and configures that user's home directory the way I like. That runs the same way:

    $ ansible-playbook -c local --inventory localhost,  desktop-devuser.yml

    OR for XPS...

    $ ansible-playbook -c local --inventory localhost,  xps-devuser.yml

As with the system setup, there are a few versions of the `devuser` script with the same prefixes we use for the system
version.

Most of those install IntelliJ. If you haven't done an install lately, edit the
`playbooks/roles/user-intellij/vars/main.yml` file and make sure the most recent version is downloaded. If you want to
upgrade IntelliJ later, you can also update var and re-run the `devuser.yml` playbook.

# Manual Setup Steps

Unfortunately there are some steps that it't not practical or possible to automate, or that I haven't figured out yet.
They are recoreded here so I don't forget to do them:

- The ansible scripts take care of installing `tmux` and pulling in the custom `.tmux.conf` I use, and `.tmux.conf` will
  automatically install `tpm`, the tmux plugin manager. However it's not obvious how to make it install the missing
  plugins automatically. To do that, start a `tmux` session and press `Ctrl-A` and then `I`. That will force tpm to
  install the missing plugins.
- By the same token you'll need to start `nvim` once to initialize all of the plugins.  Make sure you do this with a
    working internet connection.
- You need to manually pull the bitmaps from the dotfiles repo. `homeshick cd dotfiles && git lfs pull` should do the
  trick
- Firefox and Chrome configs are not easily automated. Log into them using the respective login accounts and they will
  automatically configure the appropriate extensions and settings. Then do this:
  - Firefox won't work right with the GTK theme we use. To to `about:config` and create a new setting
    `widget.content.gtk-theme-override` and set it to `Arc-Darker`. This theme complements `Arc-Dark` nicely and renders
    the UI elements with a legible color combo
  - In `about:config` enable `security.webauth.u2f`
  - Ensure Firefox is the default browser and prompts when it's not, and ensure the opposite with Chrome
  - Configure Firefox's default search engine to be DDG, not Google.  Yes, that should be synchronized along with the
      rest of the settings.  There's a [bug report](https://bugzilla.mozilla.org/show_bug.cgi?id=444284) to this effect
      which is now 11 years old.  Mozilla is funded in large part by having Google search as the default search engine,
      make of that what you will...
- The `devuser.yml` playbook will download and "install" IntelliJ but it still needs some manual configuration:
  - Obviously you have to connect the JetBrains account to establish license entitlement to use Ultimate
  - I have a github repo with IntelliJ settings, so first thing configure IntelliJ to use that repo. The repo URL is
    `https://github.com/anelson/intellij-settings.git`
  - Install the IdeaVim plugin. The config file is part of the `dotfiles` repo, you'll find it on your system at
    `~/.ideavimrc`. Point the IdeaVim plugin there and restart.
  - Install the Scala and Ruby plugins
  - Configure the fonts. The HiDPI screen might need bigger fonts, or JetBrains may have fixed HiDPI support as of the
    version you're running, you just don't know until you try.
- There is an AUR package for CrossOver, the commercial version of Wine that can be used to make Office work, however
    it's not consistently updated.  Instead it's better to install it manually using the latest binary installer from
    the Crossover site.  My login for Crossover is in 1p.  Of course one must also install Office itself.  To do that go
    to https://office.com, log in, and go to My Account and Subscriptions.  They won't even offer you download links
    unless your User Agent is a Windows browser, so use User Agent Switcher to fake that out and snag the quick
    installer.
- Dropbox is installed by Ansible but it must be configured manually. Run `dropbox` to start the GUI. The Arch Wiki
  [Dropbox](https://wiki.archlinux.org/index.php/Dropbox) page has more details
- VMWare Workstation is installed automatically but the Windows VM to use for work email and such is not. You'll have to
  build that manually. I know it sucks. A few reminders:
  - Install Office 2016
  - Install [ShutUp 10](https://www.oo-software.com/en/shutup10)
- Create a symlink from `~/Dropbox/Documents/vimwiki` to `~/vimwiki` so the VimWiki data is always synchornized with
  Dropbox
- Installing the VirtualBox extensions is possible with an AUR package, but it breaks often and since this can be
  downloaded and upgraded from within VirtualBox, I have opted to use that flow. So you need to install the extensions
  from withint he VirtualBox GUI after the initial setup
- I use Chromium (not Chrome) to connect to the web interface for Todoist and Evernote. For each of those I use the 'Add
  to desktop' feature to make a desktop link and a separate browser state for each of those. It's not the same as native
  but it's the best that's available. Each time you do this the window classes will be different, so the `i3/config`
  file will need to be updated accoringly. Chromium generates some dynamic and strange window class so it is not
  predicable.
- If this is a new system, follow my guide in the `vimwiki` for setting up Yubikeys for SSH and GPG auth.   

# Updating the firmware with `fwupdmgr` (applies to XPS systems specifically)

When doing Arch system updates the `/etc/fwupd/uefi.conf` file can get overwritten which means `fwupdmgr` seems to work
but no firmware actually gets upgraded on reboot. You must make the edit described in
[this article](https://wiki.archlinux.org/index.php/Fwupd) at the bottom of the page. This is what the line should look
like:

```
# For fwupdate 10+ allow overriding
# the compiled EFI system partition path
OverrideESPMountPoint=/boot
```

# Storing Git Credentials Securely

Currently my `dotfiles` repo has a Git config that uses the built-in `store` helper, which stores credentials on the
filesystem unencrypted. I use FDE so they're still encrypted before they hit the disk, but other user-land processes
running under my account can read them. That's not ideal.

Long story short I tried to find a good solution here that works for headless and headed systems and it seems
impossible.  So instead I use Git certificate auth from a Yubikey.  There's a page in the `vimwiki` about how to set
this up.  The dotfiles are already configured for it.

# Notes

In general, you should _never_ use `pip` or `gem` to install system packages. Installing them as user packages into your
home directory is fine, but if you ever find yourself typing `sudo pip...` or `sudo gem...`, slap yourself on the wrist
and see if there's an Arch official or AUR package for what you're trying to install. In almost all cases, you don't
mean to install systemwide but for a specific user account or perhaps even a specific project. Always prefer that.
