#  Giuseppe Vacanti (cosine science & computing bv)
#  January 31, 2003
# 
#   $Id: SAS.pm,v 1.3 2003/02/11 10:19:34 gvacanti Exp $
#
package SAS;

require 5.005;

use Env;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT
	    $UIMsg $MetaMsg $AppMsg $AppLibMsg $LibMsg $CoreMsg $KernelMsg
	    $SilentMsg $SparseMsg $VerboseMsg $NoisyMsg);

require Exporter;

@ISA = qw(Exporter);

# This line must not be broken (development)
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 


use SAS::param;
use SAS::error;

## Made available here again for backward compatibility.
$UIMsg = $SAS::error::UIMsg;
$MetaMsg = $SAS::error::MetaMsg;
$AppMsg = $SAS::error::AppMsg;
$AppLibMsg = $SAS::error::AppLibMsg;
$LibMsg = $SAS::error::LibMsg;
$CoreMsg = $SAS::error::CoreMsg;
$KernelMsg = $SAS::error::KernelMsg;

$SilentMsg = $SAS::error::SilentMsg;
$SparseMsg = $SAS::error::SparseMsg;
$VerboseMsg = $SAS::error::VerboseMsg;
$NoisyMsg = $SAS::error::NoisyMsg;



# Delegate error i/f to SAS::error
sub message {
  SAS::error::message(@_);
}

sub warning {
  SAS::error::warning(@_);
}

sub error {
  SAS::error::error(@_);
}

sub fatal {
  SAS::error::fatal(@_);
}

1;


__END__


=head1 NAME

SAS - provide access to the SAS perl facilities

=head1 SYNOPSIS

    use SAS;

=head1 DESCRIPTION

C<SAS> provides access to a number of SAS libraries. C<SAS> is simply
a wrapper package that makes available all of the functionality needed
to write SAS tasks in Perl.

=head2 Parameter interface

The functions described in C<SAS::param> and C<SAS::error> are automatically available.

=head2 Error library

The following functions are available:

=over 4

=item SAS::message($msgLayer, $msgLevel, $msg)

where 

$msgLayer can be one of $SAS::UIMsg, $SAS::MetaMsg, $SAS::AppMsg,
$SAS::AppLibMsg, $SAS::LibMsg, $SAS::CoreMsg, $SAS::KernelMsg.

$msgLevel can be one of $SAS::SilentMsg; $SAS::SparseMsg,
$SAS::VerboseMsg, $SAS::NoisyMsg

=item SAS::warning($code, $msg)

=item SAS::error($code, $msg)

=item SAS::fatal($code, $msg)

$msg is a string associated with the
message/warning/error/fatal. $code is anotyher string, uniquely
labelling the warning/error/fatal.

=back

=head1 SEE ALSO

SAS::error, SAS::param and the SAS documentation.

=head1 AUTHOR

Giuseppe Vacanti

=cut

