#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Pub/Sub topic for job state notification.
JobStateTopic=batch-job-state
# Pub/Sub topic for task state notification.
TaskStateTopic=batch-job-task-state

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=pubsub --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$ProjectID','$JobStateTopic','$TaskStateTopic' < ./pubsub.json)
EOF
