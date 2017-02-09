## @file
# Produce EPIC point source spectrum

## @method void produce_spectrum()
# Produce EPIC spectrum products
# @return Void

#========================================================================
sub produce_spectrum() {

	use vars qw(
	  $results_directory
	  $epic_event_list
	  $epic_GTI_file

	  $epic_gti_cleanevents_file
	  $epic_gti_image_file
	  $epic_gti_smoothimage_file

	  $epic_eregionanal_file
	  $epic_ecoordconv_file

	  $epic_spectral_flag
	  $epic_spectral_image_psfile
	  $epic_spectral_pileupimage_psfile
	  $epic_spectral_region_file
	  $epic_spectral_bkgregion_file
	  $epic_spectral_combinedregion_file
	  $epic_ancillary_file
	  $epic_redistribution_matrix_file
	  $epic_sourcebkgspectrum_file
	  $epic_bkgspectrum_file
	  $epic_spectrum_psfile
	  $epic_emllist_file
	  $source_epic_region_file

	  $epic_src_livetime
	  $epic_src_backscale
	  $epic_src_areascal

	  $epic_bkg_livetime
	  $epic_bkg_backscale
	  $epic_bkg_areascal

	  %model_name
	);

	#.. Test for ccf file and set ENV variable
	@test_ccf = &test_ccf();
	my $ccffile = $test_ccf[1];
	if ( !$test_ccf[0] ) {
		$logger->warn( "Producing spectrum: Run cifbuild first");
		&error_code(6);
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
		$logger->warn( "Producing spectrum: Run odfingest first");
		&error_code(6);
	}
	&set_odfingest($odfingestfile);

	#.. Print sas_setup
	&print_sas_setup();

	#.. Get event files
	my @files       = &get_EPIC_eventfiles();
#	my %epicFileMap = get_EPIC_Exposures(@files);
	my $inst;
	my $exposure;
	my $mode;
	if ( $#files == 0 ) { &error_code(4); }

	foreach my $file (@files) 
	{
		( $inst, $exposure, $mode ) = &get_File_Info($file);		
		$currentExposure = &getExpoInfo($inst,$exposure,$mode);
		
		$p = $currentExposure->getProduct("spectra");					
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
			
		# Check if the user select MOS1, MOS2, PN for analysing data
		$epic_spectral_flag = 0
		  ; # Flag that determines whether the spectra should be worked out (1: True)
		if ( $odf_object->$inst eq "no" ) {
			$logger->info(
				"INSTRUMENT $inst [exposure=$exposure]: Not selected for calculating spectra");
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
			$epic_spectral_flag = 1;			
			
			$scienceLog->info( "\n   \#> spectrum science output  [$inst,$exposure,$mode]");
			#.. Define Global Variables
			$logger->info( "   \#> Defining File Names for Source Spectrum ..... ");
			create_pnProductFileNames( $instrument, $exposure, $mode );


			###FILTERING EVENT FILES
			#.. Test for existance of GTI files
			&check_GTIs_Files( $instrument, $exposure, $mode, "spectral",$source_name );

			#.. Test for existance of PN and MOS event files
			&check_Spectra_Files( $inst, $exposure, $mode, "spectral",$source_name );
			
			#.. Get instrument's observing mode and prepare things according to shape of source and background regions.
			$epic_obsmode = $obsid_instruments{$source_obsID}{$instrument}{'mode'};
			$epic_obssubmode =
			  $obsid_instruments{$source_obsID}{$instrument}{'submode'};
	
			#.. Create GTI filtered event lists.
			if ($epic_spectral_flag) {
				&produce_gticleanfile( $epic_event_list,
					$epic_gti_cleanevents_file, $epic_GTI_file, $epic_obsmode,
					$instrument,$p);
			}    # EPIC

			#.. GET some information out of the GTI filtered event lists.
			
			$logger->info( "   \#> Sending Information from GTI Filtered Event Files to event log file: ");
			$specLog->info( "   \#> Information from GTI Filtered Event Files (Spectrum): ");	
			$scienceLog->info( "   \#> Information from GTI Filtered Event Files (Spectrum): ");					
			if ($epic_spectral_flag) {
				&event_file_inf( $epic_gti_cleanevents_file, $instrument,$specLog );
				&event_file_inf( $epic_gti_cleanevents_file, $instrument,$scienceLog );
			}    # EPIC

			###FILTERING EVENT FILES


			#Check if the user has introduced a specific source and background expression for spectral production
			
			if (length ($p->getTask("especget","sp_creation")->getParam("srcexp")->getValue()) &&
				 length ($p->getTask("especget","sp_creation")->getParam("bkgexp")->getValue()) ) {
				 	if (uc($p->getTask("xmmextractor","sp_interactivity")->getParam("interactivity")->getValue()) eq "YES")
				    {
						#.. Display ds9 and get src and bkg information
						&show_ds9($epic_gti_cleanevents_file,$instrument,$exposure,$mode,"SPC",$currentExposure);
				    }
				    $src_expr = $p->getTask("especget","sp_creation")->getParam("srcexp")->getValue();
				    $bkg_expr = $p->getTask("especget","sp_creation")->getParam("bkgexp")->getValue();
				    &run_especget_user_expr( $epic_gti_cleanevents_file, $instrument, $src_expr,$bkg_expr,$currentExposure->getExpId);
			}
			else
			{
				$logger->info( "Not user information to produce the spectra...");

				#.. Check if the user has defined its own coordinates
				&setcoordinates();


				my $source_name  = $odf_object->getSourceName;
				my $source_ra    = $odf_object->getRA;
				my $source_dec   = $odf_object->getDEC;

				$logger->info( " Produce spectrum checks... Done");

				#.. RA & DEC Coordinates of position to analyze
	
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
	
	
			  #.. Make an image using the filtered event file to get source centroid
	
				if ( ( ($instrument eq "m1") || ($instrument eq "m2") ) &&  ($mode eq "TimingEvts" )  )
				{
					$logger->warn( "   \#> Cannot produce smooth image for exposure: $exposure [instrument: $instrument and mode: $mode] ");	
				} 
				else
				{
					if ($epic_spectral_flag  )    # && !-e $epic_gti_smoothimage_file)
					{
						&produce_smooth_image(
							$epic_gti_cleanevents_file, $epic_gti_image_file,
							$epic_gti_smoothimage_file, $instrument
						);
					}   #EPIC
				}

				#.. Run eregionanalyse
				
				if ($epic_spectral_flag) {
					#.. Using the instrument's image to work out the source centroid. Only for Imaging.
					$logger->info(
					"   \#> Working out the centroid of source to analyze (Physical Units)...");												
					$epic_spectral_flag =
				 	 prepare_spectra( $instrument, $exposure, $mode, $epic_obsmode,
						$epic_obssubmode, "SPC",$currentExposure );
				}

				&prepare_region_log_file( $instrument, $exposure, $mode,$currentExposure,$specLog,"SPC");
				&prepare_region_log_file( $instrument, $exposure, $mode,$currentExposure,$scienceLog,"SPC");
				
				chdir($spectra_directory);

	   			#.. Make image plots and create region files used to extract the spectrum
				##&create_spec_plots_and_regions( $instrument, $exposure, $mode,"SPC", $currentExposure);

				#.. run epatplot
				if ( uc($currentExposure->getProduct("pileup")->getProcess()) eq "YES") {
					if ($epic_spectral_flag) {
						&run_epatplot( $epic_gti_cleanevents_file, $instrument,
							"SPC", $epic_obsmode,$currentExposure );
					}    # PN
				}
			
				#.. Obtain spectrum files for PN and MOS: source, bkg, arf and rmf files
				$logger->info("   \#> Producing source/background spectrum files and arf/rmf files (especget) ...");
				$specLog->info("   \#> Producing source/background spectrum files and arf/rmf files (especget) ...");
				
					
				if ($epic_spectral_flag) {
		
					$SRC_XC = $currentExposure->get_src_X;
					$SRC_YC = $currentExposure->get_src_Y;
					if (   $currentExposure->get_src_region eq "circle"
						|| $currentExposure->get_src_region eq "annulus" )
					{
						$RSRC1 = $currentExposure->get_src_inner_roptimg;
						$RSRC2 = $currentExposure->get_src_roptimg;
					}
					if ( $currentExposure->get_src_region eq "box" ) {
						$RSRC1 = $currentExposure->get_src_XLength;					
						$RSRC2 = $currentExposure->get_src_YLength;
					}
					$BKG_XC = $currentExposure->get_bkg_X;
					$BKG_YC = $currentExposure->get_bkg_Y;
					if (   $currentExposure->get_bkg_region eq "circle"
						|| $currentExposure->get_bkg_region eq "annulus" )
					{
						$RBKG1 = $currentExposure->get_bkg_innerrimg;
						$RBKG2 = $currentExposure->get_bkg_outerrimg;
					}
					if ( $currentExposure->get_bkg_region eq "box" ) {
						$RBKG1 = $currentExposure->get_bkg_XLength;					
						$RBKG2 = $currentExposure->get_bkg_YLength;
					}

					
					#.. Check if we are in Timing and EMOS. In this case, the interactive 
					if (($mode eq "TimingEvts") && ( ($instrument eq "m1") || ($instrument eq "m2") ) )
					{
						$logger->warn( " \#> $instrument in $mode cannot be displayed");					
					        $p->getTask("xmmextractor","sp_interactivity")->getParam("interactivity")->setValue("no");
					}
					

					if ( !&test_epic_spetralfiles() ) {
						$logger->warn( " \#> $inst spectral files not found. Running especget");
						if (uc($checkInteractivity =$p->getTask("xmmextractor","sp_interactivity")->getParam("interactivity")->getValue()) eq "YES") {
							#.. Display ds9 and get src and bkg information
							&show_ds9($epic_gti_cleanevents_file,$instrument,$exposure,$mode,"SPC",$currentExposure);
						}						
						&run_especget(
							$epic_gti_cleanevents_file, $instrument,
							$SRC_XC,                    $SRC_YC,
							$RSRC1,                     $RSRC2,
							$currentExposure->get_src_region,           $BKG_XC,
							$BKG_YC,                    $RBKG1,
							$RBKG2,                     $currentExposure->get_bkg_region,
							$p, $currentExposure->getExpId
						);
					}
					else 
					{
						$logger->warn( " \#> $inst spectral files found ! ");
					} 					
					
								
					($epic_src_livetime, $epic_src_backscale,$epic_src_areascal)
					    = &event_file_spectralinf( $epic_sourcebkgspectrum_file,
								       $instrument );    # EPIC
					($epic_bkg_livetime, $epic_bkg_backscale,$epic_bkg_areascal)
					    = &event_file_spectralinf( $epic_bkgspectrum_file,
								       $instrument );    # EPIC
					if (   $epic_src_livetime eq "unknown"
					       or $epic_src_backscale eq "unknown"
					       or $epic_src_areascal  eq "unknown" )
					{
					    &error_code(6);
					}
					if (   $epic_bkg_livetime eq "unknown"
					       or $epic_bkg_backscale eq "unknown"
					       or $epic_bkg_areascal  eq "unknown" )
					  {
					    &error_code(6);
					  }
					#.. fill XML structure properly
					$p->getTask("xmmextractor","details")->getParam("areafactor")->setValue($epic_src_backscale / $epic_bkg_backscale );
			    } 		
		      }
		}		

		
		#.. Write Summary
		
		$logger->info( "\n   \#> Spectral Analysis Summary: $file [$inst,$exposure,$mode]");
		if   ( !$epic_spectral_flag ) { $epic_summ_ana_msg = "FAILED"; }
		else                          { $epic_summ_ana_msg = "OK"; }
		
		$logger->info( "      epic : spectrum analysis : $epic_summ_ana_msg ");
		$scienceLog->info( "\n   \#> spectrum science finished  [$inst,$exposure,$mode]");		
		&error_code(0);
	
      } ### END OF EPIC LOOP
	
return (0);
}


## @method void run_especget($event_file,$instr,$src_x,$src_y,$src_L1,$src_L2,$src_rshape,$bkg_x,$bkg_y,$bkg_L1,$bkg_L2,$bkg_rshape)
# Run the SAS task specget (produce EPIC spectral products)
# @param event_file Event Fele Name
# @param instr Instrument
# @param src_x Source X_coordinate (Image Coordinates)
# @param src_y Source Y_coordinate (Image Coordinates)
# @param src_L1 Source Region Inner Radius (circle,annulus), Source Region X_Box Size (box) (Image Coordinates)
# @param src_L2 Source Region Outer Radius (circle,annulus), Source Region Y_Box Size (box) (Image Coordinates)
# @param src_rshape Source Region Shape
# @param bkg_x Background X_coordinate (Image Coordinates)
# @param bkg_y Background Y_coordinate (Image Coordinates)
# @param bkg_L1 Background Region Inner Radius (circle,annulus), Background Region X_Box Size (box) (Image Coordinates)
# @param bkg_L2 Background Region Outer Radius (circle,annulus), Background Region Y_Box Size (box) (Image Coordinates)
# @param bkg_rshape Background Region Shape
# @return Void

#========================================================================
sub run_especget() {

	my $event_file = $_[0];
	my $instr      = $_[1];
	my $src_x      = $_[2];
	my $src_y      = $_[3];
	my $src_L1     = $_[4];
	my $src_L2     = $_[5];
	my $src_rshape = $_[6];
	my $bkg_x      = $_[7];
	my $bkg_y      = $_[8];
	my $bkg_L1     = $_[9];
	my $bkg_L2     = $_[10];
	my $bkg_rshape = $_[11];
	my $product   = $_[12];
	my $exposureID = $_[13];

	my $src_box_angle = 0.;
	my $bkg_box_angle = 0.;

# Note: especget cant take a '+' in the name of the file, so the '+' coming from the source name has to be replaced by a '_'.

	$epic_ancillary_file =~ s/\+/\_/;
	$srcarfset = $epic_ancillary_file;
	$epic_redistribution_matrix_file =~ s/\+/\_/;
	$srcrmfset = $epic_redistribution_matrix_file;
	$epic_sourcebkgspectrum_file =~ s/\+/\_/;
	$srcspecset = $epic_sourcebkgspectrum_file;
	$epic_bkgspectrum_file =~ s/\+/\_/;
	$bckspecset = $epic_bkgspectrum_file;

	my $mode = $obsid_instruments{ $odf_object->getObsId }{$instr}{"mode"};
	if ( $mode eq "IMAGING" || $mode eq "imaging" ) {
		$xval = "X";
		$yval = "Y";
	}
	elsif (( $mode eq "TIMING" || $mode eq "timing" )
		&& ( $instr eq "pn" ) )
	{
		$xval = "RAWX";
		$yval = "RAWY";
	}
	elsif (( $mode eq "TIMING" || $mode eq "timing" )
		&& ( $instr eq "m1" || $instr eq "m2" ) )
	{
		$xval = "RAWX";
		$yval = "TIME";
	}
	else {
		$logger->error("Error building filter spectrum expression");		
		return (0);
	}
	chdir($spectra_directory);

	if ( $src_rshape eq "circle" ) {
		$src_rshape = "annulus";
	}    # treat circle regions as annulus with R1=0
	if ( $bkg_rshape eq "circle" ) {
		$bkg_rshape = "annulus";
	}    # treat circle regions as annulus with R1=0

$src_expr = "\(\($xval,$yval\) in $src_rshape\($src_x,$src_y,$src_L1,$src_L2\)\)";
$bkg_expr = "\(\($xval,$yval\) in $bkg_rshape\($bkg_x,$bkg_y,$bkg_L1,$bkg_L2\)\)";
$product->getTask("especget","sp_creation")->getParam("srcexp")->setValue($src_expr);
$product->getTask("especget","sp_creation")->getParam("backexp")->setValue($bkg_expr);

$scienceLog->info("Spectrum source and background expressions calculated by xmmextractor");
$scienceLog->info("Instrument: $instr Exposure: $exposureID Source expression: $src_expr");
$scienceLog->info("Instrument: $instr Exposure: $exposureID Source expression: $bkg_expr");

	if ( ( $src_rshape eq "annulus" ) && ( $bkg_rshape eq "annulus" ) ) {
		@args = (
"especget -t table=\"$event_file\" srcexp=\"(($xval,$yval) in $src_rshape($src_x,$src_y,$src_L1,$src_L2))\" backexp=\"(($xval,$yval) in $bkg_rshape($bkg_x,$bkg_y,$bkg_L1,$bkg_L2))\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
		);
	}
	elsif ( ( $src_rshape eq "box" ) && ( $bkg_rshape eq "annulus" ) ) {
		$src_L1 = $src_L1 / 2.;
		$src_L2 = $src_L2 / 2.;
		@args   = (
"especget -t table=\"$event_file\" srcexp=\"(($xval,$yval) in $src_rshape($src_x,$src_y,$src_L1,$src_L2,$src_box_angle))\" backexp=\"(($xval,$yval) in $bkg_rshape($bkg_x,$bkg_y,$bkg_L1,$bkg_L2))\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
		);
	}
	elsif ( ( $src_rshape eq "annulus" ) && ( $bkg_rshape eq "box" ) ) {
		$bkg_L1 = $bkg_L1 / 2.;
		$bkg_L2 = $bkg_L2 / 2.;
		@args   = (
"especget -t table=\"$event_file\" srcexp=\"(($xval,$yval) in $src_rshape($src_x,$src_y,$src_L1,$src_L2))\" backexp=\"(($xval,$yval) in $bkg_rshape($bkg_x,$bkg_y,$bkg_L1,$bkg_L2,$bkg_box_angle))\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
		);
	}
	elsif (( $src_rshape eq "box" )
		&& ( $bkg_rshape eq "box" )
		&& ( ( $instr eq "m1" ) || ( $instr eq "m2" ) )
		&& ( uc($mode) eq "TIMING" ) )
	{
		$src_L1 = $src_L1 / 2.;
		$src_L2 = $src_L2 / 2.;
		$bkg_L1 = $bkg_L1 / 2.;
		$bkg_L2 = $bkg_L2 / 2.;
		my $SX_min = $src_x - 10;
		my $SX_max = $src_x + 10;
		my $BX_min = $bkg_x - 10;
		my $BX_max = $bkg_x + 10;
		@args = (
"especget -t table=\"$event_file\" srcexp=\"(($xval) in [$SX_min:$SX_max])\" backexp=\"(($xval) in [$BX_min:$BX_max])\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
		);
	}
	else {
		$src_L1 = $src_L1 / 2.;
		$src_L2 = $src_L2 / 2.;
		$bkg_L1 = $bkg_L1 / 2.;
		$bkg_L2 = $bkg_L2 / 2.;
		@args   = (
"especget -t table=\"$event_file\" srcexp=\"(($xval,$yval) in $src_rshape($src_x,$src_y,$src_L1,$src_L2,$src_box_angle))\" backexp=\"(($xval,$yval) in $bkg_rshape($bkg_x,$bkg_y,$bkg_L1,$bkg_L2,$bkg_box_angle))\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
		);
	}

	system(@args) == 0 or &error_code(6);

	$logger->info( "   \#> $instr : Specget Summary: ");
	$logger->info( "        SRC FILE  : $srcspecset ");
	$logger->info( "        BKG FILE  : $bckspecset ");
	$logger->info( "        RESP FILE : $srcrmfset ");
	$logger->info( "        ANCR FILE : $srcarfset ");

	$specLog->info( "   \#> $instr : Specget Summary: ");
	$specLog->info( "        SRC FILE  : $srcspecset ");
	$specLog->info( "        BKG FILE  : $bckspecset ");
	$specLog->info( "        RESP FILE : $srcrmfset ");
	$specLog->info( "        ANCR FILE : $srcarfset ");

	return (1);
}

## @method void run_especget_user_expr($event_file,$instr,$src_expr,$bkg_expr)
# Run the SAS task specget (produce EPIC spectral products) using the user defined expression
# @param event_file Event Fele Name
# @param instr Instrument
# @param source expression
# @param background expression
# @return Void

#========================================================================
sub run_especget_user_expr() {
	$logger->info( "Running especget using user's expression");

	my $event_file = $_[0];
	my $instr      = $_[1];
	my $src_expr   = $_[2];
	my $bkg_expr   = $_[3];
	my $exposureID = $_[4];


$scienceLog->info("Spectrum source and background expressions: user's defined expressions");
$scienceLog->info("Instrument: $instr Exposure: $exposureID Source expression: $src_expr");
$scienceLog->info("Instrument: $instr Exposure: $exposureID Source expression: $bkg_expr");

# Note: especget cant take a '+' in the name of the file, so the '+' coming from the source name has to be replaced by a '_'.

	$epic_ancillary_file =~ s/\+/\_/;
	$srcarfset = $epic_ancillary_file;
	$epic_redistribution_matrix_file =~ s/\+/\_/;
	$srcrmfset = $epic_redistribution_matrix_file;
	$epic_sourcebkgspectrum_file =~ s/\+/\_/;
	$srcspecset = $epic_sourcebkgspectrum_file;
	$epic_bkgspectrum_file =~ s/\+/\_/;
	$bckspecset = $epic_bkgspectrum_file;

	chdir($spectra_directory);

	@args = (
"especget -t table=\"$event_file\" srcexp=\"$src_expr\" backexp=\"$bkg_expr\" withbadpixcorr=yes srcarfset=$srcarfset srcrmfset=$srcrmfset srcspecset=$srcspecset bckspecset=$bckspecset"
	);

	system(@args) == 0 or &error_code(6);

	$logger->info( "   \#> $instr : Specget Summary: ");
	$logger->info( "        SRC FILE  : $srcspecset ");
	$logger->info( "        BKG FILE  : $bckspecset ");
	$logger->info( "        RESP FILE : $srcrmfset") ;
	$logger->info( "        ANCR FILE : $srcarfset ");
	$specLog->info( "   \#> $instr : Specget Summary: ");
	$specLog->info( "        SRC FILE  : $srcspecset ");
	$specLog->info( "        BKG FILE  : $bckspecset ");
	$specLog->info( "        RESP FILE : $srcrmfset") ;
	$specLog->info( "        ANCR FILE : $srcarfset ");
	
	return (1);

}

## @method void test_epic_spetralfiles()
# Test for the existance of pn spectral files
# @return Void

#========================================================================
sub test_epic_spetralfiles {

   # Specget does not take file names with '+' on them. They are changed by '_'.
	chdir '$spectra_directory';
	$epic_ancillary_file =~ s/\+/\_/;	
	
	if ( ! -e $spectra_directory.'/'.$epic_ancillary_file ) {
		$logger->info( "PN Ancillery file does not exist ");
		return (0);
	}
	
	$epic_redistribution_matrix_file =~ s/\+/\_/;
	if ( !-e  $spectra_directory.'/'.$epic_redistribution_matrix_file ) {
		$logger->info( "PN Redistribution Matrix file does not exist");
		return (0);
	}
	$epic_sourcebkgspectrum_file =~ s/\+/\_/;
	if ( !-e $spectra_directory.'/'.$epic_sourcebkgspectrum_file ) {
		$logger->info( "PN Source Spectrum file does not exist");
		return (0);
	}
	$epic_bkgspectrum_file =~ s/\+/\_/;
	if ( !-e $spectra_directory.'/'.$epic_bkgspectrum_file ) {
		$logger->info( "PN Background Spectrum file does not exist");
		return (0);
	}
	return (1);
}

## @method void calculate_sky_coords()
# Converts DETX and DETY coordinates into sky images
# @return sky images

sub calculate_sky_coords {
	$imageFile = $_[0];
	$instr = $_[1];
	$output_File = $_[2];
	$DETX = 3640; #CCD2
	$DETY = -10290 ; #CCD2
	$coordtype = "DET";
	 	
	
	@args = ("ecoordconv imageset=\"$imageFile\" x=$DETX y=$DETY coordtype=$coordtype -V 4 > $output_File");
	system(@args) == 0 or &error_code(9);
	
	#Return values
	my $Xima = 0;
	my $Yima = 0;
	
	
	if ( -e $output_File ) {

		open( EREGION, "$output_File" )
		  or die "Cant open output file: $! \n";
		;    #open for write, overwrite
		$logger->info(
		  "   \#> INFORMATION OUT OF ecoordconv ($output_File) :");
		$logger->info( "   \#> Run on location: DETX: $DETX - DETY: $DETY ");

		while (<EREGION>) {
			my $line =$_;
			$line =~ s/\s+$//;
			$scienceLog->info( "$line");			
			next if /^ecoordconv/;
			next if /^(\s)*$/;
			if (/X: Y:/) {			
				my @values = split(/ /,$_);
				chomp( $Xima = $values[3] );
				$Xima =~ s/\s+//;
				chomp( $Yima = $values[4] );
				$Yima =~ s/\s+//;
				
			}
		}
		close(EREGION);
	}
	$logger->info( "\t Image coordinates X: $Xima - Y: $Yima ");
	if (($Xima == 0) || ($Yima == 0))
	{
		$logger->error( " \#> ERROR converting to Image coordinates");
		&error_code(9);
	} 
	return ($Xima,$Yima);
	
}

1;
