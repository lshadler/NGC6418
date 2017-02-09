# Author: Masaaki Sakano - SSC/LUX

our $VERSION  = '1.3.0';
our $Taskname = 'FitsCelCoordsSys';

=head1 NAME

FitsCelCoordsSys - Class representing the celestial coordinate system in a FITS file.

=head1 SYNOPSIS

    use FitsCelCoordsSys;
    use FitsCelCoordsSys qw();

=head1 DESCRIPTION

A FITS file can hold the coordinate information in the form of
the header attributes, which defines where and in which direction
and in which scale the data contents,
perhaps images, are actually located in the celestial space.
If it is an image, then it needs to define the reference point
in the data array for both celestial coordinates and local ones
(that is, the pair of indices of the 2-dimension array),
the rolling angle and increments between those two coordinate systems,
and the projection method used.  Note that more than one pair of
the local coordinates may exist, such as image and physical.

A single FITS file can consist of multiple extensions,
each of which may contain different coordinate information.
In addition further coordinate-related information, such as
the coordinates of an object, may appear.

This class is designed to represent all those coordinate-related
information described in the FITS header attribultes.
An instance of this class contains an array of MultipleCoordsSys
objects, each of which contains PairCoordsSys objects
(defined in ssclib/), each of which contains CelCoords and/or Coords
objects in it.  Also it holds some data specific to this class.


One way is to get (or refer to) a CelCoords ($c) object
in FitsCelCoordsSys ($f) is, for example, in the case of
(RA_NOM, DEC_NOM) in the primary header,

  $c = $f->{ext}->[0]->{nominal}->{def}->{col}->[0]->{cel};
  $c = $f->aryMcs('sys'=>"nominal", 'ext'=>0)->[0]->{col}->[0]->{cel};
  $c = $f->singlePcs('sys'=>"nominal", 'ext'=>0)->{cel};
  $c = $f->singleCoords('sys'=>"nominal", 'ext'=>0);

These work as follows.
In the first example, the most primitive one,
the first array index, 0, is the (FITS) extention number,
followed by the system name 'nominal',
followed by the coordinate-version name 'def'.
So, $f->{ext}->[0]->{nominal}->{def} gives 
the MultipleCoordsSys object ($mcs) you want (which contains
the CelCoords object in).

In the second example, 
$f->aryMcs('sys'=>"nominal", 'ext'=>0) returns an array of 
MultipleCoordsSys objects that satisfies the given condition
("nominal" in primary (ext=0) header), if there is any.
In this case the first element [0] is the MultipleCoordsSys object ($mcs)
you want (n.b., in this case of the given condition, it is guaranteed that
there is no more than 1 element, because it is a primary header).

Now, $mcs->{col} gives an array of PairCoordsSys objects
each for a given column number (n) as the index.
In this case, n=0 is what you want, for the primary header
does not include any significant columns.  Let us call it $pcs.

In the third example, $pcs is directly derived.
This works ONLY when there is only one PairCoordsSys object
that satisfies the condition.  In this case, it should be,
because the system name is "nominal".

Now, a PairCoordsSys object may have two Coordinate systems,
a Coords and a CelCoords objects.  In this case,
"nominal" coordinate is the celestial coordinate,
therefore $pcs->{cel} refers to the CelCoords object you want.

Alternatively of all, as in the fourth example,
the CelCoords object may be directly derived.
Again this works ONLY when there is only one Coords
(or CelCoordds) object.  In this case, it should,
however for the other common cases, such as,
system name of "image" it would not, because
the corresponding PairCoordsSys object holds both CelCoords 
(represented with the FITS header keyword of CRVAL) and
Coords (represented with CRPIX) objects.


=item new ( A.FITS[+n], [Hash] )

Create the FitsCelCoordsSys object from an input FITS file.
The required extention number (n) can be added, following '+'.
If it is a string '-', STDIN, which should be an output from fdump (in FTOOLS)
of a FITS file, will be read instead.

=item aryMcs ( [c1], [Optional-Hash] )

Returns a 1-dim array of MultipleCoordsSys (MCS) objects,
which satisfies the given condition.

The order of the MCSs in the returning array is
(1) by extention,
(2) sys: image, physical, pixellist, then alphabetical,
(3) coordinate-version: def, then alphabetical.
Note it is irrelevant of the order of the given array
(if an array is specified in the given Optional-Hash).

The argument hash key may include 'index',
of which the element is $c1->arrayAllSignificantMcsIndex();
For the other keys, see the description in _getMcsIndex2Use().

Defined as both Class and normal methods.

=item singleCoords ([f1], [options,...])

Returns a single Coords (CelCoords) object,
or 0 if more than one objects are found to satisfy the conditions,
or undef if no object is found to satisfy the conditions.
Defined as both Class and normal methods.

=item singlePcs  ([f1], [options,...])

Returns a single PairCoordsSys object,
or 0 if more than one objects are found to satisfy the conditions,
or undef if no object is found to satisfy the conditions.
Defined as both Class and normal methods.

=item arrayAllSignificantMcsIndex ( [f1] )

Returns an (0|1) array indicating all the significant indices
for {ext}->[?]->{?}->{?}: 1 for significant, else 0.
For example, the returned array @a may have an element,
$a[0]->{image}->{def} = 1.
If 'ext' is not defined first of all, null Array () is returned.
If an extention or its sub-component has no defined component,
then undef is set, eg.,

  $a[1] = undef
  $a[2]->{image} = undef

Defined as both Class and normal methods.

=item arraySignificantMcsIndex ( [f1], [Optional-Hash] )

The same as arrayAllSignificantMcsIndex(), but
this method accepts the condition-hash as the argument,
the same as aryMcs().
Note this method is called from aryMcs().

Defined as both Class and normal methods.

=item arraySignificantExtIndex ( [f1], [Optional-Hash] )

Returns a 1-dim Array indicating significant indices for {ext}->[?],
for example, (0, 1, 1, 0) means the 1st and 2nd extentions are significant.
If 'ext' is not defined first of all, null Array () is returned.
This method accepts the condition-hash as the argument, the same as aryMcs().

Defined as both Class and normal methods.

=item isNearlyEqual ( obj, [precision, [maximum_difference, [OPTION-Hash,...]]])

Returns 1 if the self and obj in the conditions given in OPTION-Hash
are the same, else 0.
Basically isNearlyEqual() is performed for all the 
MultipleCoordsSys objects that satisfies the given condition
among all those this instance contains, and if all pass, returns 1,
else 0.

OPTION-Hash may have keys of

   ( "ext" => Integer or undef or "auto",
     "coordsys" => (Array(qw(auto|physical|image|pixellist|nominal|object|pointing|...)) or undef),
     "coordversion" => (undef or (|auto|[A-Z])) )

in addition to other standard hash parameters to pass to 
MultipleCoordsSys->isNearlyEqual().
The object to compare can be a MultipleCoordsSys, PairCoordsSys
or Coords object.  If this instance contains only one of those,
the comparison is made, and judged as such, otherwise simply 0 is returned.

Defined as both class and normal methods.

=item minglePair ([c1], [Optional-Hash])

Returns a modified FitsCelCoordsSys object, or undef if something goes wrong.

This method makes up (modify) a PairCoordsSys the object contains
from two sets of PairCoordsSys in it, which are probably extracted from individual columns,

Optional-Hash includes both those for selection in FitsCelCoordsSys
(see the description in _getMcsIndex2Use()) and those passed
to MultipleCoordsSys->minglePair().

In default 'sys'=>'pixellist' is added, unless specified otherwise.
Here, 'sys'=>'auto' means the same.
See the description of MultipleCoordsSys->minglePair() for detail.

Note default 'auto' in this method (passed to MultipleCoordsSys->minglePair()) is not very clever so far.

=item deepcopy ( )

Returns deep-copied self.  Simply imported from DeepCopy module.

=item to_s ( )

Returns a simple string expression of the self.

=item _getMcsIndex2Use ( OptionalHash )

Internal normal function, though you can call this as 
&FitsCelCoordsSys::_getMcsIndex2Use() if you wish.

