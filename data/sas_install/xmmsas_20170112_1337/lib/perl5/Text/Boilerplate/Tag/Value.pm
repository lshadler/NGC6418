package Text::Boilerplate::Tag::Value;

####
#### Text::Boilerplate::Tag::Value
####   A Boilerplate tag which returns the hash value named
####   after it unscathed.
####

use strict;

use Text::Boilerplate::Tag;
@Text::Boilerplate::Tag::Value::ISA=qw(Text::Boilerplate::Tag);

###################### Object Methods ##############################

##
## inline($arg)
##   Probably one of the fastest inlines: returns
##   the argument, subscripted to the tag's name.
##   For example, for a tag named 'Address' in
##   the main body of the text, creates something
##   like '$in->{'Address'}'.
##
sub inline {
    my $self = shift;
    my ($arg) = @_;

    sprintf(q{%s->{'%s'}}, $arg, $self->name());
}



