#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Remote path is the Cloud Storage bucket name. If you want to mount a sub directory,
# you can also set the path as ${BucketName}/${SubDirctory} directly.
REMOTE_PATH=my-bucket-name
# Mount path.
MOUNT_PATH=/mnt/disks/gcs

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=gcs --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$REMOTE_PATH','$MOUNT_PATH' < ./job_with_gcs_volume.json)
EOF