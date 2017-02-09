## @file
# Task Global Variables definition for intruments

package GVProduct;

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
	
}

sub setProduct {
	my ( $self, $productName ) = @_;
    $self->{_productName} = $productName if defined($productName);
    return $self->{_productName};
}

sub getProduct {
	my( $self ) =@_;
	return $self->{_productName};
}

sub setProcess {
	
	my ( $self, $process ) = @_;
    $self->{_process} = $process if defined($process);
    
    return $self->{_process};
}

sub getProcess {
	my( $self ) = @_;
	return $self->{_process};
}

sub getTasks {
	 my( $self ) = @_;
    return $self->{_tasks};
}
sub setTasks {
    my ( $self, $tasks ) = @_;
#   	$kk = $tasks->[0];
#   	$k = $kk->getParams();
#   	while (($key, $value) = each(%$k)){
#		print "Product Set Tasks!!!.. ".$key."=".$value."\n";
#	}
   	
    $self->{_tasks} = $tasks if defined($tasks);
    return $self->{_tasks};
}

sub getTask {
	
	my ($self,$task,$info) = @_;
	
  	$tasks = $self->getTasks();
   	for ($j=0;$j<=$#{$tasks};$j++)
   	{
	   	$t = @{$tasks}[$j];	    	   	
	   	if (($t->getTask() eq $task) && ($t->getInfo() eq $info)) {
	   		#printf ("%s %s\n",$t->getTask(), $task);
	   		return $t;
	   	}
   	}
}


sub print()
{
	my ($self) = @_;
	
	printf("Product: %s %s\n",$self->getProduct(),$self->getProcess());
}

1;
