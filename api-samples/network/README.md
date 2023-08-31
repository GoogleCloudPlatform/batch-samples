## Overview
Google Batch supports jobs using custom networks.
More information in https://cloud.google.com/batch/docs/networking-overview.

## Prerequisites
* Fill in the values for variables for the samples in `submit.sh`.

## Network Samples
### job_with_custom_network.json
This script job runs the VM with customized network, and echoes `hello world` from each task.

### container_job_block_external_network.json
The container job runs the VM without external network on the container, and echoes `hello world` from each tas in the container.