package Coords;

# Author: Masaaki Sakano - SSC/LUX

our $VERSION = '4.21';
use strict;
# use Exporter 'import';
# our @EXPORT    = qw(Coords angulardistance to_s);		# symbols to export in default
# our @EXPORT_OK = qw();	# symbols to export on request

use strict;
use Data::Dumper;
use SSCLib qw(strip isnumber list2hashedindex areScalarsEqual areArraysEqual hashmerge sscnote sscwarn);
use DeepCopy;

our $Taskname = 'Coords';

=head1 NAME

Coords - Class for general-use Coordinates objects.

=head1 SYNOPSIS

    use Coords;

=head1 DESCRIPTION

Class for the coordinates.
So far to set and get the coordinates (in a neat way) are
pretty much the only facilities this class provide.

=item new ( ARGUMENTS )

Input is either a hash 
or an array of numbers like (123.45, -67.8), representing x, y, ...
If it is a hash, the allowed keys are
(allarg|arrayhash|([xyz]|all|misc|comment)%[\w_\-]+|name|subname),
where the standard 2nd components following "%" are
(val|unit|name|shortname|comment|type), although
any other arbitrary keywords are allowed.

In the above two ways of giving the information for each axis are provided.
The "y%val" key should give the value of Y-axis, and as such.
"arrayhash" key, if exists, should give an array, in which
each component gives a hash of (val|unit|name|shortname|comment|type).
This is particularly useful when the coordinates have more than 3 axes.
Note that if "arrayhash" key exists, the key "[xyz]%[\w_\-]+" is ignored.
"allarg" key can be used to directly give the input hash,
which is sometimes handy for machine-inputs if not so convenient for humans;
in that case "%" symbols, if ever given, are of course literally interpreted.
Another note is that it is recommended to set "all%type"=>"cartesian"
if it is the Cartesian coordinates, as that will allow you to calculate
the cartesian distance.

A couple of sets of example arguments are as follows:
    (123.45, -67.8, 0);
    ("x%val"=>123.45, "y%val"=>-67.8, "x%unit"=>"km", "y%unit"=>"km", "x%name"=>"Distance", "y%name"=>"Height", "x%shortname"=>"d", "y%shortname"=>"h", "all%type"=>"cartesian","name"=>"Aeroplane", "subname"=>"No.999");
    ("arrayhash"=>[{"val"=>3,"unit"=>"km"}, {"val"=>4,"shortname"=>"Y"}], "all%name"=>"CoordTest");
    ("allarg"=>{"axis"=>[{"val"=>3,"unit"=>"km"}, {"val"=>4,"shortname"=>"Y"}], "all"=>{"name"=>"CoordTest"}});


To get/set the values of this object (say, $obj), refer to them as follows;

    $obj->{axis}->[0]->{unit}	# unit in X-axis.
    $obj->{axis}->[1]->{val}	# value in Y-axis.
    $obj->{axis}->[2]->{name}	# name of Z-axis.
    $obj->{axis}->[2]->{shortname}	# short-name of Z-axis.
    $obj->{axis}->[2]->{comment}	# Comment for Z-axis.
    $obj->{axis}->[2]->{type}	# type of Z-axis.
    $obj->{all}->{type}
    $obj->{misc}->{shortname}
    $obj->{name}	# Name of this object: one of few default top-level keys
    $obj->{subname}	# Sub-name: one of few default top-level keys
    $obj->{comment}->{YOURTAG}

=item to_s ( )

Returns the string of the instance (to print), which consists of 3 lines or more.

=item isNearlyEqual ( [c1], c2, [precision, [maximum_difference, [Hash...]]] )

Defined as both class and normal methods.
In the former case, this needs one extra argument of the instance of this class.
If both the Coords instances are judged to be nearly equal,
then returns 1, or 0 otherwise.
It is based on the given precision and/or maximum_difference.
See the reference of SSCLib.pm for detail about them.
Inside, this routine checks whether all the 'val' in all axes are the same,
and whether other parameters (unit, type, sys, epoch) are the same.

In this method, if the maximum_difference is given,
the precision is ignored in evaluating 'val's in all axes.
For the other parameters, unless the optional hash with the element of
'ignoremaxdiffexceptval'=>0 is given, the maximum_difference
is ignored but precision is taken into account.

Note evaluation is performed for each parameter (or axis) independently
in principle.  However, if the method distance() is defined
(perhaps in the Subclass) or if ({all}->{type}=="cartesian")
for both the given Coords instances, and
if maximum_difference is given, the cartesian distance is calculated
and evaluated to give further constraints.
In the case of Cartesian, there should be no axis with undef 'val'
somewhere in the middle to be possibly considered to be equal
(whereas preceding and trailing insignificant axes are simply ignored).

