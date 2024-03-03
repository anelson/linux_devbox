# linux_devbox

Cookbook for setting up a Linux development box.

This branch is for Fedora Workstation (version 32 at the time of this writing).

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
an option, and `sway` also. As of this writing `i3` is what I'm using every day.  See below for issues with
Sway/Wayland.

## Setting up a remote system

If you're setting up a remote system over SSH, there are some changes to the command line:

    $ ansible-playbook --inventory <remote host>, --user <probably root> headless-devbox.yml

If the user is not `root`, you'll probably need `--ask-become-pass` to make sure Ansible has the password for when it
needs to `sudo`.

NOTE: Just because you're doing a remote setup doesn't mean you can ignore the pre-reqs that normally apply to a local
install. Make sure you have at least these:

    $ sudo dnf install python sudo

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

# Manual Setup Steps

Unfortunately there are some steps that it't not practical or possible to automate, or that I haven't figured out yet.
They are recoreded here so I don't forget to do them:

- The ansible scripts take care of installing `tmux` and pulling in the custom `.tmux.conf` I use, and `.tmux.conf` will
  automatically install `tpm`, the tmux plugin manager. However it's not obvious how to make it install the missing
  plugins automatically. To do that, start a `tmux` session and press `Ctrl-A` and then `I`. That will force tpm to
  install the missing plugins.
- By the same token you'll need to start `nvim` once to initialize all of the plugins.  Make sure you do this with a
    working internet connection.
    - Also run `:CocInstall` to make sure all CoC plugins are installed
- You need to manually pull the bitmaps from the dotfiles repo. `homeshick cd dotfiles && git lfs pull` should do the
  trick
- Firefox and Chrome configs are not easily automated. Log into them using the respective login accounts and they will
  automatically configure the appropriate extensions and settings. Then do this:
  - Firefox won't work right with the GTK theme we use. To to `about:config` and create a new setting
    `widget.content.gtk-theme-override` and set it to `Arc-Darker`. This theme complements `Arc-Dark` nicely and renders
    the UI elements with a legible color combo
  - In `about:config` enable `security.webauth.u2f` (this appears to be the default in the most recent Firefox)
  - Ensure Firefox is the default browser and prompts when it's not, and ensure the opposite with Chrome
  - Configure Firefox's default search engine to be DDG, not Google.  Yes, that should be synchronized along with the
      rest of the settings.  There's a [bug report](https://bugzilla.mozilla.org/show_bug.cgi?id=444284) to this effect
      which is now 11 years old.  Mozilla is funded in large part by having Google search as the default search engine,
      make of that what you will...
