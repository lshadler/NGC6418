
sub prepare_spectra() {
	my $instrument          = $_[0];
	my $exposure            = $_[1];
	my $mode                = $_[2];
	my $epic_obsmode        = $_[3];
	my $epic_obssubmode     = $_[4];
	my $type                = $_[5];
	my $ori_instrument_name = $instrument;
	my $currentExposure = $_[6];
	
	my $currentProduct ="";
	if ($type eq "SPC")
	{
		$currentProduct = "spectra";
	}
	elsif ($type eq "LC")
	{
		$currentProduct = "lightcurve";
	}
	

	#.. Initial value set to 1 (true)
	$epic_spectral_flag = 1;


	if ( $epic_obsmode eq 'IMAGING' || $epic_obsmode eq 'imaging' ) {

		#.. Run eregionanalyze at the source ra and dec position.
		my $epic_bore_img_x         = $instrument . "_bore_img_x";
		my $epic_bore_img_y         = $instrument . "_bore_img_y";
		my $epic_bore_optrad_asec   = $instrument . "_bore_optrad_asec";
		my $epic_bore_optradius     = $instrument . "_bore_optradius";
		my $epic_bore_img_xbkg      = $instrument . "_bore_img_xbkg";
		my $epic_bore_img_ybkg      = $instrument . "_bore_img_ybkg";
		my $epic_bkg_inner_rad_asec = $instrument . "_bkg_inner_rad_asec";
		my $epic_bkg_inner_rad      = $instrument . "_bkg_inner_rad";
		my $epic_bkg_outer_rad_asec = $instrument . "_bkg_outer_rad_asec";
		my $epic_bkg_outer_rad      = $instrument . "_bkg_outer_rad";

		(
			$epic_bore_img_x,         $epic_bore_img_y,
			$epic_bore_optrad_asec,   $epic_bore_optradius,
			$epic_bore_img_xbkg,      $epic_bore_img_ybkg,
			$epic_bkg_inner_rad_asec, $epic_bkg_inner_rad,
			$epic_bkg_outer_rad_asec, $epic_bkg_outer_rad
		) = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
		
		(
			$epic_bore_img_x,         $epic_bore_img_y,
			$epic_bore_optrad_asec,   $epic_bore_optradius,
			$epic_bore_img_xbkg,      $epic_bore_img_ybkg,
			$epic_bkg_inner_rad_asec, $epic_bkg_inner_rad,
			$epic_bkg_outer_rad_asec, $epic_bkg_outer_rad
		  )
		  = &run_eregionanalyse( $epic_gti_image_file, $ra_anal, $dec_anal,$instrument, $epic_obssubmode, $epic_eregionanal_file, $type,$currentExposure )
		  ;    # EPIC

		$currentExposure->initEregionAnalyseVars();
		if ( $epic_bore_optrad_asec == 300 ) {
			$epic_spectral_flag = 0;
		} # Something has gone wrong so wont produce spectra. 300 is maximum allowed value.

		#.. Check values of parameters defining source and background regions

		#.. Get shape of src and bkg regions:
		$currentExposure->set_src_region("circle");
		$currentExposure->set_bkg_region("annulus");
		
		$currentExposure->set_src_XLength(0);
		$currentExposure->set_src_YLength(0);
		$currentExposure->set_bkg_XLength(0);
		$currentExposure->set_bkg_YLength(0);
		
		
		$src_region_shape = $currentExposure->get_src_region();
		$bkg_region_shape = $currentExposure->get_bkg_region();

		$src_XC = $currentExposure->get_src_X();
		$src_YC = $currentExposure->get_src_Y();
		$src_R1 = $currentExposure->get_src_inner_roptimg();
		$src_R2 = $currentExposure->get_src_roptimg();
		$src_XL = $currentExposure->get_src_XLength();
		$src_YL = $currentExposure->get_src_YLength();
		$bkg_XC = $currentExposure->get_bkg_X();
		$bkg_YC = $currentExposure->get_bkg_Y();
		$bkg_R1 = $currentExposure->get_bkg_innerrimg();
		$bkg_R2 = $currentExposure->get_bkg_outerrimg();
		$bkg_XL = $currentExposure->get_bkg_XLength();
		$bkg_YL = $currentExposure->get_bkg_YLength();

		if ( $src_XC == 0 && $src_YC == 0 )
		{    # if values are set to cero take the default; from eregionanalyse
			$currentExposure->set_src_X($epic_bore_img_x);
			$currentExposure->set_src_Y($epic_bore_img_y);
		}

		if ( $bkg_XC == 0 && $bkg_YC == 0 )
		{    # if values are set to cero take the default; from eregionanalyse
			$currentExposure->set_bkg_X($epic_bore_img_xbkg);
			$currentExposure->set_bkg_Y($epic_bore_img_ybkg);			
		}

		#.. SRC Region
		if ( $src_region_shape eq "circle" ) {
			$currentExposure->set_src_inner_roptimg(0);		
			if ( $src_R2 == 0 )
			{  # if values are set to cero take the default; from eregionanalyse
				
				$currentExposure->set_src_roptimg($epic_bore_optradius);
			}			
			$src_area =
			  $pi * $currentExposure->get_src_roptimg * $currentExposure->get_src_roptimg -
			  $pi * $currentExposure->get_src_inner_roptimg * $currentExposure->get_src_inner_roptimg;
		}
		elsif ( $src_region_shape eq "annulus" ) {
			if ( $src_R1 == 0 || $src_R2 == 0 ) {
				$logger->info( "       $instrument SRC Region should be defined");
				&error_code(6);
			}
			$src_area =
			  $pi * $currentExposure->get_src_roptimg * $currentExposure->get_src_roptimg -
			  $pi * $currentExposure->get_src_inner_roptimg * rrentExposure->get_src_inner_roptimg;
		}
		elsif ( $src_region_shape eq "box" ) {
			if ( $src_XL == 0 || $src_YL == 0 ) {
				$logger->info( "       $instrument SRC Region should be defined");
				&error_code(6);
			}
			$src_area = $currentExposure->get_src_XLength * $currentExposure->get_src_YLength;
		}
		else {
			$logger->info( "       $instrument SRC Region not recognized");
			&error_code(6);
		}

		#.. BKG Region
		if ( $bkg_region_shape eq "circle" ) {
			$currentExposure->set_bkg_innerrimg(0);
			if ( $bkg_R2 == 0 ) {
				$logger->info( "       $instrument BKG Region should be defined");
				&error_code(6);
			}

			$bkg_area =
			  $pi * $currentExposure->get_bkg_outerrimg() * $currentExposure->get_bkg_outerrimg() -
			  $pi * $currentExposure->get_bkg_innerrimg() * $currentExposure->get_bkg_innerrimg();
		}
		elsif ( $bkg_region_shape eq "annulus" ) {
			if ( $bkg_R1 == 0 || $bkg_R2 == 0 )
			{  # if values are set to cero take the default; from eregionanalyse
				$currentExposure->set_bkg_innerrimg($epic_bkg_inner_rad);
				$currentExposure->set_bkg_outerrimg($epic_bkg_outer_rad);
			}
			$bkg_area =
			  $pi * $currentExposure->get_bkg_outerrimg() * $currentExposure->get_bkg_outerrimg() -
			  $pi * $currentExposure->get_bkg_innerrimg() * $currentExposure->get_bkg_innerrimg();
		}
		elsif ( $bkg_region_shape eq "box" ) {
			if ( $bkg_XL == 0 || $bkg_YL == 0 ) {
				$logger->info( "       $instrument BKG Region should be defined");
				&error_code(6);
			}
			$bkg_area = $currentExposure->get_bkg_XLength() * $currentExposure->get_bkg_YLength();
		}
		else {
			$logger->info( "       $instrument BKG Region not recognized");
			&error_code(6);
		}
				
		#.. Fill the XML structure properly
		$currentExposure->getProduct($currentProduct)->getTask("xmmextractor","details")->getParam("areafactor")->setValue($src_area / $bkg_area );

		if ( $currentExposure->get_src_X() == 0 && 
				$currentExposure->get_src_Y() == 0 ) {
			$epic_spectral_flag = 0;
		}    # Something has gone wrong so wont produce spectra.

	}
	elsif ( $epic_obsmode eq 'TIMING' || $epic_obsmode eq 'timing' ) {

		$currentExposure->set_src_region("box");
		$src_XC = $currentExposure->get_src_X();
		$src_YC = $currentExposure->get_src_Y();
		$src_XL = $currentExposure->get_src_XLength();
		$src_YL = $currentExposure->get_src_YLength();
		
		if ( $instrument eq 'm1' || $instrument eq 'm2' ) {
			$t_start =
			  $obsid_instruments{$odf_object->getObsId}{$instrument}
			  {'starting_time'};
			$t_end =
			  $obsid_instruments{$odf_object->getObsId}{$instrument}{'ending_time'};
			$interval     = $t_end - $t_start;
			$mid_interval = $t_start + $interval / 2.;
			$currentExposure->set_src_X(299.5);
			$currentExposure->set_src_Y($mid_interval);
			$currentExposure->set_src_XLength(20);
			$currentExposure->set_src_YLength($interval);
		}
		else {
			$currentExposure->set_src_X(37.);
			$currentExposure->set_src_Y(101.);
			$currentExposure->set_src_XLength(16);
			$currentExposure->set_src_YLength(199);
		}
	

		$currentExposure->set_bkg_region("box");
		$bkg_XC = $currentExposure->get_bkg_X();
		$bkg_YC = $currentExposure->get_bkg_Y();
		$bkg_XL = $currentExposure->get_bkg_XLength();
		$bkg_YL = $currentExposure->get_bkg_YLength();
	
		if ( $instrument eq 'm1' || $instrument eq 'm2' ) {
			$currentExposure->set_bkg_X(259.0)
			  ;    # lowest column value in MOS Timing 256
			$currentExposure->set_bkg_Y( $currentExposure->get_src_Y() );
			$currentExposure->set_bkg_XLength( $currentExposure->get_src_XLength() );
			$currentExposure->set_bkg_YLength( $currentExposure->get_src_YLength() );
		}
		else {
			$currentExposure->set_bkg_X( $currentExposure->get_src_XLength() / 2. + 0.5 )
			  ;    # +0.5 to keep it away from the edge of the detector
			$currentExposure->set_bkg_Y( $currentExposure->get_src_Y() );
			$currentExposure->set_bkg_XLength( $currentExposure->get_src_XLength() );
			$currentExposure->set_bkg_YLength( $currentExposure->get_src_YLength() );
		}
	

		$src_area = $currentExposure->get_src_XLength() * $currentExposure->get_src_YLength();
		$bkg_area = $currentExposure->get_bkg_XLength() * $currentExposure->get_bkg_YLength();
		#.. fill XML structure properly
		$currentExposure->getProduct($currentProduct)->getTask("xmmextractor","details")->getParam("areafactor")->setValue($src_area / $bkg_area );

	}
	else {
		$logger->info( "       $instrument Mode ($epic_obsmode) not recognized");
		&error_code(6);
	}

	$logger->info( "       $instrument ");
	$logger->info( "         $instrument Region SRC : ", $currentExposure->get_src_region());
	$logger->info( "         $instrument SRC XC     : ", $currentExposure->get_src_X());
	$logger->info( "         $instrument SRC YC     : ", $currentExposure->get_src_Y());
	if ( $currentExposure->get_src_region eq 'circle' || $currentExposure->get_src_region eq 'annulus' ) {
		$logger->info( "         $instrument SRC RC     : ", $currentExposure->get_src_inner_roptimg(),
		  " - ", $currentExposure->get_src_roptimg());
	}
	if ( $currentExposure->get_src_region eq 'box' ) {
		$logger->info( "        $instrument SRC BOX    : ", $currentExposure->get_src_XLength,
		  " - ", $currentExposure->get_src_YLength);
	}
	$logger->info( "         $instrument Region BKG : ", $currentExposure->get_bkg_region);
	$logger->info( "         $instrument BKG XC     : ", $currentExposure->get_bkg_X);
	$logger->info( "         $instrument BKG YC     : ", $currentExposure->get_src_Y);
	if ( $currentExposure->get_bkg_region eq 'circle' || $currentExposure->get_bkg_region eq 'annulus' ) {
		$logger->info( "         $instrument BKG RC     : ", $currentExposure->get_bkg_innerrimg(),
		  " - ", $currentExposure->get_bkg_outerrimg());
		if ( $currentExposure->get_bkg_outerrimg() > $currentExposure->get_bkg_innerrimg() ) {
			$logger->info(
"         WARNING: $instrument regions : The inner background region radii is smaller than the source region radii");
		}
	}
	if ( $currentExposure->get_bkg_region eq 'box' ) {
		$logger->info( "         $instrument BKG BOX    : ", $currentExposure->get_bkg_XLength,
		  " - ", $currentExposure->get_bkg_YLength);
	}
	$logger->info( "         $instrument BKG AREA SCALE FACTOR : ",
	  $currentExposure->getProduct($currentProduct)->getTask("xmmextractor","details")->getParam("areafactor")->getValue(), " (Only area taken into account)");
	if ( $currentExposure->get_src_roptimg() == 6000 ) {
		$logger->info("         WARNING : $instrument regions : Maximum allowed radius reached");
	}
	
	return ($epic_spectral_flag);
}

