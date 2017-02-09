## @file
# Produce EPIC event lists

## @method produce_epiceventlist()
# Starts and controls the production of EPIC Event List.
# @return Flags of error/success for EPIC-pn, EPIC-MOS1 and EPIC-MOS2.

#========================================================================
sub produce_epiceventlist() {

	#.. Run epproc and emproc
	$logger->info("\n----> Start EPIC Analysis ....");

	my $source_obsID = $odf_object->getObsId;
	my $source_name  = $odf_object->getSourceName;
	my $source_ra    = $odf_object->getRA;
	my $source_dec   = $odf_object->getDEC;

	#.. Test for ccf file and set ENV variable
	@test_ccf = &test_ccf();
	my $ccffile = $test_ccf[1];
	if ( !$test_ccf[0] ) {
		&run_cifbuild();
		@test_ccf = &test_ccf();
		$ccffile = $test_ccf[1];
	}
	&set_ccf($ccffile);

#.. Test for odfingest file and set ENV variable     
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];
    if (!$test_odfingest[0]) {	
		&run_odfingest();
    }
    @test_odfingest=&test_odfingest();
    if (!$test_odfingest[0]) {
    	$logger->error(" Run odfingest first");
    	 &error_code(255);
    }
    &set_odfingest($odfingestfile);
    

	#.. Print sas_setup
	&print_sas_setup();

	#.. Run epproc
	
	if ( $odf_object->EPN eq "yes" ) 
	{	
		$logger->info("\n----> Running epproc ....");
	
		chdir($pn_directory);

		$pnevt_flag          = 0;
		@test_pnevt          = &test_existance_pneventfiles();
		$pn_event_list       = $test_pnevt[1];
		$pntiming_flag       = 0;
		@test_pntimingevt    = &test_existance_pntimingeventfiles();
		$pn_timingevent_list = $test_pntimingevt[1];


		if ( $test_pnevt[0] ) {    # If event file already exist ...
			$logger->info("   \#> PN Image Event List already exist: $pn_event_list");
			$logger->info("   \#> Not running epproc");
			$pnevt_flag = 1;
		}

		if ( $test_pntimingevt[0] ) {   # If timing event file already exist ...
			$logger->info("   \#> PN Timing Event List already exist: $pn_timingevent_list");
			$logger->info("   \#> Not running epproc");
			$pntiming_flag = 1;
		}

		if ( !$pnevt_flag && !$pntiming_flag )
		{    # If event or timing files do not exist ...

			#.. Loop over all the exposures to run epproc using user's parameters
			for (my $count=0;$count<=$#exposures;$count++)
			{
   				my $expoObj = $exposures[$count];    
   				if ( ($expoObj->getInstName() eq "EPN") )
  	 			{
   				   #.. Reading input parameters... and passing them to the SAS task call
    				my $myParams = $expoObj->getProduct("EventList")->getTask("epproc","EPN_processing")->getParams();    
   					my $params = " ";
					for my $key ( keys %$myParams ) {
						$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
					}		
									 	
   					@args = ("epproc $params");
					system(@args) == 0 or &error_code(31);		
   				}		   		
			}

			$pnevt_flag          = 0;
			@test_pnevt          = &test_existance_pneventfiles();
			$pn_event_list       = $test_pnevt[1];
			$pntiming_flag       = 0;
			@test_pntimingevt    = &test_existance_pntimingeventfiles();
			$pn_timingevent_list = $test_pntimingevt[1];	

			if ( $test_pnevt[0] )
			{    # Once epproc has run, do I have event files ?
				$logger->info("   \#> After running epproc: PN Image Event List found: $pn_event_list");
				$logger->info("   \#> epproc OK ");
				$pnevt_flag = 1;
			}
			if ( $test_pntimingevt[0] )
			{    # Once epproc has run, do I have timing event files ?
				$logger->info("   \#> After running epproc: PN Timing Event List found: $pn_timingevent_list");
				$logger->info("   \#> epproc OK ");
				$pntiming_flag = 1;
			}

			if ( !$pnevt_flag && !$pntiming_flag ) {
				$logger->error("   \#> After running epproc: No PN Image or Timing Event List were found");
				$logger->error("   \#> epproc FAILED (no Events file found)");
				#	    &error_code(3) && return;
			}
		}

		&setcoordinates();				
	}

	

	#.. Run emproc
	if ( ($odf_object->EMOS1 eq "yes") || ($odf_object->EMOS2 eq "yes") ) {
		$logger->info("\n----> Running emproc ....");

		$m1evt_flag          = 0;
		@test_m1evt          = &test_existance_mos1eventfiles();
		$m1_event_list       = $test_m1evt[1];
		$m1timing_flag       = 0;
		@test_m1timingevt    = &test_existance_mos1timingeventfiles();
		$m1_timingevent_list = $test_m1timingevt[1];

		$m2evt_flag          = 0;
		@test_m2evt          = &test_existance_mos2eventfiles();
		$m2_event_list       = $test_m2evt[1];
		$m2timing_flag       = 0;
		@test_m2timingevt    = &test_existance_mos2timingeventfiles();
		$m2_timingevent_list = $test_m2timingevt[1];

		if ( $test_m1evt[0]  ) {

			$logger->info( "   \#> Image Event file already exist:");
			$logger->info( "       MOS1: $m1_event_list ");
			$logger->info( "   \#> Not running emproc ");
			$m1evt_flag = 1;
		}
		if ( $test_m2evt[0] ) {

			$logger->info( "   \#> Image Event file already exist:");
			$logger->info( "       MOS2: $m2_event_list ");
			$logger->info( "   \#> Not running emproc ");
			$m2evt_flag = 1;
		}
		
		if ( $test_m1timingevt[0] ) {

			$logger->info( "   \#> Timing Event file already exist:");
			$logger->info( "       MOS1: $m1_timingevent_list");
			$logger->info( "   \#> Not running emproc");
			$m1timing_flag = 1;
		}
		if ( $test_m2timingevt[0] ) {

			$logger->info( "   \#> Timing Event file already exist:");		
			$logger->info( "       MOS2: $m2_timingevent_list");
			$logger->info( "   \#> Not running emproc");
			$m2timing_flag = 1;
		}



		#.. Loop over all the exposures to run emproc using user's parameters
		for (my $count=0;$count<=$#exposures;$count++)
		{
   			my $expoObj = $exposures[$count];
   			my $params = " ";    
   			if ( ($expoObj->getInstName() eq "EMOS1") )
  			{
   			   #.. Reading input parameters... and passing them to the SAS task call
    			my $myParams = $expoObj->getProduct("EventList")->getTask("emproc","EMOS1_processing")->getParams();
				for my $key ( keys %$myParams ) {
					$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
				}

				if (lc($odf_object->EMOS1()) eq "yes" && 
				 ($m1evt_flag == 0) && ($m1timing_flag == 0) )	
   				{   						 
  					@args = ("emproc $params");
					system(@args) == 0 or &error_code(31);
   				}											
   			}		   		
   			if ( ($expoObj->getInstName() eq "EMOS2") )
  	 		{
   			   #.. Reading input parameters... and passing them to the SAS task call
    			my $myParams = $expoObj->getProduct("EventList")->getTask("emproc","EMOS2_processing")->getParams();    
   				
				for my $key ( keys %$myParams ) {
				$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
				}				
	   			if (lc($odf_object->EMOS2()) eq "yes" && 
	   				( $m2evt_flag == 0) && ($m2evt_flag == 0 ) )	
   				{   		
  					@args = ("emproc $params");
					system(@args) == 0 or &error_code(32);
   				}		
   			}	
		}

		$m1evt_flag          = 0;
		@test_m1evt          = &test_existance_mos1eventfiles();
		$m1_event_list       = $test_m1evt[1];
		$m1timing_flag       = 0;
		@test_m1timingevt    = &test_existance_mos1timingeventfiles();
		$m1_timingevent_list = $test_m1timingevt[1];
		$m2evt_flag          = 0;
		@test_m2evt          = &test_existance_mos2eventfiles();
		$m2_event_list       = $test_m2evt[1];
		$m2timing_flag       = 0;
		@test_m2timingevt    = &test_existance_mos2timingeventfiles();
		$m2_timingevent_list = $test_m2timingevt[1];
		if ( $test_m1evt[0] && $test_m2evt[0] )
		{    # Once emproc has run, do I have event files ?

			$logger->info(
			  "   \#> After running emproc: MOS Image Event List found:");
			$logger->info( "       MOS1: $m1_event_list ");
			$logger->info( "       MOS2: $m2_event_list ");
			$logger->info( "   \#> emproc OK ");
			$m1evt_flag = 1;
			$m2evt_flag = 1;
		}
		elsif ( $test_m1evt[0] && !$test_m2evt[0] ) {
				$logger->info( "   \#> After running emproc: MOS1 Image Event List found: $m1_event_list ");
			$logger->info( "   \#> emproc OK ");
			$m1evt_flag = 1;
		}
		elsif ( !$test_m1evt[0] && $test_m2evt[0] ) {
			$logger->info( "   \#> After running emproc: MOS2 Image Event List found: $m2_event_list ");
			$logger->info( "   \#> emproc OK ");
			
			$m2evt_flag = 1;
		}

		if ( $test_m1timingevt[0] && $test_m2timingevt[0] )
		{    # Once emproc has run, do I have timing event files ?
			$logger->info( "   \#> After running emproc: MOS Timing Event List found: ");
			$logger->info( "       MOS1: $m1_timingevent_list ");
			$logger->info( "       MOS2: $m2_timingevent_list ");
			$logger->info( "   \#> emproc OK ");
			
			$m1timing_flag = 1;
			$m2timing_flag = 1;
		}
		elsif ( $test_m1timingevt[0] && !$test_m2timingevt[0] ) {
			$logger->info( "   \#> After running emproc: MOS1 Timing Event List found: $m1_timingevent_list");
			$logger->info( "   \#> emproc OK ");
			$m1timing_flag = 1;
		}
		elsif ( !$test_m1timingevt[0] && $test_m2timingevt[0] ) {
			$logger->info( "   \#> After running emproc: MOS2 Timing Event List found: $m2_timingevent_list ");
			$logger->info( "   \#> emproc OK ");
			$m2timing_flag = 1;
		}

		if (   !$m1evt_flag
			&& !$m2evt_flag
			&& !$m1timing_flag
			&& !$m2timing_flag )
		{

			$logger->info( "   \#> After running emproc: No MOS Image or Timing Event List were found ");
			$logger->info( "   \#> emproc FAILED (no Events file found)");
				#	    &error_code(3) && return;
		}
		
	}    

	if ( $test_pnevt[0] ) { &event_file_inf( $pn_event_list, "pn",$eventLog ); }
	if ( $test_pntimingevt[0] ) {
		&event_file_inf( $pn_timingevent_list, "pn",$eventLog );
	}

	if ( $test_m1evt[0] ) { &event_file_inf( $m1_event_list, "m1",$eventLog ); }
	if ( $test_m1timingevt[0] ) {
		&event_file_inf( $m1_timingevent_list, "m1",$eventLog );
	}
	if ( $test_m2evt[0] ) { &event_file_inf( $m2_event_list, "m2",$eventLog ); }
	if ( $test_m2timingevt[0] ) {
		&event_file_inf( $m2_timingevent_list, "m2",$eventLog );
	}	
	$logger->info( "\n----> Working out EPIC event lists. Finished");
	&error_code(0);

}



## @method test_epiceventfiles($inst,$exposure,$mode)
# Test the existance of EPIC Imaging Event List
# @param instrument
# @param exposure
# @param mode
# @return File Name

#========================================================================
sub test_epiceventfiles() {
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $mode = $_[2];
	
	my $dir= "";
	if ($instrument eq "EPN") { 
		$dir = $pn_directory;
	}
	else { 
		$dir = $mos_directory;
	}
	chdir($dir);
	
	my $match = "*".$instrument."_".$exposure."_".$mode.".ds";
	@EPIC_Evtlist =  glob($match);

	if ( $#EPIC_Evtlist >= 0 ) {
		$logger->info( "   \#> $instrument $mode Event List found: ");
		foreach (@EPIC_Evtlist) { $logger->info( "\t" . $_ ); }

		$index = 0;
		if ( $#EPIC_Evtlist > 0 ) {
			$logger->info("      Using event file with longest Observation Duration: $EPIC_Evtlist[0] ");
		}
		my $epic_event_list = $EPIC_Evtlist[0];
		return ( 1, $dir . $epic_event_list );
	}
	else {
		$logger->info( "   \#> $instrument $mode Event List not found ");
		return ( 0, "No File" );
	}
}

## @method test_existance_pneventfiles()
# Test the existance of EPIC-pn Imaging Event List
# @return File Name

#========================================================================
sub test_existance_pneventfiles(){
    chdir ($pn_directory);
    @PN_Evtlist = glob('*EPN*ImagingEvts.ds');
    if ($#PN_Evtlist >= 0) {
	$logger->info("   \#> PN Image Event List found: "); foreach (@PN_Evtlist) {$logger->info("\t".$_ );}

	$index=0;
	if ($#PN_Evtlist > 0) {
	    foreach my $event_list (@PN_Evtlist) {
	    	$obs_duration=&getduration($event_list,1); push(@pnitime,$obs_duration);
	    }
	    $max_time=0.;
	    $i=0;
	    foreach (@pnitime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
	    $logger->info("      Using event file with longest Observation Duration: $PN_Evtlist[$index]");
	}
	my $pn_event_list = $PN_Evtlist[$index];
	return(1,$pn_directory.$pn_event_list);
    } else {
	$logger->info( "   \#> PN Imaging Event List not found ");
	return (0,"No File"); 
    }
}

## @method test_pntimingeventfiles()
# Test the existance of EPIC-pn Timing Event List
# @return File Name

#========================================================================
sub test_existance_pntimingeventfiles(){
    chdir ($pn_directory);
    @PN_TimEvtlist = glob('*EPN*TimingEvts.ds');
    if ($#PN_TimEvtlist >= 0) {
	$logger->info("   \#> PN Timing Event List found:"); 
	foreach (@PN_TimEvtlist) {$logger->info( "\t".$_ );}

	$index=0;
	if ($#PN_TimEvtlist > 0) {
	    foreach my $event_list (@PN_TimEvtlist) {$obs_duration=&getduration($event_list,1); push(@pnttime,$obs_duration);}
	    $max_time=0.;
	    $i=0;
	    foreach (@pnttime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
	    $logger->info( "      Using event file with longest Observation Duration: $PN_TimEvtlist[$index]");

	}
	my $pn_timingevent_list = $PN_TimEvtlist[$index];
	return(1,$pn_directory.$pn_timingevent_list);
    } else {
	$logger->info( "   \#> PN Timing List not found ");

	return (0,"No File"); 
    }
}

## @method test_existance_mos1eventfiles()
# Test the existance of EPIC-MOS1 Imaging Event List
# @return File Name

#========================================================================
sub test_existance_mos1eventfiles(){
    chdir ($mos_directory);
    my @MOS1_Evtlist = glob('*EMOS1*ImagingEvts.ds');
    if ($#MOS1_Evtlist >= 0){
	$logger->info("   \#> MOS1 Image Event List found: "); 
	foreach (@MOS1_Evtlist) {$logger->info("\t".$_ );}   

	$index=0;
	if ($#MOS1_Evtlist > 0){	    
	    foreach my $event_list (@MOS1_Evtlist) {
	    	$obs_duration=&getduration($event_list,1); push(@m1itime,$obs_duration);
	    }
	    $max_time=0.;
	    $i=0;
	    foreach (@m1itime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
	    $logger->info("      Using event file with longest Observation Duration: $MOS1_Evtlist[$index] ");

	}
	my $m1_event_list = $MOS1_Evtlist[$index];
	return(1,$mos_directory.$m1_event_list);
    } else {
	$logger->info( "   \#> MOS1 Image Event List not found ");

	return(0,"No File");
    }
}

## @method test_mos1timingeventfiles()
# Test the existance of EPIC-MOS1 Timining Event List
# @return File Name

#========================================================================
sub test_existance_mos1timingeventfiles(){
    chdir ($mos_directory);
    my @MOS1_TimEvtlist = glob('*EMOS1*TimingEvts.ds');
    if ($#MOS1_TimEvtlist >= 0){
	$logger->info("   \#> MOS1 Timing List found:"); 
	foreach (@MOS1_TimEvtlist) {$logger->info("\t".$_ );}   
	
	$index=0;
   	if ($#MOS1_TimEvtlist > 0){
	    foreach my $event_list (@MOS1_TimEvtlist) {
	    	$obs_duration=&getduration($event_list,1); push(@m1ttime,$obs_duration);
	    }
	    $max_time=0.;
	    $i=0;
	    foreach (@m1ttime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
	    $logger->info("      Using event file with longest Observation Duration: $MOS1_TimEvtlist[$index]");
	    
	}
	my $m1_timingevent_list = $MOS1_TimEvtlist[$index];
	return(1,$mos_directory.$m1_timingevent_list);
    } else {
	$logger->info("   \#> MOS1 Timing List not found ");

	return(0,"No File");
    }
}

## @method test_existance_mos2eventfiles()
# Test the existance of EPIC-MOS2 Imaging Event List
# @return File Name

#========================================================================
sub test_existance_mos2eventfiles(){
    chdir ($mos_directory);
    my @MOS2_Evtlist = glob('*EMOS2*ImagingEvts.ds');
    if ($#MOS2_Evtlist >= 0){
		$logger->info( "   \#> MOS2 Image Event List found: "); 
		foreach (@MOS2_Evtlist) {$logger->info("\t".$_ );}  
	
		$index=0;
		if ($#MOS2_Evtlist > 0){
		    foreach my $event_list (@MOS2_Evtlist) {
		    	$obs_duration=&getduration($event_list,1); push(@m2itime,$obs_duration);
		    }
		    $max_time=0.;
		    $i=0;
		    foreach (@m2itime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
		    $logger->info("      Using event file with longest Observation Duration: $MOS2_Evtlist[$index] ");
		}
		my $m2_event_list = $MOS2_Evtlist[$index];
		return(1,$mos_directory.$m2_event_list);
    } else {
		$logger->info("   \#> MOS2 Image Event List not found");
		return(0,"No File");
    }
}

## @method test_mos2timingeventfiles()
# Test the existance of EPIC-MOS2 Timining Event List
# @return File Name

#========================================================================
sub test_existance_mos2timingeventfiles(){
    chdir ($mos_directory);
    my @MOS2_TimEvtlist = glob('*EMOS2*TimingEvts.ds');
    if ($#MOS2_TimEvtlist >= 0){
		$logger->info("   \#> MOS2 Timing List found: "); 
		foreach (@MOS2_TimEvtlist) {$logger->info("\t".$_ );}  
	
		$index=0;
		if ($#MOS2_TimEvtlist > 0){
		    foreach my $event_list (@MOS2_TimEvtlist) {$obs_duration=&getduration($event_list,1); push(@m2ttime,$obs_duration);}
		    $max_time=0.;
		    $i=0;
		    foreach (@m2ttime){if ($_ > $max_time){$max_time=$_;$index=$i;};$i++}
		    $logger->info( "      Using event file with longest Observation Duration: $MOS2_TimEvtlist[$index]");
	
		}
		my $m2_timingevent_list = $MOS2_TimEvtlist[$index];
		return(1,$mos_directory.$m2_timingevent_list);
    } else {
		$logger->info("   \#> MOS2 Timing List not found");
		return(0,"No File");
    }
}



## @method test_existance_epicfiles()
# Test the existance of EPIC Event List
# @return true/false

#========================================================================
sub test_existance_epicfiles(){
    $inst = $_[0];
    if ($inst eq "EPN") {
    	chdir ($pn_directory);
    } else {    	   
    	chdir ($mos_directory);
    }
    $logger->info("   \#> Searching for EPIC event files.... ");
    @EPIC_Evtlist = glob('*'.$inst.'*Evts.ds');
    if ($#EPIC_Evtlist >= 0) {
		$logger->info("   \#> Found files: "); 
		foreach (@EPIC_Evtlist) {$logger->info("\t".$_ );}
		return(1);
    } else {
		$logger->info("   \#> No EPIC $inst files found");
		return (0); 
    }
}


1;
