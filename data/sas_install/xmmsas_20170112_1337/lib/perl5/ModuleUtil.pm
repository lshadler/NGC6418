#!perl
#
# Duncan's you-beaut new obfuscation module.
#

package ModuleUtil;

require 5.005;

# System modules
use English;
use Carp;
use strict qw{vars subs};
#use Experimental::Exception;
use Exporter;
use Cwd;
use File::Basename qw(basename);
use File::Copy qw(copy);
use POSIX qw(:fcntl_h :sys_wait_h :signal_h strftime);
use Time::HiRes qw(time sleep);

use vars qw(@ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(
    keepSafe
    ontimeFix
);

  #---------------------------------------------------------------------
  sub keepSafe {
  #---------------------------------------------------------------------
###    my (%args) = @_;

  return 1;
  }

  #---------------------------------------------------------------------
  sub ontimeFix {
  #---------------------------------------------------------------------
###    my (%args) = @_;

  return 1;
  }


1;
