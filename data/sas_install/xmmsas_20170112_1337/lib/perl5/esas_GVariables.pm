## @file
# Define Global Variables

package esas_GVariables;

##################################################
## the object constructor (simplistic version)  ##
##################################################
sub new {
    my $self  = {};    
    $self->{Cheese_prefixm}    = [];
    $self->{Cheese_prefixp}    = [];
    $self->{Cheese_verb}       = undef;
    $self->{Cheese_scale}      = undef;
    $self->{Cheese_rate}      = undef;
    $self->{Cheese_rates}      = undef;
    $self->{Cheese_rateh}      = undef;
    $self->{Cheese_dist}       = undef; 
    $self->{Cheese_mlmin}       = undef; 
    $self->{Cheese_clobber}    = undef;
    $self->{Cheese_elow}   = [];
    $self->{Cheese_ehigh}  = [];
     
    $self->{MOSSpectra_prefix}  	= undef;
    $self->{MOSSpectra_region}		= undef;
    $self->{MOSSpectra_mask} 		= undef;
    $self->{MOSSpectra_elow}		= undef;
    $self->{MOSSpectra_ehigh} 		= undef;
    $self->{MOSSpectra_CCD1} 		= undef;
    $self->{MOSSpectra_CCD2} 		= undef;
    $self->{MOSSpectra_CCD3} 		= undef;
    $self->{MOSSpectra_CCD4} 		= undef;
    $self->{MOSSpectra_CCD5} 		= undef;
    $self->{MOSSpectra_CCD6} 		= undef;
    $self->{MOSSpectra_CCD7} 		= undef;
    $self->{MOSSpectra_cflim} 		= undef;
   
    $self->{PNSpectra_prefix} 	 	= undef;
    $self->{PNSpectra_caldb} 	 	= undef;
    $self->{PNSpectra_region}		= undef;
    $self->{PNSpectra_mask} 		= undef;
    $self->{PNSpectra_elow}		= undef;
    $self->{PNSpectra_ehigh} 		= undef;
#    $self->{PNSpectra_pattern} 		= undef;
    $self->{PNSpectra_QUAD1} 		= undef;
    $self->{PNSpectra_QUAD2} 		= undef;
    $self->{PNSpectra_QUAD3} 		= undef;
    $self->{PNSpectra_QUAD4} 		= undef;
        
    $self->{ROTIM_prefix}		= undef;
    $self->{ROTIM_elow}			= undef;
    $self->{ROTIM_ehigh}		= undef;
    $self->{ROTIM_mode}			= undef; 
    $self->{ROTIM_mask}			= undef;
    $self->{ROTIM_clobber}		= undef;
     
    bless($self);          
    return $self;
}

sub printROTIM {
	 my $self = shift;
	 print "prefix = $self->{ROTIM_prefix}";
	 print "elow = $self->{ROTIM_elow}";
	 print "ehigh = $self->{ROTIM_ehigh}";
	 print "mode = $self->{ROTIM_mode}";
	 print "mask = $self->{ROTIM_mask}";
 	 print "clobber = $self->{ROTIM_clobber}\n";
}

sub printCheese {
    my $self = shift;
 
 	@tmp = $self->{Cheese_prefixm};
 	print "mosExp = $tmp\n";
 	@tmp = $self->{Cheese_prefixp};
 	print "pnExp = $tmp\n";
	print "verb = $self->{Cheese_verb}\n";
	print "scale = $self->{Cheese_scale}\n";
	print "rate = $self->{Cheese_rate}\n";
	print "rates = $self->{Cheese_rates}\n";
	print "rateh = $self->{Cheese_rateh}\n";
	print "dist = $self->{Cheese_dist}\n";
	print "mlmin = $self->{Cheese_mlmin}\n";
	print "clobber = $self->{Cheese_clobber}\n";
 	@tmp = $self->{Cheese_elow};
 	print "elow = $tmp\n";
 	@tmp = $self->{Cheese_ehigh};
 	print "ehigh = $tmp\n";
	
	print "---> esas variables <----\n";
}

