## Overview
Image streaming is a method of pulling container images in which Batch streams
data from eligible images as requested by your applications. Workloads will
initialize without waiting for the entire image to download. This can
significantly reduce the Batch job startup time and improve the overall Batch
experience, especially when eligible images are large and/or workloads are
short-lived. 

## Requirements
* [enable-image-streaming](https://cloud.google.com/batch/docs/reference/rest/v1alpha/projects.locations.jobs#container) flag must be set to true.
* Users must enable the Container File System API.
* Container images must be stored in Google Artifact Registry. Otherwise, images will not be streamed.
* Users must include containerfilesystem.googleapis.com in their service perimeter if images are protected by VPCSC.

## Limitations
* The feature is only available in v1alpha.
* Users must not specify image streaming and docker containers in the same job.
* When users enable image streaming, only **imageUri, commands, entrypoint and
volumes** are supported in the Container proto. All other fields are ignored.
* The AR repository must be in the same region as Cloud Batch VMs,
or in a [multi-region](https://cloud.google.com/artifact-registry/docs/repositories/repo-locations#location-mr) corresponding to the region where Batch VMs are running.
* The private AR repository must be accessible by the current service account running Batch.
* Images that use the [V2 Image Manifest, schema version1](https://docs.docker.com/registry/spec/manifest-v2-1/) are not supported.
* Images with empty layers or duplicate layers are not supported.
* You might not notice the benefits of Image streaming during the first pull of an eligible image.
However, after Image streaming caches the image, future image pulls on any jobs benefit from Image streaming.

## Samples
### image_streaming_simple_job.json
This is a simple job that shows how to use image streaming with Batch.
As you can see, currently there is no big difference from using docker container.
This example job uses debian image and sleeps for some time.