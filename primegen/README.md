# Batch - prime number generator container

In this sample, you'll see how to run a prime number generator container as a
job in Batch service. You will automate the lifecycle of the Batch job using Workflows.

The Google Batch service provides an end to end fully-managed batch service,
which allows you to schedule, queue, and execute jobs on Google compute
instances. The service provisions resources, manages capacity and allows batch
workloads to run at scale.

## Before you begin

We recommend creating a new project for this tutorial so that it doesn't affect any other existing projects you might have on Google Cloud. It is also easier to clean up resources when you finish.

To create a new project, run:

```
gcloud projects create [PROJECT_ID]
```

Make sure your project id is set in gcloud:

```sh
gcloud config set project [PROJECT_ID]
```

Make sure that billing is enabled for your Cloud project.
Learn how to [check if billing is enabled on a project](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled).

## Prime number generator container

In this sample, you will schedule a batch job to run a prime number generator
container. You can see the code of the container in
[PrimeGenService](PrimeGenService) folder.

### Setup

Run [setup.sh](setup.sh) to enable required services, create a service acount
for the right roles for Workflows and build and save the container.

### Test

See [workflow.yaml](workflow.yaml) for the workflow definition. It creates a
batch job with the container, waits for the job to complete and then
deletes the job.

Run [test.sh](test.sh) to deploy and then execute the workflow. You can check
the result of the workflow execution in Google Cloud console.

### Cleanup

To delete the Workflow, run the `gcloud workflows delete` command:

```
gcloud workflows delete batch-primegen --location=us-central1
```

`setup.sh` also creates a container repository. To delete this, run:

```
gcloud artifacts repositories delete container --location=us-central1
```

Cloud Build uses Cloud Storage to store resources for builds.
See the [Cloud Storage documentation](https://cloud.google.com/storage/docs/deleting-buckets) to learn how to delete storage buckets.

To delete the project, run the `gcloud projects delete` command:

```
gcloud projects delete [PROJECT_ID]
```
