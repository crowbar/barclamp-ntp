name "ntp-server"
description "NTP Server Role - NTP master for the cloud"
run_list(
  "recipe[ntp]"
)
default_attributes()
override_attributes()
