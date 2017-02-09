package LineParser;
require 5.004;
use Carp;
use strict;
use FileHandle;
use LineField;

my $SEPARATOR = undef;

sub setSeparator {
    my $class = shift;
    my $sep = shift || $SEPARATOR;
    $SEPARATOR = $sep;
}
    
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $line = shift;
    croak "Must supply a string\n" if not defined $line;
    my $self = {};
    $self->{LINE} = $line;
    $self->{FIELDS} = [];
    $self->{N_FIELDS} = 0;
    bless $self, $class;
    $self->cleanup;
    $self->parse;
    return $self;
}

sub cleanup {
    my $self = shift;
    my $string = $self->{LINE};
    $string =~ s/^\s*//;
    $string =~ s/\s*$//;
    $self->{LINE} = $string;
}

sub count {
    my $self = shift;
    my $char = shift;
    croak "Must specify character\n" if not defined $char;
    my @n = $self->{LINE} =~ /$char/g;
    return scalar @n;
}

sub positions {
    my $self = shift;
    my $char = shift;
    croak "Must specify character\n" if not defined $char;
    my @pos;
    my $pos = -1;
    while(($pos = index($self->{LINE}, $char, $pos)) > -1) {
	push @pos, $pos;
	$pos++;
    }
    return @pos;
}

sub parse {
  my $self = shift;
  die "Uneven number of double quotes found. Cannot parse this line:\n" .
    "-->" . $self->{LINE} . "<--\n" if($self->count('"') % 2 != 0);
  
  my @fields;
  
  if(defined $SEPARATOR and $SEPARATOR ne ' ') {
    # The user defined the column separator, a simple split on
    # that is all that is required at this stage.
    @fields = split /$SEPARATOR/, $self->{LINE};
    if($ENV{"VERBOSE"}){
      my $k = 0;
      print "\n";
      for(@fields){
	print $k," = ",$SEPARATOR,$fields[$k],$SEPARATOR,"\n";
	++$k;
      }
    }
  } else {    
    # No separator was defined. Need to worry about strings right
    # away. 
    if($self->count('"') == 0) { # there are no embedded strings.
      @fields = split ' ', $self->{LINE}; # split on whitespace
    } else { # there are strings.
      my @positions = $self->positions('"');
      my $lo = 0;
      my $thislong = $positions[0];
      while(defined $positions[$#positions]) {
	
	# Process the segment befor the first "
	push @fields, (split  ' ', (substr $self->{LINE}, $lo, $thislong));
	$lo += $thislong;
	
	# Process the segment between two "
	$thislong = $positions[1] - $positions[0] + 1;
	push @fields, (substr $self->{LINE}, $lo, $thislong);
	
	# Move forward
	$lo += $thislong;		
	shift @positions;
	$thislong = ($positions[1]  or length $self->{LINE}) - $positions[0] - 1;			
	shift @positions; 
      }
      push @fields, (split ' ', (substr $self->{LINE}, $lo, length $self->{LINE}));
    }
  }
  my $fcount = 0;
  # Here we have to cover the following cases:
  #  [1]  ... <sep> i1 i2 i3 ... <sep>  => for vector columns
  #  [2]  ... <sep> some string with "<sep> => for string columns
  #  [2b] ... <sep>long string without quotes<sep> => for string columns
  #  [3]  cases without the separator:
  #     [3a] i1 i2 i3 string_without_blanks
  #     [3b] i1 i2 i3 "string with blanks"
  #
  # [1] and [2b] cannot be distinguished, unless we have some clue that
  # we are dealing with strings and not with a vector of numbers. So I
  # decide that this clue is given by ''. So [2b] becomes:
  #  [2b] ... <sep>'long string without quotes'<sep> 
  foreach(@fields) {
    my $this = $_;
    # If there is a " and no separator was defined, then we are
    # dealing with strings enclosed in "". Remove the "". This is case
    # [3b].
    #
    # If there is a " and the separator was defined, then we
    # are dealing with a string with embedded ". This is case
    # [2]. Don't remove the "" because the are meant to go in the
    # output file. 
    #
    # If there is no ", and no separator was defined we are dealing
    # with [3a].
    # 
    # If there is no ", and the separator was defined, and the first
    # non blank character is ', then we are dealing with [2b].
    # Otherwise we are dealing with [1].
    if(/\"/) {
      $this =~ s/\"//g unless (defined $SEPARATOR and $SEPARATOR ne ' ');
      $self->{FIELDS}->[$fcount] = $this;
    } else {
      if(defined $SEPARATOR and $SEPARATOR ne ' ' and $this =~ /^\s*'/){
        $this =~ s/^\s*'//;
	$this =~ s/'\s*$//;
	$self->{FIELDS}->[$fcount] = $this;
      } else {
	my @subfields = split ' ', $this;
	$self->{FIELDS}->[$fcount] = \@subfields;
      }
    }
    $fcount++;
  }
  $self->{N_FIELDS} = $fcount;
}

sub getField {
    my $self  = shift;
    my $index = shift;
    croak "Must give a column index >= 0.\n" if ($index < 0);
    LineField->new($self->{FIELDS}[$index]) || croak "Column $index does not exist.\n";
}
1;

sub nFields
{
    my $self = shift;
    return $self->{N_FIELDS};

}
