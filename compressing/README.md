# Compressing with Batch
## What's this
Based on [Transcoding with Batch](https://github.com/GoogleCloudPlatform/batch-samples/tree/main/transcoding), added a handy script with PDF compressing example.

The starter script generates the required file from templates and submits the job to the Batch. You don't need to care filename or number of files. Process all PDF files in your bucket with Batch.

## Usage
Enable Batch API.
```
gcloud services enable batch.googleapis.com
```

Create and set a project if you need.

```
gcloud projects create [PROJECT_ID]
gcloud config set project [PROJECT_ID]
```
Make a bucket and copy example files there.

```
gsutil mb -p [PROJECT_ID] -b on -l US gs://[BUCKET_NAME]
gsutil cp -R input gs://[BUCKET_NAME]
```

Edit `starter.sh` and replace `[BUCKET_NAME]` with your bucket name.

```
# starter.sh

BUCKET_NAME="[BUCKET_NAME]"
```

`envsubst` is needed. It is in the `gettext` package if you have not installed it.

Run `starter.sh` when you are ready.

```
bash starter.sh
```

All done! PDF files are now in the queue and will be compressed by Batch shortly. You can check the status in the cloud console and results in `gs://[BUCKET_NAME]/output`.

## What starter.sh do for you
* Find PDF files in the bucket.
* Generate compressing script for each PDF file.
* Generate job.json.
* Submit the Batch job to the Google Cloud.

### Generate compressing script for each PDF file.
This is the line from `job.json`. You can see what happens when each task starts.

```json
"script": {
  "text": "bash /mnt/share/input/task${BATCH_TASK_INDEX}.sh"
}
```
Batch runs multiple tasks in parallel. Each task has `${BATCH_TASK_INDEX}`. It is from 0 to the number of tasks. In this case, Batch runs task0.sh, task1.sh... until the last task.

 ```sh
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
```
`starter.sh` generate task.sh file with hard-coded filenames in it. After run script, `gs://[BUCKET_NAME]/input` will be like this.

 ```
input
├── photobook-a.pdf
├── task0.sh
├── photobook-b.pdf
├── task1.sh
......
```

This is the generated task file. You can edit `task.sh.template` for your own purpose.

```
$ gsutil cat gs://[BUCKET_NAME]/input/task0.sh

#!/bin/bash

sudo apt-get -y update
sudo apt-get -y install ghostscript

filename=photobook-a.pdf

dir=/mnt/share
infile=$dir/input/$filename
outfile=$dir/output/${filename/.pdf/_compressed.pdf}
vopts="-sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -dQUIET"

mkdir -p $dir/output
gs $vopts -sOutputFile=$outfile $infile
```

### Generate job.json
``` sh
### Create job.json
echo "Creating job.json"
export BUCKET_NAME
export TASK_COUNT
cat job.json.template | envsubst '$BUCKET_NAME $TASK_COUNT'> $temp_dir/job.json
```
Generate job.json from the template. `$TASK_COUNT` decides how many tasks Batch processes in a job. So tell Batch the number of the task files in the bucket.


### Submit the job
``` sh
### Submit the job
echo "Submitting the job"
date=$(date +"%Y%m%d%H%M")
gcloud beta batch jobs submit pdf-compression_${date} --location=us-central1 --config=$temp_dir/job.json
```

Submit the job to Batch. The job name has to be unique, so add the submitting date here.



