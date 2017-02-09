#!/bin/bash
#
# stsp_setclenaup.sh 
#
# Script for cleaning up the TCX gen environment
#
# Env vars used: STSPHOME
#

#
# Move newly created files to new directory
echo "Checking newly created files in $STSPHOME"
if [ -f $STSPHOME/RTX_* ]; then
    echo "Found. Moving newly created files to /spare"
    mv -f $STSPHOME/RTX_* $STSPHOME/spare/
fi

#
# Move any remnant from previous runs to processed directory
echo "Checking remnant files from previous runs files in /new"
if [ -f  $STSPHOME/new/* ]; then
    echo "Found. Moving remnant files to /spare"
    mv -f $STSPHOME/new/* $STSPHOME/spare/
fi

#

