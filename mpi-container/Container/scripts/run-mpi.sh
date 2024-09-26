#/bin/bash

if [ $BATCH_NODE_INDEX = 0 ]; then
    mpirun --hostfile $BATCH_HOSTS_FILE -np 2 -ppn 1 hostname
fi
