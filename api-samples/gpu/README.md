## Prerequisites
* Fill in the values for variables for the samples in `submit.sh`.

## GPU Samples
### gpu_job_with_driver_installation.json
This script job runs on VMs with GPU, and echoes `hello world` to
output_task_${BATCH_TASK_INDEX}.txt file for each task.