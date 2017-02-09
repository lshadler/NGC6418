package Text::Boilerplate;

####
#### Text::Boilerplate
#### $Revision: 1.1 $
#### Created 4/9/97 by Steve Nelson
#### 
####  Allows programmers to separate what the output of a 
####  script looks like from its functionality.
####

require 5.003;

use strict;
use vars qw($VERSION $Begin_Tag $End_Tag %Default_Options $Unknown_Tag_Str
	    $Tag_Dir);

use Carp;
use FileHandle;
use English;

use Text::Boilerplate::Tag::BaseBlock;
use Text::Boilerplate::Tag::Value;

######################### Class Variables ####################

## $VERSION: The version of this Boilerplate
$VERSION = '0.08';

## $Begin_Tag, $End_Tag: The ascii codes which signal
##    when a tag begins or ends
($Begin_Tag, $End_Tag) = qw([* *]);

## $Unknown_Tag_Str: The string which the Boilerplate
##    inserts instead of an unknown tag if the 'Unknown
##    Tag Behavior' option is set to
##    Text::Boilerplate->MARK_UNKNOWN_TAGS. The string '%s'
##    is replaced with an error message.
$Unknown_Tag_Str = '<!--* UNKNOWN TAG SKIPPED: %s *-->';

## %Default_Options: Tag options set by default
%Default_Options = (
		    'Clean'                => 0,
		    'Unknown Tag Behavior' => { },
		    );

## $Tag_Dir: Directory under "Boilerplate" in which all tags
##    are stored
$Tag_Dir = 'Tag';

######################### Class Methods ######################

##
## Text::Boilerplate->new($text, \%options)
##  Parses $text into a new Boilerplate.  If $is_clean
##  is true, the Boilerplate is parsed such that no
##  external subroutine references are allowed.
##  %options contains a hash of valid options.
##  These options are:
##
##    'Unknown Tag Behavior':
##        Defines how the Boilerplate will treat
##        tags for which it can't find/load classes.
##        Appropriate values are:
##
##            Text::Boilerplate->MARK_UNKNOWN_TAGS
##            Text::Boilerplate->DIE_ON_UNKNOWN
##            Text::Boilerplate->SKIP_UNKNOWN
##
##        Default is MARK_UNKNOWN_TAGS.
##
sub new {
    my $type = shift;
    my ($source, $options) = @_;
    my ($source_ref, $base_block, $sub_code, $compiled_sub, $self);

    # Make sure that we're not making needless copies of the
    # Boilerplate source
    $source_ref = ref $source ? $source : \$source;

    # Create the base block and parse the source into it
    $base_block = new Text::Boilerplate::Tag::BaseBlock({'Name' => 'Base Block'});
    $type->parse_source($base_block, $source_ref);

    # Get the Perl code for the Boilerplate as a subroutine
    $sub_code = $type->_perl_code($base_block, $options);

    # Compile the Perl code
    $compiled_sub = $type->_compile($sub_code, $options);

    # Store all object data
    $self = {
	'Base Block'         => $base_block,
	'Source'             => $source_ref,
	'Code'               => $sub_code,
	'Compiled Sub'       => $compiled_sub,
	'Options'            => $options,
    };

    # Objectify
    bless $self, $type;

}

##
## Text::Boilerplate->load($file)
## Text::Boilerplate->load(\*FILEHANDLE)
##   Loads in a Boilerplate from a text file.
##
sub load {
    my $type = shift;
    my ($file, @additional_args) = @_;
    my ($source_fh, $our_handle, $source, $boilerplate);

    # If we were passed a filehandle
    if ( ref $file ne '' ) {
	
	# Use it as our input filehandle
	$source_fh = $file;
	$our_handle = 0;

    } # End if passed filehandle

    # Else we were passed a filename
    else {

	# Open the file
	$source_fh = new FileHandle("< $file")
	    or croak("Couldn't open file '$file' for reading: $OS_ERROR; stopped");
	# Note that we opened this file
	$our_handle = 1;
    }

    # Load the file's contents into a string
    $source = join('', $source_fh->getlines() );

    # Close the filehandle if we opened it
    $source_fh->close() if $our_handle;

    # Create a Boilerplate from the string
    $boilerplate = $type->new(\$source, @additional_args);
    
    # Store the filename if we opened it
    $boilerplate->{'Filename'} = $file if $our_handle;

    # Return the Boilerplate
    $boilerplate;
}

