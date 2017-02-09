#
# XMM Science Analysis System set up script for C-shell-like shells
#
# This script must be sourced. Otherwise it will not work and will
# output an error message in case a "return" statement is reached (bash).
# In tcsh, the "return" is not built-in so an "exit" is required.
#
# $Id: sas-setup.csh.in,v 1.56 2013/12/09 14:57:13 eojero Exp $

#  $SAS_DIR must be defined, otherwise the script returns.

if ( ! $?SAS_DIR ) then
  echo "sas-setup.csh error: SAS_DIR is undefined - Please define it !"
  exit 1  # return is not a built-in in tcsh. Usage of exit is required.
endif

#
# Since SAS 10.0.0 LHEASOFT must be initialized prior to SAS.
# Latest versions of HEADAS also define LHEASOFT, so it is enough to test for that variable
#

if ( ! $?LHEASOFT ) then
  echo "sas-setup.csh error: LHEASOFT is undefined - Please define and initialize HEADAS !"
  exit 1 
endif

#
# Handling of SAS_PATH.
#
# This is used only by SAS developers. For them, it is a way to add up
# some test binaries and libraries to those provided by SAS under $SAS_DIR.
#
# If $SAS_PATH is not set by the user, it is set to $SAS_DIR.

if ( ! $?SAS_PATH ) setenv SAS_PATH $SAS_DIR


#
# Modify PATH, LIBRARY_PATH and LD_LIBRARY_PATH (DYLD_LIBRARY_PATH on Mac OS X)
#
# Will look for all bin, lib and lib/perl5 subdirectories in $SAS_PATH
# Since $SAS_PATH can have other paths besides $SAS_DIR, separated by ":"
# it will split them into components. To do that, it will change the ":" by a 
# blank space. In the sh/bash this is done differently.
#  
# binpath  = all bin subdirectories in SAS_PATH (+= PATH)
# libpath  = all lib subdirectories in SAS_PATH (+= LIBRARY_PATH/(DY)LD_LIBRARY_PATH )
# perlpath = all lib/perl5 subdirectories in SAS_PATH (+= LD_LIBRARY_PATH)

set binpath
set libpath
set perlpath

set first

foreach n (`echo $SAS_PATH | sed -e 's/:/ /g'`)
  if ( $?first ) then
    set binpath = ( $n/bin $n/bin/devel )
    set libpath = $n/lib
    set perlpath = $n/lib/perl5
    unset first
  else
    set binpath = ( $binpath $n/bin $n/bin/devel )
    set libpath = $libpath\:$n/lib
    set perlpath = $perlpath\:$n/lib/perl5
  endif
end


# The PATH is modified to prepend to it $binpath (+ $SAS_DIR/binextra).

set path = ( $SAS_DIR/binextra $binpath $path )



# The LIBRARY_PATH is modified to prepend to it $libpath

if ( ! $?LIBRARY_PATH ) then
  setenv LIBRARY_PATH $libpath
else
  setenv LIBRARY_PATH $libpath\:$LIBRARY_PATH
endif


# In addition we prepend $SAS_DIR/libsys:$SAS_DIR/libextra to LIBRARY_PATH

setenv LIBRARY_PATH $SAS_DIR/libsys:$SAS_DIR/libextra:$LIBRARY_PATH



# The (DY)LD_LIBRARY_PATH is modified to prepend to it the $libpath
#
# Do not mix one with other to avoid messing them up

set os=`uname -s`

if ( "$os" == "Darwin" ) then

  if ( ! $?DYLD_LIBRARY_PATH ) then
    setenv DYLD_LIBRARY_PATH $libpath
  else
    setenv DYLD_LIBRARY_PATH $libpath\:$DYLD_LIBRARY_PATH
  endif

  # Prepend $SAS_DIR/libsys:$SAS_DIR/libextra to DYLD_LIBRARY_PATH
 
  setenv DYLD_LIBRARY_PATH $SAS_DIR/libsys:$SAS_DIR/libextra:$DYLD_LIBRARY_PATH  

else

  if ( ! $?LD_LIBRARY_PATH ) then
    setenv LD_LIBRARY_PATH $libpath
  else
    setenv LD_LIBRARY_PATH $libpath\:$LD_LIBRARY_PATH
  endif

  # Prepend $SAS_DIR/libsys:$SAS_DIR/libextra to LD_LIBRARY_PATH

  setenv LD_LIBRARY_PATH $SAS_DIR/libsys:$SAS_DIR/libextra:$LD_LIBRARY_PATH

endif



# PERL5LIB

if ( ! $?PERL5LIB ) then
  setenv PERL5LIB $perlpath
else
  setenv PERL5LIB $perlpath\:$PERL5LIB
endif



# In case PERLLIB exists, append it to PERL5LIB.

if( $?PERLLIB ) then
 setenv PERL5LIB $PERL5LIB\:$PERLLIB
endif



#
# LaTeX and BibTeX -- the trailing `:' is mandatory, otherwise
# if kpathsea is used the system defaults are lost.
#

# TEXINPUTS
#
# $SAS_DIR/packages/sas/doc/lib exists only in SAS builds

if ( -d $SAS_DIR/packages/sas/doc/lib ) then

  if ( ! $?TEXINPUTS ) then
    setenv TEXINPUTS $SAS_DIR/packages/sas/doc/lib:.:
  else
    setenv TEXINPUTS $SAS_DIR/packages/sas/doc/lib:$TEXINPUTS
  endif


  # BIBINPUTS

  if ( ! $?BIBINPUTS ) then
    setenv BIBINPUTS $SAS_DIR/packages/sas/doc/lib:.:
  else
    setenv BIBINPUTS $SAS_DIR/packages/sas/doc/lib:$BIBINPUTS
  endif

endif


#
# Default SAS image viewer
#

if ( ! $?SAS_IMAGEVIEWER ) then
  setenv SAS_IMAGEVIEWER ds9
endif


#
# .sas.d directory and config 
#

if ( ! $?SAS_PIPELINE ) then
   if ( ! -d $HOME/.sas.d ) then
     mkdir $HOME/.sas.d
   endif
   if ( ! -d $HOME/.sas.d/config ) then
     mkdir $HOME/.sas.d/config
   endif
#   setenv SAS_PATH $HOME/.sas.d/:$SAS_PATH
endif


# SAS_BROWSER

if ( ! $?SAS_BROWSER ) then
  setenv SAS_BROWSER "nobrowser"
endif

   
# Set PGPLOT_FONT to the grfont.dat provided by SAS (which must be in libextra)
# so SAS applications depending on pgplot can draw properly pgplot fonts.

if ( -f $SAS_DIR/libextra/grfont.dat ) then
  setenv PGPLOT_FONT $SAS_DIR/libextra/grfont.dat
endif

# Define the default level of verbosity for output, given by SAS_VERBOSITY

setenv SAS_VERBOSITY 4

# Set as default the suppression of warnings, set by SAS_SUPPRESS_WARNING=1

setenv SAS_SUPPRESS_WARNING 1

