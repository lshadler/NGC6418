#  Giuseppe Vacanti (cosine science & computing bv)
#  February  7, 2003
# 
#   $Id: error.pm,v 1.5 2003/02/24 09:31:07 gvacanti Exp $

package SAS::error;

require 5.005;

use Env;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK
	    $UIMsg $MetaMsg $AppMsg $AppLibMsg $LibMsg $CoreMsg $KernelMsg
	    $SilentMsg $SparseMsg $VerboseMsg $NoisyMsg);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw (UIMsg MetaMsg AppMsg AppLibMsg LibMsg CoreMsg KernelMsg
	      SilentMsg SparseMsg VerboseMsg NoisyMsg);

@EXPORT_OK = qw (message warning error fatal client);

# This line must not be broken (development)
$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

## FIXME: These are duplicated from the error library.
##        They should be read from the library to avoid duplication, 
##        although it is unlikely that any changes to these codes be made.
$UIMsg = 1;
$MetaMsg = 2;
$AppMsg = 3;
$AppLibMsg = 4;
$LibMsg = 5;
$CoreMsg = 6;
$KernelMsg = 7;

$SilentMsg = 0;
$SparseMsg = 1;
$VerboseMsg = 2;
$NoisyMsg = 3;

# Must set this to a non-empty string, in case this module is used from
# a script instead than a task. Scripts do not call SAS::error::client(myname).
my $client = "-";

sub client {
    if(my $x = shift){
	$client = $x;
    }
    return $client;
}

sub message {
  my ($msgLayer, $msgLevel, $msg) = @_;
  system("saserrstr -m $client $msgLayer $msgLevel \"$msg\"");
  my $x = $? >> 8;
  if($x){
    SAS::error::fatal("InternalError","SAS::error::message failed");
  }
}

sub warning {
  my ($code, $msg) = @_;
  system("saserrstr -w $client $code \"$msg\"");
  my $x = $? >> 8;
  if($x){
    SAS::error::fatal("InternalError","SAS::error::warning failed");
  }
}

sub error {
    my ($code, $msg) = @_;
    system("saserrstr -e $client $code \"$msg\"");
    exit(1);
}

sub fatal {
    my ($code, $msg) = @_;
    system("saserrstr -f $client $code \"$msg\"");
    exit(1);
}

1;

__END__


=head1 NAME

SAS::error - provide access to the SAS parameter interface

=head1 SYNOPSIS

    use SAS::error;

    message($msgLayer, $msgLevel, $msg);
    error($code, $msg);
    warning($code, $msg);
    fatal($code, $msg);

=head1 DESCRIPTION

C<SAS::error> provides access to the SAS error library. In the
following it is assumed that the reader understands the SAS error
library.

The modules exports 4 functions similar to those available in the SAS
error library: C<message>, C<error>, C<warning>, and C<fatal>.

C<msgLayer> can be one of: $UIMsg, $MetaMsg, $AppMsg, $AppLibMsg,
$LibMsg, $CoreMsg, $KernelMsg. Normal tasks should use $AppMsg.

C<msgLevel> can be one of: $SilentMsg, $SparseMsg, $VerboseMsg,
$NoisyMsg.

For details on the message levels and layers you are referred to the
help for the error library: B<sashelp --doc=error>.


=head1 SEE ALSO

The following perl modules: DAL, SAS, SAS::param.

The SAS documentation.

=head1 AUTHOR

 Giuseppe Vacanti

=cut
