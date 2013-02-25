
name "ntp-client"
description "NTP Client Role - NTP client for the cloud points to Master"
run_list(
         "recipe[ntp]"
)
default_attributes "ntp" => { "config" => { "environment" => "ntp-base-config" } }
override_attributes()

