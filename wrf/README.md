# Running the Weather Research and Forecasting model with Batch

In this example we'll run the WRF model on several VMs as part of a tightly coupled Batch Job. We'll create one machine manually (not as a Node of a Batch Job) to act as a console, and use that machine to arrange the necessary software and test data for WRF in a Filestore. Then run a Batch Job whose Nodes mount the same Filestore to share the software and test data.

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
Go to the [Filestore Instances](https://pantheon.corp.google.com/filestore/instances) page and create an SSD Filestore. Default size and settings are fine. Once it's allocated take note of its Location (e.g. us-central1-a) because we'll restrict Batch Nodes to that same location.

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

Install the Spack environment and use that to download, build, and install WRF. We'll use a build cache from Cloud Days 22 to make this go faster:

```
git clone -c feature.manyFiles=true https://github.com/spack/spack.git
. spack/share/spack/setup-env.sh
spack mirror add gcs https://storage.googleapis.com/pnnl-clouddays22-workshop
spack buildcache keys --install --trust
spack install gcc@8.2.0
spack load gcc@8.2.0
spack compiler find
spack install intel-mpi@2018.4.274
spack install wrf@3.9.1.1 build_type=dm+sm compile_type=em_real nesting=basic ~pnetcdf
spack load wrf
```

Get a small test data set (we'll try it right on the console VM before running a Batch Job for a bigger data set).

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

We need an instance template to point our Batch Job at the HPC VM Image

```
gcloud compute instance-templates create wrf-worker --image-family=hpc-centos-7 --image-project=cloud-hpc-image-public --machine-type=c2-standard-60 --boot-disk-size=200GB
```

and (to make the Batch Job configuration a little cleaner) we can store the main workload script in a separate file, at `/mnt/share/batch/runsim.sh`:

```
#!/bin/bash
if [ $BATCH_TASK_INDEX = 0 ]; then
  . /mnt/share/spack/share/spack/setup-env.sh
  spack load gcc@8.2.0
  spack compiler find
  spack load wrf
  cd /mnt/share/batch
  mpirun -hostfile $BATCH_HOSTS_FILE -np 120 -ppn 30 $PWD/wrf.exe
fi
```

This is the Batch Job (see job.json):

```
{
  "taskGroups":[{
    "task_spec":{
      "runnables":[
        { "barrier": {} },
        {
          "script": {
            "path":"/mnt/share/batch/runsim.sh"
          }
        },
        { "barrier": {} }
      ],
      "volumes":[{
        "nfs":{
          "server":"<YOUR FILESTORE IP ADDRESS>",
          "remote_path": "<YOUR FILESTORE PATH>"
        },
        "mount_path": "/mnt/share"
      }]
    },
    "task_count":4,
    "task_count_per_node": 1,
    "require_hosts_file": true,
    "permissive_ssh": true
  }],
  "allocation_policy": {
    "instances": [{
      "instance_template": "projects/<YOUR PROJECT ID>/global/instanceTemplates/wrf-worker"
    }],
    "location": {
      "allowed_locations": [ "<YOUR FILESTORE'S REGION, e.g. reiongs/us-central1>", "<YOUR FILESTORE'S ZONE, e.g. zones/us-central1-a>" ]
    }
  },
  "logs_policy": {
    "destination": "CLOUD_LOGGING"
  }
}
```

This Job has a few special properties to facilitate running MPI:

1. We call mpirun with an explicit rank count and ranks-per-node, so we need to know exactly how many Nodes will be allocated to the Job.
   task_count=4 and task_count_per_node=1 ensures that we get exactly four Nodes.
2. require_hosts_file=true causes each Node to be equipped with a file listing all Nodes in the same TaskGroup.
   We'll pass this to mpirun with the $BATCH_HOSTS_FILE environment variable.
3. permissive_ssh=true causes SSH to be configured on each Node of our Job, so that each Node can SSH to each other Node in the same TaskGroup,
   without a password. This allows the MPI processes spawned by mpirun to communicate between Nodes.
4. The "barrier" Runnables before and after the `runsim.sh` script cause the Nodes in the Job to synchronize. No Node in the TaskGroup will move
   past a barrier until all the Nodes in the TaskGroup have reached that same barrier. The first barrier causes the "driver" Node, with
   BATCH_TASK_INDEX=0, which calls mpirun, to wait for the other Nodes to start up. The second barrier keeps the worker Nodes from declaring their
   Tasks "done" before the driver Node's mpirun process has completed. This prevents the Batch autoscaler from potentially scaling down the TaskGroup's
   instance group.

With `job.json` copied to your console VM (or your mounted Filestore), and the Filestore IP and path, and project ID filled in, the Job can be run with

```
gcloud batch jobs submit wrfmpi --location=us-central1 --config=job.json
```

The Job should be completed in about 25 minutes, and can be checked with

```
gcloud batch jobs describe projects/<YOUR PROJECT>/locations/us-central1/jobs/wrfmpi
```
