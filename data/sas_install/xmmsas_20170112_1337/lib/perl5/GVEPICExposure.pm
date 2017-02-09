## @file
# Exposure Global Variables definition for EPIC intruments

package GVEPICExposure;

sub new {
    my $class = shift;
	my $self = {};	
	bless $self, $class;     
    return $self;
}
 
sub getInstName {
	 my( $self ) = @_;
    return $self->{_instName};
}
sub setInstName {
    my ( $self, $instName ) = @_;
    $self->{_instName} = $instName if defined($instName);
    return $self->{_instName};
}

sub getMode {
	 my( $self ) = @_;
    return $self->{_mode};
}
sub setMode {
    my ( $self, $mode ) = @_;
    my $pseMode;
   
    if ( ($self->getInstName eq "EMOS1") || ($self->getInstName eq "EMOS2") ) {
        if ( ($mode eq "PrimeFullWindow") ||($mode eq "PrimePartialRFS") || 
    	($mode eq "PrimePartialW2") ||($mode eq "PrimePartialW3") ||
    	($mode eq "PrimePartialW4") ||($mode eq "PrimePartialW5") ||
    	($mode eq "PrimePartialW6") ||($mode eq "PrimeFullWin3x3") )
    	{
    		$pseMode = "ImagingEvts";
    	} elsif (($mode eq "FastUncompressed") || ($mode eq "FastCompressed") ) {
    		$pseMode = "TimingEvts";
    	}
    } elsif ($self->getInstName eq "EPN") {
    	if (($mode eq "PrimeFullWindowExtended") ||($mode eq "PrimeLargeWindow") ||
    		($mode eq "PrimeSmallWindow") || ($mode eq "PrimeFullWindow") ) {
    			$pseMode = "ImagingEvts";    			
    		} elsif (($mode eq "FastTiming") || ($mode eq "FastBurst") ) {
    			$pseMode = "TimingEvts";
    		}
    } else {
    	$pseMode = $mode;
    } 
  
    $self->{_mode} = $pseMode if defined($pseMode);
    return $self->{_mode};
}

sub getExpId {
	 my( $self ) = @_;
    return $self->{_expId};
}
sub setExpId {
    my ( $self, $expId ) = @_;
    $self->{_expId} = $expId if defined($expId);
    return $self->{_expId};
}

sub getDuration {
	 my( $self ) = @_;
    return $self->{_duration};
}
sub setDuration {
    my ( $self, $duration ) = @_;
    $self->{_duration} = $duration if defined($duration);
    return $self->{_duration};
}
sub getProcess {
	 my( $self ) = @_;
    return $self->{_process};
}
sub setProcess {
    my ( $self, $process ) = @_;
    $self->{_process} = $process if defined($process);
    return $self->{_process};
}

sub getProducts {
	 my( $self ) = @_;
    return $self->{_products};
}
sub setProducts {
    my ( $self, $products ) = @_;
    $self->{_products} = $products if defined($products);
    return $self->{_products};
#    $prod = $products->[0];
#	$ll = $prod->getProduct();
#	print "PROD NAME $ll\n";
#	$ll = $prod->getTasks();
#	for ($jj=0;$jj<=$#{$ll};$jj++)
#   	{
#	 	$pp = @{$ll}[$jj];
#   		$p = $pp->getTask();
#   		print "Task: $p\n";  		      		
#   		$k = $pp->getParams();   		
#   		while (($key, $value) = each(%$k)){
#			print "Params:.. ".$key."=".$value."\n";
#		}   		
#	}

}