- Dropbox is installed by Ansible but it must be configured manually. Run `dropbox` to start the GUI. The Arch Wiki
  [Dropbox](https://wiki.archlinux.org/index.php/Dropbox) page has more details
- Create a symlink from `~/Dropbox/Documents/vimwiki` to `~/vimwiki` so the VimWiki data is always synchornized with
  Dropbox
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

## Sway and Wayland 

In this most recent update, as part of the move from Arch to Fedora, I spent a lot of time setting up a Sway config that
mirrored the capabilities I have in i3.  In the end I went back to running i3.  The following issues still need to be
addressed:

* sway uses the i3 config format, but almost none of the tools used with i3 work under wayland.  In particular, tray
    support in Waybar is glitchy and unusable.  The notification daemon `mako` isn't even packaged yet, and must be
    built from source.  
* Wayland has a protocol for screen sharing, and the WebRTC implementation in the latest Firefox supports it.  However
    Zoom does not.  Maybe if I made this transition before the entire world went on lockdown and life moved to Zoom,
    I would not have considered this a deal-breaker, but now I use Zoom screenshare at least once per day.  Workarounds
    like using the Zoom web interface are blocked by other bugs in either Firefox or Sway (people seem to disagree about
    who is at fault), or setting up a virtual webcam that is actually the contents of one's screen are complex, brittle,
    and generally unacceptable when a perfectly reliable alternative exists. 
* No wifi network picker equivalent to `nm-applet`.
* Firefox HiDPI is broken.  Firefox on Wayland appears to have absolutely no HiDPI awareness at all, in spite of
    multiple breathless announcements declaring improved HiDPI support.  Maybe I'm doing something wrong or missing
    something obvious, but I had to configure Firefox to zoom 200%, but all of the UI chrome was still tiny and
    uncomfortable to read.  Chromium, Slack, Skype, all were fine. 

Fedora has made GNOME on Wayland the default DM, and that particular combination, I must admit, is great.  Rock solid,
Firefox is very fast and no tearing at all, even Zoom screenshare works.  But that's GNOME.  If GNOME was what I wanted
for a WM, I never would have bothered with all of these contortions with i3 in the first place.

It's a pity.  I feel like we're almost there, and the performance benefits of Firefox on Wayland are fantastic.

# macOS

macOS is much less amenable to automated setup.  For now I'll just record the manual steps I use on a new mac setup.
Maybe over time I'll automate them more:

* Install Homebrew from https://brew.sh
  * Don't forget to enable it in the terminal with `eval "$(/opt/homebrew/bin/brew shellenv)"`
* Ensure the tmux-256color terminal type is recognized:
  * `brew install ncurses && /opt/homebrew/opt/ncurses/bin/infocmp tmux-256color > ~/tmux-256color.info && tic -xe tmux-256color tmux-256color.info`
  * Note the `/opt/homebrew` path assumes this command is running on an Apple Silicon mac.  Adjust the path if this is an Intel mac.
* `brew install python` and `brew install ansible`
* Make sure the necessary community collection is installed: `ansible-galaxy collection install community.general`
# `cd` into `playbooks` and run `ansible-galaxy install -r requirements.yml`
* Deploy the `headless-mac.yml` playbook
  * `ansible-playbook -c local --inventory localhost,  headless-mac.yml`
* Download "Sauce Code Pro" nerd fonts
  * `brew tap homebrew/cask-fonts && brew install --cask font-sauce-code-pro-nerd-font`
* Install Dropbox
* Wait approximately 100 years for shitty dropbox to sync up
* New SSH key management:
  * Now using 1Password for key management.  Unfortunately right now this is now something I can commit to `dotfiles`
  because it requires hard-coding a mac-specific path into the SSH config.  So when setting up a new mac this will need
  to be done manually until I find a solution for having platform-specific SSH configs:
  * ```
    Host *
      # SHIT: this is macOS specific, because on Linux hosts I have SSH'd into them from a mac with this identity agent.
      # How can this co-exist with Linux systems that share this same .ssh/config file?  FML.
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ```

    The exact path to set to `IdentityAgent` might be different on different installs, I'm not sure.  Anyway you can
    find it in the "Developer" section of 1Password settings when checking the check box to enable the SSH agent.
* Old, shitty SSH key management which should no longer be needed:
  * Make `~/Dropbox/Documents/gpg` available offline
  * Add the SSH private key to the Apple Keychain:
    * `ssh-add --apple-use-keychain ~/Dropbox/Documents/gpg/id_rsa`
* Go into the Keyboard settings, click Modifier Keys, and remap Caps Lock to Escape
  * NOTE: This needs to be done separately for each keyboard, so when using the Logitech wireless kbd and the Kinesis
    this must be done separately for each one.
  * NOTE 2: It's possible on the Kinesis to remap CapsLock to Esc in hardware, but I haven't done that recently.
  Keeping this here since it's necessary to do for any newly connected computer anyway.
* Install [Rectangle](https://rectangleapp.com) for convenient shortcuts to resize windows.  It's not i3, not by a long shot, but it sucks less than having nothing at all.
* Finder settings:
    * Under View, activate Show Path Bar
* If using Sidecar to use the iPad as an extended display, make sure the iPad is trusted so that Sidecar will work over a cable.  It own't be obvious at first that you didn't do this, but Sidecar over wifi is glitchy as fuck and will often hang.  
  
  To establish trust, connect the iPad via the cable, so it appears in Finder.  Then do a backup of the iPad.  At some point this will trigger a trust prompt on the iPad and/or the mac itself.  Once that is done, Sidecar should work over the cable and suck a lot less!
* Install the following manually:
  * Vivaldi (See note about 1Password below)
  * Brave (See note about 1Password below)
  * Dropbox
  * MS 365 Suite
  * Alacritty
  * Parallels
* Configure 1Password to trust Vivaldi and Brave
  * By default, 1P trusts Chrome, Edge, Safari, maybe Firefox.  It won't let the 1P extension in Brave or Vivaldi talk
  to the 1P desktop app, which results in a shit experience.  Open the 1P desktop app, go to Settings, Browsers, there's
  an UI option to add a trusted browser.  Navigate to the Vivaldi and Brave executables.  You can verify this works by
  opening 1P extension in the browser and going to settings; the option to integrate w/ the desktop version should be
  enabled and the status light should go from amber to green confirming it works.
* Perform the manual steps which apply to Mac, a subset of those listed in [Manual Setup Steps](#manual-setup-steps)
