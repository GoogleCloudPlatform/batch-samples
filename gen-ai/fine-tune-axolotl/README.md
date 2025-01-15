# Fine-Tuning with Axolotl on Google Cloud Batch

This project provides scripts and sample configuration files to fine-tune large
language models using [Axolotl](https://github.com/axolotl-ai-cloud/axolotl) on
[Google Cloud Batch](https://cloud.google.com/batch).

## Features

- **Job submission template:** Automates the process of submitting fine-tuning
  jobs to Google Cloud Batch.
- **Fine-tuning support:** Supports latest fine-tuning methods such as QLora and
  Flash Attention through Axolotl.
- **GPU acceleration:** Configure jobs to use a single or multiple GPUs with
  [FSDP](https://pytorch.org/blog/introducing-pytorch-fully-sharded-data-parallel-api/)
  and [Deepspeed](https://github.com/microsoft/DeepSpeed).

## Prerequisites

- A Google Cloud project with billing enabled.
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and
  configured.
- Familiarity with Google Cloud Batch concepts.
- (Recommended) A Hugging Face account for accessing models and datasets, and
  for pushing the adapter to the [Hugging Face
  Hub](https://huggingface.co/docs/hub).
- (Optional) A Weights & Biases account for experiment tracking.

## Setup

From the [Cloud
Shell](https://cloud.google.com/shell/docs/launching-cloud-shell) or another
editor, you can run these steps to get started:

1. **Clone the repository:**

    ```bash
    git clone https://github.com/GoogleCloudPlatform/batch-samples
    cd gen-ai/fine-tune-axolotl
    ```

2. **Configure environment variables:**

    - Set the `GOOGLE_CLOUD_PROJECT` environment variable to your project ID:

      ```bash
      export GOOGLE_CLOUD_PROJECT="your-project-id"
      ```

    - (Optional) set `CLOUD_STORAGE_BUCKET` to the desired cloud storage bucket
      name.
    - (Optional) set `LOCATION` environment variable if you do not wish to use
      `us-central1`.
    - (Optional) Set `BATCH_SERVICE_ACCOUNT_EMAIL` if you want to use a specific
      service account other than the default Compute Engine service account.
    - (Optional) Set `HF_TOKEN` if you need to access private models or datasets
      on Hugging Face.
    - (Optional) Set `WANDB_API_KEY` if you want to use Weights & Biases for
      logging.

3. **Run the setup script:**

    ```bash
    ./setup.sh
    ```

    This script will:

    - Enable required Google Cloud APIs.
    - Grant necessary IAM roles to the service account.
    - Create secrets in Secret Manager for `WANDB_API_KEY` and `HF_TOKEN` if the
      corresponding environment variables are set.

## Usage

1. **Configure Axolotl:**

    The sample configuration supports fine-tuning the [Gemma 2
    27B](https://huggingface.co/google/gemma-2-27b-it) instruction-tuned model
    on the [databricks-dolly-15k
    dataset](https://huggingface.co/datasets/databricks/databricks-dolly-15k).

    - Modify the `config.yaml` file to specify the desired fine-tuning
      parameters. For more details, see the [Axolotl
      documentation](https://axolotl-ai-cloud.github.io/axolotl/) and the
      [configuration file
      reference](https://axolotl-ai-cloud.github.io/axolotl/docs/config.html).
      Key parameters include:
    - `base_model`: The Hugging Face model ID or local path of the base model.
    - `hub_model_id`: (optional) the name to push the fine tuned model to the
      hub.
    - `datasets`: The dataset(s) to use for fine-tuning. See the [Axolotl
      datasets
      documentation](https://axolotl-ai-cloud.github.io/axolotl/docs/dataset-formats/)
      for more details.
    - `learning_rate`, `num_epochs`, `micro_batch_size`, etc.: Training
      hyperparameters.
    - `deepspeed`, `fsdp`, `fsdp_config`: Multiple GPU configuration. Do not set
      when using a single GPU.

    The `output_dir` and `dataset_prepared_path` values will be automatically
    set by the job submission script to locations in your Cloud Storage bucket.
    These parameters are used to export the job outputs and cache prepared
    datasets, respectively.

2. **Submit the batch job:**

    ```bash
    ./submit.sh
    ```

    The `submit.sh` script will: Extract the `base_model` from `config.yaml`.

    - Generate a unique job name based on the base model and timestamp.
    - Update the `output_dir` in `config.yaml` to point to the job-specific
      output location in Cloud Storage.
    - Upload the `config.yaml` to Cloud Storage.
    - Submit the job to Google Cloud Batch using the provided `config.json`
      template and environment variables.

3. **Monitor the job:**

    - Use the Google Cloud console or the `gcloud` CLI to [monitor the
      status](https://cloud.google.com/batch/docs/view-jobs-tasks) of the batch
      job.
    - If configured, track training progress and metrics on Weights & Biases.

4. **Download Model**

    - After the job completes, download your fine tuned model from the
      `output_dir` specified in your config.

## Configuration Details

### `config.yaml`

This file contains the Axolotl configuration. Refer to the [Axolotl
documentation](https://axolotl-ai-cloud.github.io/axolotl/home/) and the
provided example for detailed explanations of the available options.

### `config.json`

This file defines the Google Cloud Batch job. For more information, see the
[Google Cloud Batch
documentation](https://cloud.google.com/batch/docs/create-run-job). Key
parameters include:

- `taskGroups.taskSpec.runnables.container.imageUri`: The container image to use
  (defaults to `axolotlai/axolotl-cloud:0.5.2`).
- `taskGroups.taskSpec.runnables.container.commands`: The command to run inside
  the container.
- `taskGroups.taskSpec.environment.secretVariables`: Secret environment
  variables (e.g., `WANDB_API_KEY`, `HF_TOKEN`).
- `taskGroups.taskSpec.volumes`: Mounts Cloud Storage buckets to the container.
- `allocationPolicy.instances.policy.machineType`: The machine type to use
  (e.g., `a3-highgpu-2g`).
- `allocationPolicy.instances.installGpuDrivers`: Whether to automatically
  install GPU drivers.
- `logsPolicy.destination`: Where to send logs (e.g., `CLOUD_LOGGING`).
- `allocationPolicy.instances.policy.bootDisk.sizeGb`: the size of the boot
  disk, in GB.

## Troubleshooting

- **Error: Could not determine PROJECT_ID or SERVICE_ACCOUNT_EMAIL:** Ensure
  that the `GOOGLE_CLOUD_PROJECT` environment variable is set, or that you are
  running in a properly configured Google Cloud environment.
- **Permission issues:** Verify that the service account has the required IAM
  roles: `roles/batch.jobsEditor`, `roles/storage.objectAdmin`,
  `roles/artifactregistry.writer`, `roles/secretmanager.secretAccessor`.
- **Quota issues:** Check your project's quotas for Compute Engine resources
  (e.g., GPUs, CPUs, memory) and adjust values in `submit.sh` accordingly.
- **Axolotl errors:** Consult the Axolotl documentation for troubleshooting
  specific Axolotl configuration or training issues.

## Contributing

Contributions to this project are welcome! Please open an issue or submit a pull
request with your proposed changes.
