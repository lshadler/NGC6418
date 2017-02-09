#
# XMM Science Analysis System set up script for Bourne-like shells
#
# This script must be sourced. Otherwise it will not work and will 
# output an error message in case a "return" statement is reached (bash).
# In tcsh, the return is not built-in so an "exit" is required.
#
# Bourne shell (/bin/sh) does not like the "export" in the same
# line that variable is assigned. Keep the export standalone for 
# compatibility. Bourne-gaian shell or Bash, has not problem with this.
#
# $Id: sas-setup.sh.in,v 1.62 2013/10/21 09:37:04 eojero Exp $

#  $SAS_DIR must be defined, otherwise the script returns.

if test -z "$SAS_DIR" ; then
  echo "sas-setup.sh error: SAS_DIR is undefined - Please define it !"
  # Use return, not exit, with status 1. Usage of exit will kill the terminal.
  return 1    
fi

#
# Since SAS 10.0.0 LHEASOFT must be initialized prior to SAS.
# Latest versions of HEADAS also define LHEASOFT, so it is enough to test for that variable
#

if test -z "$LHEASOFT" ; then 
  echo "sas-setup.sh error: LHEASOFT is undefined - Please define and initialize HEADAS !"
  return 1  
fi

#
# Handling of SAS_PATH.
#
# This is used only by SAS developers. For them, it is a way to add up 
# some test binaries and libraries to those provided by SAS under $SAS_DIR. 
# 
# If $SAS_PATH is not set by the user, it is set to $SAS_DIR.

[ -z "$SAS_PATH" ] && export SAS_PATH=$SAS_DIR


# To make this script compatible with users of Z-shell

shell=`basename echo $SHELL`

if [ "$shell" = "zsh" ] ; then 
  ( is_shwordsplit=`builtin setopt | egrep 'ˆshwordsplit$'` ) > /dev/null 2>&1
  builtin setopt SH_WORD_SPLIT > /dev/null 2>&1
fi


#
# Modify PATH, LIBRARY_PATH and LD_LIBRARY_PATH (DYLD_LIBRARY_PATH on Mac OS X)
#
# Will look for all bin, lib and lib/perl5 subdirectories in $SAS_PATH
# Since $SAS_PATH can have other paths besides $SAS_DIR, separated by ":"
# it will split them into components. 
# To do that, it will change the Internal Separator Field variable or $IFS 
# to be temporarily a blank space. Then, it will "set" $SAS_PATH" to identify
# their components, if any, as parameters $1, $2, etc.
#  
# binpath  = all bin subdirectories in SAS_PATH (+= PATH)
# libpath  = all lib subdirectories in SAS_PATH (+= LIBRARY_PATH/(DY)LD_LIBRARY_PATH )
# perlpath = all lib/perl5 subdirectories in SAS_PATH (+= LD_LIBRARY_PATH)

# Trick to break down into directory components the $SAS_PATH, if any.

ifs=$IFS
IFS=:

# The next trick converts $SAS_PATH into a string of directories separated by spaces.

set $SAS_PATH

# Reset to default the $IFS
IFS=$ifs

binpath=
libpath=
perlpath=

first=0

# $1 is the first substring in $SAS_PATH/$SAS_DIR, from the left.
# The shift command below will bring successive substrings into $1.
# In case $SAS_PATH is equal to $SAS_DIR, $1 is the only directory.

while test $# -gt 0 ; do
  if test $first -eq 0 ; then
    first=1
    binpath=$1/bin:$1/bin/devel
    libpath=$1/lib   
    perlpath=$1/lib/perl5
  else
    binpath=$binpath:$1/bin:$1/bin/devel
    libpath=$libpath:$1/lib   
    perlpath=$perlpath:$1/lib/perl5
  fi
  shift
done

# To make this script compatible with Z-shell users (see above)

if [ "$shell" = "zsh" ] ; then 
  if [ ! $is_shwordsplit ]; then
    builtin unsetopt SH_WORD_SPLIT > /dev/null 2>&1
  fi
fi

# The PATH is modified to prepend to it $binpath (+ $SAS_DIR/binextra).

PATH=${SAS_DIR}/binextra:${binpath}:${PATH}
export PATH



# The LIBRARY_PATH is modified to prepend to it $libpath

if test -z "$LIBRARY_PATH" ; then
  LIBRARY_PATH=$libpath
else
  LIBRARY_PATH=$libpath:$LIBRARY_PATH
