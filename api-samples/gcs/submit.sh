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
# Mount options. Availble options can be found here: https://cloud.google.com/storage/docs/gcsfuse-cli.
# You can have multiple mount options by adding elements to the mountOptions list in job_with_gcs_volume.json.
MOUNT_OPTIONS="--max-conns-per-host 200"

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=gcs --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$REMOTE_PATH','$MOUNT_PATH','$MOUNT_OPTIONS' < ./job_with_gcs_volume.json)
EOF