# Author: Masaaki Sakano - SSC/LUX

our $VERSION  = '4.19.0';
our $Taskname = 'PairCoordsSys';

=head1 NAME

PairCoordsSys - Class representing a pair of celestial and pixel coordinate systems.

=head1 SYNOPSIS

    use PairCoordsSys;
    use PairCoordsSys qw(cel pix);

=head1 DESCRIPTION

A pair of coordinates that are related to each other sometimes 
appear.  Notably in astronomical FITS (image) files,
the data are stored in multi-dimensional arrays, which are represented
as the pixel coordinates, and they are the representation
of the data in the celestial coordinates.

This class represents such a pair of celestial and pixel coordinate systems.
In practice this class simply holds a CelCoords and a Coords objects,
as well as some additional data.
Ideally it should hold and handle the data transform matrix.
At the moment, however, this class does not provide
any definite interface to handle those,
although it can hold those information,
as are in any other Perl objects,
by setting and accessing/changing a corresponding hash-key and element
by users as they like.

This class is used extensively from MultipleCoordsSys class
(defined in the fitsutils package).
When MultipleCoordsSys class creates PairCoordsSys objects,
(1) it sets CRVAL, CDELT, CTYPE and CROTA information, if there is any,
under the {all} key in the CelCoords part in a PairCoordsSys, and
(2) it sets CRPIX information in the Coords part.

=item new ( HASH )

The hash must include either or both of
'cel'=>CelCoords_object or 'pix'=>Coords_object
at least.  Optionally it can include 'system'=>'physical' etc.

=item cel ( )

Returns the CelCoords object the self holds.

=item pix ( )

Returns the Coords object the self holds.

=item isNil ( )

Returns 1 if the object is practically nil, 0 otherwise.
Defined as both Class and normal methods.

=item isNearlyEqual ([p1], c2, [precision, [maximum_difference, [options,...]]])

Returns 1 if the objects are nearly equal in the given condition.
p1 must be a PairCoordsSys object, but c2 can be a (Cel)Coords object.
Note if you want to apply this function with c2 of MultipleCoordsSys,
you must do c2->isNearlyEqual(p1). 
See SSCLib.pm for detail.
Defined as both Class and normal methods.

=item singleCoords ([p1], [options,...])

Returns a single Coords (CelCoords) object,
or 0 if more than one objects are found to satisfy the conditions,
or undef if no object is found to satisfy the conditions.
Defined as both Class and normal methods.

=item merge ([p1], c2, [options,...])

Merge a PairCoordsSys or (Cel)Coords object,
Options 'from' and 'to' are either an axis number
or string "auto", in which case the merged axes
are automatically chosen, if possible.
Returns the self.
Defined as both Class and normal methods.

=item deepcopy ( )

Returns deep-copied self.  See DeepCopy module.

=item to_s ( )

Returns a simple string expression of the self.

=item rollangle ( )

NOT YET IMPLEMENTED.
Returns the roll angle at the reference point, if defined, else undef.
If a single roll-angle (CROTA2 in the WCS keyword) is defined, 
a single number is returned.
If more than one roll-angle are defined,
the reference to a 1-dim array, of which each component is a roll-angle
for that axis, is returned.
If transformation matrix is defined, the reference to the multi-dimensional
array is returned.

=cut

;    # For Emacs

#######################################################################

package PairCoordsSys;

use strict;
use Exporter 'import';

# our @EXPORT    = qw(getattribute);		# symbols to export in default
our @EXPORT_OK = qw();    # symbols to export on request

use Data::Dumper;
use SSCLib qw(uniq hashmerge isnumber sscwarn);

# use SSCLib qw(sscnote);
use DeepCopy;             # in ssclib
use Coords;               # in ssclib
use CelCoords;            # in ssclib

#### Description #####
##
## This class just represents a pair of coordinate systems,
## a CelCoords object (celestial coordinates (alpha, delta))
## and its corresponding pixel coordinates, a Coords object.
##
## If the input CelCoords and/or Coords object does not have
## any axis value, then it is superceded with undef.
##
## To access:
##  p->{cel}	: a CelCoords object
##  p->{pix}	: a Coords    object
##
## To (deep-)copy:
##  p2 = p1->deepcopy;
##
## To print the contents:
##  print p1->to_s;
##

#---------------------------------------------------------------------
sub new {

	#---------------------------------------------------------------------
	### Input:  ('cel'=>CelCoords_object, 'pix'=>Coords_object, 'system'=>'physical', ...)
	### Return: ($self)
	### Description:
	### Constraints:
	### Global:
	### Usage example:

	my $class = shift;    # The first argument is this Class
	my @ararg = @_;
	my %hsarg = @_;
	my $self  = {};
	bless $self, $class
	  ; # Inheritance is applied (with this 2-arguments bless), if there is any.
	$self->_initialize(@ararg);
	return $self;

}

