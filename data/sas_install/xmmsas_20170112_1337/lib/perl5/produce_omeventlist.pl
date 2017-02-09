## @file
# Produce OM event lists

## @method produce_omeventlist()
# Starts and controls the production of OM Event List.
# @return Flag of error/success for OM.

use Switch;
#========================================================================
sub produce_omeventlist(){
#.. Run omichain
    $logger->info( "----> Start OM Analysis ....");

#.. Define Global Variables
    $logger->info( "   \#> Defining File Names for omichain ..... ");
 
    use vars qw($source_omregion_file
		$sourceomdet
		);
#.. Check if the user has defined its own coordinates
	&setcoordinates();	
	
    my $source_obsID = $odf_object->getObsId;
    my $source_name  = $odf_object->getSourceName;
    my $source_ra    = $odf_object->getRA;
    my $source_dec   = $odf_object->getDEC; 
    
   $sourceomdet = "YES";  # Initial condition
    
    $logger->info( "Done");

#.. Definition of file names
    $source_omregion_file   = $images_directory.$source_name."_omregion\.reg";    

#.. Test for ccf file and set ENV variable
    @test_ccf=&test_ccf();
    my $ccffile=$test_ccf[1];
    if (!$test_ccf[0]) {$logger->warn( "OM Processing: Run cifbuild first "); &error_code(3);}
    &set_ccf($ccffile);

#.. Test for odfingest file and set ENV variable     
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];
    if (!$test_odfingest[0]) {$logger->info( "OM processing: Run odfingest first"); &error_code(3);}
    &set_odfingest($odfingestfile);
    
#.. Print sas_setup    
    &print_sas_setup();

#.. Run omXchain depending on the input parameter
	chdir ($om_directory);
    $logger->info( "\n----> OM processing....");
	
	my $omStatus = 0;
	my @omScienceModes = &getOMScienceModes();	
	
	if ($omScienceModes[0])
	{
		&run_omichain ();
	}
	else
	{
		$logger->info("OM imaging mode not found");
		$omLog->info("OM imaging mode not found");
	}

	if ($omScienceModes[1])
	{
		&run_omfchain ();
	}
	else
	{
		$logger->info("OM fast mode not found");
		$omLog->info("OM fast mode not found");
	}

	if ($omScienceModes[2])
	{
		&run_omgchain ();
	}
	else
	{
		$logger->info("OM grism mode not found");
		$omLog->info("OM grism mode not found");
	}
	
  	    
    $logger->info( "\n----> Working out OM event lists. Finished");
    &error_code(0); 

    return($omStatus);
}

## @method test_omeventfiles()
# Test the existance of OM Imaging Event List
# @return File Name

#========================================================================
sub test_omeventfiles(){
    chdir ($om_directory);
    my @OM_Evtlist = glob('P*OM*SIMAGE*.FIT');
    if ($#OM_Evtlist >= 0){
	$logger->info( "   \#> OM Event List found [omichain]:"); 
	foreach (@OM_Evtlist) {$logger->info( "\t".$_ );}   

	if ($#OM_Evtlist > 0){
	    $logger->info( "      Using only  $OM_Evtlist[0] [omichain]");
	}
	my $om_event_list = $OM_Evtlist[0];
	return(1,$om_directory.$om_event_list);
    } else {
	$logger->info( "   \#> OM Event List not found for omichain processing ");
	return(0,"No File");
    }
}

## @method test_omfeventfiles()
# Test the existance of Optical Monitor Fast mode Event List
# @return File Name

#========================================================================
sub test_omfeventfiles(){
    chdir ($om_directory);
    my @OM_Evtlist = glob('*OM*EVLIST*.FIT');
    if ($#OM_Evtlist >= 0){
	$logger->info( "   \#> OM Event List found [omfchain]: "); 
	foreach (@OM_Evtlist) {$logger->info( "\t".$_ );}   

	if ($#OM_Evtlist > 0){
	    $logger->info( "      Using only $OM_Evtlist[0] [omfchain] ");
	}
	my $om_event_list = $OM_Evtlist[0];
	return(1,$om_directory.$om_event_list);
    } else {
	$logger->info( "   \#> OM Event List not found for omfchain processing ");
	return(0,"No File");
    }
}

