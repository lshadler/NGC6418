## @file
# Run the SAS task edetect_chain on EPIC event files

## @method void run_edetectchain()
# Runs the SAS task edetect_chain and cross-correlates the user source position with the EPIC source list.
# @return Void

#======================================================================== 
sub run_edetectchain(){
 
	$logger->info( "\n----> Running edetect_chain ..... "); 

#.. Test for ccf file and set ENV variable
	@test_ccf=&test_ccf();
	my $ccffile=$test_ccf[1];
	if (!$test_ccf[0]) {$logger->warn( "Running edetechain...  Run cifbuild first "); &error_code(5);}
	&set_ccf($ccffile);
	
#.. Test for odfingest file and set ENV variable     
	@test_odfingest=&test_odfingest();
	my $odfingestfile=$test_odfingest[1];
	if (!$test_odfingest[0]) {$logger->info( "Running edetechain...  Run odfingest first"); &error_code(5);}
	&set_odfingest($odfingestfile);
	    
#.. Print sas_setup    
	&print_sas_setup();

#.. Define Global Variables
    $logger->info( "   \#> Defining File Names for edetect chain ..... ");
 
    use vars qw(
    	$epic_event_list
		$epic_edetect_flag
		$epic_GTI_file

		$epic_fullimage 
		$epic_emllist_file
		$epic_eboxllist_file 
		$epic_eboxmlist_file
		$source_epicregion_file	       
		);

#.. Cross match variables
	my %pnMap = ();
	my %m1Map = ();
	my %m2Map = ();
#.. Get event files
   	my @files = &get_EPIC_eventfiles();
	
 	my %epicFileMap = get_EPIC_Exposures(@files);
	my $inst;
	my $exposure;
	my $mode;
   	if ( $#files == 0 ) {&error_code(4);} 
	
	my $source_ra = "";
	my $source_dec = "";
	$epic_edetect_flag = 0; # Flag that determines whether the spectra should be worked out (1: True)
	foreach my $file (@files) 
	{

		($inst,$exposure,$mode) = &get_File_Info($file );
		$currentExposure = &getExpoInfo($inst,$exposure,$mode);
		$p = $currentExposure->getProduct("edetectchain");
		
		my $instrument = "";
		if ($inst eq "EPN") {		 
			$instrument = "pn";
		} elsif ($inst eq "EMOS1") {
			$instrument = "m1";
		} elsif ($inst eq "EMOS2") {
			$instrument = "m2";
		}
		$logger->info( "\n----> Running edetect_chain: $file [$inst,$exposure,$mode] ..... ");
		
	    
	
		# Check if the user select MOS1, MOS2, PN for analysing data
		if ($odf_object->$inst eq "no") 
		{ 
			$logger->info(
				"INSTRUMENT $inst [exposure=$exposure]: Not selected for running edetect_chain");
			$logger->info( "Skipping to the next exposure...");
		}
	  	#.. Check if the current exposure has been selected to be processed
	  	elsif ( lc($currentExposure->getProcess()) eq "no" || 
	  	  	    lc($currentExposure->getProduct("edetectchain")->getProcess()) eq "no" ) 
	  	{
	  		$logger->info(
			"EXPOSURE $exposure [intrument=$inst]: Not selected for running edetect_chain");
			$logger->info( "Skipping to the next exposure...");
		}		
		else
		{
		  $scienceLog->info( "\n   \#> edectectchain science output  [$inst,$exposure,$mode]");
		  $epic_edetect_flag = 1;
		  if ($mode =~ m/Imaging/)
		  {			  			  	
			#.. Check if the user has defined its own coordinates
			&setcoordinates();	
			
		    my $source_obsID = $odf_object->getObsId;
		    my $source_name  = $odf_object->getSourceName;
		    $source_ra    = $odf_object->getRA;
		    $source_dec   = $odf_object->getDEC;
		
		
		#.. Definition of file names
			create_pnProductFileNames( $instrument, $exposure, $mode );		    
		    	
		#.. Energy Ranges and detection likelihoods for PN and MOS
#old			my $currentEnerLow ="EDC_".$instrument."_ene_low";
#old			my $currentEnerHigh ="EDC_".$instrument."_ene_high";		
		    $temp  =  $p->getTask("xmmextractor","image_creation")->getParam("energylow")->getValue();
		    @epic_ene_low = split(',',$temp);
		    $temp = $p->getTask("xmmextractor","image_creation")->getParam("energyhigh")->getValue(); 
		    @epic_ene_high = split(',',$temp);
		    #.. Get the ECFs from XML input file
		    $temp  =  $p->getTask("xmmextractor","image_creation")->getParam("ecf")->getValue();
		    @epic_ecf = split(',',$temp);


		 	my $currentInst = "pn";
		 	if (($instrument eq "m1") || ($instrument eq "m2")) {
	    		$currentInst = "mos";
	    	}	    			
			
		    @epicGTI=&test_epic_gtifile($instrument,$exposure,$mode);
		    if ($epicGTI[0]){
				@epicinfoGTI=&gti_file_inf($epic_GTI_file,$instrument);
				if ($epicinfoGTI[0] != 0.0){$epic_GTI_file=$epicGTI[1];} else {$epic_edetect_flag = 0;}
		    } else {$epic_edetect_flag = 0;}   			
		    
		
		    @test_epicevt=&test_epiceventfiles($inst,$exposure,$mode);
		    $epic_event_list=$test_epicevt[1]; 
		    if ($test_epicevt[0]) {$epic_event_list=$test_epicevt[1];} else {$epic_edetect_flag = 0;}		   
		    if ($epic_edetect_flag eq 1) {@epicinfo=&event_file_inf($epic_event_list,$instrument,$edectLog);}
		 	
		
		#.. Get instrument's observing mode and prepare things according to shape of source and background regions.  
		    $epic_obsmode = $obsid_instruments{$source_obsID}{$instrument}{'mode'};
	
		    
		#.. Create EPIC GTI filtered event lists.
		
		    if ($epic_edetect_flag ) 
		    {
		    	&produce_gticleanfile($epic_event_list,$epic_gti_cleanevents_file,$epic_GTI_file,
		    		$epic_obsmode,$instrument,$currentExposure->getProduct("GTIFiltering"));
		    }   
		
		#.. Prepare edetect chain log file    
		    chdir($images_directory);
		

		#.. Test if I have to run edetect chain or simply produce images.    
		    
		    $logger->info( "\n----> Checking if edetect_chain needs to be run .....");

		    if (!-e $epic_fullimage && $epic_edetect_flag eq 1) {&epic_create_energy_bands($instrument,$exposure,$mode);}	    	  
		    if (!-e $epic_emllist_file && $epic_edetect_flag eq 1) {&epic_edetect_chain($instrument,$exposure,$mode,$p);}
	
		#..
		#.. Produce Images 
		#..
		    $logger->info( "\n----> Producing Instruments Images ..... ");
		    
		#.. For EPIC
		    @epic_closesource = (0.,0.,1000.);
		    	
		    if ($epic_edetect_flag eq 1)
		    {	     		    		
				if ($epicinfo[2] eq "IMAGING") 
				{			 	
			    	if (-e $epic_emllist_file) {   
			    		#.. Has our the source been detected in EPIC ?
						@epic_closesource=&epic_image($instrument,$exposure,$mode);
						
						if ($instrument eq "pn")
						{					
							push( @{$pnMap{$exposure}},@epic_closesource );		
						}
						if ($instrument eq "m1")
						{
							push (@{$m1Map{$exposure}}, @epic_closesource);
						}
						if ($instrument eq "m2")
						{
							push (@{$m2Map{$exposure}}, @epic_closesource);
						}
	
						if ($epic_closesource[2] <= $p->getTask("xmmextractor","image_creation")->getParam("sourcematch")->getValue()){$epic_edetect_flag = 1;}else{$epic_edetect_flag = 0;}   
			    	} else {
						$logger->info( "   \#> No Sources detected in $instrument within ",join(", ", $p->getTask("xmmextractor","image_creation")->getParam("sourcematch")->getValue())," deg");
						$epic_edetect_flag = 0;
			    	}
				} else 
				{
			    	$logger->warn( "   \#> Data is not IMAGING mode. Ignoring $instrument ");
			    	$epic_edetect_flag = 0;
				}
		    } else 
		    {
				$logger->warn( "   \#> No Sources detected in $instrument");
				$epic_edetect_flag = 0;
		    }		
		
		#.. Get count rate information if source has been detected
		
		    if (-e $epic_emllist_file && $epic_edetect_flag eq 1) 
			    {@epicsrcrate=&get_source_count_rate($epic_emllist_file,$instrument,0,$epic_closesource[0],$epic_closesource[1]);} 
		    if (-e $epic_emllist_file && $epic_edetect_flag eq 1) 
			    {@pnbkgrate=&get_bkg_count_rate($epic_emllist_file,$instrument,$epic_closesource[0],$epic_closesource[1]);} 
		
		#.. Get Source count rate information if source has been detected in different energy bands
		    $logger->info( "    \#> Sending Count Rate Information to edetectLog and scienceLog...:");
		    $edectLog->info( "\n   \#> Count Rate Information: [$inst,$exposure,$mode]");
		    $scienceLog->info( "\n   \#> Count Rate Information: [$inst,$exposure,$mode]");
		    		
		    if (-e $epic_emllist_file && $epic_edetect_flag eq 1){
			@epicsrcrate_E1=&get_source_count_rate($epic_emllist_file,$instrument,1,$epic_closesource[0],$epic_closesource[1]);
			@epicsrcrate_E2=&get_source_count_rate($epic_emllist_file,$instrument,2,$epic_closesource[0],$epic_closesource[1]);
			@epicsrcrate_E3=&get_source_count_rate($epic_emllist_file,$instrument,3,$epic_closesource[0],$epic_closesource[1]);
			@epicsrcrate_E4=&get_source_count_rate($epic_emllist_file,$instrument,4,$epic_closesource[0],$epic_closesource[1]);
			@epicsrcrate_E5=&get_source_count_rate($epic_emllist_file,$instrument,5,$epic_closesource[0],$epic_closesource[1]);
		    } 
		
		#.. Output rate information onto different log files  
		    $edectLog->info( "       Source IDs (from emllist.fits table):");
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "        $instrument SRC ID  : $epicsrcrate[0] ");} else {$edectLog->info( "        No positive $instrument identification");}
	
		    $edectLog->info( "       CCD IDs (from emllist.fits table): ");
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "        $instrument CCD ID  : $epicsrcrate[3] ");} else {$edectLog->info( "        No positive $instrument identification");}
		    $edectLog->info( "       Source and BKG Count Rates in entire energy range considered: ");
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "        $instrument  : ");} else {$edectLog->info( "        No positive $instrument identification");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate[1] +/- $epicsrcrate[2] ");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          BKG Rate (cts/s): $pnbkgrate[1] +/- $pnbkgrate[2] ");}
	
		    $edectLog->info( "       Source Count Rates in different energy ranges considered: ");
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "        $instrument  : ");} else {$edectLog->info( "        No positive $instrument identification");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate_E1[1] +/- $epicsrcrate_E1[2] ($epic_ene_low[0] - $epic_ene_high[0]) ");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate_E2[1] +/- $epicsrcrate_E2[2] ($epic_ene_low[1] - $epic_ene_high[1]) ");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate_E3[1] +/- $epicsrcrate_E3[2] ($epic_ene_low[2] - $epic_ene_high[2]) ");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate_E4[1] +/- $epicsrcrate_E4[2] ($epic_ene_low[3] - $epic_ene_high[3]) ");}
		    if ($epic_edetect_flag eq 1) {$edectLog->info( "          SRC Rate (cts/s): $epicsrcrate_E5[1] +/- $epicsrcrate_E5[2] ($epic_ene_low[4] - $epic_ene_high[4]) ");}
	
			$scienceLog->info("       Source IDs (from emllist.fits table): ");
			if ($epic_edetect_flag eq 1) {$scienceLog->info("        $instrument SRC ID  : $epicsrcrate[0] ");}
			
			$scienceLog->info("       CCD IDs (from emllist.fits table): ");
			if ($epic_edetect_flag eq 1) {$scienceLog->info("        $instrument CCD ID   : $epicsrcrate[3] ");}
			
			$scienceLog->info("       Source and BKG Count Rates in entire energy range considered: ");
			if ($epic_edetect_flag eq 1) {$scienceLog->info("        $instrument  : ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          $instrument SRC Rate (cts/s): $epicsrcrate[1] +/- $epicsrcrate[2] ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          $instrument BKG Rate (cts/s): $pnbkgrate[1] +/- $pnbkgrate[2] ");}
			$scienceLog->info("       Source Count Rates in different energy ranges considered: ");
			if ($epic_edetect_flag eq 1) {$scienceLog->info("        $instrument  : ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          SRC Rate (cts/s): $epicsrcrate_E1[1] +/- $epicsrcrate_E1[2] ($epic_ene_low[0] - $epic_ene_high[0]) ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          SRC Rate (cts/s): $epicsrcrate_E2[1] +/- $epicsrcrate_E2[2] ($epic_ene_low[1] - $epic_ene_high[1]) ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          SRC Rate (cts/s): $epicsrcrate_E3[1] +/- $epicsrcrate_E3[2] ($epic_ene_low[2] - $epic_ene_high[2]) ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          SRC Rate (cts/s): $epicsrcrate_E4[1] +/- $epicsrcrate_E4[2] ($epic_ene_low[3] - $epic_ene_high[3]) ");}
			if ($epic_edetect_flag eq 1) {$scienceLog->info("          SRC Rate (cts/s): $epicsrcrate_E5[1] +/- $epicsrcrate_E5[2] ($epic_ene_low[4] - $epic_ene_high[4]) ");}
			
			$logger->info( "\n   \#> edetect_chain finished: [$inst,$exposure,$mode]");		    
		  } # Only Imaging events
		  else
		  {
		  	$logger->info("EXPOSURE $exposure [intrument=$inst] is Timing: Not selected for running edetect_chain");
			$logger->info( "Skipping to the next exposure...");
			$edectLog->info("EXPOSURE $exposure [intrument=$inst] is Timing: Not selected for running edetect_chain");
			$edectLog->info( "Skipping to the next exposure...");
		  }
		}
		$scienceLog->info( "\n   \#> edectectchain science output finished  [$inst,$exposure,$mode]");
	}# Loop over all event files...
	
	#.. Is the source detected in the different instruments the same ?	
  
    if ( (keys( %$pnMap ) != 0) &&  (keys( %$m1Map )) != 0 && (keys( %$m2Map ) != 0) ) {
    	
		crossDetection(\%pnMap,\%m1Map,\%m2Map,\$source_ra,\$source_dec);
	}
    

	$logger->info( "\n----> edetect_chain finished..... ");
	
    if ($epic_edetect_flag eq 0 ) {    	
    	return(1);
    } else{
    	&error_code(0); 
    	return(0);
    } 
}

