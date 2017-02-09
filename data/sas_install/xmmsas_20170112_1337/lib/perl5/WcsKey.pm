# Author: Masaaki Sakano - SSC/LUX

our $VERSION = '1.2.0';

package WcsKey;

use strict;
require Exporter;

our @ISA = qw(Exporter);	# Inheritance?
our @EXPORT    = qw(%WcskeyIndex %Wcskeys %Wcskey4Objkey);		# symbols to export in default
our @EXPORT_OK = qw();	# symbols to export on request

#######################################################################

##  See Table 8.2 (Section 8.2, pp.77) in FITS Standard Ver.3.0 (2008/07/10)
#  Note: No parentheses are used here.  Therefore you MUST quote each of them
#   with parenthesis in using these in the Regular Expressions!!
#  Notations: 
#   i: (\d): Intermediate world coordinate axis number
#   j: (\d): Pixel coordinate axis number
#   n, k: (\d*): Column number (in table)
#   m: (\d*): Coordinate parameter number (in table)
#   a: ([A-Z]): Coordinate version.
#
#  Rule derived from here: (nb., this is important, for the code of FitsCelCoordsSys.pm assumes this rule!)
#   * "a","i","n" can appear anywhere.
#   * "i" and "j" can coexist or exist independently.
#   * When "j" exists, either "m" or "k" does not (but "n" may, as stated above).
#   * When "n" exists, either of "m" or "k" can coexist, but not the both simultaneously.
#   * "m" can exists, only when either of "i" or "n" exists.
#   * "k" can exists, only when "n" exists.
#   * It is possible that all of [inm] coexist.

our %WcskeyIndex =
  (              'Primary'  => 0,    'Bintable' => 1, 'Pixel'    => 2);

our %Wcskeys =  # Primary             Bintable vector  Pixel List
  ('WCSAXES'  => ['WCSAXESa|NAXIS',    'WCAXna',        undef],
   'CTYPE'    => ['CTYPEia',           'iCTYPn|iCTYna', 'TCTYPE?n|TCTYna'],	# E? for some non-standard XMM files
   'CUNIT'    => ['CUNITia',           'iCUNIn|iCUNna', 'TCUNIT?n|TCUNna'],	# T? for some non-standard     files
   'CRVAL'    => ['CRVALia',           'iCRVLn|iCRVna', 'TCRVA?Ln|TCRVna'],	# A? for some non-standard XMM files
   'CDELT'    => ['CDELTia',           'iCDLTn|iCDEna', 'TCDE?LTn|TCDEna'],	# E? for some non-standard XMM files
   'CRPIX'    => ['CRPIXja',           'jCRPXn|jCRPna', 'TCRPI?Xn|TCRPna'],	# I? for some non-standard XMM files
   'CROTA'    => ['CROTAi',            'iCROTn',        'TCROTn'],		# Deprecated
   'PCall'    => ['PCi_ja',            'ijPCna',        'TPC?n_ka'],
   'CDall'    => ['CDi_ja',            'ijCDna',        'TCD?n_ka'],
   'PVall'    => ['PVi_ma',            'iP?Vn_ma',      'TP?Vn_ma'],
   # Coordinate parameter array --- not yet implemented.
   'PSall'    => ['PSi_ma',            'iP?Sn_ma',      'TP?Sn_ma'],
   'WCSNAME'  => ['WCSNAMEa',          'WCSNna',        'T?WCSna'],
   'CNAME'    => ['CNAMEia',           'iCNAna',        'TCNAna'],
   'CRDER'    => ['CRDERia',           'iCRDna',        'TCRDna'],
   'CSYER'    => ['CSYERia',           'iCSYna',        'TCSYna'],
   # WCS cross-ref. target --- not yet implemented.
   # WCS cross reference --- not yet implemented.
   'LONPOLE'  => ['LONPOLEa',          'LONPna',        'LONPna'],
   'LATPOLE'  => ['LATPOLEa',          'LATPna',        'LATPna'],
   'EQUINOX'  => ['EQUINOXa|EPOCH',    'EQUIna|EPOCH',  'EQUIna|EPOCH'],
   # Time related --- not yet implemented.
   'RADECSYS' => ['RADESYSa|RADECSYS', 'RADEna',        'RADEna'],
   # Frequency/Wavelength/Spectra/Observations related --- not yet implemented.
   'VELOSYS'  => ['VELOSYSa',          'VSYSna',        'VSYSna'],	# Radial velocity
   # Redshift/Angle-of-True-velocity --- not yet implemented.
   );

our %Wcskey4Objkey = ();
foreach (keys(%Wcskeys)) {
  $Wcskey4Objkey{$_} = $_;	# eg., 'VELOSYS' => 'VELOSYS'
}
my (%hstmp) =	# Merge (overwrite) a hash
  (%Wcskey4Objkey,
   ('CTYPE'    => 'type',
    'CUNIT'    => 'unit',
    'CRVAL'    => 'val',
    'CDELT'    => 'CDELT',
    'CRPIX'    => 'val',
    'CROTA'    => 'CROTA',
    'PA_PNT'   => 'PA_PNT',
    'CNAME'    => 'name',
    'EQUINOX'  => 'epoch',
    'RADECSYS' => 'sys',
    ),
   );
%Wcskey4Objkey = %hstmp;



#######################################################################

=head1 NAME

WcsKey - Module to export some hash variables.

=head1 SYNOPSIS

use WcsKey;

=head1 DESCRIPTION

This module exports some hash variables.
They should be treated as constant, so never try to change them!

Those variables are 
  %WcskeyIndex
  %Wcskeys
  %Wcskey4Objkey

See the code itself to see which is what.

=cut
  ;	# For Emacs


1;

