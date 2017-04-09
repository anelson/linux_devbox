# # encoding: utf-8

# Inspec test for recipe .::fonts

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe command 'fc-list FontAwesome' do
	its('stdout') { should match /opentype\/FontAwesome/ }
end
