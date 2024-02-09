#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for the samples.
# -----------------------------------------
# FOLLOWING_SCRIPT is the script running after the installation.
# This sleep command keep the VMs running and helps to check the monitoring metrics.
FOLLOWING_SCRIPT="sleep 3600"
# TASK_COUNT, PARALLELISM, TASK_COUNT_PER_NODE are setting the total number of tasks,
# the parallelism of the job and concurrent running tasks on each VMs.
# This default config will boot 2 VMs each with 5 tasks running
TASK_COUNT=10
PARALLELISM=10
TASK_COUNT_PER_NODE=5
# The samples set the default VM location, the GPU type and the driver installation
# to show the GPU related metrics. Please change them to other location with GPU quota.
ALLOWED_LOCATIONS=regions/us-central1
GPU_TYPE=nvidia-tesla-t4

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=ops-agent --location="${Location}" --project="${ProjectID}" --config - <<EOF
$(envsubst '$FOLLOWING_SCRIPT' < ./one_simple_task_per_node.yaml)
EOF

gcloud batch jobs submit --job-prefix=ops-agent --location="${Location}" --project="${ProjectID}" --config - <<EOF
$(envsubst '$FOLLOWING_SCRIPT','$GPU_TYPE','$ALLOWED_LOCATIONS' < ./one_task_per_node_w_gpu.yaml)
EOF

gcloud batch jobs submit --job-prefix=ops-agent --location="${Location}" --project="${ProjectID}" --config - <<EOF
$(envsubst '$FOLLOWING_SCRIPT','$GPU_TYPE','$ALLOWED_LOCATIONS','$TASK_COUNT','$PARALLELISM','$TASK_COUNT_PER_NODE'  < ./multi_tasks_per_node_w_gpu.yaml)
EOF

