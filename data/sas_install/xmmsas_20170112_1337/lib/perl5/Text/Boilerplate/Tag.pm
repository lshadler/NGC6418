package Text::Boilerplate::Tag;

####
#### Text::Boilerplate::Tag
#### Created 4/12/97 by Steve Nelson
####
####    Global overclass for tags appearing in
####    Boilerplates.
####

use strict;

use Carp;

###################### Class Variables ########################

###################### Class Methods ##########################

##
## Text::Boilerplate::Tag->new({
##    'Name' => $name
## })
##  Creates a new Tag.
##
sub new {
    my $type = shift;
    my ($att) = @_;
    my ($self);

    $self = { 'Name' => $att->{'name'} };
    bless $self, $type;

}

##
## Text::Boilerplate::Tag->is_block()
##   Returns if the tag accepts contents.  Default
##   returns false.  (Probably this will get replaced
##   with isa once 5.004 gets better acceptance.)
##
sub is_block { '' }

##
## Text::Boilerplate::Tag->type()
##   Returns the tag's type.  By default this is
##   the last word in the class name.
##
sub type {
    my $type = shift;
    my ($full_type, @type_parts);

    $full_type = ref $type || $type;
    @type_parts = split(/::/, $full_type);
    $type_parts[$#type_parts];
}

############################ Object Methods ############################

##
## name()
##   Returns the tag's name.
##
sub name {
    my $self = shift;

    $self->{'Name'};
}

##
## inline($arg, \%options)
##   Returns the Perl code for processing the data given to
##   this tag.  This is the virtual base class; we die if
##   someone forgot to create an "inline".
##
sub inline { my $self = shift; confess("${ \( ref $self ) } failed to define an inline() method, stopped") };

1;



