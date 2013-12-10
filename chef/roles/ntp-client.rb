name "ntp-client"
description "NTP Client Role - NTP client for the cloud"
run_list(
  "recipe[ntp]"
)
default_attributes()
override_attributes()
