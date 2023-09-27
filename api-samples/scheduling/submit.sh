#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=task-in-order --location=${Location} --project=${ProjectID} --config ./task_run_in_order.json

gcloud batch jobs submit --job-prefix=task-in-parallel --location=${Location} --project=${ProjectID} --config ./task_run_in_parallel.json
