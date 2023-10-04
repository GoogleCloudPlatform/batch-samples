## Overview
Google Batch supports jobs using [Cloud Storage bucket(s)](https://cloud.google.com/storage)
as the storage volume. It helps mount existing buckets or its folders for you.

## Prerequisites
* Create a Cloud Storage bucket.
* Fill in the values for variables for the samples in `submit.sh`.

## GCS Samples
### job_with_gcs_volume.json
This script job echoes `hello world` to
${MOUNT_PATH}/output_task_${BATCH_TASK_INDEX}.txt file for each task.