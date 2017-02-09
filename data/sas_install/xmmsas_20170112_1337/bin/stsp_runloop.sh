#!/bin/bash
#
# stsp_runloop.sh 
#
# Script for looping over latest revs and running the TCX gen
#
# Env vars used: 
#    STSPHOME
#    STSPRAWDELETION
#    STSPREVLOOP
#    STSPREVCHECK
#
# CR x4 8-Oct-08 New env var for customizing the main loop

echo "stsp_runloop starting"
date

echo "STARTING LOOP PROCCESSING"
echo "========================="
#
# Get the revolution number
currentrev=`whichrev -V 0`

#let firstrev=$(( $currentrev - 4 ))
let firstrev=$(( $currentrev - $STSPREVLOOP ))

for ((i = $firstrev; i < $currentrev; i++)) ; do

	#if (($i%30==0));
	if (($i%$STSPRAWDELETION==0));
	then
	       	rm $STSPHOME/rawtm/*DAT;
	fi;
 
	echo "Calling runrev $i ";
        stsp_runrev.sh $i

done

echo "Final check about -5 revs"

#let checkrev=$(( $currentrev - 5 ))
let checkrev=$(( $currentrev - $STSPREVCHECK ))

if [ -f $STSPHOME/processed/data/RTX_$checkrev*.FIT ]; then
	echo "RTX file for revolution "$checkrev exists;
else
	echo "RTX file for " $checkrev " does not exist. Better check!"
fi

echo "stsp_runloop ending"
