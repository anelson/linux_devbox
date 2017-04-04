#
# Cookbook:: linux_devbox
# Recipe:: java_dev
#
# Copyright:: 2017, The Authors, All Rights Reserved.

package 'openjdk-8-jdk'

# Add the SBT repo and install from it
apt_repository 'sbt' do 
	uri 'https://dl.bintray.com/sbt/debian'
	keyserver 'keyserver.ubuntu.com' 
	key '2EE0EA64E40A89B84B2DF73499E82A75642AC823'
	components ['/']
	distribution ''
	action :add
end

package 'sbt'
