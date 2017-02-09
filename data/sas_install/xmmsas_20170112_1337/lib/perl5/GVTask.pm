## @file
# Task Global Variables definition for intruments
use XML::LibXML;

package GVTask;

sub new {
	
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
	
}

sub setTask {
	my ( $self, $taskName ) = @_;
    $self->{_taskName} = $taskName if defined($taskName);
    return $self->{_taskName};
}

sub getTask {
	my( $self ) =@_;
	return $self->{_taskName};
}

sub setInfo {
	my ( $self, $taskInfo ) = @_;
    $self->{_taskInfo} = $taskInfo if defined($taskInfo);
    return $self->{_taskInfo};
}

sub getInfo {
	my( $self ) =@_;
	return $self->{_taskInfo};
}


sub setParam {
	
    my ( $self, $params ) = @_;    
    
    $self->{_params} = $params if defined($params);
    return $self->{_params};
}

sub getParams {
	my( $self ) = @_;
	return $self->{_params};
}


sub getParam {
	
	 my ( $self, $param ) = @_;
	 $params = $self->getParams();
	 return $params->{$param};
}



sub setParamValue()
{
	my ( $self, $param, $value ) = @_;
	$params = $self->getParams();		
	$params->{$param} = $value if defined($value); ; 
	
}


sub getParamValue()
{
	my ( $self, $value ) = @_;

	return $self->{$value} ; 
	
}

sub print()
{
	my ($self) = @_;
	
	printf ("Task: %s \(%s\)\n",$self->getTask(),$self->getInfo());
	$params = $self->getParams();
   	while (($key, $value) = each(%$params)){
	    printf ("PARAM: %s=%s\n",$key,$value);
	}
}

1;
