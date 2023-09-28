## Overview
Batch compatible Container-Optimized (COS) Images can be built with [cos-customizer](https://cos.googlesource.com/cos/tools/+/refs/heads/master/src/cmd/cos_customizer).

## Prerequisites
Fill in the values for variables for the Container-Optimized image generation in `batch_cos_image.yaml`.

You are also welcome to add more variables such as disk type, based on your requirements.

## Build the Image
You can run the `submit.sh` script to start the image building. The package installation scripts are in the `batch_cos_image_packages.sh`.

## Errors and Logs
* If your Cloud Builds execution is stuck or failed, you can always check the Cloud Build history in the console.
* While the VM is still running, you can check on the packer image created in the process, check information such as SSH keys, serial port 3, startup-script-status.

## Batch Package Installation Verifications
After a new image is built, you can check the Batch related package
dependencies by creating an instance with your image and run the below commands for each installed package. If your image includes GPU driver packages, make sure also attach a GPU on your instance.

1.  Cloud Batch Agent: Requirement for Batch Communication

    ```
    /var/lib/google/agent --version
    ```

2.  GCSFuse: Requirement for GCS mounting

    ```
    /var/lib/google/gcsfuse -v
    ```
3.  GPU Driver: Requirement for GPU Jobs

    ```
    cos-extensions install gpu -- -version=latest
    ```

    For Container-Optimized OS VMs, this preceding command is required to be run on every VM reboot to configure GPU drivers. You can run this command and see the console log to see whether the GPU driver is already installed.

    After this command, you can run the below commands following https://cloud.google.com/container-optimized-os/docs/how-to/run-gpus#verify_the_installation to verify the installation:

    ```
    sudo mount --bind /var/lib/nvidia /var/lib/nvidia
    sudo mount -o remount,exec /var/lib/nvidia
    sudo /var/lib/nvidia/bin/nvidia-smi
