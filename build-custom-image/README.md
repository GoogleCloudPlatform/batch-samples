## Overview
[Batch](https://cloud.google.com/batch/docs/get-started) has provided Batch images under project `batch-custom-image` for different OS types.
The Batch images pre-installs the required packages for running Batch jobs, which can help you save Batch job running time, as well as overcoming network limitations.

This folder provides strategy on how to build a Batch required (preferred) image with different OS types. Due to the latency on GitHub update, if you meet with any issues when running the scripts in the folder, feel free to get help from Batch team.

## Prerequisites

1.  Make sure the Compute Engine API with the default Compute Engine service
    account for your project is enabled, and the Editor role has been granted.

2.  Make sure the Cloud Builds API is enabled and the following permissions have
    been granted to your Cloud Build Service Account as {PROJECT_NUMBER}@cloudbuild.gserviceaccount.com:

    -   Cloud Build Service Account (default added)
    -   Compute Admin (default added)
    -   Service Account User
    -   Storage Object Viewer
    -   Other roles up to your startup script command requirement.

3.  Ensure that you have [gcloud](http://go/gcloud) installed and you have run
    `gcloud init` to set up your credentials.
