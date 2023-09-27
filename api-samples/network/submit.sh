#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
#
# Variables for job_with_custom_network.json
# Ref: https://cloud.google.com/batch/docs/specify-job-network.
#
# The project ID of the project for the network you specify.
# If you are using a Shared VPC network, specify the host project.
# Otherwise, specify the current project.
HOST_PROJECT_ID=batch-api-samples
# The name of a VPC network in the host project.
NETWORK=batch-network
# The region where the subnet and the VMs for the job are located.
REGION=us-central1
# The name of a subnet that is part of the VPC network and is located
# in the same region as the VMs for the job.
SUBNET=batch-subnet
# Boolean to decide whether uses exteranl IP address or not.
# Default is false. Required if no external IP address is attached to the VM.
# If no externalpublic IP address, additional configuration is required to allow
# the VM to access Google Services.
# See https://cloud.google.com/vpc/docs/configure-private-google-access and
# https://cloud.google.com/nat/docs/gce-example#create-nat for more information.
NO_EXTERNAL_IP_ADDRESS=true
#
# Variables for container_job_block_external_network.json
# Ref: https://cloud.google.com/batch/docs/job-without-external-access#create-job-block-external-access-containers/
# The URI to pull the container image from.
CONTAINER_IMAGE_URI=busybox
# Boolean to decide whether blocks external access for the container.
BLOCK_EXTERNAL_NETWORK=true

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=network --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$HOST_PROJECT_ID','$NETWORK','$REGION','$SUBNET','$NO_EXTERNAL_IP_ADDRESS' < ./job_with_custom_network.json)
EOF

gcloud batch jobs submit --job-prefix=container-network --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$CONTAINER_IMAGE_URI','$BLOCK_EXTERNAL_NETWORK' < ./container_job_block_external_network.json)
EOF