#---------------------------------------------------------------------
sub _initialize {

	#---------------------------------------------------------------------
	### Input:  ('cel'=>CelCoords_object, 'pix'=>Coords_object, 'system'=>'physical', ...)
	### Return: ($self)
	### Description:
	###   $self->{cel} == a CelCoords object
	###   $self->{pix} == a Coords    object
	### References:

	my $self  = shift;    # The first argument is always SELF.
	my %hsarg = @_;
	my ( @ar, $s );

	while ( scalar( @ar = each(%hsarg) ) > 0 )
	{                     # For (cel|pix|ext|sysname|coordver|col)
		$self->{ $ar[0] } = $ar[1];
	}

	foreach $s (qw(cel pix)) {
		if ( &_isCoordsNil( $self->{$s} ) ) {
			$self->{$s} = undef;
		}
	}

	$self;
}

#---------------------------------------------------------------------
sub _isCoordsNil {

	#---------------------------------------------------------------------
	### Input:  ((Cel)Coords object)
	### Return: (1 if the input (Cel)Coords is practically nil, 0 otherwise)
	### Description:
	###  This is a NORMAL function!
	###   Check the axis in the input (Cel)Coords object.
	###   NOTE: if anything but (Cel)Coords object is passed as the argument,
	###   an error is raised, such as,
	###     Can't use string ("dummy") as a HASH ref while "strict refs" in use at /.../FitsCelCoordsSys.pm line xxxx.
	### References:

	my ($obj) = shift;    # (Cel)Coords object
	my ($eachh);

	if ( $obj->{axis} ) {
		foreach $eachh ( @{ $obj->{axis} } ) {
			if ($eachh) {
				next if ( !exists( $$eachh{'val'} ) );
				return 0
				  if ( defined( $eachh->{'val'} ) )
				  ;       # A value exists at least in one axis.
			}
			else {
				next; # The hash for the current index in 'axis' is not defined.
			}
		}
	}
	else {
		return 1;     # 'axis' is not defined first of all.
	}

	return 1;

}

#---------------------------------------------------------------------
sub isNil {           # for PairCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (PairCoordsSys object)
	### Input(Normal method): ()
	### Return: (1 if the object is practically nil, 0 otherwise)
	### Description: Practically calling isNil() method in lower classes.
	### References:

	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->isNil( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.

		my $c1 = shift;
		foreach (qw(cel pix))
		{ # Here I am not using  keys(%{$self})  so that it leaves a potential to add further components in the future.
			return 0 if ( !&SSCLib::isNil( $c1->{$_} ) );
		}
		return 1;
	}
}

#---------------------------------------------------------------------
sub cel {

	#---------------------------------------------------------------------
	### Input: NONE
	### Return: CelCoords object
	### Description: Returns the CelCoords object in the pair.
	### References:

	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		$self->{cel};

	}
	else {                 # Class method.
		die "cel in PairCoordsSys is not a class method!";
	}
}

#---------------------------------------------------------------------
sub pix {

	#---------------------------------------------------------------------
	### Input: NONE
	### Return: Coords object
	### Description: Returns the Coords object (for pixel coords.) in the pair.
	### References:

	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		$self->{pix};

	}
	else {                 # Class method.
		die "pix in PairCoordsSys is not a class method!";
	}
}

#---------------------------------------------------------------------
sub isNearlyEqual {        # for PairCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (p1, c2, [precision, [maximum_difference, [options,...]]])
	### Input(Normal method):    (c2, [precision, [maximum_difference, [options,...]]])
	### Return: 1 if yes, or 0 otherwise.
	### Description: Compare two PairCoordsSys objects
	###   and return true if they agree in the given precision or given maximum_difference.
	###   p1 must be a PairCoordsSys object, but c2 can be a (Cel)Coords object.
	### Reference: See SSCLib::isNearlyEqual for detail.

	my ($subname) = "isNearlyEqual";
	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->isNearlyEqual( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $p1      = shift;
		my $c2      = shift;
		my @argrest = @_;

		if ( ( !$c2->can('cel') ) || ( !$c2->can('pix') ) )
		{                  # c2 is NOT PairCoordsSys
			if ( $p1->{cel} && $p1->{pix} ) {
				return
				  0
				  ; # p1 has both cel and pix, whereas c2 is a (Cel)Coords or something.
			}
			elsif ( $p1->{cel} || $p1->{pix} ) {
				if ( $p1->{cel} ) {
					$p1->{cel}->isNearlyEqual( $c2, @argrest );    # CelCoords
				}
				else {
					$p1->{pix}->isNearlyEqual( $c2, @argrest );    # Coords
				}
			}
			else {
				&SSCLib::sscwarn(
					"p1 does not look PairCoordsSys in isNearlyEqual");
				return 0;                                          # Strange.
			}
		}
		else {    # c2 is PairCoordsSys
			my $eachk;
			
			if (   ( $p1->{cel} xor $c2->{cel} )
				|| ( $p1->{pix} xor $c2->{pix} ) )
			{
				&SSCLib::sscwarn(
"pix or cel is defined inconsistently in PairCoordsSys->isNearlyEqual(), hence not equal."
				);
				return 0;
			}
			foreach $eachk (qw(cel pix)) {
				if ( !( $p1->{$eachk} || $c2->{$eachk} ) ) {
					return 1;    # Both undef
				}
				elsif ( $p1->{$eachk} && $c2->{$eachk} ) {
					return 0
					  if (
						!$p1->{$eachk}->isNearlyEqual( $c2->{$eachk}, @argrest )
					  );
				}
				else {           # Either undef
					return 0;
				}
			}

			return
			  1;    # None of them is inconsistent, hence they are Nearly-Equal!
		}
	}    #  if (ref($self))
}    # sub isNearlyEqual

