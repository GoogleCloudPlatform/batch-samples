# Batch

## Scripts, Tools and Sample Jobs

This repository contains step-by-step tutorials and code samples to learn how to use [Batch](https://cloud.google.com/batch).

- [transcoding](transcoding): Quickstart tutorial of transcoding videos using Batch.
- [busybox](busybox): A simple sample to run a container as a Batch job.
- [primegen](primegen): An end-to-end sample of using Workflows and Cloud Build with Batch to automate the lifecycle of Batch jobs.
- [wrf](wrf): A sample for running the [Weather Research and Forecasting
  Model](https://www.mmm.ucar.edu/weather-research-and-forecasting-model) in a
  Batch Job with MPI.

# About Batch

High-performance computing and throughput-oriented batch computing are expected to perform at scale and with speed. Many workloads, such as drug discovery and genomics, financial services, and VFX rendering, require access to a large and diverse set of computing resources on demand. With more and faster computing power, you can convert an idea into a discovery, a hypothesis into a cure, or an inspiration into a product. Google Cloud provides customers flexible, on-demand access to large amounts of cutting-edge high-performance resources with Compute Engine.

Batch is a fully-managed cloud service for managing HPC, AI/ML, and data processing batch workloads on Google Cloud in a cloud-native manner. With the introduction of Batch, we seek to work with the community to define a new way to do batch computing that is cloud-optimized.

This public preview release brings traditional batch scheduler functionality into a cloud-first world. Simply focus on your workload and let Google Cloud manage the infrastructure and lifecycle of the resources. To the end-user, Batch presents a familiar interface that supports well-understood batch concepts, including:

- Support for submitting shell scripts as batch jobs
- Support for containerized batch jobs
- The ability to easily specify resources required by a job (vCPU, memory, GPUs, disks)
- Retries and Priorities
- This repository contains scripts, tools and sample jobs for use with Batch.

For more information about Batch, see

- https://cloud.google.com/batch
- https://github.com/googleapis/googleapis/tree/master/google/cloud/batch

# Community

You can go to the [Cloud Forum](https://www.googlecloudcommunity.com/gc/Infrastructure-Compute-Storage/bd-p/cloud-infrastructure) to engage with the Batch community for assistance.