##
## parse_source($block, \$source)
##  Parses the text in $source into the $block.
##
sub parse_source {
    my $type = shift;
    my ($base_block, $source_ref) = @_;
    my ($begin, $end, $current_block);

    # Make the beginning and ending tags safe for regex consumption
    $begin = quotemeta($Begin_Tag);
    $end = quotemeta($End_Tag);

    # Start with the base block
    $current_block = $base_block;

    # While we're matching elements in the source
  ELEMENT: while ( $$source_ref =~m{
      $begin \s + (.*?) \s + $end
	  | ( .*?
	     (?:
	      (?= $begin )
	      | \Z
	     )
	    )
	  }gxs
		  ) {
      my ($tag_str, $literal_str, $tag);
      $tag_str = $1; $literal_str = $2;
  
      # If the element is a tag
      if ( defined $tag_str ) {
	  
	  # Pop up a block and continue if this is this block's terminator
	  $current_block->is_terminated($tag_str) and do {
	      $current_block = $current_block->parent()
		  or last ELEMENT;
	      next ELEMENT;
	  };

	  # Parse the tag - skip unparseables
	  $tag = $type->_parse_tag($tag_str, $current_block)
	      or next ELEMENT;

	  # Add the tag to the current block
	  $current_block->add($tag);

	  # Set the current block to the tag if it's a block
	  $tag->is_block() and $current_block = $tag;

      } # End if it's a tag

      # Else it's literal text
      else {
	  my ($escaped_literal);
	  
	  # Escape any dangerous characters
	  $escaped_literal = quotemeta($literal_str);

	  # Add the text to the current block
	  $current_block->add($escaped_literal);

      } # End else it's literal

  } # End while matching elements

  # Probably should put some sort of balance check here
}

##
## Text::Boilerplate::_perl_code($base_block, \%options)
##   Returns perl code for a subroutine that, when called with
##   a hash containing input data, returns the boilerplate filled
##   in with that input data.  This is as simple as calling
##   the inline() function for the main block-- it's in its
##   own method for easier subclassing.
##   
sub _perl_code {
    my $type = shift;
    my ($base_block, $options) = @_;
    
    ## Get the Perl code for the main block
    $base_block->inline('$in', $options);

}

##
## Text::Boilerplate::_compile($code, \%options)
##    Compiles $code into a subroutine and returns the result.
##
sub _compile {
    my $type = shift;
    my ($code, $options) = @_;
    my ($boiler_sub) = @_;

    $boiler_sub = eval($code);
    croak("$type compiler error '$EVAL_ERROR' in code:\n$code\nStopped")
	if $EVAL_ERROR;
    $boiler_sub;
}

##
## _parse_tag($tag_str)
##    Parses a $tag_str string into a Text::Boilerplate::Tag.
##
sub _parse_tag {
    my $type = shift;
    my ($tag_str, $parent_block) = @_;
    my ($tag_type, $attributes, $tag_class, $class_filename, $match, %attributes, $tag);

    # Shortcut: return a Text tag if [* "Name" *] or [* 'Name' *]
    $tag_str =~ m/^ \s* ([""'']) ([\w\s]+?) \1 \s* $/x and 
	return Text::Boilerplate::Tag::Value->new({ 'name' => $2 });

    # Split the tag into a tag type and attributes
    ($tag_type, $attributes) = split(/\s+/, $tag_str, 2);

    # Figure out the class name of the tag
    $tag_class = join('::', $type, $Tag_Dir, ucfirst lc $tag_type);
    ($class_filename = $tag_class) =~ s#::#/#g;
    $class_filename .= '.pm';

    # Load the class if necessary and possible, or handle
    # the error
    eval { require "$class_filename" };
    $EVAL_ERROR and $type->_handle_tag_error($EVAL_ERROR);

    # Extract attributes
    if (defined $attributes) {
	while ( $attributes =~ 
	       m{
		   # Beginning, matches KEY
		   (\w+) \s*

		       # Start attribute has key
		       (?:

			# KEY=
			= \s* 

			# Begin quote or nonquote switch
			(?:

			 # KEY="Value"
			 # KEY='value'
			 ([""'']) (.*?) \2

			 |

			 # KEY=value
			 ([\w]+)

			 # End attribute switch
			 )

			# End has-value switch
			)?
			    # Soak up additional spaces, if any
			    \s* }xgs ) {
	my $name  = $1;
	my $value = $3 || $4 || 1;
	  
	# Store the attributes
	$attributes{lc($name)} = $value;

        }        # End while we're matching
    }        # End if the attributes are defined 

    # Create a new tag from the class and attributes
    $tag = $tag_class->new(\%attributes, $parent_block);
    
    $tag;
}

