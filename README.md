# Nomad Cluster Setup
This demo shows hot to setup a simple [Nomad](https://www.nomadproject.io/) Cluster using [Vagrant](https://www.vagrantup.com/) and [Consul](https://www.consul.io/). Moreover, it provides a short introduction to [Nomad Internals](nomad-internals/README.md).

## Requirements
- Install Vagrant.
- Install a VM provider like VirtualBox. Other supported providers can be found [here](https://www.vagrantup.com/docs/providers/).

## Vagrant
[Vagrant](https://www.vagrantup.com/) provides easy to configure, reproducible, and portable work environments. 

The Vagrantfile creates 3 server nodes at "192.68.50.1{i}", where "i" goes from 1 to 3.
Additionally it creates one client node at "192.68.60.11", but it can be set to create more clients.
All the nodes are running on Ubuntu 14.04.5. Consul and Nomad are pre-installed on each VM.

To get started, run:
```
$ vagrant up
```

If successfull, you should be able to see the following:
```
$ vagrant status
Current machine states:

nomad-server1               running (virtualbox)
nomad-server2               running (virtualbox)
nomad-server3               running (virtualbox)
nomad-client1               running (virtualbox)
```

At this point all the nodes are running. You can interact with them through SSH like:
```
$ vagrant ssh nomad-server1
```

For more configuration details refer to the [getting started guide](https://www.vagrantup.com/docs/getting-started/).

To remove your environment simply do:
```
$ vagrant destroy -f
```

## Consul
[Consul](https://www.consul.io/) is a tool for discovering and configuring services. Its integration with Nomad facilitates the work.
This section explains how to create a Consul cluster. 

Start by setting up the Consul agents for each node created with Vagrant.

First the bootstrap server. Connect through SSH to "nomad-server1". Then, run the following setup:

```
# Bootstrap Server
---------------------------
$ cd /vagrant/consul
$ cp bootstrap.json config.json

# Save this keygen! Every node should have the same keygen.
$ consul keygen

# Setup configuration parameters:
# run ./setup.sh for details of the parameters
# Example: ./setup.sh consul-server1 PUwfIn0qT3gcssCNU0wN2Q== 192.68.50.11 192.68.50.12 192.68.50.13
$ ./setup.sh HOSTNAME ENCRYPT_KEY AGENT_IP OTHER_SERVER_IP OTHER_SERVER_IP

# Run the consul server:
$ consul agent --config-dir /vagrant/consul/config.json
```

Since we are configuring nomad-server1, we specified the IPs of nomad-server2 and nomad-server3. 
Hence, these values must be changed accordingly when starting the other two servers.

You can check the cluster members with:
```
$ consul members
Node            Address            Status  Type    Build  Protocol  DC
consul-server1  198.68.50.11:8301  alive   server  0.7.0  2         dc1
```

In the same we can setup the other nodes. First, connect through SSH to "nomad-server2".
```
# Non Bootstrap Server
---------------------------
$ cd /vagrant/consul
$ cp server.json config.json

# Setup configuration parameters:
# This time we use: 192.68.50.12 192.68.50.11 192.68.50.13
$ ./setup.sh HOSTNAME ENCRYPT_KEY AGENT_IP OTHER_SERVER_IP OTHER_SERVER_IP

# Run the consul server:
$ consul agent --config-dir /vagrant/consul/config.json
```
You do the same with nomad-server3 and nomad-client1. For the latter you must specify 
all the servers IPs in the ./setup.sh arguments:
```
$ ./setup.sh HOSTNAME ENCRYPT_KEY AGENT_IP SERVER1_IP SERVER2_IP SERVER3_IP
```

At the end you can see:
```
$ consul members
Node            Address            Status  Type    Build  Protocol  DC
consul-client1  192.68.60.11:8301  alive   client  0.7.0  2         dc1
consul-server1  192.68.50.11:8301  alive   server  0.7.0  2         dc1
consul-server2  192.68.50.12:8301  alive   server  0.7.0  2         dc1
consul-server3  192.68.50.13:8301  alive   server  0.7.0  2         dc1
```

The Consul agents configuration is done with the config files found in "/consul" folder.
For each agent we must specified configuration options like: the datacenter where the agent will run, 
its IP address, the directory to store data, among others. With ./setup.sh we set some of these options.
Nevertheless, you can modify the config files to suit your needs.

For more configuration details refer to the [getting started guide](https://www.consul.io/intro/getting-started/install.html).

Once the Consul agents are running we can create our Nomad Cluster.

EXTRA: Consul provides a [web UI](https://www.consul.io/intro/getting-started/ui.html) to view all nodes
and services, and health checks, among others.
To have access to the dashboard simply run one of the agents with the "-ui" parameter.
By default the UI is available in "http://localhost:8500/ui".

## Nomad
[Nomad](https://www.nomadproject.io/) is a tool for managing cluster of machines and running applications on them.
Wen Consul is integrated with Nomad the Nomad Cluster gains the ability to bootstrap itself as well as provide service and health check registration to applications.

This section shows how to create a Nomad Cluster integrated with Consul.

Lets start by creating the agents in each node.
```
# Nomad Server
---------------------------
$ cd /vagrant/nomad
$ cp base_config.hcl config.hcl

# Setup server IP address in config file:
# run ./setup.sh for details of the parameters
# Example: ./setup.sh 192.68.50.11 /vagrant/nomad/config.hcl
$ ./setup.sh SERVER_IP CONFIG_PATH

# Run the nomad server:
$ nomad agent -config /vagrant/nomad/config.hcl -config server.hcl
```

We do this for every Nomad server (1, 2 and 3), providing the corresponding IP address. In the same way we start the client agent:
```
# Nomad Client
---------------------------
$ cd /vagrant/nomad
$ cp base_config.hcl config.hcl

# Setup client IP address in config file:
# Example: ./setup.sh 192.68.60.11 /vagrant/nomad/config.hcl
$ ./setup.sh SERVER_IP CONFIG_PATH

# Run the nomad server:
$ nomad agent -config /vagrant/nomad/config.hcl -client.hcl
```
With the given configuration all the agents register automatically with Consul and discover other Nomad servers.
If the agent is a server it will join the quorum to vote for a leader. If it is a client it will register itself and join the cluster.

When bootstrapping without Consul, Nomad agents must be started by knowing the address of at least one Nomad server.
For configuration details please refer to the [guide](https://www.nomadproject.io/docs/cluster/bootstrapping.html).

Once we finish we can check the agents in two ways:

1. The cluster servers:
```
$ nomad server-members -address="nomad-agent-http-adress:nomad-agent-http-port"
Name                  Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
nomad-server1.europe  192.68.50.11  4648  alive   true    2         0.4.1  dc1         europe
nomad-server2.europe  192.68.50.12  4648  alive   false   2         0.4.1  dc1         europe
nomad-server3.europe  192.68.50.13  4648  alive   false   2         0.4.1  dc1         europe
```
If you do not specify the "-address" parameter, you may encounter an issue. For default it takes the 
loopback address instead of the bind address set in the config files. Example: -address="http://192.68.50.11:4646".

2. The cluster clients:
```
# This will show the list of all clients if you do not specify an ID.
$ nomad node-status -address="nomad-agent-http-adress:nomad-agent-http-port"
ID        DC   Name           Drain  Status
a72dfba2  dc1  nomad-client1  false  ready
```

Once our Nomad cluster is created we can start interacting with it. The next sections shows how to run jobs in the cluster.

## Scheduling

Scheduling is the process of assigning tasks from jobs to client machines. The process must respect
the constraints defined in the job description, and optimize for resource utilization. To understand how 
this core function works in Nomad, please have a look to the [Consul Internals](nomad-internals/README.md) section.

Nomad comes with a Job template that illustrates how to configure tasks, constraints and resource allocation.
To create the example run the following, in one of the server nodes:
```
$ nomad init
```
This creates a "example.nomad" file in the current directory. You can see that the job declares a 
single task called "redis", and uses the Docker driver to run it.

In order to be sure our Job is ready to be run, we can do the following:
1. Validation: checks for syntax errors or validation problems
```
$ nomad validate <job_file>
# If no issues, the output is:
Job validation successful
```
2. Planification: determines what would happen if the job is submitted.
```
$ nomad plan <job_file>
# The output should be similar to:
+ Job: "example"
+ Task Group: "cache" (1 create)
  + Task: "redis" (forces create)

Scheduler dry-run:
- All tasks successfully allocated.

Job Modify Index: 0
To submit the job with version verification run:

nomad run -check-index 0 /vagrant/nomad/example.nomad

When running the job with the check-index flag, the job will only be run if the
server side version matches the the job modify index returned. If the index has
changed, another user has modified the job and the plan's results are
potentially invalid.
```

If no problem arises we can run the job with:
```
$ nomad run <job_file>
# The output should be similar to:
==> Monitoring evaluation "d0141f9e"
    Evaluation triggered by job "example"
    Allocation "51d89e58" created: node "4dd1439b", group "cache"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "d0141f9e" finished with status "complete"
```

The same command can be used to update the job. Each time, Nomad creates and evaluation that determines
the set of actions to take place. Given that this is a new job, Nomad decided to create an allocation and
assign it to the client node.

To check the status of a Job use:
```
$ nomad status
# The output should be similar to:
ID       Type     Priority  Status
example  service  50        running
```

To check how many running allocations a node client has use:
# This will show the list of all clients if you do not specify an ID.
$ nomad node-status -address="nomad-agent-http-adress:nomad-agent-http-port"
ID        DC   Name           Class   Drain  Status  Running Allocs
a72dfba2  dc1  nomad-client1  <none>  false  ready   1
```


Note: the parameter "-address" should be also specified.

Using Jobs is a good way to test that your Nomad cluster is working as expected.

To learn more about Nomad please check the [Nomad Internals](nomad-internals/README.md) section and the [official site](https://www.nomadproject.io/).
