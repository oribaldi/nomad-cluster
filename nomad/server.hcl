# ----------- Server Configuration -----------

server {
  # Enable server mode for the local agent
  enabled = true

  # Number of server nodes to wait for before
  # bootstrapping, depending on cluster size
  bootstrap_expect = 3
}