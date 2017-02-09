package LineField;
require 5.004;
use Carp;
use strict;
use FileHandle;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $field = shift;
    my $self = {};
    $self->{TYPE} = undef;
    $self->{ELEMENTS} = undef;
    $self->{CONTENT} = $field;

    if(ref $field) {
	$self->{TYPE} = 'numeric';
	$self->{ELEMENTS} = $#$field;
    } else {
	$self->{TYPE} = 'string';
	$self->{ELEMENTS} = 1;
    }
    
    bless $self, $class;
    return $self;
}

sub isString {
    my $self = shift;
    return ($self->{TYPE} eq 'string');
}

sub elements {
    my $self = shift;
    return length $self->{CONTENT} if $self->isString;
    return scalar @{$self->{CONTENT}};
}

sub getField {
    my $self = shift;
    my $fn = shift;
    return (substr $self->{CONTENT}, $fn, 1) if $self->isString;
    croak "This field does not exist\n" if $self->elements < $fn;
    return $self->{CONTENT}->[$fn];
}

1;
