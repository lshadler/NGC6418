package Fitsplutils;

# Author: Masaaki Sakano - SSC/LUX

our $VERSION = '1.4.0';
use strict;
use Exporter 'import';
our @EXPORT    = qw(getattribute fparkey fpartab getnaxes tbl2arrays tbl2arraysingle are2tblsequal getfitsheadernumber iscolumnexisting sumup_images readFitsStatInfo);		# symbols to export in default
our @EXPORT_OK = qw(getPerlNumeric getStringHeaderLine);	# symbols to export on request

use strict;
use Data::Dumper;
use SSCLib qw(sscnote sscwarn);

=head1 NAME

Fitsplutils - Basic Perl libraries to handle FITS files.

=head1 SYNOPSIS

    use Fitsplutils;
    use Fitsplutils ();
    use Fitsplutils qw(tbl2arrays sumup_images);
    our $Verbose;	# for sumup_images(), farith_sum_2images()
    our @Tmpfiles2kill;	# for sumup_images()

=head1 DESCRIPTION

Most of subroutines (but farith_sum_2images) can be called as

  my $ret = &THIS_SUBROUTINE(...);

in default, or of course,

  my $ret = &Fitsplutils::THIS_SUBROUTINE(...);

is fine.
The global variable in the MAIN $main::DEBUG is 
taken into account.  This routine uses SSCLib library.

Note that these routines do not carry out FileTest, but just
pass the filenames (+extentions, if specified) to HEASARC/FTOOLS.

=item getattribute ( A.FITS[+1], KEY )

Returns an Array of the header attributes for the Keyword.
Currently this is the wrapper for fkeyprint in FTOOLS.
The return status of fkeyprint can be checked via $? if you wish.
Currently this can get only numerics, logical or string (NOT HISTORY, for example).

=item fparkey ( VALUE, A.FITS+1, KEY, [comm, [add(=no), [insert(=0), [FLAG_IS-SILENT?]]]] )

Wrapper for fparkey in FTOOLS.
Returns the status of fparkey, i.e., usually zero if it normally ends.
The global variable $main::Testflag is taken into account (see run()).
"FLAG_IS-SILENT?" is simply passed to &SSCLib::run() .
As the manual (of fparkey) says:
   To delete the KEYWORD, prefix the keyword with a minus sign.
   To preserve the existing comment, specify null to the 4th.
   To allow to add the KEYWORD, specify the 5th to be yes.
Finally, to see if fparkey (in FTOOLS) has succeeded or not, check $? .

=item fpartab ( VALUE, A.FITS+1, COLUMN_NAME, ROW_No, [FLAG_IS-SILENT?] )

Wrapper for fpartab in FTOOLS.
Returns the status of fpartab, i.e., usually zero if it normally ends.
The global variable $main::Testflag is taken into account (see run()).
"FLAG_IS-SILENT?" is simply passed to &SSCLib::run() .
Finally, to see if fpartab (in FTOOLS) has succeeded or not, check $? .

  &Fitsplutils::fpartab(5.0, "tmp.fits+1", "RATE", 3) and die "Error";

