## @file
# Initialize analysis parameters

#========================================================================
sub cheese_parameters_init() {

	#.. Read Script Options
	my $name = "cheese";
	my $line = "@ARGV";
	my @save;

	if ( @save = grep /^\-p/, @ARGV ) {
		&cheese_usage();
	}

	if ( @save = grep /^-d/, @ARGV ) {
		system("sasdialog $name");
		my $x = $? >> 8;
		exit($x);
	}

	if ( @save = grep /^-v/, @ARGV ) {
		&getVersion();
	}

	#.. Default parameters (Start)

	if ( @save = grep /^prefixm=/, @ARGV ) {
		$temp = "$save[-1]";
		$temp =~ s/^.*=//;
		@prefixm = split(" ",$temp);		
	}
	else { @prefixm = (); }

	if ( @save = grep /^prefixp=/, @ARGV ) {
		$temp = "$save[-1]";
		$temp =~ s/^.*=//;
		@prefixp = split(" ",$temp);
	}
	else { @prefixp = (); }

    if ( @save = grep /^verb=/ , @ARGV) {
       $verb="$save[-1]";
       $verb =~ s/^.*=//; 
       $verb =~ s/\+/\_/;              
    }else { $verb=1; }

    if ( @save = grep /^scale=/ , @ARGV) {
       $scale="$save[-1]";
       $scale =~ s/^.*=//; 
       $scale =~ s/\+/\_/;              
    }else { $scale=0.5; }

    if ( @save = grep /^rate=/ , @ARGV) {
       $rate ="$save[-1]";
       $rate =~ s/^.*=//; 
       $rate =~ s/\+/\_/;              
    }else { $rate=1.0; }

    if ( @save = grep /^rates=/ , @ARGV) {
       $rates ="$save[-1]";
       $rates =~ s/^.*=//; 
       $rates =~ s/\+/\_/;              
    }else { $rates=1.0; }

    if ( @save = grep /^rateh=/ , @ARGV) {
       $rateh ="$save[-1]";
       $rateh =~ s/^.*=//; 
       $rateh =~ s/\+/\_/;              
    }else { $rateh=1.0; }

    if ( @save = grep /^dist=/ , @ARGV) {
       $dist="$save[-1]";
       $dist =~ s/^.*=//; 
       $dist =~ s/\+/\_/;              
    }else { $dist=40.0; }

    if ( @save = grep /^mlmin=/ , @ARGV) {
       $mlmin ="$save[-1]";
       $mlmin =~ s/^.*=//; 
       $mlmin =~ s/\+/\_/;              
    }else { $mlmin=15.0; }

    if ( @save = grep /^clobber=/ , @ARGV) {
       $clobber="$save[-1]";
       $clobber =~ s/^.*=//; 
       $clobber =~ s/\+/\_/;              
    }else { $clobber=1;}

    if ( @save = grep /^elow=/, @ARGV ) {
		$temp = "$save[-1]";
		$temp =~ s/^.*=//;
		@elow = split(" ",$temp);		
    }else { @elow = (400,2000); }

    if ( @save = grep /^ehigh=/, @ARGV ) {
		$temp = "$save[-1]";
		$temp =~ s/^.*=//;
		@ehigh = split(" ",$temp);		
    }else { @ehigh = (1300,7200); }

#.. Compute GTI user option (Start)      
	if ( @prefixm != 0 ) {
		$gv->Cheese_prefixm(@prefixm);
	}
	else {
		@tmp = ();
		$gv->Cheese_prefixm(@tmp);  # MOS exposures
	}   
	
	if ( @prefixp != 0 ) {
		$gv->Cheese_prefixp(@prefixp);
	}
	else {
		@tmp = ();
		$gv->Cheese_prefixp(@tmp); # PN exposures
	}    	
	
	$gv->Cheese_verb($verb);
	$gv->Cheese_scale($scale);
	$gv->Cheese_rate($rate);
	$gv->Cheese_rates($rates);
	$gv->Cheese_rateh($rateh);
	$gv->Cheese_dist($dist);
	$gv->Cheese_mlmin($mlmin);
	$gv->Cheese_clobber($clobber);
	if ( @elow != 0 ) {
		$gv->Cheese_elow(@elow);
	}
	else {
		@tmp = ();
		$gv->Cheese_elow(@tmp);
	}   
	if ( @ehigh != 0 ) {
		$gv->Cheese_ehigh(@ehigh)
	}
	else {
		@tmp = ();
		$gv->Cheese_ehigh(@tmp);
	}   
	
	return (0);
}

