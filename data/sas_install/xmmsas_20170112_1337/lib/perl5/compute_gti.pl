## @file
# Compute GTI the standard way

## @method void compute_gti()
# Compute GTI the standard way
# @return Void

#========================================================================
sub compute_gti(){

    $logger->info( "\n----> Working out GTI .....");

#.. Define Global Variables
    $logger->info( "   \#> Defining File Names for GTI ..... ");
    
    use vars qw(
		$epic_GTI_lightcurvefile 
		$epic_GTI_file 
		$PG_flagCall
		 );

#.. Parameters for GTI 
    
    my $source_obsID = $odf_object->getObsId;
    my $source_name  = $odf_object->getSourceName;
    
    $logger->info( "Done. ");

	$logger->info( "   \#> Testing existance of ccf.cif and SUM.SAS ..... ");
#.. Test for ccf file and set ENV variable
    @test_ccf=&test_ccf();
    my $ccffile=$test_ccf[1];
    if (!$test_ccf[0]) {&error_code(3);}
    &set_ccf($ccffile);

#.. Test for odfingest file and set ENV variable     
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];
    if (!$test_odfingest[0]) {&error_code(3);}
    &set_odfingest($odfingestfile);
    
#.. Print sas_setup    
    &print_sas_setup();

#.. Flag to check if compute_gti has been called by PG optimization (PG_flag = 1 (true))
#.. or it is the standard gti call