=item getnaxes ( A.FITS[+1] )
Returns an array (for each extention: 0 for Primary) of array describing the size of NAXES in each extention (or Primary).
If the input string includes the extention number, the returned value is a simple 1-dim array of NAXES of the extention.
To see if fkeyprint (in FTOOLS) has succeeded or not, check $? .
Usage examples are as follows.

  @a=&Fitsplutils::getnaxes("tmp.fits");
  printf("Number of extentions is %d)\n", scalar(@{$a})-1);
  printf("NAXES in Primary=(%d,%d,%d)\n", $a[0][0],$a[0][1],$a[0][2];
  printf("NAXES in Extention+3=(%d,%d)\n",$a[3][0],$a[3][1];
  printf("Dimension in Extention+3=%d \n",scalar(@{$a[3]});

  @b=&Fitsplutils::getnaxes("tmp.fits+3");	# With extention.
  printf("NAXES in Extention+3=(%d,%d)\n",$b[0],$b[1];
  printf("Dimension in Extention+3=%d \n",scalar(@b);

=item tbl2arrays ( A.FITS+1, @ARRAY_KEY )

Returns the (reference for) Hash of Array for each table
specified by @ARRAY_KEY in A.FITS+1.
The number of ARRAY_KEY should be reasonably small, such as 6 or smaller
(See the comment lines in subroutine for detail).

=item tbl2arraysingle ( A.FITS+1, KEY )

Returns an Array of the specified table.

  my (@a) = &Fitsplutils::tbl2arraysingle("a.fits+1", "TIME");

=item are2tblsequal ( FITS1+1, FITS2+1, @ARRAY_KEY )

Returns 1 if all the specified column tables are identical between
two input FITS files, or else returns 0.
Note that the contents of the arrays must be numericals (ie, no string).

  print "Equal\n" if &Fitsplutils::are2tblsequal("a.fits+1", "b.fits+1", @ar);

=item getfitsheadernumber ( FITS-FILENAME, Keyword )

Returns the value from the FITS header.

=item iscolumnexisting ( FITS-FILENAME, Column-Keyword )

Returns 1 if the column exists in the FITS, or 0 if not,
or undef if something is wrong.

=item sumup_images (OUTFIL, INFIL1, INFIL2, ...)

Sum up images of INFIL1, 2, ... and output to OUTFIL, using
the following farith_sum_2images(), which uses farith internally.
OUTFIL is overwritten if exists.
Returns 0 for normal end, else farith (or something) goes wrong,
Temporary files are stored in @main::Tmpfiles2kill which are deleted
before exiting the subroutine, unless interrupted by some external signal.

=item farith_sum_2images (OUTFIL, INFIL1, INFIL2)

Sum up two images of infil1, 2, using farith.  See above.

=item readFitsStatInfo (\%Options_Hash)

This is the wrapper routine for the task fitsstat.
This returns a hash of the data as the output of printAryStatInfo(),
or the return status integer of the task fitsstat if it fails, such as,
the file is not found and/or the Minimum/Maximum locations are inconsistent.
The keys in the returned hash are 
 ("Total sum", "Real sum", "Mean", "Sigma", "Total area", "Valid entry",
  "Minimum value", "Maximum value",
  "Minimum location", "Maximum location",
  "Lower threshold used?", "Lower threshold",
  "Upper threshold used?", "Upper threshold",
  "Lower area constrain used?", "Lower area boundary",
  "Upper area constrain used?", "Upper area boundary",
  "External mask used?", "Return status").
If it is a logical value, it gives either 1 (True) or 0 (False).
Some keys may be undefined, if that is the case (in printAryStatInfo()).
"(Lower|Upper) area boundary" and "(Minimum|Maximum) location"
are the reference to an array, if exist, otherwise the key itself is undefined.

The input argument (hash) is passed to fitsstat as they are.
For example, when an element is 'set'=>'a.fits' then
it will be expanded as "fitsstat set=a.fits" etc.
At the time of writing, 
  qw(set minareacoords maxareacoords vallower valupper)
are of particular use.

Note that the numerical figures are probably retained as raw strings
taken from the output of fitsstat, namely '3.43E+02' or '343',
as opposed to 343.0 or 343, whether it is Float or Integer.
It is Perl, so there is no need or no use to _convert_!

=cut
  ;	# For Emacs


############################################################

#---------------------------------------------------------------------
sub getattribute {
#---------------------------------------------------------------------
  ### Input:  (FITS[+n], KEYWORD)
  ### Return: (VAL1, [VAL2, ...])
  ### Description: Get the "Array" of the header attributes for the Keyword.
  #    This is the wrapper for fkeyprint in FTOOLS.
  #    If it is String, then CONTINUE keywords are taken into account
  #    and the entire string is recovered.  Also the escape sequence of
  #    the single-quote is taken into account.  The trailing spaces
  #    are omitted, following the FITS standard.
  #    To see if fkeyprint has succeeded or not, check $? .
  ### Constraints:
  #    1. Can get only numerics, logical or string (NOT HISTORY, for example).
  #    2. Unless specified explicitly in the (1st) argument,
  #       you never know which extension(s) contains the keyword.
  ### Global: 
  ### Usage example:
  # @a=&Fitsplutils::getattribute("tmp.fits+1", "NAXIS");
  # printf "NAXIS=%i\n",$a[0];

  my ($fits) = shift;
  my ($key)  = shift;
  my ($quoted) = quotemeta(uc($key));
  my (@arret) = ();
  my ($strattone, $iscontinue, $strcomment);
  my ($s);

  $iscontinue = 0;	# False
  open FKEYIN, "fkeyprint infile=$fits keynam=$key outfil=STDOUT exact=yes |";
  while(<FKEYIN>){
    if (/^\s*$/ || /^\s*#/) {
      $iscontinue = 0;	# False
      next;
    } elsif ($iscontinue) {					# CONTINUE
      if ( /^CONTINUE\s+'(.*)'/i ){			# String
	($strattone, $iscontinue, $strcomment) = &getStringHeaderLine($1);
	$arret[-1] .= $strattone;
      } else {
	$iscontinue = 0;	# False
	warn "(ssclib/Fitsplutils::getattribute) The line here read by fkeyprint seems to violate the FITS standard.  The previous line ends with '&', so CONTINUE is expected here, however the line (see below) is different.\n$iscontinue";
	redo;	# In case the same keyword reappears in this line.
      }

    } elsif( /^$quoted\s*=\s+'(.*)'/i ){			# String
	($strattone, $iscontinue, $strcomment) = &getStringHeaderLine($1);
	push(@arret, $strattone);

    } elsif( /^$quoted\s*=\s+([0-9tfed+\-\.]*)(\s+\/\s+)?/i ){	# Numeric/Logical
      $strattone = $1;
      push(@arret, &getPerlNumeric($strattone));
      ## NOTE: Based on the FITS standard, this could be
      ##   "456.0+12", which means 456E12,
      ##   "456.0D-12", etc.
      ##  Perl would not understand them as Numeric, so it converts here.

    } else {
      ## Do nothing.
    }
    # next if (/^\s*$/ || /^\s*#/);
    # if( /^$quoted\s*=\s+([0-9tfe+\-\.]*)(\s+\/\s+)?/i ){
    #   push(@arret, $1);
    # }
  }
  close FKEYIN;
  return(@arret);
}


#---------------------------------------------------------------------
sub getPerlNumeric {
#---------------------------------------------------------------------
  ### Input:  (Numeric-String (in FITS standard) or T/F)
  ### Output: (Numeric-String (in Perl standard) or T/F)
  ### Description:
  ###  Convert some of the FITS-standard based (some of which are
  ###  Fortran-based) into the STRING, which Perl can interprete
  ###  as Numeric, and return it.
  ### Examples:
  ###   &getPerlNumeric("456.0+12") -> "456.0E+12"
  ###   &getPerlNumeric("-56.0d78") -> "-56.0E78"
  ###   &getPerlNumeric("-56.0e78") -> "-56.0E78"
  ###  

  my($str) = shift;

  $str =~ s/^\s*//;
  $str =~ s/^([+\-]?)0+/${1}0/;		# Delete extra initial zeros.
  $str =~ s/^([+\-]?)0([1-9])/$1$2/;	# Delete extra initial zeros (to prevent the octal interpretation by Perl).
  $str =~ s/^([+\-]?(?:(?:0|[1-9]\d*)?\.[0-9]+|(?:0|[1-9]\d*)\.?))[EeDd]/$1E/;	# Convert D -> E
  $str =~ s/^([+\-]?(?:(?:0|[1-9]\d*)?\.[0-9]+|(?:0|[1-9]\d*)\.?))([+\-]\d+)$/$1E$2/;	# Convert *[+-]* (no E mark) -> *E*

  return($str);
}


#---------------------------------------------------------------------
sub getStringHeaderLine {
#---------------------------------------------------------------------
  ### Input:  (STRING)
  ###   STRING is a one line from a FITS header, where the initial string
  ###   up to the first single-quote should be omitted.
  ###   Optionally the last single-quote can be omitted.
  ###   STRING is allowed to contain the trailing comment.
  ### Return: (STRING(trimmed-with-&), 0(no-&)/1(with-&), Trailing-Comment)
  ### Description:
  ###  This routine returns the proper FITS-header-Attribute string
  ###  by trimming the trailing space and/or ampersand and recovering
  ###  proper single-quotes if any, as well as the flag showing
  ###  whether it expects further strings in CONTINUE keyword,
  ###  and finally the trailing comment (which may be an empty string).
  ###  In short,
  ###  if yes,  return (recovered-STRING, 1, Comment-String),
  ###  or else, return (recovered-STRING, 0, Comment-String).
  ###
  ### FITS-standard (Version 3.0; 2008/07/10):
  ###  * A beginning "'" in column 11.
  ###  * Leading blanks are significant, trailing blanks are not.
  ###  * A single-quote "'" in string is represented as "''".
  ###  * An ending "'".  This used to be specified in or after column 20,
  ###    but that restriction is not applied any more in Version 3.0.
  ###  * After the ending "'", a comment line can follow, starting with "/"
  ###    (though the existence of "/" is (or was?) not mandatory).
  ### Examples:
  ###  STREXMP1= ''     / Null string.
  ###  STREXMP2= '   '  / Empty string.
  ###  STREXMP3=        / Undefined.
  ###
  ### FITS HEASARC convention:
  ###  http://heasarc.nasa.gov/docs/software/fitsio/c/c_user/node114.html
  ###   Uses an ampersand "&" at the end of each substring to indicate
  ###   that it is continued on the next keyword, and the continuation keywords
  ###   all have the name CONTINUE without an equal sign in column 9.
  ### Example:
  ###  STRKEY  = 'This is a very long string keyword&'  / Optional Comment
  ###  CONTINUE  ' value that is continued over 3 keywords in the &  '
  ###  CONTINUE  'FITS header.' / This is another optional comment.
  ###  

  my ($strinput) = shift;
  my ($strret) = "";
  my ($strcomment) = "";
  my ($iscontinued) = 0;	# False
  my ($i,$s);
  my (%flag) = ('wassquote' => 0);

  # NOTE:
  # Recovering single-quotes and trim down the possibly trailing comment.
  #  n.b., the trailing comment may include single-quotes, and
  #  therefore it is needed.
  for($i=0; $i<length($strinput); $i++) {
    $s = substr($strinput,$i,1);
    if ($flag{'wassquote'}) {	# The previous character is a single quote.
      if ($s eq "'") {	#' Two consecutive single-quotes are found.
	$strret .= "'";	#'
	$flag{'wassquote'} = 0;
      } else {
	# This should be the end of the string, and the rest, if there is any,
	# should be a trailing comment.
	last;
      }
    } else {
      if ($s eq "'") {	#' This should either be the first of 2 consecutive single-quotes or indicates the end of the input String.
	$flag{'wassquote'} = 1;
	next;
      } else {
	$strret .= $s;	# Normal string.
      }
    }
  }
 
#print "here-come ,length=",length($strinput)," i=", $i,"\n";
  if (length($strinput) > $i) {
    $strcomment = substr($strinput,$i);
#print "strcomment=(",$strcomment,")", "\n";
    $strcomment =~ s@^\s*/?\s*@@
  }

  $iscontinued = 1 if ($strret =~ /&\s*$/);
  $strret =~ s/\s*&?\s*$//;

  return($strret, $iscontinued, $strcomment);
}


#---------------------------------------------------------------------
sub fparkey {
#---------------------------------------------------------------------
  ### Input:  (VALUE, FITS+1, KEYWORD, [comm, [add(=no), [insert(=0), [FLAG_IS-SILENT?]]]])
  ### Return: Status of fparkey, i.e., usually zero if it normally ends.
  ### Description: Wrapper for fparkey in FTOOLS.  As the manual says:
  #    To delete the KEYWORD, prefix the keyword with a minus sign.
  #    To preserve the existing comment, specify null to the 4th.
  #    To allow to add the KEYWORD, specify the 5th to be yes.
  #    "FLAG_IS-SILENT?" is passed to &SSCLib::run() .
  #    To see if fparkey (in FTOOLS) has succeeded or not, check $? .
  ### Global: $main::Testflag
  ### Usage example:
  # &Fitsplutils::fparkey(1950.0, "tmp.fits+1", "EQUINOX") and die "Error";

  my ($val)  = shift;
  my ($fits) = shift;
  my ($key)  = shift;
  my ($comm)   = shift;
  my ($add)    = shift;
  my ($insert) = shift;
  my ($flagsilent) = shift;

  my (@arcom) = ("fparkey", "value=$val", "fitsfile=$fits", "keyword=$key");
  push(@arcom, "comm='$comm'")   if (defined($comm)   && ($comm !~ /^\s*$/));
  push(@arcom, "add=$add")       if (defined($add)    && ($add  !~ /^\s*$/));
  push(@arcom, "insert=$insert") if (defined($insert) && ($insert !~ /^\s*$/));

  if (defined($flagsilent)) {
    return(&SSCLib::run( join(" ", @arcom), $flagsilent ));
  } else {
    return(&SSCLib::run( join(" ", @arcom) ));
  }
}


#---------------------------------------------------------------------
sub fpartab {
#---------------------------------------------------------------------
  ### Input:  (VALUE, FITS+1, COLUMN, ROW, [FLAG_IS-SILENT?])
  ### Return: Status of fpartab, i.e., usually zero if it normally ends.
  ### Description: Wrapper for fpartab in FTOOLS.  As the manual says:
  #    "FLAG_IS-SILENT?" is passed to &SSCLib::run() .
  #    To see if fpartab (in FTOOLS) has succeeded or not, check $? .
  ### Global: $main::Testflag
  ### Usage example:
  # &Fitsplutils::fpartab(5.0, "tmp.fits+1", "RATE", 3) and die "Error";

  my ($val)  = shift;
  my ($fits) = shift;
  my ($column) = shift;
  my ($row)    = shift;
  my ($flagsilent) = shift;

  my (@arcom) = ("fpartab", "value=$val", "fitsfile=$fits", "column=$column", "row=$row");
  # push(@arcom, "comm='$comm'")   if (defined($comm)   && ($comm !~ /^\s*$/));

  if (defined($flagsilent)) {
    return(&SSCLib::run( join(" ", @arcom), $flagsilent ));
  } else {
    return(&SSCLib::run( join(" ", @arcom) ));
  }
}


#---------------------------------------------------------------------
sub getnaxes {
#---------------------------------------------------------------------
  ### Input:  (FITS[+n])
  ### Return: ([NAXIS1, NAXIS2, ...], [[NAXIS1, NAXIS2, ...]])
  ###      or (NAXIS1, NAXIS2, ...) if +n is there in the Input.
  ### Description: Get the NAXES values of the input FITS.
  #    Uses fkeyprint in FTOOLS in it.
  #    To see if fkeyprint has succeeded or not, check $? .
  #    +n could be with preceeding zeros, like "012", for the extention No.12.
  ### Global: 
  ### Usage example:
  # @a=&Fitsplutils::getnaxes("tmp.fits");
  #  printf("Number of extentions is %d)\n", scalar(@{$a})-1);
  #  printf("NAXES in Primary=(%d,%d,%d)\n", $a[0][0],$a[0][1],$a[0][2];
  #  printf("NAXES in Extention+3=(%d,%d)\n",$a[3][0],$a[3][1];
  #  printf("Dimension in Extention+3=%d \n",scalar(@{$a[3]});
  # @b=&Fitsplutils::getnaxes("tmp.fits+3");	# With extention.
  #  printf("NAXES in Extention+3=(%d,%d)\n",$b[0],$b[1];
  #  printf("Dimension in Extention+3=%d \n",scalar(@b);

  my ($fits) = shift;

  my (@arret);
  my $ext = -1;

  open FKEYIN, "fkeyprint infile=$fits keynam=NAXIS outfil=STDOUT exact=no |";
  while(<FKEYIN>){
    if (/^\s*$/) {
      next;
    } elsif (/^\s*#\s*EXTENSION(?:\s|:)\s*(\d+)/) {	#
      $ext = $1;
      if ($#arret < $ext) {
	$arret[$ext] = [];
      };
    } elsif (/^\s*#/) {
      next;
    } elsif (/^NAXIS\s+=\s*(\d+)/) {
      if ((scalar(@{$arret[$ext]}) <= 0) && ($1 > 0)) {
	$arret[$ext][$1-1] = undef;	# Initialisation
      }
    } elsif (/^NAXIS(\d+)\s*=\s*(\d+)/) {
	$arret[$ext][$1-1] = $2;	# NAXIS
    }
  }	# while(<FKEYIN>)

  close FKEYIN;

  if ($fits =~ /\+(\d+)$/){
    @arret = @{$arret[$1]};	# Returns a normal 1-dim array if the extention is given in the Input.
  }

  return(@arret);
}


#---------------------------------------------------------------------
sub tbl2arrays {
#---------------------------------------------------------------------
  ### Input:  (FITS+1, @array_key)
  ### Return:
    ### \%hs --> ('TIME' => [3, 4, 5], 'RATE' => [5.6, 2.3, 1.5])
  ### Constraints:
  #    Because this utilises fdump in it, if one line of any row exceeds
  #  256 characters, fdump does not overlaps, of which the case this routine
  #  does not handle.  Therefore it is recommended to limit the number of
  #  column keywords to a reasonablly small, such as 6.
  #    As a future work, it is possible to use flist instead of fdump
  #  to avoid this potential problem (although flist is not as robust as
  #  fdump at the time of this writing, and so it may crash(!)).
  ### Global: $main::DEBUG
  ### Usage example:
  # my(%r,$a);
  # $a=&Fitsplutils::tbl2arrays("tmp.fits+1", qw(TIME RATE));
  # %r=%$a;	# %r = {'TIME' => [1, 2, 3], 'RATE' => [2.3, 4.5, 6.7]}
  #             # $r{'RATE'}[2] == 6.7; @{$r{'RATE'}} == (2.3, 4.5, 6.7)

  my ($fits) = shift;
  my (@arkey) = @_;
  my %hstbl;	# To return
  my @line;
  my($strkey, $i, $eachk);

  foreach $eachk (@arkey) {
    $hstbl{$eachk} = [];
  }

  $strkey = join(',', @arkey);
  open INFITS, "fdump page=no prhead=no pagewidth=256 $fits STDOUT $strkey - |" or die "Failed to open: $!\n";
  while (<INFITS>) {
    chomp;
    next if ! /^\s*\d/;
    $i=1;
    @line = split;
    foreach $eachk (@arkey) {
      push(@{$hstbl{$eachk}}, $line[$i]);
      $i++;
    }
  }
  close INFITS;

  return(\%hstbl);
}


#---------------------------------------------------------------------
sub tbl2arraysingle {
#---------------------------------------------------------------------
  ### Input:  (FITS+1, COLUMN_KEY)
  ### Return: A single Array, based on the input Table
  ### Constraints: see descriptions in sub tbl2arrays
  ### Descriptions: Wrapper of tbl2arrays().
  ### Global: $main::DEBUG
  ### Usage example:
  # @a=&Fitsplutils::tbl2arraysingle("tmp.fits+1", "TIME");

  my ($fits)   = shift;
  my ($keycol) = shift;
  my (%r,$a);
  $a=&Fitsplutils::tbl2arrays($fits, $keycol);
  %r=%$a;
  return @{$r{$keycol}};
}


#---------------------------------------------------------------------
sub are2tblsequal {
#---------------------------------------------------------------------
  ### Input: (FITS1+1, FITS2+1, @array_key)
  ### Return: 1 if all equal, 0 if not.
  ### Descriptions: Compares the (numerical) column(s) of FITS1 and 2.
  ### Global: $main::DEBUG

  my ($fits1) = shift;
  my ($fits2) = shift;
  my (@arkey) = @_;

  my(%hs1,$a1,%hs2,$a2);	# Hash (and temporary Array) etc.
  my($s1, $s2, $eachk);		# String
  $a1=&tbl2arrays($fits1, @arkey); %hs1=%$a1;
  $a2=&tbl2arrays($fits2, @arkey); %hs2=%$a2;

  if ($#{$hs1{$arkey[0]}} != $#{$hs2{$arkey[0]}}) {
    return 0;
  } else {
    ## Algorithm: Join everything in order in all the Array-s in each Hash and compare the results.
    foreach $eachk (@arkey) {
      $s1 .= join(',', map {$_+=0.0} @{$hs1{$eachk}});	# Convert all into Double
      $s2 .= join(',', map {$_+=0.0} @{$hs2{$eachk}});
    }

    if ($s1 eq $s2) {
      return 1;
    } else {
      if ($main::DEBUG) {
	print Dumper \$s1;
	print Dumper \$s2;
      }
      return 0;
    }
  }
}


######## from Thumb.pm ########

#---------------------------------------------------------------------
sub getfitsheadernumber {
#---------------------------------------------------------------------
  # Input: (FITS-FILENAME, Keyword)
  # Return: (Value) or undef if something is wrong.
  # Description: Return the value from the FITS header
  # Example: &SSCLib::getfitsheadernumber("a.fits+0", "RA_NOM")

  my $fits = shift;
  my $key = shift;
  my $line;

  open(FH_GETFITSHEADERNUMBER,"fkeyprint $fits $key exact=yes|") or return(undef);
  while ($_=<FH_GETFITSHEADERNUMBER>) {
    chop;
    &SSCLib::strip;
    next if $_ eq "";
    next if /^#/;
    if (/^$key/) {
      s/^$key\s*=//;
      $line=$_;
      last;
    }
  }
  close(FH_GETFITSHEADERNUMBER);
  return(undef) if (!defined($line));

  $_=$line;
  s/\/.*//;
  &SSCLib::strip;
  return($_);
}


#---------------------------------------------------------------------
sub iscolumnexisting {
#---------------------------------------------------------------------
  # Input: (FITS-FILENAME, Column-Keyword)
  #        Keyword has to be (probably) capital letters.
  # Return: 1 if yes, or 0 if no, or undef if something is wrong.
  # Example: &SSCLib::iscolumnexisting("a.fits+1", "EP_1_ML_ID")  # => 1|0

  my $fits = shift;
  my $key = shift;

  open(FH_ISCOLUMNEXISTING,"flcol $fits nlist=1|") or return(undef);
  while ($_=<FH_ISCOLUMNEXISTING>) {
    chop;
    &SSCLib::strip;
    if ($_ eq $key) {
      close(FH_ISCOLUMNEXISTING);
      return 1;
    }
  }
  close(FH_ISCOLUMNEXISTING);

  return 0;		# The column NOT exists.
}


#---------------------------------------------------------------------
sub sumup_images {
#---------------------------------------------------------------------
  ## Input: (OUTFIL, INFIL1, INFIL2, ...)
  ## Return: 0 for normal end, else farith (or something) goes wrong,
  ##         unless ARG is wrong.
  ## Description: Sum up images of INFIL1, 2, ... and output to OUTFIL.
  ## NOTE: Summmation is made as INFIL1+2+3+4... _SEQUENTIALLY_,
  ##  therefore it may be prone to rounded errors.
  ##  OUTFIL is overwritten if exists.
  ##  Global variable $main::Verbose is preferrably defined.
  ##    @main::Tmpfiles2kill in case for an accidental exit.
  ## Example: sumup_images($hsimage{6},$hsimage{1},$hsimage{2},$hsimage{3})

  ## Algorithm:
  ##   INFIL1 + INFIL2 => TMPFIOUT
  ##    mv TMPFILOUT TMPFILIN
  ##   TMPFILIN + INFIL3 => TMPFILOUT
  ##    mv TMPFILOUT TMPFILIN
  ##   TMPFILIN + INFIL4 => TMPFILOUT
  ##    mv TMPFILOUT TMPFILIN
  ##    ...
  ##   TMPFILIN + INFIL_LAST => OUTFIL


  my ($outfil) = shift;
  my (@arinstin) = @_;
  my ($tmpinfile, $tmpoutfile, %artmpfh, %artmpfile);
  return(undef) if ($#arinstin < 1);

  my ($status, $t);
  foreach $t (@arinstin) {
    if (!defined($t)) {
      &sscwarn("Input file is undefined.");
      return(99);
    } elsif (! -r $t) {
      &sscwarn("File($t) not exists/readable.");
      return(99);
    }
  }

  ## UNLINK is set to 0, because otherwise the GC may delete the
  ## file before the following processing, where the file is still used.
  $artmpfh{'out'} = new File::Temp(TEMPLATE => "tmp_thumb_sumup_out_XXXXXXXXXX",    DIR => '.', SUFFIX => '.fits', UNLINK=>0);
  $tmpoutfile = $artmpfh{'out'}->filename;	## Output filename
  $artmpfile{'out'} = $tmpoutfile;		## Output filename
  push(@main::Tmpfiles2kill, $artmpfile{'out'});

  $artmpfh{'in'}  = new File::Temp(TEMPLATE => "tmp_thumb_sumup_in_XXXXXXXXXX", DIR => '.', SUFFIX => '.fits', UNLINK=>0);
  $tmpinfile  = $artmpfh{'in'}->filename;	## Input filename
  $artmpfile{'in'} = shift(@arinstin);		## First Input filename
  push(@main::Tmpfiles2kill, $artmpfile{'in'});
  my ($lastimg) = pop(@arinstin);

  ## NOTE: The first(=$ARGV[1]) and last image filenames are already removed from @arinstin
  foreach $t (@arinstin) {
    ## If only two images are specified, this loop is skipped.

    $status=&farith_sum_2images($artmpfile{'out'}, $artmpfile{'in'}, $t);
    if ($status != 0) {
      unlink($tmpinfile)  if (-e $tmpinfile);
      unlink($tmpoutfile) if (-e $tmpoutfile);
      pop(@main::Tmpfiles2kill);
      pop(@main::Tmpfiles2kill);
      return($status);
    }


    ### Preparation for the next operation.
    ## Current output -> next input
    $artmpfile{'in'} = $tmpinfile;
    &sscnote("rename $artmpfile{'out'} $artmpfile{'in'}") if ($main::Verbose);
    $status=rename($artmpfile{'out'}, $artmpfile{'in'});
    if ($status != 1) {
      unlink($tmpinfile)  if (-e $tmpinfile);
      unlink($tmpoutfile) if (-e $tmpoutfile);
      pop(@main::Tmpfiles2kill);
      pop(@main::Tmpfiles2kill);
      return(! $status);
    }

    ## Next output
    $artmpfh{'out'} = $tmpoutfile;	## Output filename
  }

  ## If only two images are specified, only the following is executed.
  $status=&farith_sum_2images($outfil, $artmpfile{'in'}, $lastimg);

  unlink($tmpinfile)  if (-e $tmpinfile);
  unlink($tmpoutfile) if (-e $tmpoutfile);
  pop(@main::Tmpfiles2kill);
  pop(@main::Tmpfiles2kill);
  # $artmpfh{'in'}->unlink_on_destroy( 1 );	## Method not supported
  # $artmpfh{'out'}->unlink_on_destroy( 1 );	## Method not supported

  return($status);
}


#---------------------------------------------------------------------
sub farith_sum_2images {
#---------------------------------------------------------------------
  ## Input: (outfil, infil1, infil2)
  ## Description: Sum up two images of infil1, 2.
  ## NOTE: outfil is overwritten if exists.
  ##  Global variable $main::Verbose is preferrably defined.

  my ($outfil, $infil1, $infil2) = @_;
  my ($command, $status);

  $command = "farith "
    ."infil1=$infil1 "
    ."infil2=$infil2 "
    ."outfil=$outfil "
    ."ops=ADD "
    ."clobber=yes"
    ;

  $status=&SSCLib::run("$command", (! $main::Verbose));

  if ($status){
      warn "Failed to make the image ($outfil) (status=$status).\n";
  }
  return($status);
}


#---------------------------------------------------------------------
sub readFitsStatInfo {
#---------------------------------------------------------------------
  ## Input: (\%options)
  ##   All the options are passed to fitsstat as they are.
  ##   For example, when an element is 'set'=>'a.fits' then
  ##   it will be expanded as "fitsstat set=a.fits" etc.
  ##   At the time of writing, 
  ##     qw(set minareacoords maxareacoords vallower valupper)
  ##   are of particular use.
  ## Return: Data Hash (or $status if not normal ends).
  ##   n.b., use it as, for example,
  ##    %opt=('set'=>'a.fits', 'vallower'=>2.5);
  ##    ($a)=&readFitsStatInfo(\%opt); 
  ##    if (ref($a)) {
  ##      %r=%$a;
  ##    } else {
  ##      warn "Not REFERENCE!  Status=($a).";
  ##    }
  ## Global: $main::Verbose
  ## Description: This is the wrapper routine for the task fitsstat.
  ##   This returns the data hash as the output of printAryStatInfo().
  ##   If it is a logical value, it gives either 1 (True) or 0 (False).
  ##   Some keys may be undefined, if that is the case (in printAryStatInfo()).

  my ($Commandroot) = "fitsstat";
  my ($Commandrootquoted) = quotemeta($Commandroot);
  my $arg = shift;
  my %hsinopt = %$arg;       # dereference
  my %hsret;
  my (@artmp, $s);
  my ($status, $comstdout);
  my ($line, $key, $value);

  ($status, $comstdout)
    = &SSCLib::run_with_stdout( &SSCLib::getsascommandstring($Commandroot, \%hsinopt), (! $main::Verbose));
  return $status if ($status != 0);	# Error!

  foreach $line ( split(/\s*\n\s*/, &SSCLib::strip($comstdout)) ) {
    next if $line eq '';
    next if $line =~ /^${Commandrootquoted}:-/;
    @artmp = split(/\s*=\s*/, $line);
    if ($#artmp < 1) {
      next;
    } elsif ($#artmp > 1) {
      &SSCLib::warn("Line ($line) looks strange.  Skip.");
      next;
    }

    ($key, $value) = @artmp;	# (
    $key =~ s/\s*\([^)]*\)//g;	# Remove the part of "(...)", if there is any.

    if ($value =~ /^\s*\(\s*([^)]*)\s*\)\s*$/) {
      ## If it is a list, then it is reassigned as an array.
      ## e.g.:  Maximum location = (    174,    155)
      $s = $1;
      $value = [split(/\s*,\s*/, $s)];
    } elsif ($value =~ /^[TF]$/) {	# True|False
      if ($value eq 'T') {	# True|False
	$value = 1;	# True
      } else {
	$value = 0;	# False
      }
    }

    $hsret{$key} = $value;

    #                        Total sum =   3.0370000000E+03
    #                         Real sum =   3.0370000000E+03
    #                             Mean =   7.5925000012E-02
    #                            Sigma =   4.1498228908E-01
    #                       Total area =             419904
    #                      Valid entry =              40000
    #                    Minimum value =   0.0000000000E+00
    #                    Maximum value =   1.3000000000E+01
    #                 Minimum location = (      1,      1)
    #                 Maximum location = (    174,    155)
    #      Lower threshold used? (T/F) =   T
    #                  Lower threshold =   0.0000000000E+00
    #      Upper threshold used? (T/F) =   T
    #                  Upper threshold =   1.0000000000E+02
    # Lower area constrain used? (T/F) =   T
    #              Lower area boundary = (      1,      1)
    # Upper area constrain used? (T/F) =   T
    #              Upper area boundary = (    200,    200)
    #        External mask used? (T/F) =   F
    #         Return status (normal:0) =     0

  }

  return(\%hsret)
}


1;


########################  TEST ########################

# perl -e 'use strict;use Data::Dumper;use Fitsplutils; my(%r,$a);$a=&Fitsplutils::tbl2arrays("tmp.fits+1", qw(TIME RATE));%r=%$a;print Dumper \%r;print $r{"RATE"}[2],"\n"; print join("_",@{$r{"RATE"}}),"\n"'
# perl -e 'use strict;use Data::Dumper;use Fitsplutils; my(@a)=&Fitsplutils::tbl2arraysingle("tmp.fits+1", "TIME");print Dumper \@a; print join(", ",@a),"\n";'
# perl -e 'use strict;use Fitsplutils; print &Fitsplutils::are2tblsequal("tmp.fits+1", "tmp.fits+1", qw(TIME RATE)), "\n";'	# => 1
#
