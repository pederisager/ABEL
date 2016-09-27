#!/bin/tcsh
# submit a jobscript with "sbatch MyJobscript.tcsh Subjec_Identifier Session_Identifier Run_Identifier Design_name"

# other importent commands: 
# scancel jobid 				# Cancel job with id jobid (as returned from sbatch)
# scancel --user=MyUsername    	# Cancel all your jobs
# scancel --account=MyProject  	# Cancel all jobs in MyProject
# showq -u athanasm				# list jobs in the queue

# Job name:
#SBATCH --job-name=First6

# Project:
#SBATCH --account=UIO

# Wall clock limit:
#SBATCH --time=03:30:00

# Max memory usage:
#SBATCH --mem-per-cpu=4000M

# size of scratch disk:
# SBATCH --tmp=2000M

## Set up job environment
#source /site/bin/jobsetup

### This sources FSL where I have installed it.  
setenv FSLDIR /projects/psifmri/software/fMRI/fsl
source ${FSLDIR}/etc/fslconf/fsl.csh
setenv PATH ${FSLDIR}/bin:${PATH}

### This is an awk command that would allow you to do calculations with awk.	
alias calc 'awk "BEGIN{ print \!* }" '

# for use with sbatch as in "sbatch jobscript_fsl.tcsh 1"
set SUBID 		= $argv[1] 	# for running one participant 
set SESS 		= $argv[2] 	# for each session
set RUN 		= $argv[3] 	# for each RUN  
set DESIGNID 	= $argv[4]	# For the design to run. This would be an .fsf file you want to run.

### The folder where the $DESIGNID.fsf is stored.
setenv feat_root /projects/psifmri/fMRI/ADHD/feat

echo
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"		
echo "++++++++++++++++ Subject $SUBID Session$SESS Run$RUN $DESIGNID +++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"	
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++ FSL sourced  +++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++  ${FSLDIR} +++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


