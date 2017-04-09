#
# Cookbook:: .
# Recipe:: fonts
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Install some fonts I like, including FontAwesome and some code editor fonts
ark 'fontawsome' do 
	url node[:linux_devbox][:fontawesome_url]
	creates node[:linux_devbox][:fontawesome_path_in_tarball]
	strip_components 2
	path '/usr/share/fonts/opentype'
	action :cherry_pick
end

bash 'refresh-font-cache' do
	code "fc-cache -f -v"
end