Returns The (undef|1) array of (Hashes of) index for MultipleCoordsSys (MCS) to use,
which satisfies the given condition.
The form of the returned array is the same as arrayAllSignificantMcsIndex().

The optional hash may include the following keys:

  'arrayAllSignificantMcsIndex' (mandatory): Reference to the returned Array of $c->arrayAllSignificantMcsIndex().
     This method is based on this (reference to) array.

  'ext' for extentions: (all|auto|\d+|\@array)
     'all' means every extention (Default),
     'auto' at the moment means the first one found,
     the reference to the desired array, such as, (0, 2, 3) for extentions (0, 2, 3) can be given,
     or a simple number of the extention.

  'sys' for system-names: (all|auto|\S+|\@array)
     "system-name" means (image|physical|pixellist|nominal|object|pointing|...).
     The same as 'ext'.

  'cver' for Coordinate-version: (all|auto|def|[A-Z]|\@array)
     "Coordinate-version" is a capital letter or "def"(ault).
     The same as 'ext'.


=cut

;    # For Emacs

#######################################################################

use strict;

package FitsCelCoordsSys;

use strict;
use Exporter 'import';

# our @EXPORT    = qw(getattribute fparkey tbl2arrays tbl2arraysingle are2tblsequal getfitsheadernumber iscolumnexisting sumup_images readFitsStatInfo);		# symbols to export in default
our @EXPORT_OK = qw();    # symbols to export on request
our $DEBUGGING;

use Data::Dumper;
use SSCLib qw(strip hashmerge sscnote sscwarn areScalarsEqual);
use Fitsplutils
  qw(getattribute fparkey tbl2arrays tbl2arraysingle are2tblsequal getfitsheadernumber iscolumnexisting sumup_images readFitsStatInfo getStringHeaderLine getPerlNumeric);
use DeepCopy;             # Module in ssclib
use Coords;               # in ssclib
use CelCoords;            # in ssclib
use PairCoordsSys;        # in ssclib
use WcsKey;               # Module
use MultipleCoordsSys;

############################################################

#---------------------------------------------------------------------
sub new {

	#---------------------------------------------------------------------
	### Input:  (FITS[+n], ['NAME'=>'my_own', ...])
	### Return: ($self)
	### Description:
	### Constraints:
	### Global:
	### Usage example:

	my $class = shift;    # The first argument is Coords
	my @ararg = @_;
	my $self  = {};
	bless $self, $class
	  ; # Inheritance is applied (with this 2-arguments bless), if there is any.
	$self->_initialize(@ararg);
	return $self;

}

