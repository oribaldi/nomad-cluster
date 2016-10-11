# ----------- Base Cluster Configuration -----------

# Name the region, if omitted, the default "global" region will be used.
region = "europe"

# Persist data to a location that will survive a machine reboot.
data_dir = "/var/lib/nomad/"

# Bind to all addresses so that the Nomad agent is available 
# both on loopback and externally.
bind_addr = "127.0.0.1"

# Set the bind address
addresses {
    http = "__IP_ADDRESS__"
    rpc = "__IP_ADDRESS__"
    serf = "__IP_ADDRESS__"
}

# Advertise an accessible IP address so the server is reachable by other servers
# and clients. The IPs can be materialized by Terraform or be replaced by an
# init script.
advertise {
    http = "__IP_ADDRESS__:4646"
    rpc = "__IP_ADDRESS__:4647"
    serf = "__IP_ADDRESS__:4648"
}

# Network ports can be also set. The default values are:
# ports {
#   http = 4646
#   rpc = 4647  # only server nodes
#   serf = 4648 # only server nodes
# }

# Log verbosity (INFO, DEBUG)
log_level = "DEBUG"

# Ship metrics to monitor the health of the cluster and 
# to see task resource usage.
#telemetry {
#    statsite_address = "${var.statsite}"
#    disable_hostname = true
#}

# Enable debug endpoints.
enable_debug = true

# Consul Configuration
consul {
  # Consult agent's HTTP Address
  address = "127.0.0.1:8500"

  # The service name to register the server and client with Consul.
  server_service_name = "nomad"
  client_service_name = "nomad-client"

  # Auth info for http access
  #auth = user:password

  # Advertise Nomad services to Consul
  # Enables automatically registering the services
  auto_advertise = true

  # Enables the servers and clients bootstrap using Consul
  server_auto_join = true
  client_auto_join = true
}