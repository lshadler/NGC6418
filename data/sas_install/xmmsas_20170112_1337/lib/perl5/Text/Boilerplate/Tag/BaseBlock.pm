package Text::Boilerplate::Tag::BaseBlock;

####
#### Text::Boilerplate::Tag::BaseBlock
#### $Revision: 1.1 $
#### Created 4/15/97 by Steve Nelson
####
####   The block in a Boilerplate which holds all other elements
####

use strict;
use vars qw();
use lib qw(..);

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::BaseBlock::ISA = qw(Text::Boilerplate::Block);

####################### Class Variables #############################

########################## Class Methods ###############################

########################## Object Methods ##############################

##
## inline($arg, \%options)
##   Returns Perl code which, when called, returns a
##   filled-in version of the Boilerplate.
##
sub inline {
    my $self = shift;
    my ($arg, $options) = @_;
    my ($compiled_contents);

    # Get the Perl code for our contents
    $compiled_contents = $self->_compile_contents($arg, $options);

    # Put the contents inside a subroutine shell
    qq {
	sub {
	    my ($arg) = \@_;
	    
	    qq{$compiled_contents};
	};
    };

}