#---------------------------------------------------------------------
sub _initialize {

	#---------------------------------------------------------------------
	### Input:  (FITS[+n], ['NAME'=>'my_own', ...])
	### Return: ($self)
	### Description:
	### References:
	###  See Table 8.2 (Section 8.2, pp.77) in FITS Standard Ver.3.0 (2008/07/10)

	my $self    = shift;    # The first argument is always SELF.
	my $infits  = shift;
	my %hsinkey = @_;

	my @Arstandardkey =
	  qw( CTYPE CUNIT CRVAL CDELT CRPIX CROTA CNAME CRDER CSYER );
	my @Armatrixkey = qw( PCall CDall PVall PSall );

	# my @artmpl    = qw( CRVL CTYP CRPX CDLT CUNI );
	# my @artmplref = (@artmpl, qw( LMIN LMAX DMIN DMAX ));
	my @artmplphysical = qw( LMIN LMAX DMIN DMAX );

# Other identifiers (in this class):
# qw ( EQUINOX RADECSYS LTV1 LTM1_1 LTV2 LTM2_2 LTM1_2 LTM2_1 WCSNAME_L WCSAXES_L )
# CRVL_L etc are also used to represent the alternative values, where CRVL already exists.

	my ( %hsattrkey, %hsattrval, %hsmcs );

   # %hsattrkey: Hash for all the possible Keywords of FITS attributes.
   #   eg., $hsattrkey{'physical'}{'all'}{'RADECSYS'} =='RADESYSa|RADECSYS'
   #        $hsattrkey{'physical'}{'axis'}[0]{'CRVAL'}=='TCRVLn|TCRVna'
   #        $hsattrkey{'physical'}{'axis'}[1]{'CRVAL'}=='REFYCRVL'
   # In the case of 'axis', if the size of the 'axis' array is 1,
   # then the subsequent [ijnmk] is treated to mean the order
   # of the coordinates.  It IS the ordinary case.
   # In some exceptional cases, such as 'physical' coordinates,
   # this principle can not be applied, therefore each component of
   # the 'axis' array has to be defined, and accordingly the size
   # of the array must be more than 1.
   #
   #  With this, the resultant value will be
   #    'def'{'RADECSYS'}   => 'FK5'
   #    'L'{'RADECSYS'}     => 'FK4'	# if 'RADESYSL' is found to be the key.
   #    'def'{'axis'}[0]{CRVAL} => 123.45
   #
   #
   #
   #   eg., $hsattrkey{'physical'}{'CRVL'}{(x|y)}=='REF?CRVL'
   #    which indicates, "CRVL value is found in the Header attribute 'REF?CRVL'
   #    where '?' works as glob and is either (x|y|z|[0-9])."
   # %hsattrval: Hash for all the values related to the coordinates.
   #   If a value does not exist in the FITS header,
   #   then the corresponding keyword (in %hsattrval) is undef.
	######eg., $hsattrval{'physical'}{'x'}{'CRVL'}==123.4567	# RA at CRPX
#   eg., $hsattrval{'physical'}{'CRVL'} = CelCoords->new	# RA/DEC at CRPX, CUNI, EQUINOX, RADECSYS are included here.
#        $hsattrval{'physical'}{'CRPX'} = Coords->new	# CRPX
#        $hsattrval{'physical'}{'CDLT'} = Coords->new	# CRPX
#        $hsattrval{'physical'}{'CTYP'}{(x|y)} = 'String'	# CTYP

	my ( $iWcskey, $coordsyskey );
	my ( $tmpkey, @ar, $i, $j, $k, $s, %h, $eachc, $eachk );
	my (@Arcoordsyskey) =
	  qw( image nominal object pixellist physical pointing );
	my (@Araxisallmisc) = qw( all axis matrix misc );

	foreach (@Arcoordsyskey) {
		$hsattrkey{$_} = {};
		$hsattrval{$_} = {};
		foreach $j (@Araxisallmisc) {
			%{ $hsattrkey{$_}{$j} } = ();
		}

		# @{$hsattrkey{$_}{"axis"}} = ();	# Axis array
		$hsattrkey{$_}{"axis"} = [];    # Axis array
	}

	############################################
	## physical
	############################################
	$coordsyskey = 'physical';
	$iWcskey     = $WcskeyIndex{'Bintable'};

	# %h =('CRVAL' => '?CRVL',
	#      'CTYPE' => '?CTYP',
	#      'CRPIX' => '?CRPX',
	#      'CDELT' => '?CDLT',
	#      'CUNIT' => '?CUNI',
	#      'CNAME' => '?CNA' ,
	#      'CRDER' => '?CRD' ,
	#      'CSYER' => '?CSY' ,
	#      );
	$i = -1;
	foreach $eachc (qw( X Y Z )) {
		$i++;

		foreach $eachk (@Arstandardkey) {
			$_ = $Wcskeys{$eachk}[$iWcskey];    # 'iCRVLn|iCRVna' etc.
			s/n.*$//;                           # => 'iCRVL' etc
			s/[ij]/REF$eachc/;                  # => 'REFXCRVL' etc.
			$hsattrkey{$coordsyskey}{'axis'}[$i]{$eachk} =
			  $_;    # eg., {'physical'}{'axis'}[0]{'CRVAL'} => 'REFXCRVL' etc.
		}

		foreach $eachk (@artmplphysical) {
			$hsattrkey{$coordsyskey}{'axis'}[$i]{$eachk} =
			  'REF' . $eachc . $eachk;    # REFXLMIN, REFYDMAX etc.
		}
	}
	%{ $hsattrkey{$coordsyskey}{'all'} } = (
		'RADECSYS' => 'RADECSYS',
		'EQUINOX'  => 'EQUINOX'
	);    # Duplication of the 'image' coordinates.
	      # $hsattrkey{'physical'} =
	      #  {'axis' => [{'CRVAL'=>'REFXCRVL', 'LMIN'=>'REFXLMIN',...},
	      #              {'CRVAL'=>'REFYCRVL', 'LMIN'=>'REFYLMIN',...},
	      #              {'CRVAL'=>'REFZCRVL', 'LMIN'=>'REFZLMIN',...}],
	      #   'all' => {'RADECSYS' => 'RADECSYS',
	      #             'EQUINOX'  => 'EQUINOX' }
	      #  };

	############################################
	## pixellist
	############################################
	$coordsyskey                        = 'pixellist';
	$iWcskey                            = $WcskeyIndex{'Pixel'};
	$hsattrkey{$coordsyskey}{'axis'}[0] = {};
	foreach $eachk (@Arstandardkey) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'axis'}[0]{$eachk} =
		  $s;   # eg., {'pixellist'}{'axis'}[0]{'CRVAL'} => 'TCRVLn|TCRVna' etc.
	}

	# Matrix WCS parameters for each axis ('matrix')
	foreach $eachk (@Armatrixkey) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'matrix'}{$eachk} =
		  $s;    # eg., {'pixellist'}{'matrix'}{'PCall'} => 'TPCn_ka' etc.
	}

	foreach $eachk (qw( RADECSYS EQUINOX )) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'all'}{$eachk} =
		  $s;    # eg., {'pixellist'}{'all'}{'RADECSYS'} => 'RADEna' etc.
	}

	# $hsattrkey{'pixellist'} =
	#  {'axis' => [{'CRVAL'=>'TCRVLn|TCRVna',...}],
	#   'all' => {'RADECSYS' => 'RADEna',
	#             'EQUINOX'  => 'EQUIna|EPOCH' }
	#  };

	############################################
	## nominal
	############################################
	$coordsyskey = 'nominal';
	$iWcskey     = $WcskeyIndex{'Primary'};
	%{ $hsattrkey{$coordsyskey}{'axis'}[0] } = ( 'CRVAL' => 'RA_NOM' );
	%{ $hsattrkey{$coordsyskey}{'axis'}[1] } = ( 'CRVAL' => 'DEC_NOM' );
	foreach $eachk (qw( RADECSYS EQUINOX )) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'all'}{$eachk} =
		  $s;  # eg., {'nominal'}{'all'}{'RADECSYS'} => 'RADESYSa|RADECSYS' etc.
	}

	############################################
	## object
	############################################
	$coordsyskey = 'object';
	$iWcskey     = $WcskeyIndex{'Primary'};
	%{ $hsattrkey{$coordsyskey}{'axis'}[0] } = ( 'CRVAL' => 'RA_OBJ' );
	%{ $hsattrkey{$coordsyskey}{'axis'}[1] } = ( 'CRVAL' => 'DEC_OBJ' );
	foreach $eachk (qw( RADECSYS EQUINOX )) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'all'}{$eachk} =
		  $s;   # eg., {'object'}{'all'}{'RADECSYS'} => 'RADESYSa|RADECSYS' etc.
	}

	############################################
	## pointing
	############################################
	$coordsyskey = 'pointing';
	$iWcskey     = $WcskeyIndex{'Primary'};
	%{ $hsattrkey{$coordsyskey}{'axis'}[0] } = ( 'CRVAL' => 'RA_PNT' );
	%{ $hsattrkey{$coordsyskey}{'axis'}[1] } = ( 'CRVAL' => 'DEC_PNT' );

	# %{$hsattrkey{$coordsyskey}{'axis'}[2]} = ('CRVAL' => 'PA_PNT');
	foreach $eachk (qw( RADECSYS EQUINOX )) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'all'}{$eachk} =
		  $s; # eg., {'pointing'}{'all'}{'RADECSYS'} => 'RADESYSa|RADECSYS' etc.
	}

	############################################
	## image
	############################################
	$coordsyskey = 'image';
	$iWcskey     = $WcskeyIndex{'Primary'};

	# Ordinary WCS parameters for each axis ('axis')
	$hsattrkey{$coordsyskey}{'axis'}[0] = {};
	foreach $eachk (@Arstandardkey) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'axis'}[0]{$eachk} = $s
		  ; # eg., {'image'}{'axis'}[0]{'CRVAL'} => 'CRVALia' (== CRVAL1, CRVAL2L) etc.
	}

	# Matrix WCS parameters for each axis ('matrix')
	foreach $eachk (@Armatrixkey) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'matrix'}{$eachk} =
		  $s;    # eg., {'image'}{'matrix'}{'PCall'} => 'PCi_ja' etc.
	}

	# Non-standard WCS parameters (=> 'misc')
	foreach $j (qw( LTV1 LTM1_1 LTV2 LTM2_2 LTM1_2 LTM2_1 )) {
		$hsattrkey{$coordsyskey}{'misc'}{$j} = $j;
	}

	# Ordinary WCS parameters for general ('all')
	foreach $eachk (qw( RADECSYS EQUINOX WCSNAME WCSAXES )) {
		$s = $Wcskeys{$eachk}[$iWcskey] or next;
		$hsattrkey{$coordsyskey}{'all'}{$eachk} = $s
		  ; # eg., {'image'}{'all'}{'WCSNAME'} => 'WCSNAMEa' (== WCSNAME, WCSNAMEL)
	}

	# $hsattrkey{'image'} =
	#  {'axis' => [{'CRVAL'=>'CRVALia',...}],
	#   'all' => {'RADECSYS' => 'RADECSYS',
	#             'EQUINOX'  => 'EQUINOX',
	#             'WCSNAME'  => 'WCSNAMEa',
	#             'WCSAXES'  => 'WCSAXESa'}
	#  };

	# print "here\n";
	# print Dumper \%hsattrkey;
	print $hsattrkey{$coordsyskey}{'axis'}[0]{'CRVAL'}, "\n"
	  if ($DEBUGGING);    # CRVALia
	%h =
	  &_getAttributeForCelCoordKey(
		$hsattrkey{$coordsyskey}{'axis'}[0]{'CRVAL'}, "CRVAL7Q" );
	print Dumper \%h if ($DEBUGGING);    # => 'CRVAL7Q', 'a'=>'Q', 'i'=>7
	%h =
	  &_getAttributeForCelCoordKey( $hsattrkey{'pixellist'}{'axis'}[0]{'CRVAL'},
		"TCRV12Q" );                     # 'TCRVLn|TCRVna'
	print Dumper \%h if ($DEBUGGING);    # => 'TCRV12Q', 'a'=>'Q', 'n'=>12
	%h =
	  &_getAttributeForCelCoordKey( $hsattrkey{'pixellist'}{'axis'}[0]{'CRVAL'},
		"TCRVL12" );                     # 'TCRVLn|TCRVna'
	print Dumper \%h if ($DEBUGGING);    # => 'TCRVL12', 'n'=>12

	print "Middle(key): "    if ($DEBUGGING);
	print Dumper \%hsattrkey if ($DEBUGGING);

	####################################
	# MAIN: Reading FITS header
	####################################

	$self->{ext} = [];
	%hsattrval   = ();                   # For each extention.
	my (%hskeyinfo);
	my ( $iext,     $line,         @arkey );
	my ( $eachsys,  $eachcoordver, $eachcomp, $eachiaxis, $eachkey );
	my ( $key2eval, $value2eval,   $valfinal );
	my ( $coordver, $columnnum,    $icoord );

	# eg, image  axis|all   \d(==x,y...) CRVAL

	my ($hsKeySysCompNow);               # Ref to Hash
	my ($keyhashfinal);                  # Scalar(String)
	$iext = 0;
	if ( '-' eq $infits ) {    # Receives the output of fdump from STDIN.
		*FITSHEADERIN = *STDIN;
	}
	else {
		open FITSHEADERIN,
"fdump infile=$infits outfil=STDOUT columns=- rows=- prdata=no more=yes|";
		if ( $infits =~ /(?:\+(\d+)|\[(\d+)\])$/ )
		{                      # FITS extention is specified.
			$self->{ext}->[ ( $1 || $2 ) ] = undef;
			$iext = $1;
		}
	}

	##### Algorithm #####
	##
	## Read the input (output of fdump for the FITS header) line by line.
	##
	## Internally, it processes each extention as a block.
	## In each extention, %hsattrval is constructed:
	##  %hsattrval === {SYS}{COORD_VERSION}[COLUMN(=n)]{axis}[\d+]{KEY}
	##             === {SYS}{COORD_VERSION}[COLUMN(=n)]{matrix}{KEY}[i][j][k|m]
	##             === {SYS}{COORD_VERSION}[COLUMN(=n)]{COMPONENT}{KEY}
	##   (Example:    physical    L           0         all       EQUINOX)
	## based on the input line and hash %hsattrkey for the keywords of interest,
	##  %hsattrkey === {SYS}{axis}[\d+]{KEY}
	##             === {SYS}{COMPONENT}{KEY}
	## Note(1): The [COLUMN] is useful in the BINTABLE vector.
	##          If not BINTABLE, it is always 0.
	## Note(2): The latter lacks of {COORD_VERSION}, as you see.
	##
	## At the end of each extention, a collection of MultipleCoordsSys
	## objects are created, using the contents of %hsattrval,
	## i.e., %{$hsattrval{SYS}{COORD_VERSION}} is used to create
	## each MultipleCoordsSys object.
	## Then %hsattrval is flushed for the use of the next extention.
	##
	## MultipleCoordsSys objects are stored in $self in the form of
	##  $self->{ext}->[NUMBER(Extention)]->{SYS}->{COORD_VERSION} = MultipleCoordsSys->new;
	##
	##
	##### NOTE for developers: #####
	## The structure of $self can be implemented differently;
	## $self can just contains the simple array of MultipleCoordsSys objects,
	## instead of holding each as a separate element in a multi-layered hash.
	## Since each MultipleCoordsSys knows its Extention, SYS and COORD_VERSION,
	## $self could handle them to do anything.
	## However, in creating each MultipleCoordsSys this routin already
	## knows Extention, SYS and COORD_VERSION.  Therefore I have implemented
	## this as a form of hash as described above.
	##
	##
	while ( $line = <FITSHEADERIN> ) {
		chop($line);
		if ( $line =~ /^\s*$/ ) {
			next;
		}
		elsif ( $line =~ /^(CONTINUE|HISTORY)/ ) {
			next;

		}
		elsif ( $line =~ /^END\s*$/ ) {
			print "DEBUG:(before-multiple)hsattrval=" if ($DEBUGGING);
			print Dumper \%hsattrval                  if ($DEBUGGING);

			####################################
	  		# Make MultipleCoordsSys(CelCoords/Coords) objects after every extention.
			####################################
			%hsmcs = ();
			foreach $eachsys (@Arcoordsyskey) {    # 'physical', 'image' etc.
				$hsmcs{$eachsys} ||= {};
				foreach $eachcoordver ( keys( %{ $hsattrval{$eachsys} } ) )
				{                                  # 'default' or [A-Z]

					print STDERR "DEBUG: MultipleCoordsSys->new( 'sysname'  => $eachsys, 'coordver' => $eachcoordver, 'arcolumn' => "
					  if ($DEBUGGING);
					$s = $hsattrval{$eachsys}{$eachcoordver};
					print Dumper \$s if ($DEBUGGING);

					if ( $hsattrval{$eachsys}{$eachcoordver} ) {

						$s = MultipleCoordsSys->new(
							'ext'      => $iext,
							'sysname'  => $eachsys,
							'coordver' => $eachcoordver,
							'arcolumn' => $hsattrval{$eachsys}{$eachcoordver}
						);
						$hsmcs{$eachsys}{$eachcoordver} = $s if $s;
					}
				}
			}

			$self->{ext} ||= [];
			%{ $self->{ext}[$iext] } = %hsmcs;    # For each FITS extention.

####################################
			print "BEFORE-last:hsattrval=\n" if ($DEBUGGING);
			print Dumper \%hsattrval         if ($DEBUGGING);

			#print Dumper \$hsattrval{$eachsys} if ($DEBUGGING);
			print "BEFORE-last:hsmcs=\n" if ($DEBUGGING);
			print Dumper \%hsmcs         if ($DEBUGGING);

			#last;
####################################
			%hsattrval = ();    # Initialise for each extention.
			$iext++;            # next FITS extention.
			next;

		}
		else {                  # if ($line =~ /^\s*$/)
			### Deal with each line of the input header.

			$key2eval   = substr( $line, 0, 8 );
			$value2eval = substr( $line, 10 );

			print STDERR "DEBUG:key2eval=($key2eval)\n" if ($DEBUGGING);
			foreach $eachsys (@Arcoordsyskey) {    # 'physical', 'image' etc.
				$hsattrval{$eachsys} ||= {};
				foreach $eachcomp ( keys( %{ $hsattrkey{$eachsys} } ) )
				{                                  # 'axis', 'all' etc
					$hsKeySysCompNow = $hsattrkey{$eachsys}{$eachcomp};
					$s = ref($hsKeySysCompNow);
					if ( $s eq 'ARRAY' ) {         # Probably 'axis'
						## Do nothing
					}
					elsif ( $s eq 'HASH' ) {
						$hsKeySysCompNow = [$hsKeySysCompNow];
					}
					else {
						die "Strange.";
					}

					foreach $eachiaxis ( 0 .. $#{$hsKeySysCompNow} )
					{                              # Loop over (x,y,z,...)
						if ( !$hsKeySysCompNow->[$eachiaxis] )
						{    # Safety net --- this should not happen.
							&SSCLib::sscwarn("Something is wrong in [$iext]{$eachsys}{$eachcomp}."
							);
							next;
						}

						foreach $eachkey (
							keys( %{ $hsKeySysCompNow->[$eachiaxis] } ) )
						{    # Loop over (CRVAL, RADECSYS,...)

							%hskeyinfo =
							  &_getAttributeForCelCoordKey(
								$hsKeySysCompNow->[$eachiaxis]->{$eachkey},
								$key2eval );
								
							## NOTE: %hskeyinfo is like ('keymatched'=>'TCRV2L', 'i'=>2, 'j'=>undef, 'n'=>3, 'm'=>undef, 'k'=>undef, 'a'=>'L')
							print STDERR "DEBUG:key=($hsKeySysCompNow->[$eachiaxis]->{$eachkey}), key2eval=($key2eval), keymatched=($hskeyinfo{'keymatched'})\n"
							  if ( defined $hskeyinfo{'keymatched'}
								&& $DEBUGGING );

							if ( $hskeyinfo{'keymatched'} ) {

# The header line we are examining here is significant, and the value has to be stored.

								## Get the value to store.
								$s = &SSCLib::strip($value2eval);
								if ( "\047" eq substr( $value2eval, 0, 1 ) )
								{    # \047 is a single-quote.
									@ar =
									  &Fitsplutils::getStringHeaderLine(
										substr( $value2eval, 1 ) );
									$valfinal = $ar[0];    # String
								}
								else {
									$s =~ s/\s+.*$//;
									$valfinal =
									  &Fitsplutils::getPerlNumeric($s)
									  ;                    # Numeric									
								}

								#if ($eachsys eq 'pixellist'){
								print STDERR
"DEBUG:keymatched=($hskeyinfo{'keymatched'}), valfinal=($valfinal), s=($s), a=($hskeyinfo{'a'})\n"
								  if ($DEBUGGING);
								print STDERR "DEBUG:hskeyinfo=" if ($DEBUGGING);
								print Dumper \%hskeyinfo        if ($DEBUGGING);
								#}

								## Get the Coordinate Version number. (See FITS Standard)
								$coordver = $hskeyinfo{'a'};
								$coordver                       ||= 'def';
								$hsattrval{$eachsys}{$coordver} ||= [];

								## Get the Column number. (See FITS Standard for the notation of [ijnmk])
								if ( defined $hskeyinfo{'n'} ) {
									$columnnum = $hskeyinfo{'n'};
								}
								else {
									$columnnum = 0
									  ; # Default (if the column n does not exist).
								}

								#if ($eachsys eq 'pixellist'){
								# print "hsattrval=";print Dumper \%hsattrval;
								print "HERE010...\n"     if $DEBUGGING;
								print "010:hsattrval="   if $DEBUGGING;
								print Dumper \%hsattrval if $DEBUGGING;

								#}
								$hsattrval{$eachsys}{$coordver}[$columnnum] ||=
								  {};

								$keyhashfinal = $eachkey;

								if ( 'axis' eq $eachcomp ) {

									#if ($eachsys eq 'pixellist'){
									print "HERE011...\n"     if $DEBUGGING;
									print "011:hsattrval="   if ($DEBUGGING);
									print Dumper \%hsattrval if $DEBUGGING;

									#}
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp} ||= [];

									## Get the Coordinate axis number. (See FITS Standard for the notation of [ijnmk])
									$icoord = -1;
									foreach (qw( i j )) {
										if ( defined $hskeyinfo{$_} ) {
											$icoord =
											  $hskeyinfo{ $_
											  }; # eg., CRVALi, CRPIX; if TCRVLn etc, then undefined.
											last;
										}
									}
									if ( $icoord < 0 ) {
										$icoord = $eachiaxis;

										# If it is 'physical' etc., $eachiaxis >= 0 .
										# If it is not, and [ijn] is not defined (which is unlikely), then $eachiaxis must be 0, and accordingly $icoord=0 .
									}

										#print "012:hsattrval=";print Dumper \%hsattrval;
										#print "HERE012...(sys=$eachsys)($valfinal) icoord=($icoord) keyhashfinal=($keyhashfinal)\n";
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}[$icoord] ||= {};

							  		#print "012b:hsattrval=";print Dumper \%hsattrval;
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}[$icoord]{$keyhashfinal} =
									  $valfinal;

									#if ($eachsys eq 'pixellist'){
									print "HERE013...\n"   if $DEBUGGING;
									print "013:hsattrval=" if $DEBUGGING;
									print Dumper \%hsattrval if $DEBUGGING;

									#}

								}
								elsif ( 'matrix' eq $eachcomp ) {
					
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp} ||= {};
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}{$keyhashfinal} ||= [];

									$i = $hskeyinfo{'i'};
									$i ||= 0;
									$j = $hskeyinfo{'j'};
									$j ||= 0;
									$k = 0;
									foreach (qw( k m )) {
										if ( defined $hskeyinfo{$_} ) {
											$k =
											  $hskeyinfo{ $_
											  };    # eg., TCDn_ka, iPVn_ma
											last;
										}
									}
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}{$keyhashfinal}[$i] ||= [];
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}{$keyhashfinal}[$i][$j] ||= [];
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}{$keyhashfinal}[$i][$j][$k] =
									  $valfinal;

								}
								else
								{ # if ('axis' eq $eachcomp) # Namely, if 'all' or 'misc', comes here.
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp} ||= {};
									$hsattrval{$eachsys}{$coordver}[$columnnum]
									  {$eachcomp}{$keyhashfinal} = $valfinal;

								}    # if ('axis' eq $eachcomp)

							}    #      if ($hskeyinfo{'keymatched'})
						} #     foreach $eachkey (keys(%{$hsKeySysCompNow[$eachiaxis]}))	# 'CRVAL' etc.
					}    #    foreach $eachiaxis (1..$#{$hsKeySysCompNow})
				} #   foreach $eachcomp (keys(%{$hsattrkey{$eachsys}}))	# 'axis' etc
			}    #  foreach $eachsys (@Arcoordsyskey)	# 'physical', 'image' etc.

			#print STDERR "DEBUG:end-of-loop: ";print Dumper \%hsattrval;

		}    # if ($line =~ /^\s*$/)
	}    # while(<FITSHEADERIN>)

	close FITSHEADERIN;

	if (%hsinkey) { # The syntax "(defined %hsinkey)" is deprecated, apparently.
		## Further process  [!!!FUTURE WORKS!!!]
	}

	$self;
}    # sub _initialize