sub printMOSSpectra {
	my $self = shift;
	
	print "MOS prefix = $self->{MOSSpectra_prefix}\n";
	print " = $self->{MOSSpectra_region}\n";
	print " = $self->{MOSSpectra_mask}\n";
	print " = $self->{MOSSpectra_elow}\n";
	print " = $self->{MOSSpectra_ehigh}\n";
	print " = $self->{MOSSpectra_CCD1}\n";
	print " = $self->{MOSSpectra_CCD2}\n";
	print " = $self->{MOSSpectra_CCD3}\n";
	print " = $self->{MOSSpectra_CCD4}\n";
	print " = $self->{MOSSpectra_CCD5}\n";
	print " = $self->{MOSSpectra_CCD6}\n";
	print " = $self->{MOSSpectra_CCD7}\n";
	print " = $self->{MOSSpectra_caldb}\n";
	print " = $self->{MOSSpectra_cflim}\n";
	
}

sub printPNSpectra {
	my $self = shift;
	
	print "PN prefix = $self->{PNSpectra_prefix}\n";
	print " = $self->{PNSpectra_caldb}\n";
	print " = $self->{PNSpectra_region}\n";
	print " = $self->{PNSpectra_mask}\n";
	print " = $self->{PNSpectra_elow}\n";
	print " = $self->{PNSpectra_ehigh}\n";
#	print " = $self->{PNSpectra_pattern}\n";
	print " = $self->{PNSpectra_CCD1}\n";
	print " = $self->{PNSpectra_CCD2}\n";
	print " = $self->{PNSpectra_CCD3}\n";
	print " = $self->{PNSpectra_CCD4}\n";
#	print " = $self->{PNSpectra_caldb}\n";
	
}

##############################################
## methods to access per-object data        ##
##                                          ##
## With args, they set the value.  Without  ##
## any, they only retrieve it/them.         ## 
##############################################

sub ROTIM_prefix {
    my $self = shift;
    if (@_) { $self->{ROTIM_prefix}  = shift }
    return $self->{ROTIM_prefix};
}

sub ROTIM_elow {
    my $self = shift;
    if (@_) { $self->{ROTIM_elow}  = shift }
    return $self->{ROTIM_elow};
}

sub ROTIM_ehigh {
    my $self = shift;
    if (@_) { $self->{ROTIM_ehigh}  = shift }
    return $self->{ROTIM_ehigh};
}

sub ROTIM_mode {
    my $self = shift;
    if (@_) { $self->{ROTIM_mode}  = shift }
    return $self->{ROTIM_mode};
}

sub ROTIM_mask {
    my $self = shift;
    if (@_) { $self->{ROTIM_mask}  = shift }
    return $self->{ROTIM_mask};
}
sub ROTIM_clobber {
    my $self = shift;
    if (@_) { $self->{ROTIM_clobber}  = shift }
    return $self->{ROTIM_clobber};
}


sub MOSSpectra_prefix {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_prefix}  = shift }
    return $self->{MOSSpectra_prefix};
}

sub MOSSpectra_region {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_region}  = shift }
    return $self->{MOSSpectra_region};
}

sub MOSSpectra_mask {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_mask}  = shift }
    return $self->{MOSSpectra_mask};
}

sub MOSSpectra_elow {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_elow}  = shift }
    return $self->{MOSSpectra_elow};
}

sub MOSSpectra_ehigh {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_ehigh}  = shift }
    return $self->{MOSSpectra_ehigh};
}
sub MOSSpectra_CCD1 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD1}  = shift }
    return $self->{MOSSpectra_CCD1};
}
sub MOSSpectra_CCD2 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD2}  = shift }
    return $self->{MOSSpectra_CCD2};
}
sub MOSSpectra_CCD3 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD3}  = shift }
    return $self->{MOSSpectra_CCD3};
}

sub MOSSpectra_CCD4 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD4}  = shift }
    return $self->{MOSSpectra_CCD4};
}

sub MOSSpectra_CCD5 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD5}  = shift }
    return $self->{MOSSpectra_CCD5};
}

sub MOSSpectra_CCD6 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD6}  = shift }
    return $self->{MOSSpectra_CCD6};
}

sub MOSSpectra_CCD7 {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_CCD7}  = shift }
    return $self->{MOSSpectra_CCD7};
}

