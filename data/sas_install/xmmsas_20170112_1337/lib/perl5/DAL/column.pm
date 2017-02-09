#
# Giuseppe Vacanti, European Space Agency, 1998-1999
#
package DAL::column;

use strict;
use Carp;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT @EXPORT_OK);

use DAL_C_lib;
use DAL::pointer;
use DAL::ptr_manipulator;
use DAL::attribute;
use DAL::Options;

require Exporter;
require DAL;
@ISA = qw(DAL Exporter);

# This line must not be broken
$VERSION = do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# private constructor
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
    my $self = shift or croak();
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
    &DAL_C_lib::releaseColumn($self->ptr());
}

# -- name
sub name {
    my $self = shift;
    &DAL_C_lib::nameOfColumn($self->ptr());
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
    &DAL_C_lib::renameColumn($self->ptr(), $p->{'newname'});
}

# -- label
sub label {
    my $self = shift;
    return &DAL_C_lib::columnLabel($self->ptr());
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
    &DAL_C_lib::relabelColumn($self->ptr(), $p->{'newlabel'});
}

# -- mode
sub mode {
    my $self = shift;
    &DAL_C_lib::mode($self->ptr());
}

# -- dimensions
sub dimensions {
    my $self = shift;
    my $ndims = &DAL_C_lib::numberOfDimensionsOfColumn($self->ptr());
    if (wantarray) {
	my $p = DAL::pointer->new('long', $ndims);
	$p->ptr(&DAL_C_lib::dimensionsOfColumn($self->ptr()));
	return $p->value;
    } else {
	return $ndims;
    }
}

sub elements {
  my $self = shift;
  &DAL_C_lib::numberOfElementsOfColumn($self->ptr());
}

# -- units
sub units {
    my $self = shift;
    &DAL_C_lib::columnUnits($self->ptr());
}

# -- rows
sub rows {
    my $self = shift;
    &DAL_C_lib::numberOfRowsOfColumn($self->ptr());
}

# -- type
sub type {
    my $self = shift;
    &DAL_C_lib::columnDataType($self->ptr());
}

# -- data
sub data {
    my $co = shift;
    my $nelems = $co->elements;
    my $nrows = $co->rows;
    my $size = $nelems * $nrows;
    my $Ctype;

    my $dataPtr;
    my $swigType = sprintf "%s *", $co->mapType();

    foreach($co->type()) {
	($_ == $DAL::INT8) and do {
	    $dataPtr = &DAL_C_lib::int8ColumnData($co->ptr());
	    last;
	};
	($_ == $DAL::INT16) and do {
	    $dataPtr = &DAL_C_lib::int16ColumnData($co->ptr());
	    last;
	};
	($_ == $DAL::INT32) and do {
	    $dataPtr = &DAL_C_lib::int32ColumnData($co->ptr());
	    last;
	};
	($_ == $DAL::REAL32) and do {
	  $dataPtr = &DAL_C_lib::real32ColumnData($co->ptr());
	  last;
	};
	($_ == $DAL::REAL64) and do {
	    $dataPtr = &DAL_C_lib::real64ColumnData($co->ptr());
	    last;
	};
	($_ == $DAL::BOOL) and do {
	    $dataPtr = &DAL_C_lib::boolColumnData($co->ptr());
	    last;
	};
	($_ == $DAL::STRING) and do {
	    $dataPtr = &DAL_C_lib::stringColumnData($co->ptr());
	    last;
	};

	croak("Unknown column type.");
	
    }

    my $self = DAL::ptr_manipulator->new($dataPtr, $swigType);
    
}

sub setCellSize {
  my $co = shift;
  my %params = @_;
  my $opt = DAL::Options->new({
			       'row' => 0,
			       'size' => 1,
			       });
  $opt->options(\%params);
  my $p = $opt->current();
  my $row = $p->{'row'};
  my $size = $p->{'size'};
  &DAL_C_lib::setCellSize($co->ptr(), $row, $size);
}

sub cellSize {
  my $co = shift;
  my %params = @_;
  my $opt = DAL::Options->new({
			       'row' => 0,
			       });
  $opt->options(\%params);
  my $p = $opt->current();
  my $row = $p->{'row'};
  &DAL_C_lib::cellSize($co->ptr(), $row);
}


sub cellData {
  my $co = shift;
  my %params = @_;
  my $opt = DAL::Options->new({
			       'row' => 0,
			       });
  $opt->options(\%params);
  my $p = $opt->current();
  my $row = $p->{'row'};
  my $dataptr;
  my $swigType = sprintf "%s *", $co->mapType();
  my $dataPtr;

  foreach($co->type()) {
    ($_ == $DAL::INT8) and do {
      $dataPtr = &DAL_C_lib::int8CellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::INT16) and do {
      $dataPtr = &DAL_C_lib::int16CellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::INT32) and do {
      $dataPtr = &DAL_C_lib::int32CellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::REAL32) and do {
      $dataPtr = &DAL_C_lib::real32CellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::REAL64) and do {
      $dataPtr = &DAL_C_lib::real64CellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::BOOL) and do {
      $dataPtr = &DAL_C_lib::boolCellData($co->ptr(), $row);
      last;
    };
    ($_ == $DAL::STRING) and do {
      $dataPtr = &DAL_C_lib::stringCellData($co->ptr(), $row);
      last;
    };
    
    croak("Unknown column type.");
    
  }

  my $self = DAL::ptr_manipulator->new($dataPtr, $swigType);

}

sub isVariableLength {
  my $self = shift;
  return &DAL_C_lib::cellType($self->ptr()) == $DAL_C_lib::Variable;
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
    &DAL_C_lib::columnHasAttribute($self->ptr(), $p->{'name'});
}

sub deleteAttribute {
    my $self = shift;
    my %params = @_;
    my $opt = DAL::Options->new({
	'name' => undef,
    });
    $opt->options(\%params);
    my $p = $opt->current();
    &DAL_C_lib::columnAttributeWithName($self->ptr(), $p->{'name'});
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
	    &DAL_C_lib::setBoolColumnAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, #$p->{'units'},
						$p->{'label'});
	    last;
	};			     
	($_ == $DAL::INT8) and do {
	    &DAL_C_lib::setInt8ColumnAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	    last;
	};			     
	($_ == $DAL::INT16) and do {
	    &DAL_C_lib::setInt16ColumnAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	    last;
	};			     
	($_ == $DAL::INT32) and do {
	    &DAL_C_lib::setInt32ColumnAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	    last;
	};			     
	($_ == $DAL::REAL32) and do {
	    &DAL_C_lib::setReal32ColumnAttribute($self->ptr(), $p->{'name'},
						$p->{'value'}, $p->{'units'},
						$p->{'label'});
	    last;
	};			     
	($_ == $DAL::REAL64) and do {
	    &DAL_C_lib::setReal64ColumnAttribute($self->ptr(), $p->{'name'},
						 $p->{'value'}, $p->{'units'},
						 $p->{'label'});
	    last;
	};			     
	($_ == $DAL::STRING) and do {
	    &DAL_C_lib::setStringColumnAttribute($self->ptr(), $p->{'name'},
						 $p->{'value'}, $p->{'units'},
						 $p->{'label'});
	    last;
	};
	
	croak("Unknow column type.");
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
    my $ptr = &DAL_C_lib::columnAttributeWithName($ds->ptr(), $p->{'name'});
    $self->ptr($ptr);
    return $self;   
}

1;

