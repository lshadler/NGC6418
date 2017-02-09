package Text::Boilerplate::Tag::Select;

####
#### Text::Boilerplate::Tag::Select
#### $Revision: 1.1 $
####
####  Used for creating a SELECT menu with "sticky" values.
####

use strict;

use Text::Boilerplate::Block;

@Text::Boilerplate::Tag::Select::ISA = qw(Text::Boilerplate::Block);


########################### Class Variables ############################

########################### Class Methods ##############################

##
## new(\%attributes, $parent)
##  Creates a new Select block.
##
sub new {
    my $type = shift;
    my ($attributes) = @_;
    my ($self);

    $self = $type->SUPER::new(@_);
    $self->{'Options'} = [];
    delete $attributes->{'name'};
    $self->{'Attributes'} = $attributes;
    $self;
}

########################## Object Methods ##############################

##
## add($element)
##  Adds the element to the Select block.  If the element is
##  plain text, parses out any <OPTION>s and stores them.
##
sub add {
    my $self = shift;
    my ($element) = @_;

    # If we're a text element
    if (ref $element eq '') {
	my ($unescaped_literal);

	# Unescape the literal
	$unescaped_literal = eval("qq{$element}");

	# For each <OPTION> in the element
	while ($unescaped_literal =~ m{
	    <OPTION
	    \s*
		(VALUE=".*?")?
            \s*
		(SELECTED)?
            \s*>
	    \s*
		([^<]*)
        }xig) {
	    my ($option, $value, $selected);

	    # Figure out the option name and whether it's
	    # selected by default
	    $option = $3;
	    $selected = $2;
	    
	    # If the value was specified <OPTION VALUE="...">
	    if ($1) {

		# Get rid of that pesky VALUE=
		($value = $1) =~ s/VALUE="(.*?)"/$1/i;

	    } # End if specified

	    # Else the option value wasn't specified
	    else {

		# Use the option name, sans whitespace at end,
		# for value
		($value = $option) =~ s/\s*$//;
	    }
	    
	    # Store the option in the options list
	    push(@{ $self->{'Options'} }, [$option, $value, $selected]);

	}
    } # End if literal

    # Else it's not literal text, so handle it normally
    else { $self->SUPER::add($element); }

}
	    
##
## inline($arg, \%options)
##   Returns Perl code that creates a SELECT list with
##   the appropriate OPTION tags selected, based on the
##   tag's input value.
##
sub inline {
    my $self = shift;
    my ($arg, $options) = @_;
    my ($options_list, $contents_perl, $other, $other_str);

    # Get a list of all options to be put in subroutine
    $options_list = join("\n", map(
        qq{['$$_[0]', '$$_[1]', '$$_[2]'],}, 
	@{ $self->{'Options'} }
    ));

    # Get ready to pass on HTML values
    $other = $self->{'Attributes'};
    $other_str = join(' ', map(uc($_) . qq{="$other->{$_}"}, keys %$other));
    
    # Interpolate into subroutine
    sprintf(q{${ \( do {
	my $in_val = %s->{'%s'};
	my (@options_chosen, $options_str);
	my @options = ( %s );


	@options_chosen = map {
	    my ($opt, $val, $default) = @$_;
	    my ($selected);

	    if (not defined $in_val) {
		$selected = $default ? ' SELECTED' : '';
	    }

	    elsif ($val eq $in_val) { $selected = ' SELECTED'; }
	    else { $selected = ''; }

	    qq{<OPTION VALUE="$val"$selected>$opt};
	} @options;
 
	$options_str = join('', @options_chosen);

	qq{<SELECT NAME="%s" %s>$options_str</SELECT>};

    } )}}, $arg, $self->name(), $options_list, $self->name(), $other_str);
}







