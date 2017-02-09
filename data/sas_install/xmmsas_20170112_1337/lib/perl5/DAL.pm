#
# DAL --
#
# G. Vacanti, ESA, 1998-2000
#
package DAL;

require 5.004;

use Env;
use Carp;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA @EXPORT @EXPORT_OK
            $BOOL $INT8 $INT16 $INT32 $REAL32 $REAL64 $STRING
	    $READ $CREATE $MODIFY $TEMP
	    $HI $LO $HILO $USENV
	    );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
             BOOL INT8 INT16 UINT16 INT32 UINT32 REAL32 REAL64 STRING
             READ CREATE MODIFY TEMP ASPARENT
	     HI LO HILO USENV
            );

@EXPORT_OK = qw(
                TABLETYPE ARRAYTYPE
               );


# This line must not be broken (development)
##$VERSION = do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Releases.
$VERSION = "1.22";

use DAL_C_lib;

##use DAL::lib;
use DAL::dataset;
use DAL::column;
use DAL::array;
use DAL::pointer;
use DAL::attribute;
use DAL::Options;

# Constants to be exported from the C library
$BOOL   = $DAL_C_lib::Bool;
$INT8   = $DAL_C_lib::Int8;
$INT16  = $DAL_C_lib::Int16;
$INT32  = $DAL_C_lib::Int32;
##$UINT16 = $DAL_C_lib::Uint16;
##$UINT32 = $DAL_C_lib::Uint32;
$REAL32 = $DAL_C_lib::Real32;
$REAL64 = $DAL_C_lib::Real64;
$STRING = $DAL_C_lib::DString;

$READ     = $DAL_C_lib::Read;
$CREATE   = $DAL_C_lib::Create;
$MODIFY   = $DAL_C_lib::Modify;
$TEMP     = $DAL_C_lib::Temp;

$HI        = $DAL_C_lib::High;
$LO        = $DAL_C_lib::Low;
$HILO      = $DAL_C_lib::HighLow;
$USENV     = $DAL_C_lib::UseEnvironment;

### These are not used at the moment
###$ASPARENT = $DAL_C_lib::AsParent;
###$TABLETYPE = $DAL_C_lib::TableType;
###$ARRAYTYPE = $DAL_C_lib::ArrayType;

my %typeMap = (
	       $BOOL    => 'char',
	       $INT8    => 'char',
	       $INT16   => 'int16',
	       $INT32   => 'int32',
	       $REAL32  => 'real32',
	       $REAL64  => 'real64',
	       $STRING  => 'char'
	       );


# Register user of the package as a DAL client.
if(defined $main::VERSION) {
    &DAL_C_lib::dataServerClient("$main::0 $main::VERSION");
} else {
    &DAL_C_lib::dataServerClient("$main::0");
}

# This one catches any calls to non existing methods.
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method =~ /DESTROY/;
    confess "Unknown method ->$method()\n";
}

sub clobber {
    return &DAL_C_lib::clobber();
}

sub version {
    return $VERSION;
}

sub mapType {
    my $self = shift;
    my $dalType = $self->type();
    return $typeMap{$dalType} or confess "Don't know how to map this type.\n";
}


### These two are no longer supported.
# This registers a client with the data server.
# Private method.
# sub _register {
#     my $proto = shift;
#     my $clientName = shift;
#     &DAL_C_lib::dataServerClient($clientName);
# }
# data set constructor
# sub dataset {
#     my $proto = shift;
#     my $self = DAL::dataset->_new(@_);
#     return $self;
# }


# Autoload methods go after =cut, and are processed by the autosplit program.


=head1 NAME

  DAL - aka pedal (Perl Enhanced Data Access Layer)

=head1 SYNOPSIS

  use DAL;

  my $ds = DAL::dataset->new(-name => 'set', -mode => CREATE);
  my $tab = $ds->addTable(-name => 'table', -rows => 1234);
  my $col = $tab->addColumn(-name => 'column', -type => REAL32);

  etc.

=head1 Differences from previous releases

As of version 1.0 of the pedal, the static method

  DAL->register($string) 

