#!/bin/tcsh

# submit a jobscript with "sbatch MyJobscript.tcsh"
# other importent commands: 
# scancel jobid 				# Cancel job with id jobid (as returned from sbatch)
# scancel --user=MyUsername    	# Cancel all your jobs
# scancel --account=MyProject  	# Cancel all jobs in MyProject
# showq -u danmikae				# list jobs in the queue

# Job name:
#SBATCH --job-name=feat_{$TASK_ID}

# Project:
#SBATCH --account=uio

# Wall clock limit:
#SBATCH --time=24:00:00

# Max memory usage:
#SBATCH --mem-per-cpu=5000M

# priority: (will be submitted faster when low, but might then be aborted)
#SBATCH --partition=lowpri 

## load fsl
module load fsl/4.1.7
source $FSLDIR/etc/fslconf/fsl.csh

set anID = correct_evs
set fsf_root =  /cluster/home/danmikae/fsf/secondlevel/$anID
cd $fsf_root


set start_date = `date`
echo ++++++++++ starting feat $TASK_ID at $start_date[2-4] ++++++++++

# run analysis
feat $fsf_root/{$TASK_ID}.fsf


set end_date = `date`
echo ++++++++++ Feat finished at $end_date ++++++++++
