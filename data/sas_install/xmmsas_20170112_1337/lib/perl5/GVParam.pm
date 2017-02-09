## @file
# Param Global Variables definition for intruments

package GVParam;


sub new {
	my %params = ();
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
	
}

sub setParam {
	
	my ( $self, $paramName, $paramValue ) = @_;
	$params{$paramName} = $paramValue;
	#while (($key, $value) = each(%params)){
    # print "For.. ".$key."=".$value."\n";
	#}
    $self->{_params} = $params if defined($params);
    
    return $self->{_params};
}
	
sub getParam {
	my( $self ) = @_;
	return %params;
}

sub clean()
{
	%params = ();
}

sub print {
	my( $self ) = @_;
	
	#print Param Values
	printf("Param: %s \n", $self->_params);
}

1;
