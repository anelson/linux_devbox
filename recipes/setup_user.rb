#
# Cookbook:: .
# Recipe:: setup_user
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Configure the user
# Unlike the other recipes, this one assumes it's run (unprivileged) as the user to be set up
# Therefore, it doesn't run as part of the default recipe, it must be run separately
username = node['linux_devbox']['user']
home = "/home/#{username}"
oh_my_zsh_dir = "#{home}/.oh-my-zsh"
homeshick_dir = "#{home}/.homesick/repos/homeshick"
dotfiles_dir = "#{home}/.homesick/repos/dotfiles"

# use zsh for the shell
user username do
	action :modify
	shell '/bin/zsh'
end

# Checkout oh-my-zsh
directory 'oh_my_zsh_dir' do
	path oh_my_zsh_dir
	action :create
	recursive true

	user username
	group username
end

git 'oh-my-zsh' do
	repository 'git://github.com/robbyrussell/oh-my-zsh.git'
	destination oh_my_zsh_dir
	checkout_branch 'master'
	action :sync

	user username
	group username
end

# Checkout homeshick for dotfiles
directory 'homeshick_dir' do
	path homeshick_dir
	action :create
	recursive true

	user username
	group username
end

git 'homeshick' do
	repository 'git://github.com/andsens/homeshick.git'
	checkout_branch 'master'
	destination homeshick_dir
	action :sync

	user username
	group username
end

# Clone my personal dotfiles repo into homeshick
directory 'dotfiles_dir' do
	path dotfiles_dir
	action :create
	recursive true

	user username
	group username
end

git 'dotfiles' do
	repository 'https://github.com/anelson/dotfiles.git'
	checkout_branch 'master'
	destination dotfiles_dir
	action :sync

	user username
	group username
end

# Use homshick to symlink from the dotfiles into the home directory
bash 'link dotfiles' do
	code "#{home}/.homesick/repos/homeshick/bin/homeshick link dotfiles -f -q"
	user username
	not_if { ::File.exist?("#{home}/.vim") }
end
