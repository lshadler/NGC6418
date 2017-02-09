## @file
# Produce EPIC point source lightcurve

## @method void produce_lightcurve()
# Produce EPIC lightcurve products
# @return Void

#========================================================================
sub produce_lightcurve() {

	use vars qw($src_scale
	  $bkg_scale
	  $epic_obsmode
	  $epic_event_list
	  $epic_GTI_file
	  $epic_bkglc_file
	  $epic_cleanevents_file
	  $epic_gti_image_file
	  $epic_gti_smoothimage_file
	  $epic_eregionanal_file
	  $epic_lcurve_region_file
	  $epic_lcurve_bkgregion_file
	  $epic_lcurve_combinedregion_file
	  $epic_emllist_file
	  $source_epic_region_file

	  $epic_sourcelc_e0_file
	  $epic_bkglc_e0_file
	  $epic_srcbkgsubtractlc_e0_file

	  $epic_lcurve_flag
	);
	

	#.. Test for ccf file and set ENV variable
	@test_ccf = &test_ccf();
	my $ccffile = $test_ccf[1];
	if ( !$test_ccf[0] ) {
		$logger->error( "      Run cifbuild first");
		&error_code(7);
	}
	&set_ccf($ccffile);

	#.. Test for odfingest file and set ENV variable
	@test_odfingest = &test_odfingest();
	my $odfingestfile = $test_odfingest[1];
	if ( !$test_odfingest[0] ) {
		&run_odfingest();
	}
	@test_odfingest = &test_odfingest();
	if ( !$test_odfingest[0] ) {
		$logger->info( "      Run odfingest first ");
		&error_code(7);
	}
	&set_odfingest($odfingestfile);

	#.. Print sas_setup
	&print_sas_setup();

	#.. Default Names
	my $source_obsID = $odf_object->getObsId;
	my $source_name  = $odf_object->getSourceName;

	#.. Get event files
	my @files = &get_EPIC_eventfiles();

	#	my %epicFileMap = get_EPIC_Exposures(@files);
	my $inst;
	my $exposure;
	my $mode;
	if ( $#files == 0 ) { &error_code(4); }

	foreach my $file (@files) {
		( $inst, $exposure, $mode ) = &get_File_Info($file);
		$currentExposure = &getExpoInfo($inst,$exposure,$mode);
		my $isExposureFlag = $currentExposure->getProcess();
		$p = $currentExposure->getProduct("lightcurve");	
		my $isExposureLCFlag = $p->getProcess();
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

		$logger->info( "\n----> Working out Light Curve: $file  [$inst,$exposure,$mode] .....");
		
		$epic_lcurve_flag = 0
		  ; # Flag that determines whether the light curve should be worked out (1: True)

		# Check if the user select EMOS1, EMOS2, PN for analysing data
		if (  $odf_object->$inst eq "no" ) {
			$logger->info(
"INSTRUMENT $inst [exposure=$exposure]: Not selected for calculating light curve");
			$logger->info( "Skipping to the next exposure...");
		}
	  	#.. Check if the current exposure has been selected to be processed
	  	elsif ( (lc($currentExposure->getProcess()) eq "no") ||  
	  			(lc($p->getProcess()) eq "no") )
	  	{
	  		$logger->info(
			"EXPOSURE $exposure [intrument=$inst]: Not selected for producing lightcurve");
			$logger->info( "Skipping to the next exposure...");
		}	
		else {
		    $epic_lcurve_flag = 1;		    		  
		    
			$scienceLog->info( "\n   \#> lightcurve science output  [$inst,$exposure,$mode]");
		    #.. Definition of file names
		    $logger->info( "   \#> Defining File Names for Light Curve..... ");
		    create_pnProductFileNames( $instrument, $exposure, $mode );
		    
		    $epic_cleanevents_file =
			$lcurve_directory
			. $instrument . "_"
			. $exposure . "_"
			. $mode
			. "_events_filtered\.fit";
			$epic_gti_image_file =
			    $gti_directory
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_img_gtifiltered\.img";
			$epic_gti_smoothimage_file =
			    $gti_directory
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_img_gtifiltered_smooth\.img";
			$epic_eregionanal_file =
			    $lcurve_directory
			  . $odf_object->getSourceName . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_eregionanalyse\.txt";
			$epic_emllist_file =
			    $images_directory
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_emllist\.fits";

			$source_epic_region_file =
			    $images_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_region\.reg";
			$epic_lcurve_region_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_region\.reg";
			$epic_lcurve_bkgregion_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_bkgregion\.reg";
			$epic_lcurve_combinedregion_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_combinedregion\.reg";

			$epic_sourcelc_e0_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_source.lc";
			$epic_bkglc_e0_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_bkg.lc";
			$epic_srcbkgsubtractlc_e0_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_sourcebkgsubtracted.lc";

			$epic_bkglc_file =
			    $lcurve_directory
			  . $source_name . "_"
			  . $instrument . "_"
			  . $exposure . "_"
			  . $mode
			  . "_bkg.lc";

			# Light curve parameters
			#.. Check if the user has defined its own coordinates
			&setcoordinates();


			my $source_ra    = $odf_object->getRA;
			my $source_dec   = $odf_object->getDEC;

			$logger->info( "Lightcurve inital checks. Done ");

			chdir($lcurve_directory);


			#.. RA & DEC Coordinates of position to analyze

#.. If run_edetect chain has been ran, use the closest source to the RA DEC given by the user for analysis
			my ( $ra_epic_closesource, $dec_epic_closesource,
				$epic_mindist_deg ) =
			  &find_closest_source($source_epic_region_file);

			if (   $epic_mindist_deg != 1000.
				&& $epic_mindist_deg <= $currentExposure->getProduct("edetectchain")->getTask("xmmextractor","image_creation")->getParam("sourcematch")->getValue() )
			{
				$logger->info(
"   \#> WARNING: analysis: RA and DEC of source to analyze has been changed (according to $instrument).");

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
      #.. Test for existance of GTI files
            &check_GTIs_Files( $instrument, $exposure, $mode, "lcurve",
                              $source_name );

	  #.. Test for existance of PN and MOS event files (both Imaging and Timing)
			&check_Spectra_Files( $inst, $exposure, $mode, "lcurve",
				$source_name );

#.. Get instrument's observing mode and prepare things according to shape of source and background regions.
			$epic_obsmode = $obsid_instruments{$source_obsID}{$instrument}{'mode'};
			$epic_obssubmode =
			  $obsid_instruments{$source_obsID}{$instrument}{'submode'};

			#.. Create filtered event lists.
			if ($epic_lcurve_flag) {
				&produce_cleanfile( $epic_event_list,
					$epic_cleanevents_file, $epic_obsmode,
					$instrument,$p );
			}    # EPIC

			#.. Get some information out of the GTI filtered event lists.
			$logger->info( "   \#> Sending Information from GTI Filtered Event Files to event and science log file: ");
			$logger->info( "   \#> Information from GTI Filtered Event Files (Lightcurve): ");
			$scienceLog->info( "   \#> Information from GTI Filtered Event Files (Lightcurve): ");
			if ($epic_lcurve_flag) {
				&event_file_inf( $epic_cleanevents_file, $instrument,$lcLog );
				&event_file_inf( $epic_gti_cleanevents_file, $instrument,$scienceLog );
			}    # EPIC


#.. Make an image using the filtered event file to get source centroid from eregionanalyse
			if ( ( ($instrument eq "m1") || ($instrument eq "m2") ) &&  ($mode eq "TimingEvts" )  )
			{
				$logger->info( "   \#> Cannot produce smooth image for exposure: $exposure [instrument: $instrument and mode: $mode]");	
			} 
			else
			{
				if ( ($epic_lcurve_flag) || (uc($p->getTask("xmmextractor","lc_interactivity")->getParam("interactivity")->getValue()) eq "YES") )    # && !-e $epic_gti_smoothimage_file)
				{
					&produce_smooth_image(
						$epic_gti_cleanevents_file, $epic_gti_image_file,
						$epic_gti_smoothimage_file, $instrument
					);
				}
			}                         # EPIC

#.. Using the instrument's image to work out the source centroid. Only for Imaging.

			$logger->info( "   \#> Centroid of source to analyze (Physical Units) ");

			#.. Run eregionanalyse
			if ( ($epic_lcurve_flag)  || (uc($p->getTask("xmmextractor","lc_interactivity")->getParam("interactivity")->getValue()) eq "YES") ){
				$epic_lcurve_flag =
				  &prepare_spectra( $instrument, $exposure, $mode,
					$epic_obsmode, $epic_obssubmode, "LC",$currentExposure );
			}

			#.. run epatplot
			if ( uc($currentExposure->getProduct("pileup")->getProcess()) eq "YES") {
				if ($epic_lcurve_flag) {
					&run_epatplot( $epic_gti_cleanevents_file, $instrument,
						"LC", $epic_obsmode,$currentExposure )
				}    # EPIC				
			}

			#.. Prepare light curve log file and output information										
			&prepare_region_log_file( $instrument, $exposure, $mode, $currentExposure,$lcLog,"LC" );
			&prepare_region_log_file( $instrument, $exposure, $mode, $currentExposure,$scienceLog,"LC" );


			chdir($lcurve_directory);
			
			#.. Make image plots and create region files used to extract the Light curves
			$logger->info("\n   \#> Producing plots and region files ..... ");
			
			if ( -e $epic_lcurve_region_file ) {
			    unlink("$epic_lcurve_region_file")
				or die "Cannot rm file $temp_file: $!";
			}
			
			if ( -e $epic_lcurve_bkgregion_file ) {
			    unlink("$epic_lcurve_bkgregion_file")
				or die "Cannot rm file $temp_file: $!";
			}
			
			if ( -e $epic_lcurve_combinedregion_file ) {
			    unlink("$epic_lcurve_combinedregion_file")
				or die "Cannot rm file $temp_file: $!";
			}
			
			if ( $currentExposure->get_src_region eq "circle" || $currentExposure->get_src_region eq "annulus" )
			{
				$x  = $currentExposure->get_src_X;
				$y  = $currentExposure->get_src_Y;
				$L1 = $currentExposure->get_src_inner_roptimg;
				$L2 = $currentExposure->get_src_roptimg;
			}
			if ( $currentExposure->get_src_region eq "box" ) {
				$x  = $currentExposure->get_src_X;
				$y  = $currentExposure->get_src_Y;
				$L1 = $currentExposure->get_src_XLength;
				$L2 = $currentExposure->get_src_YLength;
			}
			if ($epic_lcurve_flag) {
				&addsourcetoregionfile( $epic_lcurve_region_file, $x, $y, $L1,
					$L2, "yellow", "", $currentExposure->get_src_region, "physical" );
			}    # PN
			if ($epic_lcurve_flag) {
				&addsourcetoregionfile( $epic_lcurve_combinedregion_file,
					$x, $y, $L1, $L2, "yellow", "", $currentExposure->get_src_region,
					"physical" );
			}    # PN

			if ( $currentExposure->get_bkg_region eq "circle" || $currentExposure->get_bkg_region eq "annulus" )
			{
				$x  = $currentExposure->get_bkg_X;
				$y  = $currentExposure->get_bkg_Y;
				$L1 = $currentExposure->get_bkg_innerrimg;
				$L2 = $currentExposure->get_bkg_outerrimg;
			}
			if ( $currentExposure->get_bkg_region eq "box" ) {
				$x  = $currentExposure->get_bkg_X;
				$y  = $currentExposure->get_bkg_Y;
				$L1 = $currentExposure->get_bkg_XLength;
				$L2 = $currentExposure->get_bkg_YLength;
			}
			if ($epic_lcurve_flag) {
				&addsourcetoregionfile( $epic_lcurve_bkgregion_file, $x, $y,
					$L1, $L2, "red", "", $currentExposure->get_bkg_region, "physical" );
			}    # PN
			if ($epic_lcurve_flag) {
				&addsourcetoregionfile( $epic_lcurve_combinedregion_file,
					$x, $y, $L1, $L2, "red", "", $currentExposure->get_bkg_region, "physical" );
			}    # PN

			$logger->info(
			  "\n   \#> Producing Source and BKG Light Curve files ..... ");

			if ($epic_lcurve_flag) {
				$SRC_XC = $currentExposure->get_src_X;
				$SRC_YC = $currentExposure->get_src_Y;
				if (   $currentExposure->get_src_region eq "circle"
					|| $currentExposure->get_src_region eq "annulus" )
				{
					$RSRC1 = $currentExposure->get_src_inner_roptimg;
				}
				if (   $currentExposure->get_src_region eq "circle"
					|| $currentExposure->get_src_region eq "annulus" )
				{
					$RSRC2 = $currentExposure->get_src_roptimg;
				}
				if ( $currentExposure->get_src_region eq "box" ) {
					$RSRC1 = $currentExposure->get_src_XLength;
				}
				if ( $currentExposure->get_src_region eq "box" ) {
					$RSRC2 = $currentExposure->get_src_YLength;
				}
				$BKG_XC = $currentExposure->get_bkg_X;
				$BKG_YC = $currentExposure->get_bkg_Y;
				if (   $currentExposure->get_bkg_region eq "circle"
					|| $currentExposure->get_bkg_region eq "annulus" )
				{
					$RBKG1 = $currentExposure->get_bkg_innerrimg;
				}
				if (   $currentExposure->get_bkg_region eq "circle"
					|| $currentExposure->get_bkg_region eq "annulus" )
				{
					$RBKG2 = $currentExposure->get_bkg_outerrimg;
				}
				if ( $currentExposure->get_bkg_region eq "box" ) {
					$RBKG1 = $currentExposure->get_bkg_XLength;
				}
				if ( $currentExposure->get_bkg_region eq "box" ) {
					$RBKG2 = $currentExposure->get_bkg_YLength;
				}
								
				$region = $currentExposure->get_src_region;
				
				if (   -e $epic_sourcebkgspectrum_file && -e $epic_bkgspectrum_file )
				{
					( $src_livetime, $src_backscale, $src_areascal ) =
					  &event_file_spectralinf( $epic_sourcebkgspectrum_file,
						$instrument );
					( $bkg_livetime, $bkg_backscale, $bkg_areascal ) =
					  &event_file_spectralinf( $epic_bkgspectrum_file,
						$instrument );
					$src_scale = 1.;
					$bkg_scale = ( $src_backscale / $bkg_backscale );

					#.. fill XML structure properly
					$p->getTask("xmmextractor","details")->getParam("areafactor")->setValue($bkg_scale);			       
				}
				$src_scale = 1.;
				$bkg_scale = $p->getTask("xmmextractor","details")->getParam("areafactor")->getValue();
			
				#.. Check if we are in Timing and EMOS. In this case, the interactive 
				if (($mode eq "TimingEvts") && ( ($instrument eq "m1") || ($instrument eq "m2") ) )
				{
					$logger->info( "\n   \#> $instrument in $mode cannot be displayed.");
					$p->getTask("xmmextractor","lc_interactivity")->getParam("interactivity")->setValue("no");
				}
				
				
				if ( (length ($p->getTask("evselect","src_filtering")->getParam("expression")->getValue()) == 0) && 
						(length ($p->getTask("evselect","bkg_filtering")->getParam("expression")->getValue()) == 0) ) 
				{
				 	if (uc($p->getTask("xmmextractor","lc_interactivity")->getParam("interactivity")->getValue()) eq "YES")  
				 	{
				 		#.. Display ds9 and get src and bkg information
						$logger->info( "file to be displayed in ds9... $epic_cleanevents_file");
						&show_ds9($epic_cleanevents_file,$instrument,$exposure,$mode,"LC",$currentExposure);
						
						&produce_user_LC(
						$epic_cleanevents_file,
						$p->getTask("evselect","src_filtering")->getParam("expression")->getValue(),
						$p->getTask("evselect","bkg_filtering")->getParam("expression")->getValue(),						
						$instrument,
						$epic_sourcelc_e0_file,
						$epic_bkglc_e0_file,
						$epic_srcbkgsubtractlc_e0_file,
						$currentExposure
					);
				 	} else {
					
						&produce_LC(
							$epic_cleanevents_file,     $region,
							$SRC_XC,                        $SRC_YC,
							$RSRC1,                         $RSRC2,
							$BKG_XC,                        $BKG_YC,
							$RBKG1,                         $RBKG2,
							$instrument,
							$epic_sourcelc_e0_file,         $epic_bkglc_e0_file,
							$epic_srcbkgsubtractlc_e0_file, $epic_obsmode, $currentExposure
						);
				 	}
				}
				else {
					 if (uc($p->getTask("xmmextractor","lc_interactivity")->getParam("interactivity")->getValue()) eq "YES")
				  	 {
						#.. Display ds9 and get src and bkg information
						$logger->info( "file to be displayed in ds9... $epic_cleanevents_file");
						&show_ds9($epic_cleanevents_file,$instrument,$exposure,$mode,"LC",$currentExposure);
					 }

					&produce_user_LC(
						$epic_cleanevents_file,
						$p->getTask("evselect","src_filtering")->getParam("expression")->getValue(),
						$p->getTask("evselect","bkg_filtering")->getParam("expression")->getValue(),						
						$instrument,
						$epic_sourcelc_e0_file,
						$epic_bkglc_e0_file,
						$epic_srcbkgsubtractlc_e0_file,
						$currentExposure
					);
				}
			}

			#.. Write Summary

			$logger->info( " \#> Light Curve Analysis Summary :");

			$lcLog->info( " \#> Light Curve Analysis Summary :");

			if ( !$epic_lcurve_flag ) {
				$epic_summ_ana_msg = "FAILED";
			}
			else {
				$epic_summ_ana_msg = "OK";
			}

			$logger->info( "      $instrument : lightcurve analysis : $epic_summ_ana_msg ");

			$lcLog->info("      $instrument : lightcurve analysis : $epic_summ_ana_msg ");
			$scienceLog->info( "\n   \#> Lightcurve science output finished  [$inst,$exposure,$mode]");
		}				      

	    }    ### END OF EPIC LOOP
	&error_code(0);
	return;
}

## @method void produce_LC($events_file,$region,$X_Source,$Y_Source,$Source_inRad,$Source_outRad,$X_BKG,$Y_BKG,$BKG_inRad,$BKG_outRad,$T_Bin,$instr,$LC_SRC,$LC_BKG,$LC_corrected,$subMode)
# Creates LC.
# @param event_file Event File Name
# @param region Type of Region (circle, annulus, box)
# @param X_Source Source X_coordinate (Image Coordinates)
# @param Y_Source Source Y_coordinate (Image Coordinates)
# @param Source_inRad Source Region Inner Radius (circle,annulus), Source Region X_Box Size (box) (Image Coordinates)
# @param Source_outRad Source Outer Radius (circle,annulus), Source Region Y_Box Size (box) (Image Coordinates)
# @param X_BKG Background X_coordinate (Image Coordinates)
# @param Y_BKG Background Y_coordinate (Image Coordinates)
# @param BKG_inRad Background Region Inner Radius (circle,annulus), Background Region X_Box Size (box) (Image Coordinates)
# @param BKG_outRad Background Region Outer Radius (circle,annulus), Background Region Y_Box Size (box) (Image Coordinates)
# @param T_Bin Time Bin (secs)
# @param instr Instrument
# @param LC_SRC Source Light Curve Output File Name
# @param LC_BKG Background Light Curve Output File Name
# @param LC_corrected Light Curve corrected Output File Name
# @subMode Observation mode (IMAGING, TIMING)
# @return Void

#========================================================================
sub produce_LC() {

	# Creates a file from a time series created by evselect

	my $event_file    = $_[0];
	my $region        = $_[1];
	my $X_Source      = $_[2];
	my $Y_Source      = $_[3];
	my $Source_inRad  = $_[4];
	my $Source_outRad = $_[5];
	my $X_BKG         = $_[6];
	my $Y_BKG         = $_[7];
	my $BKG_inRad     = $_[8];
	my $BKG_outRad    = $_[9];
	my $instr         = $_[10];
	my $src_outfile   = $_[11];
	my $bkg_outfile   = $_[12];
	my $LC_corrected  = $_[13];
	my $subMode       = $_[14];
	my $currentExpo   = $_[15];


	my $source_name = $odf_object->getSourceName;
	my $mode        = $obsid_instruments{ $odf_object->getObsId }{$instr}{'mode'};
	my $submode     = $obsid_instruments{ $odf_object->getObsId }{$instr}{'submode'};
	my $exposureID = $currentExpo->getExpId();
	
	$scienceLog->info("Lightcurve source expression calculated by xmmextractor");

	&produce_lightcurve_file(
		$X_Source,    $Y_Source,
		$Source_inRad, $Source_outRad, $region,
		$instr,        $event_file,    $src_outfile, $subMode, "SRC",$currentExpo
	);
	
	$scienceLog->info("Lightcurve background expression calculated by xmmextractor");
	&produce_lightcurve_file(
		$X_BKG,       $Y_BKG,
		$BKG_inRad, $BKG_outRad, $region,
		$instr,     $event_file, $bkg_outfile, $subMode, "BKG",$currentExpo
	);
	
	#.. epiclccorr:
	@args = (
		"epiclccorr",            "srctslist=$src_outfile",
		"eventlist=$event_file", "outset=$LC_corrected",
		"withbkgset=yes",        "bkgtslist=$bkg_outfile",
		"applyabsolutecorrections=yes"
	);

	system(@args) == 0 or &error_code(7);

	return (1);
}

## @method void produce_user_LC($events_file,$src_expr,$bkg_expr,$instr,$LC_SRC,$LC_BKG,$LC_corrected,$expo)
# Creates LC.
# @param event_file Event File Name
# @param source expression
# @param background expression
# @param T_Bin Time Bin (secs)
# @param instr Instrument
# @param LC_SRC Source Light Curve Output File Name
# @param LC_BKG Background Light Curve Output File Name
# @param LC_corrected Light Curve corrected Output File Name
# @return Void

#========================================================================
sub produce_user_LC() {

	# Creates a file from a time series created by evselect

	my $event_file   = $_[0];
	my $src_expr     = $_[1];
	my $bkg_expr     = $_[2];	
	my $instr        = $_[3];
	my $src_outfile  = $_[4];
	my $bkg_outfile  = $_[5];
	my $LC_corrected = $_[6];		
	my $currentExpo  = $_[7];

	my $source_name = $odf_object->getSourceName;
	my $mode        = $obsid_instruments{ $odf_object->getObsId }{$instr}{'mode'};
	my $submode     = $obsid_instruments{ $odf_object->getObsId }{$instr}{'submode'};
	my $exposureID = $currentExpo->getExpId();

	$scienceLog->info("Lightcurve source expression: user's defined");
	&produce_user_lightcurve_file( $src_expr, $instr,
		$event_file, $src_outfile,"SRC",$currentExpo );
	$scienceLog->info("Lightcurve background expression: user's defined");
	&produce_user_lightcurve_file( $bkg_expr, $instr,
		$event_file, $bkg_outfile,"BKG",$currentExpo );

	#.. epiclccorr:
	@args = (
		"epiclccorr",            "srctslist=$src_outfile",
		"eventlist=$event_file", "outset=$LC_corrected",
		"withbkgset=yes",        "bkgtslist=$bkg_outfile",
		"applyabsolutecorrections=yes"
	);

	system(@args) == 0 or &error_code(7);

	return (1);
}

## @method void produce_lightcurve_file($XC,$YC,$R1,$R2,$T,$region,$instr,$event_file,$outfile,$subMode)
# Produce a time series given region (circle, annulus or box) and energy range (E1, E2).
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
sub produce_lightcurve_file() {

	# Produce an event file for a given region and energy range

	my $XC         = $_[0];
	my $YC         = $_[1];
	my $R1         = $_[2];
	my $R2         = $_[3];
	my $region     = $_[4];
	my $instr      = $_[5];
	my $event_file = $_[6];
	my $outfile    = $_[7];
	my $subMode    = $_[8];
	my $type       = $_[9];
	my $currentExpo = $_[10];
	my $xVal;
	my $yVal;

	my $T = 0;
	
	
	$logger->info( "       $instr : $region ");
	$logger->info( "       Event File: $event_file");
	$logger->info( "       Output File: $outfile) ");
	
	$lcLog->info("       $instr :  $region ");
	$lcLog->info("       Event File: $event_file");
	$lcLog->info("       Output File: $outfile ");

	$scienceLog->info("       $instr : $region ");
	$scienceLog->info("       Event File: $event_file");
	$scienceLog->info("       Output File: $outfile ");

	my $exposureID = $currentExpo->getExpId();
	
	
	if (   ( $instr eq "m1" or $instr eq "m2" )
		&& ( uc($subMode) eq 'TIMING' ) )
	{

		#$areaexpr="((RAWX,TIME) in box($XC,$YC,$R1,$R2,0))";
		my $X_min = $XC - $R1 / 2.;
		my $X_max = $XC + $R1 / 2.;
		$areaexpr = "(RAWX in [$X_min:$X_max])";
	}
	else {
		if ( $region eq "circle" || $region eq "annulus" ) {
			$areaexpr = "((X,Y) in annulus($XC,$YC,$R1,$R2))";
		}
		if ( $region eq "box" ) {
			if ( $subMode eq 'IMAGING' || $subMode eq 'imaging' ) {
				$xVal = "X";
				$yVal = "Y";
			}
			else {
				$xVal = "RAWX";
				$yVal = "RAWY";
			}

			$areaexpr = "(($xVal,$yVal) in box($XC,$YC,$R1,$R2,0))";
		}
	}
	
	if ($type eq "SRC") {
		$src_expr = "\"$areaexpr\"";		
		$currentExpo->getProduct("lightcurve")->getTask("evselect","src_filtering")->getParam("expression")->setValue($src_expr);
		$T = $currentExpo->getProduct("lightcurve")->getTask("evselect","src_filtering")->getParam("timebinsize")->getValue();
		$scienceLog->info("Instrument: $instr Exposure: $exposureID : Time serie filter expression for source: $src_expr");
	} else
	{
		$bkg_expr = "\"$areaexpr\"";
		$currentExpo->getProduct("lightcurve")->getTask("evselect","bkg_filtering")->getParam("expression")->setValue($bkg_expr);
		$T = $currentExpo->getProduct("lightcurve")->getTask("evselect","bkg_filtering")->getParam("timebinsize")->getValue();
		$scienceLog->info("Instrument: $instr Exposure: $exposureID : Time serie filter expression for background: $bkg_expr");
	}
	
	
	@args = (
"evselect table=$event_file:EVENTS expression=\"$areaexpr\" rateset=$outfile timebinsize=$T withrateset=yes maketimecolumn=yes makeratecolumn=yes"
	);

	system(@args) == 0 or &error_code(7);
	return (1);
}

## @method void produce_user_lightcurve_file($XC,$YC,$R1,$R2,$T,$region,$instr,$event_file,$outfile,$subMode)
# Produce a time series given region (circle, annulus or box) and energy range (E1, E2).
# @param expression
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
sub produce_user_lightcurve_file() {

	# Produce an event file for a given region and energy range

	my $expression = $_[0];
	my $instr      = $_[1];
	my $event_file = $_[2];
	my $outfile    = $_[3];
	my $type       = $_[4];
	my $currentExpo = $_[5];
	
	my $T = 0;


	if ($type eq "SRC") {
		$T = $currentExpo->getProduct("lightcurve")->getTask("evselect","src_filtering")->getParam("timebinsize")->getValue();
		
	} else
	{
		$T = $currentExpo->getProduct("lightcurve")->getTask("evselect","bkg_filtering")->getParam("timebinsize")->getValue();
	}


	$logger->info( "       $instr : Filter expression: ".$expression);
	$logger->info( "       $instr : Time Bining : $T sec");
	$logger->info( "       Event File: $event_file");
	$logger->info( "       Output File: $outfile ");

	$lcLog->info("       $instr :  Filter expression: ".$expression);
	$lcLog->info("       Event File: $event_file");
	$lcLog->info("       Output File: $outfile");

	$scienceLog->info("       $instr :  Filter expression: ".$expression);
	$scienceLog->info("       $instr :  Time Bining : $T sec");
	$scienceLog->info("       Event File: $event_file");
	$scienceLog->info("       Output File: $outfile)");


	my $exposureID = $currentExpo->getExpId();
	
	$scienceLog->info("Instrument: $instr Exposure: $exposureID Lightcurve Filter expression for $type: $expression");

	@args = (
"evselect table=$event_file:EVENTS expression=$expression rateset=$outfile timebinsize=$T withrateset=yes maketimecolumn=yes makeratecolumn=yes"
	);

	system(@args) == 0 or &error_code(7);
	return (1);
}


## @method void produce_cleanfile($even_file,$even_cleanfile,$subMode,$instr)
# Given a default expression and event file, produce a clean event file.
# @param even_file Event File Name
# @param subMode instrument mode
# @param instr Instrument
# @param product info
# @return Void

#========================================================================
sub produce_cleanfile(){

    my $even_file    = $_[0];
    my $even_cleanfile = $_[1]; 
    my $subMode      = $_[2];
    my $instr        = $_[3];
    my $prodInfo = $_[4];
    

    $logger->info( "   \#> Producing clean event file from $even_file .... ");
  	
   
    #.. Reading input parameters... and passing them to the SAS task call
    my $myParams = $prodInfo->getTask("evselect","clean_evtfile")->getParams();    

	my $params = " ";
	for my $key ( keys %$myParams ) {
		if ($key eq "expression")
		{
			my $expr =  $myParams->{$key}->getValue();		
			$params = $params." $key=\"".$expr."\""; 
		}
		else
		{
			$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
		}   
	}

	if (exists $myParams->{"table"} ){
       		$lcurveLog->info("Lightcurve filtering: Using users' intput event file: [ $myParams->{\"table\"}->getValue()] ");       		
   	}
   	else {
     		$params = $params." table=\"$even_file:EVENTS\" ";
   	}      
	if ( exists $myParams->{"filteredset"}) {
       		$lcurveLog->info("Lightcurve filtering: Using users' output event file: [ $myParams->{\"filteredset\"}->getValue()] ");
   	}
   	else {
     		$params = $params." filteredset=$even_cleanfile ";
   	}        						    
	#..  Done
    @args = ("evselect $params");
    system(@args) == 0 or &error_code(6);

    $logger->info( "Done");

    return(1);
}

1;