#---------------------------------------------------------------------
sub isNearlyEqual {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, c2, [precision, [maximum_difference, [options,...]]])
	### Input(Normal method):    (c2, [precision, [maximum_difference, [options,...]]])
	### Return: 1 if yes, or 0 otherwise.
	### Description: Compare two FitsCelCoordsSys objects
	###   and return true if they agree in the given precision or given maximum_difference,
	###   after the components (of both the objects) are reduced,
	###   according to the given hash conditions.
	###   c2 can be MultipleCoordsSys, PairCoordsSys or (Cel)Coords, instead of FitsCelCoordsSys.
	### Reference: See SSCLib::isNearlyEqual for detail.

	my ($subname) = "isNearlyEqual";

	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->isNearlyEqual( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1      = shift;
		my $c2      = shift;
		my @argrest = @_;
		my %hsarg;
		%hsarg = @argrest[ 2 .. $#argrest ] if ( scalar(@argrest) > 2 );

		my ( @armcs1, @armcs2 );
		@armcs1 = $c1->aryMcs(%hsarg);

		if ( !$c2->can('aryMcs') ) {    # c2 is NOT FitsCelCoordsSys
			if ( 1 == scalar(@armcs1) ) {
				return $armcs1[0]->isNearlyEqual( $c2, @argrest )
				  ;                     # MultipleCoordsSys->isNearlyEqual
			}
			else {
				return 0;
			}

		}
		else {                          # c2 should be a FitsCelCoordsSys

			@armcs2 = $c2->aryMcs(%hsarg);

			return 0 if ( $#armcs1 != $#armcs2 );

			my ($i);
			foreach $i ( 0 .. $#armcs1 ) {
				return 0
				  if ( !$armcs1[$i]->isNearlyEqual( $armcs2[$i], @argrest ) );
			}

			return 1;
		}    #   if (! $c2->can('aryMcs'))
	}    #  if (ref($self))
}    # sub isNearlyEqual

#---------------------------------------------------------------------
sub singleCoords {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: A single Coords (or CelCoords) object,
	###  or 0 if more than one objects are found to satisfy the conditions,
	###  or undef if no object is found to satisfy the conditions.
	### Description:
	###   For the conditions (Optional-Hash), see the description of aryMcs().
	### Reference:

	my ($subname) = "singleCoords";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->singleCoords( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;

		my (@armcs);
		@armcs = $c1->aryMcs(%hsarg);
		if (@armcs) {
			if ( scalar(@armcs) == 1 ) {
				return $armcs[0]->singleCoords(%hsarg);
			}
			else {
				return 0;
			}
		}
		else {    # Null
			return undef;
		}
	}
}    # sub singleCoords

#---------------------------------------------------------------------
sub singlePcs {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: A single PairCoordsSys object,
	###  or 0 if more than one objects are found to satisfy the conditions,
	###  or undef if no object is found to satisfy the conditions.
	### Description:
	###   For the conditions (Optional-Hash), see the description of aryMcs().
	### Reference:

	my ($subname) = "singlePcs";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->singlePcs( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;

		my (@armcs);
		@armcs = $c1->aryMcs(%hsarg);
		if (@armcs) {
			if ( scalar(@armcs) == 1 ) {
				return $armcs[0]->singlePcs(%hsarg);
			}
			else {
				return 0;
			}
		}
		else {    # Null
			return undef;
		}
	}
}    # sub singlePcs

#---------------------------------------------------------------------
sub aryMcs {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: The 1-dim array of MultipleCoordsSys (MCS) objects,
	###  which satisfies the given condition.
	### Description:
	###   The order of the MCSs in the returning array is
	###    (1) by extention,
	###    (2) sys: image, physical, pixellist, then alphabetical,
	###    (3) coordinate-version: def, then alphabetical.
	###   Note it is irrelevant of the order of the given array
	###  (if an array is specified in the given Optional-Hash).
	###
	###   The argument hash key may include 'index',
	###  of which the element is $c1->arrayAllSignificantMcsIndex();
	###   For the other keys, see the description in _getMcsIndex2Use().
	### Reference:

	my ($subname) = "aryMcs";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->aryMcs( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;
		my (@arMcsIndex2Use);
		my ( @arsys, @arcver );

		if ( exists( $hsarg{'index'} ) ) {
			@arMcsIndex2Use =
			  @{ $hsarg{'index'}
			  }; # Array of hash, the same as the Returned array of arraySignificantMcsIndex()
		}
		else {
			@arMcsIndex2Use = $c1->arraySignificantMcsIndex(%hsarg);

			# print "DEBUG(mcs1): ";print Dumper \@arMcsIndex2Use ;
		}

		## Construct the returning array of MCS.
		my ( $eachsys, $eachcoordver, $iext, $s );
		foreach $iext ( 0 .. $#arMcsIndex2Use ) {
			next if ( ref( $arMcsIndex2Use[$iext] ) ne 'HASH' );			
		
			@arsys = &_sort_arsys( keys( %{ $arMcsIndex2Use[$iext] } ) );		
			foreach $eachsys (@arsys) {
				next if ( ref( $arMcsIndex2Use[$iext]{$eachsys} ) ne 'HASH' );

# @arcver = sort {if ($b eq 'def') { 1 } else {$a cmp $b}} keys(%{$arSigMcsIndex[$iext]{$eachsys}});	# 'def' first.
				@arcver =
				  &_sort_arcver(
					keys( %{ $arMcsIndex2Use[$iext]{$eachsys} } ) )
				  ;    # 'def' first.
				 # foreach $eachcoordver (keys(%{$arMcsIndex2Use[$iext]{$eachsys}})) {
				foreach $eachcoordver (@arcver) {
					if ( $arMcsIndex2Use[$iext]{$eachsys}{$eachcoordver} ) {
						push( @arret,
							$c1->{ext}[$iext]{$eachsys}{$eachcoordver} );
					}
				}
			}    #    foreach $eachsys (@arsys) {
		}    #   foreach $iext (0..$#arMcsIndex2Use)

		return @arret;
	}    #  if (ref($self))

}    # sub aryMcs

#---------------------------------------------------------------------
sub arrayAllSignificantMcsIndex {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1)
	### Input(Normal method):(NONE)
	### Return: The array indicating all the significant indices
	###   for {ext}->[?]->{?}->{?}: 1 for significant, else 0.
	###   For example, the returned array @a may have an element,
	###   $a[0]->{image}->{def} = 1.
	###   If 'ext' is not defined first of all, null Array () is returned.
	###   If an extention or its sub-component has no defined component,
	###   then undef is set, eg.,
	###    $a[1] = undef
	###    $a[2]->{image} = undef
	### Description:
	### Reference:

	my ($subname) = "arrayAllSignificantMcsIndex";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->arrayAllSignificantMcsIndex( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1 = shift;

		return @arret if ( !exists( $$c1{ext} ) );
		return @arret if ( !defined( $c1->{ext} ) );
		if ( ref( $c1->{ext} ) ne 'ARRAY' ) {    # Neither ARRAY nor undef.
			print Dumper \$c1;
			die("'ext' in $self object is wrong.");
		}

		my ( $eachsys, $eachcoordver, $iext, $s );
		foreach $iext ( 0 .. $#{ $c1->{ext} } ) {
			$arret[$iext] = undef;               # undef in default.
			next if ( ref( $c1->{ext}[$iext] ) ne 'HASH' );
			foreach $eachsys ( keys( %{ $c1->{ext}[$iext] } ) ) {
				next if ( ref( $c1->{ext}[$iext]{$eachsys} ) ne 'HASH' );
				$arret[$iext] ||= { $eachsys => undef };
				foreach $eachcoordver (
					keys( %{ $c1->{ext}[$iext]{$eachsys} } ) )
				{
					$arret[$iext]{$eachsys} ||= { $eachcoordver => undef };
					if (
						( $c1->{ext}[$iext]{$eachsys}{$eachcoordver} )
						&&                       # NOT undef
						(
							$c1->{ext}[$iext]{$eachsys}{$eachcoordver}
							->can('isNil')
						)
					  )
					{    # Must be MultipleCoordsSys class object
						$arret[$iext]{$eachsys}{$eachcoordver} =
						  ( !$c1->{ext}[$iext]{$eachsys}{$eachcoordver}
							  ->isNil );    # 0 or 1
					}
				} #   foreach $eachcoordver (keys(%{$c1->{ext}[$iext]{$eachsys}}))
			}    #  foreach $eachsys (keys(%{$c1->{ext}[$iext]}))
		}    # foreach $iext (0..$#{$c1->{ext}})

		return @arret;
	}    #  if (ref($self))
}    # sub arrayAllSignificantMcsIndex

