# Introduction

This example shows how to train a [convolutional neural network](https://en.wikipedia.org/wiki/Convolutional_neural_network)
using a multi-node [Batch](https://cloud.google.com/batch/docs/get-started) job.
The example model will be trained to distinguish pictures of cats
from pictures of dogs, using the dataset from the Kaggle competition
[Dogs vs. Cats](https://www.kaggle.com/competitions/dogs-vs-cats).

In order to run the training job you will need to download the data set
from Kaggle using

```
kaggle competitions download -c dogs-vs-cats
```

as described on the Dogs vs. Cats competition's [data page](https://www.kaggle.com/competitions/dogs-vs-cats/data).
The complete dataset (including test data and a sample submission) is around 800 MB zipped.
It contains a file, "train.zip", which is all that's needed for the Batch sample.

**You do not need to inflate train.zip in order to run the Batch sample.**

Two Batch jobs are involved in the training process. The first job preprocesses
the 25000 images of dogs and cats in the training data using general purpose
machines from the e2 family. The second uses pytorch on several nodes with NVIDIA
V100 GPUs to train a CNN on the preprocessed images.

# Computing environment

There are only two prerequisites for running the sample:

1. You will need to put train.zip **not inflated** in a directory on a [Filestore](https://cloud.google.com/filestore),
which you will point to with both the preprocessing and training jobs.
2. You will need to place a container image with the required Python packages and
utility scripts (see the provided Container directory) on the [Artifact Registry](https://cloud.google.com/artifact-registry),
where it can be pulled as needed by the Batch jobs.

You can build the required docker image by cd'ing to the provided Container directory and running

```
docker build .
```

This command will build an image with the Python and shell scripts used by both Batch jobs,
and the various libraries those scripts need to run.

## The preprocessing job

The preprocessing job is described in the file normalize.yaml. Its purpose is to transform the
25000 images of dogs and cats in train.zip from RGB to grayscale, and to give them all a uniform
128x128 pixel dimension. After filling in the details of your Filestore and docker image in
normalize.yaml, you can run the job with

```
gcloud batch jobs submit normalize --project=<your project> --location=<any region, e.g. us-central1> --config=normalize.yaml
```

This job will allocate 100 (controlled by taskCount) e2-standard-4 machines, which will all pull
the container and mount the Filestore. Each machine will then process 125 images of cats and 125
images of dogs (size controlled by the BIN_SIZE environment variable) from train.zip, found in
the DATA_ROOT directory, repackage the resulting 250 images into a zip archive called
"bin\<index\>.zip" and place that archive back on the Filestore in the DATA_ROOT directory.

When the preprocessing job completes there will be archives bin0.zip through bin99.zip in the
DATA_ROOT directory. These archives will be used by the training job in the next step.

## Training the CNN

The training job is described in the file train.yaml. After filling in the details of your
Filestore and docker image in train.yaml, you can run the job with

```
gcloud batch jobs submit train --project=<your project> --location=<any regino, e.g. us-central1> --config=train.yaml
```

The training job allocates eight n1-standard-4 machines equipped with NVIDIA V100 GPUs. Batch
takes care of all the details related to installing drivers and configuring docker so it will
have access to the GPUs.

Each n1-standard-4 in the training job starts by copying the 100 bin\<index\>.zip archives from
the Filestore to the local machine, and inflating them into a complete training set under /tmp.

```
/tmp
    train
        dog
            0.jpg
            1.jpg
            ...
            12499.jpg
        cat
            0.jpg
            1.jgp
            ...
            12499.jpg
```

After the training data has been localized to each machine, all machines proceed to run the
same pytorch training script. Batch coordinates this process in two ways:

1. Batch arranges for each node to run the pytorch training script only after the training
data has been localized on every machine.
2. Batch provides necessary arguments to torchrun (see Container/scripts/runtorch.sh) via
envirornment variables, to determine how the nodes should share training tasks (which node
is the rendezvous endpoint, which port to use, how many nodes are in the job, etc.).

The nodes in the training job will work together to train a CNN (defined in
Container/scripts/multi-train.py) to distinguish images of cats from images of dogs.
You can follow the training's progress in the training job's details page in the
Google Cloud web UI. The training will run for 50 epochs, reporting average loss
over the training set for each epoch.

When training completes the node with global rank 0 will copy the state of the
trained model back to the shared Filestore (again, at DATA_ROOT) in a file
called final.pt.