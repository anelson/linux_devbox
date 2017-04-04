# # encoding: utf-8

# Inspec test for recipe linux_devbox::java_dev

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe command 'java -version' do
	its('stderr') { should match /openjdk version "1.8.0/}
end

describe package('sbt') do
	it { should be_installed }
end

