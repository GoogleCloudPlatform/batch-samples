This sample demonstrates fine tuning the llama2-7b model on Batch.

## Environment setup

The Batch job requires two non-Batch components in the computing environment.

*   a Filestore to hold the fine tuning python script and results from the job.
*   a Hugging Face Hub read-access-token in your project's Secrets Manager.

Choose a path in the Filestore to mount and create a directory "scripts" within
that directory, and copy fine-tune.py to the scripts directory, e.g.

```
/share/llm/
  /scripts
    fine-tune.py
```

Create a [Hugging Face Hub](https://huggingface.co/docs/hub/en/index) account if
needed, and generate a [read-token](https://huggingface.co/settings/tokens).
Copy the token and save it as a secret in the
[Secrets Manager](https://cloud.google.com/security/products/secret-manager).

## Running the fine tuning job

Fill in your Filestore IP address, share path, the name of your Hugging Face
Token secret, and update RESULTS_DIR and SCRIPTS_DIR if needed in the job
template `job.yaml` file, and you will be abel to run the job with gcloud:

```
gcloud batch jobs submit fine-tune-llama2 \
  --project=<YOUR PROJECT> \
  --location=<REGION> \
  --config=job.yaml
```

You can use any REGION
[supported by Batch](https://cloud.google.com/batch/docs/locations). The job
will run faster if you select the same region as the Filestore.

Batch will provision a `g2-standard-96` and start running your fine tuning job.
When the job is complete Batch will automatically deprovision the VM. Your tuned
model (along with training checkpoints) will be in the RESULTS_DIR set in
job.yaml, on your Filestore.
