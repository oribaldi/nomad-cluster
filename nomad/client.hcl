# ----------- Client Configuration -----------

# Datacenter to register the client
datacenter = "dc1"

client {
  # Enable client mode for the local agent
  enabled = true

  # Reserve a portion of the nodes resources
  # from being used by Nomad when placing tasks.
  # For example:
  # reserved {
  #     cpu = 500 # MHz
  #     memory = 512 # MB
  #     disk = 1024 # MB
  #     reserved_ports = "22,80,8500-8600"
  # }
}