## Overview
Google Batch supports jobs using local SSDs as the storage volume. Each local SSD
is 375 GB, so the size of the local SSDs required in total must be a multiple of
375 GB. For example, for 2 local SSDs, set this value to 750 GB.

## Prerequisites
* Check your project has [enough quota](https://cloud.google.com/compute/resource-usage#disk_quota) for local ssds.
* Fill in the values for variables for the samples in `submit.sh`.

## LocalSSD Samples
### job_with_local_ssd_volume.json
This script job echoes `hello world` to ${MOUNT_PATH}/output_task_${BATCH_TASK_INDEX}.txt
file for each task.