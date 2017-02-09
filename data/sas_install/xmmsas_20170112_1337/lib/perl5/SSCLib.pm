package SSCLib;

# Author: Masaaki Sakano - SSC/LUX

## Originated in Thumb.pm in src_thumbs, but some routines
##  qw(getexpids extractexpidsfurther extractexpids)
## are excluded.

our $VERSION = '4.19.0';

use strict;
use Exporter 'import';
#@EXPORT    = qw();		# symbols to export in default
	# NOTE: Never export isNearlyEqual() in default!
our @EXPORT_OK = qw(deepcopy strip quote_string nint isnumber product getcartesiandistance uniq compact minloc maxloc replacestrinarywithmin replacestrinarywithmax isNil stringsundef2undef isNearlyEqual areScalarsEqual areArraysEqual areHashesEqual list2hashedindex hashmerge hashadd which_command getobsidstr getseqidstr getsascommandstring isoptdefined run run_with_stdout sscwarn sscnote quit getParams boolTranslate gunzipfits_if_needed);	# symbols to export on request
# Not-Exported: setsasvars gettestdata_dir

use Cwd;
use File::Basename;	# for dirname(), basename()
use IO::File;
use File::Temp ();
use List::Util;
use Data::Dumper;
use POSIX qw(log10 ceil floor); # Math functions.

=head1 NAME

SSCLib - Basic Perl libraries for SAS tools.

=head1 SYNOPSIS

use SSCLib;
our $Testflag;	# for run() 
our $Taskname;	# for sscwarn(), sscnote(), quit()
our @Tmpfiles2kill;	# for quit()
our %Flagglobal;	# $Flagglobal{'cleanup'} for quit() 

=head1 DESCRIPTION

Common libraries used in various SAS tasks.

=item deepcopy ( Scalar, ['exclude'=>RegExp])

This performs "deep-copy", namely copies all the elements
of hashes and arrays, which the input (reference) scalar (and
its recursive descendents) contains.  If the input (reference) scalar
is blessed to a package (class), then 'deepcopy' method of the class
is performed with the optional hash passed as it is, if defined,
else it is simply copied.
If the optional hash with the key 'exclude' for Regular-Expression
is given, those keys are not deep-copied, but simply copied.
It is particularly useful if the reference may contain
a self-reference somewhere.
If the reference includes self-reference, it causes infinite loop.
The following is an example.

  %h=("t"=>0);
  @a=(1,{"k"=>6,"ig9"=>\%h},[3,4],5);
  $cp2 = &SSCLib::deepcopy(\@a, 'exclude'=>'^ig\d$');

=item strip ( Scalar )

Returns the stripped-Scaler.

=item quote_string ( Scalar )

Returns the quoted-Scalar.
A constraint is that if the input string contains both single and double
quotations, this routine just returns the original string.

=item nint ( Scalar )

Fortran90 function of nint(), namely returns the nearest integer.

# =item PI
# 
# Returns Pi.
# 
# =item deg2radian
# 
# Returns the numeric in radian converted from degree.
# 
# =item radian2deg
# 
# Returns the numeric in degree converted from radian.
# 
# =item acospositive
# Returns Arc-cosine of the input in unit of radian,
# which is always zero or positive, namely, if the input value
# is negative, the returned value will be (PI/2 < v <= PI) [radian].

=item isnumber

Returns 1 if ALL the Input elements look a number, or 0 otherwise.
If any of them is undef, returns 0.
Spaces or Linefeeds are not allowed in the input.
You may want to call this subroutine like:
  print "yes\n" if &SSCLib::isnumber(&SSCLib::strip($string));
  $string=~s/\s//g; print "yes\n" if &SSCLib::isnumber($string);
Preceeding multiple zeros are not allowed. 
Numbers (Return 1): "5", "+5.9", "0.5", "-.5", "5.", "+5.9e3", "5.9E+3", "-.5E-003".
NON-Numbers (Return 0): "0005", "05.3", "5.9D3", "5.9 e3", "5.9-3".

=item product ( LIST )

Return the product of all the elements in the input LIST.

=item getcartesiandistance ( \@Array, \@Array )

Return the distance between the two points in the Cartesian coordinates.

=item uniq ( LIST )

uniq command in UNIX, working on LIST.  Returns uniq-qed LIST.

=item compact ( LIST )

Returns compact-ed list, that is, "compacts" all the undef and returns it.

=item minloc ( LIST )

Returns the (first) position (=Array index), where the minimum value is found.
Note the non-numeric values are simply regarded as zero.
If you don't like that, you may want to do as follows:
  $loc_forMinVal = &minloc(&replacestrinarywithmax(@array_in));

=item maxloc ( LIST )

Returns the (first) position (=Array index), where the maximum value is found.
Note the non-numeric values are simply regarded as zero.
If you don't like that, you may want to do as follows:
  $loc_forMaxVal = &maxloc(&replacestrinarywithmin(@array_in));

=item replacestrinarywithmin ( LIST )

Returns the array with the non-numeric values replaced
with a smaller value than any other element in the given list.

=item replacestrinarywithmax ( LIST )

Returns the array with the non-numeric values replaced
with a larger value than any other element in the given list.

=item isNil ( VAR )

This function is called either
  &isNil($scalar);
  &isNil($reference);
  &isNil(@array);	# or &isNil(\@array);
  &isNil(%hash);	# False if there is any key (but '').
  &isNil(\%hash);	# 'key'=>'' is regarded as nil.
Returns 1 if Var is empty, namely
  undef or
  "" [Scalar] or
  ('k1'=>undef, 'k2'=>"") [Hash] or
  (undef, "", {}, undef, ...) [Array],
else 0 otherwise.
Reference is searched recursively.
If the reference includes self-reference, it causes infinite loop.
Note numerical zero (=0) is regarded as Non-Nil, as long as
it has been explicitly used as zero in the code.

=item stringsundef2undef ( LIST )

Return another ARRAY, where 'undef' is converted into true undef in Perl.

=item isNearlyEqual ( Scalar, Scalar, [Precision, [Maximum_difference]] )

Compares two (probably) float values, and returns true either if they agree
in the given Precision (=order) or if their difference is smaller
than the given Maximum_difference.  
The default Precision and Maximum_difference are 5 and 0, respectively.
See the manual of test_utils in ssclib for more detail.

=item areScalarsEqual ( Scalar, Scalar, [Precision, [Maximum_difference]] )

Compares two values.  If they are Numeric,
isNearlyEqual() is applied.
See the manual of isNearlyEqual().
If character strings, they have to be identical.
If they are objects blessed to an arbitrary class,
then the method isNearlyEqual() has to be defined in the class
and returns true/false, or otherwise this returns 0.
Note that references (to REF,SCALAR,ARRAY,HASH,Object) are allowed as the argument
although the self-reference would cause an INFINITE loop.

=item areScalarsEqual ( \@Array, \@Array, [Precision, [Maximum_difference]] )

