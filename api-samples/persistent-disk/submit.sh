#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Mount path.
MOUNT_PATH=/mnt/disks/pd
# For `job_with_existing_pd_volume.json`, existing disk is ro.
# For `job_with_new_pd_volume.json`, it can be mount option from https://man7.org/linux/man-pages/man8/mount.8.html.
MOUNT_OPTIONS=rw,async
# DEVICE_NAME is the device name of the disk.
DEVICE_NAME=device
# NEW_DISK_SIZE is the size of the new persistent disk in GB. The allowed sizes depend on the type
# of persistent disk, but the minimum is often 10 GB (10) and the maximum is often 64 TB (64000).
NEW_DISK_SIZE=120
# NEW_DISK_TYPE is the disk type of the new persistent disk, either `pd-standard`, `pd-balanced`, `pd-ssd`, or `pd-extreme`.
NEW_DISK_TYPE=pd-balanced
# EXT_DISK_SELF_LINK is the self link of an existing disk.
# For regional disk, it looks like "projects/myproject/regions/us-central1/disks/epd".
# For zonal disk, it looks like "projects/myproject/zones/us-central1-a/disks/epd".
EXT_DISK_SELF_LINK=projects/myproject/regions/us-central1/disks/existingpd
# ALLOWED_REGION and ALLOWED_ZION compose the allowed locations for the job.
# For `job_with_existing_pd_volume.json`:
# - For each existing zonal persistent disk, the job's location must be the disk's zone;
# - For each existing regional persistent disk, the job's location must be either the disk's region
# or, if specifying zones, one or both of the specific zones where the regional persistent
# disk is located.
# For `job_with_new_pd_volume.json`:
# -  ALLOWED_REGION and ALLOWED_ZONE compose the allowed locations for the new disk.
ALLOWED_REGION=regions/us-central1
ALLOWED_ZONE=zones/us-central1-a

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=epd --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$DEVICE_NAME','$MOUNT_PATH','$EXT_DISK_SELF_LINK','$ALLOWED_REGION','$ALLOWED_ZONE' < ./job_with_existing_pd_volume.json)
EOF

gcloud batch jobs submit --job-prefix=npd --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$DEVICE_NAME','$MOUNT_PATH','$MOUNT_OPTIONS','$NEW_DISK_SIZE','$NEW_DISK_TYPE','$ALLOWED_REGION','$ALLOWED_ZONE' < ./job_with_new_pd_volume.json)
EOF