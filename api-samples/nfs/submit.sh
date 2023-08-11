#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# SERVER is the IP address of the Filestore instance.
SERVER=10.103.138.186
# Remote path is source path extracted from NFS.
# For example, the file share name of Filestore.
REMOTE_PATH=/my_file_share_name
# Mount path.
MOUNT_PATH=/mnt/disks/nfs

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=nfs --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$SERVER', '$REMOTE_PATH','$MOUNT_PATH' < ./job_with_nfs_volume.json)
EOF