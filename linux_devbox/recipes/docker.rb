#
# Cookbook:: linux_devbox
# Recipe:: docker
#
# Copyright:: 2017, The Authors, All Rights Reserved.
docker_installation_script 'default' do 
	repo 'main'
	action :create
end
