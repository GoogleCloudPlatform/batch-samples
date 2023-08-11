#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Artifact Registry Repository name
RepositoryName=my-repository
# Debian image
Image=debian:latest
# Turn OFF the allexport option
set +o allexport

# Image streaming is only available on v1alpha
gcloud alpha batch jobs submit --job-prefix=image-streaming --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$Location','$ProjectID','$RepositoryName','$Image' < ./image_streaming_simple_job.json)
EOF
