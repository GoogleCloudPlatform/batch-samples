## Overview
Batch tasks can be interrupted by Spot preemption. Batch now provides a new exit code (50001) for Spot preemption task failures. Below examples demonstarte how to make use of the new exit code to retry failed tasks.

## Samples
### task_retry_purely_on_preemption.json
This is a basic Batch job example which uses Spot VMs for tasks. There is a 50001 exit code specified in lifecycle policies. This is the new code specifically used by Batch for Spot preemption retry. According to the max retry count in the job spec, this job will be retried at most 5 times upon Spot preemption interruption.

### task_retry_including_preemption.json
This is Batch job example which shows using Spot VMs running a script with some exit codes to retry, 1 and 2 in this example. In this example, the task will be retried 3 times if the script exits on 1 or 2 as well as Spot preemption interruption. Please be noted that all exit codes share the same max retry count which is 3 in this example. For instance, if the task has retried 3 times already on script exit codes (1 or 2), then any following failures including Spot preemption will not be handled by Batch. 
