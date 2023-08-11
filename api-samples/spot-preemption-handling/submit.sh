#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# Turn OFF the allexport option
set +o allexport

# Run batch on Spot VM and purely retry on Spot preemption.
gcloud batch jobs submit --job-prefix=preemption --location=${Location} --project=${ProjectID} --config ./task_retry_purely_on_preemption.json
