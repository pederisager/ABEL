#!/bin/bash

#SBATCH --account=uio
#SBATCH --time=0:0:10
#SBATCH --mem-per-cpu=256M

source /cluster/bin/jobsetup

module purge	# clear any inherited modules
set -o errexit	# exit on errors

module load fsl	# Will load the default version of FSL in ABEL (check using module avail).

OUTFILE=$TASK_ID.feat/

cd $SCRATCH

chkfile $OUTFILE
mkdir -p $OUTFILE/$OUTFILE
echo "1" > $OUTFILE/$OUTFILE/1.txt
