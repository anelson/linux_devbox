#
# Cookbook:: linux_devbox
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

apt_update 'update' do
	frequency 86_400 # every 24 hours
	action :periodic
end

include_recipe 'linux_devbox::java_dev'
include_recipe 'linux_devbox::docker'
include_recipe 'linux_devbox::dev_tools'