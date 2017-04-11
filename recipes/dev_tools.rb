#
# Cookbook:: .
# Recipe:: dev_tools
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Install some commonly used packages
package ['build-essential',
 'cmake',
 'git',
 'nodejs',
 'ruby',
 'ruby-dev',
 'libev-dev',
 'libstartup-notification0-dev',
 'zsh',
 'tmux',
 'curl',
 'dos2unix',
 'linux-image-extra-virtual',
 'open-vm-tools', 'open-vm-tools-desktop',
 'tree',
 'jq'
]

# Install python 2 and 3 and their respecive pips
python_runtime '2' do
	pip_version true
	action :install
end

python_runtime '3' do
	pip_version true
	action :install
end

# Install the AWS CLI using python 3
python_package 'awscli' do
	action :upgrade
end

# Download and install the git-lfs package manually
# As of now it's not on any convenient repo
git_lfs_path = Chef::Config['file_cache_path'] + '/git-lfs.deb'

remote_file git_lfs_path do
	source 'https://packagecloud.io/github/git-lfs/packages/debian/jessie/git-lfs_2.0.2_amd64.deb/download'
	mode '0700'
	action :create_if_missing
end

dpkg_package 'git-lfs' do
	source git_lfs_path
	action :install
end
