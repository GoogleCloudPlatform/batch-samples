# Introduction
This example shows how to run a multi-node containerized MPI job with Batch. To run the example you will need to build a container image and push it to the [Artifact Registry](https://cloud.google.com/artifact-registry),
where it can be pulled as needed by Batch.

A Dockerfile for a suitable minimal docker image is provided in the Container directory. You can build the image by cd'ing to the Container directory and running

```
docker build .
```

The image includes [MPICH](https://www.mpich.org/) and and [OpenSSH](https://www.openssh.com/) client and server, along with two small shell scripts.

1. A script to configure the SSH client and SSH server to use port 5000 (instead of the default 22) and to then run the SSH server.
2. A script to execute a simple MPI command, which causes each node in the Batch job to run "hostname".

After building the docker image you must tag it and push it to a repository in the Artifact Registry, then modify the template job.yaml file to point at your image.

# Job overview

The Batch job is configured in the file job.yaml. The job allocates two nodes for two tasks (one task per node) and each task runs two containers based off of the same image. The first container runs an SSH server peristently in the background, listening on port 5000 (instead of the default 22). The second container executes the "real" MPI command on whichever of the two nodes has the Batch provided environment variable BATCH_NODE_INDEX=0.

When the second container calls mpirun, that command attempts to connect to the other node via SSH in order to create an MPI process on that node. It is necessary for the first node's SSH to "land" inside the container running on the second node, rather than on the host VM. Therefore both VMs have one container running an SSH server on a non-standard port, and whichever VM happens to have BATCH_NODE_INDEX=0 also connects via SSH on that same port.

The host VM continues to run its own SSH server on port 22. That is not used by the Batch job, but it's useful in case you need to SSH into the host VM for debugging.

The Batch job uses two barriers, name "vms-ready" and "finish-mpi". The first barrier prevents either VM from executing the second container before *both* VMs have executed the first container. The second barrier prevents either VM from declaring it's assigned task "done" before the MPI-running second container has completed. This prevents Batch from scaling down the node with BATCH_NODE_INDEX=1. It's unlikely that Batch would scale down the second node before a simple "hostname" command had time to complete, but preventing scaling down can be important for long-running jobs with many tightly coupled nodes.

The Batch job uses two options to simplify the MPI command: requireHostsFile and permissiveSsh. These cause Batch to generate a hosts file (at /etc/cloudbatch-taskgroup-hosts) with the hostnames of all the nodes allocated to the job, and to configure SSH keys on all nodes so that the root user can SSH between nodes without entering a password. The container configurations in the job spec grant the containers access to paths on the host VM so that the containers can see the Batch generated host file and shared SSH keys, and all containers are configured to use the "host" network so that MPI can access whichever ports it needs (5000 for SSH and then a range of other ports for communication between MPI processes).

The job is configured to use a Batch-provided Debian-based VM boot image rather than a COS-based image, which is the default for container based jobs. The COS-based image would require
additional work within the Batch job to modify firewall settings, in order to allow MPI interprocess communication. The Debian image has suitable firewall settings by default.

# Running the job

After pushing your container image to the Artifact Registry and updating job.yaml to point to your image, you can run the job with

```
$ gcloud batch jobs submit mpi-container-test \
  --project=<your project> \
  --location=<any region> \
  --config=job.yaml
```

The job will appear in the Pantheon UI after a few moments and you can monitor its progress, and output logs from there. If everything goes well the output logs will eventualy include two entries with the hostnames of the nodes allocated to the job.