##
## _handle_tag_error()
##
sub _handle_tag_error { die "Oops: @_"; }

######################### Object Methods ##########################
     
### Accessor Methods:

## 
## source()
##  Returns the text of the Boilerplate.
##
sub source {
    my $self = shift;

    ${ $self->{'Source'} };
}

##
## code()
##  Returns the code of the Boilerplate's fill() subroutine.
##
sub code() {
    my $self = shift;

    $self->{'Code'};
}

##
## options()
##  Returns a hash of the options that are set for this
##  Boilerplate.
##
sub options {
    my $self = shift;

    %{ $self->{'Options'} };
}

##
## _base_block()
##  Returns the Boilerplate's main block.
##
sub _base_block {
    my $self = shift;

    $self->{'Base Block'};
}

### Other methods:

##
## fill(\%values)
##   Returns the text of the Boilerplate, its [* ... *] tags 
##   filled in with the values in %values.
##
sub fill {
    my $self = shift;
    my ($values) = @_;

    &{ $self->{'Compiled Sub'} }($values);
}

##
## tag_info()
##   Returns a list of hashes containing the name, type,
##   and attributes of all of the tags in the Boilerplate,
##   like so: 
##   { 'Name' => $name, 'Type' => $type, 'Contents' => $contents }
##
sub tag_info {
    my $self = shift;
    my ($traverser);

    # Recursive sub to traverse the tag tree
    $traverser = sub {
	my (@elements) = @_;
	my (@out_elements);

	# For each element
      ELEMENT: foreach (@elements) {
	  my ($name, $type, $contents);

	  # Skip if not a tag
	  ref $_ or next ELEMENT;

	  # Get the tag's name and type
	  $name = $_->name();
	  $type = $_->type();

	  # Get info on the tag's contents if it's a block
	  $contents = $_->is_block ? 
	      [ &$traverser( $_->contents() ) ] : [];

	  # Store the tag info
	  push(@out_elements, {
	      'Name'     => $name,
	      'Type'     => $type,
	      'Contents' => $contents,
	  });

      } # End foreach

	# Return the tag info
	@out_elements;
 
    }; # End recursive sub

    # Traverse the Boilerplate
    return &$traverser($self->_base_block()->contents());
}

1;

__END__

=head1 NAME

Text::Boilerplate - format a script's output without programming

=head1 SYNOPSIS


    use Text::Boilerplate;

    # Create a Boilerplate from a text string
    $boiler = new Text::Boilerplate $text;

    # Create a Boilerplate by loading a file
    $boiler = Text::Boilerplate->load($filename);

    # Create a Boilerplate by loading from a filehandle
    $boiler = Boilerplate->load(\*FILEHANDLE);

    # Fill in all tags in a Boilerplate
    print STDOUT $boiler->fill({ 
        'Tag Name'  => $value, 
        'Tag Name2' => $value,
        'Tag Name3' => [
            { Subtag1 => $subval, Subtag2 => $subval2 },
            { Subtag1 => $subval3, Subtag2 => $subval4 }
        ],
    });


    # Get the Perl code to produce the Boilerplate
    $boiler->code();

    # Get information on the tags in the Boilerplate
    $boiler->tag_info();


=head1 DESCRIPTION

Boilerplates let you separate what a script does from what its output
looks like, using a simple mark-up language which is easy for
non-programmers to learn.  Using Boilerplates can make creating
and maintaining dynamic web pages and e-mail messages much easier.

=head2 Using the Boilerplate Mark-Up System

The Boilerplate mark-up system is designed to allow the look and feel for
script-generated text (i.e. dynamic HTML pages, form letters, etc.) to
be designed by someone who doesn't know how to program.