is no longer supported. The corresponding actions are now carried out
by default once the `use DAL' statement is executed.

If the application defined the variable $VERSION, this will be used to
create a unique string with which the application is registered with
the DAL.

The DAL module does no longer export data type and access mode
constants into the application's name space. These constants must be
fully qualified

The pedal makes use of named parameters. These are specified like so:

  $ob->method(par1 => value, par2 => value ...);

The adoption of a new parameter handling library means that parameter
names preceeded by a dash (-par1 => value) are no longer supported.

There has been a change in nomenclature in the DAL. Previously,
tables, arrays, columns and attributes had a comment field. This is
now called label.

=head1 DESCRIPTION

The pedal is a Perl OO interface to the B<XMM Data Access Layer> (DAL)
libraries. In the following I assume that you are familiar with the
DAL data model and the terminology that goes with it.

If you have successfully built this package, you can find more about
the XMM DAL (and SAS) by following the links to the local
documentation, usually B<file://${SAS_DIR}/README.html> .

Most methods require one or more options to be set. In some cases
default values are provided. Note that in general the pedal does not
try to ensure that the parameters needed by a method are being set to
something sensible (or at all). I made the design choice to make the
Perl layer as simple as possible. That means, the parameter values are
used in the Perl code are handed down to the underlying libraries that
then decide whether this input makes sense or not.

=head2 pedal objects

In the following I shall use the following variables to label DAL
objects:

=over 4



=item *

*

$ds is a data set.



=item *

*

$tb is a table.



=item *

*

$co is a column.



=item *

*

$ar is an array.



=item *

*

$bl is a block.



=item *

*

$ob is any of the above, unless otherwise noted.

=back


=head2 pedal data types

The variable B<$datatype> is also used to indicate one of the following
constants.

=over 4



=item *

$DAL::BOOL: logical



=item *

$DAL::INT8: one-byte integer (unsigned)



=item *

$DAL::INT16: two-byte integer (signed)



=item *

$DAL::INT32: four-byte integer (signed) 



=item *

$DAL::REAL32: eight-byte float



=item *

$DAL::REAL64: sixteen-byte float



=item *

$DAL::STRING: character string

=back

=head2 pedal access modes

The variable B<$mode> is used to indicate one of the following
constants. These too are exported by default. The variable $mode
refers to the way the DAL opens a data set.

=over 4



=item *

$DAL::READ: the data set cannot be modified.



=item *

$DAL::CREATE: the data set is created if it does not exist. If it exists, it is overwritten.



=item *

$DAL::MODIFY: the data set can be modified.



=item *

$DAL::TEMP: the data set is temporary, that is it is erased once it is released.

=back

=head2 pedal memor model

The variable B<$mem> is used to indicate one of the following
constants. These too are exported by default. The variable $mem refers
to the way the DAL makes use of the available memory.

=over 4



=item *

$DAL::HI: the DAL reads all the data in memory.



=item *

$DAL::LO: the DAL reads in memory the least possible amount of
data, only when the data is actually needed.

=back

=head1 STATIC METHODS

  DAL::version(); # returns the pedal version in use.

  DAL::clobber(); # returns the clobber status.

=head1 CONSTRUCTORS

=head2 Data set contructor

=over 4



=item *

$ds = DAL::dataset->new(name => $data_set_name,
                        accessmode => $mode,
                        memorymodel => $mem); 


Defaults:

accessmode => $DAL::CREATE

memorymodel => $DAL::HI


=back


=head2  Table constructors

=over 4



=item *

$tb = $ds->addTable(name => $table_name, 
                    nrows => $n,
                    position => $p,
                    label => $label);


Defaults:

nrows => 0

position => -1 (leave it to the DAL to decide, a wise choice)

label => ''




=item *

$tb = $ds->table(name => $table_name);

Returns the named table, if it exists.


=back


=head2  Column constructors


=over 4




=item *

$co = $tb->addColumn(name => $column_name,
                           datatype => $datatype,
                           label => $string,
                           units => $string,
                           dimensions => $arrayRef,
                           position => $n);


Defaults:

datatype => $DAL::REAL32

label => ''

units => ''

dimensons => [1]

position => -1 (leave it to the DAL, a wise choice)




=item *

$co = $tb->column(name => $column_name);

Returns the named column, if it exists.

=back

=head2  Array constructors

=over 4



=item *

$ar = $ds->addArray(name => $array_name,
                          datatype => $type,
                          dimensions => $arrayRef,
                          position => $integer);
  

Defaults:

datatype => $DSAL::REAL32

dimensions => [0]

position => -1 (leave it to the DAL, a wise choice)




=item *

$ar = $ds->arrays(name => $array_name);

Returns the named array, if it exists.

=back

=head2  Attribute constructor

=over 4




=item *

$at = $ob->attribute(name => $attribute_name);

Returns the named attribute, if it exists.

=back

=head1 OTHER METHODS


=head2 Any pedal object

=over 4



=item *

$ob->data();

Returns a pointer to the data structure behind the object. See L<DATA
METHODS>.



=item *

$ob->label();

Returns the object's label.



=item *

$ob->relabel(newlabel => $new_object_label);

Relabels the object.



=item *

$ob->name();

Returns the name of the object.



=item *

$ob->rename(newname => $new_object_name);

Renames the object.

=back

=head2 Any pedal object but  attributes

=over 4



=item *

$ob->mode();

Returns the access mode used to open the data set.



=item *

$ob->release();

Releases the object. The DAL could decide  to free the memory
allocated to the object.



=item *

$ob->hasAttribute(-name => $attribute_name);

Returns true if the object has the named attribute.




=item *

$ob->addAttribute(name => $attribute_name,
                        datatype => $datatype,
                        value => $value,
                        units => $units,
                        label => $string);


Adds an attribute to the object. For columns the list of possible
attributes is defined in the DAL.

Defaults:

datatype => $DAL::REAL32

value => 0

units => ''

label => ''



=item *

$ob->deleteAttribute(name => $attribute_name);

Removes the named attribute.

=back

=head2 Any pedal object but attributes and columns

=over 4



=item *

$ob->addComment(value => $string);

Adds a comment entry to the object.

Defaults:

value => ''



=item *

$ob->comments();

Returns the number of comment entries.



=item *

$ob->comment(position => $n); 

Returns the n-th comment entry.

Defaults:

position => 0



=item *

$ob->addHistory(value => $string);

Add a history entry to the object.

Defaults:

value => ''



=item *

$ob->historys(); 

Returns the number of history entries for the object.



=item *

$ob->history(position => $n); 

Returns the n-th history entry.

Defaults:

position => 0

=back

=head2 Any pedal object but data sets and tables

=over 4



=item *

$ob->units();

Returns the units of the object.



=item *

$ob->type();

Returns the data type of the object.


=back 

=head2 Data set objects

=over 4



=item *

$ds->addArray(...);

See L<Array  constructors>.



=item *

$ds->array(...);

See L<Array  constructors>.



=item *

$ds->hasArray(name => $array_name);

Returns true if the named array exists.



=item *

$ds->deleteArray(name => $array_name);

Deletes the named array.



=item *

$ds->addTable(...);

See L<Array constructors>.



=item *

$ds->table(...);

See L<Array constructors>.



=item *

$ds->hasTable(name => $table_name);

Returns true if the named table exists.



=item *

$ds->deteleTable(name => $table_name);

Deletes the named table.



=item *

$ds->blocks(); 

Returns the number of blocks in the data set.



=item *

$ds->hasBlock(name => $block_name); 

Returns true if the named block exists.



=item *

$ds->deleteBlock(name => $block_name);

Deletes the named block.

=back

=head2 Table objects

=over 4



=item *

$ob->columns();

Returns the number of columns in the object.



=item *

$tb->hasColumn(name => $column_name);

Returns true if the named column exists in the table.



=item *

$co = $tb->addColum(...);

See L<Column constructors>.



=item *

$co = $tb->column(...);

See L<Column constructors>.



=item *

$tb->deleteColumn(name => $column_name);

Deletes the named column.

=back


=head2 Column and array objects

=over 4



=item *

$ob->dimensions();

In list context it returns a list with the dimensions of the
object. In scalar context it returns the number of dimensions of the object.



=item *

$ob->elements();

This returns the number of elements in a data cell. This is the
product of the elements in the list returned by the previous method.

=back

=head2 Table and Column objects

=over 4



=item *

$ob->rows();

Returns the number of rows in the object.

=back

=head2 Column objects (variable length)

These methods work on variable length column. A varaible length column
is created by setting C<dimensions => []> in the C<addColumn> call.

=over 4



=item *

$ob->setCellSize(row => $row,
                       size => $size);

Sets $row to contain $size elements.

Defaults:

row => 0

size => 1



=item *

$ob->cellSize(row => $row);

Inquires the size of a row.

Defaults:

row => 0



=item *

$v = $ob->cellData(row => $row);

Returns the data object corresponsing to a given row. See L<DATA METHODS>.

Defaults:

row => 0

=back

=head1 DATA METHODS

Note that these methods are not efficient (i.e., they are slow).
Good enough to manipulate small data sets.

=over 4



=item *

$v = $ob->data();

Returns a pointer to the data associated with te object.



=item *

$v->set($value, $index); 

Assigns $value to the $index-th elemnth of the object.



=item *

$oneElement = $v->value($index);

Returns the current elements.

=back

=head2 Attribute methods

=over 4



=item *

$at->asInt8();

Returns the attribute as $DAL::INT8.



=item *

$at->asInt16();

Returns the attribute as $DAL::INT16.



=item *

$at->asInt32();

Returns the attribute as $DAL::INT32.



=item *

$at->asString();

Returns the attribute as $DAL::STRING.



=item *

$at->asBool();

Returns the attribute as $DAL::BOOL.



=item *

$at->asReal32();

Returns the attribute as $DAL::REAL32.



=item *

$at->asReal64();

Returns the attribute as $DAL::REAL64.

=back

=head1 DEVELOPERS NOTES

The pedal is based on a C interface to the XMM Data Access Layer C++
libraries. The C interface was then converted to a set of
Perl-callable routines via SWIG (F<http://www.swig.org/>). Then, an
object oriented interface was built over the flat Perl interface.

=head1 TODO

=over 4



=item *

*

The data methods are extremely slow. They are based on SWIG's pointer
libraries, that possibly where never intended to handle large amounts
of data. The pedal should interface to PDL (F<http://pdl.perl.org/>).



=item *

*

It should be possible to insert/remove rows from a table.



=item *

*

It should be possible to copy rows from one table to another.

=back

=head1 AUTHORS

Giuseppe Vacanti, cosine science & comuting, XMM Science Operations Team

Mark Thomas, Cara, XMM Science Operations Team

=head1 HISTORY

The pedal was born out of an idea of Giuseppe Vacanti. It was made
possible by Mark Thomas's hard work.

=head1 SEE ALSO

DAL::utils.

=cut

1;
