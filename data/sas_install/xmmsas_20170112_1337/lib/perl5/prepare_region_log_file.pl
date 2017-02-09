
sub prepare_region_log_file()
{
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $mode = $_[2];
	my $currentExposure = $_[3];
	my $currentLog = $_[4];
	my $currentProduct = $_[5];
	my $product = "spectra";

	if ($currentProduct eq "LC")
	{
		$product = "lightcurve";	
	}
	
	$currentLog->info( "   \#> $product processing...");
	$currentLog->info( "   \#> Centroid of source to analyze (Physical Units)");
	$currentLog->info( "   \#> INSTRUMENT: $instrument EXPOSURE: $exposure");
	$currentLog->info( "         SRC Region : ",$currentExposure->get_src_region);
	$currentLog->info( "         SRC XC     : ", $currentExposure->get_src_X);
	$currentLog->info( "         SRC YC     : ", $currentExposure->get_src_Y);
	if ( $currentExposure->get_src_region eq "circle" ||  $currentExposure->get_src_region eq "annulus")
	{$currentLog->info( "         SRC RADII  : ", $currentExposure->get_src_inner_roptimg," - ", $currentExposure->get_src_roptimg);}
	if ( $currentExposure->get_src_region eq "box") 
	{$currentLog->info( "         SRC BOX    : ", $currentExposure->get_src_XLength," - ", $currentExposure->get_src_YLength);}
	$currentLog->info( "         BKG Region : ", $currentExposure->get_bkg_region);
	$currentLog->info( "         BKG XC     : ", $currentExposure->get_bkg_X);
	$currentLog->info( "         BKG YC     : ", $currentExposure->get_bkg_Y);
	if ( $currentExposure->get_bkg_region eq "circle" ||  $currentExposure->get_bkg_region eq "annulus") 
	{
	    $currentLog->info( "         BKG RADII  : ", $currentExposure->get_bkg_innerrimg," - ", $currentExposure->get_bkg_outerrimg);
	    if ($currentExposure->get_src_roptimg > $currentExposure->get_bkg_innerrimg)
	    {$currentLog->info( "         WARNING: $instrument regions : The inner background region radii is smaller than the source region radii");} 	    
	}
	if ($currentExposure->get_bkg_region eq "box") 
	{$currentLog->info( "         BKG BOX    : ",$currentExposure->get_bkg_XLength," - ",$currentExposure->get_bkg_YLength);}
	$currentLog->info( "         BKG AREA SCALE FACTOR : ",$currentExposure->getProduct($product)->getTask("xmmextractor","details")->getParam("areafactor")->getValue()," (Only area taken into account)");
	if ($currentExposure->get_src_roptimg == 6000){$currentLog->warn(  "         WARNING : PN regions : Maximum allowed radius reached");}

    
}
    
1;
