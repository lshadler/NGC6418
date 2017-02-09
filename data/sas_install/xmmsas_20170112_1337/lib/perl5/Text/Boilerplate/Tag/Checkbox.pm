package Text::Boilerplate::Tag::Checkbox;


####
#### Text::Boilerplate::Tag::Checkbox
####   A Boilerplate tag which returns the hash value named
####   after it as an HTML <INPUT TYPE="checkbox"...> tag,
####   checked if the value is true, unchecked otherwise.
####

use strict;

use Text::Boilerplate::Tag;
@Text::Boilerplate::Tag::Checkbox::ISA=qw(Text::Boilerplate::Tag);

######################## Class Methods #############################

##
## new({ 'name' => $name, 'value' => $value, 'checked' => $checked })
##  Creates a new Checkbox tag with the appropriate attributes.
##
sub new {
    my $type = shift;
    my ($att) = @_;
    my $self;

    $self = $type->SUPER::new($att);
    $self->{'Value'} = $att->{'value'};
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
##   Returns the default value of the tag.
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

    $self->{'Checked'};
}

##
## inline($arg)
##   Returns a subroutine to turn the named key off of $arg into an
##   HTML <INPUT TYPE="checkbox" tag, checked as appropriate.
##
sub inline {
    my $self = shift;
    my ($arg) = @_;
    my ($my_val, $code, $value_str, $tag_src);

    # Code for getting value named after this tag
    $my_val = sprintf(q{%s->{'%s'}}, $arg, $self->name());

    # Figure out the code for expressing whether to check oneself or
    # not...Sorry for the opaque code... this is difficult to explain
    # in human terms.
    $code = sprintf(q{grep($_ eq q{%s}, @{%s}) ? ' CHECKED' : ''}, 
		    $self->value(),
		    $my_val,
		    );

    $self->checked()
	and $code = sprintf(
	    q{defined %s ? ( %s ) : ' CHECKED'},
	    $my_val,
            $code,
       );

    $tag_src = sprintf(
        q{<INPUT TYPE="checkbox" NAME="%s" VALUE="%s"${ \( %s ) }>},
        $self->name(),
        $self->value(),
        $code
    );
    
    $tag_src;
}





    