Note if one of the values in the pair are undefined,
checking is simply skipped, except for 'val's, for which
all the significant indices must be consistent between c1 and c2,
to be possibly qualified to be "nearly equal".
For example, when all->epoch is defined only in one of the objects,
this does NOT immediately return false (=0).


=item isNil ( )

Returns 1 if the object is not _significant_, or 0 otherwise.

=item arraySignificantValIndex ( )

Defined as both class and normal methods.
Returns the Array indicating significant indices for {axis}->[?]->{val},
for example, (0, 1, 1, 0) means the 1st and 2nd indices are significant.
If 'axis' is not defined first of all, null Array () is returned.

=item firstSignificantValIndex ( [c1], [\@arraySignificantValIndex] )

Defined as both class and normal methods.
Returns the index of the first "significant" axis,
namely the axis, of which 'val' is defined.
This optionally takes the reference of the returned
array of arraySignificantValIndex() (it will be calculated
internally if not given).

=item lastSignificantValIndex ( [c1], [\@arraySignificantValIndex] )

Defined as both class and normal methods.
The same as firstSignificantValIndex, but returns that of the last one.

=item areValsFilled ( [c1], [(First|-1), [(Last|-1), [\arraySignificantValIndex]]] )

Defined as both class and normal methods.
Returns 1 if all the {axis}->[?]->{val} between (optionally given)
First and Last indices are defined, or 0 otherwise.

If First/Last is undef, then 0 and size of the axes-Array are used
for the first/last indices, respectively.
If it is -1 (or negative), then the first/last SIGNIFICANT indices are
estimated and used, ie., the preceding and trailing indices
with insignificant (meaning 'val' is undef) are ignored.
This optionally takes a reference of the returned array
of Coords->arraySignificantValIndex() in the argument.

=item distanceCartesian ( [c1], c2, [('ifirst'=>$i1ini, 'ilast'=>$i1fin, 'arysig'=>\@arsig1)])

Defined as both class and normal methods.
Returns the distance between c1 and c2 in the Cartesian coordinates.
It is users' responsibility that all the 'val's in BOTH the instances
for the significant indices are guaranteed to have values,
and the ranks for c1 and c2 are consistent.
Although this method accepts ifirst==-1 etc in the argument,
it checks with only the first instance, c1.

See the description of areValsFilled() for the meaning of the argument
(though the interface in this method is hash, instead of array).

=item isAxisAngle ( [c1], index )

Defined as both class and normal methods.
Returns 1 if the axis[index] is angle, or 0 otherwise.

=item deepcopy ( [c1], ['exclude'=>RegExp] )

Imported from DeepCopy.pm module.


=cut
  ;	# For Emacs


############################################################

my @STANDARD_HASH_KEYS_FOR_SUBCOMPONENT
  = qw(val unit name shortname comment type);	# Global variable valid only within this package.

#---------------------------------------------------------------------
sub new {
#---------------------------------------------------------------------
  ### Input: ("x%val"=>123.45, "y%val"=>-67.8, "x%unit"=>"km", "y%unit"=>"km", "x%name"=>"Distance", "y%name"=>"Height", "x%shortname"=>"d", "y%shortname"=>"h", "all%type"=>"cartesian", "name"=>"Proton", "subname"=>"cross-section")
  ###    or  (Numeric, Numeric, [Numeric, [...]])
  ###   If the second form is chosen, the units have to be in degree.
  ### Return: (Instance of Coords class)
  ### Description: 
  ### Constraints:
  ### Global: 
  ### Usage example:

  my $class = shift;	# The first argument is Coords
  my @ararg = @_;
  my $self = {};
  bless $self, $class;	# Inheritance is applied (with this 2-arguments bless), if there is any.
  $self->_initialize(@ararg);
  return $self;
}

sub _initialise_each_hash_subcomponent {
  ### Input: $self->{all} or alike.
  ### Return: NONE
  ### Description: Initialise the Input, reference to a hash (eg $self->{all})

  my $s;
  $_[0] = {};
  foreach $s ( @STANDARD_HASH_KEYS_FOR_SUBCOMPONENT ) {
    $_[0]->{$s} = undef;
  }
}