if (	-d /projects/psifmri/fMRI/ADHD/data/${SUBID}/session${SESS}/ \
	&& 	-s /projects/psifmri/fMRI/ADHD/data/${SUBID}/session${SESS}/ ) then
		
	### Folder where the filtered_func_data.nii.gz is. May also be raw data, whatever your $DESIGNID.fsf requires as input.	
	set FLDR = "/projects/psifmri/fMRI/ADHD/data/$SUBID/session$SESS/MRI/func/run$RUN"
	
	### Folder where behaviour data for task-fMRI is, if you have. Again, this depends on your setup.
	set behav = "/projects/psifmri/fMRI/ADHD/data/$SUBID/session$SESS/behavior/run$RUN"
	chmod a+wrx -R 	$FLDR/	
	
	set clean = `echo $DESIGNID | cut -d "_" -f 3`
	

	 if(! -e $FLDR/pre/full_NL/filtered_func_data.nii.gz ) then
		echo "++++++++++++++++ This subject has no filtered_func_data ++++++++++++++++++++++++++"
		echo "+++++++++++++++++++++++		 exiting script 	++++++++++++++++++++++++++++++"
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo ""
		set Date = `date`
		echo "++++++++++++++ Terminating script at $Date[2-4] ++++++++++++++"
		echo $Date[2-4] ${DESIGNID} $SUBID $SESS  $RUN - No filtered_func_data files >> ${DESIGNID}_fails.txt
		echo
		exit 0
	endif
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "++++++++++++++++++++++ stage 1, first level analysis ++++++++++++++++++++++++++++++"
	
	set Date = `date`
	echo "++++++++++++++++++++++ Preparing files at $Date[2-4] ++++++++++++++++++++++++++++++"
	echo
	
	### assigns a random temporary name
	set tmp_file = `mktemp`
	
	### This will be the file name for the subject spesific .fsf based on the DESIGNID.fsf
	set file = ${SUBID}_${SESS}_${RUN}


	### Find number of volumes, in case some subjects have less volumes.
	set act_num_vol = `fslval $FLDR/pre/full_NL/filtered_func_data.nii.gz dim4`	
	
	### This replaves several things in the $DESIGNID.fsf file. It requires that all subjects have folders setup in the exact same manner.
	### You'll need to tweak this depending on what you have to deal with. 
	### In my case, any occurence of "SUBID" in the $DESIGNID.fsf would be replaced with a subject identified, like "001".
	### I had two sessions, so the text "SESS" would be replaced with "1" for first session.
	### Each session had two runs of fMRI task, so the text "RUN" would be replaced with "2" for second session.
	### I replaced the actualy number of volumes in the fsf with the text "number_of_volumes", which would be replaced with the actual number of volumes as detected above.
	### Lastly, the output would be specified with "DESIGNID" in the .fsf file, so I could control where it was stored.
	### It replaces all these instances, and creates a new .fsf
	sed	-e "s/SUBID/$SUBID/g" \
		-e "s/SESS/$SESS/g" \
		-e "s/RUN/$RUN/g" \
		-e "s/number_of_volumes/$act_num_vol/g" \
		-e "s/DESIGNID/$DESIGNID/g" \
		${feat_root}/1/${DESIGNID}.fsf > ${tmp_file}.fsf




	# get name of original path for fsl results 
	# (results will copied from $SCRATCH to here after analysis is finished). Running analyses directly in $SCRATCH is much faster, 
	# it will be writted directly to a folder on the computer running the analysis. We will copy it back to where you want it later.
	set orig_output_dir = `awk '/outputdir/ {print $3}' ${tmp_file}.fsf | cut -d '"' -f 2`
	set input_dir = `awk '/feat_files/ {print $3}' ${tmp_file}.fsf | cut -d '"' -f 2 | cut -d "/" -f 1-13`
	#rm -rf $orig_output_dir		
	#mkdir -p $orig_output_dir
	
	# Applies registration to the input. Might not apply to you. I had run preprosessing on everything, but not registered it.
	featregapply $input_dir
	
	#find the number of contrasts
	set cope = `awk '/Title for contrast_orig/ {++c} END {print c}' ${tmp_file}.fsf`
	
	set tmp_dir = $SCRATCH/${file}.feat		
	echo "++++++++++++++ Input directory is: $input_dir"
	echo "++++++++++++++ SCRATCH output-directory: $tmp_dir"
	echo "++++++++++++++ Original output-directory: $orig_output_dir"
	echo
	
	# Creates directories you need. Again, this makes sense for me, might not for you.
	mkdir -p ${feat_root}/1/${DESIGNID}/
	mkdir -p $FLDR/1
				
	# replace original results-path with directory on $SCRATCH
	awk '{if ($2 == "fmri(outputdir)") print $1, $2, "'$tmp_dir'"; else print $0 }' \
		 ${tmp_file}.fsf > ${feat_root}/1/${DESIGNID}/${file}.fsf

	set Date = `date`
	echo "++++++++++++++++++++++ Starting analysis at $Date[2-4] ++++++++++++++++++++++++++++++"		
					
	# RUN analysis  
	feat ${feat_root}/1/${DESIGNID}/${file}.fsf
	echo
	
	### Copy the files from SCRATCH to the original destination
	mkdir -p $orig_output_dir
	cp -r $tmp_dir/* $orig_output_dir
	cp -r $input_dir/reg/ $orig_output_dir/
	chmod a+wrx -R $orig_output_dir

	set Date = `date`
	echo "++++++++++++++++ First stage completed at $Date[2-4] +++++++++++++++"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo ""	
	echo ""

	featregapply $orig_output_dir

	cd $feat_root/2
	set Run1Dir = `echo $orig_output_dir | sed -e "s/run2/run1/g"`
	
	
	## If this is the second run, continue on to intermediate level analyses.
	if($RUN == 2 && -f $orig_output_dir/thresh_zstat1.nii.gz && -d $Run1Dir) then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "++++++++++++++++++ stage 2, effects across runs +++++++++++++++++++++++++"
		echo
		
		## Chek if RUN1 is done, if not, create a delay, and test again. Continue when run1 is complete.
		set k = 1
		while( -d $orig_output_dir && ! -f $Run1Dir/reg_standard/mask.nii.gz && $k<20)
			set Date = `date`
			echo "run1 not completed yet. Waiting 5 minutes to test again.  Time is $Date[4]"
			sleep 300
			@ k++
		end
		
		set Date = `date`
		echo "++++++++++++++++++++++ Preparing files at $Date[2-4] ++++++++++++++++++++++++++++++"
		echo 
		set file = "${DESIGNID}_${SUBID}_${SESS}"
		set TYPE = `echo $DESIGNID | cut -d "_" -f 2`
		
		## Requires the intermediate fsf to have a specific name. and as before, SUBID, SESS and DESIGNID should be replaced appropriately
		sed -e "s/DESIGNID/$DESIGNID/g" \
			-e "s/SUBID/$SUBID/g" \
			-e "s/SESS/$SESS/g" \
			design_${TYPE}_base.fsf > ${tmp_file}.fsf
		
		# get name of local directory to write feat results to
		set tmp_dir = $SCRATCH/${file}.gfeat
		
		# get name of original path for fsl results 
		# (results will copied from $SCRATCH to here after analysis is finished)
		set orig_output_dir = `awk '/outputdir/ {print $3}' ${tmp_file}.fsf | cut -d '"' -f 2`
		echo "++++++++++++++ SCRATCH output-directory: $tmp_dir"
		echo "++++++++++++++ original output-directory: $orig_output_dir ++++++++++ "
		echo
		
		mkdir -p ${DESIGNID}
		
		# replace original results-path with directory on $SCRATCH
		awk '{if ($2 == "fmri(outputdir)") print $1, $2, "'$tmp_dir'"; else print $0 }' \
			 ${tmp_file}.fsf > ${DESIGNID}/${file}.fsf
		
		set Date = `date`
		echo "++++++++++++++++++++++ Starting analysis at $Date[2-4] ++++++++++++++++++++++++++++++"
		
		# run analysis  
		feat ${DESIGNID}/${file}.fsf
		echo
		
		rm -r 			$orig_output_dir
		mkdir -p 		$orig_output_dir
		cp -r 			$tmp_dir/* $orig_output_dir
		chmod a+wrx -R 	$orig_output_dir/
		
	### Run some checks if this is not run1.	
	else if(! -f $orig_output_dir/cluster_zstat1.txt) then
		echo "++++++++++++++ An error occured during lvl1 analysis or lvl 1 results were not copied to local folder correctly ++++++++++++++"
		echo
		
	else if(! -d $Run1Dir) then
		echo "++++++++++++++ lvl 1 not run for Run1 ++++++++++++++"
		echo "++++++++++++++ $Run1Dir "
		echo
		
	else
		echo "++++++++++++++ Stage 2 starts after run 2 is completed ++++++++++++++"
		echo "++++++++++++++++++++ This is run $RUN ++++++++++++++++++++"
		echo
	endif
	
else
	echo "++++++++++++++ session folder empty or does not exist ++++++++++++++"
	echo
endif

#Change permissions to output folders so other project collaborators may access results.
chmod a+wrx -R ${feat_root}/1
chmod a+wrx -R ${feat_root}/2

set Date = `date`
echo "+++++++++++++++++++ Script ended at $Date[2-4] ++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
echo
echo
