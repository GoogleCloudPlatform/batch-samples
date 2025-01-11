#!/bin/bash

# -----------------------------------------------------
# Use Defaults from Environment
# -----------------------------------------------------

# Get Project ID from environment variable or gcloud config
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2> /dev/null)}"

# Use default Compute Engine service account or environment variable
SERVICE_ACCOUNT_EMAIL="${BATCH_SERVICE_ACCOUNT_EMAIL:-$(gcloud iam service-accounts list \
  --filter="displayName:Default compute service account" \
  --format="value(email)" 2> /dev/null)}"

# Check if we have the necessary values
if [ -z "$PROJECT_ID" ] || [ -z "$SERVICE_ACCOUNT_EMAIL" ]; then
  echo "Error: Could not determine PROJECT_ID or SERVICE_ACCOUNT_EMAIL."
  echo "Please set the GOOGLE_CLOUD_PROJECT and/or BATCH_SERVICE_ACCOUNT_EMAIL environment variables,"
  echo "or ensure you are running in a properly configured Google Cloud environment."
  exit 1
fi

# -----------------------------------------------------
# Enable Required APIs
# -----------------------------------------------------

echo "Enabling required APIs for project: ${PROJECT_ID}..."
gcloud services enable \
  batch.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  --project="${PROJECT_ID}"

# -----------------------------------------------------
# Grant IAM Roles to the Service Account
# -----------------------------------------------------

echo "Granting IAM roles to service account: ${SERVICE_ACCOUNT_EMAIL}..."

# Batch Job Editor
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/batch.jobsEditor" \
  --condition="None"

# Storage Object Admin (for accessing dataset and config)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/storage.objectAdmin" \
  --condition="None"

# Artifact Registry Writer (if pushing images to Artifact Registry)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --condition="None"

# Secret Manager Secret Accessor (for accessing secrets)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/secretmanager.secretAccessor" \
  --condition="None"

# -----------------------------------------------------
# Create Secrets in Secret Manager
# -----------------------------------------------------

echo "Checking environment variables for secrets..."

# WandB API Key
if [ -n "$WANDB_API_KEY" ]; then
  if ! gcloud secrets describe "wandb-api-key" --project="${PROJECT_ID}" &> /dev/null; then
    echo "Creating secret 'wandb-api-key'..."
    gcloud secrets create "wandb-api-key" --replication-policy="automatic" --project="${PROJECT_ID}"
    echo -n "$WANDB_API_KEY" | gcloud secrets versions add "wandb-api-key" --data-file=- --project="${PROJECT_ID}"
  else
    echo "Secret 'wandb-api-key' already exists. Skipping creation."
  fi
else
  echo "WANDB_API_KEY environment variable not set. Skipping secret creation."
fi

# Hugging Face Hub Token
if [ -n "$HF_TOKEN" ]; then
  if ! gcloud secrets describe "hf-token" --project="${PROJECT_ID}" &> /dev/null; then
    echo "Creating secret 'hf-token'..."
    gcloud secrets create "hf-token" --replication-policy="automatic" --project="${PROJECT_ID}"
    echo -n "$HF_TOKEN" | gcloud secrets versions add "hf-token" --data-file=- --project="${PROJECT_ID}"
  else
    echo "Secret 'hf-token' already exists. Skipping creation."
  fi
else
  echo "HF_TOKEN environment variable not set. Skipping secret creation."
fi

echo "Project setup and permissions complete!"
