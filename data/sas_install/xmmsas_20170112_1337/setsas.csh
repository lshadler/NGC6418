#!/bin/csh
#
# setsas.csh - Automatically generated by configure_install at installation
#
# $Id: configure_install,v 1.15 2013/12/09 14:57:13 eojero Exp $
#

set platform=`uname -s`

if ( ! $?LHEASOFT ) then 
  echo "setsas.csh: Error - Please define and initialize HEASOFT !"
  exit 1
endif


# C-shell does not like undefined env. variables

if ( ! $?LD_LIBRARY_PATH ) then
  setenv LD_LIBRARY_PATH ""
endif

if ( $platform == "Darwin" &&  ! $?DYLD_LIBRARY_PATH ) then
  setenv DYLD_LIBRARY_PATH ""
endif

if ( ! ${?SAS_PREV_PATH} ) then 
  setenv SAS_PREV_PATH                   $PATH
  if ( $platform == "Darwin" ) then
    setenv SAS_PREV_DYLD_LIBRARY_PATH    $DYLD_LIBRARY_PATH
  else
    setenv SAS_PREV_LD_LIBRARY_PATH      $LD_LIBRARY_PATH
  endif
else
  setenv PATH                            $SAS_PREV_PATH
  if ( $platform == "Darwin" ) then 
    setenv DYLD_LIBRARY_PATH             $SAS_PREV_DYLD_LIBRARY_PATH
  else
    setenv LD_LIBRARY_PATH               $SAS_PREV_LD_LIBRARY_PATH
  endif  
endif

setenv SAS_DIR /home/lshadler/Documents/data_capstone/sas_install/xmmsas_20170112_1337
# Unset any previous definition of SAS_PATH (previous SAS initializations!)
unsetenv SAS_PATH
source $SAS_DIR/sas-setup.csh
if ( $platform == "Darwin" ) then 
  limit datasize unlimited
  limit stacksize 65532
endif

echo ; sasversion
echo ; echo "Do not forget to define SAS_CCFPATH, SAS_CCF and SAS_ODF"; echo