# @file
# Initialize analysis parameters

#========================================================================
sub mosspectra_parameters_init() {

	#.. Read Script Options
	my $name = "mosspectra";
	my $line = "@ARGV";
	my @save;

	if ( @save = grep /^\-p/, @ARGV ) {
		&mosspectra_usage();
	}

	if ( @save = grep /^-d/, @ARGV ) {
		system("sasdialog $name");
		my $x = $? >> 8;
		exit($x);
	}

	if ( @save = grep /^-v/, @ARGV ) {
		&getVersion();
	}

	#.. Default parameters (Start)
   if ( @save = grep /^prefix=/ , @ARGV) {
       $prefix="$save[-1]";
       $prefix =~ s/^.*=//; 
       $prefix =~ s/\+/\_/;              
   }else { $prefix="1S001"; }
   
   $gv->MOSSpectra_prefix($prefix);

   if ( @save = grep /^region=/ , @ARGV) {
       $region="$save[-1]";
       $region =~ s/^.*=//; 
       $region =~ s/\+/\_/;              
   }else { $region="reg.txt"; }
   
   $gv->MOSSpectra_region($region);

   if ( @save = grep /^mask=/ , @ARGV) {
       $mask="$save[-1]";
       $mask =~ s/^.*=//; 
       $mask =~ s/\+/\_/;              
   }else { $mask=0; }
   
   $gv->MOSSpectra_mask($mask);
   
   if ( @save = grep /^elow=/ , @ARGV) {
       $elow="$save[-1]";
       $elow =~ s/^.*=//; 
       $elow =~ s/\+/\_/;              
   }else { $elow=0; }
   
   $gv->MOSSpectra_elow($elow);

  if ( @save = grep /^ehigh=/ , @ARGV) {
       $ehigh="$save[-1]";
       $ehigh =~ s/^.*=//; 
       $ehigh =~ s/\+/\_/;              
   }else { $ehigh=0; }
   
   $gv->MOSSpectra_ehigh($ehigh);
   
   if ( @save = grep /^ccd1=/ , @ARGV) {
       $ccd1="$save[-1]";
       $ccd1 =~ s/^.*=//; 
       $ccd1 =~ s/\+/\_/;              
   }else { $ccd1=1; }
   $gv->MOSSpectra_CCD1($ccd1);
   
   if ( @save = grep /^ccd2=/ , @ARGV) {
       $ccd2="$save[-1]";
       $ccd2 =~ s/^.*=//; 
       $ccd2 =~ s/\+/\_/;              
   }else { $ccd2=1; }
   
   $gv->MOSSpectra_CCD2($ccd2);
   
   if ( @save = grep /^ccd3=/ , @ARGV) {
       $ccd3="$save[-1]";
       $ccd3 =~ s/^.*=//; 
       $ccd3 =~ s/\+/\_/;              
   }else { $ccd3=1; }
   
   $gv->MOSSpectra_CCD3($ccd3);
   
   if ( @save = grep /^ccd4=/ , @ARGV) {
       $ccd4="$save[-1]";
       $ccd4 =~ s/^.*=//; 
       $ccd4 =~ s/\+/\_/;              
   }else { $ccd4=1; }
   
   $gv->MOSSpectra_CCD4($ccd4);
   
   if ( @save = grep /^ccd5=/ , @ARGV) {
       $ccd5="$save[-1]";
       $ccd5 =~ s/^.*=//; 
       $ccd5 =~ s/\+/\_/;              
   }else { $ccd5=1; }
   
   $gv->MOSSpectra_CCD5($ccd5);
   
   if ( @save = grep /^ccd6=/ , @ARGV) {
       $ccd6="$save[-1]";
       $ccd6 =~ s/^.*=//; 
       $ccd6 =~ s/\+/\_/;              
   }else { $ccd6=1; }
   
   $gv->MOSSpectra_CCD6($ccd6);
   
   if ( @save = grep /^ccd7=/ , @ARGV) {
       $ccd7="$save[-1]";
       $ccd7 =~ s/^.*=//; 
       $ccd7 =~ s/\+/\_/;              
   }else { $ccd7=1; }
   
   $gv->MOSSpectra_CCD7($ccd7);
     
  if ( @save = grep /^cflim=/ , @ARGV) {
       $cflim="$save[-1]";
       $cflim =~ s/^.*=//; 
       $cflim =~ s/\+/\_/;              
   }else { $cflim=6400; }
   
   $gv->MOSSpectra_cflim($cflim);

   if ( @save = grep /^caldb=/ , @ARGV) {
       $caldb="$save[-1]";
       $caldb =~ s/^.*=//; 
       $caldb =~ s/\+/\_/;              
   }else { $caldb=""; }
   
   $gv->MOSSpectra_caldb($caldb);
      
}

