#!/bin/bash
#
# stsp_runtcx.sh 
#
# Script for running TCX gen
#
# Usage: $0 [<rev>] / default=routine loop
# Arg1 [revolution number]
#
# Env var used: STSPHOME
#

date

if [ $# = 0 ] ; then
 runmode=`echo "loop"` 
else
 runmode=`echo "single"`
 myrev=$1
fi
echo "------------------"
echo "Starting tcxgen in mode $runmode"

. stsp_settcx.sh

echo "Using STSPHOME as " $STSPHOME
echo "------------------"

#
cd $STSPHOME

stsp_preparation.sh
stsp_cleanup.sh

if [ "$runmode" = "single" ] ; then
  echo "calling runrev $myrev"
  stsp_runrev.sh $myrev 
else
   echo "calling runloop"
 stsp_runloop.sh 
fi

echo "------------------"
echo "runtcx EXITING"
echo "------------------"