#---------------------------------------------------------------------
sub arraySignificantMcsIndex {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: The (0|1) array for significant components,
	###  which satisfies the given condition.
	### Description:
	###   The same as arrayAllSignificantMcsIndex(), but
	###  this method accepts the condition-hash as the argument,
	###  the same as aryMcs().
	###   Note this method is called from aryMcs().
	###
	###   The argument hash key may include 'allindex',
	###  of which the element is $c1->arrayAllSignificantMcsIndex();
	###   For the other keys, see the description in _getMcsIndex2Use().
	### Reference:

	my ($subname) = "arraySignificantMcsIndex";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->arraySignificantMcsIndex( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;
		my ( @arAllSigMcsIndex, @arMcsIndex2Use );
		my ( @arsys,            @arcver );

		if (   ( exists( $hsarg{'allindex'} ) )
			&& ( 'ARRAY' eq ref( $hsarg{'allindex'} ) ) )
		{
			@arAllSigMcsIndex =
			  @{ $hsarg{'allindex'}
			  }; # Array of hash, the same as the Returned array of arrayAllSignificantMcsIndex()
		}
		elsif (( exists( $hsarg{'arrayAllSignificantMcsIndex'} ) )
			&& ( 'ARRAY' eq ref( $hsarg{'arrayAllSignificantMcsIndex'} ) ) )
		{
			@arAllSigMcsIndex = @{ $hsarg{'arrayAllSignificantMcsIndex'} };
		}
		else {
			@arAllSigMcsIndex = $c1->arrayAllSignificantMcsIndex;
		}

		#print "DEBUG: ";print Dumper \@arAllSigMcsIndex ;
		#print "DEBUG: ";print Dumper \%hsarg ;

		return &_getMcsIndex2Use(
			'arrayAllSignificantMcsIndex' => \@arAllSigMcsIndex,
			%hsarg
		);

	}
}    # sub arraySignificantMcsIndex

