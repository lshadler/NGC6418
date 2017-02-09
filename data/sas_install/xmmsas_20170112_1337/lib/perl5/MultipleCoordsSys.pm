# Author: Masaaki Sakano - SSC/LUX

our $VERSION = '1.3.0';
our $Taskname = 'MultipleCoordsSys';

=head1 NAME

MultipleCoordsSys - Class representing multiple (celestial and pixel) coordinate systems.

=head1 SYNOPSIS

    use MultipleCoordsSys;

=head1 DESCRIPTION

Class to represent multiple-coordinate systems.
This can be
(A) just multiple sets of coordinates, or
(B) two different coordinate systems and its transformation, or
(C) its combinations.
For example, a FITS table can contain many coordinate pairs (case A).
A primary header of FITS files can indicate the image (or physical) coordinates
between the pixel and celestial ones (case B).
A header of a FITS extention can include both (case C).

In the current implementation, this class's object holds the hash keys of

   'ext'      => FITS-Extention number (eg., 0 (for primary))
   'sysname'  => SYSTEM-Name (eg., 'physical')
   'coordver' => Coordinate-Version Name (/def|[A-Z]/ though others are allowed)
   'col'      => 1-dim Array of PairCoordsSys objects, or possibly undef.
     Each index means the column number.
   'matrix'   => Hash of keywords /PCall|CDall|.../
     Each hash is a 4-dim Array of [n][i][j][km].
      e.g., {'PCall'->[i][j][km]=>123.4,...}
   'all'      => Hash of various parameters.
   'name'     => Name.
   'subname'  => SubName.
   'comment'  => Hash of comments.

Among these, (ext|sysname|coordver) keys are basically for information only.
(col|matrix) is the main parameters.
'all' may hold some essential parameters.

This class is used extensively from FitsCelCoordsSys class.
See the document of FitsCelCoordsSys for detail.


=item new ( HASH )

The input HASH must include 'arcolumn' key, of which the element is
a reference to an array, of which each index is the column number (n)
(n=0 for anything not related to the FITS table column, such as,
the attributes in the primary header), and of which each component is
a hash with the keys, such as, 'CRPIX', 'CRVAL', 'CDELT' etc
as defined in %Wcskey4Objkey .

The HASH may include 'matrix' key, of which the element is
a hash with the key of the matrix component, such as, 'PCall',
each of which is a reference to an 3-dimensional array
of [i][j][km] for a numeric.
See Table 8.2 (Section 8.2, pp.77) in FITS Standard Ver.3.0 (2008/07/10)
for the meanings of [nijkm].

The HASH may include other keys, such as, (ext|sysname|coordver|all),
the first three of which are highly recommended to be defined.
Those values are held as the top-level hash key in the self.

The following is an example for the argument HASH.

  { 'arcolumn' => [ 
       {'CRVAL'=>128.0, 'CUNIT'=>'deg', 'CRPIX'=>'10', 'CTYPE'=>'RA---TAN', 'CDELT'=>0.123},
       {'CRVAL'=>-64.0, 'CUNIT'=>'deg', 'CRPIX'=>'7',  'CTYPE'=>'DEC--TAN', 'CDELT'=>0.123, 'CROTA'=>0} ],
     'matrix' => {'PCall'=>[undef,[undef,[123]],[undef,undef,[-2]]]},
     'all' => {'type'=>"something"},
     'ext' => 0,
     'system'   => 'physical',
     'coordver' => 'def'
   }

=item col ( )

Returns an Array, $self->{col}, which is a 1-dim Array of PairCoordsSys objects, where each index indicates the column number.

=item isNil ( )

Returns 1 if the object is practically nil, 0 otherwise.
Defined as both Class and normal methods.

=item isNearlyEqual ([m1], m2, [precision, [maximum_difference, [options,...]]])

Returns 1 if the objects are nearly equal in the given condition.
See SSCLib.pm for detail.
Defined as both Class and normal methods.

=item arrayAllSignificantPcsIndex ( [m1] )

Returns a 1-dim array indicating all the significant indices
for {col}->[?]: 1 for significant (! isNil()), else 0.
If 'col' is not defined first of all, null Array () is returned.
Defined as both Class and normal methods.

=item size ( [m1] )

Returns the number of the significant indices (i.e., significant
PairCoordsSys objects it holds).
Defined as both Class and normal methods.

=item singleCoords ([m1], [options,...])

Returns a single Coords (CelCoords) object,
or 0 if more than one objects are found to satisfy the conditions,
or undef if no object is found to satisfy the conditions.
Defined as both Class and normal methods.

=item singlePcs  ([m1], [options,...])

Returns a single PairCoordsSys object,
or 0 if more than one objects are found to satisfy the conditions,
or undef if no object is found to satisfy the conditions.
Defined as both Class and normal methods.

=item minglePair ([m1], [Optional-Hash])

Returns a modified MultipleCoordsSys object, or undef if something goes wrong.
This makes up (modify) a PairCoordsSys from two sets of PairCoordsSys in it,
which are probably extracted from individual columns,
and sets it up appropriately; the first PairCoordsSys has more elements
than used to after mingled up, and other PairCoordsSys are deleted.
The new PairCoordsSys instance $p now has

   @{$p->{orgcolumns}}: List of all the original columns,
     $p->{cel|pix}->{axis}->[*]->{column}: each index shows the original column number.

The optional hash can have keys of

   fromcol  => COLumn-number FROM which the values are imported,
   fromaxis => AXIS index number FROM which the values are imported,
   tocol    => COLumn-number TO which the values are implemented,
   toaxis   => AXIS index number TO which the values are implemented.

In default, all are the string 'auto'.

Another possible key is 'popaxis' (Default=1); delete the trailing axes at the end of this method, if true.

=item deepcopy ( )

Returns deep-copied self.  Simply imported from DeepCopy module.

=item to_s ( )

Returns a simple string expression of the self.

=cut
  ;	# For Emacs


#######################################################################

package MultipleCoordsSys;

use strict;
use Exporter 'import';
# our @EXPORT    = qw(getattribute fparkey tbl2arrays tbl2arraysingle are2tblsequal getfitsheadernumber iscolumnexisting sumup_images readFitsStatInfo);		# symbols to export in default
our @EXPORT_OK = qw();	# symbols to export on request

