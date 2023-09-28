## Overview
Batch compatible CentOS Images can be built using Google supported [Packer](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/packer).

## Prerequisites
### Generate Packer Builder
The packer base image is required in your project for you to build a custom image with Packer.

If your project hasn't have the Packer image, you can build one based on the following commands:

1.  Clone the `cloud-builders-community` repo:

    ```
    $ git clone https://github.com/GoogleCloudPlatform/cloud-builders-community
    ```

2.  Go to packer folder and build the packer base image in your project:

    ```
    $ cd cloud-builders-community/packer
    $ gcloud builds submit .
    ```

    After this, your project will have the basic packer image under
    `gcr.io/$PROJECT_ID/packer`, which will be used in the later image
    generation.

For more information on how to set Packer configurations for image building, you can refer to https://developer.hashicorp.com/packer/plugins/builders/googlecompute#configuration-reference.

### Customize variables
Fill in the values for variables for the CentOS image generation in `batch_centos_image.yaml`.

You are also welcome to add more variables such as disk type, based on your requirements.

## Build the Image
You can run the `submit.sh` script to start the image building. The package installation scripts are in the `batch_centos_image_packages.sh`.

## Errors and Logs
* If your Cloud Builds execution is stuck or failed, you can always check the Cloud Build history in the console.
* While the VM is still running, you can check on the packer image created in the process, check information such as SSH keys, serial port 1, startup-script-status.

## Batch Package Installation Verifications
After a new image is built, you can check the Batch related package
dependencies by creating an instance with your image and run the below commands for each installed package. If your image includes GPU driver packages, make sure also attach a GPU on your instance.

1.  Cloud Batch Agent: Requirement for Batch Communication

    ```
    cloud-batch-agent --version
    ```

2.  Docker: Requirement to run Batch Container Jobs

    ```
    docker --version
    ```

3.  Docker Credentials: Credential to run docker

    ```
    docker-credential-gcr version
    ```

4.  GCSFuse: Requirement for GCS mounting

    ```
    gcsfuse -v
    ```

5.  NFS: Requirement for Filestore mounting

    ```
    yum list installed | grep nfs-utils
    ```

6.  Mdadm: Requirement for Local SSD usage

    ```
    sudo mdadm --version
    ```

7.  GPU Driver: Requirement for GPU Jobs

    ```
    nvidia-smi
    ```