Say, for example, that you need to develop a CGI script for a local
bookstore that lists their top three best-selling books, plus their
customer of the week.  If, like me, you have no real aptitude for HTML
page design, you'd probably have someone else design the actual page, which,
let's say, should look like this:

    <HTML>
    
    <HEAD>
        <TITLE>Boring Bookshop</TITLE>
    </HEAD>
    
    <BODY>
        <H1>Boring Books</H1>

        <P>
            <B>Customer Of The Week:</B> Bob Smeed
        </P>

        <P>
            <B>Top Three Best-Selling Books</B>

            1. <I>Book Title #1</I> by Author<BR>
            2. <I>Book Title #2</I> by Author #2<BR>
            3. <I>Book Title #3</I> by Author #3<BR>
        </P>
    </BODY>

    </HTML>
    

Well, you could just hard-code the HTML into your script with
print statements.  Sooner or later, though, Boring Books is
going to want changes made to the HTML.  If this were an
ordinary web page, they could simply ask a page designer
to make whatever fixes they want (e.g. putting their logo
on top, putting the top-selling books into an HTML table,
changing the background, etc.) without bothering you,
the programmer.  In this case, though, the HTML is
buried inside a script, and even if the graphics person
is willing to make changes to your code, there's a strong
possibility that they might introduce errors into your
script whenever they edit it.

That's where the Boilerplate mark-up system comes in.
Instead of sticking your HTML in the script, you could
create a separate text file, consisting of:

    
    <HTML>
    
    <HEAD>
        <TITLE>Boring Bookshop</TITLE>
    </HEAD>
    
    <BODY>
        <H1>Boring Books</H1>

        <P>
            <B>Customer Of The Week:</B> [* "Customer" *]
        </P>

        <P>
            <B>Top Three Best-Selling Books</B>
            [* REPEAT NAME="Top Books" *]
                [* "Rank" *]. <I>[* "Title" *]</I> 
                by [* "Author" *]<BR>
            [* /REPEAT *]
        </P>
    </BODY>

    </HTML>

Then, in your script, add a few lines to load this file from disk and
fill it in with book titles and so forth.  Assuming you named the
above file "boringbooks.html", the code would look something 
like this:

    use Text::Boilerplate;


    # Do whatever is necessary to figure out the top-selling
    # books and customer of the week, print the HTML header,
    # etc.

    # Load the Boilerplate from its file
    $boiler = Text::Boilerplate->load('./boringbooks.html');

    # Print out the Boilerplate, filling in books
    # and customer
    print STDOUT $boiler->fill({
        'Customer'  => $customer,
        'Top Books' => \@books_info,      # @books_info:
                                          # A list of hashes a la
   });                                    # { 'Rank' => $rank, 
                                          #   'Title' => $title,
                                          #   'Author => $author }



=head2 Efficiency

The Boilerplate system is designed to fill in values extremely
quickly, at the expense of some additional time taken during
initialization.  Therefore, to get the most out of it, try to use as
few 'load's or 'new's as possible, and as many 'fill's as you want.
In CGI scripts, a good way of doing this is to use FastCGI, like so:

    use CGI::Fast;
    use Text::Boilerplate;

    # Load the boilerplate for our dynamic page
    $boiler = Boilerplate->new(<<EOF);
    <HTML>
    <HEAD><TITLE>Greetings</TITLE></HEAD>
    <BODY>Hello, [* VALUE NAME="User Name" *]</BODY>
    </HTML>
    EOF

    # Start accepting web hits
    while ($form = new CGI::Fast) {
        
        # Print 'em out a personalized page, assuming that
        # they entered 'Name' on a previous form
        print $form->header();
        print $boiler->fill({'User Name' => $form->param('Name')});
    }

=head1 METHODS

Text::Boilerplate encapsulates a number of different modules allowing
you to create, learn about, and fill in boilerplate text.

=head2 Static Methods

=over 4

=item new()

Arguments: $text

Creates a new Text::Boilerplate from a scalar.  For example:

    $form_ltr = new Text::Boilerplate("Dear [* 'Name' *],");

This would create a new Text::Boilerplate with a VALUE fill-in tag
named 'Name'.

=item load()

Arguments: $filename

Loads in a Text::Boilerplate from a text file or filehandle.  For
example:

    $boiler = Text::Boilerplate->load('page1.boil');

Load() croaks if it can't open the file.  I don't know if this is
a bug or a feature.

If you already have a filehandle open containing boilerplate text,
you can pass load() a filehandle reference, like this:

   $boiler = Text::Boilerplate->load(\*DATA);

This could be helpful if you want to store Text::Boilerplate
data at the end of your script.  (Although this *would* defeat
the purpose a bit...)


=item fill()

