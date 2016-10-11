# Nomad Internal

This section provides a short introduction to Nomad and the Nomad Internals. For more information please refer to 
the [official site](https://www.nomadproject.io/)

## Nomad

Nomad is cluster and application management tool. Nomad enables users to declare what they want to run, and then decides
how and where to run these jobs.

Among the advantages of using Nomad can be found:

1.  Supports different task drivers like Docker, which facilitates the deployment of containerized applications to the cluster.
2.  Supports Linux, Windows, BSD and OSX.
3.  Supports global scale infraestructure.
3.1 Nomad models the infraestructure as groups of datacenters, which form a larger region.
3.2 Multi-region federation is also possible.
4. Combines features of schedulers and resource managers into a single system.

[Nomad Use Cases](https://www.nomadproject.io/intro/use-cases.html) mentions the multiple ways Nomad can be used.
[Nomad vs Others](https://www.nomadproject.io/intro/vs/index.html) provides a comparison of Nomad with other similar softwares.


## Nomad Internals

This section summarizes how Nomad works, its architecture and sub-systems.

### Infraestructure

Nomad models infraestructure as regions and datacenters. A region may contain multiple datacenters, servers and clients. Servers are responsible of handling the region state and scheduling decisions. On the other hand, clients are assigned to different datacenters within a region. They are in charge of running a group of tasks.

At a high level, a single region Nomad Cluster looks like this:

![image](https://www.nomadproject.io/assets/images/nomad-architecture-region-a5b20915.png)

A multi-region cluster, at a high level, looks like this:

![image](https://www.nomadproject.io/assets/images/nomad-architecture-global-a8f14b78.png)

Let's have a look at each element to understand more how they interact:

* Region:
    * Regions may be composed by multiple datacenters, servers and clients. 
    * Regions are fully independent from each other. In other words, they do not share
        state, clients nor jobs.
    * Users can submit requests to any region, and they are forwarded to the appropriate server. 
        This is thanks to the Gossip Protocol (see bellow).
    * Each region is expected to have 3 or 5 servers.

* Datacenters:
    * There can be multiple datacenters in a region.
    * There can be multiple clients in a datacenter.

* Servers:
    * Each region has a cluster of servers.
    * Servers manage all jobs and clients, run evaluations and create tasks allocations.
    * Servers use clients resources to make scheduling decisions and create allocations.
    * Servers consider jobs' constraints to find the optimal placement for each task.
    * Servers form a consensus group, where all work together and elect a leader which has extra duties.
        For instance, the leader provides additional coordination during scheduling.
    * Servers replicate data between each other.
    * Servers federate across regions to make Nomad globally awared.

* Clients:
    * Clients are machines that run groups of tasks.
    * Clients run a Nomad agent, which is responsible for registering with the servers,
        checking assigned work and executing the corresponding tasks.
    * Clients communicate with their servers using Remote Procedure Calls (RPC).
    * Clients provide available resources, attributes and installed drivers.

* Jobs:
    * Jobs are user workload specifications.
    * A job is considered a "desired state".
    * A job declaration does not specifies where to run the tasks. The responsibility resides on the servers.
    * A job is composed by one or more task groups.
    * Users make use of [Nomad CLI](https://www.nomadproject.io/docs/commands/index.html) or [API](https://www.nomadproject.io/docs/http/index.html) to submit jobs to servers.

* Task Group:
    * A task group is a set of tasks that must be run together.
    * A task group is the unit of scheduling. Hence, the group must be run on the same client.

* Evaluation:
    * Evaluations are the scheduling process.
    * A new evaluation is created every time a job is created or updated.
    * An evaluation determines if any actions must be taken.
    * An evaluation may change allocations.

* Allocation:
    * An allocation is the mapping between a task group and a Nomad client.
    * An allocation is created for every task group declared in a job.
    * Allocations are created by the servers as part of the scheduling process.

* Bin Packing:
    * Bin Packing is the process of filling bins with items, such that the utilization is maximized.
    * Client nodes are bins, and the group tasks are the items for Nomad.


### Consensus Protocol

The [CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem) that a distributed system cannot provide all three guarantees:
    * Consistency: every read receives the most recent write or an error.
    * Availability: every request receives a response; not necessarilly the most recent version.
    * Partition Tolerance: the system continues to operate despite arbitrary partitioning due to network failures.

    To guarantee Consistency Nomad uses the Consensus Protocol. This protocol is based on [Raft](https://media-api.atlassian.io/file/223578e2-b74c-44fc-aff4-3f9d74ff03a8/binary?token=eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiI1M2U1NGU4NC00NmY5LTRhNjAtYjQ4Yi1kOWQxN2Y2OTVlZmQiLCJhY2Nlc3MiOnsidXJuOmZpbGVzdG9yZTpmaWxlOjIyMzU3OGUyLWI3NGMtNDRmYy1hZmY0LTNmOWQ3NGZmMDNhOCI6WyJyZWFkIl19LCJleHAiOjE0NzYyMDAwNjEsIm5iZiI6MTQ3NjE5OTQwMX0.XG8xihPCBplLXiOQzEUAk8K0mfIZB8o8cnunAgrxkwQ&client=53e54e84-46f9-4a60-b48b-d9d17f695efd&name=raft.pdf).

    #### Raft Overview

    A consensus algorithm is necessary in order to have a coherent cluster, that works together and can survive failures of some members. A coherent group of nodes must have copies of the same "state" to guarantee Consistency. Raft implements distributed consensus by using a replicated log. Let's see how it works:

    Raft specifies three states for the cluster nodes. Every node starts in the "follower" state, where they recieve log entries from the "leader" and cast votes. Nodes self-promote to the "candidate" state if no entries are received in a time period. Candidate nodes request votes from their peers; all nodes participating in log replication. If a candidate receives the majority of votes from the peer set, it is promoted to "leader" state. The leader is responsible for accepting new log entries from a client, storing them, and replicating them to all the followers. Moreover, it manages when an entry is considered "committed". An entry is considered committed if it has been durably stored on a quorum of nodes. Once committed it can be applied. An illustrative example can be found [here](http://thesecretlivesofdata.com/raft/).

    Consensus is fault-tolerant while quorum is available. For instance, consider a cluster of two nodes A and B. The quorum size is also 2; hence, both nodes must agree to commit a log entry. If one of the node fails, it is impossible to have quorum. This results in unavailability, as no other nodes nor entries can be added. The only solution is then to remove and restart the nodes. Therefore, it is recommendable to have 3 to 5 nodes in a cluster, to maximize availability without compromising the performance. Check this [deployment table](https://www.nomadproject.io/docs/internals/consensus.html#deployment_table) for more details on different scenarios.

### Raft in Nomad

    In Nomad consensus is only necessary among server nodes. Remember that servers are responsible for keeping the global state of the cluster. Hence, they compose the peer set. When a request arrives to a non-leader server, it is forwarded to the leader. There can be two types of requests:
    * Query type: is read-only. The leader generates the result from the current state.
    * Transaction type: modifies the sate. The leader generates a new log entry and replicates it to the other nodes.

    In a multi-region scenario, each region elects its leader and maintains a disjoint peer set. A request can be submitted to any region, but it is forwarded to the correct leader. This allows lower latency transactions and higher availability.

    ### Consistency Modes
    * default: only the leader can service a read.
    * stale: allows any server to service a read. It allows that an unavailable cluster will still be able to respond.

### Gossip Protocol

Nomad uses this protocol to manage cluster membership. It is provided through the [Serf](https://www.serf.io/) library. The idea is that cluster members periodically exchange messages with each other. This allows a quick failure detection, by notifying all the cluster of failed members.

Nomad makes use of a WAN gossip pool, where all servers participate in. The protocol allows servers to:
    * Detect servers in the same region and perform automatic clustering.
    * Detect failures.
    * Do cross region requests.

### Scheduling

Scheduling is the process of assigning group tasks from jobs to the client nodes. As mentioned in "Infraestructure", jobs are workload declarations submitted by users. They represent a desired state. Jobs are composed by tasks, and the constraints and resources needed to run them. Given this declaration, the scheduling process creates and evaluation and determines the appropriate allocations.

Tasks are scheduled on clients of the cluster. This is done through the mapping of a set of tasks to a client node, which will run them. This mapping is refered as Allocation.

An evaluation is created every time the external state changes. There are two situations that produce this change. The first case happens when a job is submitted, updated or deregistered by a user. The second case occurs when a client fails. These events trigger the creation of a new evaluation, in order to achieve the desired state (represented by jobs). The next diagram illustrates the life cyle of an evaluation in Nomad:

![image](https://www.nomadproject.io/assets/images/nomad-evaluation-flow-7629d361.png)

Once an evaluation is created it is enqueued into the Evaluation Broker. Only the leader server runs this evaluation broker. Nomad servers run scheduling workers, which dequeue evaluations from the broker, and invoke the appropriate scheduler for the job.

There are 4 types of schedulers:
* Service: for long-lived services.
* Batch: for fast batch jobs.
* System: for running jobs on every node.
* Core: for internal maintenance.

Schedulers process the evaluation and generate an allocation plan. This may result on the creation of new allocations or in the update, migration or stop of current ones.

Placing allocations is divided in two phases:
1.  Feasibility Checking: the scheduler finds suitable nodes. Filters those that are unhealthy, that miss required drivers or do not satisfy constraints.

2. Ranking: the scheduler ranks the feasible nodes to find the best option. This is mainly based on the resource utilization (Bin Packing) and the density of the applications. The highest ranking node is then added to the allocation plan.

When the plan is complete, the scheduler sends it to the leader. Then, the plan is enqueued to the Plan Queue. The plan queue manages pending plans, provides priority ordering, and allows Nomad to handle concurrency races. The leader processes the plans and creates allocations if no conflict is found; otherwise, the scheduler is notified terminate or explore alternative plans. Finally nodes execute the allocations of the plans.