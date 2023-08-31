#!/bin/bash
function exit_error() {
  # Writes a message to the log to stop the image building.
  echo "Batch Image Build Failed:" "$@"
  exit 1
}

function install_docker_requirements() {
  install_driver_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_driver_packages")
  if [[ "$install_driver_packages" = "true" ]]; then
    # Install docker.
    yum install -y yum-utils
    yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || exit_error "docker installation failed."
    # Install docker credential helper.
    CLOUDSDK_PYTHON=/usr/bin/python3 gsutil cp gs://batch-agent-prod-us/docker-credential-gcr-tool/docker-credential-gcr-"$MACHINE".tar.gz docker-credential-gcr.tar.gz
    tar -xzf docker-credential-gcr.tar.gz
    chmod +x docker-credential-gcr
    cp docker-credential-gcr /usr/bin/
    docker-credential-gcr version || exit_error "docker-credentail-gcr installation failed."
  fi
}

function install_gcsfuse() {
  install_gcs_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_gcs_packages")
  if [[ "$install_gcs_packages" = "true" ]]; then
    echo "[gcsfuse]
name=gcsfuse (packages.cloud.google.com)
baseurl=https://packages.cloud.google.com/yum/repos/gcsfuse-el7-$MACHINE
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
    https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" | tee /etc/yum.repos.d/gcsfuse.repo
    yum -y install gcsfuse || exit_error "gcsfuse installation failed."
    # Enable gcsfuse to find fusermount.
    export PATH=/usr/bin/fusermount:$PATH
  fi
}

function install_mdadm() {
  install_local_ssd_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_local_ssd_packages")
  if [[ "$install_local_ssd_packages" = "true" ]]; then
    yum install mdadm -y || exit_error "mdadm installation failed."
  fi
}

function install_gpu_driver() {
  install_gpu_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_gpu_packages")
  if [[ "$install_gpu_packages" = "true" ]]; then
    # Precache metadata for GPU drivers installation.
    mkdir -p /opt/google/gpu-installer
    echo 1 >> /opt/google/gpu-installer/deps_installed.flag
    curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py
    python3 install_gpu_driver.py || exit_error "gpu driver installation failed."
  fi
}

function install_agent() {
  install_agent_packages=$(curl -sfH "${HEADER}" "${ATTR_URL}/install_agent_packages")
  if [[ "$install_agent_packages" = "true" ]]; then
    echo "[cloud-batch-agent]
name=cloud-batch-agent (Artifact Registry)
baseurl=https://us-central1-yum.pkg.dev/projects/cloud-batch-content/cloud-batch-rpm
enabled=1
gpgcheck=0
repo_gpgcheck=0" | tee /etc/yum.repos.d/cloud-batch-agent.repo
    BATCH_AGENT_VERSION=$(gcloud artifacts versions list --repository=cloud-batch-deb --package=cloud-batch-agent --location=us-central1 --project=cloud-batch-content --sort-by="CREATE_TIME" --format="value(VERSION)" | tail -1)
    yum install -y --disablerepo='*' --enablerepo='cloud-batch-agent' cloud-batch-agent-"$BATCH_AGENT_VERSION" || exit_error "cloud-batch-agent installation failed."
    systemctl disable --now cloud-batch-agent.service
  fi
}

function main() {
  sudo su
  MACHINE="$(uname -m)"
  readonly HEADER="Metadata-Flavor:Google"
  readonly ATTR_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
  # Install docker requirements.
  install_docker_requirements
  # Install GCS requirements.
  install_gcsfuse
  # Install Local SSD requirements.
  install_mdadm
  # Install GPU driver.
  install_gpu_driver
  # Install Cloud Batch Agent.
  install_agent
}

main "$@"
