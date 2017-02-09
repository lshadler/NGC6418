package Text::Boilerplate::Tag::Separator;

####
#### Text::Boilerplate::Tag::Separator
#### $Revision: 1.1 $
####
####  Represents a block of text within a repeating block
####  that should come between repetitions of the block.
####  Only legal within REPEAT blocks.
####

use strict;
use lib qw(..);

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::Separator::ISA = qw(Text::Boilerplate::Block);

################################ Object Methods ##########################

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
    


