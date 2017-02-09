package Text::Boilerplate::Tag::If;

####
#### Text::Boilerplate::Tag::If
#### $Revision: 1.1 $
####
####  Represents a block of the Boilerplate that you
####  only want to have included if a value is true.
#### 

use strict;

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::If::ISA = qw(Text::Boilerplate::Block);

########################### Class Variables ############################

########################### Class Methods ##############################

########################## Object Methods ##############################

##
## new(\%attributes, $parent)
##  Creates a new Repeat block.
##
sub new {
    my $type = shift;
    my ($self);

    $self = $type->SUPER::new(@_);
    $self->{'Else'} = [];
    $self;
}
    

##
## add($element)
##  Adds the element to the If block.  Subclassed to handle Else
##  blocks.
##
sub add {
    my $self = shift;
    my ($element) = @_;

    if (ref $element && $element->type() eq 'Else') {
	push( @{ $self->{'Else'} }, $element );
    }

    else {
	$self->SUPER::add($element);
    }
}

##
## inline($arg, \%options)
##   Returns Perl code which, when supplied with a list of 
##   hashes, returns a filled-in version of its contents
##   for each one, joined by any Separator blocks
##   contained in the Repeat block.
##
sub inline {
    my $self = shift;
    my ($arg, $options) = @_;
    my ($if_perl, $else_perl);

    # Get Perl code for the contents
    $if_perl = $self->_compile_contents($arg, $options);

    # Get Perl code for the else block
    $else_perl = join('', 
			   map( $_->inline($arg, $options),
			       @{ $self->{'Else'} } 
			       )
			   );

    # Schemeish 'or'
    sprintf(q{${ \( %s->{'%s'} ? qq{%s} : qq{%s} ) }}, 
	    $arg, $self->name(), $if_perl, $else_perl
	    );


}

