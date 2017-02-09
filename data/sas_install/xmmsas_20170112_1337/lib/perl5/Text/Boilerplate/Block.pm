package Text::Boilerplate::Block;

####
#### Text::Boilerplate::Block
####
####   Abstract base class for all tags that accept
####   contents.
####

use strict;

use Text::Boilerplate::Tag;

@Text::Boilerplate::Block::ISA = qw( Text::Boilerplate::Tag );

########################### Class Variables #######################

############################ Class Methods ########################

##
## new({'Name' => $name }, $parent)
##  Creates an empty block named 'Name', which exists in
##  parent block $parent.
##
sub new {
    my $type = shift;
    my ($in, $parent) = @_;
    my ($self);

    $self = $type->SUPER::new($in);
    $self->{'Contents'} = [];
    $self->{'Parent'} = $parent;
    bless $self, $type;
}

## 
## is_block()
##  Overrides the default-- returns true, for obvious reasons.
##
sub is_block { 1; }

########################## Object Methods #############################

##
## add($element)
##   Adds an element to the block.
##
sub add {
    my $self = shift;
    my ($element) = @_;

    push( @{ $self->{'Contents'} }, $element );
}


##
## contents()
##   Returns the contents of the block; i.e. any elements which
##   were encountered between the beginning tag and the end
##   tag.
##   
sub contents {
    my $self = shift;
    
    @{ $self->{'Contents'} };
}

##
## is_terminated($tag_str)
##  Returns whether this $tag_str terminates this block.
##
sub is_terminated {
    my $self = shift;
    my ($tag_str) = @_;

    lc($tag_str) eq lc( "/" . $self->type() );
}

##
## parent()
##  Returns the block which contains this block.
##
sub parent {
    my $self = shift;
    
    $self->{'Parent'};

}

### Protected utility routine

##
## _compile_contents($arg, \%options)
##   Returns Perl code for the contents of the Block.
##
sub _compile_contents {
    my $self = shift;
    my ($arg, $options) = @_;
    my ($element, @compiled_contents);

    # For each element in the block
    foreach $element ( $self->contents() ) {

      # Get perl code if it's a tag, or the text if it's literal
      push(
	   @compiled_contents, 
	   ref $element 
	     ? $element->inline($arg, $options)
	     : $element
	   );

  } # End foreach element

    # Return the compiled contents as a string
    return join('', @compiled_contents);

}


	       
    










