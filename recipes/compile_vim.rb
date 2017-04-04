#
# Cookbook:: .
# Recipe:: compile_vim
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# vim8 is not on the official repos for ubuntu 16.04 yet
# it needs to be compiled from source

remote_file "#{Chef::Config[:file_cache_path]}/vim_source.tar.bz2" do 
	source node['linux_devbox']['vim_tarball']
	action :create

	not_if %Q{ vim --version | head -1 | grep 'Vi IMproved' }

	# If this file is downloaded, then and only then trigger the build process
	notifies :install,"package[install-deps]",:immediately
end

package 'install-deps' do 
	package_name [
		'libncurses5-dev',
		'libgnome2-dev',
		'libgnomeui-dev',
		'libgtk2.0-dev',
		'libgtk-3-dev',
		'libatk1.0-dev',
		'libbonoboui2-dev',
		'libcairo2-dev',
		'libx11-dev',
		'libxpm-dev',
		'libxt-dev',
		'python-dev',
		'python3-dev',
		'ruby-dev',
		'lua5.1',
		'liblua5.1-dev',
		'libperl-dev',
		'checkinstall',
		'git'
	]

	action :nothing
	notifies :run, "bash[build-and-install-vim]", :immediately
end

bash 'build-and-install-vim' do 
	cwd Chef::Config[:file_cache_path]

	code <<-EOH
		tar xvjf vim_source.tar.bz2
		cd vim80
		make distclean
		./configure --with-features=huge \
			--enable-fail-if-missing \
            --enable-multibyte \
            --enable-largefile \
            --enable-rubyinterp=yes \
            --enable-pythoninterp=yes \
            --with-python-config-dir=/usr/lib/python2.7/config \
            --enable-python3interp=no \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            "--with-compiled-by=Adam for your vim'ing pleasure" \
            --enable-gui=gtk3 
			--enable-cscope
			--prefix=/usr
		make VIMRUNTIMEDIR=/usr/share/vim/vim80

		sudo checkinstall

		sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
		sudo update-alternatives --set editor /usr/bin/vim
		sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
		sudo update-alternatives --set vi /usr/bin/vim	
	 	EOH

	action :nothing
end