## end of run_edetectchain

## @method void crossDetection()
# Check if the source has been detected in the different instruments.
#
# @return void

#====================================================================== 
sub crossDetection()
{
	
	#.. Is the source detected in the different instruments the same ?
 	my($pnMap,$m1Map,$m2Map,$source_ra,$source_dec)=@_;
	
    my $pnmos1det     = "NO";
    my $pnmos1_dist   = 1000.;
    my $pnmos2det     = "NO";
    my $pnmos2_dist   = 1000.;
    my $mos1mos2det   = "NO";
    my $mos1mos2_dist   = 1000.;
	my $pn_edetect_flag = "0";
	my $m1_edetect_flag = "0";
	my $m2_edetect_flag = "0";

	my @pn_closesource = (0.0,0.0,"??");
	my @m1_closesource = (0.0,0.0,"??");
	my @m2_closesource = (0.0,0.0,"??");
	
	my $pn_exposure ="";
	my $m1_exposure ="";
	my $m2_exposure ="";
	
	if ( (keys( %$pnMap ) != 0) )  {
		foreach $var ( keys %$pnMap) {
			$pn_exposure = $var;		
			@pn_closesource = @{$$pnMap{$pn_exposure}};		
		}
	}	
	
	if ( (keys( %$m1Map ) != 0) ) {
		foreach $var ( keys %$m1Map) {
			$m1_exposure = $var;		
			@m1_closesource = @{$$m1Map{$m1_exposure}};	
		}
	}
	
	if ( (keys( %$m2Map ) != 0) ) {
		foreach $var ( keys %$m2Map) {
			$m2_exposure = $var;
			@m2_closesource = @{$$m2Map{$m2_exposure}};
		}
	}
   	
   	#.. initial value

	if ( (keys( %$pnMap ) != 0)  && (keys( %$m1Map ) != 0) ){			
		$pnmos1_dist = &Angular_separation($pn_closesource[0],$m1_closesource[0],$pn_closesource[1],$m1_closesource[1]);
 			if ($pnmos1_dist <= $p->getTask("xmmextractor","image_creation")->getParam("cameramatch")->getValue()) {$pnmos1det = "YES";}
	} 
    
    if ( (keys( %$pnMap ) != 0)  && (keys( %$m2Map ) != 0) ){	
		$pnmos2_dist = &Angular_separation($pn_closesource[0],$m2_closesource[0],$pn_closesource[1],$m2_closesource[1]);
		if ($pnmos2_dist <= $p->getTask("xmmextractor","image_creation")->getParam("cameramatch")->getValue()) {$pnmos2det = "YES";}

    } 
    
    if ( (keys( %$m1Map ) != 0)  && (keys( %$m1Map ) != 0) ){
		$mos1mos2_dist = &Angular_separation($m1_closesource[0],$m2_closesource[0],$m1_closesource[1],$m2_closesource[1]);		
		if ($mos1mos2_dist <= $p->getTask("xmmextractor","image_creation")->getParam("cameramatch")->getValue()) {$mos1mos2det = "YES";}				

    }
    
    
	    $logger->info( "\n   \#> Sending Cross Correlation Information for EPIC to edetectLog...:");

	    $edectLog->info("\n   \#> Cross Correlation Information for EPIC: PN[$pn_exposure] EMOS1[$m1_exposure] EMOS2[$m2_exposure] ");
		$edectLog->info("       SOURCE           PN               MOS1             MOS2  ");
		$edectLog->info("  RA       DEC     RA       DEC      RA       DEC    RA        DEC ");
		$edectLog->info(" $$source_ra $$source_dec $pn_closesource[0] $pn_closesource[1] $m1_closesource[0] $m1_closesource[1] $m2_closesource[0] $m2_closesource[1] ");
		$edectLog->info("  Distance to closest source in each instrument: ");
		$edectLog->info("  (If RA,DEC of the source is within ", join(", ", $p->getTask("xmmextractor","image_creation")->getParam("cameramatch")->getValue())," deg of RA,DEC of detected ");
		$edectLog->info("  camera source, it is assumed the source is the same) ");
		$edectLog->info("    SOURCE-PN : $pn_closesource[2] deg. Same source ?: $pn_edetect_flag ");
		$edectLog->info("    SOURCE-M1 : $m1_closesource[2] deg. Same source ?: $m1_edetect_flag ");
		$edectLog->info("    SOURCE-M2 : $m2_closesource[2] deg. Same source ?: $m2_edetect_flag ");
		$edectLog->info("  Comparing Source detection on different cameras: ");
		$edectLog->info("  (If RA,DEC of one camera is within ", join(", ", $p->getTask("xmmextractor","image_creation")->getParam("cameramatch")->getValue())," deg of RA,DEC of another camera ");
		$edectLog->info("  it is assumed the source in both cameras is the same) ");
		$edectLog->info("    Distance PN-MOS1    : $pnmos1_dist deg. Same source ?: $pnmos1det ");
		$edectLog->info("    Distance PN-MOS2    : $pnmos2_dist deg. Same source ?: $pnmos2det ");
		$edectLog->info("    Distance MOS1-MOS2  : $mos1mos2_dist deg. Same source ?: $mos1mos2det ");
    	
    	$logger->info( "\n   \#> Done:");


}