Fills in all of the tags in a Boilerplate with the data provided to
it, formatted appropriately, and returns the text of the filled-in
Boilerplate.  Example:

    $boiler = Text::Boilerplate->new(<<EOF);
    In Xanadu did [* VALUE NAME="Person" *]
    A stately [* VALUE NAME="Item" *] decree...
    EOF

    $filled_boiler = $boiler->fill({
        'Person' => 'Kubla Khan',
        'Item'   => 'Pleasure-Dome',
    });

$filled_boiler is now:

    In Xanadu did Kubla Khan
    A stately Pleasure-Dome decree...

See L<"BOILERPLATE TAGS"> for a full discussion of Boilerplate tag
syntax.

=item code()

Behind the scenes, a Boilerplate is just a Perl subroutine
compiled from the text of the Boilerplate document.  If for
some strange reason you want to see the Perl code for
this subroutine, use the code() method.  Keep in mind that
this code is not especially human-readable.


=item tag_info()

Returns a list of hashes containing the name, type,
and attributes of all of the tags in the Boilerplate,
like so: 

    ( { 'Name'     => $name, 
        'Type'     => $type, 
        'Contents' => $contents }, ...)

For nested tags (such as REPEAT), the 'Contents' key will contain a
reference to a list of all of the tags contained between the tag
(i.e. C<[* REPEAT NAME="fish" *]>) and its terminator (i.e. C<[*
/REPEAT *]>).  Other tags will hold a reference to an empty list in
the 'Contents' value.
=back

=head1 BOILERPLATE TAGS

All of this is useless without tags to fill in.  Boilerplate
tags are always sandwiched between S<'[* '> and S<' *]'>.  They generally
consist of a tag type, followed by a list of attributes, e.g.:

    [* TAG NAME="name of tag" ATTR2="Another" ATTR3 *]

Tag types and attribute names are case-insensitive; tag values
are not.  Therefore, THIS="that" means the same thing as this="that",
but not the same as THIS="THAT".

There are three ways to assign a value to an attribute: using a
double quote, using a single quote, and using no quotes.  These
are all the same:

    [* TAG NAME="thing" *]
    [* TAG NAME='thing' *]
    [* TAG NAME=thing *]

You can't use spaces in an attribute value without putting quotes
around the value.

=head2 General Tags

Tags of general utility.

=item VALUE

Attributes: NAME

Description:
The VALUE tag is the simplest and most commonly-used of
all Boilerplate tags.  It just fills in whatever data
provided by the script.  Since it is so frequently used,
there's a shortcut for it: just use the NAME attribute's
value in quotes, and the Boilerplate module will interpret
it as though it were a VALUE tag.

