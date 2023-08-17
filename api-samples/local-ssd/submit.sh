#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# DEVICE_NAME is the device name of local ssds.
DEVICE_NAME=mylocalssd
# MACHINE_TYPE is the machine type you want to use for this job.
# The allowed number of local SSDs depends on the machine type.
MACHINE_TYPE=n1-standard-1
# Mount path of the volume.
MOUNT_PATH=/mnt/disks/localssd
# LOCAL_SSD_SIZE is the size of local ssd volume required. It should
# be a multiple of 375 GB.
LOCAL_SSD_SIZE=750

# Turn OFF the allexport option.
set +o allexport

gcloud batch jobs submit --job-prefix=localssd --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$DEVICE_NAME','$MACHINE_TYPE','$MOUNT_PATH','$LOCAL_SSD_SIZE' < ./job_with_local_ssd_volume.json)
EOF