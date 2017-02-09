package Text::Boilerplate::Tag::Radio;


####
#### Text::Boilerplate::Tag::Radio
####   A Boilerplate tag which returns the hash value named
####   after it as an HTML <INPUT TYPE="radio"> tag, CHECKED
####   if the value of the thingy named after this (which should
####   be an array ref) contains the value in this one's VALUE
####   tag.
####

use strict;

use Text::Boilerplate::Tag;
@Text::Boilerplate::Tag::Radio::ISA=qw(Text::Boilerplate::Tag);

######################## Class Methods #############################

##
## new({ 'name' => $name, 'value' => $value, 'checked' => $checked })
##  Creates a new Radio tag with the appropriate attributes.
##
sub new {
    my $type = shift;
    my ($att) = @_;
    my $self;

    $self = $type->SUPER::new($att);
    $self->{'Value'} = defined $att->{'value'} ? $att->{'value'} : '';
    if ( defined $att->{'checked'} ) {
	$self->{'Checked'} = $att->{'checked'} ? 1 : '';
    }
    else {
	$self->{'Checked'} = '';
    }

    $self;
}


###################### Object Methods ##############################


##
## value()
##   Returns the value of the tag.
##
sub value {
    my $self = shift;

    $self->{'Value'};
}

##
## checked()
##  Returns a true value if the tag's default value is CHECKED, false
##  otherwise.
##
sub checked {
    my $self = shift;

    $self->{'Checked'} ? 1 : '';
}

##
## inline($arg)
##   Returns a subroutine to turn the named key off of $arg into an
##   HTML <INPUT TYPE="radio"> tag, checked as appropriate.
##
sub inline {
    my $self = shift;
    my ($arg) = @_;
    my ($code, $tag_src);

    # Sorry for the opaque code... this is difficult to explain
    # in human terms.
    $code = sprintf(q{( %s->{'%s'} eq '%s' ) ? ' CHECKED' : ''}, $arg, $self->name(), $self->value());


    $self->checked()
	and $code = sprintf(
	    q{defined %s->{'%s'} ? ( %s ) : ' CHECKED'},
	    $arg,
	    $self->name(),
            $code,
       );

    $tag_src = sprintf(
        q{<INPUT TYPE="radio" NAME="%s" VALUE="%s"${ \( %s ) }>},
        $self->name(),
        $self->value(),
        $code
    );
    
    $tag_src;
}





    
