# # encoding: utf-8

# Inspec test for recipe .::i3wm

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe command 'i3 --version' do
	its('stdout') { should match /4.13/}
end

describe command 'i3' do 
	it { should exist }
end