## @file
# Initialize analysis parameters

#========================================================================
sub pnspectra_parameters_init() {

	#.. Read Script Options
	my $name = "pnspectra";
	my $line = "@ARGV";
	my @save;

	if ( @save = grep /^\-p/, @ARGV ) {
		&pnspectra_usage();
	}

	if ( @save = grep /^-d/, @ARGV ) {
		system("sasdialog $name");
		my $x = $? >> 8;
		exit($x);
	}

	if ( @save = grep /^-v/, @ARGV ) {
		&getVersion();
	}

	#.. Default parameters (Start)
   if ( @save = grep /^prefix=/ , @ARGV) {
       $prefix="$save[-1]";
       $prefix =~ s/^.*=//; 
       $prefix =~ s/\+/\_/;              
   }else { $prefix="S001"; }
   
   $gv->PNSpectra_prefix($prefix);

   if ( @save = grep /^caldb=/ , @ARGV) {
       $caldb ="$save[-1]";
       $caldb =~ s/^.*=//; 
       $caldb =~ s/\+/\_/;              
   }else { $caldb="/CalDB"; }
   
   $gv->PNSpectra_caldb($caldb);

   if ( @save = grep /^region=/ , @ARGV) {
       $region="$save[-1]";
       $region =~ s/^.*=//; 
       $region =~ s/\+/\_/;              
   }else { $region="reg.txt"; }
   
   $gv->PNSpectra_region($region);

   if ( @save = grep /^mask=/ , @ARGV) {
       $mask="$save[-1]";
       $mask =~ s/^.*=//; 
       $mask =~ s/\+/\_/;              
   }else { $mask=0; }
   
   $gv->PNSpectra_mask($mask);
   
   if ( @save = grep /^elow=/ , @ARGV) {
       $elow="$save[-1]";
       $elow =~ s/^.*=//; 
       $elow =~ s/\+/\_/;              
   }else { $elow=0; }
   
   $gv->PNSpectra_elow($elow);

  if ( @save = grep /^ehigh=/ , @ARGV) {
       $ehigh="$save[-1]";
       $ehigh =~ s/^.*=//; 
       $ehigh =~ s/\+/\_/;              
   }else { $ehigh=0; }
   
   $gv->PNSpectra_ehigh($ehigh);

#   if ( @save = grep /^pattern=/ , @ARGV) {
#       $pattern="$save[-1]";
#       $pattern =~ s/^.*=//; 
#       $pattern =~ s/\+/\_/;              
#   }else { $pattern=4; }
#   
#   $gv->PNSpectra_pattern($pattern);
   
   if ( @save = grep /^quad1=/ , @ARGV) {
       $quad1="$save[-1]";
       $quad1 =~ s/^.*=//; 
       $quad1 =~ s/\+/\_/;              
   }else { $quad1=1; }
#   print "quad $quad1\n";

   $gv->PNSpectra_QUAD1($quad1);
   
   if ( @save = grep /^quad2=/ , @ARGV) {
       $quad2="$save[-1]";
       $quad2 =~ s/^.*=//; 
       $quad2 =~ s/\+/\_/;              
   }else { $quad2=1; }
   
   $gv->PNSpectra_QUAD2($quad2);
   
   if ( @save = grep /^quad3=/ , @ARGV) {
       $quad3="$save[-1]";
       $quad3 =~ s/^.*=//; 
       $quad3 =~ s/\+/\_/;              
   }else { $quad3=1; }
   
   $gv->PNSpectra_QUAD3($quad3);
   
   if ( @save = grep /^quad4=/ , @ARGV) {
       $quad4="$save[-1]";
       $quad4 =~ s/^.*=//; 
       $quad4 =~ s/\+/\_/;              
   }else { $quad4=1; }
   
   $gv->PNSpectra_QUAD4($quad4);
      
   if ( @save = grep /^caldb=/ , @ARGV) {
       $caldb="$save[-1]";
       $caldb =~ s/^.*=//; 
       $caldb =~ s/\+/\_/;              
   }else { $caldb=""; }
   
   $gv->PNSpectra_caldb($caldb);
      
}

