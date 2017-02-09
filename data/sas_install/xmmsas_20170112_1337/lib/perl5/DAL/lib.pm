package DAL::lib;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DAL_C_lib;

@ISA = qw(DAL_C_lib Exporter);
@EXPORT = qw(
	
);
$VERSION = '0.01';

1;

