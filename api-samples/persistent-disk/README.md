## Overview
Google Batch supports jobs using persistent disks as the storage volume.

Each persistent disk in a job can be either new (defined in and created with the
job) or existing (already created in your project and specified in the job). To
use an existing persistent disk, you must format it to ext4 and unmount it before
using in Batch. Batch formats and mounts any new persistent disks that you include
in a job.

## Prerequisites
* If you are going to test `job_with_existing_pd_volume.json`, please create an existing
persistent disk in ext4 format and umount it before using it in Batch.
* Fill in the values for variables for the samples in `submit.sh`.

## PD Samples
### job_with_existing_pd_volume.json
This script job echoes `hello world` to
${MOUNT_PATH}/output_task_${BATCH_TASK_INDEX}.txt file for each task.

### job_with_new_pd_volume.json
This script job echoes `hello world` to
${MOUNT_PATH}/output_task_${BATCH_TASK_INDEX}.txt file for each task.