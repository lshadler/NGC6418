package DAL::dataset;

use strict;
use Carp;

use DAL_C_lib;
use DAL::pointer;
use DAL::table;
use DAL::array;
use DAL::attribute;
use DAL::Options;

use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DAL;

@ISA = qw(DAL Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Preloaded methods go here.

# -- constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;
    my $self = {};
    bless $self, $class;
    $self->ptr(undef);
    my $opt = DAL::Options->new({
	'name' => undef,
	'accessmode' => $DAL::CREATE,
	'memorymodel' => $DAL::USENV,
    });

    $opt->synonyms({
	mode => 'accessmode',
    });
    $opt->options(\%params);
    my $p = $opt->current();

    my $ds = &DAL_C_lib::dataSet($p->{'name'}, $p->{'accessmode'}, $p->{'memorymodel'});
    $self->ptr($ds);
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
    &DAL_C_lib::releaseDataSet($self->ptr());
}

# -- name
sub name {
    my $self = shift;
    &DAL_C_lib::nameOfDataSet($self->ptr());
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
    &DAL_C_lib::renameDataSet($self->ptr(), $p->{'newname'});
}

# -- label
sub label {
    my $self = shift;
    return &DAL_C_lib::dataSetLabel($self->ptr());
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
    &DAL_C_lib::relabelDataSet($self->ptr(), $p->{'newlabel'});
}

# -- mode
sub mode {
    my $self = shift;
    &DAL_C_lib::mode($self->ptr());
}

# -- addComment
sub addComment {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'value' => '',
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::addCommentToDataSet($self->ptr(), $p->{'value'});
}

# -- addHistory
sub addHistory {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'value' => 'Empty history',
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::addHistorygToDataSet($self->ptr(), $p->{'value'});
}

# -- comments
sub comments {
    my $self = shift;
    &DAL_C_lib::numberOfCommentsOfDataSet($self->ptr());
}

# -- comment
sub comment {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'position' => 0,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::commentOfDataSet($self->ptr(), $p->{'position'});
}

# -- history
sub historys {
    my $self = shift;
    &DAL_C_lib::numberOfHistorysOfDataSet($self->ptr());
}

sub history {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'position' => -1,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::historyOfDataSet($self->ptr(), $p->{'position'});
}

# -- addTable
# Table constructor
sub addTable {
    my $ds = shift;
    my %params = @_;
    my $self = DAL::table->_new;
    my $opt = DAL::Options->new({
	'name' => undef,
	'nrows' => 0,
	'label' => '',
	'position' => -1,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $ptr = &DAL_C_lib::addTable($ds->ptr(), $p->{'name'},
				   $p->{'nrows'}, $p->{'label'},
				   $p->{'position'});
    $self->ptr($ptr);
    return $self;
}

sub table {
    my $ds = shift;
    my %params = @_;
    my $self = DAL::table->_new;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();

    my $ptr = &DAL_C_lib::tableWithName($ds->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;
}


# -- addArray
# Array constructor
sub addArray {
    my $ds = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
	'datatype' => $DAL::REAL32,
	'dimensions' => [0],
	'label' => '',
	'units' => '',
	'position' => -1,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $self = DAL::array->_new;
    my $ndims = @{ $p->{'dimensions'} };
    my $v = DAL::pointer->new("long", $ndims);
    $v->set($p->{'dimensions'});
    my $ptr = &DAL_C_lib::addArray($ds->ptr(), $p->{'name'}, $p->{'datatype'}, 
				   $ndims, $v->ptr(), $p->{'label'},
				   $p->{'units'}, $p->{'position'});
    $v->free;
    $self->ptr($ptr);
    return $self;
}

sub array {
    my $ds = shift;
    my %params = @_;
    my $self = DAL::array->_new;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $ptr = &DAL_C_lib::arrayWithName($ds->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;
}

# -- block
sub blocks {
    my $self = shift;
    &DAL_C_lib::numberOfBlocks($self->ptr());
}

sub hasBlock {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::dataSetHasBlock($self->ptr(), $p->{'name'});
}

sub deleteBlock {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::deleteBlockWithName($self->ptr(), $p->{'name'});
}


# __FIXME__ these should be implemented with the appropriate call
sub deleteTable {
    my $self = shift;
    $self->deleteBlock(@_);
}
sub deleteArray {
    my $self = shift;
    $self->deleteBlock(@_);
}

sub hasTable {
    my $self = shift;
    $self->hasBlock(@_);
}
sub hasArray {
    my $self = shift;
    $self->hasBlock(@_);
}


# -- attribute
sub hasAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::dataSetHasAttribute($self->ptr(), $p->{'name'});
}

sub deleteAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::deleteDataSetAttributeWithName($self->ptr(), $p->{'name'});
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
	    &DAL_C_lib::setBoolDataSetAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, #$p->{'units'},
						$p->{'label'});
	    next;
	};			     
	($_ == $DAL::INT8) and do {
	    &DAL_C_lib::setInt8DataSetAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	    next;
	};			     
	($_ == $DAL::INT16) and do {
	    &DAL_C_lib::setInt16DataSetAttribute($self->ptr(), $p->{'name'},
						 $p->{'value'}, $p->{'units'},
						 $p->{'label'});
	    next;
	};			     
	($_ == $DAL::INT32) and do {
	    &DAL_C_lib::setInt32DataSetAttribute($self->ptr(), $p->{'name'},
						 $p->{'value'}, $p->{'units'},
						 $p->{'label'});
	    next;
	};			     
	($_ == $DAL::REAL32) and do {
	    &DAL_C_lib::setReal32DataSetAttribute($self->ptr(), $p->{'name'},
						  $p->{'value'}, $p->{'units'},
						  $p->{'label'});
	    next;
	};			     
	($_ == $DAL::REAL64) and do {
	    &DAL_C_lib::setReal64DataSetAttribute($self->ptr(), $p->{'name'},
						  $p->{'value'}, $p->{'units'},
						  $p->{'label'});
	    next;
	};			     
	($_ == $DAL::STRING) and do {
	    &DAL_C_lib::setStringDataSetAttribute($self->ptr(), $p->{'name'},
						  $p->{'value'}, #$p->{'units'},
						  $p->{'label'});
	    next;
	};
	do {confess "Cannot match data type.\n";} ;
	
    }
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
    my $ptr = &DAL_C_lib::dataSetAttributeWithName($ds->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;   
}

1;

