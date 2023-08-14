#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Google Batch supports jobs with GPU, by indicating `INSTALL_GPU_DRIVERS` as true, Batch
# will fetch the drivers required for the GPU type that you specify in the policy field
# from a third-party location, and install them on your behalf. Otherwise, you need to
# install GPU drivers manually to use any GPUs for this job.
INSTALL_GPU_DRIVERS=true
# MACHINE_TYPE you choose must support the GPU type you want for this job.
# https://cloud.google.com/compute/docs/gpus
MACHINE_TYPE=n1-standard-1
# GPU_TYPE being used in this job.
GPU_TYPE=nvidia-tesla-t4
# GPU_COUNT being used in this job.
GPU_COUNT=1
# ALLOWED_LOCATION you choose must have the GPU type you want for this job.
# https://cloud.google.com/compute/docs/gpus/gpu-regions-zones
ALLOWED_LOCATION=regions/us-central1

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=gcs --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$INSTALL_GPU_DRIVERS','$MACHINE_TYPE','$GPU_TYPE','$GPU_COUNT','$ALLOWED_LOCATION' < ./gpu_job_with_driver_installation.json)
EOF