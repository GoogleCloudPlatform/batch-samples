#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# Ref: https://cloud.google.com/batch/docs/create-run-job-custom-boot-disks#create-run-job-custom-boot-disk.
# -----------------------------------------
# Boot Disk Image URI path, or in short.
BootDiskImage=batch-centos
# Boot Disk Size, no smaller than the default disk size 30GB.
BootDiskSize=50
# Boot Disk Type, either pd-standard, pd-balanced, pd-ssd, or pd-extreme.
BootDiskType=pd-standard

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=bootdisk --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$BootDiskImage','$BootDiskSize','$BootDiskType' < ./job_with_custom_boot_disk.json)
EOF
