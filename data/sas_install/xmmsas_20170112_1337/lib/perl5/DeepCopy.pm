package DeepCopy;

# Author: Masaaki Sakano - SSC/LUX

# NOTE: The tests are performed in 
#   ../test/testcoordspm
#   ../test/testcelcoordspm

our $VERSION = '4.19.0';

use strict;
require Exporter;

our @ISA = qw(Exporter);	# Inheritance?
our @EXPORT    = qw(deepcopy);		# symbols to export in default
our @EXPORT_OK = qw();	# symbols to export on request
# Not-Exported: 

use Cwd;
use File::Basename;	# for dirname(), basename()
use IO::File;
use File::Temp ();
use List::Util;
use Data::Dumper;
use POSIX qw(log10 ceil floor); # Math functions.

=head1 NAME

DeepCopy - Module of deepcopy(), used in packages.

=head1 SYNOPSIS

use DeepCopy;

=head1 DESCRIPTION

Define a generic deepcopy() method.

=item deepcopy ( [Instance], ['exclude'=>RegExp] )

For a class TestClass and its instance $t,

  TestClass->deepcopy($t, [optional-hash])
  $t->deepcopy([optional-hash])

are defined.
See the description of SSCLib::deepcopy().
Note $t-{instance} is NOT copied.

=cut
  ;	# For Emacs


############################################################

#---------------------------------------------------------------------
sub deepcopy {
#---------------------------------------------------------------------
  ### Input(Class method):  (c1, [optional-hash])
  ### Input(Normal method):([optional-hash])
  ### Returns: Deep-copied self.
  ### Description: 
  ###   See the description of SSCLib::deepcopy().
  ### Note: $self-{instance} is NOT copied.

  my ($subname) = "deepcopy";

  my $self=shift;

  if (ref($self)) {	# Normal method.
    # return( Coords->deepcopy($self,@_) );	# Practically calling the following.
    return( ref($self)->deepcopy($self,@_) );	# Practically calling the following.

  } else {		# Class method.

    my $self1 = shift;
    my %hsarg = @_;

    my $self2 = {};
    bless $self2, ref($self1);

    my ($key, $value);

    while (($key, $value) = each %$self1) {
      next if ($key eq 'instance');
      $self2->{$key} = &SSCLib::deepcopy($value, %hsarg);	# Deep copy
    }

    return $self2;
  }
}


1;