# @file
# Initialize analysis parameters

#========================================================================
sub rotimdetsky_parameters_init() {

	#.. Read Script Options
	my $name = "rotimdetsky";
	my $line = "@ARGV";
	my @save;

	if ( @save = grep /^\-p/, @ARGV ) {
		&rotimdetsky_usage();
	}

	if ( @save = grep /^-d/, @ARGV ) {
		system("sasdialog $name");
		my $x = $? >> 8;
		exit($x);
	}

	if ( @save = grep /^-v/, @ARGV ) {
		&getVersion();
	}

	#.. Default parameters (Start)
   if ( @save = grep /^prefix=/ , @ARGV) {
       $prefix="$save[-1]";
       $prefix =~ s/^.*=//; 
       $prefix =~ s/\+/\_/;              
   }else { $prefix="1S001"; }
   
   $gv->ROTIM_prefix($prefix);

   if ( @save = grep /^elow=/ , @ARGV) {
       $elow="$save[-1]";
       $elow =~ s/^.*=//; 
       $elow =~ s/\+/\_/;              
   }else { $elow=2000; }
   
   $gv->ROTIM_elow($elow);

  if ( @save = grep /^ehigh=/ , @ARGV) {
       $ehigh="$save[-1]";
       $ehigh =~ s/^.*=//; 
       $ehigh =~ s/\+/\_/;              
   }else { $ehigh=8000; }
   
   $gv->ROTIM_ehigh($ehigh);

  if ( @save = grep /^mode=/ , @ARGV) {
       $mode="$save[-1]";
       $mode =~ s/^.*=//; 
       $mode =~ s/\+/\_/;              
   }else { $mode=0; }
   
   $gv->ROTIM_mode($mode);

  if ( @save = grep /^mask=/ , @ARGV) {
       $mask="$save[-1]";
       $mask =~ s/^.*=//; 
       $mask =~ s/\+/\_/;              
   }else { $mask="none"; }
   
   $gv->ROTIM_mask($mask);

   if ( @save = grep /^clobber=/ , @ARGV) {
       $clobber="$save[-1]";
       $clobber =~ s/^.*=//; 
       $clobber =~ s/\+/\_/;              
    }else { $clobber=1;}

   $gv->ROTIM_clobber($clobber);
     
}