Compares two arrays.
See the manual of areScalarsEqual() for detail.
Note references (to REF,SCALAR,ARRAY,HASH,Object) are allowed as the element
in each argument although any self-reference would cause an INFINITE loop.

=item areHashesEqual ( \@Hash, \@Hash, [Precision, [Maximum_difference, [Exception_key1, ...]]] )

Compares two hashes.
If the Exception_key(s) are given, those keys are not used in comparison.
See the manual of areScalarsEqual() for detail.
Note references (to REF,SCALAR,ARRAY,HASH,Object) are allowed as the element
in each argument although any self-reference would cause an INFINITE loop.
Exception_key(s) are recursively considered for those referenced hash(es).

=item list2hashedindex ( ARRAY )

Returns the hash of ( $ARRAY[0] => 0, $ARRAY[1] => 1, ... ). 

=item hashmerge ( \HASH1, \HASH2, [\HASH3, ...] )

Alias for hashadd(). 

=item hashadd ( \HASH1, \HASH2, [\HASH3, ...] )

Add the contents of Hash2 (3, ...) into Hash1, unless
the same key exists in Hash1.  If Hash2, 3 ... have
the same keys, then prior hash's value is adopted.
Note that each hash must be passed as a reference.

  my %hs=&hashadd(\%h1, \%h2, \%h3);

=item which_command ( FILENAME )

Returns the full-path for the given filename, searching over ENV{'PATH'}.
If the filename is not found (or is found to be a directory),
then undef is returned.

=item setsasvars ( [CCF-FILENAME or its DIRECTORY] )

Set environment variables SAS_CCFPATH and SAS_CCF (for SSC), following
 1) if the argument is given, it has the first priority (for SAS_CCF only),
 2) if not, or if it fails after inspection (not readable etc), then go to the next step,
 3) the environmental variables are checked if preset,
 4) if still fails, set the default values.
This subroutine is useful mainly for test harnesses.

=item isoptdefined ( SAS_COMMAND, PARAMETER )

Check if the given parameter name is accepted for the SAS-command given.
Returns 1 if yes, 0 otherwise, or die if the command does not run in the first place.

=item run ( STRING, FLAG_IS-SILENT? )

Invoke the command given.
If the global variable $Testflag in MAIN is set, then just dry-run.
Returns the status of the command, i.e., usually zero if it normally ends.

=item run_with_stdout ( STRING, FLAG_IS-SILENT? )

The same as run() above, but returns the array of
($STATUS, $STDOUTPUT).

=item sscwarn ( LIST )

Print Warning messages.  Line feed is automatically inserted. 

=item sscnote ( LIST )

Print Warning messages as a NOTE.  Line feed is automatically inserted. 

=item quit ( [ Message, [Status(Integer)]] )

Exits gracefully with a given message and status number.
Expects $taskname to be defined globally.
All the temporary files (defined in the global var. @tmpfiles2kill) are deleted.

=item getobsidstr ( OBS_ID )

Returns (OBS_ID_STR) with 10 digits.

=item getseqidstr ( SEQ_ID )

Returns (SEQ_ID_STR) with 6 digits.

=item getsascommandstring ( COMMAND, \%Options_Hash )

