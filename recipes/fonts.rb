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

tar_extract node[:linux_devbox][:sourcecodepro_url] do 
	target_dir '/usr/share/fonts/opentype'
	creates '/usr/share/fonts/opentype/SourcCodePro-Regular.otf'
	tar_flags [ '--strip-components 2', node[:linux_devbox][:sourcecodepro_path_in_tarball] ]
end


bash 'refresh-font-cache' do
	code "fc-cache -f -v"
end

