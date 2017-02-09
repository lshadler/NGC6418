## @file
# Produce pile-up plots

## @method run_epatplot()
# run SAS task epatplot
# @return Flag of error/success.

#========================================================================

sub epatplot()
{
	use vars qw(
	  $epic_event_list
	  $epic_GTI_file
	  $epic_gti_cleanevents_file
	  $source_epic_region_file
	);
	my @files       = &get_EPIC_eventfiles();
		
	foreach my $file (@files) 
	{
		( $inst, $exposure, $mode ) = &get_File_Info($file);		
		$currentExposure = &getExpoInfo($inst,$exposure,$mode);
		
		$p = $currentExposure->getProduct("pileup");					
		my $source_obsID = $odf_object->getObsId;
			
		my $instrument = "";
		if ( $inst eq "EPN" ) {
			$instrument = "pn";
		}
		elsif ( $inst eq "EMOS1" ) {
			$instrument = "m1";
		}
		elsif ( $inst eq "EMOS2" ) {
			$instrument = "m2";
		}
		
		$logger->info( "\n----> Working out Source Spectrum: $file [$inst,$exposure,$mode] ..... ");
		if ( $odf_object->$inst eq "no" ) {
			$logger->info("INSTRUMENT $inst [exposure=$exposure]: Not selected for calculating spectra");
			$logger->info( "Skipping to the next exposure...");
		}
	  	#.. Check if the current exposure has been selected to be processed
	  	elsif ( (lc($currentExposure->getProcess()) eq "no") ||  
	  			(lc($p->getProcess()) eq "no") ) 
	  	{
	  		$logger->info(
			"EXPOSURE $exposure [intrument=$inst]: Not selected for producing spectrum");
			$logger->info( "Skipping to the next exposure...");
		}			
		else {
			
			$logger->info("   \#> Working out the centroid of source to analyze (Physical Units)...");
			$epic_obsmode = $obsid_instruments{$source_obsID}{$instrument}{'mode'};
			$epic_obssubmode =  $obsid_instruments{$source_obsID}{$instrument}{'submode'};

			
			$logger->info( "   \#> Defining File Names for Source Spectrum ..... ");
			create_pnProductFileNames( $instrument, $exposure, $mode );

			#.. Test for existance of GTI files
			&check_GTIs_Files( $instrument, $exposure, $mode, "spectral",$source_name );

			#.. Test for existance of PN and MOS event files
			&check_Spectra_Files( $inst, $exposure, $mode, "spectral",$source_name );
			
			#.. Create GTI filtered event lists.
			&produce_gticleanfile( $epic_event_list,
					$epic_gti_cleanevents_file, $epic_GTI_file, $epic_obsmode,
					$instrument,$currentExposure->getProduct("GTIFiltering"));


			#.. Check if the user has defined its own coordinates
			&setcoordinates();

			my $source_ra    = $odf_object->getRA;
			my $source_dec   = $odf_object->getDEC;

			#.. If run_edetect chain has been ran, use the closest source to the RA DEC given by the user for analysis
			my ( $ra_epic_closesource, $dec_epic_closesource,
				$epic_mindist_deg ) =
			&find_closest_source($source_epic_region_file);			
	
			if (   $epic_mindist_deg != 1000.
				&& $epic_mindist_deg <= $currentExposure->getProduct("edetectchain")->getTask("xmmextractor","image_creation")->getParam("sourcematch")->getValue() )
			{
				$logger->info(
				"   \#> WARNING: analysis: RA and DEC of source to analyze has been changed (according to $inst).");
				$ra_anal  = $ra_epic_closesource;
				$dec_anal = $dec_epic_closesource;
			}
			else {
				$ra_anal  = $source_ra;     # (deg) User Coordinates
				$dec_anal = $source_dec;    # (deg) User coordinates
			}
			$logger->info( "   \#> RA & DEC of source to analyse: ");
			$logger->info( "        RA : $ra_anal deg ");
			$logger->info( "        DEC: $dec_anal deg ");	

			#.. Coords OK
			
			#.. Make an image using the filtered event file to get source centroid
	
			if ( ( ($instrument eq "m1") || ($instrument eq "m2") ) &&  ($mode eq "TimingEvts" )  )
			{
				$logger->warn( "   \#> Cannot produce smooth image for exposure: $exposure [instrument: $instrument and mode: $mode] ");	
			} 
			else
			{
				&produce_smooth_image(
					$epic_gti_cleanevents_file, $epic_gti_image_file,
					$epic_gti_smoothimage_file, $instrument
				);
			}
										
			#.. Run eregionanalyse										
			my $epic_pileup_flag = prepare_spectra( $instrument, $exposure, $mode, $epic_obsmode,	$epic_obssubmode, "SPC",$currentExposure );
			
			if ($epic_pileup_flag) {
			&run_epatplot( $epic_gti_cleanevents_file, $instrument,
							"SPC", $epic_obsmode,$currentExposure );
			}
			
		} # End of pileup processing				
	}


	
	
	
}




