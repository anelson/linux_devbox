#
# Cookbook:: .
# Recipe:: i3wm
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Install a deb package to install the i3 repository key
remote_file "#{Chef::Config[:file_cache_path]}/i3_key.deb" do
  source "http://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2017.01.02_all.deb"
  checksum "4c3c6685b1181d83efe3a479c5ae38a2a44e23add55e16a328b8c8560bf05e5f"
end

dpkg_package "i3_key" do
  source "#{Chef::Config[:file_cache_path]}/i3_key.deb"
  action :install
end

apt_repository 'i3' do 
	uri 'http://debian.sur5r.net/i3/'
	components ['universe']
	distribution node['lsb']['codename']
	action :add
end

package 'i3'