Returns the string of the SAS command, which can be directly passed to &run(),
converting the input Options hash, which consists of keys and values
as the SAS task command-line options.
Note that the input Options hash can have an element of Array,
then the list for that option is passed to the SAS task.
If you want to give an option like "-V 5", then make it ("-V 5") as the hash key,
while the corresponding `value' is undef (NOT an empty string).
If you want to give an empty string for the parameter, do so, 
If an element in the input Options hash is a Scalar, it can contain space(s)
between words (but NOT at the beginning or end), however if it also contains
any quotation mark or the preceding or following white spaces, the whole string
had better be quoted beforehand.  If an Array, it is compulsory.

=item getParams

Returns the command-line arguments as a hash.
Assumes that the sub-routines getParamDefaults() and getVersionThenQuit()
exist.

  my %params = &getParams;

=item printParamsThenQuit

Called from getParams() when --help.

=item boolTranslate ( BooleanArgument )

Returns 1 (true|yes) or 0 (false|no), depending on the input, which
is the command-line argument.  The input is assumed to be preprocessed
in &getParams().

  my $cleanup = &boolTranslate($params{'cleanup'});

=item gettestdata_dir ( [Name-of-Task, [Sub-directory]] )

Returns the data-directory for testing (using saslocate).

=item gunzipfits_if_needed ( /DIR/FILENAME, [OriginalDirectory] )

gunzip (or copy if not needed) the FITS file into /DIR/FILENAME 
from OriginalDirectory (or from /DIR/).
Return 0 if normal ends or the returned value from gunzip or cp of
the UNIX command, or -1 if no candidate is found,

In B-sh, this subroutine can be used like
perl -MSSCLib -we '
  @Files = map { "outfiles/$_.FIT" } qw(EPIC P0102640401EPX000OMSRLI0000);
  foreach (@Files) {
    &SSCLib::gunzipfits_if_needed($_, &SSCLib::gettestdata_dir("rgssources"));
  }
'

=cut
  ;	# For Emacs


############################################################

######## General-use Perl routines ########

#---------------------------------------------------------------------
sub deepcopy {
#---------------------------------------------------------------------
  ## Input: (Scalar, ['exclude'=>RegExp])
  ## Return: Scalar deep-copied from the input.
  ## Description: 
  ##   This performs "deep-copy", namely copies all the elements
  ##  of hashes and arrays, which the input (reference) scalar (and
  ##  its recursive descendents) contains.  If the input (reference) scalar
  ##  is blessed to a package (class), then 'deepcopy' method of the class
  ##  is performed with the optional hash passed as it is, if defined,
  ##  else it is simply copied.
  ##   If the optional hash with the key 'exclude' for Regular-Expression
  ##  is given, those keys are not deep-copied, but simply copied.
  ##  It is particularly useful if the reference may contain
  ##  a self-reference somewhere.
  ##   If the reference includes self-reference, it causes infinite loop.
  ## Examples:
  ##   @a=(1,{"k"=>6},[3,4],5);
  ##   $cp2 = &SSCLib::deepcopy(\@a);

  my $sca = shift;
  my %hsarg = @_;
  my $ret;
  my ($key, $value);

  my $refchked = ref($sca);
  if ($refchked) {
    ## Reference

    if (    ('SCALAR' eq $refchked) ||
	    ('REF'    eq $refchked) ) {
      return deepcopy(\$sca, %hsarg);

    } elsif ('ARRAY'  eq $refchked) {
      $ret = [];
      foreach (@$sca) {
	push(@$ret, deepcopy($_, %hsarg));
      }

    } elsif ('HASH'   eq $refchked) {
      $ret = {};
      while (($key, $value) = each %$sca) {
	if (exists($hsarg{'exclude'}) && ($key =~ $hsarg{'exclude'})) {
	  $ret->{$key} = $value;			# Simple copy
	} else {
	  $ret->{$key} = deepcopy($value, %hsarg);	# Deep copy
	}
      }

    } elsif(('CODE'   eq $refchked) ||
	    ('GLOB'   eq $refchked) ) {
      $ret = $sca;	# Simple copy

    } else {	# Blessed to a package (Class)
      if ($sca->can('deepcopy')) {
	$ret = $sca->deepcopy(%hsarg);
      } else {
	$ret = $sca;	# Simple copy
      }
    }

  } else {
    ## NOT Reference

    $ret = $sca;	# Simple copy
  }

  return $ret;
}



#---------------------------------------------------------------------
sub strip {
#---------------------------------------------------------------------
  ## Input: (Scalar)
  ## Return: (Stripped-Scaler)
  ## Description: If called without an argument, $_ is stripped.


  if ($#_ > -1) {
    my $a = shift;
    return($a) if ! defined($a);	# if undef
    $a =~ s/^\s*//;
    $a =~ s/\s*$//;
    return($a);
  } else {
    s/^\s*//;
    s/\s*$//;
    return($_);
  }
}


#---------------------------------------------------------------------
sub nint {
#---------------------------------------------------------------------
  ## Input: (number)
  ## Return: nint(number)  # Namely, the nearest number.

  return( int($_[0] + .5 * ($_[0] <=> 0)) );
}


# #---------------------------------------------------------------------
# sub PI {
# #---------------------------------------------------------------------
# Replaced with
#  use Math::Trig;
#  pi
# 
#   ## Input: NONE
#   ## Return: Pi
# 
#   return( atan2(1,1) * 4 );
#   # *Pi = 3.14159265358979323846264338327950;
# }
# 
# #---------------------------------------------------------------------
# sub deg2radian {
# #---------------------------------------------------------------------
# Replaced with
#  use Math::Trig;
#  deg2rad()
# 
#   ## Input: (Numeric[deg])
#   ## Return: Numeric[radian]
#   ## Note: Not using SSCLib::PI() to gain a speed.
# 
#   return( $_[0]/45.0*atan2(1,1) );	# PI == atan2(1,1) * 4
# 
# }
# 
# #---------------------------------------------------------------------
# sub radian2deg {
# #---------------------------------------------------------------------
# Replaced with
#  use Math::Trig;
#  rad2deg()
# 
#   ## Input: (Numeric[radian])
#   ## Return: Numeric[deg]
#   ## Note: Not using SSCLib::PI() to gain a speed.
# 
#   return( $_[0]/atan2(1,1)*45.0 );	# PI == atan2(1,1) * 4
# }
# 
# 
# #---------------------------------------------------------------------
# sub acospositive {
# #---------------------------------------------------------------------
# Replaced with
#  use Math::Trig;
#  acos();	# => Complex number (for x<-1 or x>1)
# or
#  use POSIX qw(acos);
#  acos();	# NaN for x<-1 or x>1
# 
#   ## Input: (Numeric)
#   ## Return: Numeric[radian] (Arc-cosine of the input)
#   ## Note: If the input value of the cosine is negative,
#   ##   the returned value will be (PI/2 < v <= PI) [radian],
#   ##   nb., acos(-1/2)=>120deg, acos(-1)=>PI.
# 
#   return( atan2(sqrt(1-$_[0]**2), $_[0]) );
# }


#---------------------------------------------------------------------
sub isnumber {
#---------------------------------------------------------------------
  ## Input: (string, [string, [...]])
  ## Return: 1 if Input looks a number, or 0 otherwise.
  ## Description: Spaces or Linefeeds are not allowed in the input.
  ##  You may want to call this subroutine like:
  ##    print "yes\n" if &SSCLib::isnumber(&SSCLib::strip($string));
  ##    $string=~s/\s//g; print "yes\n" if &SSCLib::isnumber($string);
  ##  Preceeding multiple zeros are not allowed. 
  ##  Numbers (Return 1):
  ##    "5", "+5.9", "0.5", "-.5", "5.", "+5.9e3", "5.9E+3", "-.5E-003"
  ##  NON-Numbers (Return 0):
  ##    "0005", "05.3", "5.9D3", "5.9 e3", "5.9-3"

  # my $s = shift;
  # if ($s =~ /^([+\-]?((0|[1-9]\d*)?\.[0-9]+|(0|[1-9]\d*)\.?)([Ee][+\-]?\d+)?)$/) {
  foreach (@_) {
    return 0 if (! (defined $_));
    if (! /^([+\-]?((0|[1-9]\d*)?\.[0-9]+|(0|[1-9]\d*)\.?)([Ee][+\-]?\d+)?)$/) {
      return 0;
    }
  }

  return 1;
  # } else {
  #   return 0;
  # }
}


#---------------------------------------------------------------------
sub product {
#---------------------------------------------------------------------
  ## Input: (List)
  ## Return: Product of all the elements in the list

  #my ($a, $b);
  return List::Util::reduce {$a * $b} (@_);
}
# #---------------------------------------------------------------------
# sub getproducts {
# #---------------------------------------------------------------------
#   ## Input: Array
#   ## Return: Product of all the elements in the input Array
# 
#   my($ret) = 1;
#   my(@arin) = @_;
#   my($i);
# 
#   foreach $i (@arin) {
#     $ret *= $i;
#   }
# 
#   return $ret;
# }


#---------------------------------------------------------------------
sub getcartesiandistance {
#---------------------------------------------------------------------
  ## Input: (\@Array1, \@Array2)
  ## Return: The distance between the two points in the Cartesian coordinates.

  my($subname) = "getcartesiandistance";
  my $arg1 = shift;
  my @ar1 = @$arg1;       # dereference
  my $arg2 = shift;
  my @ar2 = @$arg2;       # dereference
  my $sq = 0;
  my $i;

  my $lastindex = $#ar1;
  die "Number of the elements is inconsisntent in $subname." if $lastindex != $#ar2;

  foreach $i (0..$lastindex) {
    $sq += ($ar1[$i]-$ar2[$i])**2
  }

  return( sqrt($sq) );
}


#---------------------------------------------------------------------
sub uniq {
#---------------------------------------------------------------------
  ## Input: (List)
  ## Return: uniq-ed list

  my %seen;
  return(grep { ! $seen{$_} ++ } @_);
}


#---------------------------------------------------------------------
sub compact {
#---------------------------------------------------------------------
  ## Input: (List)
  ## Return: compact-ed list ("compacts" all the undef and returns it).

  my @arret;
  foreach (@_) {
    push(@arret, $_) if (defined $_);
  }
  return(@arret);
}


#---------------------------------------------------------------------
sub maxloc {
#---------------------------------------------------------------------
  ## Input: (LIST)
  ## Return: (First) Position (=Array index), where the maximum value is found.
  ## Description: 
  ## Note: Non-numeric values are simply regarded as zero.
  ##   If you want non-numeric values to be ignored, do
  ##    $loc_forMaxVal = &maxloc(&replacestrinarywithmin(@array_in));

  my(@arin) = @_;
  my ($maxval, $ret);

  if (isnumber(strip($arin[0]))) {
    $maxval = $arin[0];
  } else {
    $maxval = 0;
  }

  $ret = 0;

  foreach (1..$#arin) {
    if ($arin[$_] > $maxval) {
      $maxval = $arin[$_];
      $ret = $_;
    }
  }

  return $ret;
}


#---------------------------------------------------------------------
sub minloc {
#---------------------------------------------------------------------
  ## Input: (LIST)
  ## Return: (First) Position (=Array index), where the minimum value is found.
  ## Description: 
  ## Note: Non-numeric values are simply regarded as zero.
  ##   If you want non-numeric values to be ignored, do
  ##    $loc_forMinVal = &minloc(&replacestrinarywithmax(@array_in));

  my(@arin) = @_;
  my ($minval, $ret);

  if (isnumber(strip($arin[0]))) {
    $minval = $arin[0];
  } else {
    $minval = 0;
  }

  foreach (1..$#arin) {
    if ($arin[$_] < $minval) {
      $minval = $arin[$_];
      $ret = $_;
    }
  }

  return $ret;
}


#---------------------------------------------------------------------
sub replacestrinarywithmin {
#---------------------------------------------------------------------
  ## Input: (LIST)
  ## Return: @ARRAY2
  ## Description: Returns the array with the non-numeric values replaced
  ##   with a smaller value than any other element in the array.
  ## Note: 

  my(@arret) = @_;
  my ($minval);

  local $^W = 0;	# Suppress the warning messages in min() when there are non-numeric values in the array.
  $minval = List::Util::min(@arret) - 1;

  map{$_ = $minval if (! isnumber(strip($_)))} @arret;
  # map{$_ = $minval if (! /^\s*([+\-]?((0|[1-9]\d*)?\.[0-9]+|(0|[1-9]\d*)\.?)([Ee][+\-]?\d+)?)\s*$/);} @arret;

  return @arret;
}


#---------------------------------------------------------------------
sub replacestrinarywithmax {
#---------------------------------------------------------------------
  ## Input: (LIST)
  ## Return: @ARRAY2
  ## Description: Returns the array with the non-numeric values replaced
  ##   with a larger value than any other element in the array.
  ## Note: 

  my(@arret) = @_;
  my ($maxval);

  local $^W = 0;	# Suppress the warning messages in max() when there are non-numeric values in the array.
  $maxval = List::Util::max(@arret) + 1;

  map{$_ = $maxval if (! isnumber(strip($_)))} @arret;
  # map{$_ = $maxval if (! /^\s*([+\-]?((0|[1-9]\d*)?\.[0-9]+|(0|[1-9]\d*)\.?)([Ee][+\-]?\d+)?)\s*$/);} @arret;

  return @arret;
}


#---------------------------------------------------------------------
sub isNil {
#---------------------------------------------------------------------
  ## Input: (Variable)
  ## Return: 1 or 0.
  ## Description: 
  ##  This function is called either
  ##    &isNil($scalar);
  ##    &isNil($reference);
  ##    &isNil(@array);	# or &isNil(\@array);
  ##    &isNil(%hash);	# False if there is any key (but '').
  ##    &isNil(\%hash);	# 'key'=>'' is regarded as nil.
  ##  Returns 1 if Var is empty, namely
  ##    undef or
  ##    "" [Scalar] or
  ##    ('k1'=>undef, 'k2'=>"") [Hash] or
  ##    (undef, "", {}, undef, ...) [Array],
  ##  else 0 otherwise.
  ##  Reference is searched recursively.
  ##  If the reference includes self-reference, it causes infinite loop.
  ##  Note numerical zero (=0) is regarded as Non-Nil, as long as
  ##  it has been explicitly used as zero in the code.

  my @arin = @_;
  my ($eachv, $refchked);

  foreach $eachv (compact(@arin)) {	# compact in SSCLib
    $refchked = ref($eachv);
    if ($refchked) {
      ## Reference

      if (    ('SCALAR' eq $refchked) ||
	      ('REF'    eq $refchked) ) {
	return 0 if ! isNil(\$eachv);
      } elsif ('ARRAY'  eq $refchked) {
	return 0 if ! isNil(@$eachv);
      } elsif ('HASH'   eq $refchked) {
	return 0 if ! isNil(values(%$eachv));
      } elsif(('CODE'   eq $refchked) ||
	      ('GLOB'   eq $refchked) ) {
	return undef;
      } else {	# Blessed to a package (Class)
	if ($eachv->can('isNil')) {
	  return 0 if ! $eachv->isNil();
	} else {
	  return undef;
	}
      }

    } else {
      ## NOT Reference

      return 0 if '' ne $eachv;
    }
  }

  return 1;
}


#---------------------------------------------------------------------
sub stringsundef2undef {
#---------------------------------------------------------------------
  # Input: (@ARRAY)
  # Return: (@ARRAY), where 'undef' is converted into true undef in Perl.

  my (@ar) = @_;

  return( map { if(/^\s*undef\s*$/i){undef} else{$_} } @ar );
}


#---------------------------------------------------------------------
sub isNearlyEqual {
#---------------------------------------------------------------------
  ## Input: (val1, val2, [precision, [maximum_difference]])
  ## Return: 1 if yes, or 0 otherwise.
  ## Description: Compare two (probably) float values,
  ##   and return true if they agree in the given precision (=order),
  ##   or if their difference is smaller than the given maximum_difference.
  ## Reference: ssclib/test_utils.f90 (isNearlyEqual() <= isNearlyEqualDDCore()),
  ##   originally based on [ruby-list:42510].

  my ($subname) = "isNearlyEqual";

  my ($cmp) = shift;
  my ($compared) = shift;
  my ($precision, $maxdiff) = (5, 0);	# Default
  # $precision = shift if ($#_ > -1);
  $precision = $_[0] if ($_[0]);	# Not loaded if undef
  $maxdiff   = $_[1] if ($_[1]);	# Not loaded if undef
  die "precision($precision) is negative in $subname." if $precision < 0;

  my ($prec);
  my ($cmpnonzero) = $cmp;

  die "SSCLib::isNearlyEqual: The 1st argument is undefined." if (! defined($cmp));
  die "SSCLib::isNearlyEqual: The 2nd argument is undefined (1st=($cmp))." if (! defined($compared));

  if ($cmp == $compared) {
    return 1;
  } elsif (abs($cmp - $compared) < $maxdiff) {
    return 1;
  } elsif ($cmp == 0 || $compared == 0) {
    return 0;
  } else {
    $prec = $precision - floor(log10(abs($cmpnonzero))) - 1;
    if ( nint($cmp * 10 ** $prec) == nint($compared * 10 ** $prec) ) {
      return 1;
    } else {
      return 0;
    }
  }
}
  

#---------------------------------------------------------------------
sub areScalarsEqual {
#---------------------------------------------------------------------
  ## Input: (val1, val2, [precision, [maximum_difference, [dummies, ...]]])
  ## Return: 1 if yes, or 0 otherwise.
  ## Description: Compare two values (mostly Numeric, that is,
  ##   if they are strings, they have to be identical).
  ##   See isNearlyEqual().
  ##   Note references (to REF,SCALAR,ARRAY,HASH) are allowed as the argument
  ##   although the self-reference would cause an INFINITE loop.

  my $val1 = shift;
  my $val2 = shift;
  my @aroptions = @_;	# ([precision, [maximum_difference]])
  # my ($precision, $maxdiff) = (5, 0);	# Default
  # $precision = shift if ($#_ > -1);
  # $maxdiff   = shift if ($#_ > -1);

  my $refv1 = ref($val1);
  my $refv2 = ref($val2);

  if ($refv1 eq $refv2) {
    if ($refv1 eq '') {	# eg., undef (nb., ref(@a)=='')
      if ((! defined($val1)) && (! defined($val2))) {
	return 1;
      } elsif ((! defined($val1)) || (! defined($val2))) {
	return 0;
      } elsif ($val1 eq $val2) {
	return 1;
      } else {
	return 0 if (($val1 !~ /\d/) || ($val2 !~ /\d/));	# Non-Numeric
	return 0 if ((! &isnumber($val1)) || (! &isnumber($val2)));	# Non-Numeric
	return( &isNearlyEqual($val1, $val2, @aroptions) );
	# return( &isNearlyEqual($val1, $val2, $precision, $maxdiff) );
      }
    } elsif ($refv1 eq 'REF') {
      return &areScalarsEqual(${$val1}, ${$val2},  @aroptions);
      # return &areScalarsEqual(${$val1}, ${$val2}, $precision, $maxdiff);
    } elsif ($refv1 eq 'SCALAR') {
      return &areScalarsEqual(${$val1}, ${$val2},  @aroptions);
    } elsif ($refv1 eq 'ARRAY') {
      return &areArraysEqual(\@{$val1}, \@{$val2}, @aroptions);
    } elsif ($refv1 eq 'HASH') {
      return &areHashesEqual(\%{$val1}, \%{$val2}, @aroptions);
    } elsif (($refv1 eq 'CODE')  or  ($refv1 eq 'GLOB')) {
      &sscwarn("CODE or GLOB can not be evaluated in SSCLib-areScalarsEqual().");
      return 0;
    } else {	# object blessed to a Class
#print "here00\n";
      if ($val1->can('isNearlyEqual')) {
#print "val1="; print Dumper \$val1;
#print "val2="; print Dumper \$val2;
#print "aroptions="; print Dumper \@aroptions;
#print "val...At_="; print Dumper \@_;
	return $val1->isNearlyEqual($val2, @aroptions);
      } else {  
	return 0;
      }
    }
  } elsif ($refv1 eq '') {
    if ($refv2 eq 'REF') {
      return &areScalarsEqual($val1, ${$val2}, @aroptions);
    } elsif ($refv2 eq 'SCALAR') {
      return &areScalarsEqual($val1, ${$val2}, @aroptions);
    } else {
      return 0;
    }
  } elsif ($refv1 eq 'REF') {
    if ($refv2 eq '') {
      return &areScalarsEqual(${$val1}, $val2,     @aroptions);
    } elsif ($refv2 eq 'SCALAR') {
      return &areScalarsEqual(${$val1}, ${$val2},  @aroptions);
    } elsif ($refv2 eq 'ARRAY') {
      return &areScalarsEqual(${$val1}, \@{$val2}, @aroptions);
    } elsif ($refv2 eq 'HASH') {
      return &areScalarsEqual(${$val1}, \%{$val2}, @aroptions);
    } else {
      return 0;
    }
  } elsif ($refv1 eq 'SCALAR') {
    if ($refv2 eq '') {
      return &areScalarsEqual(${$val1}, $val2,     @aroptions);
    } elsif ($refv2 eq 'REF') {
      return &areScalarsEqual(${$val1}, ${$val2},  @aroptions);
    } else {
      return 0;
    }
  } elsif ($refv1 eq 'ARRAY') {
    if ($refv2 eq 'REF') {
      return &areScalarsEqual(\@{$val1}, ${$val2}, @aroptions);
    } else {
      return 0;
    }
  } elsif ($refv1 eq 'HASH') {
    if ($refv2 eq 'REF') {
      return &areScalarsEqual(\%{$val1}, ${$val2}, @aroptions);
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}

#---------------------------------------------------------------------
sub areArraysEqual {
#---------------------------------------------------------------------
  ## Input: (\%array1, \%array2, [precision, [maximum_difference, [dummies, ...]])
  ## Return: 1 if yes, or 0 otherwise.
  ## Description: Compare two arrays (mostly Numeric, that is,
  ##   if they are strings, they have to be identical).
  ##   See areScalarsEqual() for detail.
  ##   Note references (to REF,SCALAR,ARRAY,HASH) are allowed as the element
  ##   in each argument although the self-reference would cause an INFINITE loop.

  my $arg1 = shift;
  my @ar1 = @$arg1;       # dereference
  my $arg2 = shift;
  my @ar2 = @$arg2;       # dereference
  my @aroptions = @_;	# ([precision, [maximum_difference]])

  # my ($precision, $maxdiff) = (5, 0);	# Default
  # $precision = shift if ($#_ > -1);
  # $maxdiff   = shift if ($#_ > -1);

  my ($i);

  if ($#ar1 != $#ar2) {
    return 0;
  } else {
    foreach $i (0..$#ar1) {
      return 0 if (! (&areScalarsEqual($ar1[$i], $ar2[$i], @aroptions)) );
    }
  }

  return 1;
}


#---------------------------------------------------------------------
sub areHashesEqual {
#---------------------------------------------------------------------
  ## Input: (\%hash1, \%hash2, [precision, [maximum_difference, ['exceptions'=>[Array_of_Keys], ...]]])
  ## Return: 1 if yes, or 0 otherwise.
  ## Description: Compare two hashes (mostly Numeric, that is,
  ##  if they are strings, they have to be identical).
  ##   If the 3rd and/or 4th argument is not desired to be specified,
  ##  they can be undef.
  ##   If the exception_key(s) are given in the argument hash,
  ##  those keys are not used in comparison.  Those exception_key(s) are 
  ##  taken into account recursively in the subsequent reference(s) to hashes,
  ##  if there is any.
  ##   See areScalarsEqual() for detail.
  ##   Note references (to REF,SCALAR,ARRAY,HASH) are allowed as the element
  ##  in each argument although the self-reference would cause an INFINITE loop.

  my $arg1 = shift;
  my %hs1 = %$arg1;       # dereference
  my $arg2 = shift;
  my %hs2 = %$arg2;       # dereference
  my @aroptions = @_;	# ([precision, [maximum_difference]])

  # my ($precision, $maxdiff) = (5, 0);	# Default
  # $precision = shift if ($#_ > -1);
  # $maxdiff   = shift if ($#_ > -1);

  my(@arexcept) = @_;
  shift(@arexcept);
  shift(@arexcept);
  my(%hsarg) = @arexcept;

  my($i);

  # foreach $i (@arexcept) {
  foreach $i (@{$hsarg{"exceptions"}}) {
    delete($hs1{$i});	# Local change.
    delete($hs2{$i});
  }

  my(@keys1) = sort(keys(%hs1));
  my(@keys2) = sort(keys(%hs2));

  if (! (&areArraysEqual(\@keys1, \@keys2)) ){
    return 0;
  } else {
    foreach $i (@keys1) {
      return 0 if (! (&areScalarsEqual($hs1{$i}, $hs2{$i}, @aroptions)) );
    }
  }

  return 1;
}


#---------------------------------------------------------------------
sub list2hashedindex {
#---------------------------------------------------------------------
  ## Input: (ROW0, NO1, SECOND, ...)
  ## Return: (Hash)=("ROW0"=>0, "NO1"=>1, "SECOND"=>2, ...)

  my (@arin) = @_;
  my (%hs);

  my $i = 0;
  foreach (@arin) {
    $hs{$_}=$i;
    $i++;
  }

  return(%hs);
}


#---------------------------------------------------------------------
sub hashmerge {
#---------------------------------------------------------------------
  ## Description: Alias for &hashadd()
  return &hashadd(@_);
}

#---------------------------------------------------------------------
sub hashadd {
#---------------------------------------------------------------------
  ## Input: (\Hash1, \Hash2, [\Hash3, ...])
  ##        each hash must be passed as a reference.
  ## Return: (Hash)
  ## Description: Add the contents of Hash2 (3, ...) into Hash1, unless
  ##              the same key exists in Hash1.  If Hash2, 3 ... have
  ##              the same keys, then prior hash's value is adopted.
  ## Example: %hs=&hashadd(\%h1, \%h2, \%h3)
  ## Test code: perl -e 'use Data::Dumper;use SSCLib;%a=("x"=>1);%b=("y"=>2,"z"=>3);%c=("g"=>7,"x"=>5);%x=SSCLib::hashadd(\%a,\%b,\%c);print Dumper \%x;'
  ##   $VAR1 = {
  ##             'y' => 2,
  ##             'g' => 7,
  ##             'x' => 1,
  ##             'z' => 3
  ##           };

  my $arg = shift;
  my %hsorg = %$arg;
  my (@arhs2add) = @_;
  my (%hstmp, $key);

  foreach (@arhs2add) {
    %hstmp=%$_;

    foreach $key (keys(%hstmp)) {
      if (! exists $hsorg{$key}) {
	$hsorg{$key}=$hstmp{$key};
      }
    }
  }

  return(%hsorg);
}


#---------------------------------------------------------------------
sub which_command {
#---------------------------------------------------------------------
  ## Input: (Command-Name)
  ## Return: Full-Path OR undef (if the command is not found in the PATH)

  my $commandname = shift;
  my @pathtmp = split(":",$ENV{'PATH'});
  my @arcom;
  my @arfin;
  my $t;

  @arcom=map{
    $t=$_."/$commandname";
    if ((-f $t)&&(-x $t)){$t} else {0}
  } @pathtmp;
  @arfin=grep(!/^0$/,@arcom);
  return $arfin[0];
}


######## SAS-use Perl routines ########

#---------------------------------------------------------------------
sub setsasvars {
#---------------------------------------------------------------------
  ## Input: ( [CCF-File or its Directory] )
  ## Description:
  ##  set environment variables SAS_CCFPATH and SAS_CCF, following
  ##   1) if the argument is given, it has the first priority (for SAS_CCF only),
  ##   2) if not, or if it fails after inspection (not readable etc), then go to the next step,
  ##   3) the environmental variables are checked if preset,
  ##   4) if still fails, set the default values.
  ## Note:
  ##  If [Directory] is specified, DIR/ccf.cif, DIR/P0*OBX*CALIND*.FTZ etc are searched.

  my($sasccf) = ""; 
  $sasccf = shift if (1 <= scalar(@_)); 
  my($sasccfpath, $a, $d, @arfile); 

  ### Set SAS_CCFPATH
  $a="SAS_CCFPATH";
  if (! grep(/^\Q$a\E$/, keys(%ENV))) {
    foreach ( qw(/raid/calarchive /data/archive/ccf/public /data/archive/ccf/devel /data/archive/ccf/cat) ){
      if (-d $_) {
	$sasccfpath = $_;
	last;
      }
    }
    $ENV{$a}=$sasccfpath;
  }

  ### Set SAS_CCF
  $a="SAS_CCF";
  if ("" ne $sasccf) {
    if ((-f $sasccf) && (-r $sasccf)) {
      $ENV{$a}=$sasccf;
    } elsif (-d $sasccf) {
      foreach $d (glob("$sasccf/{,product/}{ccf.cif,P*OBX000CALIND0000.{FIT,FTZ,FITS,fits,fits.gz,fits.Z,fit}}")) {
	if (-r $d) {
	  $ENV{$a}=$d;
	  last
	}
      }
    } else {
      &sscwarn("CCF-File of or in the specified ($sasccf) is not either found or readable.  Trying with the standard procedure, now...");
    }
  }
  grep(/^\Q$a\E$/, keys(%ENV)) or $ENV{$a}=`saslocate lib/testccf/ccf.cif`; chomp($ENV{$a});

#  $a="SAS_CCFPATH"; grep(/^\Q$a\E$/, keys(%ENV)) or $ENV{$a}=$sasccfpath;
#  $a="SAS_CCF";     grep(/^\Q$a\E$/, keys(%ENV)) or $ENV{$a}=`saslocate lib/testccf/ccf.cif`; chomp($ENV{$a});

  return;
}


sub isoptdefined {
  ## Input: (Command, Parameter)
  ## Return: 1 if yes, 0 otherwise, or die if the command does not run in the first place.
  ## Description: Command is a SAS command.  Parameter is e.g. 'usedss'.
  ## Example: $opt9="usedss=no " if (&isoptdefined("eexpmap", "usedss"))
  ## Note: It is unefficent to call this subroutine repeatedly
  ##       for the same command.

  my($com) = shift;	# SAS-command name
  my($optname) = shift;	# Option parameter name
  my($optnamere) = quotemeta($optname);
  my($flagprmnow)=0;
  my($isoptexisting)=0;

  open(SASCOMARGTEST, "$com -h|") or die "Failed to run '$com -h'";
  while (<SASCOMARGTEST>){
    if (/^\s*Parameters\s*:/) {
      $flagprmnow=1;
      next;
    } elsif ($flagprmnow) {
      next;
    } elsif (/^\s*$optnamere /) {
      $isoptexisting=1;
      last;
    }
  }
  close(SASCOMARGTEST);

  $isoptexisting;
}


#---------------------------------------------------------------------
sub run {
#---------------------------------------------------------------------
  # Input: ($STRING-command, FLAG(is_silent?))
  # Return: Return of running (=system()); or 0 if $Testflag==true
  # Description: If FLAG(no-print) is 1, then comment will NOT be printed.
  #   $Testflag should be defined globally.
  # Example: &SSCLib::run($com) and die "FATAL:Command ($com) failed.\n";

  my ($command) = shift;
  my ($flagsilent) = shift;
  my $status = 0;

  print " invoke ".$command."\n" unless ($flagsilent);	# print in Default
  if (! $main::Testflag) {
    $status = system($command);
  }

  return $status;
}

#---------------------------------------------------------------------
sub run_with_stdout {
#---------------------------------------------------------------------
  # Input: ($STRING-command, FLAG(is_silent?))
  # Return: (STATUS, STDOUT(of the command))
  # Description: If FLAG(no-print) is non-0, then comment will NOT be printed.
  #   $Testflag should be defined globally.
  # NOTE: Return STATUS is 0 if $Testflag==true.

  my ($command) = shift;
  my ($flagsilent) = shift;
  my $status = 0;
  my $output = "";

  print " invoke ".$command."\n" unless ($flagsilent);	# print in Default
  if (! $main::Testflag) {
    $output = `$command`;
    $status = $?;
  }

  return ($status, $output);
}

#---------------------------------------------------------------------
sub sscwarn {
#---------------------------------------------------------------------
  ## Assumes $Taskname is defined globally in MAIN.
#  open(LOG, ">> $log_name") if ($write_log);
  my (@a)=@_;
  foreach (@a) {
    chomp;
    print STDERR "** ".$main::Taskname.": WARNING: $_\n";
#    print LOG "** $taskname: warning, $_\n\n" if ($write_log);
  }
#  close(LOG) if ($write_log);
}

#---------------------------------------------------------------------
sub sscnote {
#---------------------------------------------------------------------
#  open(LOG, ">> $log_name") if ($write_log);
  my (@a)=@_;
  foreach (@a) {
    chomp;
    print STDERR "** ".$main::Taskname.": NOTE: $_\n";
    #print "** $taskname: warning, $_\n\n";
#    print LOG "** $taskname: warning, $_\n\n" if ($write_log);
  }
#  close(LOG) if ($write_log);
}


#----------------------------------------------------------------------
sub quit {
#----------------------------------------------------------------------
  # Expects $Taskname and $Flagglobal{'cleanup'} to be defined globally.

  my ($message, $status) = @_;

  my $whole_message = "** ";
  if (defined($main::Taskname)) {
    $whole_message .= "$main::Taskname: ";
  }
  $whole_message .= "ERROR! $message\n\n";
  print STDERR $whole_message;

  my ($cleanup) = 1;
  if ( %main::Flagglobal && grep(/^cleanup$/, keys(%main::Flagglobal)) ) {
    $cleanup = $main::Flagglobal{'cleanup'};
  }

  if ($cleanup) { 
    foreach (@main::Tmpfiles2kill) {
      unlink($_) if (-e $_);
    }
  }

  exit $status;
}


#---------------------------------------------------------------------
sub getobsidstr {
#---------------------------------------------------------------------
  # Input: (OBS_ID)
  # Return: (OBS_ID_STR) with 10 digit.

  return (('0'x( 10-length($_[0])))."$_[0]");
}


#---------------------------------------------------------------------
sub getseqidstr {
#---------------------------------------------------------------------
  # Input: (SEQ_ID)
  # Return: (SEQ_ID_STR) with 6 digit.

  return (('0'x( 6-length($_[0])))."$_[0]");
}


#---------------------------------------------------------------------
sub getsascommandstring {
#---------------------------------------------------------------------
  ## Input: ("Command", \%Options)
  ## Return: "Command-and-arguments-String", or -1 if any of the arguments is wrong.
  ## Description: Returns the string of the SAS command, which can be directly passed to &run(),
  ##   converting the input Options hash, which consists of keys and values
  ##   as the SAS task command-line options.
  ##   Note that the input Options hash can have an element of Array,
  ##   then the list for that option is passed to the SAS task.
  ##   If you want to give an option like "-V 5", then make it ("-V 5") as the hash key,
  ##   while the corresponding `value' is undef (NOT an empty string).
  ##   If you want to give an empty string for the parameter, do so, 
  ##   If an element in the input Options hash is a Scalar, it can contain space(s)
  ##   between words (but NOT at the beginning or end), however if it also contains
  ##   any quotation mark or the preceding or following white spaces, the whole string
  ##   had better be quoted beforehand.  If an Array, it is compulsory.

  my ($Subname) = "getsascommandstring";
  my ($commandroot) = shift;
  my $arg = shift;
  my %hsinopt = %$arg;       # dereference
  my ($strcommand) = $commandroot;
  my ($key, $value, $refval, $comkey, $comval);

  while (($key,$value) = each %hsinopt){

    $comkey = &strip($key);
    #if ($comkey =~ /\s/ || $comkey eq '')	# "-V 5" etc is allowed. 
    if ($comkey eq '') {
      &sscwarn("Argument key for &$Subname is an empty string.");
      return -1;
    }

    if (! defined($value)) {
      if ($comkey =~ /^\s*-/) {
	$strcommand .= " " . $comkey;
	next;
      } else {
	&sscwarn("Argument value for the key($comkey) in &$Subname is undefined, but the key does not begin with `-'.");
	return -1;
      }
    }

    $comval = $value;
    $refval = ref($value);
    if ($refval eq "") {	# ref -- 'SCALAR'
      if ($comval eq '') {
	$comval = "''";		# defined, but the empty string.
      } elsif ($comval =~ /\s/) {
	$comval = &quote_string(&strip($comval));
      }

    } elsif ($refval eq 'ARRAY') {
      # NOTE: if any of the element in Array contains any space, then
      #   the whole string should be quoted beforehand, and the quotation
      #   mark should be consistent (whether single or double) over
      #   all the elements.

      $comval = &quote_string( &strip(join(" ", @{$comval})) );

    } else {
      &sscwarn("Argument ($key) for &$Subname is inappropriate.");
      return -1;
    }			# if ($refval eq 'SCALAR')

    if ($comval eq '') {
      &sscwarn("Contact the code developper for an empty string that should not happen in &$Subname.");
      $strcommand .= " " . $comkey;	# Should not happen.
    } else {
      $strcommand .= " " . $comkey . "=" . $comval;
    }
  }			# while (($key,$value) = each %hsinopt)

  return $strcommand;
}


