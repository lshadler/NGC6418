package Text::Boilerplate::Tag::Input;


####
#### Text::Boilerplate::Tag::Input
####   A Boilerplate tag which returns the hash value named
####   after it as an HTML <INPUT...> tag.
####

use strict;

use Text::Boilerplate::Tag;
@Text::Boilerplate::Tag::Input::ISA=qw(Text::Boilerplate::Tag);

######################## Class Methods #############################

##
## new({ 'Name' => $name, 'Value' => $value, ...})
##  Creates a new INPUT tag with the appropriate attributes.
##
sub new {
    my $type = shift;
    my ($att) = @_;
    my $self;

    $self = $type->SUPER::new($att);
    $self->{'Value'} = defined $att->{'value'} ? $att->{'value'} : '';

    delete $att->{'name'};
    delete $att->{'value'};

    $self->{'Other'} = $att;
    $self;
}


###################### Object Methods ##############################


##
## value()
##   Returns the default value of the tag.
##
sub value {
    my $self = shift;

    $self->{'Value'};
}

##
## other()
##   Returns the other HTML attributes included in the tag.
##
sub other {
    my $self = shift;

    $self->{'Other'};
}

##
## inline($arg)
##   Returns a subroutine to turn the named key off of $arg into
##   an HTML form input.
##
sub inline {
    my $self = shift;
    my ($arg) = @_;
    my ($value, $other, $other_str);

    # Figure out the name and default value
    $value = sprintf( q{%s->{'%s'}}, $arg, $self->name() );
    $value = sprintf( 
		     q{${ \( length(%s) ? %s : '%s' ) }}, 
                     $value, $value, $self->value()
    )
	if defined $self->value();

    # Get ready to pass on HTML values
    $other = $self->other();
    $other_str = join(' ', map(uc($_) . qq{="$other->{$_}"}, keys %$other));

    sprintf(q{<INPUT NAME="%s" VALUE="%s" %s>}, 
	    $self->name(), $value, $other_str
	    );
}

1;

