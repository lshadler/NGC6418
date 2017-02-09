package DAL::table;

use strict;
use Carp;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);

use DAL_C_lib;
use DAL::pointer;
use DAL::column;
use DAL::attribute;
use DAL::Options;

require Exporter;
require DAL;
@ISA = qw(DAL Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

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


sub release {
  my $self = shift;
  &DAL_C_lib::releaseTable($self->ptr());
}

sub mode {
  my $self = shift;
  &DAL_C_lib::mode($self->ptr());
}

sub rows {
  my $self = shift;
  &DAL_C_lib::numberOfRowsOfTable($self->ptr());
}

sub columns {
  my $self = shift;
  &DAL_C_lib::numberOfColumns($self->ptr());
}

sub column {
    my $tb = shift;
    my %params = @_;
    my $self = DAL::column->_new;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $ptr = &DAL_C_lib::columnWithName($tb->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;
}

sub name {
  my $self = shift;
  &DAL_C_lib::nameOfTable($self->ptr);
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
    &DAL_C_lib::renameTable($self->ptr(), $p->{'newname'});
}
# -- label
sub label {
    my $self = shift;
    return &DAL_C_lib::tableLabel($self->ptr());
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
    &DAL_C_lib::relabelTable($self->ptr(), $p->{'newlabel'});
}


sub addComment  {
  my $self = shift;
  my %params = @_;
  my $opt = DAL::Options->new({
      'value' => '',
  });
  $opt->options(\%params);
  my $p = $opt->current();
  &DAL_C_lib::addCommentToTable($self->ptr, $p->{'value'});
}

# -- comments

sub comments {
    my $self = shift;
    &DAL_C_lib::numberOfCommentsOfTable($self->ptr);
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
    &DAL_C_lib::commentOfTable($self->ptr, $p->{'position'});
}

# -- historys

sub historys {
    my $self = shift;
    &DAL_C_lib::numberOfHistorysOfTable($self->ptr);
}

# -- comment

sub history {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'position' => 0,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::historyOfTable($self->ptr, $p->{'position'});
}


sub hasColumn {
  my $self = shift;
  my %params = @_;
  my $opt = DAL::Options->new({
      'name' => undef,
  });
  $opt->options(\%params);
  my $p = $opt->current();
  &DAL_C_lib::tableHasColumn($self->ptr, $p->{'name'});
}

sub addColumn {
  my $tb = shift;
  my %params = @_;
  my $self = DAL::column->_new;
  my $opt = DAL::Options->new({
      'name' => undef,
      'datatype' => $DAL::REAL32,
      'label' => '',
      'units' => '',
      'dimensions' => [1],
      'position' => -1,
  });
  $opt->options(\%params);
  my $p = $opt->current();
  my $ndims = @{ $p->{'dimensions'} };
  my $v = DAL::pointer->new('long', $ndims);
  $v->set($p->{'dimensions'});
  my $ptr = &DAL_C_lib::addColumn($tb->ptr, $p->{'name'}, $p->{'datatype'},
				  $p->{'label'}, $p->{'units'}, $ndims,
				  $v->ptr, $p->{'position'});
  $v->free;
  $self->ptr($ptr);
  return $self;
}

# -- delete

sub deleteColumn {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::deleteColumnWithName($self->ptr, $p->{'name'});
}


# -- attribute
sub attribute {
    my $ds = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    my $self = DAL::attribute->_new;
    my $ptr = &DAL_C_lib::tableAttributeWithName($ds->ptr, $p->{'name'});
    $self->ptr($ptr);
    return $self;   
}


sub hasAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::tableHasAttribute($self->ptr, $p->{'name'});
}

sub deleteAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::deleteTableAttributeWithName($self->ptr, $p->{'name'});
}

sub addAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
	'datatype' => $DAL::REAL32,
	'value' => 0,
	'units' => '',
	'label' => '',
    });
    $opt->options(\%params);
    my $p = $opt->current();

    foreach($p->{'datatype'}) {
	($_ == $DAL::BOOL) and do {
	    &DAL_C_lib::setBoolTableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, #$p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::INT8) and do {
	    &DAL_C_lib::setInt8TableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::INT16) and do {
	    &DAL_C_lib::setInt16TableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::INT32) and do {
	    &DAL_C_lib::setInt32TableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::REAL32) and do {
	    &DAL_C_lib::setReal32TableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::REAL64) and do {
	    &DAL_C_lib::setReal64TableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	};			     
	($_ == $DAL::STRING) and do {
	    &DAL_C_lib::setStringTableAttribute($self->ptr, $p->{'name'},
						$p->{'value'}, #$p->{'units'},
						$p->{'label'});
	};			     
    }
}

1;

