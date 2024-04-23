#!/bin/bash

#SBATCH --job-name=google                   # a short name for job
#SBATCH --nodes=1                		    # node count
#SBATCH --ntasks-per-node=2                 # total number of tasks across all nodes
#SBATCH --cpus-per-task=1                   # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --gpus-per-task=1                   # gpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=64G                   # memory per cpu-core (4G is default)
#SBATCH --gres=gpu:2                        # number of gpus per node
#SBATCH --time=00:10:00                     # total run time limit (HH:MM:SS)
#SBATCH --output=%x.out                     # output stream
#SBATCH --error=%x.err                      # error stream
#SBATCH --export=all

# Now initialise the module list for the cluster
