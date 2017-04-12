#
# Cookbook:: linux_devbox
# Recipe:: termite
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Compile termite the fancy terminal emulator from source
package 'termite-deps' do
  package_name ['libvte-2.91-dev',
    'autoconf',
    'libglib2.0-dev',
    'gtk-doc-tools',
    'libpcre2-dev',
    'libgirepository1.0-dev',
    'gperf',
    'libvte-dev',
    'valac',
    'unzip']

  action :install
end

ark "vte-ng" do
  url "https://github.com/thestinger/vte-ng/archive/0.46.1.a.zip"
  action :put
  path "#{Chef::Config[:file_cache_path]}"
end

bash 'compile-vte-ng' do
  cwd "#{Chef::Config[:file_cache_path]}/vte-ng"
  code <<-EOH
    bash autogen.sh
    make
    make install
    EOH
end

git "#{Chef::Config[:file_cache_path]}/termite-build" do
   repository node[:linux_devbox][:termite_git_repo]
   checkout_branch node[:linux_devbox][:termite_version]
   enable_submodules true
   action :sync
 end

 bash 'compile-termite' do
   cwd "#{Chef::Config[:file_cache_path]}/termite-build"
   code <<-EOH
     make
     make install
     [ -e /lib/terminfo/x/xterm-termite ] || \
       ln -s /usr/local/share/terminfo/x/xterm-termite /lib/terminfo/x/xterm-termite
     EOH
end