use Data::Dumper;
use List::Util qw(max sum);	# qw(max min sum reduce)
use SSCLib qw(isnumber hashmerge sscnote sscwarn);
# use Fitsplutils;
use DeepCopy;		# Module in ssclib
use Coords;		# in ssclib
use CelCoords;		# in ssclib
use PairCoordsSys;	# in ssclib
use WcsKey;	# Module

our ($DEBUGGING);

##
## Class to represent multi-coordinate systems.
## This can be
##  (A) just multiple sets of coordinates, or
##  (B) two different coordinate systems and its transformation, or
##  (C) its combinations.
## For example, a FITS table can contain many coordinate pairs (case A).
## A primary header of FITS files can indicate the image(physical) coordinates
## between the pixel and celestial ones (case B).
## A header of a FITS extention can include both (case C).
##
## In the current implementation, this class's object holds the hash keys of
##    'ext'      => FITS-Extention number (eg., 0 (for primary))
##    'sysname'  => SYSTEM-Name (eg., 'physical')
##    'coordver' => Coordinate-Version Name (/def|[A-Z]/ though others are allowed)
##    'col'      => 1-dim Array of PairCoordsSys objects, or possibly undef.
##      Each index means the column number.
##    'matrix'   => Hash of keywords /PCall|CDall|.../
##      Each hash is a 4-dim Array of [n][i][j][km].
##       e.g., {'PCall'[i][j][km]=>123.4,...}
##
## To (deep-)copy:
##  m2 = m1->deepcopy;
##
## To print the contents:
##  print m1->to_s;
##

#---------------------------------------------------------------------
sub new {
#---------------------------------------------------------------------
  ### Input:  ('ext'=>0, 'sysname'=>'physical', 'coordver'=>'def', 'arcolumn'=>[{'axis'=>[{'CRVAL'=>123.4,...},...], 'matrix'=>{'PCall'[i][j][km]=>123.4,...}, 'all'=>{'EQUINOX'=>2000.0,...}}, ...])
  ### Return: ($self)
  ### Description: 
  ### Constraints:
  ### Global: 
  ### Usage example:

  my $class = shift;	# The first argument is Coords
  my @ararg = @_;
  my %hsarg = @_;
  my $self = {};
  bless $self, $class;	# Inheritance is applied (with this 2-arguments bless), if there is any.
  $self->_initialize(@ararg);
  return $self;

}


