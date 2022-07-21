#!/bin/bash
if [ $BATCH_TASK_INDEX = 0 ]; then
  . /mnt/share/spack/share/spack/setup-env.sh
  spack load gcc@8.2.0
  spack compiler find
  spack load wrf
  cd /mnt/share/batch
  mpirun -hostfile $BATCH_HOSTS_FILE -np 120 -ppn 30 $PWD/wrf.exe
fi
