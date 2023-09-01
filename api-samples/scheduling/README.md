## Overview
Google Batch supports jobs running in sequential order, or as soon as possible.


## Scheduling Samples
### task_run_in_order.json
This job runs 3 tasks with 1 VM one by one with task index increasing order.

### task_run_in_parallel.json
The job runs 3 tasks in parallel in 1 VM.
The parallel schema can be defined by `taskCountPerNode` and `parallelism`  fields.
`AS_SOON_AS_POSSIBLE` is also Batch's default Scheduling Policy.
