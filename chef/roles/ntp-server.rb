
name "ntp-server"
description "NTP Servier Role - NTP master for the cloud"
run_list(
         "recipe[ntp]"
)
default_attributes "ntp" => { "external_servers" => [], "config" => { "environment" => "ntp-base-config" } }
override_attributes()

