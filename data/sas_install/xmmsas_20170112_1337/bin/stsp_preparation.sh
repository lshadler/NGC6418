#!/bin/bash
#
# stsp_preparation.sh 
#
# Script for getting fds data for the TCX gen environment
#
# Env. Vars used: 
#  STSPHOME
#  STSPFDS
#  STSPXMMURL
#
# CR x4 jcv 8-Oct-08 New env variable for XMM URL
#

echo "stsp_preparation starts"
date

echo "GETTING FDS DATA"
echo "===================="
#
# Get the orbita file from the website  
echo "Getting orbita file"
#wget -q http://xmm.vilspa.esa.es/~xmmdoc/orbit/data/orbita.tar.gz -O $STSPFDS/orbita.tar.gz
wget -q $STSPXMMURL/orbita.tar.gz -O $STSPFDS/orbita.tar.gz

#
# Untar it
tar zxf $STSPFDS/orbita.tar.gz  -C $STSPFDS/

#
# Get the Revolution number from the website
echo "Getting latest revno file"
#wget -q http://xmm.vilspa.esa.es/~xmmdoc/orbit/data/revno -O $STSPFDS/revno
wget -q $STSPXMMURL/revno -O $STSPFDS/revno
#
# Format it into the required form
grep "START REVOLUTION" $STSPFDS/revno | awk '{print $7,$4}' > $STSPHOME/revno.txt

echo "stsp_preparation ending"