## @method test_omgeventfiles()
# Test the existance of the automated processing and extraction of spectra from 
# Optical Monitor images obtained with the Optical and UV grisms Imaging Event List
# @return File Name

#========================================================================
sub test_omgeventfiles(){
    chdir ($om_directory);
    my @OM_Evtlist = glob('p*OM*RIMAGE*.FIT');
    if ($#OM_Evtlist >= 0){
	$logger->info( "   \#> OM Event List found [omgchain]: "); foreach (@OM_Evtlist) {$logger->info( "\t".$_ );}   

	if ($#OM_Evtlist > 0){
	    $logger->info( "      Using only $OM_Evtlist[0] [omgchain]");

	}
	my $om_event_list = $OM_Evtlist[0];
	return(1,$om_directory.$om_event_list);
    } else {
	$logger->info( "   \#> OM Event List not found for grism processing...");

	return(0,"No File");
    }
}

## @method test_omSRCfiles()
# Test the existance of OM Source List
# @return File Name

#========================================================================
sub test_omSRCfiles(){
    chdir ($om_directory);
    my @OM_SRClist = glob('P*OM*SRLI*.FIT');
    if ($#OM_SRClist >= 0){
	$logger->info( "   \#> OM Source List found: "); foreach (@OM_SRClist) {$logger->info( "\t".$_ );}   

	if ($#OM_SRClist > 0){
	    $logger->info( "      Using only $OM_SRClist[0] ");

	}
	my $om_src_list = $OM_SRClist[0];
	return(1,$om_directory.$om_src_list);
    } else {
	$logger->info( "   \#> OM Source List not found ");

	return(0,"No File");
    }
}

## @method test_test_omComboSRCfiles()
# Test the existance of OM Combine Observations Source List
# @return File Name

#========================================================================
sub test_omComboSRCfiles(){
    chdir ($om_directory);
    my @OM_ComboSRClist = glob('P*OMCOMBOBSMLI*.FIT');
    if ($#OM_ComboSRClist >= 0){
	$logger->info( "   \#> OM Source Combo List found: "); foreach (@OM_ComboSRClist) {$logger->info( "\t".$_ );}   

	if ($#OM_ComboSRClist > 0){
	    $logger->info( "      Using only $OM_ComboSRClist[0] ");
	}
	my $om_Combosrc_list = $OM_ComboSRClist[0];
	return(1,$om_directory.$om_Combosrc_list);
    } else {
	$logger->info( "   \#> OM Source Combo List not found ");

	return(0,"No File");
    }
}

## @method om_image($om_srclist_file,$om_fullimage)
# Produce an OM Image and region file from Source List. Produces an OM Image with regions from region file overlaid.
# @param om_srclist_file Name of OM Source List
# @param om_fullimage Name of input Image file to be plotted with regions overlaid
# @return RA (deg) and DEC (deg) of closest OM detected source to the source of interes. Angular distance (deg) between OM and source of interest.

#========================================================================
sub om_image(){
    chdir ($images_directory);

    my $om_srclist_file = $_[0];
    my $om_fullimage    = $_[1];
     
    my $omregion_file   = $images_directory."omregion\.txt"; 
	
    my $source_ra     = $odf_object->getRA;
    my $source_dec    = $odf_object->getDEC;
    my $source_name   = $odf_object->getSourceName;

#.. Run the SAS commands srcdisplay to produce region file
    @args=("srcdisplay"
	   ,"boxlistset=$om_srclist_file" 
	   ,"imageset=$om_fullimage"
	   ,"sourceradius=0.0011"
	   ,"withregionfile=yes"
	   ,"regionfile=$omregion_file"); 
    system(@args);                       

#.. From the list of detected sources in the region file find the closest source to yours
#.. and add your source to the region file to be plotted. 
    if (-e $omregion_file){
	@omclose_source=&find_closest_source($omregion_file);
	&addsourcetoregionfile($omregion_file,$omclose_source[0],$omclose_source[1],0.,0.0008,"red","","circle","fk5");
	&addsourcetoregionfile($omregion_file,$source_ra,$source_dec,0.,0.0010,"green",$source_name,"circle","fk5");	
    } else {
	$logger->info( "   \#> OM Region file $omregion_file does not exist ");
	
	return(100.,100.,100.);
    }

    rename($omregion_file,$source_omregion_file);
    $logger->info( "   \#> OM Region file produced: $source_omregion_file ");


#.. Run DS9. Arguments: image file, region file, title, output name
    &produce_ps_file($om_fullimage,$source_omregion_file,"OM",$images_directory.$source_name."_OM_image.ps");

    return($omclose_source[0],$omclose_source[1],$omclose_source[2]);
}

