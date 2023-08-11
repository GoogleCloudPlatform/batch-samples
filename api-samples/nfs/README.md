## Overview
Google Batch supports jobs using an existing network file system (NFS), such
as a [Filestore file share](https://cloud.google.com/filestore) as the storage
volume.

## Prerequisites
* Create a Filestore instance, make sure that its network is properly configured
to allow traffic between Batch job's VMs and the NFS. For more information, please
see [Configuring firewall rules for Filestore](https://cloud.google.com/filestore/docs/configuring-firewall).
* Fill in the values for variables for the samples in `submit.sh`.

## NFS Samples
### job_with_nfs_volume.json
This script job echoes `hello world` to
${MOUNT_PATH}/output_task_${BATCH_TASK_INDEX}.txt file for each task.