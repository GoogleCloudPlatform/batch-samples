## Prerequisites
* Create a Google Cloud [Pub/Sub](https://cloud.google.com/pubsub) topic for job state notification and a Pub/Sub topic for task state notification.
* Fill in the values for variables for this sample in `submit.sh`.

## Pub/Sub Samples
### pubsub.json
This sample creates a job that publishes all changes in job state to a Pub/Sub topic and publishes a change to another topic when a task fails.
