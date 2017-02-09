# rwut_getraw.sh
#
# Script for getting the raw files  and sending to the cachedir
#
# Usage: $0 [cache dir] [ftp command to perform] 
# Arg1 [cache dir]
# Arg2 [ftp command to perform]
#
# Env var used: 
# STSPLOCALCACHE used for trying local better than ftp
#
# History
# CR x1 jcv 7-Oct-08 STSPLOCAL_YES for local raw tm cache usage 
# CR x4 jcv 8-Oct-08 Renamed STSPLOCAL_YES to STSPLOCALCACHE 
# SPR x8 jcv 03-Feb-09 Now local loader script may be invoked 
# SPR x8b jcv 03-Feb-09 Fixed local loader arguments 
# SPR x12 jcv 17-Apr-09 Ftp user/pass got from env variable 
#
date
#
MYCACHE=$1
MYCOMMAND=$2
#
export STSPDEFAULT=yes

if  [ ! -z "$STSPLOCALLOADER" ]; then 
 echo "Local script for loading raw tm defined."
 if [ -f $STSPHOME/$STSPLOCALLOADER ]; then
   echo "Found. Raw tm will get loaded by local script. Running it."
   MYFILE=`basename $MYCOMMAND`
   $STSPHOME/$STSPLOCALLOADER $MYFILE $MYCACHE
   export STSPDEFAULT=no
 else
   echo "Not found. Local script $STSPLOCALLOADER not found in $STSPHOME."
 fi
fi

if  [ "$STSPDEFAULT" == "yes" ]; then
   echo "Raw tm will get loaded by default scripts."
   echo "rawfiles will be located into $MYCACHE..."
   if [ "$STSPLOCALCACHE" = "TRUE" ] ; then
      echo "...BE SURE they are already there, working in local mode!"
   else
#     NEW SPRx12
#      MYFILE=`basename $MYCOMMAND`
#      MYFTP=`echo "ftp://""$STSPRAWUSER"":""$STSPRAWPASS""@""$STSPRAWNODE""/""$MYFILE"`
#      echo "...by retrieving them from remote dir using $MYFTP"
#      echo "...by retrieving them from remote dir using $MYCOMMAND"
#     export my_command="wget -nv -nc -P$MYCACHE -nH --cut-dirs=2 $MYCOMMAND" 
#      export my_command="wget -nv -nc -P$MYCACHE -nH --cut-dirs=2 $MYFTP" 
#      $my_command
      echo " $MYCOMMAND $MYCACHE \n "
      $MYCOMMAND $MYCACHE
#     END SPRx12 
   fi
fi

echo "exiting from rwut_getraw.sh"

