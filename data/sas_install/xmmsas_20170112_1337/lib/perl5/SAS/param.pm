#  Giuseppe Vacanti (cosine science & computing bv)
#  January 31, 2003
# 
#   $Id: param.pm,v 1.6 2003/06/13 10:21:12 gvacanti Exp $
package SAS::param;

require 5.005;

use Env;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw (parameterCount intParameter realParameter
	      stringParameter booleanParameter);

# This line must not be broken (development)
$VERSION = do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

use SAS::error;

my $first = 1;

# On the command line: param="v1 v2 v3"
# ARGV contains: param=v1 v2 v3
# This function puts the quotes back so that the parameter library works.
sub _treat_argv {
  if($first){
    undef $first;
    foreach(@ARGV){
      s/=/="/;
      $_ .= '"';
    }
  }
}


# These are perl interfaces to the tool sasparam.
# We append @ARGV to each command line because sasparam will 
# pass it to the parameter library to be scanned.

sub parameterCount {
  &_treat_argv();
  my $name = shift;
  my $c = sprintf("sasparam %s -c %s", &SAS::error::client() , $name);
  $c = "$c @ARGV";
  my $ret = qx/$c 2>&1/; # perldoc -f system
  my $x = $? >> 8;
  if($x){
    SAS::error::fatal("parameterCount", $ret);
  }
  chomp($ret);
  return $ret;
}

sub intParameter {
  &_treat_argv();
    my ($name, $pos) = @_;
    $pos = -1 unless defined $pos;
    my $c = sprintf("sasparam %s -i %s %d", &SAS::error::client() , $name, $pos);
    $c = "$c @ARGV";
     my $ret = qx/$c 2>&1/;
    my $x = $? >> 8;
    if($x){
	SAS::error::fatal("intParameter", $ret);
      }
    chomp($ret);
    return $ret;
}

sub realParameter {
  &_treat_argv();
    my ($name, $pos) = @_;
    $pos = -1 unless defined $pos;
    my $c = sprintf("sasparam %s -r %s %d", &SAS::error::client() , $name, $pos);
    $c = "$c @ARGV";
    my $ret = qx/$c 2>&1/;
    my $x = $? >> 8;
    if($x){
	SAS::error::fatal("realParameter", $ret);
      }
    chomp($ret);
    return $ret;
}

sub stringParameter {
  &_treat_argv();
    my ($name, $pos) = @_;
    $pos = -1 unless defined $pos;
    my $c = sprintf("sasparam %s -s %s %d", &SAS::error::client() , $name, $pos);
    $c = "$c @ARGV";
    my $ret = qx/$c 2>&1/;
    my $x = $? >> 8;
    if($x){
	SAS::error::fatal("stringParameter", $ret);
      }
    chomp($ret);
    return $ret;
}

sub booleanParameter {
  &_treat_argv();
    my ($name, $pos) = @_;
    $pos = -1 unless defined $pos;
    my $c = sprintf("sasparam %s -b %s %d", &SAS::error::client() , $name, $pos);
    $c = "$c @ARGV";
    my $ret = qx/$c 2>&1/;
    my $x = $? >> 8;
    if($x){
	SAS::error::fatal("booleanParameter", $ret);
      }
    chomp($ret);
    return $ret;
}


1;

__END__


=head1 NAME

SAS::param - provide access to the SAS parameter interface

=head1 SYNOPSIS

    use SAS::param;

=head1 DESCRIPTION

C<SAS::param> provides access to the SAS parameter interface. In the
following it is assumed that the reader understans the SAS parameter library.

The following functions are available:

=over 4

=item $count = parameterCount($param_name)

This returns the number of items in a list parameter.

=item $value = intParameter($param_name[, $position]);

This returns the value of of an integer parameter. If it is a list
parameter, it returns the value at $position in the list.

=item $value = realParameter($param_name[, $position]);

The same as above, but for real parameters.

=item $value = stringParameter($param_name[, $position]);

The same as above, but for string parameters.

=item $value = booleanParameter($param_name[, $position]);

The same as above, but for boolean parameters.

=head1 SEE ALSO

The following perl modules: DAL, SAS, SAS::error.

The SAS documentation: B<sashelp --doc=param>

=head1 AUTHOR

 Giuseppe Vacanti

=cut
