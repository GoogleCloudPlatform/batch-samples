#!/bin/bash

torchrun \
    --nproc_per_node=1 \
    --nnodes=$BATCH_NODE_COUNT \
    --node_rank=$BATCH_NODE_INDEX \
    --rdzv_id=$BATCH_JOB_UID \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$BATCH_MAIN_NODE_HOSTNAME:29703 \
    /mnt/disks/dogs-vs-cats/scripts/multi-train.py
