## GCS examples

Google Batch supports jobs using a Cloud Storage bucket as the storage volume.
It mounts buckets with existing prefixes which allows you to access the existing
files in subfolders of the bucket.

For detailed information on each field, please refer to

*   official guide:
    https://cloud.google.com/batch/docs/create-run-job-storage#use-bucket

*   official api doc: https://cloud.google.com/batch/docs/reference/rest

### mount_a_gcs_bucket.json

This script job echoes hello world to
MOUNT_PATH/output_task_${BATCH_TASK_INDEX}.txt file for each task.

### access_a_sub_folder_in_gcs_bucket.json

This script job echoes hello world to
MOUNT_PATH/{SUB_FOLDER}/output_task_${BATCH_TASK_INDEX}.txt file for each task.

## Run an example

```
gcloud batch jobs submit $JOB_NAME \
--config $EXAMPLE_FILE_NAME.json \
--location $LOCATION
```
