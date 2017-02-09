#
# Giuseppe Vacanti, European Space Agency, 1998-1999
#
package DAL::array;

use strict;
use Carp;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use DAL_C_lib;
use DAL::pointer;
use DAL::attribute;
use DAL::Options;

require Exporter;
require DAL;

@ISA = qw(DAL Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Preloaded methods go here.

sub _new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;
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

# -- release
sub release {
    my $self = shift;
    &DAL_C_lib::releaseArray($self->ptr());
}

# -- mode
sub mode {
    my $self = shift;
    &DAL_C_lib::mode($self->ptr());
}

# -- comment
sub addComment  {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'value' => '',
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::addCommentToArray($self->ptr(), $p->{'value'});
}

sub comments {
    my $self = shift;
    &DAL_C_lib::numberOfCommentsOfArray($self->ptr());
}

sub comment {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'position' => 0,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::commentOfArray($self->ptr(), $p->{'position'});
}

# -- history
sub addHistory  {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'value' => 'Empty history',
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::addHistoryToArray($self->ptr(), $p->{'value'});
}

sub historys {
    my $self = shift;
    &DAL_C_lib::numberOfHistorysOfArray($self->ptr());
}

sub history {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'position' => -1,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::historyOfArray($self->ptr(), $p->{'position'});
}

# -- name
sub name {
    my $self = shift;
    &DAL_C_lib::nameOfArray($self->ptr());
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
    &DAL_C_lib::renameArray($self->ptr(), $p->{'newname'});
}

# -- label
sub label {
    my $self = shift;
    return &DAL_C_lib::arrayLabel($self->ptr());
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
    &DAL_C_lib::relabelArray($self->ptr(), $p->{'newlabel'});
}

# -- dimensions
sub dimensions {
    my $self = shift;
    my $ndims = &DAL_C_lib::numberOfDimensionsOfArray($self->ptr());
    if (wantarray) {
	my $p = DAL::pointer->new('long', $ndims);
	$p->ptr(&DAL_C_lib::dimensionsOfArray($self->ptr()));
	return $p->value();
    } else {
	return $ndims;
    }
}

# -- elements
sub elements {
    my $self = shift;
    &DAL_C_lib::numberOfElementsOfArray($self->ptr());
}

# -- type
sub type {
    my $self = shift;
    &DAL_C_lib::arrayDataType($self->ptr());
}

# -- units
sub units {
    my $self = shift;
    &DAL_C_lib::arrayUnits($self->ptr());
}

# -- attribute
sub deleteAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::deleteArrayAttributeWithName($self->ptr(), $p->{'name'});
}

sub addAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
	'datatype' => $DAL::INT32,
	'value' => 0,
	'units' => '',
	'label' => '',
    });
    $opt->options(\%params);
    my $p = $opt->current();

    foreach($p->{'datatype'}) {
	($_ == $DAL::BOOL) and do {
	    &DAL_C_lib::setBoolArrayAttribute($self->ptr(), $p->{'name'},
					      $p->{'value'}, #$p->{'units'},
					      $p->{'label'});
	};			     
	($_ == $DAL::INT8) and do {
	    &DAL_C_lib::setInt8ArrayAttribute($self->ptr(), $p->{'name'},
					      $p->{'value'}, $p->{'units'},
					      $p->{'label'});
	};			     
	($_ == $DAL::INT16) and do {
	    &DAL_C_lib::setInt16ArrayAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::INT32) and do {
	    &DAL_C_lib::setInt32ArrayAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::REAL32) and do {
	    &DAL_C_lib::setReal32ArrayAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::REAL64) and do {
	    &DAL_C_lib::setReal64ArrayAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::STRING) and do {
	    &DAL_C_lib::setStringArrayAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, #$p->{'units'},
						$p->{'label'});
	};			     
    }
}

sub hasAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::arrayHasAttribute($self->ptr(), $p->{'name'});
}

sub attribute {
    my $ds = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $self = DAL::attribute->_new;
    my $ptr = &DAL_C_lib::arrayAttributeWithName($ds->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;   
}


# -- data

sub data {
    my $ar = shift;
    my $nelems = $ar->elements;
    my $Ctype;
    my $dataPtr;
    my $swigType = sprintf "%s *",$ar->mapType();
    foreach($ar->type()) {
	($_ == $DAL::INT8) and do {
	    $dataPtr = &DAL_C_lib::int8ArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::INT16) and do {
	    $dataPtr = &DAL_C_lib::int16ArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::INT32) and do {
	    $dataPtr = &DAL_C_lib::int32ArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::REAL32) and do {
	    $dataPtr = &DAL_C_lib::real32ArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::REAL64) and do {
	    $dataPtr = &DAL_C_lib::real64ArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::BOOL) and do {
	    $dataPtr = &DAL_C_lib::boolArrayData($ar->ptr());
	    last;
	} ;
	($_ == $DAL::STRING) and do {
	    $dataPtr = &DAL_C_lib::stringArrayData($ar->ptr());
	    last;
	} ;

	croak("Unknown array type.");

    }

    my $self = DAL::ptr_manipulator->new($dataPtr, $swigType);

}

1;