#---------------------------------------------------------------------
sub getParams {
#---------------------------------------------------------------------
  # This routine is shared with all chains. Should therefore be in a
  # separate module.

  my ($possible_key, $actual_key, $value, $no_match_found
      , $unmatched_pars_found);

  my %params = &main::getParamDefaults();

  # Look for '-v':
  foreach (@ARGV) {
    if ($_ eq '-v') {
      &main::getVersionThenQuit();
    }
  }

  # Look for '-h(elp)':
  foreach (@ARGV) {
    if (/^-h(|elp)/) {
      &printParamsThenQuit();
    }
  }

  $unmatched_pars_found = 0;
  foreach (@ARGV) {
    if ($_ =~ /^(\w+)(=+)/) {
      $actual_key = $1;
#print "actual key = $actual_key\n";
      $value = $';	#' (Comment just for Emacs)
      $no_match_found = 1;
      foreach $possible_key (keys(%params)) {
#print "  possib key = $possible_key\n";
	if ($possible_key eq $actual_key) {
	  $params{$possible_key} = $value;
	  $no_match_found = 0;
	  last;
	}
      }
#print "\n";
      if ($no_match_found) {
	$unmatched_pars_found = 1;
	&sscwarn("Unrecognised parameter: $actual_key");
      }
    }
  }
  &quit("Unmatched parameters found.", -1) if ($unmatched_pars_found);

  return %params;
}

