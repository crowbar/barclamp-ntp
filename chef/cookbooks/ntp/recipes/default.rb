#
# Copyright 2011-2013, Dell
# Copyright 2013-2014, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

unless Chef::Config[:solo]
  env_filter = " AND environment:#{node[:ntp][:config][:environment]}"
  servers = search(:node, "roles:ntp\\-server#{env_filter}")
else
  servers = []
end
ntp_servers = []
servers.each do |n|
  ntp_servers.push n[:crowbar][:network][:admin][:address] if n.name != node.name
end
if node["roles"].include?("ntp-server")
  ntp_servers += node[:ntp][:external_servers]
  is_server = true
end

if node[:platform]=="windows"
  #for windows

  unless ntp_servers.nil? or ntp_servers.empty?
    ntplist=""
    ntp_servers.each do |ntpserver|
      ntplist += "#{ntpserver},0x1 "
    end
    execute "update ntp list for w32tm" do
      command "w32tm.exe /config /manualpeerlist:\"" + ntplist + "\" /syncfromflags:MANUAL"
    end

    service "w32time" do
      action :start
    end

    # in case the service was already started, tell it the config has changed
    execute "tell w32tm about updated config" do
      command "w32tm.exe /config /update"
    end
  else
    service "w32time" do
      action :stop
    end
  end

else
  #for linux
  package "ntp" do
    action :install
  end

  driftfile = "/var/lib/ntp/ntp.drift"
  driftfile = "/var/lib/ntp/drift/ntp.drift" if node[:platform] == "suse"

  user "ntp"

  admin_interface = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address

  template "/etc/ntp.conf" do
    owner "root"
    group "root"
    mode 0644
    source "ntp.conf.erb"
    variables(:ntp_servers => ntp_servers,
            :admin_interface => admin_interface,
            :is_server => is_server,
            :fudgevalue => 10,
            :driftfile => driftfile)
    notifies :restart, "service[ntp]"
  end

  #
  # Make sure the ntpdate helper is removed to speed up network restarts
  # This script manages ntp for the client
  #
  file "/etc/network/if-up.d/ntpdate" do
    action :delete
  end if ::File.exists?("/etc/network/if-up.d/ntpdate")

  service "ntp" do
    service_name "ntpd" if node[:platform] =~ /^(centos|redhat)$/
    service_name "ntpd" if node[:platform] == "suse" && node[:platform_version].to_f >= 12.0
    supports :restart => true, :status => true, :reload => true
    running true
    enabled true
    action [ :enable, :start ]
  end
end

