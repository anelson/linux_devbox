# # encoding: utf-8

# Inspec test for recipe linux_devbox::termite

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe command('termite') do
  it { should exist }
end
