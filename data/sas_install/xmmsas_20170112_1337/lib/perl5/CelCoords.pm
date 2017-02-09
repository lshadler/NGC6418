package CelCoords;

# Author: Masaaki Sakano - SSC/LUX

our $VERSION = '4.21';
use strict;
use Exporter 'import';
# our @EXPORT    = qw(CelCoords angulardistance to_s);		# symbols to export in default
# our @EXPORT_OK = qw();	# symbols to export on request

use strict;
use Coords;
use Math::Trig;	# pi, acos, rad2deg, deg2rad...
use POSIX qw(fmod);	# fmod: Float MODulo.
use Data::Dumper;
use SSCLib qw(isnumber hashmerge sscnote sscwarn);

our $Taskname = 'CelCoords';

=head1 NAME

CelCoords - Class for Celestial-Coordinates objects.

=head1 SYNOPSIS

    use CelCoords;

=head1 DESCRIPTION

Class for the celestial coordinates.
This is a subclass of Coords class.
Many methods are defined in Coords class.
The method to_s is overwritten.

=item new ( ARGUMENTS )

Input is either a hash in the form of ("x%val"=>123.45, "y%val"=>-67.8, "x%unit"=>"deg", "y%unit"=>"deg", "all%sys"=>"FK5", "all%epoch"=>2000.0)
or an array with 4 components (x[deg], y[deg], COORDSYS, EPOCH), such as, (123.45, -67.8, "FK5", 2000.0), in which case all must be there in this order.
The hash key parameters can include "allarg" and "arrayhash".
See the reference of Coords.pm for detail --- the interface is the same,
except the aliases of "sys" and "epoch" (for "all%sys" and "all%epoch", respectively)
are defined for the input in this class (nb., they nevertheless are
stored with the key "all%..." in the object as usual).
Note all%type=="spherical-celestial" is automatically assigned in default unless otherwise explicitly given by the user.

=item angulardistance ( ARGUMENT )

If this is called as Class method, the arguments are either (CelCoords1, CelCoords2) or (RA1, DEC1, RA2, DEC2) [degree].
  my ($angle) = &CelCoords::angulardistance($c1, $c2);
  my ($angle) = &CelCoords::angulardistance($ra1, $dec1, $ra2, $dec2);
If this is called as normal method, the argument is (CelCoords2).
  my ($angle) = $c1->angulardistance($c2);
Returns the angular distance between the two CelCoords objects
in unit the same as that of the X-axis of the first object ($c1->{axis}->[0]->{x}).
So far, only the valid units are degree and radian.
If something is wrong, returns a negative value (-1).


=item distance ( ARGUMENT )

Alias for angulardistance().


=item to_s ( )

Returns the string of the instance (to print).

=cut
  ;	# For Emacs


############################################################

our @ISA = qw(Coords);	# Inheritance

#---------------------------------------------------------------------
sub new {
#---------------------------------------------------------------------
  ### Input: ("x%val"=>123.45, "y%val"=>-67.8, "x%unit"=>"deg", "y%unit"=>"deg", "sys"=>"FK5", "epoch"=>2000.0)
  ###    or  (123.45, -67.8, "FK5", 2000.0) (All must be there in this order).
  ###   If the second form is chosen, the units have to be in degree.
  ### Return: (Instance of CelCoords class)
  ### Description: 
  ### Constraints:
  ### Global: 
  ### Usage example:

  my $class = shift;	# The first argument is CelCoords
  my @ararg = @_;

  # my $self = {};
  my($self);
  my(@ar, $s1, $s2);
  my(%h) = ('all%type'=>"spherical-celestial");

  ## Reading arguments
  if ( (4 == scalar(@ararg))
      && isnumber($ararg[0])	# isnumber in SSCLib
      && isnumber($ararg[1])
      && isnumber($ararg[3]) ) {	# Array input
    %h = ('x%val'     => $ararg[0],
	  'y%val'     => $ararg[1],
	  'all%sys'   => $ararg[2],
	  'all%epoch' => $ararg[3],
	  'x%unit' => 'deg',
	  'y%unit' => 'deg',
	  );

  } else {				# Hash input
    my %hsarg = @_;

    while (scalar(@ar=each(%hsarg)) > 0){
      if ($ar[0] =~ /^(allarg|arrayhash|(sub)?name)$/i) {
	$h{lc($&)} = $ar[1];
      } elsif ($ar[0] =~ /^(sys|epoch)$/) {
	## If another new top-level keyword is invented, then
	## the above "IF" condition should be modified as such.
	$h{'all%'.$&} = $ar[1];	# Special form for (sys|epoch)
      } elsif ($ar[0] =~ /^([\w_\-]+)%([\w_\-]+)$/) {
	$h{$ar[0]} = $ar[1];
      } else {
	$h{'all%'.$ar[0]} = $ar[1];
	&sscwarn("The arguments in new(@ararg) does not look right (Pair==($ar[0])($ar[1])).") if isnumber($ar[0]);	# isnumber in SSCLib
      }
    }
  }

  $self = Coords->new(%h);
  # $self = {};
  bless $self, $class;	# Inheritance is applied (with this 2-arguments bless), if there is any.
  # $self->_initialize(@ararg);
  return $self;
}


