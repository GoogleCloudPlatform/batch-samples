#!/bin/bash

function exit_error() {
  # Writes a message to the log to stop the image building.
  echo "Batch Debian Image Build Failed:" "$@"
  exit 1
}

function install_docker_requirements() {
  install_driver_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_driver_packages")
  if [[ "$install_driver_packages" = "true" ]]; then
    # Install docker.
    apt-get install --yes ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install --yes docker-ce docker-ce-cli containerd.io docker-compose-plugin || exit_error "docker installation failed."
    # Install docker credential helper.
    MACHINE="$(uname -m)"
    CLOUDSDK_PYTHON=/usr/bin/python3 gsutil cp gs://batch-agent-prod-us/docker-credential-gcr-tool/docker-credential-gcr-"$MACHINE".tar.gz docker-credential-gcr.tar.gz
    tar -xzf docker-credential-gcr.tar.gz
    chmod +x docker-credential-gcr
    cp docker-credential-gcr /usr/local/bin/
    docker-credential-gcr version || exit_error "docker-credentail-gcr installation failed."
  fi
}

function install_gcsfuse() {
  install_gcs_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_gcs_packages")
  if [[ "$install_gcs_packages" = "true" ]]; then
    VERSION="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo "deb https://packages.cloud.google.com/apt gcsfuse-$VERSION main" | tee /etc/apt/sources.list.d/gcsfuse.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    apt-get update
    apt-get -y install gcsfuse || exit_error "gcsfuse installation failed."
  fi
}

function install_nfs() {
  install_nfs_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_nfs_packages")
  if [[ "$install_nfs_packages" = "true" ]]; then
    apt -y install nfs-common || exit_error "nfs installation failed."
  fi
}

function install_mdadm() {
  install_local_ssd_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_local_ssd_packages")
  if [[ "$install_local_ssd_packages" = "true" ]]; then
    apt install mdadm --no-install-recommends || exit_error "mdadm installation failed."
  fi
}

function install_gpu_driver() {
  install_gpu_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_gpu_packages")
  if [[ "$install_gpu_packages" = "true" ]]; then
    curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py
    python3 install_gpu_driver.py || exit_error "gpu driver installation failed."
  fi
}

function install_agent() {
  install_agent_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_agent_packages")
  if [[ "$install_agent_packages" = "true" ]]; then
    echo deb https://us-central1-apt.pkg.dev/projects/cloud-batch-content cloud-batch-deb main | tee /etc/apt/sources.list.d/google-cloud-batch-agent.list
    curl https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | sudo apt-key add -
    apt-get update
    BATCH_AGENT_VERSION=$(gcloud artifacts versions list --repository=cloud-batch-deb --package=cloud-batch-agent --location=us-central1 --project=cloud-batch-content --sort-by="CREATE_TIME" --format="value(VERSION)" | tail -1)
    apt-get install -y cloud-batch-agent="$BATCH_AGENT_VERSION" || exit_error "cloud-batch-agent installation failed."
    systemctl disable --now cloud-batch-agent.service
  fi
}

function main() {
  sudo su
  readonly HEADER="Metadata-Flavor:Google"
  readonly ATTR_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
  # Install docker requirements.
  install_docker_requirements
  # Install GCS requirements.
  install_gcsfuse
  # Install NFS requirements.
  install_nfs
  # Install Local SSD requirements.
  install_mdadm
  # Install GPU driver.
  install_gpu_driver
  # Install Cloud Batch Agent.
  install_agent
}

main "$@"
