# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# Change these options to your
#
config :nerves, :firmware,
  fwup_conf: "config/fwup.conf"

config :nerves, :firmware,
  rootfs_additions: "rootfs-additions"

config :nerves_ntp, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org", 
    "2.pool.ntp.org", 
    "3.pool.ntp.org"
  ]

import_config "#{Mix.env}.exs"
