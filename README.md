# linux_devbox

Cookbook for setting up a Linux development box.

# Initial setup

To start with, clone this repo somewhere.  `cd` into the repo directory and run `berks` to download the dependent cookbooks and put them in the `cookbooks/` directory.  There's a `.gitignore` rule to ensure this vendored `cookbooks` dir doesn't get checked in:

    $ berks vendor cookbooks

This will create or update the `cookbooks/` directory, filling it with all of the dependencies, _as well as a copy of this cookbook_.  That's an important detail.  After this, when `chef-client` runs in local mode it will see a `cookbooks/` directory and assume that directory contains the repository of cookbooks to run in local mode.  If you change the files in this cookbook that are under source control, those changes won't be picked up by `chef-client` until you re-run `berks vendor cookbooks`.  This can be very confusing if you're not ready for it.

# Tests

If you are feeling fastidious, verify the tests are passing first:

    $ kitchen test

# System setup

Most of the code in this cookbook sets up the Linux system, and thus needs to run as root.  To perform the system setup:

    $ sudo chef-client -z -o linux_devbox

# User setup

A few elements of this cookbook are concerned with setting up the user's environment.  Those need to be run as the login user you are setting up for development work.  For a variety of reasons, which I think are bullshit but I digress, you can't mix runs of `chef-client` as `root` and as an unprivileged user.  Nonetheless, the recipe to set up the current user with my development environment needs to be run separately, and still as `sudo`.  Whatever non-privileged user is invoking `sudo` is the user who is set up.

    $ sudo chef-client -z -o linux_devbox::setup_user