sub run_epatplot()
{
	my $event_file = $_[0];
	my $instr      = $_[1];
	my $analysis   = $_[2];	
	my $subMode    = $_[3];
	my $currentExposure = $_[4];

	my $outfile = $instr."_epatplot.ps";
	
	my $region = $currentExposure->get_src_region;

	my $SRC_XC    = $currentExposure->get_src_X;
	my $SRC_YC    = $currentExposure->get_src_Y;
	if ($currentExposure->get_src_region eq "circle" || $currentExposure->get_src_region eq "annulus") 
	{
		$RSRC1     = $currentExposure->get_src_inner_roptimg;
		$RSRC2     = $currentExposure->get_src_roptimg;
	}
		
		
	if ($currentExposure->get_src_region eq "box") 
	{
		$RSRC1     = $currentExposure->get_src_XLength;
		$RSRC2     = $currentExposure->get_src_YLength;
	}

	$logger->info( "epatplot: SRC_XC: $SRC_XC");
	$logger->info( "epatplot: SRC_YC: $SRC_YC");
	$logger->info( "epatplot: RSRC1: $RSRC1");
	$logger->info( "epatplot: RSRC2: $RSRC2");
	$logger->info( "epatplot: region: $region");
	$logger->info( "epatplot: instr: $instr");
	$logger->info( "epatplot: event_file: $event_file");
	$logger->info( "epatplot: subMode: $subMode");
	my $filter_event_file = &produce_source_event_file($SRC_XC,$SRC_YC,$RSRC1,$RSRC2,$region,$instr,$event_file,$subMode);
	$logger->info( "epatplot: filter_event_file: $filter_event_file");
	$logger->info( "epatplot: outfile: $outfile");
	@args = ("epatplot set=$filter_event_file  device=\"\/VCPS\" outdir=$epatplot_directory plotfile=$outfile");
 		
    system(@args)== 0 or &error_code(8);		
	
	return(1);
}

## @method void produce_lightcurve_file($XC,$YC,$R1,$R2,$T,$region,$instr,$event_file,$outfile,$subMode)
# Produce a time series given region (circle, annulus or box) and energy range (E1, E2).
# @param E1 Low Bound Energy Range (eV)	   
# @param E2 High Bound Energy Range (eV)	   
# @param XC X-Center of Source Region (Image Pixels)	   
# @param YC Y-Center of Source Region (Image Pixels)	   
# @param R1 Radius/Length of Source Region (Image Pixels)
# @param R2 Radius/Length of Source Region (Image Pixels)
# @param T Time Bin (secs)	   
# @param region	Region Type (circle, annulus, box)   
# @param instr Instrument	   
# @param event_file Event File Name
# @param outfile Output File Name (Rate Set)	    
# @subMode Observation Mode 
# @return Void

#========================================================================
sub produce_source_event_file(){
    
# Produce an event file for a given region and energy range

    my $XC      = $_[0];
    my $YC      = $_[1];
    my $R1      = $_[2];
    my $R2      = $_[3];
    my $region  = $_[4];
    my $instr   = $_[5];
    my $event_file = $_[6];
    my $subMode = $_[7];
	my $xVal;
    my $yVal;
    my $areaexpr;
    my $outputname = $epatplot_directory.$instr."_epatplot.fits";
	
    if (($instr eq "m1" or $instr eq "m2") &&  (uc($subMode) eq 'TIMING') )
    {    	       		
    	#$areaexpr="((RAWX,TIME) in box($XC,$YC,$R1,$R2,0))";
    	my $X_min = $XC - $R1/2.;
    	my $X_max = $XC + $R1/2.; 
    	$areaexpr="(RAWX in [$X_min:$X_max])";
    } 
    else
    {
	    if ($region eq "circle" || $region eq "annulus") {$areaexpr="((X,Y) in annulus($XC,$YC,$R1,$R2))";}
   		if ($region eq "box") 
   		{
    		if ($subMode eq 'IMAGING' || $subMode eq 'imaging') {
    			$xVal = "X";
    			$yVal = "Y";
    		}
    		else 
    		{
    			$xVal = "RAWX";
    			$yVal = "RAWY";
    		}
    	
    		$areaexpr="(($xVal,$yVal) in box($XC,$YC,$R1,$R2,0))";
   		}
    }


    $logger->info( "areaexpr: $areaexpr");
    @args = ("evselect table=$event_file:EVENTS expression=\"$areaexpr\" keepfilteroutput=yes withfilteredset=yes filteredset=$outputname ");

    system(@args)== 0 or &error_code(7);
    	
    return($outputname);
}

1;


