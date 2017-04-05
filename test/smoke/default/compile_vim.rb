# # encoding: utf-8

# Inspec test for recipe .::compile_vim

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/


describe command 'vim --version' do
	its('stdout') { should match /Vi IMproved 8.0/}
	its('stdout') { should match /\+X11/}
	its('stdout') { should match /\+python/}
end

describe command 'vi' do 
	it { should exist }
end

describe command '/usr/bin/gvim' do 
	it { should exist }
end

describe command '/usr/bin/vim' do 
	it { should exist }
end

describe file '/usr/share/applications/vim.desktop' do 
	it { should be_file }
	it { should be_readable }
end

describe pip('sexpdata') do 
	it { should be_installed }
end

describe pip('websocket-client') do 
	it { should be_installed }
end