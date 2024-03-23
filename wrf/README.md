# Running the Weather Research and Forecasting model with Batch

In this example we'll run the [WRF](https://www.mmm.ucar.edu/models/wrf) model on several VMs as part of a tightly coupled Batch job. We'll create one machine manually (not as a node of a Batch job) and use that machine to arrange the necessary software and test data for WRF in a Filestore. Then we'll run a Batch job whose nodes mount the same Filestore to access that software and test data.

We'll use the [Google Cloud CLI](https://cloud.google.com/sdk/gcloud) (gcloud) to work with Batch and other Google Cloud features.

## Before you start

1. [Install](https://cloud.google.com/sdk/docs/install) and [initialize](https://cloud.google.com/sdk/docs/initializing) the Google Cloud CLI.
. Make sure that billing is enabled for your Cloud project. Learn how to [check if billing is enabled on a project](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled).

## Create a new project

We recommend creating a new project for this tutorial so that it doesn't affect any other existing projects you might have on Google Cloud. It is also easier to clean up resources when you finish.

To create a new project, run:

```
gcloud projects create [PROJECT_ID]
```

We'll use the `[PROJECT_ID]` you specified for the rest of this tutorial. To change the default project for `gcloud`, run:


```
gcloud config set project [PROJECT_ID]
```

See the document to learn more about [creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).


## Enable the Batch API

First, run the following command to enable the Batch API. You need to do this when you use Batch for the first time in a project.

```
gcloud services enable batch.googleapis.com
```

## Create the Filestore
Go to the [Filestore Instances](https://console.cloud.google.com/filestore/instances) page and create an SSD Filestore. Default size and settings are fine. Once it's allocated take note of its Location (e.g. us-central1-a) because we'll restrict Batch Nodes to that same location.

## Create the console machine
The Nodes of our Batch Job will run the CentOS 7 based HPC VM Image. Our console machine doesn't technically need to match those Nodes, but doing so simplifies our setup process a little.

```
gcloud compute instances create wrf-console \
  --zone=<wherever that Filestore ended up> \
  --image-family=hpc-centos-7 \
  --image-project=cloud-hpc-image-public \
  --machine-type=c2-standard-60 \
  --boot-disk-size=200GB
```

## Setup WRF
SSH to your console machine, mount the Filestore and cd to its mount path:

```
sudo -s
mkdir /mnt/share
mount -t nfs <Filestore IP>:/<Filestore share name> /mnt/share
cd /mnt/share
```

Make sure you have up to date Google Cloud CLI components

```
gcloud components update
```

and have set application default credentials.

```
gcloud auth login
```

The next step uses the [Spack package manager](https://spack.io/), which reqiures Python 3. You can check the version of Python on your login node with

```
python --version
```

If the version is less than three, install Python 3 and make sure that the "python" in your PATH points to python3 instead of python2.

```
sudo yum install python3
sudo rm /usr/bin/python
sudo ln -s /usr/bin/python3 /usr/bin/python
```

With Python 3 installed you can now set up a Spack environment and install WRF.

```
git clone -c feature.manyFiles=true https://github.com/spack/spack.git
cd spack
git checkout -b v0.21 origin/releases/v0.21
. share/spack/setup-env.sh
spack install --no-check-signature gcc@8.2.0
spack load gcc@8.2.0
spack compiler find
spack install intel-mpi@2018.4.274
spack install --no-check-signature wrf@3.9.1.1 build_type=dm+sm compile_type=em_real nesting=basic ~pnetcdf
spack load wrf
```

Get a small test data set. We'll try it right on the console VM before running a Batch job on a bigger data set.

```
wget http://www2.mmm.ucar.edu/wrf/bench/conus12km_v3911/bench_12km.tar.bz2
tar xjf bench_12km.tar.bz2
```

Set up a test directory

```
mkdir test
cd test
cp ../bench_12km/* .
WRF=`spack location -i wrf`
ln -s $WRF/run/* .
```

and you should be able to run wrf.exe on this test data (time in case you're interested in how long it takes, it should be about a minute and a half):

```
time mpirun -np 30 wrf.exe
```

Now let's get the bigger data set and run wrf.exe against it as part of a Batch Job

```
cd ..
wget https://www2.mmm.ucar.edu/wrf/bench/conus2.5km_v3911/bench_2.5km.tar.bz2
tar xjf bench_2.5km.tar.bz2
mkdir batch
cd batch
cp ../bench_2.5km/* .
WRF=`spack location -i wrf`
ln -s $WRF/run/* .
```

We can run wrf.exe on this just like the smaller set, but on a single c2-standard-60 it will take more than an hour.

## The Batch Job

This is the Batch Job (see job.yaml):

```
taskGroups:
  - taskSpec:
      runnables:
        - barrier:
            name: wait-all-vm-startup
        - script:
            text: |
              #!/bin/bash
              if [ $BATCH_NODE_INDEX = 0 ]; then
                . /mnt/share/spack/share/spack/setup-env.sh
                spack load gcc@8.2.0
                spack compiler find
                spack load wrf
                cd /mnt/share/batch
                mpirun -hostfile $BATCH_HOSTS_FILE -np 120 -ppn 30 $PWD/wrf.exe
              fi
        - barrier:
            name: wait-mpirun-finish
      volumes:
        - nfs:
            server: <YOUR FILESTORE IP ADDRESS>
            remote_path: <YOUR FILESTORE PATH>
          mount_path: /mnt/share
    task_count: 4
    task_count_per_node: 1
    require_hosts_file: true
    permissive_ssh: true
allocation_policy:
  instances:
    - policy:
        machine_type: c2-standard-60
        boot_disk:
          image: batch-hpc-centos
          size_gb: 200
  location:
    allowed_locations:
      - regions/us-central1
      - zones/us-central1-a
logs_policy:
  destination: CLOUD_LOGGING
```

This Job has a few special properties to facilitate running MPI:

1. We call mpirun with an explicit rank count and ranks-per-node, so we need to know exactly how many nodes will be allocated to the job.
   task_count=4 and task_count_per_node=1 ensures that we get exactly four nodes.
2. require_hosts_file=true causes each node to be equipped with a file listing all nodes in the same TaskGroup. This hosts file is at the path $BATCH_HOSTS_FILE.
3. permissive_ssh=true causes SSH to be configured on each node so that each node can SSH to each other node in the same TaskGroup,
   without a password. This allows mpirun to coordinate MPI processes across all nodes.
4. The "barrier" runnables before and after the main script cause the nodes in the job to synchronize. No node in the TaskGroup will move
   past a barrier until all the nodes have reached that same barrier. The first barrier causes the "driver" Node, with
   BATCH_NODE_INDEX=0 to wait for the other nodes to start up. The second barrier keeps the worker nodes from declaring their
   tasks "done" before the driver node's mpirun process has completed. This prevents the Batch autoscaler from potentially scaling down the TaskGroup's
   instance group.

With `job.yaml` copied to your console VM and the Filestore information filled in the job can be run with

```
gcloud batch jobs submit wrfmpi --location=us-central1 --config=job.yaml
```

The Job should be completed in about 25 minutes, and can be checked with

```
gcloud batch jobs describe projects/<YOUR PROJECT>/locations/us-central1/jobs/wrfmpi
```