sub _initialize {
  my $self = shift;	# The first argument is always SELF.
  my @ararg = @_;
  $self->{instance} = \@ararg;	# For Debug.

  my %xyz123 = &list2hashedindex( qw(x y z) );	# in SSCLib
  my %flag = ('isallnumber' => 1);	# True in default.
  my(@ar, $i, $s1, $s2, $val_arrayhash, $val_allarg);

  ## Initialisation
  foreach ( qw(name subname) ) {
    $self->{$_} = '';
  }
  foreach ( qw(all misc comment) ) {
    &_initialise_each_hash_subcomponent($self->{$_});
    # $self->{$_} = {};
    # foreach $s2 ( @STANDARD_HASH_KEYS_FOR_SUBCOMPONENT ) {
    #   $self->{$_}{$s2} = undef;
    # }
  }
  $self->{axis} = [];

  ## Check if the input argument is an Array or not.
  foreach (@ararg){
    next if (! defined $_);
    if (! &isnumber($_)) {	# in SSCLib
      $flag{'isallnumber'} = 0;
      last;
    }
  }

  ## MAIN: Set up the object instances.
  if ($flag{'isallnumber'}) {	# The input argument is an Array.
    foreach $i (0..$#ararg){
      &_initialise_each_hash_subcomponent($self->{axis}->[$i]);	# Call as a normal function, NOT as a method in this package.
      $self->{axis}->[$i]->{val} = $ararg[$i];
    }

  } else {			# The input argument is a Hash.
    my %hsarg = @ararg;

    $val_arrayhash = undef;
    while (scalar(@ar=each(%hsarg)) > 0){
      if ($ar[0] =~ /^([\w_\-]+)%([\w_\-]+)$/) {	# The argument is in the form of *%*
	$s1 = $1;
	$s2 = $2;
	if ($s1 =~ /^[xyz]$/i) {	# x%val, y%unit etc.
	  if (! defined(                        $self->{axis}->[$xyz123{lc($s1)}])) {
	    &_initialise_each_hash_subcomponent($self->{axis}->[$xyz123{lc($s1)}]);
	  }
	  $self->{axis}->[$xyz123{lc($s1)}]->{$s2} = $ar[1];
	} else {			# all%unit, misc%name etc.
	  if (! defined(                        $self->{$s1})) {
	    &_initialise_each_hash_subcomponent($self->{$s1});
	  }
	  $self->{$s1}->{$s2} = $ar[1];
	}

      } else {
	if ($ar[0] eq 'allarg') {
	  $val_allarg     = $ar[1];
	} elsif ($ar[0] eq 'arrayhash') {
	  $val_arrayhash  = $ar[1];
	} else {	# (name|subname)
	  $self->{$ar[0]} = $ar[1];	# Skip 'arrayhash'.
	}
      }
    }	# while (scalar(@ar=each(%hsarg)) > 0)

    if (defined($val_allarg)) {		# 'allarg' is specified.
      while (scalar(@ar=each(%{$val_allarg})) > 0) {
	$self->{$ar[0]} = $ar[1];
      }

      # NOTE: arrayhash option is ignored.
      #  If there are other top-level (such as, 'axis', 'all', 'misc')
      # parameters that are separately specified and are not included
      # in 'allarg', those stay as they are.

    } elsif (defined($val_arrayhash)) {	# 'arrayhash' is specified.
      $self->{axis} = $val_arrayhash;	# Reference to Array.

      # NOTE: If scalar(@$val_arrayhash) is 2, and if z%val etc,
      # namely out of the range of the size of @$val_arrayhash exist,
      # then those values stay as they are in $self->{axis},
      # that is, they are not overwritten or deleted.
    }

  }	#  if ($flag{'isallnumber'})

  $self;
}	# sub _initialize


