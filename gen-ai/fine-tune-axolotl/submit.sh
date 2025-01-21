#!/bin/bash

# Exit on any error
set -e

# --- Configuration ---
# General Settings
export PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2> /dev/null)}"
export LOCATION="${LOCATION:-us-central1}"
export BUCKET="${CLOUD_STORAGE_BUCKET:-$PROJECT_ID}"

# Batch Service Account
export BATCH_SERVICE_ACCOUNT_EMAIL="${BATCH_SERVICE_ACCOUNT_EMAIL:-$(gcloud iam service-accounts list --filter='displayName:Default compute service account' --format='value(email)')}"

# Container Settings
export CONTAINER_IMAGE="axolotlai/axolotl-cloud:0.5.2"
CONTAINER_COMMAND="accelerate launch -m axolotl.cli.train"  # Config file will be appended later

# Secret Manager (Optional)
export WANDB_API_KEY_SECRET="projects/${PROJECT_ID}/secrets/wandb-api-key/versions/latest"
export HF_TOKEN_SECRET="projects/${PROJECT_ID}/secrets/hf-token/versions/latest"

# Compute Resources
export MACHINE_TYPE="a3-highgpu-2g"
export CPU_MILLI=8000
export MEMORY_MIB=60000
export BOOT_DISK_SIZE_GB=250
export SHM_SIZE="1g"
export RESERVATION="NO_RESERVATION"
export LOGS_DESTINATION="CLOUD_LOGGING"

# --- Prepare job name ---
# Extract base_model from config.yaml
if [ ! -f "config.yaml" ]; then
  echo "Error: config.yaml not found. Ensure it's in the correct location."
  exit 1
fi
BASE_MODEL=$(grep "^base_model:" config.yaml | grep -v "^#" | awk '{print $2}')
if [ -z "$BASE_MODEL" ]; then
  echo "Error: Could not extract base_model from config.yaml"
  exit 1
fi

# Sanitize base_model and generate timestamp
SANITIZED_BASE_MODEL=$(echo "$BASE_MODEL" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_/' | sed 's/^-*//;s/-*$//;s/^[^a-z]//; s/\//--/g')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
export JOB_NAME="${SANITIZED_BASE_MODEL}-${TIMESTAMP}"

# --- Derived paths ---
export BUCKET_PATH="${BUCKET}/training"
export MOUNT_PATH="/mnt/disks/gcs/training"
export CONFIG_URL="gs://${BUCKET_PATH}/jobs/${JOB_NAME}/config.yaml"
export CONTAINER_COMMAND="${CONTAINER_COMMAND} ${MOUNT_PATH}/jobs/${JOB_NAME}/config.yaml"
export OUTPUT_PATH="${MOUNT_PATH}/jobs/${JOB_NAME}/out"
export DATASET_PATH="${MOUNT_PATH}/datasets"

# --- Update output and dataset paths in config.yaml ---
sed -i "/^output_dir:/d;/^dataset_prepared_path:/d" config.yaml
if ! tail -n 1 config.yaml | grep -q '$'; then
  echo "" >> config.yaml
fi
echo "output_dir: \"${OUTPUT_PATH}/\"" >> config.yaml
echo "dataset_prepared_path: \"${DATASET_PATH}\"" >> config.yaml

# --- Ensure PROJECT_ID is set ---
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Could not determine PROJECT_ID."
  echo "Please set the GOOGLE_CLOUD_PROJECT environment variable,"
  echo "or ensure you are running in a properly configured Google Cloud environment."
  exit 1
fi

# --- Handle bucket creation or usage ---
if gcloud storage buckets describe "gs://${BUCKET}/" > /dev/null 2>&1; then
  echo "Using existing bucket '${BUCKET}'."
else
  echo "Bucket '${BUCKET}' does not exist. Creating it..."
  gcloud storage buckets create "gs://${BUCKET}/" --location="${LOCATION}" && echo "Successfully created bucket '${BUCKET}'." || { echo "Error creating bucket '${BUCKET}'."; exit 1; }
fi

# --- Upload config.yaml ---
echo "Uploading config.yaml to ${CONFIG_URL}..."
gcloud storage cp config.yaml ${CONFIG_URL}

# --- Submit the Batch job ---
echo "Submitting Batch job..."
gcloud batch jobs submit "$JOB_NAME" \
  --location "$LOCATION" \
  --config - <<EOF
$(envsubst < config.json)
EOF
echo "Job '${JOB_NAME}' submitted successfully!"