#.. Get event files
   my @files = &get_EPIC_eventfiles();
	
 	my %epicFileMap = get_EPIC_Exposures(@files);
	my $inst;
	my $exposure;
	my $mode;
   if ( $#files == 0 ) {&error_code(4);} 
	
	foreach my $file (@files) {	
		($inst,$exposure,$mode) = &get_File_Info($file);
		
		$currentExposure = &getExpoInfo($inst,$exposure,$mode);	
		
		# Check if the user select MOS1, MOS2, PN for analysing data
		if ($odf_object->$inst eq "no") 
		{ 
			$logger->info(
				"INSTRUMENT $inst [exposure=$exposure]: Not selected for computing GTIs");
			$logger->info( "Skipping to the next instrument or exposure...");
		}
	  	#.. Check if the current exposure has been selected to be processed
	  	elsif ( lc($currentExposure->getProcess())  eq "no" ||
	  	        lc($currentExposure->getProduct("GTIFiltering")->getProcess()) eq "no" ) 
	  	{
	  		$logger->info("\n---->INSTRUMENT $inst [exposure=$exposure]: Not selected for calculating GTI");
			$logger->info( "Skipping to the next exposure...");
		}				
		else {
	 		$logger->info( "\n----> Calculating GTI: $file [$inst,$exposure,$mode] .....");
			
			my $instrument = "";
			if ($inst eq "EPN") {		 
				$instrument = "pn";
			} elsif ($inst eq "EMOS1") {
				$instrument = "m1";
			} elsif ($inst eq "EMOS2") {
				$instrument = "m2";
			}
	 		
	 		#.. Get event files

	  		@test_epicevt=&test_epiceventfiles($inst,$exposure,$mode);
	  	 	$file=$test_epicevt[1];	  	 	
			my $epic_event_list = $file;		
	
		    if ($file) {&event_file_inf($epic_event_list,$instrument,$gtiLog);}
		    
		    my $p = $currentExposure->getProduct("GTIFiltering");
			
		    my $optimize_SN_flag = $p->getTask("xmmextractor","SN_optimization")->getParam("PG_optimize_SN")->getValue();
		    my $SN_interactivity_flag = $p->getTask("xmmextractor","GTIFiltering_interactivity")->getParam("interactivity")->getValue();		 		    
			#.. This routine will work out a new PN_Rate, MOS1_Rate and MOS2_Rate		
			if ($PG_flagCall == 0)
			{
			    #.. If the interactive mode is enabled, open ds9 with the eventlist and let the 
			    #.. user to play with the src and bkg regions.										

			    if($SN_interactivity_flag eq "yes") 
			    {
				&calculate_Signal2Noise($epic_event_list,$instrument,$exposure,$mode,$currentExposure);					
			    }
			    else 
			    {
				if (($optimize_SN_flag eq "yes")  && $file)
				{						
				    &PG_gti_filter($instrument,$exposure,$mode,$currentExposure,$epic_event_list);						
				}
			    }      
			}
			
		    chdir($gti_directory);
		    my $currentEnerCut  = "GTI_".$instrument."energy_cut";
		    my $epic_energy_cut = $currentExposure->getProduct("GTIFiltering")->getTask("evselect","lc_creation")->getParam("expression")->getValue();
			
		    my $currentRate = "GTI_".$instrument."_Rate";
		    my $epic_Rate = $currentExposure->getProduct("GTIFiltering")->getTask("tabgtigen","gti_creation")->getParam("expression")->getValue();
		    my $timebin = $currentExposure->getProduct("GTIFiltering")->getTask("evselect","lc_creation")->getParam("timebinsize")->getValue();        
	
		    $logger->info( " \#> Parameters for GTI send to gti log file...");
		    $gtiLog->info(" \#> Parameters for GTI: $file [$inst,$exposure,$mode]");
		    
		    if ($optimize_SN_flag eq "no"){
			$gtiLog->info( "           Background Light Curve Parameters: ");
			$gtiLog->info( "           $instrument Filter expression  : $epic_energy_cut");
		    }	
		    $gtiLog->info( "           Definition of GTI:");
		    $gtiLog->info( "           $instrument $epic_Rate cts/sec");
		    $gtiLog->info( "           Time Bin       : $timebin sec");
			
	#.. File definition
			
			$epic_GTI_lightcurvefile = $gti_directory.$instrument."_".$exposure."_".$mode."_back_lightc.fits";
			$epic_GTI_file           = &set_gtifilename($instrument,$exposure,$mode);
			
	    	
	#.. Create EPIC GTI File
		    if ($file){
		    	$logger->info( " \#> Creating GTI file for [$inst,$exposure,$mode]...");
		    	my $expression =$epic_energy_cut;
	#.. Building evselect parameters
	
				#.. Reading input parameters... and passing them to the SAS task call
				my $myParams =	$p->getTask("evselect","lc_creation")->getParams();
				my $params = " ";
				for my $key ( keys %$myParams ) {
	        		$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";			
				}
	
				if ( exists  $myParams{ 'table' } )	{
		       		$gtiLog->info("evselect: Using users' event file: [ $myParams->{$key}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." table=$epic_event_list:EVENTS ";
		       	}        		
		       	if (  exists $myParams->{"rateset"} ) {
		       		$gtiLog->info("evselect: Using users' lightcurve output file name: [ $myParams->{$key}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." rateset=$epic_GTI_lightcurvefile ";
		       	}        		
		       	if ( exists $myParams->{"withrateset"}) {
		       		$gtiLog->info("evselect: Using users' withrateset value: [ $myParams->{$key}->getValue()] ");		        		
		       	}	
		       	else
		       	{
		       		$params = $params." withrateset=yes ";
		       	}		     		      	
		       	if ( exists $myParams->{"maketimecolumn"}) {
		       		$gtiLog->info("evselect: Using users' maketimecolumn value: [ $myParams->{$key}->getValue()] ");		        		
		       	}	
		       	else
		       	{
		       		$params = $params." maketimecolumn=yes ";
		       	}	
		       	if ( exists $myParams->{"makeratecolumn"}) {
		       		$gtiLog->info("evselect: Using users' makeratecolumn value: [ $myParams->{$key}->getValue()] ");		        		
		       	}	
		       	else
		       	{
		       		$params = $params." makeratecolumn=yes ";
		       	}			       		     		      	
				
						
		#.. Done.
				@args = ("evselect $params");
				system(@args)== 0  or &error_code(4);
				
		#.. Building evselect parameters
		
				#.. Reading input parameters... and passing them to the SAS task call
				my $mytabgtiParams =	$p->getTask("tabgtigen","gti_creation")->getParams();
				my $tabgtiParams = " ";
				for my $key ( keys %$mytabgtiParams ) {
					if ( ref($mytabgtiParams->{$key})) {					
						$tabgtiParams = $tabgtiParams." $key=\"".$mytabgtiParams->{$key}->getValue()."\" ";  
					}
					else {					
						$tabgtiParams = $tabgtiParams." $key=\"".$mytabgtiParams->{$key}."\" ";  
					}						        	
				}
				if (exists $myParams->{"table"}) {
		       		$gtiLog->info("tabgtigen: Using users' event file: [ $myParams->{$key}->getValue()] ");
		       	}
		       	else {
		       		$tabgtiParams = $tabgtiParams." table=$epic_GTI_lightcurvefile ";
		       	}
		       	if (exists $myParams->{"gtiset"})	{
		       		$gtiLog->info("tabgtigen: Using users' gtiset file: [ $myParams->{$key}->getValue()] ");
		       	}
		       	else {
		       		$tabgtiParams = $tabgtiParams." gtiset=$epic_GTI_file ";
		       	}        	        								
				
				@args = ("tabgtigen $tabgtiParams ");
				system(@args)== 0 or &error_code(4);

				&gti_file_inf($epic_GTI_file,$instrument);	
				$logger->info( " \#> Done...");
	    	}	    
		}
	} # end of EPIC file loop
	 $logger->info( "\n----> Working out GTI. Finished");

    &error_code(0);
    return(0);
}

## @method set_gtifilename($instr,$exposure,$mode)
# Set the name of the GTI file for EPIC
# @param instr Instrument (pn,mos1,mos2)
# @param exposure
# @param mode Observing Mode (imaging,timing)
# @return GTI File name for a EPIC instr/mode

#========================================================================
sub set_gtifilename(){

    my $instr = $_[0];
	my $exposure = $_[1];
    my $mode  = $_[2];

    my $gtifile = $instr."_gti_".$exposure."_".$mode.".fits";
    
    return($gtifile)
}

## @method test_epic_gtifile()
# Test for existance of EPIC-pn GTI file and get the name of the GTI file if it exist
# @param $instrument
# @param $exposure
# @param $mode
# @return EPIC-pn GTI File name

#========================================================================
sub test_epic_gtifile(){
	
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $mode = $_[2];
	
    chdir ($gti_directory);

    my $flag = 0;
    my $file = "No file";

    $epic_GTI_file=&set_gtifilename($instrument,$exposure,$mode);
    if (-e $epic_GTI_file) {
		$logger->info( "   \#> $mode $instrument GTI File found: $epic_GTI_file");
		$flag=1;
    } else {
		$logger->info( "   \#> $mode $instrument GTI File not found");	
    }

    if ($flag) {$file=$gti_directory.$epic_GTI_file};
    return($flag,$file);     

}


## @method void produce_gticleanfile($even_file,$even_gtifile,$gti_file,$subMode,$instr)
# Given a gti file and event file, produce a gti clean event file.
# @param even_file Event File Name
# @param even_gtifile Event GTI Clean File Name
# @param gti_file GTI File Name
# @param subMode instrument mode
# @param instr Instrument
# @return Void

#========================================================================
sub produce_gticleanfile(){

    my $even_file    = $_[0];
    my $even_gtifile = $_[1]; 
    my $gti_file     = $_[2];
    my $subMode      = $_[3];
    my $instr        = $_[4];
    my $prodInfo     = $_[5];

    $logger->info( "   \#> Producing GTI clean event file from $even_file .... ");
   
   #.. Reading input parameters... and passing them to the SAS task call
    my $myParams = $prodInfo->getTask("evselect","clean_evtfile")->getParams();    

	my $params = " ";
	for my $key ( keys %$myParams ) {
		if ($key eq "expression")
		{
			my $expr =  $myParams->{$key}->getValue();
			$expr =~ s/gti.fits/$gti_file/;
			$params = $params." $key=\"".$expr."\""; 
		}
		else
		{
			$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
		}   
	}

	if (exists $myParams->{"table"} ){
       		$gtiLog->info("GTI filtering: Using users' intput event file: [ $myParams->{\"table\"}->getValue()] ");       		
   	}
   	else {
     		$params = $params." table=\"$even_file:EVENTS\" ";
   	}      
	if ( exists $myParams->{"filteredset"}) {
       		$gtiLog->info("GTI filtering: Using users' output event file: [ $myParams->{\"filteredset\"}->getValue()] ");
   	}
   	else {
     		$params = $params." filteredset=$even_gtifile ";
   	}        						    
    #.. Done
    
    @args = ("evselect $params " );
    system(@args) == 0 or &error_code(6);

    $logger->info("Done.");

    return(1);
}
1;
