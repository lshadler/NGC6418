# 26 Feb 2013 (EC):
#   - modify set and value so that the type and length are passed to
#     the DAL_C_lib_wrap routines

package DAL::ptr_manipulator;

require 5;

use DAL_C_lib;
use Carp;

use strict;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak('Usage: new($address, $swigtype)') if (@_ < 1 || @_ > 2);

    my $p = shift;
    my $t = shift || undef;
    
    my $self = {};

    $self->{_original_pointer} = $p;
    $self->{_swig_type} = $t;

    my $np;

    $t ? $np = $p : $np = &DAL_C_lib::ptrcast($p, $t);

    $self->{_pointer} = $np; # this is what we use in practice

    bless $self, $class;

}
# This one catches any calls to non existing methods.
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method =~ /DESTROY/;
    confess "Unknown method ->$method()\n";
}

sub _op {
    my $self = shift;
    return $self->{_original_pointer};
}

sub _p {
    my $self = shift;
    return $self->{_pointer};
}

sub _st {
    my $self = shift;
    return $self->{_swig_type};
}

sub set {
    # hack by EC

    # self, value, index, type
    my @arglist = @_;
    my $self = shift;
    my $value = shift;
   
    $arglist[0] = $self->_p;

    if(ref($self->_op) ne "boolPtr" and ref($self->_op) ne "int8Ptr"){ 
	$arglist[1] = $value;
	&DAL_C_lib::ptrset(@arglist);
    } else {
	$value = pack('c',$value);
	$arglist[1] = $value;
	&DAL_C_lib::ptrset(@arglist);
    }
}

sub value {
    # hack by EC

    # self, index, type, len
    my @arglist = @_;
    my $self = shift;

    $arglist[0] = $self->_p;

    my $value;

    if(ref($self->_op) ne "boolPtr" and ref($self->_op) ne "int8Ptr"){ 
	$value = &DAL_C_lib::ptrvalue(@arglist);
    } else {
	$value = &DAL_C_lib::ptrvalue(@arglist);
	$value = unpack('c',$value);
    }
    return $value;
}
    
1;