# Retrieve a particular product
sub getProduct()
{
	
	my ($self,$prod) = @_;
	
  	$products = $self->getProducts();
   	for ($j=0;$j<=$#{$products};$j++)
   	{
	   	$p = @{$products}[$j];	    	   	
	   	if ($p->getProduct() eq $prod) {
	   		return $p;
	   	}
   	}
   
}

# Values from ereginoanalyse call

sub initEregionAnalyseVars()
{
	my( $self) = @_;
	$self->{_src_region} = "none";
	$self->{_bkg_region} = "none";
	$self->{_X} = 0;
	$self->{_Y} = 0;
	$self->{_roptsky} = 0;
	$self->{_inner_roptimg} = 0;
	$self->{_roptimg} = 0;
	$self->{_src_XLength} = 0;
	$self->{_src_YLength} = 0;
	$self->{_XB} = 0;
	$self->{_YB} = 0;
	$self->{_bkg_innerrsky} = 0;
	$self->{_bkg_innerrimg} = 0;
	$self->{_bkg_outerrsky} = 0;
	$self->{_bkg_outerrimg} = 0;
	$self->{_bkg_XLength} = 0;
	$self->{_bkg_YLength} = 0;
}

sub set_src_region()
{
	 my( $self,$src_region) = @_;
	 $self->{_src_region} = $src_region if defined($src_region);	
}

sub get_src_region()
{
	 my( $self) = @_;
	 return $self->{_src_region};	
}

sub set_bkg_region()
{
	 my( $self,$bkg_region) = @_;
	 $self->{_bkg_region} = $bkg_region if defined($bkg_region);	
}

sub get_bkg_region()
{
	 my( $self) = @_;
	 return $self->{_bkg_region};	
}
sub set_src_X()
{
	 my( $self,$x) = @_;
	 $self->{_X} = $x if defined($x);	
}

sub get_src_X()
{
	 my( $self) = @_;
	 return $self->{_X};	
}

sub set_src_Y()
{
	 my( $self,$y) = @_;
	 $self->{_Y} = $y if defined($y);	
}

sub get_src_Y()
{
	 my( $self) = @_;
	 return $self->{_Y};	
}


sub set_src_roptsky()
{
	 my( $self,$roptsky) = @_;
	 $self->{_roptsky} = $roptsky if defined($roptsky);	
}

sub get_src_roptsky()
{
	 my( $self) = @_;
	 return $self->{_roptsky};	
}

sub set_src_inner_roptimg()
{
	 my( $self,$inner_roptimg) = @_;
	 $self->{_inner_roptimg} = $inner_roptimg if defined($inner_roptimg);	
}

sub get_src_inner_roptimg()
{
	 my( $self) = @_;
	 return $self->{_inner_roptimg};	
}

sub set_src_roptimg()
{
	 my( $self,$roptimg) = @_;
	 $self->{_roptimg} = $roptimg if defined($roptimg);	
}

sub get_src_roptimg()
{
	 my( $self) = @_;
	 return $self->{_roptimg};	
}


sub set_src_XLength()
{
	 my( $self,$src_XLength) = @_;
	 $self->{_src_XLength} = $src_XLength if defined($src_XLength);	
}

sub get_src_XLength()
{
	 my( $self) = @_;
	 return $self->{_src_XLength};	
}

sub set_src_YLength()
{
	 my( $self,$src_YLength) = @_;
	 $self->{_src_YLength} = $src_YLength if defined($src_YLength);	
}

sub get_src_YLength()
{
	 my( $self) = @_;
	 return $self->{_src_YLength};	
}


sub set_bkg_X()
{
	 my( $self,$xb) = @_;
	 $self->{_XB} = $xb if defined($xb);	
}

sub get_bkg_X()
{
	 my( $self) = @_;
	 
	 return $self->{_XB};	
}

sub set_bkg_Y()
{
	 my( $self,$yb) = @_;
	 $self->{_YB} = $yb if defined($yb);	
}

sub get_bkg_Y()
{
	 my( $self) = @_;
	 return $self->{_YB};	
}

sub set_bkg_innerrsky()
{
	 my( $self,$bkg_innerrsky) = @_;
	 $self->{_bkg_innerrsky} = $bkg_innerrsky if defined($bkg_innerrsky);	
}

sub get_bkg_innerrsky()
{
	 my( $self) = @_;
	 return $self->{_bkg_innerrsky};	
}

sub set_bkg_innerrimg()
{
	 my( $self,$bkg_innerrimg) = @_;
	 $self->{_bkg_innerrimg} = $bkg_innerrimg if defined($bkg_innerrimg);	
}

sub get_bkg_innerrimg()
{
	 my( $self) = @_;
	 return $self->{_bkg_innerrimg};	
}

sub set_bkg_outerrsky()
{
	 my( $self,$bkg_outerrsky) = @_;
	 $self->{_bkg_outerrsky} = $bkg_outerrsky if defined($bkg_outerrsky);	
}

sub get_bkg_outerrsky()
{
	 my( $self) = @_;
	 return $self->{_bkg_outerrsky};	
}

sub set_bkg_outerrimg()
{
	 my( $self,$bkg_outerrimg) = @_;
	 $self->{_bkg_outerrimg} = $bkg_outerrimg if defined($bkg_outerrimg);	
}

sub get_bkg_outerrimg()
{
	 my( $self) = @_;
	 return $self->{_bkg_outerrimg};	
}

sub set_bkg_XLength()
{
	 my( $self,$bkg_XLength) = @_;
	 $self->{_bkg_XLength} = $bkg_XLength if defined($bkg_XLength);	
}

sub get_bkg_XLength()
{
	 my( $self) = @_;
	 return $self->{_bkg_XLength};	
}

sub set_bkg_YLength()
{
	 my( $self,$bkg_YLength) = @_;
	 $self->{_bkg_YLength} = $bkg_YLength if defined($bkg_YLength);	
}

sub get_bkg_YLength()
{
	 my( $self) = @_;
	 return $self->{_bkg_YLength};	
}

sub print {
    my ($self) = @_;

    #print Exposure Info
    printf( "Exposure: %s %s %s %s %s\n", $self->getInstName(), $self->getMode,
    	$self->getExpId, $self->getDuration, $self->getProcess );
       	$products = $self->getProducts();
   
   		for ($j=0;$j<=$#{$products};$j++)
   		{
	   		$product = @{$products}[$j];
	   		$product->print();
	   		$tasks = $product->getTasks();
   			for ($jj=0;$jj<=$#{$tasks};$jj++)
   			{
	   			$task = @{$tasks}[$jj];
	   			$task->print();	   			
  			}	   
  		}
}


1;