#---------------------------------------------------------------------
sub _initialize {
#---------------------------------------------------------------------
  ### Input:  ('ext'=>0, 'sysname'=>'physical', 'coordver'=>'def', 'arcolumn'=>[{'axis'=>[{'CRVAL'=>123.4,...},...], 'matrix'=>{'PCall'[i][j][km]=>123.4,...}, 'all'=>{'EQUINOX'=>2000.0,...}}, ...])
  ### Return: ($self)
  ### Description: In the returned (or modified) $self,
  ###   $self->{'ext'}      === /\d/
  ###   $self->{'sysname'}  === /physical|image|pointing|.../
  ###   $self->{'coordver'} === /^(def|[A-Z])$/
  ###
  ###   $self->{'col'}: Array of column number (0..MAX_COL_NUMBER); Default==0
  ###        ->{'col'}[0..n] : a PairCoordsSys object (which contains CelCoords|Coords objects)
  ###            or possibly undef.
  ###   $self->{'matrix'}: Hash of keywords /PCall|CDall|.../
  ###        ->{'matrix'}{'PCall'}[n][i][j][km]: 4-dim Array.
  ###               Up to 3 dimensions can be used at most.
  ###               Default index for each dimension is zero.
  ###
  ### References: 
  ###  See Table 8.2 (Section 8.2, pp.77) in FITS Standard Ver.3.0 (2008/07/10)

  my $self = shift;     # The first argument is always SELF.
  my %hsarg = @_;
#print Dumper \%hsarg;
print "hsarg(Multiple) == " if ($DEBUGGING);
print Dumper \%hsarg if ($DEBUGGING);
  my @armainarg = @{$hsarg{'arcolumn'}};

  my %hsinter = ();	# Intermediate hash, constructed from the argument hash.
  my($COL, $COLCEL, $COLPIX) = qw(col colcel colpix) ;	# Constants
  my %defarg = ('ext'=>undef, 'sysname'=>undef, 'coordver'=>'def');

  my ($columnnum, $eachcomp, $icoord, $eachkey, $key4obj);
  my ($i, $imax, %h, $s);

  foreach ( keys(%defarg) ) {
    $self->{$_}   = $hsarg{$_};
    $self->{$_} ||= $defarg{$_};
  }

  my $coordverchar = $self->{coordver};
  $coordverchar = "" if ($coordverchar eq 'def');

  ####################################
  ## As a preparation to creat $self,
  ## here we construct the intermediate hash %hsinter from the argument hash.
  ##  $hsinter{'colcel'}: Array of column number (0..MAX_COL_NUMBER); Default==0
  ##          {'colcel'}[0..n] : Hash of /axis|all|misc|.../
  ##          {'colcel'}[0..n]{'axis'} == [ {'val'=>123.45, 'type'=>'RA', 'unit'=>'deg', 'CDELT'=>0.0, 'CROTA'=>0.0, ...}, ...]
  ##          {'colcel'}[0..n]{'all'}  == {'epoch'=>2000.0, 'coordsys'=>'RA---TAN', ...}
  ##          {'colcel'}[0..n]{'ELSE'} == {'VELOSYS'=>'Unknown', ...}
  ##  $hsinter{'colpix'}: Array of column number (0..MAX_COL_NUMBER); Default==0
  ##          {'colpix'}[0..n] : Hash of /axis/ (only, so far (for CRPIX\d))
  ##          {'colpix'}[0..n]{'axis'} == [ {'val'=>123.45, 'type'=>'RA---TAN', 'name'=>'CRPIX1'}, ...]	# 3 keys only.
  ##  $hsinter{'matrix'}: Hash of keywords /PCall|CDall|.../
  ##          {'matrix'}{'PCall'}[n][i][j][km]: 4-dim Array.
  ##              Up to 3 dimensions can be used at most.
  ##              Default index for each dimension is zero.
  ##
  ####################################
  foreach $columnnum (0..$#armainarg) {	# 0..n
    foreach $eachcomp (keys(%{$armainarg[$columnnum]})) {	# 'axis', 'all' etc
      if ('axis' eq $eachcomp) {
	### 'axis'
	$hsinter{$COLCEL} ||= [];
	$hsinter{$COLPIX} ||= [];
	$hsinter{$COLCEL}[$columnnum] ||= {};
	$hsinter{$COLPIX}[$columnnum] ||= {};
	$hsinter{$COLCEL}[$columnnum]{$eachcomp} ||= [];
	$hsinter{$COLPIX}[$columnnum]{$eachcomp} ||= [];

	## Convert each key if needed.
	## e.g., 'CRVAL' => 'val', 'CRPIX' => 'val'
	foreach $icoord ( 0..$#{$armainarg[$columnnum]{$eachcomp}} ) {
	  $hsinter{$COLCEL}[$columnnum]{$eachcomp}[$icoord] ||= {};
	  $hsinter{$COLPIX}[$columnnum]{$eachcomp}[$icoord] ||= {};

	  foreach $eachkey ( keys(%{$armainarg[$columnnum]{$eachcomp}[$icoord]}) ) {
	    $key4obj = ($Wcskey4Objkey{$eachkey} || $eachkey);

	    if (      'CRPIX' eq $eachkey ) {
	      ## Define Pixel coordinates.
	      $hsinter{$COLPIX}[$columnnum]{$eachcomp}[$icoord]{$key4obj} = $armainarg[$columnnum]{$eachcomp}[$icoord]{$eachkey};

	      if ($columnnum == 0) {
		$s = sprintf("%s%d%s", 'CRPIX', $icoord,   $coordverchar);	# If column number n==0, then $iccord must be significant.
	      } elsif ($icoord == 0) {
		$s = sprintf("%s%d%s", 'TCRP', $columnnum, $coordverchar);	# If $icoord==0, then, column number n must be significant.
	      } else {
		$s = sprintf("%d%s%d%s", $icoord, 'CRP', $columnnum, $coordverchar);
	      }
	      $hsinter{$COLPIX}[$columnnum]{$eachcomp}[$icoord]{'name'} = $s;
	      $hsinter{$COLPIX}[$columnnum]{'all'} ||= {};
	      $hsinter{$COLPIX}[$columnnum]{'all'}{'type'} ||= 'cartesian';

	    } else {
	      ## Define Celestial coordinates.

	      $hsinter{$COLCEL}[$columnnum]{$eachcomp}[$icoord]{$key4obj} = $armainarg[$columnnum]{$eachcomp}[$icoord]{$eachkey};

	      if ( 'CTYPE' eq $eachkey ) {	# Define both Pixel and Celestial coordinates.
		$s = $armainarg[$columnnum]{$eachcomp}[$icoord]{$eachkey};
		$hsinter{$COLPIX}[$columnnum]{$eachcomp}[$icoord]{$key4obj}  = $s;

		$hsinter{$COLCEL}[$columnnum]{$eachcomp}[$icoord]{'orgtype'} = $s;	## Define {'axis'=>[]=>{'orgtype'}}.
		$_ = substr($s, 0, 4);	# 'RA--' <= 'RA---TAN' (=== /[A-Z0-9_\-]{4}-[A-Z0-9_]{3})
		s/\-*$//;
		$hsinter{$COLCEL}[$columnnum]{$eachcomp}[$icoord]{$key4obj} = $_;		# Overwritten with 'RA|DEC' etc.

	      } elsif ( 'CRVAL' eq $eachkey ) {	# Add 'name'
		if ($columnnum == 0) {
		  $s = sprintf("%s%d%s", 'CRVAL', $icoord,   $coordverchar);	# If column number n==0, then $iccord must be significant.
		} elsif ($icoord == 0) {
		  $s = sprintf("%s%d%s", 'TCRV', $columnnum, $coordverchar);	# If $icoord==0, then, column number n must be significant.
		} else {
		  $s = sprintf("%d%s%d%s", $icoord, 'CRV', $columnnum, $coordverchar);
		}
		$hsinter{$COLCEL}[$columnnum]{$eachcomp}[$icoord]{'name'} = $s;

	      }
	    }
	  }
	}

	## Make sure the numbers of components for the arrays 'colcel|colpix' are the same.
	$imax = max($#{$hsinter{$COLCEL}[$columnnum]{$eachcomp}},
		    $#{$hsinter{$COLPIX}[$columnnum]{$eachcomp}});	# &max() in List::Util
	$hsinter{$COLCEL}[$columnnum]{$eachcomp}[$imax] ||= undef;	# Should be unnecessary because the last element is referred to below.
	$hsinter{$COLPIX}[$columnnum]{$eachcomp}[$imax] ||= undef;

	$s = $hsinter{$COLCEL}[$columnnum]{$eachcomp}[0];
	if ((! $s) ||
	    ( ref($s) ne 'HASH' ) ||
	    ((ref($s) eq 'HASH') && ((! exists($$s{val})) || (! defined($s->{val}))))) {	# In short, "If the axis[0] is insignificant"
	  ## In the FITS files, the numbering of the coordinate axes 
	  ## generally starts from 1, eg., CRVAL1(alpha), CRVAL2(delta).
	  ## In Coords/CelCoords class, the numbering of the coordinate axes 
	  ## starts from 0.
	  ## Therefore we here slide the array elements by -1.
	  ## NOTE if it is physical coordinates (using 'REFXCRVL' etc.),
	  ## of "nominal" (RA_NOM) etc,
	  ## then the coordinates passed here already start from index==0.
	  foreach $i ( 0..($imax-1) ) {	# Ends at $imax-1
	    $hsinter{$COLCEL}[$columnnum]{$eachcomp}[$i] = $hsinter{$COLCEL}[$columnnum]{$eachcomp}[$i+1];	# Slide the array by -1.
	    $hsinter{$COLPIX}[$columnnum]{$eachcomp}[$i] = $hsinter{$COLPIX}[$columnnum]{$eachcomp}[$i+1];	# Slide the array by -1.
	  }
	  pop(@{$hsinter{$COLCEL}[$columnnum]{$eachcomp}});	# Remove the last element.
	  pop(@{$hsinter{$COLPIX}[$columnnum]{$eachcomp}});	# Remove the last element.
	}

      } elsif ('matrix' eq $eachcomp) {
	### 'matrix'
	$hsinter{$eachcomp} ||= {};
	foreach $eachkey (keys(%{$armainarg[$columnnum]{$eachcomp}})) {	# 'PCall', 'CDall' etc
	  $hsinter{$eachcomp}{$eachkey} ||= [];
	  $hsinter{$eachcomp}{$eachkey}[$columnnum] = $armainarg[$columnnum]{$eachcomp}{$eachkey};	# In the form of {'matrix'}{'PCall'}[n][i][j][km]
	}

      } elsif ('all' eq $eachcomp) {
	### 'all'
	$hsinter{$COLCEL} ||= [];
	$hsinter{$COLCEL}[$columnnum]{$eachcomp} ||= {};

	## Convert each key if needed.
	## e.g., 'EQUINOX' -> 'epoch'
	foreach $eachkey ( keys(%{$armainarg[$columnnum]{$eachcomp}}) ) {
	  $key4obj = ($Wcskey4Objkey{$eachkey} || $eachkey);
	  $hsinter{$COLCEL}[$columnnum]{$eachcomp}{$key4obj} = $armainarg[$columnnum]{$eachcomp}{$eachkey};
	}

      } else {
	### 'misc' etc.
	$hsinter{$COLCEL} ||= [];
	$hsinter{$COLCEL}[$columnnum] ||= {};
	$hsinter{$COLCEL}[$columnnum]{$eachcomp} = $armainarg[$columnnum]{$eachcomp};	# [0..n]{'misc'=>{'ABC'=>'XYZ',...}}

      }		# if ('axis' eq $eachcomp)
    }	#  foreach $eachcomp (keys(%{$armainarg[$columnnum]})) 	# 'axis', 'all' etc
  }	# foreach $columnnum (0..$#{$armainarg}) 	# 0..n


  ####################################
  ## Now construct $self.
  ####################################

  $self->{'matrix'} = $hsinter{'matrix'};
  $self->{$COL}= [];
  # $self->{$COL} = {'cel'=>undef, 'pix'=>undef};
  # $self->{$COL}{'cel'} = [];
  # $self->{$COL}{'pix'} = [];
  $imax = max($#{$hsinter{$COLCEL}},
	      $#{$hsinter{$COLPIX}});	# &max() in List::Util
  # $self->{$COL}{'cel'}[$imax] ||= undef;	# To make sure the numbers of the components (column numbers) are the same.
  # $self->{$COL}{'pix'}[$imax] ||= undef;

  foreach $columnnum (0..$imax) {	# 0..n

    ## The following two can coexist for the same column number n.
    ## For example, the primary FITS header (n==0, as it is undefined)
    ## can, and usually does, have both CRVAL? and CRPIX?.
    ## That is why we use PairCoordsSys class to represent them.

    %h = ( 'cel' => undef,
	   'pix' => undef,
	   'ext' => $self->{'ext'},
	   'sysname' => $self->{'sysname'},
	   'coordver'=> $self->{'coordver'},
	   'col' => $columnnum,
	   'matrix' => $hsinter{'matrix'} );

    if ($hsinter{$COLCEL}[$columnnum]){
      $h{'cel'} = CelCoords->new('allarg'=>$hsinter{$COLCEL}[$columnnum]);
    }
    if ($hsinter{$COLPIX}[$columnnum]){
      $h{'pix'} = Coords->new(   'allarg'=>$hsinter{$COLPIX}[$columnnum]);
    }

    $s = PairCoordsSys->new(%h);

    if ($s->isNil) {
      $self->{$COL}[$columnnum] = undef;
    } else {
      $self->{$COL}[$columnnum] = $s;
    }

  }

  $self;
}


#---------------------------------------------------------------------
sub col {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (m1)
  ### Input(Normal method): ()
  ### Return: $self->{col}
  ### Description: 
  ### References: 

  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->isNil($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $m1=shift;

    return @{$m1->{col}};
  }
}	# sub col


#---------------------------------------------------------------------
sub isNil {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (MultipleCoordsSys object)
  ### Input(Normal method): ()
  ### Return: (1 if the object is practically nil, 0 otherwise)
  ### Description: Practically calling isNil() method in lower classes.
  ### References: 

  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->isNil($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $m1=shift;

    my $ifin = $#{$m1->{col}};

    my $i;
    foreach $i (0..$ifin) {
      if ( $m1->{col}[$i] ) {	# PairCoordsSys or undef
	return 0 if (! $m1->{col}[$i]->isNil);	# PairCoordsSys
      } else {
	next;			# undef
      }	
    }

    return 1;
  }
}	# sub isNil


#---------------------------------------------------------------------
sub isNearlyEqual {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (m1, c2, [precision, [maximum_difference, [options,...]]])
  ### Input(Normal method):    (c2, [precision, [maximum_difference, [options,...]]])
  ### Return: 1 if yes, or 0 otherwise.
  ### Description: Compare two MultipleCoordsSys objects
  ###   and return true if they agree in the given precision or given maximum_difference.
  ###   c2 can be PairCoordsSys or (Cel)Coords, instead of MultipleCoordsSys.
  ###   Note that this does not check the consistency of cross-terms,
  ###   such as PC.
  ### Reference: See SSCLib::isNearlyEqual for detail.

  my ($subname) = "isNearlyEqual";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->isNearlyEqual($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $m1=shift;
    my $c2=shift;
    my @argrest=@_;
    my %hsargrest;

    my $verbosityLoc = 0;
    if (scalar(@argrest) > 2) {
      %hsargrest = @argrest[2..$#argrest];
      if (exists($hsargrest{'verbosity'})) {
	$verbosityLoc = $hsargrest{'verbosity'};
      }
    }

    if ( (! $c2->can('col')) || ($c2->can('pix')) ) {	# c2 is NOT MultipleCoordsSys (therefore either PairCoordsSys or (Cel)Coords)
      my $p1;
      $p1 = $m1->singlePcs(%hsargrest);
      if ($p1) {
	return $p1->isNearlyEqual($c2, @argrest);	# PairCoordsSys->isNearlyEqual
      } else {
	sscwarn("MultipleCoordsSys instance has more than one PairCoordsSys, hence is not equal to a single PairCoordsSys or (Cel)Coords instance in comparison.") if ($verbosityLoc > 3);
	return 0;	# Either zero or more than one PairCoordsSys 
      }

    } else {

      ## Now, c2 should be MultipleCoordsSys
      my $i1fin = $#{$m1->{col}};
      my $i2fin = $#{$c2->{col}};

      if ($i1fin != $i2fin) {
	# Dimensions of the axes are different.
	sscwarn("Dimensions of the axes in MultipleCoordsSys are different ($i1fin != $i2fin).") if ($verbosityLoc > 4);
	return 0;

      } else {
	my $i;
	foreach $i (0..$i1fin) {
	  if (  ! ($m1->{col}[$i] || $c2->{col}[$i])) {
	    next;		# Both undef
	  } elsif ($m1->{col}[$i] && $c2->{col}[$i]) {
	    if (! $m1->{col}[$i]->isNearlyEqual($c2->{col}[$i], @argrest)) {
	      sscwarn("Not equal in MultipleCoordsSys Column=($i).") if ($verbosityLoc > 4);
	      return 0;
	    }
	  } else {	# Either undef
	    sscwarn("Either is undef for MultipleCoordsSys Column=($i), hence not equal.") if ($verbosityLoc > 4);
	    return 0;
	  }	
	}
      }

      return 1;	# None of them is inconsistent, hence Nearly-Equal.
    }

  }	#  if (ref($self))
}	# sub isNearlyEqual


#---------------------------------------------------------------------
sub arrayAllSignificantPcsIndex {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (c1)
  ### Input(Normal method):(NONE)
  ### Return: 1-dim array indicating all the significant indices
  ###   for {col}->[?]: 1 for significant (! isNil()), else 0.
  ###   If 'col' is not defined first of all, null Array () is returned.
  ### Description: 
  ### Reference: 

  my ($subname) = "arrayAllSignificantPcsIndex";
  my $self=shift;

  my @arret;

  if (ref($self)) {	# Normal method.
    return( ref($self)->arrayAllSignificantPcsIndex($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;

    return @arret if (! exists($$c1{col}));
    return @arret if (! defined($c1->{col}));
    if (ref($c1->{col}) ne 'ARRAY') {	# Neither ARRAY nor undef.
      print Dumper \$c1;
      die("'col' in $self object is wrong.");
    }

    my($n);
    foreach $n (0..$#{$c1->{col}}) {
      $arret[$n] = undef;	# undef in default.
      if (($c1->{col}[$n]) &&	# NOT undef
	  ($c1->{col}[$n]->can('isNil'))) {	# Must be PairCoordsSys class object
	$arret[$n] = (! $c1->{col}[$n]->isNil);	# 0 or 1
      }
    }		# foreach $n (0..$#{$c1->{col}})

    return @arret
  }	#  if (ref($self))
}	# sub arrayAllSignificantPcsIndex


#---------------------------------------------------------------------
sub singleCoords {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [Optional-Hash])
  ### Input(Normal method):([Optional-Hash])
  ### Return: A single Coords (CelCoords) object,
  ###  or 0 if more than one objects are found to satisfy the conditions,
  ###  or undef if no object is found to satisfy the conditions.
  ### Description: 
  ###   Optional hash is ignored for now.
  ###   ## For the conditions (Optional-Hash), see the description of FitsCelCoordsSys::aryMcs().
  ### Reference: 

  my ($subname) = "singleCoords";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->singleCoords($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;
    my %hsarg = @_;

    my $pcs = $c1->singlePcs(%hsarg);

    if ((! $pcs) ||	# 0 (more than 1 PCS) or undef (no PCS).
	(! $pcs->can('singleCoords')) ) {	# The latter should not happen, but just to play safe.
      return undef;
    } else {
      return $pcs->singleCoords(%hsarg);
    }
  }
}	# sub singleCoords


#---------------------------------------------------------------------
sub size {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [Optional-Hash])
  ### Input(Normal method):([Optional-Hash])
  ### Return: Size of MultipleCoordsSys, that is,
  ###  the number of significant PairCoordsSys objects that contains.
  ### Description: 
  ###   Optional hash is ignored for now.
  ###   ## For the conditions (Optional-Hash), see the description of FitsCelCoordsSys::aryMcs().
  ### Reference: 

  my ($subname) = "size";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->size($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;
    my %hsarg = @_;

    my @ar = $c1->arrayAllSignificantPcsIndex;
    if (@ar) {
      return sum(&_undef2zero(@ar));	# sum() in List::Util
    } else {
      return 0;
    }
  }
}	# sub size


#---------------------------------------------------------------------
sub singlePcs {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [Optional-Hash])
  ### Input(Normal method):([Optional-Hash])
  ### Return: A single PairCoordsSys object,
  ###  or 0 if more than one objects are found to satisfy the conditions,
  ###  or undef if no object is found to satisfy the conditions.
  ### Description: 
  ###   Optional hash is ignored for now.
  ###   ## For the conditions (Optional-Hash), see the description of FitsCelCoordsSys::aryMcs().
  ### Reference: 

  my ($subname) = "singlePcs";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->singlePcs($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;
    my %hsarg = @_;

    my @arSigIndex = $c1->arrayAllSignificantPcsIndex;
    my $sum_arSigIndex = $c1->size;	# n.b., Overhead to recalculate @arSigIndex (NOT expensive) in size().

    return undef if ($sum_arSigIndex <= 0);
    return 0     if ($sum_arSigIndex > 1);

    # Now it is guaranteed there is one significant PairCoordsSys
    foreach (0..$#arSigIndex) {
      return $c1->{col}->[$_] if ($arSigIndex[$_]);
    }

    print STDERR "DEBUG(MultipleCoordsSys::$subname): c1 = ";
    print Dumper \$c1;
    die "Contact the code developper.";
  }
}	# sub singlePcs


#---------------------------------------------------------------------
sub minglePair {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [Optional-Hash])
  ### Input(Normal method):([Optional-Hash])
  ### Return: A modified MultipleCoordsSys object,
  ###  or undef if something goes wrong.
  ### Description: 
  ###   Making up (modify) a PairCoordsSys from two sets of PairCoordsSys in it
  ###  which are probably extracted from individual columns,
  ###  and set it up appropriately; the first PairCoordsSys has more elements
  ###  than used to after mingled up, and other PairCoordsSys are deleted.
  ###   The new PairCoordsSys instance $p now has
  ###    @{$p->{orgcolumns}}: List of all the original columns,
  ###      $p->{cel|pix}->{axis}->[*]->{column}: each index shows the original column number.
  ###   The optional hash can have keys of
  ###    fromcol  => COLumn-number FROM which the values are imported,
  ###    fromaxis => AXIS index number FROM which the values are imported,
  ###    tocol    => COLumn-number TO which the values are implemented,
  ###    toaxis   => AXIS index number TO which the values are implemented.
  ###   In default, all are the string 'auto'.
  ###   Another possible key is 'popaxis' (Default=1); delete the trailing axes
  ###  at the end of this method, if true.
  ###   Another possible key is 'verbosity' (Default=0).
  ### Reference: 

  my ($subname) = "minglePair";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->minglePair($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;
    my %hsarg = @_;
    my %hsprm = ('col'=>{}, 'axis'=>{});
    my($colfinal);
    my($fromto, $colaxis, $eachn, $eachp, $eachi, $candn, $candi, $s, $i);

    $hsarg{'popaxis'} = 1   if (! exists($hsarg{'popaxis'}));
    $hsarg{'verbosity'} = 0 if (! exists($hsarg{'verbosity'}));

    return undef if (ref($c1->{col}) ne 'ARRAY');
    $colfinal = $#{$c1->{col}};
    return undef if ($colfinal < 0);

    ## Optional hash handling
    foreach $colaxis ( qw(col axis) ) {
      foreach $fromto ( qw(to from) ) {
	$s = $fromto . $colaxis;
	if (defined($hsarg{$s})) {
	  if (isnumber($hsarg{$s})) {
	    $hsprm{$colaxis}{$fromto} = $hsarg{$s};
	  } elsif (($hsarg{$s} eq '') || (lc($hsarg{$s}) eq 'auto')) {
	    $hsprm{$colaxis}{$fromto} = 'auto';
	  } else {
	    sscwarn("Value of the option($s) is wrong in $subname() in $self.");
	    return undef;
	  }
	} else {
	  $hsprm{$colaxis}{$fromto} = 'auto';
	}	# if (defined($hsarg{$s})) ... else ...
      }	#  foreach $fromto qw(to from)
    }	# foreach $colaxis qw(col axis)

    ###### Handles 'auto' and decides which column/axis ######

    my(@arcol, @arnaxis, @artmp);
    # my(%flag) = ('setindex' => 0);
    my(%flag) = ('searchRaDec' => 1, 'searchUndef' => 1, 'searchAny' => 1);
    my($curcol, $curaxis);
    foreach $fromto ( qw(to from) ) {	# Case "to" first.
      next if ( ($hsprm{'col'}{$fromto} ne 'auto') && ($hsprm{'axis'}{$fromto} ne 'auto') );
      if ($hsprm{'col'}{$fromto}  eq 'auto') {
	@arcol = 0..$colfinal;
      } else {
	@arcol = $hsprm{'col'}{$fromto};
      }
      if ($hsprm{'axis'}{$fromto} eq 'auto') {
	@arnaxis = ();
      } else {
	@arnaxis = $hsprm{'axis'}{$fromto};
      }

      $curcol  = undef;
      $curaxis = undef;
      foreach $eachn (@arcol) {
	if ( (($fromto eq "to")   && (isnumber($hsprm{'col'}{"from"})) && ($hsprm{'col'}{"from"} == $eachn)) ||
	     (($fromto eq "from") && (isnumber($hsprm{'col'}{"to"}))   && ($hsprm{'col'}{"to"}   == $eachn)) ) {
	  # The current index is already used, hence skipped.
	  next;
	}
	next if (! $c1->{col}[$eachn]);		# Column is null.

	foreach $eachp ( qw(cel pix) ) {
	  next if (! $c1->{col}[$eachn]->{$eachp}->{axis});	# Axis is null.
	  next if (ref($c1->{col}[$eachn]->{$eachp}->{axis}) ne 'ARRAY');	# Axis is not ARRAY.
	  next if (scalar(@{$c1->{col}[$eachn]->{$eachp}->{axis}}) < 1);	# Axis is null ARRAY.

	  $candn = undef;
	  $candi = undef;
	  if ( $flag{'searchRaDec'} ) {
	    ## Case
	    #   TCRV3: type=RA  ([Value1])
	    #   TCRV4: type=DEC ([Value2])
	    # or
	    #   TCRV3: type=RA  ([Value1, undef])
	    #   TCRV4: type=DEC ([undef,  Value2])
	    # then,
	    #   TCRV3 ==> RA,DEC  ([Value1, Value2])

	    @artmp = @{$c1->{col}[$eachn]->{$eachp}->{axis}};
	    if ($fromto eq 'to') {
	      if ( (defined($artmp[0]->{type})) &&
		   ($artmp[0]->{type} =~ /^(RA|GLON)\b/) &&	# Axis[0] must be RA.
		   ( ( (scalar(@artmp) == 1) ) ||	# Size of Axis is 1.
		     ( (scalar(@artmp) == 2) && 	# Size of Axis is 2 and [1] is undefined (for DEC).
		       ((ref($artmp[1]) ne 'HASH') || (! defined($artmp[1]->{val}))) ) ) ) {
		$candn = $eachn;
		$candi = 1;
	      } else {
		last;	# Skip evaluation of pix.
	      }
	    } else {	# namely, if ($fromto eq 'from')
	      if      ( (defined($artmp[0]->{type})) &&
			($artmp[0]->{type} =~ /^(DEC|GLAT)\b/) &&	# Axis[0] must be DEC.
			(scalar(@artmp) == 1) &&	# Size of Axis is 1 and [0]->{val} is defined (DEC).
			((ref($artmp[0]) eq 'HASH') || (  defined($artmp[0]->{val}))) ) {
		$candn = $eachn;
		$candi = 0;
	      } elsif ( (defined($artmp[1]->{type})) &&
			($artmp[1]->{type} =~ /^(DEC|GLAT)\b/) &&	# Axis[1] must be DEC.
			(scalar(@artmp) == 2) &&	# Size of Axis is 2 and [0]->{val} is undefined (RA) and [1]->{val} is defined (DEC).
			((ref($artmp[0]) ne 'HASH') || (! defined($artmp[0]->{val}))) &&
			((ref($artmp[1]) eq 'HASH') && (  defined($artmp[1]->{val}))) ) {
		$candn = $eachn;
		$candi = 1;
	      } else {
		last;	# Skip evaluation of pix.
	      }
	    }

	  } elsif ($flag{'searchUndef'}) {	# ie., if ($flag{'searchAny'})

	    ## Case
	    #   TCRV3: type=ANY ([Value1, undef])
	    #   TCRV4: type=ANY ([undef,  Value2])
	    # then,
	    #   TCRV3 ==> RA,DEC  ([Value1, Value2])

	    @arnaxis = (0..$#{$c1->{col}[$eachn]->{$eachp}->{axis}}) if (! scalar(@arnaxis));	# namely, 'auto' for "axis"
	    foreach $eachi (@arnaxis) {	# Each axis number
	      if ( ( ($fromto eq 'to') && 
		     (! defined($c1->{col}[$eachn]->{$eachp}->{axis}[$eachi]->{val})) ) ||
		   ( ($fromto eq 'from') && 
		     (  defined($c1->{col}[$eachn]->{$eachp}->{axis}[$eachi]->{val})) ) ) {
		## This column/axis is likely to be the one to mingle.
		$candn = $eachn;
		$candi = $eachi;
		last;
	      } elsif ($flag{'searchAny'}) {
	      } else {
	      }
	    }	#    foreach $eachi (@arnaxis)

	  } else {
	    die "Not supported, yet.  Contact the code developer.";
	  }	# if ( $flag{'searchRaDec'} ) ... else ...

	  if (defined($curcol)) {
	    if (($curcol != $candn) && ($hsprm{'col'}{$fromto} eq 'auto')) {
	      sscwarn("Column(n=$candn) (in ($eachp) for ($fromto)) is another candidate, but here uses already defined value ($curcol).") if ($hsarg{'verbosity'} > 3);	# Presumably it is processing 'pix' now, while it has been defined already in 'cel'
	      # $curcol  = $candn;
	    }
	  } else {
	    $curcol  = $candn;
	  }

	  if (defined($curaxis)) {
	    if (($curaxis != $candi) && ($hsprm{'axis'}{$fromto} eq 'auto')) {
	      sscwarn("Axis(i=$candi) (in ($eachp) for ($fromto)) is another candidate, but here uses already defined value ($curaxis).") if ($hsarg{'verbosity'} > 3);	# Presumably it is processing 'pix' now, while it has been defined already in 'cel'
	      # $curaxis = $candi;
	    }
	  } else {
	    $curaxis = $candi;
	  }

	  @arnaxis = () if (! isnumber($hsprm{'axis'}{$fromto}));
	}	#   foreach $eachp qw(cel pix)
      }		#  foreach $eachn (@arcol)

      if ($hsprm{'col'}{$fromto} eq 'auto') {
	if (defined $curcol) {
	  $hsprm{'col'}{$fromto} = $curcol;
	} else {
	  if ($flag{'searchRaDec'}) {
	    sscnote("Search for RA/Dec failed in ($fromto).  Searching for undef/defined now.\n") if ($hsarg{'verbosity'} > 4);
	    $flag{'searchRaDec'} = 0;
	    redo;	# Retry with a different searching algorithm.
	  # } elsif ($flag{'searchUndef'}) {
	  #   $flag{'searchUndef'} = 0;
	  #   redo;	# Retry with a different searching algorithm.
	  # # } elsif ($flag{'searchAny'}) {
	  # #   $flag{'searchAny'} = 0;
	  # #   redo;
	  } else {
	    sscwarn("Failed to determine the candidate Column for ($fromto).");
	    return undef;
	  }
	}
      }

      if ($hsprm{'axis'}{$fromto} eq 'auto') {
	if (defined $curaxis) {
	  $hsprm{'axis'}{$fromto} = $curaxis;
	} else {
	  if ($flag{'searchRaDec'}) {
	    sscnote("Search for RA/Dec failed in ($fromto).  Searching for undef/defined now.\n") if ($hsarg{'verbosity'} > 4);
	    $flag{'searchRaDec'} = 0;
	    redo;	# Retry with a different searching algorithm.
	  # } elsif ($flag{'searchUndef'}) {
	  #   $flag{'searchUndef'} = 0;
	  #   redo;	# Retry with a different searching algorithm.
	  # # } elsif ($flag{'searchAny'}) {
	  # #   $flag{'searchAny'} = 0;
	  # #   redo;
	  } else {
	    sscwarn("Failed to determine the candidate Axis number for ($fromto).");
	    return undef;
	  }
	}
      }

    }		# foreach $fromto qw(to from)

    sscnote("Mingle From (Col,Axis)=($hsprm{'col'}{'from'}, $hsprm{'axis'}{'from'}) To (Col,Axis)=($hsprm{'col'}{'to'}, $hsprm{'axis'}{'to'}).\n") if ($hsarg{'verbosity'} > 4);


    ###### MAIN ######

    my $m2 = $c1->deepcopy;	# MultipleCoordsSys


    die "Wrong col-from ($hsprm{'col'}{'from'})\n" if ($hsprm{'col'}{'from'} eq "auto");
    die "Wrong col-to ($hsprm{'col'}{'to'})\n" if ($hsprm{'col'}{'to'} eq "auto");
    die "Wrong axis-from ($hsprm{'axis'}{'from'})\n" if ($hsprm{'axis'}{'from'} eq "auto");
    die "Wrong axis-to ($hsprm{'axis'}{'to'})\n" if ($hsprm{'axis'}{'to'} eq "auto");

    my $p2 = $m2->{col}[$hsprm{'col'}{'to'}]->merge($m2->{col}[$hsprm{'col'}{'from'}],
						    'from'=>$hsprm{'axis'}{'from'},
						    'to'  =>$hsprm{'axis'}{'to'});
    # PairCoordsSys object (merge() as a method in PairCoordsSys)

    $p2->{orgcolumns} = [$hsprm{'axis'}{'from'}, $hsprm{'axis'}{'to'}];
    foreach $eachp ( qw(cel pix) ) {
      $p2->{$eachp}->{axis}[$hsprm{'axis'}{'to'}]->{column} = $hsprm{'col'}{'from'};
    }

    $m2->{col}[$hsprm{'col'}{'to'}]   = $p2;
    $m2->{col}[$hsprm{'col'}{'from'}] = undef;

    if ( ($hsarg{'popaxis'}) &&
	 ($hsprm{'col'}{'from'} == $#{$m2->{col}}) ) {
      ## pop all the insignificant trailing axis if $hsprm{'col'} is the last index.
      pop(@{$m2->{col}});
      foreach $i (reverse(0..$#{$m2->{col}})) {
	if ($m2->{col}[$i]) {
	  last;
	} else {
	  pop(@{$m2->{col}});
	}
      }
    }

    return $m2;
  }	#  if (ref($self))
}	# sub minglePair


#---------------------------------------------------------------------
sub to_s {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input(Class method):  (m1, ['indent'=>"", 'withname'=>0|1], 'verbosity'=>\d)
  ### Input(Normal method): (['indent'=>"", 'withname'=>0|1], 'verbosity'=>\d)
  ### Return: String expression.
  ### Description: 
  ###   If the optional indent, such as, "| " is given, it is added
  ###  to the head of each line.
  ###   Verbosity: 0:Silent, 2:rather-quiet, 3:Sparse, 4:Verbose, 5:Noisy
  ### Reference: 

  my ($subname) = "to_s";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->to_s($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $m1=shift;
    my %hsarg=@_;
    my $indent = ($hsarg{'indent'} || "");
    # my $indentregexp = quotemeta($indent);

    my %hsdef = ('verbosity' => 2);
    my %hs2pass = ('indent' => "  ");
       %hs2pass = hashmerge(\%hs2pass, \%hsarg);	# in SSCLib
       %hs2pass = hashmerge(\%hs2pass, \%hsdef);	# in SSCLib
    my $verbosity = $hs2pass{'verbosity'};	# 2 in default.

    my($retstr, $strmatrix, $eachkey, $n, $i, $j, $k, $s);
    $retstr  = sprintf("===== Ext=(%s) Sysname=(%s) Coordinate-Version=(%s) =====\n",
		       ($m1->{'ext'}     || 0),
		       ($m1->{'sysname'} || 'undef'),
		       ($m1->{'coordver'}|| 'undef') );

    if (ref($m1->{matrix}) eq 'HASH') {
      $strmatrix = ''; 
      foreach $eachkey (keys(%{$m1->{matrix}})) {
	next if (ref($m1->{matrix}->{$eachkey}) ne 'ARRAY');
	foreach $n (0..$#{$m1->{matrix}->{$eachkey}}) {
	  next if (ref($m1->{matrix}->{$eachkey}[$n]) ne 'ARRAY');
	  foreach $i (0..$#{$m1->{matrix}->{$eachkey}[$n]}) {
	    next if (ref($m1->{matrix}->{$eachkey}[$n][$i]) ne 'ARRAY');
	    foreach $j (0..$#{$m1->{matrix}->{$eachkey}[$n][$i]}) {
	      next if (ref($m1->{matrix}->{$eachkey}[$n][$i][$j]) ne 'ARRAY');
	      foreach $k (0..$#{$m1->{matrix}->{$eachkey}[$n][$i][$j]}) {
		next if (! defined($m1->{matrix}->{$eachkey}[$n][$i][$j][$k]));
		$strmatrix .= sprintf("  %s (n=%d i=%d j=%d km=%d): ",
				      $eachkey, $n, $i, $j, $k);
		$strmatrix .= $m1->{matrix}->{$eachkey}[$n][$i][$j][$k];
		$strmatrix .= "\n";
	      }	#   Loop over m
	    }	#   Loop over k
	  }	#   Loop over j
	}	#   Loop over n
      }		#  foreach $eachkey (keys(%{$m1->{matrix}}))

      if ($strmatrix) {
	$retstr .= " === Matrix:\n";
	$retstr .= $strmatrix;
      } else {
	$retstr .= " === Matrix: NONE\n" if ($verbosity > 2);
      }
    } else {	# if (ref($m1->{matrix} eq 'HASH'))
      $retstr .= " === Matrix: NONE\n" if ($verbosity > 2);
    }
    if (ref($m1->{col}) eq 'ARRAY') {
      foreach $n (0..$#{$m1->{col}}) {
	if ((! $m1->{col}[$n]) || ($m1->{col}[$n]->isNil)) {	# PairCoordsSys->isNil
	  $retstr .= sprintf(" === Column(n=%d): NONE\n", $n) if ($verbosity > 2);
	} else {
	  $retstr .= sprintf(" === Column(n=%d): \n", $n);
	  $s = $m1->{col}[$n]->to_s(%hs2pass);	# PairCoordsSys->to_s
	  $retstr .= $s;
	}
      }
    } else {
      $retstr .= " === Column: NONE\n" if ($verbosity > 2);
    }

    $retstr =~ s/^/$indent/gm;	# Add an indent, if needed.
    return $retstr;
  }
}	# sub to_s


#---------------------------------------------------------------------
sub _undef2zero {	# for MultipleCoordsSys
#---------------------------------------------------------------------
  ### Input:  (ARRAY)
  ### Return: (ARRAY) where undef is replaced with numerical 0.
  ### Description:  Normal function!
  ### Reference: 

  map {defined($_) ? $_ : 0 } @_;
}	# sub _undef2zero


1;


########################  TEST ########################

