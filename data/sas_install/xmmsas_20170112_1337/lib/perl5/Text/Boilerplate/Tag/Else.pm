package Text::Boilerplate::Tag::Else;

####
#### Text::Boilerplate::Tag::Else
#### $Revision: 1.1 $
####
####  Holds what's displayed in an IF../IF block when the
####  IF condition is false.
####

use strict;
use lib qw(..);

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::Else::ISA = qw(Text::Boilerplate::Block);


########################### Class Methods ##############################

##
## inline($arg, \%options)
##   Returns Perl code which, when supplied with a hash, returns
##   a version of its source text with all the tags filled in.
##   Does not repeat.
##
sub inline {
    my $self = shift;
    my ($arg, $options) = @_;

    $self->_compile_contents($arg, $options);
}