sub create_spec_plots_and_regions() {
	my $instrument = $_[0];
	my $exposure   = $_[1];
	my $mode       = $_[2];
	my $type       = $_[3];
	my $currentExposure = $_[4];	


	$logger->info( "\#> Producing plots and region files ..... ");


	if ( -e $epic_spectral_region_file ) {
		unlink("$epic_spectral_region_file")
		  or die "Cannot rm file $temp_file: $!";
	}

	if ( -e $epic_spectral_bkgregion_file ) {
		unlink("$epic_spectral_bkgregion_file")
		  or die "Cannot rm file $temp_file: $!";
	}

	if ( -e $epic_spectral_combinedregion_file ) {
		unlink("$epic_spectral_combinedregion_file")
		  or die "Cannot rm file $temp_file: $!";
	}

	#.. SRC
	if ( $currentExposure->get_src_region() eq "circle" || $currentExposure->get_src_region() eq "annulus" ) {
		$x  = $currentExposure->get_src_X();
		$y  = $currentExposure->get_src_Y();
		$L1 = $currentExposure->get_src_inner_roptimg();
		$L2 = $currentExposure->get_src_roptimg();
	}
	if ( $currentExposure->get_src_region() eq "box" ) {
		$x  = $currentExposure->get_src_X();
		$y  = $currentExposure->get_src_Y();
		$L1 = $currentExposure->get_src_XLength();
		$L2 = $currentExposure->get_src_YLength();
	}
	if ($epic_spectral_flag) {
		&addsourcetoregionfile( $epic_spectral_region_file, $x, $y, $L1, $L2,
			"yellow", "", $currentExposure->get_src_region, "physical" );    # EPIC
	}
	if ($epic_spectral_flag) {
		&addsourcetoregionfile( $epic_spectral_combinedregion_file,
			$x, $y, $L1, $L2, "yellow", "", $currentExposure->get_src_region, "physical" )
		  ;                                                    #EPIC
	}

	#.. BKG

	if ( $currentExposure->get_bkg_region eq "circle" || $currentExposure->get_bkg_region eq "annulus" ) {
		$x  = $currentExposure->get_bkg_X();
		$y  = $currentExposure->get_bkg_Y();
		$L1 = $currentExposure->get_bkg_innerrimg();
		$L2 = $currentExposure->get_bkg_outerrimg();
	}
	if ( $currentExposure->get_bkg_region eq "box" ) {
		$x  = $currentExposure->get_bkg_X();
		$y  = $currentExposure->get_bkg_Y();
		$L1 = $currentExposure->get_bkg_XLength();
		$L2 = $currentExposure->get_bkg_YLength();
	}
	if ($epic_spectral_flag) {
		&addsourcetoregionfile( $epic_spectral_bkgregion_file, $x, $y, $L1, $L2,
			"red", "", $currentExposure->get_bkg_region(), "physical" );
	}
	if ($epic_spectral_flag) {
		&addsourcetoregionfile( $epic_spectral_combinedregion_file,
			$x, $y, $L1, $L2, "red", "", $currentExposure->get_bkg_region(), "physical" );
	}

	#.. PS Plots

	if ($epic_spectral_flag) {
		if (-e $epic_gti_smoothimage_file) {
			&produce_ps_file( $epic_gti_smoothimage_file,
				$epic_spectral_combinedregion_file,
				$instrument, $epic_spectrum_psfile );
		}
	}    # PN

}

1;
