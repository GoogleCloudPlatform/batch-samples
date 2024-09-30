# Introduction
This example shows how to run a simple multi-node MPI job with Batch. You can run the sample job with

```
$ gcloud batch jobs submit mpi-container-test \
  --project=<your project> \
  --location=<any region> \
  --config=job.yaml
```

The job will allocate two nodes and execute "hostname" on both nodes with MPI, using the [MPICH](https://www.mpich.org/) implementation.

# Explanation of the job spec

The Batch job is configured in the file job.yaml. The job is configured to run two tasks with one task per node, meaning that Batch will create two nodes for the job. Each task begins by running the script `apt-get install --yes --no-install-recommends mpich`, to install MPICH. In a "real" job the entire software stack would probably be prepared ahead of time in a shared volume or on a custom boot image for the job's VMs, but installing MPI as part of the job means the sample can run with no external infrastructure prepared ahead of time.

The barrier named "vms-ready" prevents either node from executing the second script before both nodes have finished the first script. Both nodes execute the second script, but only the node with the Batch-provided environment variable BATCH_NODE_INDEX = 0 will call `mpirun`. The mpirun command spawns MPI processes on both nodes, calling hostname.

The barrier named "finish-mpi" prevents either node from declaring its task "done" before both nodes have completed the second script. This ensures that Batch will not scale down the node with BATCH_NODE_INDEX = 1 while mpirun is still working. It's unlikely that the node would be scaled down before a simple "hostname" script completes, but preventing scaledown can be important for jobs with long-running MPI processes and a large number of tightly coupled nodes.

The job includes the options "requireHostsFile" and "permissiveSsh". The first causes Batch to prepare a hosts file (at the path $BATCH_HOSTS_FILE), listing all the hostnames of all the nodes allocated to the job. The second causes Batch to configure shared SSH keys on all nodes so that the root user can SSH between nodes allocated to the job without entering a password. This is required for mpirun to connect to the second node and spawn a process.