#---------------------------------------------------------------------
sub to_s {
#---------------------------------------------------------------------
  ### Input: (['indent'=>"", 'withname'=>1(Default)])
  ### Return: (String representation of the coordinates)
  ### Description: 
  ###   If the optional indent, such as, "| " is given, it is added
  ###  to the head of each line.
  ### Constraints:
  ### Global: 
  ### Usage example:

  my $self = shift;	# The first argument is $self
  my %arghashpartdef = ('indent' => "", 'withname' => 1);
  my %hsarg = @_;
     %hsarg = hashmerge(\%hsarg, \%arghashpartdef);	# in SSCLib

  my $indent = ($hsarg{'indent'} || "");

  my ($i, $j, $s, $retstr);

  ### 1st line (not printed, if specified so)
  $retstr = sprintf("NAME (SUB): %s (%s)\n"
		    , ($self->{name}    ? $self->{name}    : "NONE")
		    , ($self->{subname} ? $self->{subname} : "NONE")
		    ) if ($hsarg{'withname'});

  ### 2nd line
  ## Names of x, y, ...
  $retstr .= "(";
  foreach $i (0..$#{$self->{axis}}) {
    $s = '';
    if ((defined $self->{axis}->[$i]->{shortname}) && (strip($self->{axis}->[$i]->{shortname}) ne '')) {	# strip() in SSCLib
      $s = $self->{axis}->[$i]->{shortname};
    } elsif ((defined $self->{axis}->[$i]->{name}) && (strip($self->{axis}->[$i]->{name}) ne '')) {		# strip() in SSCLib
      $s = $self->{axis}->[$i]->{name};
    } else {
      $s =  sprintf("C%d",$i+1);	# ("C1"[x], "C2"[y], ...) if the axis name is not defined.
    }
    # $retstr .= ($s ? $s : "C".$i+1) . ",";
    $retstr .= $s . ",";
  }
  $retstr = substr($retstr,0,length($retstr)-1);	# Remove "," in the end
  ## Values of x, y, ...
  $retstr .= ")=(";
  foreach $i (0..$#{$self->{axis}}) {
    if (defined $self->{axis}->[$i]->{val}) {
      $retstr .= $self->{axis}->[$i]->{val} . ",";
    } else {
      $retstr .= 'UNDEFINED' . ",";
    }
  }
  $retstr = substr($retstr,0,length($retstr)-1);	# Remove "," in the end
  $retstr .= ")";

  ## Units of x, y, ...
  $retstr .= " [";
  foreach $i (0..$#{$self->{axis}}) {
    $retstr .= ($self->{axis}->[$i]->{unit} ? $self->{axis}->[$i]->{unit} : "UNDEFINED") . ",";
  }
  $retstr = substr($retstr,0,length($retstr)-1);	# Remove "," in the end
  $retstr .= "]\n ";

  ### 3rd line
  ## Common things
  foreach $i (keys(%{$self->{all}})) {
    if (defined $self->{all}->{$i}) {
      $retstr .= " $i=(" . $self->{all}->{$i} . "),";
    }
  }
  $retstr = substr($retstr,0,length($retstr)-1);	# Remove "," in the end
  $retstr .= "\n";

  ### 4th and following lines
  foreach $i (keys(%{$self->{comment}})) {
    if (defined $self->{comment}->{$i}) {
      $retstr .= sprintf("# %s: %s\n", $i, $self->{comment}->{$i});
    }
  }

  $retstr =~ s/^/$indent/gm;	# Add an indent, if needed.
  return($retstr);
}