## @method void epic_create_energy_bands($instrument,$exposure,$mode)
# Produce EPIC images in 5 user define energy bands.
# @param $instrument
# @param $exposure
# @param $mode
# @return Void

#========================================================================
sub epic_create_energy_bands(){
    my $instrument = $_[0];
    my $exposure = $_[1];
    my $mode = $_[2];

    $logger->info( "   \#> $instrument: ");
    $logger->info( "      Events File Used: $epic_gti_cleanevents_file");
    $logger->info( "      GTI File Used   : $epic_GTI_file ");


    my $number_of_bands = $#epic_ene_low;
    my $xbinsize        = 80;
    my $ybinsize        = 80;

    chdir($images_directory);

    $logger->info( "      Energy Band: $epic_ene_low[0] - $epic_ene_high[$number_of_bands] ");

    @args = ("evselect"
	     ,"table=$epic_gti_cleanevents_file:EVENTS"
	     ,"imagebinning=binSize"
	     ,"imageset=$epic_fullimage"
	     ,"withimageset=yes"
	     ,"xcolumn=X","ycolumn=Y"
	     ,"ximagebinsize=$xbinsize","yimagebinsize=$ybinsize"
	     ,"expression=(PI in \[$epic_ene_low[0]:$epic_ene_high[$number_of_bands]\])");
    system(@args)== 0 or &error_code(5);
    
    my $ene_band = 0;
    while ($ene_band <= $number_of_bands){
	
		$logger->info( "      Energy Band($ene_band) : $epic_ene_low[$ene_band] - $epic_ene_high[$ene_band] ");
		
		my $image = $instrument."_".$exposure."_".$mode."_image_b".$ene_band.".fits";
	
		@args = ("evselect"
		 ,"table=$epic_gti_cleanevents_file:EVENTS"
		 ,"imagebinning=binSize"
		 ,"imageset=$image"
		 ,"withimageset=yes"
		 ,"xcolumn=X","ycolumn=Y"
		 ,"ximagebinsize=$xbinsize","yimagebinsize=$ybinsize"
		 ,"expression=(PI in \[$epic_ene_low[$ene_band]:$epic_ene_high[$ene_band]\])");
		system(@args)== 0 or &error_code(5);	
		$ene_band++;
		

    }
    
    return (0);
}