#---------------------------------------------------------------------
sub distance {
#---------------------------------------------------------------------
  ### Alias for angulardistance(),
  ### to be used in isNearlyEqual() in the base class, Coords.

  return(angulardistance(@_));
}


#---------------------------------------------------------------------
sub angulardistance {
#---------------------------------------------------------------------
  ### Input: (CelCoords1, CelCoords2) or
  ###      : (RA1, DEC1, RA2, DEC2) [degree] if called as Class method.
  ###      : (CelCoords2)                    if called as normal method.
  ### Return: Angular distance between two CelCoords objects
  ###   in unit the same as that of the X-axis of the first object ($c1->{axis}->[0]->{x}).
  ###   So far, only the valid units are degree and radian.
  ###   If something is wrong, returns a negative value (-1).
  ### Description: 

  my $self=shift;
  my $halfPI = pi/2;	# pi defined Math::Trig
  my $RETWRONG = -1;

  my $cosinegamma;
  my $isdeg = 0;	# False

  if (ref($self)) {	# Normal method.
    return( ref($self)->angulardistance($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my($alpha1,$delta1, $alpha2,$delta2);	# in radian.
    my $retangle;

    if ((scalar(@_) == 4) &&
	(isnumber(@_)) ) {	# isnumber in SSCLib
      $isdeg = 1;	# True in default.
      $alpha1 = &deg2rad($_[0]);	# &deg2rad() in Math::Trig
      $delta1 = &deg2rad($_[1]);
      $alpha2 = &deg2rad($_[2]);	# -2pi < alpha < 2pi, guaranteed.
      $delta2 = &deg2rad($_[3]);

      $alpha1 += 2*pi if $alpha1 < 0;			# pi in Math::Trig
      $alpha2 += 2*pi if $alpha2 < 0;

    } else {

      my $c1=shift;
      my $c2=shift;

      $isdeg = 1 if ($c1->{axis}->[0]->{unit} && ($c1->{axis}->[0]->{unit} =~ /^(arc)?deg(ree)?/i));

      if ( (($c1->{all}->{sys} && $c2->{all}->{sys}) && 
	    ($c1->{all}->{sys} ne $c2->{all}->{sys}))
        || ((defined($c1->{all}->{epoch}) && defined($c2->{all}->{epoch})) &&
            ($c1->{all}->{epoch} ne $c2->{all}->{epoch}) ) ) {
        return($RETWRONG);
      }

      if ( defined($c1->{axis}->[0]) &&
	   defined($c1->{axis}->[1]) &&
	   defined($c2->{axis}->[0]) &&
	   defined($c2->{axis}->[1]) ) {
	$alpha1 = CelCoords->get_longitude_radian_positive($c1->{axis}->[0]);
	$delta1 = CelCoords->get_latitude_radian($c1->{axis}->[1]);
	$alpha2 = CelCoords->get_longitude_radian_positive($c2->{axis}->[0]);
	$delta2 = CelCoords->get_latitude_radian($c2->{axis}->[1]);
      } else {
	return undef;
      } 
    }

    $cosinegamma = cos($halfPI-$delta1) * cos($halfPI-$delta2)
                 + sin($halfPI-$delta1) * sin($halfPI-$delta2) * cos($alpha1-$alpha2);
    # http://www.krysstal.com/sphertrig.html
    # http://spiff.rit.edu/classes/phys440/lectures/coords/coords.html

    $retangle = &acos($cosinegamma);	# in Math::Trig
    # $retangle = atan2(sqrt(1-$cosinegamma**2), abs($cosinegamma));

    if ($isdeg) {
      return( &rad2deg($retangle) );
    } else {
      return( $retangle );
    }
  }

}


#---------------------------------------------------------------------
sub get_longitude_radian_positive {
#---------------------------------------------------------------------
  ### Input: (longitude, [unit(Def:deg)])
  ###     or ($coord->{axis}->[0])	# Must have ->{val, unit}.
  ### Return: Modulo of the longitude (0<=RA<360[deg]) in radian.
  ### Description: Class method, but can be used as normal method.

  my $self=shift;	# Ignore
  my $alpha = shift;	# Longitude
  my $unit = "deg";	# Default
  $unit = shift if (scalar(@_) > 0);

  if ((ref $alpha) and (defined $alpha->{val})) {
    if ((defined $alpha->{unit}) and ($alpha->{unit} ne "")){
      $unit = $alpha->{unit};
    }
    $alpha = $alpha->{val};
  }

  if (     $unit =~ /^(arc)?deg(ree)?/i) {
    $alpha = &deg2rad($alpha);		# &deg2rad() in Math::Trig
  } elsif ($unit =~ /^rad(ian)?/i) {
    $alpha = &fmod($alpha, 360);	# &fmod() in POSIX
  } else {
    ## Do nothing (namely, passed as it is).
  }

  ## Convert the potential negative into positive.
  $alpha += 2*pi if ($alpha < 0);	# pi in Math::Trig

  return($alpha);
}

#---------------------------------------------------------------------
sub get_latitude_radian {
#---------------------------------------------------------------------
  ### Input: (latitude, [unit(Def:deg)])
  ###     or ($coord->{axis}->[1]})	# Must have ->{val, unit}.
  ### Return: The latitude in radian.
  ### Constraint: The input has to be in the range of -90<=delta<=90 [deg].
  ### Description: Class method, but can be used as normal method.

  my $self=shift;	# Ignore
  my $delta = shift;	# Latitude
  my $unit = "deg";	# Default
  $unit = shift if (scalar(@_) > 0);

  if ((ref $delta) and (defined $delta->{val})) {
    if ((defined $delta->{unit}) and ($delta->{unit} ne "")){
      $unit = $delta->{unit};
    }
    $delta = $delta->{val};
  }

  if (     $unit =~ /^(arc)?deg(ree)?/i) {
    $delta = &deg2rad($delta);		# &deg2rad() in Math::Trig
  } elsif ($unit =~ /^rad(ian)?/i) {
    # Do nothing.
  }

  return($delta);
}


#---------------------------------------------------------------------
sub to_s {
#---------------------------------------------------------------------
  ### Input: (['indent'=>"", 'withname'=>1(Default)])
  ### Return: String expression of the instance (to print).
  ### Description: 
  ###   If the optional indent, such as, "| " is given, it is added
  ###  to the head of each line.
  ###   Overwriting "to_s" method in the base class, Coords.

  my $self = shift;
  my %arghashpartdef = ('indent' => "", 'withname' => 1);
  my %hsarg = @_;
     %hsarg = hashmerge(\%hsarg, \%arghashpartdef);	# in SSCLib

  my $indent = ($hsarg{'indent'} || "");

  my(@arunit, $i, $s, $strundef, $fmt);
  $strundef = sprintf("%11s", 'UNDEFINED');
  my(%hsnum) =
    ('val'  => [$strundef, $strundef],
     'CDELT'=> [$strundef, $strundef],
     'CROTA'=> [$strundef, $strundef], );
  my(%hssysepoch) = ('sys'=>'UNDEFINED', 'epoch'=>'UNDEFINED');
  my(%hssysepochfmt) = ('epoch'=>'%f');

  my(%flaghsnum) = ();
  foreach $s (keys(%hsnum)) {
    $flaghsnum{$s} = 0;	# Flag whether the key is defined or not.
  }

  foreach $i (0..1) {
    $arunit[$i] = 'UNDEFINED';
    if ((ref($self->{axis}) eq 'ARRAY') && ($#{$self->{axis}} >= $i)) {
      if ( ref($self->{axis}->[$i]) eq 'HASH' )  {
	foreach $s (keys(%hsnum)) {
	  if ( defined($self->{axis}->[$i]{$s}) ) {
	    #(exists( $self->{axis}->[$i]{val})) &&	# Unnecessary
	    $flaghsnum{$s} = 1;	# The keyword is defined in at least 1 axis.
	    if ($s eq 'val') {
	      $hsnum{$s}[$i] = sprintf("%11.6f", $self->{axis}->[$i]->{$s});
	    } else {
	      $hsnum{$s}[$i] = sprintf("%e",     $self->{axis}->[$i]->{$s});
	    }
	  }
	}

	if ( defined($self->{axis}->[$i]{unit}) ) {
	  $arunit[$i] = $self->{axis}->[$i]->{unit};
	}
      }
    }
  }	# foreach $i (0..1)

  foreach $s (keys(%hssysepoch)) {
    if (defined($self->{all}->{$s})) {
      $fmt = ($hssysepochfmt{$s} || '%s');
      $hssysepoch{$s} = sprintf($fmt, $self->{all}->{$s});
    }
  }

  my ($retstr) = "";
  ### 1st line
  $retstr = sprintf("NAME (SUB): %s (%s)\n"
		    , ($self->{name}    ? $self->{name}    : "NONE")
		    , ($self->{subname} ? $self->{subname} : "NONE")
		    ) if ($hsarg{'withname'});

  ### 2nd line
  #return sprintf("(%11.6f, %11.6f) [%s, %s: (%s, epoch=%s)]"
  $retstr .= sprintf("(%s, %s) [%s, %s] (%s, epoch=%s)"
		     , $hsnum{'val'}[0], $hsnum{'val'}[1], $arunit[0], $arunit[1]
		     # , $arval[0], $arval[1], $arunit[0], $arunit[1]
		     , $hssysepoch{'sys'}, $hssysepoch{'epoch'} 
		     );
  foreach $s (qw(CDELT CROTA)) {
    if ($flaghsnum{$s}) {
      $retstr .= sprintf(" %s=(%s, %s)", $s, $hsnum{$s}[0], $hsnum{$s}[1]);
    }
  }

  $retstr .= "\n";

  ### 3rd line
  ## Common things
  foreach $i (keys(%{$self->{all}})) {
    next if ($i =~ /^(sys|epoch)$/);
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



sub DESTROY {	# Called upon the garbage collection of objects.
}


1;

