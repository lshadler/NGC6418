#-*- perl -*-
package DAL::pointer;

require 5.004;

use DAL_C_lib;

use strict;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;

@ISA = qw(Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 


# Preloaded methods go here.

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    die "Usage\n" if (@_ != 2);

    my ($type, $nelems) = @_;
    my $self = {};

#    die "Invalid pointer type $type\n" if not exists $TRANSLATE{$type};
#    my $stype = $TRANSLATE{$type} || $type;

    bless $self, $class;
    $self->{'_index'} = 0;
    $self->{'_nelems'} = $nelems || 1;
    $self->{'_type'} = $type;
#    $self->{'_daltype'} = $type;
    $self->{'_ptr'} = &DAL_C_lib::ptrcreate($type, 0,
					    $self->{'_nelems'});
    return $self;
}


sub free {
    my $self = shift;
    &DAL_C_lib::ptrfree($self->{'_ptr'});
    return;
}

#sub DESTROY {
#    my $self = shift;
#    $self->free;
#};

sub set {
    my $self = shift;
    my $ra = shift || croak ;

    foreach(@$ra) {
        if($self->{'_index'} >= $self->{'_nelems'}) {
            warn "Pointer roll over. Index reset to 0.\n";
	    printf "Affected pointer is %s\n",$self->ptr;
            $self->reset();
        }
	
 	my $value = $_;

# 	foreach($self->daltype) {
	    
# 	    /bool|int8/ and do {
# 		$value = pack('c',$value);
# 		last;
# 	    } ;

# 	    /dstring/ and do {
# 		$value = $self->value . $value;
# 		last ;
# 	    }
# 	}
	&DAL_C_lib::ptrset($self->ptr, $value, $self->{'_index'}++,
			   $self->type);
    }
    return;
}

sub value {
    my $self = shift;

    my @list;
    if(wantarray) {
        $self->reset();
        my $i;
        for($i=0; $i<$self->{'_nelems'}; $i++) {
            my $v = $self->value();
            push @list, $v;
        }
        $self->reset();
        return @list;
    } else {

        return  &DAL_C_lib::ptrvalue($self->ptr, $self->{'_index'}++,
				     $self->type);
    }
}

sub ptr {
    my $self = shift;
    return $self->{'_ptr'} unless @_;
    $self->{'_ptr'} = shift;
    return;
}

sub type {
    my $self = shift;
    return $self->{'_type'};
}

# sub daltype {
#     my $self = shift;
#     return $self->{'_daltype'};
# }

sub cast {
    my $self = shift;
    my $newtype = shift || croak "arguments";
    $self->{'_ptr'} = &DAL_C_lib::ptrcast($self->{'_ptr'}, $newtype);
    $self->{'_type'} = $newtype;
}

sub reset {
    my $self = shift;
    $self->{'_index'} = 0;
}
        
1;

