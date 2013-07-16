# Copyright 2011, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node["roles"].include?("ntp-client")
  unless Chef::Config[:solo]
    env_filter = " AND environment:#{node[:ntp][:config][:environment]}"
    servers = search(:node, "roles:ntp\\-server#{env_filter}")
  end
  ntp_servers = nil
  ntp_servers = servers.map {|n| n["fqdn"] } unless servers.nil?
else
  ntp_servers = node[:ntp][:external_servers]
end

if node[:platform]=="windows"
  #for windows

  service "w32time" do
    action :stop
  end

  ntplist=""
  unless ntp_servers.nil? or ntp_servers.empty?
    ntp_servers.each do |ntpserver|
      ntplist += "#{ntpserver},0x1 "
    end
    execute "update_timezone" do
      command "w32tm.exe /config /manualpeerlist:\"ntplist\" /syncfromflags:MANUAL"
    end

    execute "update_timezone" do
      command "w32tm.exe /config /update"
    end

    service "w32time" do
      action :start
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
  template "/etc/ntp.conf" do
    owner "root"
    group "root"
    mode 0644
    source "ntp.conf.erb"
    variables(:ntp_servers => ntp_servers,
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
    supports :restart => true, :status => true, :reload => true
    running true
    enabled true
    action [ :enable, :start ]
  end
end