#---------------------------------------------------------------------
sub singleCoords {    # for PairCoordsSys

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
	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->singleCoords( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;

		if ( $c1->{cel} && $c1->{pix} ) {
			return 0;
		}
		elsif ( $c1->{cel} && !$c1->{pix} ) {
			return $c1->{cel};
		}
		elsif ( !$c1->{cel} && $c1->{pix} ) {
			return $c1->{pix};
		}
		else {
			return undef;    # equivalent to isNil()
		}
	}
}    # sub singleCoords

#---------------------------------------------------------------------
sub merge {    # for PairCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): ([p1], c2, [Optional-Hash])
	### Input(Normal method):(c2, [Optional-Hash])
	### Return: self or undef if something goes wrong.
	### Description:
	###   Merge a set of parameters for one axis into another PairCoordsSys obj.
	###   Both Celestial and Pixel parts are merged if exists.
	###   Optional hash 'from' and 'to' are either an axis number
	###  or string "auto", in which case the merged axes
	###  are automatically chosen, if possible.
	###   Note the self does NOT change.
	### Reference:

	my ($subname) = "merge";
	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->merge( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $p     = shift;
		my $p1    = $p->deepcopy;    # to change and return.
		my $c2    = shift;
		my %hsarg = @_;

		my (@arkey);
		my ( $i, $ifromto, $fromto, $celpix, $eachk );

		my %coordobj = ( 'cel' => undef, 'pix' => undef );

		my (%hsiaxis);               # Axis numbers for 'from' and 'to'
		foreach (qw(from to)) {
			if ( defined( $hsarg{$_} ) ) {
				if ( isnumber( $hsarg{$_} ) ) {    # in SSCLib
					$hsiaxis{$_} = $hsarg{$_};
				}
				elsif ( $hsarg{$_} eq 'auto' ) {
					$hsiaxis{$_} = $hsarg{$_};
				}
				else {
					print Dumper \%hsarg;
					die "Argument($_) for PairCoordsSys::merge is invalid.";
				}
			}
			else {
				$hsiaxis{$_} = 'auto';
			}
		}

		# Which or both of 'cel' and 'pix' is merged?
		if ( $c2->can('cel') && $c2->can('pix') ) {
			if ( !$c2->cel->isNil ) {
				$coordobj{'cel'} = { 'from' => $c2->cel, 'to' => $p1->cel };
			}
			if ( !$c2->pix->isNil ) {
				$coordobj{'pix'} = { 'from' => $c2->pix, 'to' => $p1->pix };
			}
		}
		elsif ( $c2->can('angulardistance') ) {
			$coordobj{'cel'} = { 'from' => $c2, 'to' => $p1->cel };
		}
		else {
			$coordobj{'pix'} = { 'from' => $c2, 'to' => $p1->pix };
		}

		###### MAIN ######

		foreach $celpix (qw(cel pix)) {
			if ( $coordobj{$celpix} ) {    # Whether process it?
				foreach $fromto (qw(from to)) {

					# Determine the indices to process if needed.
					if ( $hsiaxis{$fromto} eq 'auto' ) {
						$ifromto = undef;
						foreach $i (
							0 .. $#{ $coordobj{$celpix}->{$fromto}->{axis} } )
						{
							## Get the sole index to process.
							if (
								exists(
									$coordobj{$celpix}->{$fromto}->{axis}->[$i]
									  ->{val}
								)
								&& defined(
									$coordobj{$celpix}->{$fromto}->{axis}->[$i]
									  ->{val}
								)
							  )
							{
								if ( $fromto eq 'from' ) {
									if ( defined $ifromto ) {
										&sscwarn(
"More than one significant parameter are found in $fromto in $celpix for auto option in PairCoordsSys::merge()."
										);
										return undef;
									}
									else {
										$ifromto = $i
										  ; # Copy from a sole significant value.
									}
								}
							}
							else {
								if ( $fromto eq 'to' ) {
									if ( defined $ifromto ) {
										&sscwarn(
"More than one significant parameter are found in $fromto in $celpix for auto option in PairCoordsSys::merge()."
										);
										return undef;
									}
									else {
										$ifromto = $i
										  ; # Copy to a sole insignificant value.
									}
								}
							}
						}    #   foreach $i (0..$#{$coordobj{$celpix}->{axis}})

						#print "DEBUG:ifromto($fromto)=($ifromto)\n";
						if ( !defined $ifromto ) {
							&sscwarn(
"No significant parameter is found in $fromto in $celpix for auto option in PairCoordsSys::merge()."
							);
							return undef;
						}

						$hsiaxis{$fromto} = $ifromto;
					}    #  if ($hsiaxis{$fromto} eq 'auto')
				}    # foreach $fromto qw(from to)

				## Making the list of all the keywords to process.
				@arkey = (
					keys(
						%{
							$coordobj{$celpix}->{'to'}->{axis}
							  ->[ $hsiaxis{'to'} ]
						  }
					),    # It is actually $p1
					keys(
						%{
							$coordobj{$celpix}->{'from'}->{axis}
							  ->[ $hsiaxis{'from'} ]
						  }
					)
				);
				@arkey = uniq(@arkey);    # in SSCLib

				## Merge the parameters
				foreach $eachk (@arkey) {

			   # Overwrite everything for the axis, deleting keywords if needed.
					if (
						exists(
							$coordobj{$celpix}->{'from'}->{axis}
							  ->[ $hsiaxis{'from'} ]
						)
					  )
					{
						$p1->{$celpix}->{axis}->[ $hsiaxis{'to'} ] =
						  $coordobj{$celpix}->{'from'}->{axis}
						  ->[ $hsiaxis{'from'} ];
					}
					else {

	   # elsif (exists(  $p{$celpix}->{axis}->[$hsiaxis{'to'}]))	# Same meaning!
						delete( $p1->{$celpix}->{axis}->[ $hsiaxis{'to'} ] );
					}
				}    #   foreach $eachk (@arkey)
			}    #  if ($coordobj{$celpix})
		}    # foreach $celpix qw(cel pix)

		return ($p1);
	}    #  if (ref($self))

}    # sub merge

#---------------------------------------------------------------------
sub to_s {    # for PairCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method):  (p1, ['indent'=>"", 'withname'=>0(Default)])
	### Input(Normal method): (['indent'=>"", 'withname'=>0(Default)])
	### Return: String expression.
	### Description:
	###   If the optional indent, such as, "| " is given, it is added
	###  to the head of each line.
	### Reference:

	my ($subname) = "to_s";
	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->to_s( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $p1      = shift;
		my %hsarg   = @_;
		my %hsdef   = ( 'withname' => 0 );
		my %hs2pass = ( 'indent' => " " );
		%hs2pass = hashmerge( \%hs2pass, \%hsarg );    # in SSCLib
		%hs2pass = hashmerge( \%hs2pass, \%hsdef );    # in SSCLib
		      # For the hash to pass to Coords and CelCoords,
		      # 'indent' is always " ".
		      # 'withname' is inherited from the argument, but in default 0.

		my $indent = ( $hsarg{'indent'} || "" );

		# my $indentregexp = quotemeta($indent);

		my ($s);

		my %strpair = ();
		foreach (qw(cel pix)) {
			if ( $p1->{$_} ) {
				$strpair{$_} = $p1->{$_}->to_s(%hs2pass);
			}
			else {
				$strpair{$_} = '';
			}
		}

		my $retstr;

		$s = $strpair{'cel'};
		if ($s) {
			$retstr = "=== Celestial ===\n";
			$retstr .= $s;
			chomp($retstr);
			$retstr .= "\n";
		}
		else {
			$retstr .= "=== Celestial: NONE\n";
		}

		$s = $strpair{'pix'};
		if ($s) {
			$retstr .= "=== Pixel ===\n";
			$retstr .= $s;
			chomp($retstr);
			$retstr .= "\n";
		}
		else {
			$retstr .= "=== Pixel: NONE\n";
		}

		$retstr =~ s/^/$indent/gm;    # Add an indent, if needed.
		return $retstr;
	}
}    # sub to_s	# for PairCoordsSys

1;
