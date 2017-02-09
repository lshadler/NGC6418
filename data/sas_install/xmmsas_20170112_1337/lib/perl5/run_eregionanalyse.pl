## @method run_eregionanalyse($image_file,$r,$d,$instr,$submode,$eregionanal_file,$analysis)
# Run the SAS task eregionanalyse (Find optimum source extraction region). The source region is a circle and the background region is an annulus centered on the source region, whose inner radius is a given distance away from the source radius.
# @param image_file Image File Name
# @param r Source RA
# @param d Source DEC
# @param instr Instrument
# @param submode Observation Mode
# @param eregionanal_file File for output depending on instrument
# @param analysis Which analysis routine is calling eregionanalyse (LC,SPC,PG)
# @return Source X_Centroid, Source Y_Centroid, Optimum Source Radius (sky coord), Optimum Source Radius (image coord), Background Inner Radius (Sky coord), Background Inner Radius (Image coord), Background Outer Radius (Sky coord), Background Outer Radius (Image coord)

#========================================================================
sub run_eregionanalyse() {

	my $image_file = $_[0];
	my $r          = $_[1];
	my $d          = $_[2];
	my $instr      = $_[3];
	my $submode    = $_[4];
	my $eregionanal_file = $_[5];    # Select file for output depending on instrument
	my $analysis = $_[6];    # Which analysis routine is calling eregionanalyse
	my $currentExposure = $_[7];
	
	$logger->info( "\n ----> Running eregionanalyse over $image_file .... ");

	#.. Work out Annulus that will define the BKG Region
$areafactor = $currentExposure->getProduct("lightcurve")->getTask("xmmextractor","details")->getParam("areafactor")->getValue();# How much bigger the BKG area should be with respect to the on-source Area

	if ( $analysis eq "PG" )  { $areafactor = 1.0; }



#.. NOTE: 0.001666667deg = 6arcsecs (EPIC-pn PSF which the worse case scenario (EPIC-MOS = 5arcsec))
#..       The area covered by the bkg region is chosen to cover the same area as that of the source region


	my $sky2img = 1.0 / 0.05;  # 1 sky pixel = 0.05arcsec

#    my $src_radius      = 0.001666667;                             # Initial value (= EPIC-pn PSF)
	my $src_radius = 0.005555555556
	  ;    # (5 June 2008) After talking to Richard, this initial region
	       # is used to work out the centroid. So it should be bigger than 6",
	       # 20" is a good starting point.
	my $bkg_rad_factor =
	  1;    # How far from the src region is the background region
	my $bkg_innerradius = 0.01666667
	  ; # Initial value (Should be around 60arcsec, the values used in the pipeline)

	my $bkg_outerradius =
	  sqrt( $bkg_innerradius**2 + $areafactor * $src_radius**2 )
	  ;    # Initial value

	#.. Return Values
	my $x             = 1;
	my $y             = 1;
	my $xc            = 1;
	my $yc            = 1;
	my $ropt          = 1;
	my $roptsky       = 1;
	my $bkg_innerrsky = 0;
	my $bkg_outerrsky = 0.;
	my $bkg_innerrimg = 0.;
	my $bkg_outerrimg = 0.;
	

	$src_expr = "((RA,DEC) in circle($r,$d,$src_radius))";
	$bkg_expr =
	  "((RA,DEC) in annulus($r,$d,$bkg_innerradius,$bkg_outerradius))";
	if ( ( $instr eq "m1" || $instr eq "m2" )
		&& ($submode eq "PrimePartialW2" || $submode eq "PrimePartialW3" || $submode eq "PrimePartialW4") )
	{
		$logger->warn( "       WARNING: $instr Entering Small Window Settings.");
		
		#call to ecoordconv
		
		($xc,$yc) = &calculate_sky_coords($image_file,$instr,$epic_ecoordconv_file);
		
		$rad1 = 0.;
		$rad2 = sqrt($areafactor) * 3600. * $src_radius * $sky2img;
		$bkg_expr = "((X,Y) in annulus($xc,$yc,$rad1,$rad2))";	
	}
	
	@args = (
"eregionanalyse imageset=\"$image_file\" srcexp=\"$src_expr\" backexp=\"$bkg_expr\" -V 4 > $eregionanal_file"
	);
	system(@args) == 0 or &error_code(6);

	if ( -e $eregionanal_file ) {

		open( EREGION, "$eregionanal_file" )
		  or die "Cant open output file: $! \n";
		;    #open for write, overwrite
		$logger->info(
		  "   \#> INFORMATION OUT OF eregionanalyse ($eregionanal_file) send to science log");

		$scienceLog->info(
		  "   \#> INFORMATION OUT OF eregionanalyse ($eregionanal_file) :");
		$scienceLog->info( "\t $instr : Run on location: RA: $r - DEC: $d ");


		while (<EREGION>) {
			#$logger->info( "\t $_");
			#$scienceLog->info( "\t $_");
			if ((/eregionanalyse/) && (/input region centre/))
			{
				my $line =$_;
				$line =~ s/\s+$//;
				$scienceLog->info( "$line");	
			}
			
			next if /^eregionanalyse/;
			next if /^(\s)*$/;
			#$logger->info( "$instr : $_");
			if (/xcentroid/) {
				@split = split /:/, $_;
				chomp( $x = $split[1] );
				$x =~ s/\s+//;
			}
			if (/ycentroid/) {
				@split = split /:/, $_;
				chomp( $y = $split[1] );
				$y =~ s/\s+//;
			}

			if ( (/exposure/) || (/input region centre/) ||
				(/encircled/) || (/Bckgnd/) ){				
				my $line =$_;
				$line =~ s/\s+$//;
				$scienceLog->info( "$line");
			}

			if (/optradius/) {
				( $roptsky, $roptimg ) = ( split /\s+/, $_ )[ 2, 4 ];
				$roptsky =~ s/\s+//;
				$roptimg =~ s/\s+//;
			}			
		}		
		close(EREGION);
	}

	#.. Background center region
	$xb = $x;
	$yb = $y;
	if ( ( $instr eq "m1" || $instr eq "m2" )
		&& ($submode eq "PrimePartialW2" || $submode eq "PrimePartialW3" || $submode eq "PrimePartialW4") )
	{
		$xb              = $xc;
		$yb              = $yc;
		$bkg_innerradius = 0.;
	}

	#.. Source Region Size
	if ( ( $instr eq "m1" || $instr eq "m2" )
		&& ($submode eq "PrimePartialW2" || $submode eq "PrimePartialW3" || $submode eq "PrimePartialW4") )
	{
		if ( $roptsky > 40.0 ) {
			$roptsky = 40.0;     # arcsec
			$roptimg = 800.0;    # image
			$logger->warn(" WARNING: $instr Radius of Source Region greater than 40 arsec. Set to 40 arsec.");

		}
	}

	#.. In sky coordinates
	$bkg_innerrsky = 3600. *
	  $bkg_innerradius; # Inner radius of BKG region in sky coordinates (arcsec)
	$bkg_outerrsky = sqrt( $areafactor * $roptsky**2 + $bkg_innerrsky**2 );

	#.. In image coordinates
	$bkg_innerrimg =
	  3600. *
	  $bkg_innerradius *
	  $sky2img;    # Inner radius of BKG region in imag coordinates (arcsec)
	  
	$bkg_outerrimg = sqrt( $areafactor * $roptimg**2 + $bkg_innerrimg**2 );
	
				
	return (
		$x,             $y,  $roptsky,       $roptimg,
		$xb,            $yb, $bkg_innerrsky, $bkg_innerrimg,
		$bkg_outerrsky, $bkg_outerrimg
	);
}

1;

