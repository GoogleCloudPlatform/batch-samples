# Batch API samples
This directory contains samples of [Batch](https://cloud.google.com/batch) jobs that show how to use the Batch API. Each sample is usually simple and focuses on a single feature.

## Common prerequisites for all samples
* You have a [Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
* You have a Linux command line terminal with bash to run the commands.
* You have the [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/gcloud) installed and initialized.
* You have enabled the [Batch API](https://console.cloud.google.com/batch) and understand the [basic Batch concepts](https://cloud.google.com/batch/docs/get-started#product-overview).
* You have the permissions required to [create Batch jobs](https://cloud.google.com/batch/docs/create-run-basic-job).
* You have modified the variables in [env.sh](./env.sh) to match your environment.

## To run a Batch API sample job
1. Read the README.md file in the subdirectory that contains the sample job.
1. Follow the manual steps to set up the prerequisites for the sample.
1. Change to the subdirectory and run the following command:

```
./submit.sh
```
