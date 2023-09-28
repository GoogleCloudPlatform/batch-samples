#!/bin/bash
function exit_error() {
  # Writes a message to the log to stop the image building.
  echo "Batch COS Image Build Failed:" "$@"
  exit 1
}

function install_gcsfuse() {
  if [[ "$install_gcs_packages" = "true" ]]; then
    GCSFUSE_REPO=gcsfuse-bullseye
    toolbox --version
    TOOLBOX_PATH=$(sudo find /var/lib/toolbox -type d -name 'root-us.*')
    toolbox echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee "$TOOLBOX_PATH"/etc/apt/sources.list.d/gcsfuse.list
    toolbox bash -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
    toolbox apt-get update
    # Install GCSFuse.
    toolbox apt-get install -y gcsfuse
    cp "$TOOLBOX_PATH"/usr/bin/gcsfuse "$HOST_PATH"/gcsfuse
    # Check GCSFuse installation.
    "$HOST_PATH"/gcsfuse --version || exit_error "gcsfuse installation failed."
  fi
}

function install_agent() {
  if [[ "$install_agent_packages" = "true" ]]; then
    toolbox --version
    TOOLBOX_PATH=$(sudo find /var/lib/toolbox -type d -name 'root-us.*')
    toolbox echo "deb https://us-central1-apt.pkg.dev/projects/cloud-batch-content cloud-batch-deb main" | tee "$TOOLBOX_PATH"/etc/apt/sources.list.d/google-cloud-batch-agent.list
    toolbox bash -c 'curl https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | apt-key add -'
    toolbox apt-get update
    BATCH_AGENT_VERSION=$(toolbox gcloud artifacts versions list --repository=cloud-batch-deb --package=cloud-batch-agent --location=us-central1 --project=cloud-batch-content --sort-by="CREATE_TIME" --format="value(VERSION)" | tail -1 | tr -d '\r')
    toolbox apt-get install -y cloud-batch-agent="$BATCH_AGENT_VERSION"
    cp "$TOOLBOX_PATH"/usr/bin/cloud-batch-agent "$HOST_PATH"/agent
    chmod a+x "$HOST_PATH"/agent
    # Check Cloud Batch Agent installation.
    "$HOST_PATH"/agent --version || exit_error "cloud-batch-agent installation failed."
  fi
}

function install_gpu_driver() {
  if [[ "$install_gpu_packages" = "true" ]]; then
    cos-extensions install gpu -- -version=latest || exit_error "gpu driver installation failed."
  fi
}

function main() {
  sudo su
  HOST_PATH=/var/lib/google
  # Install GCS requirements.
  # Pre-installing GCSFuse is required for Batch jobs with Container-Optimized OS based images.
  install_gcsfuse
  # Install Cloud Batch Agent.
  # Pre-installing Cloud Batch Agent is required for Batch jobs with Container-Optimized OS based images.
  install_agent
  # Install GPU driver.
  install_gpu_driver
}

main "$@"
