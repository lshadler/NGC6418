#!/bin/bash 
#
# stsp_runrev.sh 
#
# Script for running the TCX gen over one given rev
#
# Arg1 <revolution number>
#
# env vars used: 
#    STSPHOME
#    USES2K
#    STSPRUNVER
#
# History:
# CR x4   jcv 8-Oct-08 New env var USES2K
# CR x5   jcv 9-Oct-08 New env var STSPRUNVER 
# SPR x5  jcv 29-Oct-08 Args of stspproc may be read from locals env 
# CR x9   jcv 19-Jan-09 New stspmarkbad flag
# SPR x7  jcv 21-Jan-09 RunStrict Mode
# SPR x15 jcv 18-May-09 New args for passes processing 
# SPRx20  jcv 17-Dec-09 New parameter for not fitting anything
# SPRx25  jcv 10-Feb-10 New parameter for maxdelta in handovers
# CRx20   jcv 21-Sep-10 New parameter for handling interleaved tm
# SPRx36  jcv 10-Nov-11 File names should have padded revolution number
# CRx22   jcv 10-Nov-11 clean of nonICD columns may not take place 
# SPRx37  jcv 14-Nov-11 New parameter for fixing symmetric passes 
#
if [ $# != 1 ] ; then
 echo "Usage $0 <revolution number>"
 exit 0 
fi

echo "stsp_runrev.sh starting"
date
#
cd $STSPHOME

export STSPTHISREV=$1

echo "====================================================="
echo "TCXGen v $TCXVER"
echo "REVOLUTION $STSPTHISREV, Version $STSPRUNVER PROCESSING"
echo "====================================================="
#
# CRx5 proper version management
export STSPPADDEDVER=`printf "%04d" ${STSPRUNVER}`

#
# SPRx36 proper file names
export STSPPADDEDREV=`printf "%04d" ${STSPTHISREV}`

#export STSPROOTNAME=`echo RTX_${STSPTHISREV}_${STSPPADDEDVER}`
#export STSPLOGNAME=`echo RTX_run_${STSPTHISREV}_${STSPPADDEDVER}.log`
#export STSPDATANAME=`echo RTX_${STSPTHISREV}_${STSPPADDEDVER}.FIT`
export STSPROOTNAME=`echo RTX_${STSPPADDEDREV}_${STSPPADDEDVER}`
export STSPLOGNAME=`echo RTX_run_${STSPPADDEDREV}_${STSPPADDEDVER}.log`
export STSPDATANAME=`echo RTX_${STSPPADDEDREV}_${STSPPADDEDVER}.FIT`
#

# CR x5
if [ -f $STSPHOME/processed/data/$STSPDATANAME ]; then
	echo "INFORMATIONAL MESSAGE:";
	echo ">RTX file for revolution $STSPTHISREV and same version $STSPRUNVER exists";
	echo ">Please, cleanup manually and retry.";
else
	echo "Running stspproc --rev $STSPTHISREV versioned as $STSPRUNVER"

	# Run the task
	# CR x4,CR x5 
        # SPR x5, now some args can be run through locals env vars
        # CR x9 Then same
        # SPR x15 same
        # SPR x20 same
        # SPR x25 same
        # CRx20 same
        # CRx22 same
        # SPRx37 
	stspproc --prewindow=$STSPPREWIN --postwindow=$STSPPOSTWIN --revolution=$STSPTHISREV --useS2K=$USES2K --version=$STSPRUNVER --strict=$STSPSTRICT --markbad=$STSPMARKBAD --cachedir=$STSPHOME/rawtm/ --passfitpoints=$STSPPASSFITPOINTS --postpassdelay=$STSPPOSTPASSDELAY --performfit=$BESMART --maxdelta=$HOMAXDELTA --fullBTI=$STSPFULLBTI --keepancilliary=$KEEPANCILLIARY  --symthres=$SYMTHRESHOLD > $STSPLOGNAME 2>&1

	# Move newly created files to new directory
        echo "Moving newly created RTX files to /new directory"
        echo "(Here the files will be checked)"
	mv -f $STSPHOME/RTX_* $STSPHOME/new/

	#
	# Look for errors
        echo "Checking newly created files here: "  $STSPHOME/new/ 
        echo "Searching for errors (just in CAPITALS)"
	nErrors=`grep ERROR $STSPHOME/new/RTX_*log | wc -l`

	if (( $nErrors != 0)); then

    		echo "stspproc failed for Revolution" $STSPTHISREV
    		cat $STSPHOME/new/*.log
    		echo "Moving files to /error"
    		mv -f $STSPHOME/new/* $STSPHOME/error/

	else
                echo "Searching for WARNINGS (just in CAPITALS)"
    		nWarnings=`grep WARNING $STSPHOME/new/RTX_*log | wc -l`

    		if (( $nWarnings != 0)); then

			echo "stspproc completed with warnings in Rev" $STSPTHISREV
			echo "************************************"
			echo "> dumping log file here."
			echo "************************************"
			cat $STSPHOME/new/*.log
			echo "************************************"
			echo "> ending dump log file here."
			echo "************************************"
    	                echo "Moving files to /warning"
			mv -f $STSPHOME/new/* $STSPHOME/warning/

    		else

			echo "stspproc completed successfully in Rev " $STSPTHISREV
			echo "Moving to /processed "
			mv -f $STSPHOME/new/RTX*FIT  $STSPHOME/processed/data/
			mv -f $STSPHOME/new/RTX*ps   $STSPHOME/processed/ps/
			mv -f $STSPHOME/new/RTX*log  $STSPHOME/processed/log/
			mv -f $STSPHOME/new/RTX*stsp $STSPHOME/processed/stsp/


    		fi

		fi
fi

echo "stsp_runrev.sh ending"
