package DAL::attribute;

use strict;
use Carp;

use DAL_C_lib;
use DAL::pointer;
use DAL::ptr_manipulator;

use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DAL;

@ISA = qw(DAL Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Preloaded methods go here.

sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->ptr(undef);
    return $self;
}

sub ptr {
    my $self = shift;
    if (@_) { $self->{'PTR'} = shift }
    return $self->{'PTR'};
}

# This one catches any calls to non existing methods.
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method =~ /DESTROY/;
    confess "Unknown method ->$method()\n";
}

# -- assignment operator
sub set {
    my $self = shift;
    my $value = shift;
    foreach($self->type()) {

	print "This is set: ",$self->type(),"\n";

	($_ == $DAL::INT8) and do {	    
	    &DAL_C_lib::setInt8Attribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};
	($_ == $DAL::INT16) and do {	    
	    &DAL_C_lib::setInt16Attribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};
	($_ == $DAL::INT32) and do {	    
	    &DAL_C_lib::setInt32Attribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};
	($_ == $DAL::REAL32) and do {	    
	    &DAL_C_lib::setReal32Attribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};
	($_ == $DAL::REAL64) and do {	    
	    &DAL_C_lib::setReal64Attribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};
	($_ == $DAL::BOOL) and do {	    
	    &DAL_C_lib::setBoolAttribute($self->ptr(),$value, $self->label());
	    last;
	};
	($_ == $DAL::STRING) and do {	    
	    &DAL_C_lib::setStringAttribute($self->ptr(),$value, $self->units(), $self->label());
	    last;
	};

	croak("Unknown attribute type.");
	
    }
}

# -- units
sub units {
    my $self = shift;
    &DAL_C_lib::attributeUnits($self->ptr());
}

# -- name
sub name {
    my $self = shift;
    &DAL_C_lib::nameOfAttribute($self->ptr());
}

# -- rename
sub rename {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'newname' => undef,
    });
    $opt->synonyms({
	'name' => 'newname',
    });
    $opt->options(\%params);
    my $p = $opt->current();    
    &DAL_C_lib::renameAttribute($self->ptr(), $p->{'newname'});
}

# -- label
sub label {
    my $self = shift;
    return &DAL_C_lib::attributeLabel($self->ptr());
}

# -- relabel
sub relabel {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'newlabel' => undef,
    });
    $opt->synonyms({
	'label' => 'newlabel',
    });
    $opt->options(\%params);
    my $p = $opt->current();    
    &DAL_C_lib::relabelAttribute($self->ptr(), $p->{'newlabel'});
}

# -- data methods
sub asBool {
    my $self = shift;
    &DAL_C_lib::boolAttribute($self->ptr());
}

sub asInt8 {
    my $self = shift;
    &DAL_C_lib::int8Attribute($self->ptr());
}

sub asInt16 {
    my $self = shift;
    &DAL_C_lib::int16Attribute($self->ptr());
}

sub asInt32 {
    my $self = shift;
    &DAL_C_lib::int32Attribute($self->ptr());
}

sub asReal32 {
    my $self = shift;
    &DAL_C_lib::real32Attribute($self->ptr());
}

sub asReal64 {
    my $self = shift;
    &DAL_C_lib::real64Attribute($self->ptr());
}

sub asString {
    my $self = shift;
    &DAL_C_lib::stringAttribute($self->ptr());
}

# -- type
sub type {
    my $self = shift;
    &DAL_C_lib::attributeDataType($self->ptr());
}

1;

