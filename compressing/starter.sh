#!/bin/bash

BUCKET_NAME="[BUCKET_NAME]"
gcsFilePaths=$(gsutil ls gs://$BUCKET_NAME/input | grep .pdf) #All pdf files in bucket will be proccessed.

temp_dir=$(mktemp -d)
trap 'rm -rf $temp_dir' EXIT

### Create task.sh files
echo "Creating each task.sh files"
TASK_COUNT=0
for gcsFilePath in $gcsFilePaths
do
  FILE_NAME=${gcsFilePath##*/};
  export FILE_NAME
  cat task.sh.template | envsubst '$FILE_NAME' > $temp_dir/task$TASK_COUNT.sh

  TASK_COUNT=`expr $TASK_COUNT + 1`
done

gsutil -m cp $temp_dir/task*.sh gs://$BUCKET_NAME/input/

### Create job.json
echo "Creating job.json"
export BUCKET_NAME
export TASK_COUNT
cat job.json.template | envsubst '$BUCKET_NAME $TASK_COUNT'> $temp_dir/job.json

### Submit the job
echo "Submiting the job"
date=$(date +"%Y%m%d%H%M")
gcloud beta batch jobs submit pdf-compression_$date --location=us-central1 --config=$temp_dir/job.json