#---------------------------------------------------------------------
sub printParamsThenQuit {
#---------------------------------------------------------------------

  my %params = &main::getParamDefaults;
  foreach (keys(%params)) {
    print "$_,\tdefault = $params{$_}\n";
  }

  exit 0;
}


#---------------------------------------------------------------------
sub boolTranslate {
#---------------------------------------------------------------------
  my ($inStr) = @_;
  my $out;

  if ($inStr =~ /^\w+$/) {
    $inStr = lc($inStr);
    if ($inStr eq 'y' || $inStr eq 'yes' || $inStr eq 't'
	|| $inStr eq 'true') {
      $out = 1;
    } elsif ($inStr eq 'n' || $inStr eq 'no' || $inStr eq 'f'
	     || $inStr eq 'false') {
      $out = 0;
    } else {
      &quit("Non-boolean variable $inStr treated as boolean.", -2);
    }
  } elsif ($inStr ne '0' && $inStr ne '1') {
    &quit("Non-boolean variable $inStr treated as boolean.", -3);
  }

  return($out);
}


#---------------------------------------------------------------------
sub gettestdata_dir {
#---------------------------------------------------------------------
  ## Input: ([Name-of-Task, [Sub-directory]])
  ## Return: ($data_dir)
  ## Description: Get Data-directory for testing (using saslocate), or die.
  ## Example: $datadir = &gettestdata_dir("colimplot") 
  ##        : $datadir = &gettestdata_dir("ssclib","shortest") 

  my $task = shift;
  my $subdir = shift;

  if (! defined($task)) {
    # Guess the task name --- perhaps wrong, though.
    $task = dirname($0);
    $task =~ s/\.[^.]*$//i;	# Cut any suffix
    #$task =~ s/^test\d*_?//i;
    $task =~ s/_.*$//i;
    $task = lc($task);
    if ($task eq "") {
      die "Can't determine the possible task name in gettestdata_dir.\n";
    }
  }
  $task =~ s/_data$//;
  if (defined($subdir)) {
    $subdir =~ s@^\s*/*@/@;
  } else {
    $subdir = ''
  }

  my $data_dir = `saslocate lib/data/${task}_data${subdir}`;	# Data directory --- should be the same for epiclccorr
  if (!defined($data_dir)) {
    die "Can't find testprods data for ${task}.\n";
  }
  chomp($data_dir);

  return($data_dir);
}


#---------------------------------------------------------------------
sub gunzipfits_if_needed {
#---------------------------------------------------------------------
  ## Input: (/DIR/FILENAME, [OriginalDirectory])
  ## Return: 0 if normal ends.
  ## Description: gunzip the (FITS) data, if needed into /DIR/FILENAME 
  ##   The default original directory is the same as
  ##   the path for the 1st argument (/DIR/).
  ## Library: use File::Basename
  ## Example: &gunzipfits_if_needed("./tmp.ds", "/data/a/b/c/") 
  ##   then, /data/a/b/c/tmp.FTZ => ./tmp.ds (after gunzip-ped)

  my($fname)  = shift;
  my($fnamebase) = basename($fname);
  my($orgdir) = shift;
  $orgdir = dirname($fname) if ( (!defined($orgdir)) || $orgdir eq "" );
  my($orgdirfname) = "$orgdir/$fnamebase";
  my($fnameroot, $a, $b);

  if ( -e $fname ) {
    return 0;
  } elsif (-e $orgdirfname) {
	return &SSCLib::run("cp -i $orgdirfname $fname");
  } else {
    $fnameroot = $fnamebase;
    $fnameroot =~ s/\.([^.\/]+)$//;
    foreach ( qw(fits FIT) ) {
      ## Already gunzip-ped, but in a different name.
      $a = "$orgdir/$fnameroot.$_";
      if (-e $a) {
	return &SSCLib::run("cp -ip $a $fname");
      }
    }
    foreach ( qw(fits.gz ftz FTZ gz) ) {
      ## Gunzip the file.
      $a = "$orgdir/$fnameroot.$_";
      $b = "$orgdir/$fnamebase.$_";
      if (-e $a) {
	return &SSCLib::run("gunzip -c $a > $fname");
      } elsif (-e $b) {
	return &SSCLib::run("gunzip -c $b > $fname");
      }
    }
  }
  return -1;	# No candidate file is found.
}


# This routine should be here, as it badly disturbs the indent in Emacs!
#---------------------------------------------------------------------
sub quote_string {
#---------------------------------------------------------------------
  ## Input: ("String")
  ## Return: ("'String'"), namely quoted string.
  ## Example: &quote_string(&strip(" ABC 'DEF' GH  ")) 
  ## Constraints: If the input string contains both single and double
  ##   quotations, this routine just returns the original string.

  my($str)  = shift;

  ## Handle the quotations if there is any.
  if ($str =~ /["]/ && $str =~ /[']/) { #'"
    # Do nothing
  } elsif ($str =~ /^\s*['][^']*[']\s*$/) { #' # namely <'...'>
    # Do nothing
  } elsif ($str =~ /^\s*["][^"]*["]\s*$/) { #" # namely <"...">
    # Do nothing
  } elsif ($str =~ /["]/) {  # namely (&& !~ /[']/) #'"
    $str =~ s/^[']//;	#'
    $str =~ s/[']$//;	#'
    $str = "'". $str . "'";
  } else {
    $str =~ s/^["]//;	#"
    $str =~ s/["]$//;	#"
    $str = '"'. $str . '"';
  }

  return $str;
}



1;
