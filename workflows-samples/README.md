# Batch Workflows samples
This directory contains samples of [Batch](https://cloud.google.com/batch) related GCP [workflows](https://cloud.google.com/workflows).

## Common prerequisites for all samples
* You have a [Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
* You have enabled the [Batch API](https://console.cloud.google.com/batch) and understand the [basic Batch concepts](https://cloud.google.com/batch/docs/get-started#product-overview).
* You have the permissions required to [create Batch jobs](https://cloud.google.com/batch/docs/create-run-basic-job).
* You should know about how to create and deploy GCP Workflows, more details in [Workflows Overview](https://cloud.google.com/workflows/docs/overview).

## Samples
### export-to-bigquery-delete-batch-jobs
* This workflow will try to create big query dataset and table, it then will export the jobs into the big query table and delete the exported jobs. 
* The arguments of the workflow are:
  * project
  * location
  * job_filter: Used with list/delete the Batch jobs, default to list FAILED or SUCCEEDED Batch jobs which are created before 2023/02/13 for demonstration purpose
  * page_size: default to 100
  * dateset_id: default is default_dataset_id
  * table_id: default is default_table_id
* The schema of the big query table is three string type columns: name, uid, job.