## @method void usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub rotimdetsky_usage() {
    print "\nrot-im-det-sky [-h] \n\n";
    print "This perl script recasts model particle background or soft proton \n";
    print "images from detector coordinates to sky coordinates.\n\n";
    print "Inputs\n\n";
    print "    prefix: the detector/exposure ID (e.g., 1S001)\n";
    print "    verb: SAS verbosity parameter\n";
    print "    elow: band low energy limit\n";
    print "    ehigh: band high energy limit\n";
    print "    mode: 1 => particle background\n";
    print "          2 => soft proton background\n";
    print "    mask: if desired, image file name for additional masking \n\n";
    print "Example:\n";
    print "      rot-im-det-sky prefix=1S001 elow=400 ehigh=1250 mode=1 \n\n";
    system("listparams rotimdetsky");
    my $x = $? >> 8;
    &do_exit(0)
}


## @method void usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub mosspectra_usage() {
    print "\nmos-spectra [-h] \n\n";
    print "This perl script extracts the intermediate files used to \n";
    print "create the QPB spectra and images for extended source \n";
    print "analysis of XMM MOS data.\n\n";
    print "Inputs\n";
    print "    prefix: the detector/exposure ID (e.g., 1S001)\n";
    print "    caldb: the location of the FWC event files\n";
    print "    region: a file with additional region information\n";
    print "    mask:     0 => no source masking \n";
    print "              1 => mask using the combined band source list of cheese or cheese \n";
    print "              2 => mask using the soft band source list of cheese \n";
    print "              3 => mask using the hard band source list of cheese \n";
    print "    elow: band low energy limit\n";
    print "    ehigh: band high energy limit\n";
    print "    ccd#: CCD control, 1 to include, 0 to ignore\n\n";
    print "Example:\n";
    print "mos-spectra prefix=1S001 caldb=/CalDB region=mos1-reg.txt elow=400 \n";
    print "      ehigh=1250 ccd1=1 ccd2=1 ccd3=1 ccd4=1 ccd5=1 ccd6=0 ccd7=1 \n\n";
    system("listparams mosspectra");
    my $x = $? >> 8;
    &do_exit(0)
}

## @method void usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub pnspectra_usage() {
    print "\npn-spectra [-h] \n\n";
    print "This perl script extracts the intermediate files used to \n";
    print "create the QPB spectra and images for extended source \n";
    print "analysis of XMM PN data.\n\n";
    print "Inputs\n";
    print "    prefix: the detector/exposure ID (e.g., 1S001)\n";
    print "    caldb: the location of the FWC event files\n";
    print "    region: a file with additional region information\n";
    print "    mask: 0 => no source masking \n";
    print "              1 => mask using the combined band source list of  \n";
    print "                   cheese or cheese \n";
    print "              2 => mask using the soft band source list of cheese \n";
    print "              3 => mask using the hard band source list of cheese \n";
    print "    elow: band low energy limit\n";
    print "    ehigh: band high energy limit\n";
#    print "    pattern: maximum PATTERN to use \n";
    print "    quad#: quad control, 1 to include, 0 to ignore\n\n";
    print "Example:\n";
    print "pn-spectra prefix=S003 caldb=/CalDB verb=1 region=pn-reg.txt mask=1 \n";
    print "     elow=400 ehigh=1250 quad1=1 quad1=2 quad3=1 quad4=1 \n\n";
#    print "pn-spectra prefix=S003 caldb=/CalDB verb=1 region=pn-reg.txt mask=1 \n";
#    print "     elow=400 ehigh=1250 pattern=4 quad1=1 quad1=2 quad3=1 quad4=1 \n\n";
    system("listparams pnspectra");
    my $x = $? >> 8;
    &do_exit(0)
}

