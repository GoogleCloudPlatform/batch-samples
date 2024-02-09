## Overview

The Ops Agent is recommended as the primary agent for collecting telemetry from
Compute Engine instances that are running your batch jobs. It combines the
collection of logs, metrics, and traces into a single process, providing better
understanding of your resources' usage.

These examples provide a method to install the Ops Agent through Batch service
for installation on individual VMs. If agent installation on a fleet is
required, please refer to
[Ops agent installation on a fleet installation](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/managing-agent-policies).

## Prerequisites

*   Ensure that your operating system is supported by the Ops Agent.
    Container-Optimized OS is not supported, please check
    [supported operating systems](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent#supported_operating_systems)
    for more details and updates. As a result, please specify other boot disk to
    avoid the default Batch Container-Optimized OS image use in the Batch
    container jobs.

*   Make sure that
    [the required access](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent#access)
    is granted properly.

*   Ensure that you
    [enable the services](https://cloud.google.com/service-usage/docs/enable-disable)
    for both the Cloud Logging API and Cloud Monitoring API.

*   If your VMs that don't have access to remote package repositories(like using
    a private network), please refer to
    [the VMs without remote package access section](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/installation#remote_package_access)
    for more information.

*   If you run a GPU Batch job, and you need to install or upgrade your GPU
    driver with Ops Agent. Please make sure the agent is stopped before
    installing or upgrading your GPU drivers using
    [the installation script](https://cloud.google.com/compute/docs/gpus/install-drivers-gpu#installation_scripts).

*   Fill in the values for variables for this sample in `submit.sh`.

## Ops Agent Samples

### installation_with_one_task_per_node.json

This sample installs Ops Agent with only one task running per node.

### installation_with_multi_tasks_per_node.json

This sample installs Ops Agent with multiple concurrent tasks running on the
same node.

## Other Resources

[Ops Agent -- Before you begin](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/installation#before_you_begin)

[Troubleshoot the Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/troubleshooting)

[Monitoring third-party applications](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/third-party)

[Script -- Installing the Ops Agent on individual VMs](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/installation)
