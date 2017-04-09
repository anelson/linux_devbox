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

default['linux_devbox']['fontawesome_url'] = "https://github.com/FortAwesome/Font-Awesome/archive/v4.7.0.tar.gz"
default['linux_devbox']['fontawesome_path_in_tarball'] = "Font-Awesome-4.7.0/fonts/FontAwesome.otf"
default['linux_devbox']['sourcecodepro_url'] = "https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.tar.gz"