sub MOSSpectra_caldb {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_caldb}  = shift }
    return $self->{MOSSpectra_caldb};
}

sub MOSSpectra_cflim {
    my $self = shift;
    if (@_) { $self->{MOSSpectra_cflim}  = shift }
    return $self->{MOSSpectra_cflim};
}

sub PNSpectra_prefix {
    my $self = shift;
    if (@_) { $self->{PNSpectra_prefix}  = shift }
    return $self->{PNSpectra_prefix};
}

sub PNSpectra_caldb {
    my $self = shift;
    if (@_) { $self->{PNSpectra_caldb}  = shift }
    return $self->{PNSpectra_caldb};
}

sub PNSpectra_region {
    my $self = shift;
    if (@_) { $self->{PNSpectra_region}  = shift }
    return $self->{PNSpectra_region};
}

sub PNSpectra_mask {
    my $self = shift;
    if (@_) { $self->{PNSpectra_mask}  = shift }
    return $self->{PNSpectra_mask};
}

sub PNSpectra_elow {
    my $self = shift;
    if (@_) { $self->{PNSpectra_elow}  = shift }
    return $self->{PNSpectra_elow};
}

sub PNSpectra_ehigh {
    my $self = shift;
    if (@_) { $self->{PNSpectra_ehigh}  = shift }
    return $self->{PNSpectra_ehigh};
}

sub PNSpectra_QUAD1 {
    my $self = shift;
    if (@_) { $self->{PNSpectra_QUAD1}  = shift }
    return $self->{PNSpectra_QUAD1};
}
sub PNSpectra_QUAD2 {
    my $self = shift;
    if (@_) { $self->{PNSpectra_QUAD2}  = shift }
    return $self->{PNSpectra_QUAD2};
}
sub PNSpectra_QUAD3 {
    my $self = shift;
    if (@_) { $self->{PNSpectra_QUAD3}  = shift }
    return $self->{PNSpectra_QUAD3};
}
sub PNSpectra_QUAD4 {
    my $self = shift;
    if (@_) { $self->{PNSpectra_QUAD4}  = shift }
    return $self->{PNSpectra_QUAD4};
}

sub Cheese_prefixm {
    my $self = shift;
    if (@_) { @{ $self->{Cheese_prefixm} } = @_ }
    return @{ $self->{Cheese_prefixm} };
}

sub Cheese_prefixp {
    my $self = shift;
    if (@_) { @{ $self->{Cheese_prefixp} } = @_ }
    return @{ $self->{Cheese_prefixp} };
}

sub Cheese_verb {
    my $self = shift;
    if (@_) { $self->{Cheese_verb}  = shift }
    return $self->{Cheese_verb};
}

sub Cheese_scale {
    my $self = shift;
    if (@_) { $self->{Cheese_scale}  = shift }
    return $self->{Cheese_scale};
}

sub Cheese_rate {
    my $self = shift;
    if (@_) { $self->{Cheese_rate}  = shift }
    return $self->{Cheese_rate};
}

sub Cheese_rates {
    my $self = shift;
    if (@_) { $self->{Cheese_rates}  = shift }
    return $self->{Cheese_rates};
}

sub Cheese_rateh {
    my $self = shift;
    if (@_) { $self->{Cheese_rateh}  = shift }
    return $self->{Cheese_rateh};
}

sub Cheese_dist {
    my $self = shift;
    if (@_) { $self->{Cheese_dist}  = shift }
    return $self->{Cheese_dist};
}

sub Cheese_mlmin {
    my $self = shift;
    if (@_) { $self->{Cheese_mlmin}  = shift }
    return $self->{Cheese_mlmin};
}

sub Cheese_clobber {
    my $self = shift;
    if (@_) { $self->{Cheese_clobber}  = shift }
    return $self->{Cheese_clobber};
}

sub Cheese_elow {
    my $self = shift;
    if (@_) { @{ $self->{Cheese_elow} } = @_ }
    return @{ $self->{Cheese_elow} };
}

sub Cheese_ehigh {
    my $self = shift;
    if (@_) { @{ $self->{Cheese_ehigh} } = @_ }
    return @{ $self->{Cheese_ehigh} };
}

1;