#---------------------------------------------------------------------
sub isNearlyEqual {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, c2, [precision, [maximum_difference, [Hash...]]])
  ### Input(Normal method):    (c2, [precision, [maximum_difference, [Hash...]]])
  ### Return: 1 if yes, or 0 otherwise.
  ### 
  ### Description: 
  ###   Check whether all the 'val' in all axes are the "same",
  ###  in the given precision or maximum_difference (if the latter
  ###  is given, the former is ignored for 'val', because the difference
  ###  between RA=0.0001 and (+/-)0.00001 may be insignificant whereas
  ###  they differ by a factor of (+/-)10), and whether other parameters
  ###  (unit, type, sys, epoch, etc) are the same, and if so, returns 1.
  ###  For {axis}, except for 'unit' and 'type', only numerical values
  ###  are checked, that is, none of character values are evaluated.
  ###  For example, {axis}[0]{CDELT} is checked, whereas {axis}[0]{comment} is generally not.
  ### 
  ###   Note evaluation is performed for each parameter (or axis) independently
  ###  in principle.  However, if the method distance() is defined
  ###  perhaps in the Subclass or if ({all}->{type}=="cartesian"), and
  ###  if maximum_difference is given, the cartesian distance is calculated
  ###  and evaluated to give further constraints.
  ###  In the case of Cartesian, there should be no axis with undef 'val'
  ###  somewhere in the middle to be possibly considered to be equal
  ###  (whereas preceding and trailing insignificant axes are simply ignored).
  ### 
  ###   Note if one of the values in the pair are undefined,
  ###  checking is simply skipped, except for 'val's, for which
  ###  all the significant indices must be consistent between c1 and c2,
  ###  to be possibly qualified to be "nearly equal".
  ###  For example, when all->epoch is defined only in one of the objects,
  ###  this does NOT immediately return false (=0).
  ### 
  ###   If a 'verbosity' (Numeric) is specified in the optional Hash,
  ###  this routines may issue the comment to STDERR when it is
  ###  found out to be NOT nearly equal, depending on the verbosity level.
  ###   Default(0), Sparse(3), Verbose(4), Noisy(5).
  ### 
  ###   Calls &SSCLib::areScalarsEqual() in it.
  ### Reference: 

  my ($subname) = "isNearlyEqual";
  my $self=shift;

  my %flag = ( 'cartesian'=>0 );

  if (ref($self)) {	# Normal method.
    return( ref($self)->isNearlyEqual($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;
    my $c2=shift;
    my $maxdiff = $_[1];	# maybe undef.
    my @argrest = @_;
    my %arghashpartdef = ('ignoremaxdiffexceptval'=>1, 'verbosity'=>0);	# Default
    my %arghashpart;
       %arghashpart = @argrest[2..$#argrest] if ($#argrest >= 2);
       %arghashpart = hashmerge(\%arghashpart, \%arghashpartdef);	# Hash part of the given argument.

    my @arg4allbutval = @argrest;
    my @arg4val       = @argrest;

    if ($arghashpart{'ignoremaxdiffexceptval'}) {
      $arg4allbutval[1] = undef if ($#arg4allbutval >= 1);	# No maxdiff.
    }
    if (defined $maxdiff) {
      $arg4val[0] = undef if ($#arg4val >= 0);			# No precision.
    }


    my($i, $j, $i1ini, $i1fin, $eachk);

    ## For 'all' and 'misc'
    foreach $j (qw(all misc)) {
      ## 'type|sys|epoch' are checked.
      ## (sys|epoch) are expected to exist only in CelCoord objects.
      foreach $eachk (qw(type sys epoch)) {
	if (exists($$c1{$j}) && exists($$c2{$j})) {
	  if (exists( $c1->{$j}{$eachk}) && exists( $c2->{$j}{$eachk}) &&
	      defined($c1->{$j}{$eachk}) && defined($c2->{$j}{$eachk})) {
	    # If {all|misc}->{type|sys|epoch} lacks in either of them,
	    # it is not checked.
	    # return 0 if (! &SSCLib::areScalarsEqual($c1->{$j}{$eachk}, $c2->{$j}{$eachk}, @arg4allbutval));
	    if (! &SSCLib::areScalarsEqual($c1->{$j}{$eachk}, $c2->{$j}{$eachk}, @arg4allbutval)) {
	      sscnote("($c1->{$j}{$eachk}) is not equal to ($c2->{$j}{$eachk}) for ($j)($eachk).") if ($arghashpart{'verbosity'} > 3);
	      return 0;
	    }
	    if (('all' eq $j) && ('type' eq $eachk) &&
		(defined $c1->{$j}{$eachk}) &&
		(defined $c2->{$j}{$eachk}) &&
		('cartesian' eq lc(&strip($c1->{$j}{$eachk}))) &&
		('cartesian' eq lc(&strip($c2->{$j}{$eachk}))) ) {	# strip() in SSCLib
	      $flag{'cartesian'} = 1;	# Cartesian coordinates.
	    }
	  }
	}
      }
    }

    my @arsig1 = $c1->arraySignificantValIndex;
    my @arsig2 = $c2->arraySignificantValIndex;
#print Dumper \@arsig1;
#print Dumper \@arsig2;

    # For (only) 'val', when it exists in one, then it has to exist
    # in the other as well.  Plus, the ranks of the axes have to be
    # consistent.
    if (! &SSCLib::areArraysEqual(\@arsig1, \@arsig2)) {	# Some of the 'val's do not exist in either of the instances.
      sscnote("Significant axies are different.") if ($arghashpart{'verbosity'} > 3);
      print Dumper \@arsig1 if ($arghashpart{'verbosity'} > 5);
      print Dumper \@arsig2 if ($arghashpart{'verbosity'} > 5);
      return 0;
    }

    $i1ini = $c1->firstSignificantValIndex(\@arsig1);
    $i1fin = $c1->lastSignificantValIndex( \@arsig1);
    return 1 if ($i1fin < 0);	## axis is not defined in either of them, so they are "equal".


    ## Now the significant indices for $c1 and $c2 are the same.

    ## For 'axis'
    ## 'unit|type|val' are checked.
    foreach $i (0..$i1fin) {
      # foreach $eachk (qw(unit type val)) {
      foreach $eachk (keys(%{$c1->{axis}[$i]})) {
	next if ( (! exists( $c2->{axis}[$i]{$eachk})) ||
		  (! defined($c1->{axis}[$i]{$eachk})) ||
		  (! defined($c2->{axis}[$i]{$eachk})) );

	# If {axis}[?]->{unit|type} lacks or is undefined in either of them,
	# the following is skipped.

	if ('val' eq $eachk) {
	  if ($c1->isAxisAngle($i) && $c2->isAxisAngle($i)) {	# Angle
	    # Skip this check.
	  } else {
	    if (! &SSCLib::areScalarsEqual($c1->{axis}[$i]{$eachk}, $c2->{axis}[$i]{$eachk}, @arg4val)) {	# Precision is not checked.
	      sscnote("($c1->{axis}[$i]{$eachk}) is not equal to ($c2->{axis}[$i]{$eachk}) for ($i)($eachk).") if ($arghashpart{'verbosity'} > 3);
	      return 0;
	    }
	  }
	} elsif ($eachk =~ /^(unit|type)$/) {
	  if (! &SSCLib::areScalarsEqual($c1->{axis}[$i]{$eachk}, $c2->{axis}[$i]{$eachk}, @arg4allbutval)) {	# maxdiff may not be checked.
	    sscnote("($c1->{axis}[$i]{$eachk}) is not equal to ($c2->{axis}[$i]{$eachk}) for ($i)($eachk).") if ($arghashpart{'verbosity'} > 3);
	    return 0;
	  }
	} elsif ($eachk =~ /(name|comment|note|version)/i) {	# Not checked.
	  next;
	} else {
	  if ( isnumber($c1->{axis}[$i]{$eachk}) &&
	       isnumber($c2->{axis}[$i]{$eachk}) ) {	# Check only numerics.
	    if (! &SSCLib::areScalarsEqual($c1->{axis}[$i]{$eachk}, $c2->{axis}[$i]{$eachk}, @argrest)) {	# Both maxdiff and precision are checked.
	      sscnote("($c1->{axis}[$i]{$eachk}) is not equal to ($c2->{axis}[$i]{$eachk}) for ($i)($eachk).") if ($arghashpart{'verbosity'} > 3);
	      return 0;
	    }
	  }
	}
      }
    }

    my($distance);

    if (defined $maxdiff) {
      if ($c1->can('distance')) {
	$distance = $c1->distance($c2, @argrest);
	if (defined($distance) && ($distance > $maxdiff)) {	# Skip if $distance is undef.
	  sscnote("Distance ($distance) is bigger than maxdiff ($maxdiff).") if ($arghashpart{'verbosity'} > 3);
	  return 0;
	}

      } elsif ($flag{'cartesian'}) {
	# Treat as the Cartesian coordinates.
	# That is, checking whether the distance between the two sets
	# of the given coordinates is less than the given maximum difference.

	if (! $c1->areValsFilled($i1ini, $i1fin, \@arsig1)) {	# Some indices in the middle lack of 'val', which means something wrong in Cartesian.
	  sscnote("Something is wrong in Cartesian coordinates (undef somewhere in the middle).") if ($arghashpart{'verbosity'} > 3);
	  return 0;
	}

	$distance = $c1->distanceCartesian($c2, ('ifirst'=>$i1ini, 'ilast'=>$i1fin, 'arysig'=>\@arsig1));	# 'arysig' is not needed in this case, however if it is not given, it will be calculated anyway in the method internally (even if it is not used in this case).  Therefore it is better to give it here in order to avoid the overhead.

	if (defined($distance) && ($distance > $maxdiff)) {	# Skip if $distance is undef.
	  sscnote("Distance ($distance) is bigger than maxdiff ($maxdiff).") if ($arghashpart{'verbosity'} > 3);
	  return 0;
	}
      }
    }	#   if (defined $maxdiff)

    return 1;

  }	#  if (ref($self))  	# Normal method.
}	# sub isNearlyEqual


#---------------------------------------------------------------------
sub isNil {
#---------------------------------------------------------------------
  ### Input(Class method): (c1)
  ### Input(Normal method):(NONE)
  ### Return: 1 if the object is not _significant_, or 0 otherwise.
  ### Description: 
  ### Reference: 

  my ($subname) = "isNil";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->isNil($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;

    my @ar = $c1->arraySignificantValIndex;

    if (scalar(grep {$_} @ar)) {
      return 0;
    } else {
      return 1;
    }      
  }
}


#---------------------------------------------------------------------
sub arraySignificantValIndex {
#---------------------------------------------------------------------
  ### Input(Class method): (c1)
  ### Input(Normal method):(NONE)
  ### Return: The Array indicating significant indices for {axis}->[?]->{val},
  ###   for example, (0, 1, 1, 0) means the 1st and 2nd indices are significant.
  ###   If 'axis' is not defined first of all, null Array () is returned.
  ### Description: 
  ### Reference: 

  my ($subname) = "arraySignificantValIndex";
  my $self=shift;

  my @arret;

  if (ref($self)) {	# Normal method.
    return( ref($self)->arraySignificantValIndex($self,@_) );	# Practically calling the following.

  } else {		# Class method.
    my $c1=shift;

    return @arret if (! exists($$c1{axis}));
    return @arret if (! defined($c1->{axis}));
    if (ref($c1->{axis}) ne 'ARRAY') {	# Neither ARRAY nor undef.
      print Dumper \$c1;
      die("'axis' in Coords object is wrong.");
    }

    my $sigindex = 0;
    my $i;
    foreach $i (0..$#{$c1->{axis}}) {
# print STDERR "DEBUG:i=($i)\n";
      if (! $c1->{axis}[$i]) {
	push(@arret, 0);
      } elsif (ref($c1->{axis}[$i]) ne 'HASH') {
	push(@arret, 0);
      } elsif (! exists( $c1->{axis}[$i]{val})) {
	push(@arret, 0);
      } elsif (! defined($c1->{axis}[$i]{val})) {
	push(@arret, 0);
      } else {
	push(@arret, 1);
      }
    }

    return @arret
  }	# if (ref($self))
}


#---------------------------------------------------------------------
sub firstSignificantValIndex {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [\arraySignificantValIndex])
  ### Input(Normal method):(NONE or [\arraySignificantValIndex])
  ### Return: The first significant index for {axis}->[?]->{val} .
  ###   Or -1 if none of the {axis}->[*]->{val} is significant.
  ### Description: 
  ###   This optionally takes a reference of the returned array
  ###  of Coords->arraySignificantValIndex() in the argument.
  ### Reference: 

  my ($subname) = "firstSignificantValIndex";
  my $self=shift;
  my $Retdef = -1;

  if (ref($self)) {	# Normal method.
    return( ref($self)->firstSignificantValIndex($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $c1=shift;
    my @arsig;

    if (scalar(@_) >= 1) {
      my $r = shift;
      @arsig = @$r;
    } else {
      @arsig = Coords->arraySignificantValIndex($c1);
    }

    my $i;
    foreach $i (0..$#arsig) {
      return $i if $arsig[$i];
    }

    return $Retdef;
  }	# if (ref($self))
}

#---------------------------------------------------------------------
sub lastSignificantValIndex {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [\arraySignificantValIndex])
  ### Input(Normal method):(NONE or [\arraySignificantValIndex])
  ### Return: The last significant index for {axis}->[?]->{val} .
  ###   Or -1 if none of the {axis}->[*]->{val} is significant.
  ### Description: 
  ###   This optionally takes a reference of the returned array
  ###  of Coords->arraySignificantValIndex() in the argument.
  ### Reference: 

  my ($subname) = "lastSignificantValIndex";
  my $self=shift;
  my $Retdef = -1;

  if (ref($self)) {	# Normal method.
    return( ref($self)->lastSignificantValIndex($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $c1=shift;
    my @arsig;

    if (scalar(@_) >= 1) {
      my $r = shift;
      @arsig = @$r;
    } else {
      @arsig = Coords->arraySignificantValIndex($c1);
    }

    my $i;
    foreach $i (reverse(0..$#arsig)) {
      return $i if $arsig[$i];
    }

    return $Retdef;
  }	# if (ref($self))
}


#---------------------------------------------------------------------
sub areValsFilled {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, [(First|-1), [(Last|-1), [\arraySignificantValIndex]]])
  ### Input(Normal method):([(First|-1), [(Last|-1), [\arraySignificantValIndex]]])
  ### Return: 1 if all the {axis}->[?]->{val} between First and Last indices
  ###  are defined, or 0 otherwise.
  ### Description: 
  ###   First and/or last indices to check are optionally given.
  ###   If it is undef, then 0 and $#Array are used for the first/last
  ###  indices, respectively.
  ###   If it is -1 (or negative), then the first/last _significant_ indices are
  ###  estimated and used, ie., the preceding and trailing indices
  ###  with insignificant (meaning 'val' is undef) are ignored.
  ###   This optionally takes a reference of the returned array
  ###  of Coords->arraySignificantValIndex() in the argument.
  ### Reference: 

  my ($subname) = "areValsFilled";
  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->areValsFilled($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $c1=shift;

    my ($ifirst, $ilast, @arsig) = &_getIFirstLastArsig($c1, @_);

    my $i;
    foreach $i ($ifirst..$ilast) {
      return 0 if (! $arsig[$i]);
    }

    return 1;
  }	# if (ref($self))
}


#---------------------------------------------------------------------
sub isAxisAngle {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, index)
  ### Input(Normal method):(index)
  ### Return: 1 if the axis[index] is angle, or 0 otherwise.
  ### Description: 
  ### Reference: 

  my ($subname) = "isAxisAngle";

  my $self=shift;
  if (ref($self)) {	# Normal method.
    return( ref($self)->isAxisAngle($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $c1=shift;
    my $i=shift;

    if ( exists($$c1{axis}) &&
	 defined($c1->{axis}) &&
	 defined($c1->{axis}[$i]) ) {
      if (      (exists( $c1->{axis}[$i]{type})) &&
		(defined($c1->{axis}[$i]{type})) &&
		($c1->{axis}[$i]{type} =~ /^(angle|RA|DEC)$/) ) {
	return 1;
      } elsif ( (exists( $c1->{axis}[$i]{unit})) &&
		(defined($c1->{axis}[$i]{unit})) &&
		($c1->{axis}[$i]{unit} =~ /^(rad(ians?)?|deg(rees?)?|(arc)?min(utes?)?|(arc|[mu])?sec(onds?)?)$/i) ) {
	return 1;
      } else {
	return 0;
      }
    } else {
      return 0;
    }

  }	# if (ref($self))
}


#---------------------------------------------------------------------
sub distanceCartesian {
#---------------------------------------------------------------------
  ### Input(Class method): (c1, c2, [('ifirst'=>$i1ini, 'ilast'=>$i1fin, 'arysig'=>\@arsig1)])
  ### Input(Normal method):(c2, [('ifirst'=>$i1ini, 'ilast'=>$i1fin, 'arysig'=>\@arsig1)])
  ### Return: Distance between c1 and c2 in the Cartesian coordinates.
  ### Description: 
  ###   It is users' responsibility that all the 'val's in BOTH the instances
  ###  for the significant indices are guaranteed to have values,
  ###  and the ranks for c1 and c2 are consistent.  If that is the case,
  ###  undef is returned (or maybe error --- error-handling routine is
  ###  not perfect at the moment).
  ###  Although this method accepts ifirst==-1 etc in the argument,
  ###  it checks with only the first instance, c1.
  ###
  ###   First and/or last indices to check are optionally given.
  ###   If it is undef, then 0 and $#Array are used for the first/last
  ###  indices, respectively.
  ###   If it is -1 (or negative), then the first/last _significant_ indices are
  ###  estimated for c1 and used, ie., the preceding and trailing indices
  ###  with insignificant (meaning 'val' is undef) are ignored.
  ###   This optionally takes a reference of the returned array
  ###  of Coords->arraySignificantValIndex() in the argument.
  ###  Note if the significant values are given for both ifirst and ilast,
  ###  in principle 'arysig' option should not be needed.  However
  ###  it will be internally calculated anyway even in that case, if not given.
  ###  Therefore, if you have already the 'arysig' array, it is better
  ###  to be given here, in order to avoid the overhead.
  ### Reference: 

  my ($subname) = "distanceCartesian";

  my $self=shift;

  if (ref($self)) {	# Normal method.
    return( ref($self)->distanceCartesian($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $c1=shift;
    my $c2=shift;

    my %hsarg = @_;
    my ($ifirst, $ilast, @arsig) = &_getIFirstLastArsig($c1, $hsarg{'ifirst'}, $hsarg{'ilast'}, $hsarg{'arysig'});

    my $i;
    my $distance2 = 0;	# Square of the distance.

    foreach $i ($ifirst..$ilast) {
      if (defined($c1->{axis}[$i]{val}) && defined($c2->{axis}[$i]{val})) {
	$distance2 += ($c1->{axis}[$i]{val} - $c2->{axis}[$i]{val})**2;
      } else {
	return undef;
      }
    }

    return sqrt($distance2);
  }	# if (ref($self))
}


#---------------------------------------------------------------------
sub _getIFirstLastArsig {
#---------------------------------------------------------------------
  ### Input: (c1, [(First|-1), [(Last|-1), [\arraySignificantValIndex]]])
  ### Return: (iFirst, iLast, @arsig...)
  ### Description: 
  ###   This is an internal normal function.
  ###   First and/or last indices to check are optionally given.
  ###   If it is undef, then 0 and $#Array are used for the first/last
  ###  indices, respectively.
  ###   If it is -1 (or negative), then the first/last _significant_ indices are
  ###  estimated and used, ie., the preceding and trailing indices
  ###  with insignificant (meaning 'val' is undef) are ignored.
  ###   This optionally takes a reference of the returned array
  ###  of Coords->arraySignificantValIndex() in the argument.
  ### Reference: 

  my $c1 = shift;
  my ($ifirst, $ilast, @arsig);

  # Array of significant indices
  if (defined $_[2]) {
    my $r = $_[2];
    @arsig = @$r;
  } else {
    @arsig = Coords->arraySignificantValIndex($c1);
  }

  # First
  if (defined $_[0]) {
    if ($_[0] < 0) {
	$ifirst = Coords->firstSignificantValIndex($c1, \@arsig);
    } else {
	$ifirst = $_[0];
    }
  } else {
	$ifirst = 0;
  }

  # Last
  if (defined $_[1]) {
    if ($_[1] < 0) {
	$ilast = Coords->lastSignificantValIndex($c1, \@arsig);
    } else {
	$ilast = $_[1];
    }
  } else {
	$ilast = $#arsig;
  }

  return($ifirst, $ilast, @arsig);
}


sub DESTROY {	# Called upon the garbage collection of objects.
}


1;


### TESTS