fi


# In addition we prepend $SAS_DIR/libsys:$SAS_DIR/libextra to LIBRARY_PATH

LIBRARY_PATH=$SAS_DIR/libsys:$SAS_DIR/libextra:$LIBRARY_PATH

export LIBRARY_PATH



# The (DY)LD_LIBRARY_PATH is modified to prepend to it the $libpath
#
# Do not mix one with other to avoid messing them up

os=`uname -s`

if [ "$os" = "Darwin" ] ; then

  if test -z "$DYLD_LIBRARY_PATH" ; then
    DYLD_LIBRARY_PATH=${libpath}
  else
    DYLD_LIBRARY_PATH=${libpath}:$DYLD_LIBRARY_PATH
  fi

  # Prepend $SAS_DIR/libsys:$SAS_DIR/libextra to DYLD_LIBRARY_PATH

  DYLD_LIBRARY_PATH=$SAS_DIR/libsys:$SAS_DIR/libextra:$DYLD_LIBRARY_PATH

  export DYLD_LIBRARY_PATH

else

  if test -z "$LD_LIBRARY_PATH" ; then
    LD_LIBRARY_PATH=${libpath}
  else
    LD_LIBRARY_PATH=${libpath}:$LD_LIBRARY_PATH
  fi

  # Prepend $SAS_DIR/libsys:$SAS_DIR/libextra to LD_LIBRARY_PATH

  LD_LIBRARY_PATH=$SAS_DIR/libsys:$SAS_DIR/libextra:$LD_LIBRARY_PATH

  export LD_LIBRARY_PATH

fi


# PERL5LIB

if test -z "$PERL5LIB" ; then
  PERL5LIB=$perlpath
else
  PERL5LIB=$perlpath:$PERL5LIB
fi


# If PERLLIB exists, append it to PERL5LIB

if test ! -z "$PERLLIB" ; then
  PERL5LIB=$PERL5LIB:$PERLLIB
fi

export PERL5LIB


#
# LaTeX and BibTeX -- the trailing `:' is mandatory, otherwise
# if kpathsea is used the system defaults are lost.
#

#
# $SAS_DIR/packages/sas/doc/lib is available only on builds of SAS. 

if test -d "$SAS_DIR/packages/sas/doc/lib" ; then

  # TEXINPUTS

  if test -z "$TEXINPUTS" ; then
    TEXINPUTS=$SAS_DIR/packages/sas/doc/lib:.:
  else
    TEXINPUTS=$SAS_DIR/packages/sas/doc/lib:.:${TEXINPUTS:-}:
  fi

  export TEXINPUTS

  # BIBINPUTS

  if test -z "$BIBINPUTS" ; then
    BIBINPUTS=$SAS_DIR/packages/sas/doc/lib:.:
  else
    BIBINPUTS=$SAS_DIR/packages/sas/doc/lib:.:${BIBINPUTS:-}:
  fi

  export BIBINPUTS

fi

#
# Default SAS image viewer
#

if [ -z "$SAS_IMAGEVIEWER" ] ; then
  SAS_IMAGEVIEWER=ds9
fi

export SAS_IMAGEVIEWER

#
# .sas.d directory and config
#

if [ -z "$SAS_PIPELINE" ] ; then
   if [ ! -d $HOME/.sas.d ] ; then
      mkdir $HOME/.sas.d
   fi
   if [ ! -d $HOME/.sas.d/config ] ; then
      mkdir $HOME/.sas.d/config
   fi
#   export SAS_PATH=$HOME/.sas.d/:$SAS_PATH
fi


# Set SAS_BROWSER to whatever is determined by the SAS configure 

if [ -z "$SAS_BROWSER" ] ; then
  SAS_BROWSER="nobrowser"
fi

export SAS_BROWSER

# Set PGPLOT_FONT to the grfont.dat provided by SAS (which must be in libextra)
# so SAS applications depending on pgplot can draw properly pgplot fonts.

if [ -f $SAS_DIR/libextra/grfont.dat ] ; then
  PGPLOT_FONT=$SAS_DIR/libextra/grfont.dat
fi

export PGPLOT_FONT

# Define the default level of verbosity for output, given by SAS_VERBOSITY

SAS_VERBOSITY=4
export SAS_VERBOSITY

# Set as default the suppression of warnings, set by SAS_SUPPRESS_WARNING=1

SAS_SUPPRESS_WARNING=1
export SAS_SUPPRESS_WARNING