(N.B.: I have since come to dislike using VALUE as a tag name, since
it's so frequently an attribute.  Be prepared for changes.)

Examples:

    [* VALUE NAME="User Name" *] has [* VALUE NAME="time" *]
    hours left on the system.

    The quick [* "Color" *] [* "Animal" *] jumped over the
    lazy [* "Other Animal" *]


=item REPEAT.../REPEAT

Attributes: NAME

Description:
The REPEAT tag fills in as many copies of whatever is
between it and its closing tag as are required by the
data supplied by the script.

If a SEPARATOR block appears within the REPEAT block,
the contents of SEPARATOR are filled in between every
repetition of the REPEAT block.  Note that SEPARATOR
cannot access data given to the REPEAT block by the script.

Examples:

    <B>The users on this system are:</B>
    <OL>
    [* REPEAT NAME="User List" *]
        <LI>[* "Username" *]
    [* /REPEAT *]
    </OL>


    <B>Your menu item choices:</B>
    [* REPEAT NAME="Menu List" *]
    <P>
        [* "Menu Item" *]
    </P>
    [* SEPARATOR *]
    <HR>
    [* /SEPARATOR *]
    [* /REPEAT *]


=item SEPARATOR.../SEPARATOR

Separates the repeating items in a REPEAT block.  See L<"REPEAT"> for
details.  SEPARATOR's tags are filled in from the same set of values
as the block surrounding the repeat.  (Don't worry about this overmuch.)

=item ENV

Attributes: NAME

Returns the environment variable (or equivalent) for which it's named.
Probably not terribly useful on machines which don't support such
things.  A frequent use of ENV is to create a form that calls its
creating script, like so:

    <FORM METHOD="post" ACTION="[* ENV NAME='SCRIPT_NAME' *]">

Since, in the CGI protocol, SCRIPT_NAME always contains the relative
URL of the current script, the proper URL to call the script would be
filled into the ACTION tag.

The ENV tag opens up potential security holes if you keep sensitive
data hanging around in environment variables.

=item IF.../IF

Attributes: NAME

If the value for which IF is named is true, it fills that in.  If that
value is false, the section remains blank.  If an ELSE block appears
within the IF block, the ELSE block is filled in.  For example:

    [* IF NAME="Items Found" *]
        [* "Items Found" *] items were found.
        [* ELSE *]
            No items were found.
        [* /ELSE *]
    [* /IF *]

=item ELSE.../ELSE

Inside an IF.../IF block, defines what to print if the IF value is
false. See L<"IF">.

=head2 Web Tags

While you're welcome to use the following tags for any purpose,
they're probably most useful in generating HTML pages on-the-fly.

=item INPUT

Attributes: VALUE I<any attribute>

The INPUT tag is used for generating a form input HTML tag with a
dynamic VALUE.  For example:

    <FORM METHOD="post" ACTION="/cgi-bin/other_script.pl">

    <P>
        User Name: [* INPUT NAME="User Name" *]
    </P>

    <INPUT TYPE="submit">

    </FORM>

If the script decided that 'User Name' should be 'Christabel', for
example, the filled-in boilerplate would be:
    

    <FORM METHOD="post" ACTION="/cgi-bin/other_script.pl">

    <P>
        User Name: <INPUT NAME="User Name" VALUE="Christabel">
    </P>

    <INPUT TYPE="submit">

    </FORM>
    
If you wish for the input field to have a default value, you can
specify it using the VALUE attribute, like so:

    [* INPUT NAME="User Name" VALUE="Person From Porlock" *]

That way, if the script doesn't have a value for 'User Name', it will
default to 'Person From Porlock'.

Any other attributes given to INPUT will be copied verbatim into the
filled-in tag, e.g.:

    [* INPUT NAME="User Name" SIZE="20" MAXSIZE="25" *]

will become something like:

    <INPUT NAME="User Name" VALUE="Christabel" SIZE="20" MAXSIZE="25">

Note that I only recommend using INPUT for simple fill-in fields, like
text and number input types.  See L<"RADIO"> and L<"CHECKBOX"> for
more complex form inputs.

=item RADIO

Attributes: NAME VALUE

Used to generate HTML <INPUT TYPE="radio"> tags.  The HTML tag is
marked CHECKED if the value supplied by the script for this tag is
equal to the tag's VALUE attribute.

=item CHECKBOX

Attributes: NAME VALUE

Used to generate HTML <INPUT TYPE="checkbox"> tags.  The HTML tag is
marked CHECKED if one of the values supplied by the script for this
tag is equal to the tag's VALUE attribute.

Programmer's note: takes an array reference as argument.

=item SELECT.../SELECT

ATTRIBUTES: NAME I<any attribute>

The SELECT tag is used to generate option lists with
script-controllable selections.  The options are specified in the
document with HTML <OPTION> tags, just as in ordinary HTML.  Values in
the SELECT tag are passed on into the generated HTML.  For example:

    [* SELECT NAME="Poet" SIZE="4" *]
        <OPTION>Coleridge
	<OPTION>Browning
        <OPTION>Wordsworth
    [* /SELECT *]

If the script chose a value of "Browning" for "Poet", the script would
return:

    <SELECT NAME="Poet" SIZE="4">
        <OPTION VALUE="Coleridge">Coleridge
	<OPTION VALUE="Browning" SELECTED>Browning
	<OPTION VALUE="Wordsworth">Wordsworth
    </SELECT>

Programmer's note: this tag accepts an array ref, permitting multiple
selections that way.

=item MENU

Attributes: NAME I<any>

Used to create an HTML <SELECT> menu on-the-fly for a list of options.
While the Boilerplate SELECT tag chooses from a list of options
already present in the Boilerplate, MENU generates the appropriate tag
from data supplied by the script.

Programmer's note: this tag accepts a list of hashes, a la:

    [ { 'Option' => $opt, 'Value' => $val, 'Selected' => $sel } ... ]

=back

=head1 SEE ALSO

L<perl>, L<Text::Template>, and L<Text::Vpp>.


=head1 COPYRIGHT

Copyright (c) 1997 Steve Nelson. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

senelson@negentropy.com (Steve Nelson)