#---------------------------------------------------------------------
sub arraySignificantExtIndex {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: 1-dim Array indicating significant indices for {ext}->[?],
	###   for example, (0, 1, 1, 0) means the 1st and 2nd extentions are significant.
	###   If 'ext' is not defined first of all, null Array () is returned.
	### Description:
	###   This method accepts the condition-hash as the argument,
	###  the same as aryMcs().
	###
	###   For the other keys, see the description in _getMcsIndex2Use().
	### Description:
	### Reference:

	my ($subname) = "arraySignificantExtIndex";
	my $self = shift;

	my @arret;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->arraySignificantExtIndex( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;

		my (@arMcsIndex2Use);
		if ( exists( $hsarg{'index'} ) ) {
			@arMcsIndex2Use =
			  @{ $hsarg{'index'}
			  }; # Array of hash, the same as the Returned array of arraySignificantMcsIndex()
		}
		else {
			@arMcsIndex2Use = $c1->arraySignificantMcsIndex(%hsarg);
		}

		my ( $eachsys, $eachcoordver, $iext, $s );
		foreach $iext ( 0 .. $#arMcsIndex2Use ) {
			$arret[$iext] = 0;    # Insignificant in default.
			next if ( ref( $arMcsIndex2Use[$iext] ) ne 'HASH' );
			foreach $eachsys ( keys( %{ $arMcsIndex2Use[$iext] } ) ) {
				next if ( ref( $arMcsIndex2Use[$iext]{$eachsys} ) ne 'HASH' );
				foreach $eachcoordver (
					keys( %{ $arMcsIndex2Use[$iext]{$eachsys} } ) )
				{
					$arret[$iext] = 1
					  if ( $arMcsIndex2Use[$iext]{$eachsys}{$eachcoordver} );

	   # Once it is set to be 1, there is no need to carry on checking.
	   # However the processing speed is not a problem here, so I just leave it.
				}
			}
		}

		return @arret;
	}    #  if (ref($self))
}    # sub arraySignificantExtIndex

