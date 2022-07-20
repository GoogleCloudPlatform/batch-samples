# Batch - simple container

In this sample, you'll see how to run a simple container as a job in Batch service. You
will then automate the lifecycle of the Batch job using Workflows.

The Google Batch service provides an end to end fully-managed batch service,
which allows you to schedule, queue, and execute jobs on Google compute
instances. The service provisions resources, manages capacity and allows batch
workloads to run at scale.

## Before you begin

We recommend creating a new project for this tutorial so that it doesn't affect
any other existing projects you might have on Google Cloud. It is also easier to
clean up resources when you finish.

To create a new project, run:

```sh
gcloud projects create [PROJECT_ID]
```

Make sure your project id is set in gcloud:

```sh
gcloud config set project [PROJECT_ID]
```

## Simple container

In this sample, you will schedule a batch job to run a simple container.

### Setup

Run [setup.sh](setup.sh) to enable required services and add right roles to your user account.

### Test

See [job.json](job.json) for the job definition. It runs 3 busybox containers
and echos some environment variables.

Run [test.sh](test.sh) to run the Batch job. Once the job is started, you should
see 3 Compute Engine VMs created and you can check the logs of the VMs to see
the outputted environment variables.

## Simple container with Workflows

### Setup

Run [setup-workflow.sh](setup-workflow.sh) to enable required services and
create a service account with the right roles for Workflows.

### Test

See [workflow.yaml](workflow.yaml) for the workflow definition. It creates a
batch job with the busybox containers, waits for the job to complete and then
deletes the job.

Run [test-workflow.sh](test-workflow.sh) to deploy and then execute the
workflow. You can check the result of the workflow execution in Google Cloud
console.

### Cleanup

To delete the Batch jobs you created, use the `gcloud beta batch jobs delete` command.

The following one-liner deletes all jobs containing "job-busybox-" in the names in the us-central1 region.

```sh
gcloud beta batch jobs list us-central1 --format="value(name)" | grep job-busybox- \
 | xargs -L1 gcloud beta batch jobs delete --location=us-central1
```

To delete the Workflow, run the `gcloud workflows delete` command:

```sh
gcloud workflows delete batch-busybox --location=us-central1
```

To delete the project, run the `gcloud projects delete` command:

```sh
gcloud projects delete [PROJECT_ID]
```
