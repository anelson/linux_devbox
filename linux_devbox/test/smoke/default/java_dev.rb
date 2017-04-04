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

# There should be an sbt launcher script on the path
describe command('sbt') do 
	it { should exist }
end

# Can't actually run IDEA since it doesn't have a headless mode
# just make sure it's in the path and call it good
describe file('/opt/ideaIU/idea/bin/idea.sh') do 
	it { should exist }
end

