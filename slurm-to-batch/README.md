# Slurm to Google Cloud Batch Converter

This Python script simplifies the transition of your Slurm workload scripts to Google Cloud Batch jobs. It parses supported Slurm directives and generates a Batch job template tailored for GPU-based workloads.

## Supported Slurm Directives

* `--job-name`
* `--gpus-per-task`
* `--gres=gpu`
* `--nodes`
* `--ntasks-per-node`

## Prerequisites

* Python 3.x
* Install required Python packages: `pip install -r requirements.txt` 

## Usage
   ```bash
   python3 convert_slurm_batch_job.py <slurm_script_path> <batch_template_folder>
   ```
   * <slurm_script_path>: Path to your Slurm script.
   * <batch_tempalte_folder> (Optional): Desired output directory for the template files(default to the Slurm script's parent folder).
The script will generate a YAML Batch job template.

## Template Placeholders
After generating the template, replace the following placeholders:

* <CUSTOM_GPU_TYPE>: The GPU type you want to use (e.g., nvidia-l4, nvidia-tesla-v100).
* <CUSTOM_BOOT_IMAGE>: The custom image you want to use. The image must have slurmd and slurmctld available.
    - Example: projects/<project_id>/global/images/<image_name>
* <CUSTOM_BOOT_DISK_SIZE>: The boot disk size of the VM. This should be compatible with the <CUSTOM_BOOT_IMAGE> field.
* <SELECTED_ZONE>: The zone where you want to submit your Batch job. Ensure the zone has the resources you need, especially GPU resources. (e.g., `us-central1-a`)
* <SRUN_COMMAND>: The srun command you want to use for running the workload.
    - Example: `srun -N2 --gres=gpu:2 /bin/nvidia-smi -L` to check the GPU UUID on each SLURM task.

### Example Batch Job

You can find a working example of a replaced batch job template at `examples/example_batch_job.yaml`. To submit this job, run the following command:

```bash
gcloud batch jobs submit projects/<project_id>/locations/us-central1/jobs/testjob01 --config ./examples/example_batch_job.yaml
```