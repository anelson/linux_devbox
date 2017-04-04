# # encoding: utf-8

# Inspec test for recipe .::compile_vim

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/


describe command 'vim --version' do
	its('stdout') { should match /Vi IMproved 8.0/}
	its('stdout') { should match /\+X11/}
	its('stdout') { should match /\+python/}
end