## @method void usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub cheese_usage() {

	#..Print Help message
    print "\ncheese [-h] \n\n";
    print "This perl script allows the source detection and mask production to be done \n";
    print "    in one or two bands, typically soft and hard in the two band case.\n\n";
    print "Inputs \n";
    print "    prefixm: list of the MOS detector exposure IDs (e.g., 1S001 2S002) \n";
    print "    prefixp: list of the PN detector exposure IDs (e.g., S003) \n";
    print "    verb: SAS verbosity \n";
    print "    scale: the energy fraction for the exclusion of point \n";
    print "         sources (e.g., 0.9) which sets the exclusion radius \n";
    print "    rate: the flux threshold (in units of 1.0e-14 cgs) for \n";
    print "         the exclusion of point sources in the total (combined) band (e.g., 0.5) \n";
    print "    rates: the flux threshold (in units of 1.0e-14 cgs) for \n";
    print "         the exclusion of point sources in the soft band (e.g., 0.5) \n";
    print "    rateh: the flux threshold (in units of 1.0e-14 cgs) for \n";
    print "         the exclusion of point sources in the hard band (e.g., 0.5) \n";
    print "    dist: min separation in arc seconds between masked sources \n";
    print "    mlmin: min maxlike detection level \n";
    print "    clobber: 1 to overwrite files \n";
    print "    elow: list of band low energy limits (e.g., 400 2000) \n";
    print "    ehigh: list of band high energy limits (e.g., 1250 7200) \n";
    print "  \n";
    print " cheese prefixm='1S001 2S002' prefixp=S003 verb=0 scale=0.5 \n";
    print "      dist=40.0 mlmin=20.0 clobber=1 elow=400 ehigh=1300 \n";
    print " cheese prefixm='1S001 2S002' prefixp=S003 verb=0 scale=0.9 rate=1.0 \n";
    print "      rates=1.0 rateh=1.0 dist=40.0 mlmin=15.0 clobber=1 \n";
    print "      elow='400 2000' ehigh='1250 8000' \n";
    system("listparams cheese");
    my $x = $? >> 8;
    &do_exit(0)
}

## @method void getVersion()
# Get the version number
# @return Void

#========================================================================
sub getVersion() {
	my $ccom = "";
	chomp( my $sasdir = `which cheese` );
	my $ii = index( $sasdir, '/bin/cheese' );
	if ( $ii == -1 ) {
		print "Sorry, directory structure of cheese $sasdir "
		  . "could not be recognised.\n";
	}
	else {
		$sasdir = substr( $sasdir, 0, $ii );

		# Optimize to avoid searching whole directory if standard structure
		$ccom = "packages/cheese/VERSION";
		if ( !-e $sasdir . "/" . $ccom ) {
			$ccom = `cd $sasdir; find . -name VERSION | grep cheese`;
		}
		if ( length($ccom) == 0 ) {
			print "Sorry, cheese's version number was not found in $sasdir.\n"
			  . "Please look in the package documentation.\n";
		}
		else {
			chomp( my $version = `cd $sasdir; cat $ccom` );
			$ccom = $sasdir . "/RELEASE";
			my $release = "";
			if ( -e $ccom ) { chomp( $release = `cat $ccom` ) }
			print "cheese $version [$release] \n";
		}
	}

}
## @method void error_code($error_signal)
# Definition of error codes
# @param error_signal Error Code
# @return Void

#========================================================================
sub error_code(){
#.. Define the actions to take according to Error Code

    my $error_signal = $_[0];

    my %error_code= (
		     '0' => "   \#> Success",
		     '100' => "   \#> Error: Parameter error",
		     '255' => "   \#> Error: Running Cheese",
		     );     

   if (defined $error_code{$error_signal}) {
	my $msg = $error_code{$error_signal};
	print "$msg\n";
	if ($error_signal != 0) {&do_exit($error_signal);}
    } else {
	my $msg = "   \#> Error option not recognized.\n";
	print "$msg\n";
	&error_code(255);
    } 

    return(0);
}

#========================================================================

## @method void do_exit($exit_code)
# Exit analysis program
# @param exit_code Exit code to be output on exit
# @return Void

#========================================================================    
sub do_exit(){        	

#.. Define exit code

    my $exit_code = $_[0];

    exit $exit_code;
    return(0);
}

	
1;
