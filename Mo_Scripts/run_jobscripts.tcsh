#!/bin/csh
##By Athanasia Monika Mowinckel
# use:
# tcsh run_jobscripts.tcsh DESIGNID
# 
# - DESIGNID is the base fsf file to be called upon
#
#This scripts assumes 2 sessions and 2 runs. 
#It calls the slurm script jobscript_FirstSecond.sl with sbatch
#####

if($#argv == 0) then
	echo "You must provide a design name as an argument"
	exit 0
endif

## Navnet på .fsf filen som er satt opp som du ønsker kjøre. 
set design = $argv[1]

## Denne leser en liste en fil som lister alle deltagerne. En deltager per linje.
foreach sbj(`cat ../subject_lists/SubsAll.txt`)
#foreach sbj(002 004 051 054 055 111 116 119 120 402 454 512 518 554 594 599)

#Jeg har to tidspunkter med data per delager
	foreach session(1 2)
	
	#Jeg har også to runder med oppgave per tidspunkt også.
		foreach run(1 2)
			echo ""

			echo "${sbj} ${session} ${run} ${design}"
			sbatch -J ${IW}_${clean}_${sbj}_${session}_${run} jobscript_FirstSecond.sl $sbj $session $run $design
			sleep .10
			
		end #End run
	end #End session
end #End sbj


