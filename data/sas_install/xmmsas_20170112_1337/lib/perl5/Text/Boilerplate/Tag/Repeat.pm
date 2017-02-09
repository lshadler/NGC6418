package Text::Boilerplate::Tag::Repeat;

####
#### Text::Boilerplate::Repeat
#### $Revision: 1.1 $
####
####  Represents a block of the Boilerplate that you
####  want to have repeated as many times as necessary.
#### 

use strict;

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::Repeat::ISA = qw(Text::Boilerplate::Block);

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
    $self->{'Separator'} = [];
    $self;
}
    

##
## add($element)
##  Adds the element to the Repeat block.  Subclassed to
##  store any Separator blocks in the Separator list.
##
sub add {
    my $self = shift;
    my ($element) = @_;

    if (ref $element && $element->type() eq 'Separator') {
	push( @{ $self->{'Separator'} }, $element );
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
    my ($contents_perl, $separator_perl);

    # Get Perl code for the contents
    $contents_perl = $self->_compile_contents('$_', $options);

    # Get Perl code for the separator
    $separator_perl = join('', 
			   map( $_->inline('$_', $options),
			       @{ $self->{'Separator'} }
			       )
			   );

    # Put all of these in a join
    qq{\$\{ \\\(join\(qq\{$separator_perl\}\, map\(qq\{$contents_perl\},\@\{ $arg\-\>\{\'${ \( $self->name() ) }\'\} \}\)\)\) \}};

}