#---------------------------------------------------------------------
sub minglePair {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method): (c1, [Optional-Hash])
	### Input(Normal method):([Optional-Hash])
	### Return: A modified FitsCelCoordsSys object,
	###  or undef if something goes wrong.
	### Description:
	###   Making up (modify) a PairCoordsSys the object contains
	###  from two sets of PairCoordsSys in it,
	###  which are probably extracted from individual columns,
	###
	###   Optional-Hash includes both those for selection in FitsCelCoordsSys
	###  (see the description in _getMcsIndex2Use()) and those passed
	###  to MultipleCoordsSys->minglePair().
	###   In default 'sys'=>'pixellist' is added, unless specified otherwise.
	###  Here, 'sys'=>'auto' means the same.
	###   See the description of MultipleCoordsSys->minglePair for detail.
	###   Note default 'auto' in this method is not very clever so far.
	### Reference:

	my ($subname) = "minglePair";
	my $self = shift;

	# my $retFccs;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->minglePair( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;
		my %h     = ( 'sys' => "pixellist" );    # Default if not specified.
		%hsarg = &hashmerge( \%hsarg, \%h );
		$hsarg{'sys'} = "pixellist"
		  if ( ( !defined( $hsarg{'sys'} ) ) || ( $hsarg{'sys'} eq "auto" ) );

		my (@arMcsIndex2Use);
		if ( exists( $hsarg{'index'} ) ) {
			@arMcsIndex2Use =
			  @{ $hsarg{'index'}
			  }; # Array of hash, the same as the Returned array of arraySignificantMcsIndex()
		}
		else {
			@arMcsIndex2Use = $c1->arraySignificantMcsIndex(%hsarg);
		}

		my $f2 = $c1->deepcopy;    # Returned object.
		my $m2;

		my ( $eachsys, $eachcoordver, $iext, $s );
		foreach $iext ( 0 .. $#arMcsIndex2Use ) {
			next if ( ref( $arMcsIndex2Use[$iext] ) ne 'HASH' );
			foreach $eachsys ( keys( %{ $arMcsIndex2Use[$iext] } ) ) {
				next if ( ref( $arMcsIndex2Use[$iext]{$eachsys} ) ne 'HASH' );
				foreach $eachcoordver (
					keys( %{ $arMcsIndex2Use[$iext]{$eachsys} } ) )
				{
					if ( $arMcsIndex2Use[$iext]{$eachsys}{$eachcoordver} ) {
						$m2 =
						  $f2->{ext}[$iext]{$eachsys}{$eachcoordver}
						  ->minglePair(%hsarg);
						if ($m2) {
							$f2->{ext}[$iext]{$eachsys}{$eachcoordver} = $m2;
						}
						else {
							sscwarn(
"Something is wrong in FitsCelCoordsSys->minglePair for Extention=($iext), sys=($eachsys) coordver=($eachcoordver)"
							);
							return undef;
						}
					}
				}
			}
		}

		return $f2;

	}    #  if (ref($self))
}    # sub minglePair

#---------------------------------------------------------------------
sub to_s {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input(Class method):  (c1, ['printall'=>0(def)|1, 'indent'=>"", 'withname'=>0|1, condition-Hash])
	### Input(Normal method): (['printall'=>0(def)|1, 'indent'=>"", 'withname'=>0|1, condition-Hash])
	### Return: String expression.
	### Description:
	###   The optional hash can include 3 different classes of components,
	###  i.e., the one unique to this method ('printall'),
	###  the one used in to_s() in the container classes (indent|withname),
	###  the one used to choose which MCS (=MultipleCoordsSys) to look at (ext|sys|cver).
	###   If 'printall'=>1 is given in the argument, print all the extentions
	###  via the unique routine in this to_s(), by skipping
	###  the check whether each MCS is significant or not.
	###   If the optional 'indent', such as, "| " is given, it is added
	###  to the head of each line.
	###   For the other keys in the condition-Hash, see the description in _getMcsIndex2Use().
	### Reference:

	my ($subname) = "to_s";
	my $self = shift;

	if ( ref($self) ) {    # Normal method.
		return ( ref($self)->to_s( $self, @_ ) )
		  ;                # Practically calling the following.

	}
	else {                 # Class method.
		my $c1    = shift;
		my %hsarg = @_;

		# my %hs2pass = ('indent' => "");	# Nil indent is passed.
		#    %hs2pass = hashmerge(\%hs2pass, \%hsarg);	# in SSCLib
		# my $indent = ($hsarg{'indent'} || "");
		my $printall = $hsarg{'printall'};
		my $retstr   = "";

		if ($printall) {
			my ( $eachsys, $eachcoordver, $iext );
			foreach $iext ( 0 .. $#{ $c1->{ext} } ) {
				next if ( ref( $c1->{ext}[$iext] ) ne 'HASH' );
				foreach $eachsys ( keys( %{ $c1->{ext}[$iext] } ) ) {
					next if ( ref( $c1->{ext}[$iext]{$eachsys} ) ne 'HASH' );
					foreach $eachcoordver (
						keys( %{ $c1->{ext}[$iext]{$eachsys} } ) )
					{
						if (
							( $c1->{ext}[$iext]{$eachsys}{$eachcoordver} )
							&&    # NOT undef
							(
								$c1->{ext}[$iext]{$eachsys}{$eachcoordver}
								->can('to_s')
							)
						  )
						{         # Must be MultipleCoordsSys class object
							$retstr .=
							  $c1->{ext}[$iext]{$eachsys}{$eachcoordver}
							  ->to_s(%hsarg);
						}
					} #   foreach $eachcoordver (keys(%{$c1->{ext}[$iext]{$eachsys}}))
				}    #  foreach $eachsys (keys(%{$c1->{ext}[$iext]}))
			}    # foreach $iext (0..$#{$c1->{ext}})

		}
		else {
			my @armcs = $c1->aryMcs(%hsarg);

			foreach (@armcs) {
				$retstr .= $_->to_s(%hsarg);
			}
		}

		# $retstr =~ s/^/$indent/gm;	# Add an indent, if needed.
		return $retstr;
	}    # if (ref($self))
}

