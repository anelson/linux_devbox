default['java']['install_flavor'] = 'openjdk'
default['java']['jdk_version'] = '8'

edition = 'U'
version = '2017.1'
default['idea']['setup_dir'] = '/opt/ideaIU'
default['idea']['edition'] = edition
default['idea']['version'] = version
# the idea cookbook is implemented in such a way that changing edition and version doesn't update the URL
default['idea']['url'] = "https://download-cf.jetbrains.com/idea/ideaI#{edition}-#{version}.tar.gz"

default['linux_devbox']['user'] = ENV['SUDO_USER'] || node[:current_user]
default['linux_devbox']['vim_tarball'] = ["ftp://ftp.vim.org/pub/vim/unix/vim-8.0.tar.bz2", "ftp://ftp.ca.vim.org/pub/vim/unix/vim-8.0.tar.bz2"]