## @method void om_mosaic()
# Produce an OM Mosaic Image with region file ovelaid
# @return Void

#========================================================================
sub om_mosaic(){
    chdir ($om_directory);

    my $obsid         = $odf_object->getObsId;
    my $source_name   = $odf_object->getSourceName;

    my $om_mosaic_image= $om_directory."P".$obsid."OMMOSAIC.FIT";
   
    my @OM_event_file_list= glob('P*OMS*SIMAGE*.FIT');

    if ($#OM_event_file_list < 0) {$logger->info( "   \#> No Images found for Mosaic Image "); return(0);}
    $logger->info( "   \#> Mosaic Image $om_mosaic_image will be created ");
    $logger->info( "   \#> OM List for Mosaic Image: "); foreach (@OM_event_file_list) {$logger->info( "\t".$_ );}   

    @args=("ommosaic"
	   ,"imagesets=@OM_event_file_list" 
	   ,"mosaicedset=$om_mosaic_image"
	  ); 
    system(@args);   


#.. Run DS9. Arguments: image file, region file, title, output name
    &produce_ps_file($om_mosaic_image,$source_omregion_file,"OM",$images_directory.$source_name."_OM_Mosaic_image.ps");

    return(1);

}


sub run_omichain
{
	my $omevt_flag = 0;
 	$logger->info( "\n----> Running omichain ....");
	$omevt_flag    = 0;
	@$test_omevt   = &test_omeventfiles();
	$om_event_list = $test_omevt->[1];

	if ( $test_omevt->[0] )
	{    # If event file already exist ...
		$logger->info("   \#> OM Image Event List already exist: $om_event_list");
		$logger->info("   \#> Not running omichain");
		$omevt_flag = 1;
	}

	if ( !$omevt_flag )
	{    # If event files do not exist ...
		@$args = ("omichain");
		system(@$args) == 0
		  or return ($omevt_flag)
		  ; # Dont add error if it fails, OM analysis is secundary to the whole chain:  == 0 or &error_code(3);
		$omevt_flag    = 0;
		@$test_omevt   = &test_omeventfiles();
		$om_event_list = $test_omevt->[1];

		if ( $test_omevt->[0] )
		{    # Once omichain has run, do I have event files ?
			$logger->info(
"   \#> After running omichain: OM Image Event List found: $om_event_list" );
			$logger->info("   \#> omichain OK ");
			$omevt_flag = 1;
		}

		if ( !$omevt_flag )
		{
			$logger->info(
				"   \#> After running omichain: No OM Image Event List found ");
			$logger->info("   \#> omichain FAILED (no Events file found)");
		}
	}
	
	#.. Producing images 

    @om_closesource = (0.,0.,1000.);

    if ($omevt_flag){  
	$logger->info( "   \#> Producing OM MOSAIC Image and Image file ");
	@test_omsrc=&test_omComboSRCfiles();
	$om_src_list=$test_omsrc[1];
	if ($test_omsrc[0]) {
	    @om_closesource=&om_image($om_src_list,$om_event_list);	   
	    &om_mosaic;
	}

#.. OM Cross Correlation Information 
	if ($om_closesource[2] <= $odf_object->getOM_sourcematch()){$sourceomdet = "YES";}else{$sourceomdet = "NO";} #.. Has our the source been detected in OM ?  

#.. Output log information
    my $source_ra     = $odf_object->getRA;
    my $source_dec    = $odf_object->getDEC;
    

	$logger->info( "\n   \#> Cross Correlation Information for OM:");
	$logger->info( "       SOURCE           OM  ");
	$logger->info( "  RA       DEC     RA       DEC  ");
	$logger->info( " $source_ra $source_dec $om_closesource[0] $om_closesource[1] ");
	$logger->info( "  Distance to closest source: ");
	$logger->info( "  (If RA,DEC of the source is within ", join(", ", $odf_object->getOM_sourcematch())," deg of RA,DEC of detected ");
	$logger->info( "  camera source, it is assumed the source is the same) ");
	$logger->info( "    SOURCE-OM : $om_closesource[2] deg. Same source ?: $sourceomdet ");

	$omLog->info( "\n   \#> Cross Correlation Information for OM:");
	$omLog->info( "       SOURCE           OM  ");
	$omLog->info( "  RA       DEC     RA       DEC  ");
	$omLog->info( " $source_ra $source_dec $om_closesource[0] $om_closesource[1] ");
	$omLog->info( "  Distance to closest source: ");
	$omLog->info( "  (If RA,DEC of the source is within ", join(", ", $odf_object->getOM_sourcematch())," deg of RA,DEC of detected ");
	$omLog->info( "  camera source, it is assumed the source is the same) ");
	$omLog->info( "    SOURCE-OM : $om_closesource[2] deg. Same source ?: $sourceomdet ");

    }
    

}

sub run_omfchain
{

	$logger->info("\n----> Running omfchain ....");

	$omfevt_flag   = 0;
	@$test_omevt   = &test_omfeventfiles();
	$om_event_list = $test_omevt->[1];

	if ( $test_omevt->[0] )
	{    # If event file already exist ...
		$logger->info(
				   "   \#> OM Image Event List already exist: $om_event_list ");
		$logger->info("   \#> Not running omfchain");
		$omfevt_flag = 1;
	}

	if ( !$omfevt_flag )
	{    # If event files do not exist ...
		@$args = ("omfchain");
		system(@$args) == 0
		  or return ($omfevt_flag)
		  ; # Dont add error if it fails, OM analysis is secundary to the whole chain:  == 0 or &error_code(3);
		$omfevt_flag   = 0;
		@$test_omevt   = &test_omfeventfiles();
		$om_event_list = $test_omevt->[1];

		if ( $test_omevt->[0] )
		{    # Once omichain has run, do I have event files ?
			$logger->info(
"   \#> After running omfchain: OM Image Event List found: $om_event_list " );
			$logger->info("   \#> omichain OK ");

			$omfevt_flag = 1;
		}

		if ( !$omfevt_flag )
		{
			$logger->info(
				 "   \#> After running omfchain: No OM Image Event List found");
			$logger->info("   \#> omichain FAILED (no Events file found) ");
		}
	}
	return ();
}

sub run_omgchain
{
	my $omgevt_flag   = shift;
	my $logger        = shift;
	my $om_event_list = shift;
	my $args          = shift;
	my $test_omevt    = shift;

	$logger->info("\n----> Running omgchain ....");
	$omgevt_flag   = 0;
	@$test_omevt   = &test_omgeventfiles();
	$om_event_list = $test_omevt->[1];

	if ( $test_omevt->[0] )
	{    # If event file already exist ...
		$logger->info(
				   "   \#> OM Image Event List already exist: $om_event_list ");
		$logger->info("   \#> Not running omgchain");
		$omgevt_flag = 1;
	}

	if ( !$omgevt_flag )
	{    # If event files do not exist ...
		@$args = ("omgchain");
		system(@$args) == 0
		  or return ($omgevt_flag)
		  ; # Dont add error if it fails, OM analysis is secundary to the whole chain:  == 0 or &error_code(3);
		$omgevt_flag   = 0;
		@$test_omevt   = &test_omgeventfiles();
		$om_event_list = $test_omevt->[1];

		if ( $test_omevt->[0] )
		{    # Once omichain has run, do I have event files ?
			$logger->info(
"   \#> After running omgchain: OM Image Event List found: $om_event_list" );
			$logger->info("   \#> omichain OK");
			$omgevt_flag = 1;
		}

		if ( !$omgevt_flag )
		{
			$logger->info(
				 "   \#> After running omfchain: No OM Image Event List found");
			$logger->info("   \#> omgchain FAILED (no Events file found)");
		}
	}

	return ();
}

1;
