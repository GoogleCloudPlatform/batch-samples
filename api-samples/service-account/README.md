## Overview

Google Batch jobs default to using the Compute Engine default service account,
but also provides two ways to specify the job's service account,
which offers better control on the resources and applications that a job's VMs can access.

## Prerequisites

* Please make sure that the service account you plan to use has the [permissions](https://cloud.google.com/batch/docs/get-started#project-prerequisites)
required to create Batch jobs for your project. And if you are prepared to use
instance template, specify the same custom service account both in your [instance template](https://cloud.google.com/compute/docs/instance-templates/create-instance-templates#gcloud) 
and your [job's definition](https://cloud.google.com/batch/docs/create-run-job-custom-service-account#api).

* Fill in the values for variables for this sample in `submit.sh`.


## Service Account Samples
### job_with_a_sa.json

This sample uses your service account and echoes hello world.

### template_with_a_sa.json

This sample uses your service account and instance template and echoes hello
world.
