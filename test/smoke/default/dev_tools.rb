# # encoding: utf-8

# Inspec test for recipe .::dev_tools

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/


describe package('git') do
	it { should be_installed }
end

describe package('git-lfs') do
	it { should be_installed }
end

describe command 'pip --version' do
	its('stdout') { should match /python 3/}
end

describe command 'pip2 --version' do
	its('stdout') { should match /python 2/}
end

describe pip('awscli') do 
	it { should be_installed }
end