## @method void epic_edetect_chain()
# Runs the SAS task edetect_chain for EPIC
# @param $instrument
# @param $exposure
# @param $mode
# @param $prod
# @return Void

#========================================================================
sub epic_edetect_chain(){
    my $instrument = $_[0];
    my $exposure = $_[1];
    my $mode = $_[2];
    my $prod = $_[3];
    
    my $inst= $instrument;
    if (($instrument eq "m1") || ($instrument eq "m2")) {
    	$inst = "mos";
    }
    my $currentInstDir = $inst."_directory";

    chdir($$currentInstDir);
	
    my @epicAttitudelist = glob('*AttHk.ds');
    if ($#epicAttitudelist < 0) {&error_code(5);}
    my $epicAttitudefile = $$currentInstDir.$epicAttitudelist[0]; 

    my @filter=&event_file_inf($epic_gti_cleanevents_file,$instrument,$edectLog);
    my $epic_filter=$filter[1];

    chdir($images_directory);
    
    ### New implementation to get the ECFs from odfParamCreator.
    ##my @epic_ecf      = &epic_ecfvalues($epic_filter,$instrument);
    my $number_of_bands = $#epic_ene_low; 
    
    $logger->info( "\n   \#> Running edetect chain for $instrument .... ");
 
   #.. Reading input parameters... and passing them to the SAS task call
    my $myParams = $prod->getTask("edetect_chain","src_detection")->getParams();    
	my $params = " ";
	my $parValue=0;
	for my $key ( keys %$myParams ) {
			$params = $params." $key=".$myParams->{$key}->getValue();   									
	}
 
    my $img0=$images_directory.$instrument."_".$exposure."_".$mode."_image_b0\.fits";
    my $img1=$images_directory.$instrument."_".$exposure."_".$mode."_image_b1\.fits";
    my $img2=$images_directory.$instrument."_".$exposure."_".$mode."_image_b2\.fits";
    my $img3=$images_directory.$instrument."_".$exposure."_".$mode."_image_b3\.fits";
    my $img4=$images_directory.$instrument."_".$exposure."_".$mode."_image_b4\.fits";
    @args = ("edetect_chain","imagesets=$img0 $img1 $img2 $img3 $img4" 
	     ,"eventsets=$epic_gti_cleanevents_file"
	     ,"attitudeset=$epicAttitudefile" 
	     ,"pimin=$epic_ene_low[0] $epic_ene_low[1] $epic_ene_low[2] $epic_ene_low[3] $epic_ene_low[4]"
	     ,"pimax=$epic_ene_high[0] $epic_ene_high[1] $epic_ene_high[2] $epic_ene_high[3] $epic_ene_high[4]" 
	     ,"ecf=$epic_ecf[0] $epic_ecf[1] $epic_ecf[2] $epic_ecf[3] $epic_ecf[4]" 
	     ,"eboxl_list=$epic_eboxllist_file"
	     ,"eboxm_list=$epic_eboxmlist_file" 
	     ,"esp_nsplinenodes=16"
	     ,"eml_list=$epic_emllist_file"
   		 ,"$params"	     
	     ,"eml_fitextent=\"yes\"");
    system(@args)== 0 or &error_code(5);

    $logger->info( "      $instrument ECF Values  : ");
    foreach (@epic_ecf) {$logger->info( "$_ ");};
			 
    return(0);
}


## @method epic_image()
# Produce an EPIC Image and region file from Source List. Produces an EPIC Image with regions from region file overlaid.
# @param instrument
# @param exposure
# @param mode
# @return RA (deg) and DEC (deg) of closest EPIC-pn detected source to the source of interes. Angular distance (deg) between EPIC-pn and source of interest.

#========================================================================
sub epic_image(){
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $mode = $_[2];
	
    chdir ($images_directory);
     
    my $epicregion_file = $images_directory.$instrument."_".$exposure."_".$mode."region\.txt"; 
    my $source_ra     = $odf_object->getRA;
    my $source_dec    = $odf_object->getDEC;
    my $source_name   = $odf_object->getSourceName;

#.. Run the SAS commands srcdisplay to produce region file
	
    @args=("srcdisplay"
	   ,"boxlistset=$epic_emllist_file" 
	   ,"imageset=$epic_fullimage"
	   ,"sourceradius=0.01"
	   ,"withregionfile=yes"
	   ,"regionfile=$epicregion_file"); 
    system(@args);                         # == 0 or &error_code(5); NOTE: If I put this bit, it wont run on the grid

#.. Kill the ds9 opened by srcdisplay	
	system("kill -9 `ps waux | grep ds9 | grep Ds9- | awk '{print \$2}'`");

#.. From the list of detected sources in the region file find the closest source to yours
#.. and add your source to the region file to be plotted. 
    if (-e $epicregion_file){
		@epicclose_source=&find_closest_source($epicregion_file);
		&addsourcetoregionfile($epicregion_file,$epicclose_source[0],$epicclose_source[1],0.,0.008,"red","","circle","fk5");
		&addsourcetoregionfile($epicregion_file,$source_ra,$source_dec,0.,0.009,"green",$source_name,"circle","fk5");	
    } else {
		$logger->info( "   \#> $instrument Region file $epicregion_file does not exist ");	
		return(100.,100.,100.);
    }

    rename($epicregion_file,$source_epicregion_file);
    $logger->info( "   \#> $instrument Region file produced: $source_epicregion_file ");

#.. Run DS9. Arguments: image file, region file, title, output name
    &produce_ps_file($epic_fullimage,$source_epicregion_file,$instrument,$images_directory.$source_name."_".$instrument."_".$exposure."_".$mode."_image.ps");

    return($epicclose_source[0],$epicclose_source[1],$epicclose_source[2]);
}


## @method epic_ecfvalues($filter, $instrument)
# Definition of Energy Conversion Factors (ECF) for EPIC cameras
# @param filter EPIC Filter
# @param instrument
# @return Array with ECF for 5 user defined energy bins

#========================================================================
sub epic_ecfvalues(){

    my $filter = $_[0];
    my $instrument = $_[1];

    $logger->info( "    $instrument  Filter ECF Set: $filter ");
    $filter =~ s/\s+//;
    if ($instrument eq "pn")
    {
	if ($filter eq "Open") {return(15.711,7.5030,1.9837,0.9415,0.2399);} 
    	if ($filter eq "Thick") {return(4.990,5.315,1.847,0.927,0.2390);} 
    	if ($filter eq "Medium") {return(8.010,6.442,1.930,0.9394,0.2400);} 
    	if ($filter eq "Thin" or $filter eq "Thin1" or $filter eq "Thin2") {return(9.041,6.596,1.953,0.941,0.2401);}
    }
    if ($instrument eq "m1")
    {
    	if ($filter eq "Open") {return(3.0377,2.2011,0.75244,0.26492,0.02774);}
    	if ($filter eq "Thick") {return(0.984,1.622,0.7024,0.260,0.02760);} 
    	if ($filter eq "Medium") {return(1.564,1.983,0.7325,0.2639,0.02772);}
    	if ($filter eq "Thin" or $filter eq "Thin1" or $filter eq "Thin2") {return(1.756,1.980,0.741,0.2644,0.02773);}   	 
    }

    if ($instrument eq "m2")
    {
    	if ($filter eq "Open") {return(3.0618,2.1963,0.75597,0.27772,0.029915);} 
    	if ($filter eq "Thick") {return(0.994,1.620,0.7059,0.2727,0.02976);} 
    	if ($filter eq "Medium") {return(1.579,1.935,0.7361,0.2767,0.02988);} 
    	if ($filter eq "Thin" or $filter eq "Thin1" or $filter eq "Thin2") {return(1.772,1.977,0.7445,0.2771,0.0299);} 	 
    }

    return(1,1,1,1,1);
}


## @method find_closest_source($region_file)
# Given a Region File, find the closest source in the region file to the source of interest.
# @param region_file Name of Region File
# @return RA (deg), DEC (deg) Angular distance (deg) of closest detected source to the source of interest.

#========================================================================
sub find_closest_source(){

    my $source_ra=$odf_object->getRA;
    my $source_dec=$odf_object->getDEC;
    
    my $region_file = $_[0];

    my @ra_list;
    my @dec_list;
	
    if (-e $region_file) {
	
		open (REGIONFILE, $region_file); # or die "couldn't open file $region_file: $! \n";
		
		while (<REGIONFILE>) {
		    my $line = $_;
		    next if /^global/;  # skip comment lines
	    	next if /^[\#*]/;   # skip comment lines
	    	next if /^(\s)*$/;  # skip blank lines
	    	next if !/(color\=white)$/;  # use only lines that come from edetect_chain
	    	chomp($line);
	    	$line =~ s/fk5\;circle\(//;
	    	$line =~ s/\,0.01\) \# color\=white//;
	    	my($ra, $dec) = split(/\,/, $line);
	    	push @ra_list, $ra;
	    	push @dec_list, $dec;
		}
		close(REGIONFILE);
		$counter = 0;
		$mindist = 100.;
		
		foreach(@ra_list){			
	    	$angsep = &Angular_separation($ra_list[$counter],$source_ra,$dec_list[$counter],$source_dec);
	    	if ($angsep < $mindist){
				$mindist    = $angsep; 
				$mincounter = $counter;
	    	}
	    $counter ++;
		}
    } else {
		$mincounter            = 0;
		$ra_list[$mincounter]  = 0.;
		$dec_list[$mincounter] = 0.;
		$mindist = 1000.;
    }
  
    return($ra_list[$mincounter],$dec_list[$mincounter],$mindist);
}

## @method get_source_count_rate($src_file,$instr,$energyband,$ra,$dec)
# Get source count rate from the Source List
# @param src_file Source List
# @param instr Instrument
# @param energyband Energy Band of interest
# @param ra Source RA
# @param dec Source DEC
# @return Source ID in the Source List, Source Count Rate and Error, CCD Number where the source is.

#========================================================================
sub get_source_count_rate(){

    my $src_file    = $_[0];
    my $instr       = $_[1]; 
    my $energyband  = $_[2];
    my $ra          = $_[3];
    my $dec         = $_[4];

    my $RALOW       = $ra-0.0005;
    my $RAHIG       = $ra+0.0005;
    my $DELOW       = $dec-0.0005;
    my $DEHIG       = $dec+0.0005;
    my $temp_file   = $images_directory."temp";
    my $out_file    = $src_file.".temp";
    my $src_ml_id   = 0.;
    my $src_ccd_id  = 0.;
    my $tot_srcrate = 0.;
    my $tot_esrcrate= 0.;

    if ($instr eq "pn") {$Instrument_ID = 1;}
    if ($instr eq "m1") {$Instrument_ID = 2;}
    if ($instr eq "m2") {$Instrument_ID = 3;}

#.. Create a reduced list from the input table of detected instrument sources with the one closest to our source
    @args = ("fselect $src_file $out_file \"ID_BAND==$energyband&&ID_INST==$Instrument_ID&&RA>$RALOW&&RA<$RAHIG&&DEC>$DELOW&&DEC<$DEHIG\" clobber=yes");
    system(@args)== 0 or &error_code(5);

    chomp(my $source   = `fkeyprint infile=$out_file+1  keynam=NAXIS2 outfil=STDOUT exact=yes | grep NAXIS2 | tail -1 | cut -c12-30`);
    $source     =~ s/\s+//;
    $source     =~ s/\'+//;

    if ($source == 1){
	
	#.. Get Source ID from reduced list
		@args = ("fdump $out_file $temp_file \"ML_ID_SRC\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
		system(@args)== 0 or &error_code(5);
		chomp($src_ml_id = `cat $temp_file`);
		$src_ml_id =~ s/\s+//;
	
	#.. Get CCD ID in which source falls from reduced list
		@args = ("fdump $out_file $temp_file \"CCDNR\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
		system(@args)== 0 or &error_code(5);
		chomp($src_ccd_id = `cat $temp_file`);
		$src_ccd_id =~ s/\s+//;
	
	#.. Get Source Rate from reduced list
		@args = ("fdump $out_file $temp_file \"RATE\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
		system(@args)== 0 or &error_code(5);
		chomp($tot_srcrate = `cat $temp_file`);
		$tot_srcrate =~ s/\s+//;
		
	#.. Get Source Rate Error from reduced list
		@args = ("fdump $out_file $temp_file \"RATE_ERR\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
		system(@args)== 0 or &error_code(5);
		chomp($tot_esrcrate = `cat $temp_file`);
		$tot_esrcrate =~ s/\s+//;
	
	#.. Delete Temporary Files
		unlink("$temp_file") or die "Cannot rm file $temp_file: $!";
		unlink("$out_file") or die "Cannot rm file $out_file: $!";
		
    } else {
		$src_ml_id    = 10000.;
		$tot_srcrate  = 0.;
		$tot_esrcrate = 0.;
		if ($source > 1) {
	    	$logger->info( "      More than one source identified: $source "); 	    	    
		} elsif ($source == 0) {
	    	$logger->info( "      No Sources identified in $_[0] \n");
		}
    }
 
    return($src_ml_id,$tot_srcrate,$tot_esrcrate,$src_ccd_id);

}

## @method get_bkg_count_rate($src_file,$instr,$ra,$dec)
# Get background count rate from the Source List
# @param src_file Source List
# @param instr Instrument
# @param ra Source RA
# @param dec Source DEC
# @return Source ID in the Source List, Background Count Rate and Error.

#========================================================================
sub get_bkg_count_rate{
    
    my $src_file     = $_[0];
    my $instr        = $_[1];
    my $ra           = $_[2];
    my $dec          = $_[3];

    my $RALOW        = $ra-0.0005;
    my $RAHIG        = $ra+0.0005;
    my $DELOW        = $dec-0.0005;
    my $DEHIG        = $dec+0.0005;
    my $energyband   = 1;
    my $number_of_bands = 5;
    my $temp_file    = $images_directory."temp";
    my $out_file     = $src_file.".temp";
    my $src_ml_id    = 0.;
    my $tot_bkgrate  = 0.;
    my $tot_ebkgrate = 0.;
    my $BG_MAP       = 0.;
    my $EXP_MAP      = 1.;
    my $CUTRAD       = 0.;

    if ($instr eq "pn") {$Instrument_ID = 1;}
    if ($instr eq "m1") {$Instrument_ID = 2;}
    if ($instr eq "m2") {$Instrument_ID = 3;}

    while ($energyband <= $number_of_bands) {
#.. Create a reduced list from the input table of detected instrument sources with the one closest to our source
	@args = ("fselect $src_file $out_file \"ID_BAND==$energyband&&ID_INST==$Instrument_ID&&RA>$RALOW&&RA<$RAHIG&&DEC>$DELOW&&DEC<$DEHIG\" clobber=yes");
	system(@args)== 0 or &error_code(5);

	chomp(my $source   = `fkeyprint infile=$out_file+1 keynam=NAXIS2 outfil=STDOUT exact=yes | grep NAXIS2 | tail -1 | cut -c12-30`);
	$source     =~ s/\s+//;
	$source     =~ s/\'+//;

	if ($source == 1){

#.. Get Source ID from reduced list
	    @args = ("fdump $out_file $temp_file \"ML_ID_SRC\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
	    system(@args)== 0 or &error_code(5);
	    chomp($src_ml_id = `cat $temp_file`);
	    $src_ml_id =~ s/\s+//;
	    
#.. Get Source BG_MAP from reduced list
	    @args = ("fdump $out_file $temp_file \"BG_MAP\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
	    system(@args)== 0 or &error_code(5);
	    chomp($BG_MAP = `cat $temp_file`);
	    $BG_MAP =~ s/\s+//;
	    
#.. Get Source EXP_MAP from reduced list	
	    @args = ("fdump $out_file $temp_file \"EXP_MAP\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
	    system(@args)== 0 or &error_code(5);
	    chomp($EXP_MAP = `cat $temp_file`);
	    $EXP_MAP =~ s/\s+//;
	    
#.. Get Source CUTRAD from reduced list	
	    @args = ("fdump $out_file $temp_file \"CUTRAD\" - prhead=no showcol=no showunit=no showrow=no clobber=yes");
	    system(@args)== 0 or &error_code(5);
	    chomp($CUTRAD = `cat $temp_file`);
	    $CUTRAD =~ s/\s+//;
	    
#.. Workout bkg rate for a given energy band and accumulate 	
	    $logger->info( "   \#> Values used for Background count rate (Energy $energyband): ");
	    $logger->info( "      $_[1] Exposure map  : $EXP_MAP ");
	    $logger->info( "      $_[1] Background map: $BG_MAP ");
	    $logger->info( "      $_[1] Cut Radius    : $CUTRAD ");

	    if ($EXP_MAP != 0 || $EXP_MAP eq "" || $BG_MAP != 0 || $BG_MAP eq "" || $CUTRAD != 0 || $CUTRAD eq ""){ 
		$tot_bkgrate    = $tot_bkgrate+(($BG_MAP*(3.14159265*$CUTRAD**2))/$EXP_MAP);
		$tot_ebkgrate   = $tot_ebkgrate+($BG_MAP*((3.14159265*$CUTRAD**2)/$EXP_MAP)**2);
	    } else {
		$logger->info( "      Could not workout bakground rate. ");
		
		$tot_bkgrate  = 0;
		$tot_ebkgrate = 0;
	    }	
	    
#.. Delete Temporary Files
	    unlink("$temp_file") or die "Cannot rm file $temp_file: $!";
	    unlink("$out_file") or die "Cannot rm file $out_file: $!";
	    
	} else {
	    $src_ml_id    = 10000.;
	    $tot_bkgrate  = 0.;
	    $tot_ebkgrate = 0.;
	    if ($source > 1) {
		$logger->info( "      More than one source identified: $source "); 	    
		
	    } elsif ($source == 0) {
		$logger->info( "      No Sources identified in $_[0] ");
		
	    }
	}

	$energyband++;
	
    }
    
    $tot_ebkgrate   = sqrt($tot_ebkgrate);
    
    return($src_ml_id,$tot_bkgrate,$tot_ebkgrate);
}
1;



