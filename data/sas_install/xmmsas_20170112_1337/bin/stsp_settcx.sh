#!/bin/bash
#
# stsp_settcx.sh 
#
# Script for setting up the TCX gen environment
#
# CRx1 jcv 2008-10-07 New env variables for local raw repository
# CRx2 jcv 2008-10-08 New env variables for TCX and DELAYS versions 
# CRx4 jcv 2008-10-08 New file for local setup, overriding default vars 
#                     New env var for reading SCOSI or S2K rawfiles
#                     New env var for reading xmm URL
#                     New env vars for looping
#                     Fixed CRx1 env var name as STSPLOCALCACHE 
# CRx5 jcv 2008-10-09 Enhanced versioning with STSPRUNVER
# SPRx2 jcv 2008-10-09 Enhanced Delays.fit management 
# SPRx5 jcv 2008-10-28 Now some args can be run as env vars 
# SPRx5x6 jcv 2009-1-15 Updated version to 1.1 
# CRx9 jcv 2009-1-19 New markbad flag
# SPRx7 jcv 2009-01-21 Strict runs for ignoring abort signal
# SPRx8 jcv 2009-03-02 Local loader scripts may be required 
# SPRx9 jcv 2009-03-04 STSPHOME may be defined somewhere else 
# SPRx15 jcv 2009-05-18 New envs for passes processing
# SPRx20 jcv 2009-12-17 New paramater for not fitting anything
# SPRx21 jcv 2010-02-03 Update to ver1.4 
# SPRx23 jcv 2010-02-04 Update to ver2.0 
# SPRx25 jcv 2010-02-10 New parameter maxdelta
# CRx20 jcv 2010-09-21 NEw param for handling interleaved TM
# CRx22 jcv 2011-11-10 New param for keeping ancilliary columns in file 
# SPRx37 jcv 2011-11-14 New parameter symthres for fixing symm passes 
#
export STSPFDS=$HOME/Tcxgen/fds
# SPR x9
#export STSPHOME=$HOME/Tcxgen/tcx_data
if  [ ! -z "$STSPHOME" ]; then
 echo "STSPHOME found defined as  $STSPHOME"
else
 echo "STSPHOME not defined. Defining it by default."
 export STSPHOME=$HOME/Tcxgen/tcx_data
fi
#
# CRx1
# CRx4 Renamed STSPLOCAL_YES to STSPLOCALCACHE 
export STSPLOCALCACHE=FALSE
# SPR x8
# Do not uncomment unless the default behaviour should be local scripting
#export STSPLOCALLOADER=stsp_loader.sh
#
# CRx2
# SPRx2
# SPRx5x6x7x13x23
export TCXVER=2.1
#
export TDLYFILENAME=delays.fit

# SPRx12
export STSPRAWUSER=rawtm
export STSPRAWPASS=2x5ten
export STSPRAWNODE=xsa01

# CRx5
export STSPRUNVER=1
#
# CRx4
export STSPLOCALS=stsp_locals.sh
export USES2K=yes
export STSPXMMURL=http://xmm.vilspa.esa.es/~xmmdoc/orbit/data/
export STSPRAWDELETION=30
export STSPREVLOOP=4
export STSPREVCHECK=5
#
# SPR x5
export STSPPREWIN=120000
export STSPPOSTWIN=80000
#
# CR x9
export STSPMARKBAD=yes
#
# SPR x7
export STSPSTRICT=yes
#
# SPRx15
export STSPPASSFITPOINTS=20
export STSPPOSTPASSDELAY=15
#
# SPRx20
export BESMART=yes
#
# SPRx25
export HOMAXDELTA=0.00005
#
# CRx20
export STSPFULLBTI=no
#
# CRx22
export KEEPANCILLIARY=no
#
# SPRx37
export SYMTHRESHOLD=0.2

#
if [ -f $STSPHOME/$STSPLOCALS ]; then
   echo "Local file for local environment found. Running it."
   . $STSPHOME/$STSPLOCALS 
else
   echo "Local file for local environment not found. Running defaults."
fi
# End CRx4

mkdir -p $STSPHOME/rawtm
mkdir -p $STSPHOME/new
mkdir -p $STSPHOME/spare
mkdir -p $STSPHOME/error
mkdir -p $STSPHOME/warning
mkdir -p $STSPHOME/processed/data
mkdir -p $STSPHOME/processed/ps
mkdir -p $STSPHOME/processed/log
mkdir -p $STSPHOME/processed/stsp

ln -s $STSPFDS/orbita  $STSPHOME/fort.68
ln -s $STSPFDS/stations.sdid  $STSPHOME/fort.69

#

