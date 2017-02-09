# 26 Feb 2013 (EC):
#   - ensure that setStringCell sets no more than $co->elements() bytes
#   - specify dstringPtr as the type to set/value, and specify len to value


package DAL::utils;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
     setStringCell getStringCell
);

$VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

sub getStringCell {
    my $co = shift;
    my $index = shift;
    my $s = $co->data()->value($co->elements()*$index,"dstringPtr",$co->elements());
    substr($s,0,$co->elements());
}

sub setStringCell {
    my $co = shift;
    my $index = shift;
    my $value = shift;
    
    # the string must git within co->elements() bytes, and be padded with spaces
    my $value = substr($value,0,$co->elements());

    while(length $value < $co->elements()) { $value .= " " }
    $co->data()->set($value,$co->elements()*$index,"dstringPtr");
    
}

=head1 NAME

  DAL::utils - pedal utilities

=head1 SYNOPSIS

  use DAL::utils qw/setStringCell getStringCell/;

=head1 DESCRIPTION

A collection of utility functions related to the pedal (see B<DAL>).
B<DAL::utils> does not export anything into the caller's name space.

=head2 String columns

These functions can be used to set and retrieve rows in a string column.

=over 4

=item setStringCell($columnObject,$index,$value)

Set the $index-th row of the column pointed to by $columnObject to $value. 
$value is treated as a string.

=item  $s = getStringCell($columnObject,$index)

Returns the string in the $index-th row of the column pointed to by $columnObject.

=back

=head1 AUTHOR

Giuseppe Vacanti, European Space Agency, XMM Science Operations Team
Ed Chapin, European Space Agency, XMM Science Operations Centre

=head1 SEE ALSO

DAL.

=cut

1;
