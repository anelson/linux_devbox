# # encoding: utf-8

# Inspec test for recipe linux_devbox::docker

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe command 'docker -v' do
	its('stdout') { should match /Docker version 17\./}
end