#---------------------------------------------------------------------
sub _getAttributeForCelCoordKey {

	#---------------------------------------------------------------------
	### Input:  (Key, String)
	### Return: Hash, eg. ('keymatched'=>'TCRV2L', 'i'=>2, 'j'=>undef, 'n'=>3, 'm'=>undef, 'k'=>undef, 'a'=>'L')
	###  See Table 8.2 (Section 8.2, pp.77) in FITS Standard Ver.3.0 (2008/07/10) for the meaning of [ijnmka].
	### Description:
	###  This is a NORMAL function!
	###  If the key does not match, then 'keymatched'=>undef in the returned hash,
	###  where all the above keys still exist nevertheless.
	### References:

	my ($inkey) = shift;    # eg., 'TCRVLn|TCRVna'
	$inkey = &SSCLib::strip($inkey);
	my ($instr) = shift;
	my (%rethash);

	my ( %hsregexpindices, @armatched );
	my ( $strregexp,       $i, $s );

	## Initialisation
	$rethash{'keymatched'} = undef;
	foreach (qw( i j n m k a )) {
		$rethash{$_}         = undef;
		$hsregexpindices{$_} = [];
	}

	## Which of $1..$9 corresponds to [ijnmka]?
	$i = 1;
	foreach $s ( split( //, $inkey ) ) {    # Evaluate a character by character
		if ( $s =~ /[ijnmka]/ ) {
			push( @{ $hsregexpindices{$s} }, $i );
			$i++;
		}
	}

	## Making RegExp
	$_ = &SSCLib::strip($inkey);
	s/[ij]/(\\d)/g;
	s/[n]/(\\d*)/g;                         # Maybe \d+
	s/[km]/(\\d+)/g;
	s/[a]/([A-Z]?)/g;
	$strregexp = $_;

	# $rethash{'regexp'} = $strregexp;	# For Debug
	# print "strregexp = $strregexp\n";

	## Do matching and construct the returning hash (%rethash).
	if ( $instr =~ /^($strregexp)\s*$/ ) {
		$rethash{'keymatched'} = $1;

		@armatched =
		  ( $1, $2, $3, $4, $5, $6, $7, $8, $9 )
		  ;    ## Is there any smarter way to do this?

		# print STDERR "DEBUG:armatched=";print Dumper \@armatched;
		# print STDERR "DEBUG:hsregexpindices=";print Dumper \%hsregexpindices;
		foreach $s (qw( i j n m k a )) {
			foreach $i ( @{ $hsregexpindices{$s} } ) {
				$rethash{$s} = $armatched[$i] if ( defined( $armatched[$i] ) );
			}
		}
	}

	%rethash;
}    # sub _getAttributeForCelCoordKey

#---------------------------------------------------------------------
sub _sort_arsys {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input:(1-dim Array of 'system' keywords)
	### Return: Sorted array from the input.
	### Description: Internal function.
	###  Priority:
	###    1. 'image'
	###    2. 'physical'
	###    3. 'pixellist'
	###    4. Else (alphabetical)
	### Reference:
	
	my @sortedvars = sort @_;
	
	return @sortedvars;
}

#---------------------------------------------------------------------
sub _sort_arcver {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input:(1-dim Array of 'coordinatever' keywords)
	### Return: Sorted array from the input.
	### Description: Internal function.
	###  Priority:
	###    1. 'def'
	###    2. Else (alphabetical)
	### Reference:

	sort {
		if ( $b eq 'def' )
		{    # 'def' first.
			1;
		}
		else {
			$a cmp $b;
		}
	} @_;
}

#---------------------------------------------------------------------
sub _getMcsIndex2Use {    # for FitsCelCoordsSys

	#---------------------------------------------------------------------
	### Input:(Hash)
	### Return: The (undef|1) array of (Hashes of) index for MultipleCoordsSys (MCS) to use,
	###   which satisfies the given condition.
	###   The form of the returned array is the same as arrayAllSignificantMcsIndex().
	### Description: Internal function.
	###  The optional hash may include the following keys:
	###   'arrayAllSignificantMcsIndex' (mandatory): Reference to the returned Array of $c->arrayAllSignificantMcsIndex().
	###      This method is based on this (reference to) array.
	###   'ext' for extentions: (all|auto|\d+|\@array)
	###      'all' means every extention (Default),
	###      'auto' at the moment means the first one found,
	###      the reference to the desired array, such as, (0, 2, 3) for extentions (0, 2, 3) can be given,
	###      or a simple number of the extention.
	###   'sys' for system-names: (all|auto|\S+|\@array)
	###      "system-name" means (image|physical|pixellist|nominal|object|pointing|...).
	###      The same as 'ext'.
	###   'cver' for Coordinate-version: (all|auto|def|[A-Z]|\@array)
	###      "Coordinate-version" is a capital letter or "def"(ault).
	###      The same as 'ext'.
	### Reference:

	my ($subname) = "_getMcsIndex2Use";
	my %hsarg     = @_;
	my %hsopt     = %hsarg;
	my %hsargdef  = (
		'ext'  => 'all',
		'sys'  => 'all',
		'cver' => 'all'
	);
	%hsopt = hashmerge( \%hsopt, \%hsargdef );    # in SSCLib

	my @arret;

	my @arSigMcsIndex = @{ $hsarg{'arrayAllSignificantMcsIndex'} };

	my %flag = (
		'ext1'   => 0,
		'sys1'   => 0,
		'cver1'  => 0,
		'extany' => 0
		, # The last two are used if there is any significant Mcs in the given block.
		'sysany' => 0
	);

	my @arext;
	if (
		( ( !$hsopt{'ext'} ) && ( $hsopt{'ext'} != 0 ) )
		||    # i.e., if undef or ''
		( lc( $hsopt{'ext'} ) eq 'all' )
	  )
	{
		@arext = ( 0 .. $#arSigMcsIndex );
	}
	elsif ( lc( $hsopt{'ext'} ) eq 'auto' ) {
		$flag{'ext1'} = 1;    # Skip after the first one.
	}
	elsif ( ref( $hsopt{'ext'} ) eq 'ARRAY' ) {
		@arext = @{ $hsopt{'ext'} };
	}
	else {
		@arext = ( $hsopt{'ext'} );
	}

	my ( @arsys, @arsysdef );
	if (   ( !$hsopt{'sys'} )
		|| ( lc( $hsopt{'sys'} ) eq 'all' ) )
	{
		## Do nothing.
	}
	elsif ( lc( $hsopt{'sys'} ) eq 'auto' ) {
		$flag{'sys1'} = 1;    # Skip after the first one.
	}
	elsif ( ref( $hsopt{'sys'} ) eq 'ARRAY' ) {
		@arsysdef = @{ $hsopt{'sys'} };
	}
	else {
		@arsysdef = ( $hsopt{'sys'} );
	}

	my ( @arcver, @arcverdef );
	if (   ( !$hsopt{'cver'} )
		|| ( lc( $hsopt{'cver'} ) eq 'all' ) )
	{
		## Do nothing.
	}
	elsif ( lc( $hsopt{'cver'} ) eq 'auto' ) {
		$flag{'cver1'} = 1;    # Skip after the first one.
	}
	elsif ( ref( $hsopt{'cver'} ) eq 'ARRAY' ) {
		@arcverdef = @{ $hsopt{'cver'} };
	}
	else {
		@arcverdef = ( $hsopt{'cver'} );
	}

	my ( $eachsys, $eachcoordver, $iext, $s );
	$flag{'extany'} = 0;
	foreach $iext (@arext) {
		$arret[$iext] ||= undef;    # undef in default.
		next if ( ref( $arSigMcsIndex[$iext] ) ne 'HASH' );

		if (@arsysdef) {
			@arsys = @arsysdef;
		}
		else {
			@arsys = keys( %{ $arSigMcsIndex[$iext] } );
		}
		$flag{'sysany'} = 0;
		foreach $eachsys (@arsys) {
			next if ( ref( $arSigMcsIndex[$iext]{$eachsys} ) ne 'HASH' );

			if (@arcverdef) {
				@arcver = @arcverdef;
			}
			else {
				@arcver = keys( %{ $arSigMcsIndex[$iext]{$eachsys} } );
				@arcver = sort {
					if ( $b eq 'def' ) { 1 }
					else { $a cmp $b }
				} @arcver;    # 'def' first.
			}
			foreach $eachcoordver (@arcver) {
				if ( $arSigMcsIndex[$iext]{$eachsys}{$eachcoordver} ) {
					$arret[$iext]           ||= {};    # Initialisation
					$arret[$iext]{$eachsys} ||= {};    # Initialisation
					$arret[$iext]{$eachsys}{$eachcoordver} = 1;
					$flag{'sysany'}                        = 1;
					$flag{'extany'}                        = 1;
					last if $flag{'cver1'};
				}
			}    #   foreach $eachcoordver (@arcver) {
			last if ( $flag{'sys1'} && $flag{'sysany'} );
		}    #  foreach $eachsys (@arsys) {
		last if ( $flag{'ext1'} && $flag{'extany'} );
	}    # foreach $iext (@arext) {

	return @arret;
}    # sub _getMcsIndex2Use

1;

