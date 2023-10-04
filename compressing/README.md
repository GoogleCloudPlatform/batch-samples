# Compressing with Batch
## What's this?
Based on [Transcoding with Batch](https://github.com/GoogleCloudPlatform/batch-samples/tree/main/transcoding), added a handy script with PDF compressing example.

The starter script generates necessary files from templates and submits the job to the Batch. Process all PDF files in your bucket with Batch. You don't need to care filename or number of files.

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
Make a bucket and copy `input` directory there.

```
gsutil mb -p [PROJECT_ID] -b on -l US gs://[BUCKET_NAME]
gsutil cp -R input gs://[BUCKET_NAME]
```

Edit `starter.sh` and replace `[BUCKET_NAME]` with your bucket name.

```
# starter.sh

BUCKET_NAME="[BUCKET_NAME]"
```
Run `starter.sh`.

Note: `envsubst` is used in the script. If `which envsubst` does not return the command path, try installing `gettext` package first.

```
bash starter.sh
```

All done! PDF files are in the queue and will be compressed by Batch shortly. You can see job name and status in the Cloud Console as well. The compressed PDF will be in `gs://[BUCKET_NAME]/output`.

## What starter.sh do for you
* Find PDF files in the bucket.
* Generate compressing script for each PDF file.
* Generate job.json.
* Submit the Batch job to the Google Cloud.

### Generate compressing script for each PDF file.
`job.json` describes the task executed by Batch.

```json
"script": {
  "text": "bash /mnt/share/input/task${BATCH_TASK_INDEX}.sh"
}
```
```
"taskCount": 3,
```

In the above example, task0.sh task1.sh task2.sh will be executed. Each task has `${BATCH_TASK_INDEX}`. It is from 0 to the number of `taskCount`.

`starter.sh` generate task.sh files while hard-coding PDF filename.

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
After run script, `gs://[BUCKET_NAME]/input` will be like this.

 ```
input
├── photobook-a.pdf
├── task0.sh
├── photobook-b.pdf
├── task1.sh
......
```

This is the generated task file.

```
gsutil cat gs://[BUCKET_NAME]/input/task0.sh
```

```sh
#!/bin/bash

sudo apt-get -y update
sudo apt-get -y install ghostscript

filename=photobook-a.pdf #filename is inserted from the template.

dir=/mnt/share
infile=$dir/input/$filename
outfile=$dir/output/${filename/.pdf/_compressed.pdf}
vopts="-sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -dQUIET"

mkdir -p $dir/output
gs $vopts -sOutputFile=$outfile $infile
```


The key point is that `starter.sh` passes `$FILE_NAME` to `task.sh.template` and generated `task0.sh` with the PDF file name in it. In the result, Batch executes `task${BATCH_TASK_INDEX}.sh` one after another to compress each PDF file.

You can edit `task.sh.template` for your purpose.

### Generate job.json
``` sh
### Create job.json
echo "Creating job.json"
export BUCKET_NAME
export TASK_COUNT
cat job.json.template | envsubst '$BUCKET_NAME $TASK_COUNT'> $temp_dir/job.json
```
Generate job.json from the template. `$TASK_COUNT` decides how many tasks Batch processes in a job. So tell Batch the number of the task files in the bucket.

If you want to change parameters such as machine type, running duration, and the number of tasks in parallel, edit `job.json.template`.

### Submit the job
``` sh
### Submit the job
echo "Submitting the job"
date=$(date +"%Y%m%d%H%M")
gcloud beta batch jobs submit pdf-compression_${date} --location=us-central1 --config=$temp_dir/job.json
```

Submit the job to Batch. The job name has to be unique, so add the submitting date here.

This is the whole process of getting file names, generating the necessary files, and submitting the jobs to Batch.
