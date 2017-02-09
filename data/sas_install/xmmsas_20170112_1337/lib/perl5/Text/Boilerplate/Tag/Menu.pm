package Text::Boilerplate::Tag::Menu;

####
#### Text::Boilerplate::Tag::Menu
#### $Revision: 1.1 $
####
####
####  Represents a SELECT menu consisting of script-generated data.
####

use strict;

use Text::Boilerplate::Tag;

@Text::Boilerplate::Tag::Menu::ISA = qw(Text::Boilerplate::Tag);

########################### Class Variables ############################

########################### Class Methods ##############################

##
## new({ 'Name' => $name, ...})
##    Creates a new MENU tag with the appropriate attributes.
##
sub new {
    my $type = shift;
    my ($att) = @_;
    my ($self);

    # Do basic tag initialization
    $self = $type->SUPER::new($att);

    # Store the unused attributes for reincarnation within the
    # <SELECT> tag
    delete $att->{'name'};
    $self->{'Other'} = $att;

    # Return the object
    $self;
}


########################## Object Methods ##############################

##
## inline($arg, \%options)
##   Returns Perl code which, when supplied with a list of hashes of
##   the format {'Option' => $, 'Value' => $, 'Selected' => $,}
##   interpolates a SELECT menu with the appropriate options and
##   values.
##
sub inline {
    my $self = shift;
    my ($arg, $options) = @_;
    my ($other_str, $arg_val);

    # Get the other options converted to a string
    $other_str = join(' ', 
		      map(sprintf(q{%s="%s"}, uc($_), $self->{'Other'}{$_}),
			  keys %{ $self->{'Other'} })
		      );

    # Return the Perl code
    $arg_val = sprintf(q{%s->{'%s'}}, $arg, $self->name());
    sprintf(<<'End_Code', $self->name(), $other_str, $arg_val, $arg_val);
<SELECT NAME="%s"%s>
${ \( defined %s and
    join('', 
        map {
            my $val_str = qq{ VALUE="$_->{'Value'}"} if defined $_->{'Value'};
            my $sel_str = $_->{'Selected'} ? ' SELECTED' : '';
 
            qq{\t<OPTION${val_str}${sel_str}>$_->{'Option'}\n};
        } 
        @{ %s }
    ) 
) }</SELECT>
End_Code

}

