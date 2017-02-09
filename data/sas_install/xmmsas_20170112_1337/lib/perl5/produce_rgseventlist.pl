## @file
# Produce RGS event lists

## @method produce_rgseventlist()
# Starts and controls the production of RGS Event List.
# @return Flag of error/success for RGS.

#========================================================================
sub produce_rgseventlist(){

#.. Run rgsproc
    $logger->info( "\n----> Start RGS Analysis ....");

    my $source_obsID = $odf_object->getObsId;
    my $source_name  = $odf_object->getSourceName;

#.. Test for ccf file and set ENV variable
    @test_ccf=&test_ccf();
    my $ccffile=$test_ccf[1];
    if (!$test_ccf[0]) {$logger->warn( "      Run cifbuild first"); &error_code(3);}
    &set_ccf($ccffile);

#.. Test for odfingest file and set ENV variable     
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];
    if (!$test_odfingest[0]) {$logger->info( "      Run odfingest first "); &error_code(3);}
    &set_odfingest($odfingestfile);
    
#.. Print sas_setup    
    &print_sas_setup();


#.. Run rgsproc
    chdir ($rgs_directory);

    $rgs1evt_flag    = 0;
    @test_rgs1evt=&test_rgs1eventfiles();
    $rgs1_event_list=$test_rgs1evt[1];

    $rgs2evt_flag    = 0;
    @test_rgs2evt=&test_rgs2eventfiles();
    $rgs2_event_list=$test_rgs2evt[1];

    if ($test_rgs1evt[0]) {               # If event file already exist ...
		$logger->info( "   \#> RGS1 Event List already exist: $rgs1_event_list "); 
		$logger->info( "   \#> Not running rgsproc ");
		$rgs1evt_flag = 1;
    }
    if ($test_rgs2evt[0]) {               # If event file already exist ...
		$logger->info( "   \#> RGS2 Event List already exist: $rgs2_event_list "); 
		$logger->info( "   \#> Not running rgsproc ");
		$rgs2evt_flag = 1;
    }	
	
	# If RGS1 or RGS2 event files do not exist ...
    if (!$rgs1evt_flag && !$rgs2evt_flag)  
    { 
		$logger->info( "\n----> Running rgsproc ....");

		$currentExposure = &getRGSExpoInfo();
		$p = $currentExposure->getProduct("rgsproc");

	
		#.. Loop over all the exposures to run epproc using user's parameters
		#.. Global flag to identify if rgsproc was run for a particular expids
		my $rgsproc_flag = 0;
		for (my $count=0;$count<=$#exposures;$count++)
		{
   			my $expoObj = $exposures[$count];
   			my $params = " "; 
			my $rgs_expids_flag = 0;			
   			if ( ($expoObj->getInstName() eq "RGS1") )
   			{
   			   #.. Reading input parameters... and passing them to the SAS task call
   				my $myParams = $expoObj->getProduct("EventList")->getTask("rgsproc","RGS1_processing")->getParams();    
  				for my $key ( keys %$myParams ) {
					$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
					if ($key eq "instexpids")
					{
						$rgs_expids_flag = 1;  
					}
				}				
				if ($rgs_expids_flag == 1)
				{
					@args = ("rgsproc $params " ); 
					system(@args) == 0 or &error_code(34);
					$rgsproc_flag = 1;
				}				
   			}		   		
   			if ( ($expoObj->getInstName() eq "RGS2") )
   			{
  			   #.. Reading input parameters... and passing them to the SAS task call  			     			   
   				my $myParams = $expoObj->getProduct("EventList")->getTask("rgsproc","RGS2_processing")->getParams();    
   					
				for my $key ( keys %$myParams ) {
					$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
									
					if ($key eq "instexpids")
					{
						$rgs_expids_flag = 1;  
					}
				}
				if ($rgs_expids_flag == 1)
				{
					@args = ("rgsproc $params " ); 
					system(@args) == 0 or &error_code(35);
					$rgsproc_flag = 1;
				}							
   			}
		}
		
		#.. If rgsproc was not executed... Do it
		if ($rgsproc_flag == 0)
		{
			@args = ("rgsproc " ); 
			system(@args) == 0 or &error_code(3);
		}
		
		$rgs1evt_flag    = 0;
		@test_rgs1evt=&test_rgs1eventfiles();
		$rgs1_event_list=$test_rgs1evt[1];
		$rgs2evt_flag    = 0;
		@test_rgs2evt=&test_rgs2eventfiles();
		$rgs2_event_list=$test_rgs2evt[1];
    }
    else
    {
    	$logger->info( "\n----> RGS event files found. Not running rgsproc ....");
    }
    
	if ($test_rgs1evt[0]) {           # Once rgsproc has run, do I have event files ?
	    $logger->info( "   \#> After running rgsproc: RGS1 Event List found: $rgs1_event_list"); 
	    $logger->info( "   \#> rgsproc OK ");

	    $rgs1evt_flag = 1;
	} else {
	    $logger->info( "   \#> After running rgsproc: RGS1 Event List not found "); 
	    $logger->info( "   \#> rgsproc FAILED ");
	    $rgs1evt_flag = 0;
	}

	if ($test_rgs2evt[0]) {           # Once rgsproc has run, do I have event files ?
	    $logger->info( "   \#> After running rgsproc: RGS2 Event List found: $rgs2_event_list"); 
	    $logger->info( "   \#> rgsproc OK ");
	    $rgs2evt_flag = 1;
	} else {
	    $logger->info( "   \#> After running rgsproc: RGS2 Event List not found "); 
	    $logger->info( "   \#> rgsproc FAILED ");
	    $rgs2evt_flag = 0;
	}
	
	if (!$rgs1evt_flag && !$rgs2evt_flag)  {
	    $logger->info( "   \#> After running rgsproc: No RGS1 or RGS2 Event List were found "); 
	    $logger->info( "   \#> rgsproc FAILED (no Events file found) ");
#	    &error_code(3) && return;
	}  
    
    
	if ($test_rgs1evt[0]) {&event_file_inf($rgs1_event_list,"rgs1",$rgsLog);}
	if ($test_rgs2evt[0]) {&event_file_inf($rgs2_event_list,"rgs2",$rgsLog);}

    

#.. Display the dispersion versus cross dispersion and dispersion versus energy images and 
#.. overlay the selected region masks.

    if ($rgs1evt_flag || $rgs2evt_flag){
		$logger->info( "\#> Producing dispersion vs cross dispersion and vs energy plots ... ");
    }
    if ($rgs1evt_flag){   
		@test_rgs1src=&test_rgs1SRCfiles();
		$rgs1_SRCList_file=$test_rgs1src[1];
		if ($test_rgs1src[0]) {&get_rgsSRCList_info($rgs1_SRCList_file,"rgs1");}
		if ($test_rgs1evt[0]) {
		    $rgs1_plot_flag=&make_rgs_plot($rgs1_event_list,$rgs1_SRCList_file,"rgs1");
	    	if (!$rgs1_plot_flag) {
				$logger->error( "Failed to produce plot for RGS1");
	    	}
		}      
    }
    if ($rgs2evt_flag){  
		@test_rgs2src=&test_rgs2SRCfiles();
		$rgs2_SRCList_file=$test_rgs2src[1];
		if ($test_rgs2src[0]) {&get_rgsSRCList_info($rgs2_SRCList_file,"rgs2");}
		if ($test_rgs2evt[0]) {
	    	$rgs2_plot_flag=&make_rgs_plot($rgs2_event_list,$rgs2_SRCList_file,"rgs2");
	    	if (!$rgs2_plot_flag) {
				$logger->error( "       Failed to produce plot for RGS2");
	    	}
		}
    }
	$logger->info( "\n----> Working out RGS event lists. Finished");
    &error_code(0); 
    return($rgs1evt_flag,$rgs2evt_flag);
}

## @method test_rgs1eventfiles()
# Test the existance of RGS1 Event List
# @return File Name

#========================================================================
sub test_rgs1eventfiles{
    chdir ($rgs_directory);
    my @RGS1_Evtlist = glob('*R1*EVENLI0000.FIT');
    if ($#RGS1_Evtlist >= 0){
	$logger->info( "   \#> RGS1 Event List found:"); 
	foreach (@RGS1_Evtlist) {$logger->info( "\t".$_ );}   

	if ($#RGS1_Evtlist > 0){
	    $logger->info( "      Using only $RGS1_Evtlist[0]");
	}
	my $rgs1_event_list = $RGS1_Evtlist[0];
	return(1,$rgs_directory.$rgs1_event_list);
    } else {
	$logger->info( "   \#> RGS1 Event List not found ");
	return(0,"No File");
    }
}

## @method test_rgs2eventfiles()
# Test the existance of RGS2 Event List
# @return File Name

#========================================================================
sub test_rgs2eventfiles{
    chdir ($rgs_directory);
    my @RGS2_Evtlist = glob('*R2*EVENLI0000.FIT');
    if ($#RGS2_Evtlist >= 0){
		$logger->info( "   \#> RGS2 Event List found: "); 
		foreach (@RGS2_Evtlist) {$logger->info( "\t".$_ );}   
		if ($#RGS2_Evtlist > 0){
	    	$logger->info( "      Using only $RGS2_Evtlist[0] ");
		}
		my $rgs2_event_list = $RGS2_Evtlist[0];
		return(1,$rgs_directory.$rgs2_event_list);
    } else {
		$logger->info( "   \#> RGS2 Event List not found ");
		return(0,"No File");
    }
}

## @method test_rgs1SRCfiles()
# Test the existance of RGS1 Source List
# @return File Name

#========================================================================
sub test_rgs1SRCfiles{
    chdir ($rgs_directory);
    my @RGS1_SRClist = glob('*R1*SRCLI_0000.FIT ');
    if ($#RGS1_SRClist >= 0){
	$logger->info( "   \#> RGS1 Source List found: "); 
	foreach (@RGS1_SRClist) {$logger->info( "\t".$_ );}   
	if ($#RGS1_SRClist > 0){
	    $logger->info( "      Using only $RGS1_SRClist[0]");
	}
	my $rgs1_src_list = $RGS1_SRClist[0];
	return(1,$rgs_directory.$rgs1_src_list);
    } else {
	$logger->info( "   \#> RGS1 Source List not found ");
	return(0,"No File");
    }
}

## @method test_rgs2SRCfiles()
# Test the existance of RGS2 Source List
# @return File Name

#========================================================================
sub test_rgs2SRCfiles{
    chdir ($rgs_directory);
    my @RGS2_SRClist = glob('*R2*SRCLI_0000.FIT ');
    if ($#RGS2_SRClist >= 0){
	$logger->info( "   \#> RGS2 Source List found:");
	foreach (@RGS2_SRClist) {$logger->info( "\t".$_ );}   

	if ($#RGS2_SRClist > 0){
	    $logger->info( "      Using only $RGS2_SRClist[0]");
	}
	my $rgs2_src_list = $RGS2_SRClist[0];
	return(1,$rgs_directory.$rgs2_src_list);
    } else {
	$logger->info( "   \#> RGS2 Source List not found");
	return(0,"No File");
    }
}

## @method void get_rgsSRCList_info($in_file,$instr)
# Obtain information from RGS1/RGS2 Source List for instrument instr
# @param src_file Input Source List
# @param instr Instrument (RGS1/RGS2)
# @return Void

#========================================================================
sub get_rgsSRCList_info{

    my $src_file     = $_[0];
    my $temp_file    = $src_file."\.temp";
    my $instr        = $_[1];

    chdir($rgs_directory);
    
    @args = ("fdump \'$src_file\[1\]\' $temp_file \"RA\" 1 prhead=no showcol=no showunit=no showrow=no clobber=yes");
    system(@args)== 0 or &error_code(3);
    chomp($RGS_Proposal[0] = `cat $temp_file`);
    $RGS_Proposal[0] =~ s/\s+//;
    unlink("$temp_file") or die "Cannot rm file $temp_file: $!";
    
    @args = ("fdump \'$src_file\[1\]\' $temp_file \"RA\" 2 prhead=no showcol=no showunit=no showrow=no clobber=yes");
    system(@args)== 0 or &error_code(3);
    chomp($RGS_OnAxis[0] = `cat $temp_file`);
    $RGS_OnAxis[0] =~ s/\s+//;
    unlink("$temp_file") or die "Cannot rm file $temp_file: $!";

    @args = ("fdump \'$src_file\[1\]\' $temp_file \"DEC\" 1 prhead=no showcol=no showunit=no showrow=no clobber=yes");
    system(@args)== 0 or &error_code(3);
    chomp($RGS_Proposal[1] = `cat $temp_file`);
    $RGS_Proposal[1] =~ s/\s+//;
    unlink("$temp_file") or die "Cannot rm file $temp_file: $!";

    @args = ("fdump \'$src_file\[1\]\' $temp_file \"DEC\" 2 prhead=no showcol=no showunit=no showrow=no clobber=yes");
    system(@args)== 0 or &error_code(3);
    chomp($RGS_OnAxis[1] = `cat $temp_file`);
    $RGS_OnAxis[1] =~ s/\s+//;
    unlink("$temp_file") or die "Cannot rm file $temp_file: $!";

    $rgs_dist = &Angular_separation($RGS_Proposal[0],$RGS_OnAxis[0],$RGS_Proposal[1],$RGS_OnAxis[1]);
    $logger->info( "        $instr SRC Separation (PROPOSAL and ONAXIS Source) : ",$rgs_dist*3600.," : arcsec ");

    return(1);
}

## @method void make_rgs_plot($in_file,$src_list,$instr)
# Obtain information from RGS1/RGS2 Source List
# @param in_file Input Event List 
# @param src_list Input Source List 
# @param instr Instrument (RGS1/RGS2)
# @return Void

#========================================================================
sub make_rgs_plot{

    my $in_file    = $_[0];
    my $src_list   = $_[1];
    my $instr      = $_[2];

    my $pi_file      = "pi_".$instr."\.fit";
    my $spatial_file = "spatial_".$instr."\.fit";
    my $ps_file      = "image_".$instr."\.ps";

    if ($instr eq "rgs1"){$expr="RGS1_SRC1_SPATIAL,BETA_CORR,XDSP_CORR"}
    if ($instr eq "rgs2"){$expr="RGS2_SRC1_SPATIAL,BETA_CORR,XDSP_CORR"}

	if (-e $ps_file) {
		$logger->info( "   \#> RGS disp vs xdisp and disp vs ener exists... ");
	}
    else 
    {
    	@args = ("evselect table=\'$in_file:EVENTS\' imageset=\'$spatial_file\' xcolumn=\'BETA_CORR\' ycolumn=\'XDSP_CORR\'");
    	system(@args) == 0 or return(0);
    
    	@args = ("evselect table=\'$in_file:EVENTS\' imageset=\'$pi_file\' xcolumn=\'BETA_CORR\' ycolumn=\'PI\' yimagemin=0 yimagemax=3000 expression=\'REGION($src_list:$expr)\'");
    	system(@args) == 0 or return(0);

    	@args = ("rgsimplot endispset=\'$pi_file\' spatialset=\'$spatial_file\' srcidlist='1' srclistset=\'$src_list\' plotfile=\'$ps_file\' device=\/ps");
    	system(@args) == 0 or return(0);
    }

    return(1);
}

sub produceRGSLightcurves()
{
	my $source_obsID = $odf_object->getObsId;
    my $source_name  = $odf_object->getSourceName;
	my $ext = 1;

	if ( lc($odf_object->RGS1) eq "no")   
	{
		$logger->info( "\n---->INSTRUMENT RGS1: Not selected for calculating light curve");
	}
	else
	{
		$logger->info( "\n---->Calculating RGS1 light curve");
		@rgsExposures = &getRGSExposures("RGS1");
		for (my $count=0;$count<=$#rgsExposures;$count++)
		{
			my $currentExpo = $rgsExposures[$count];			
			$p = $currentExpo->getProduct("lightcurve");
		
			#.. RGS1 Lightcurve
	    	my $rgs1_timebinsize =  $p->getTask("rgslccorr","RGS_lc_generator")->getParam("timebinsize")->getValue();	
			my $rgs1_sourcelc_file = $lcurve_directory.$source_name."_rgs1.lc";
			my $rgs1_bkglc_file = $lcurve_directory.$source_name."_rgs1_bkg.lc";
			my @test_rgs1evt=&test_rgs1eventfiles();
		
			$logger->info( "   \#> RGS1 Event List already exist: $test_rgs1evt[1] ");
		
			my @test_rgs1src=&test_rgs1SRCfiles();
			$logger->info( "   \#> RGS1 Source List already exist: $test_rgs1src[1] ");			
			if ($test_rgs1evt[0]) {	
				chomp(my $rgs1_srcid = `fkeyprint infile=$test_rgs1src[1]+$ext keynam=PRIMESRC outfil=STDOUT exact=yes | sed '/^#/d' | grep PRIMESRC | head -1 | awk '{print \$2}'`);		

				$logger->info( "      RGS1 : Processing LCurve for Time Bin: $rgs1_timebinsize.");
					
				#.. Reading input parameters... and passing them to the SAS task call
				$myParams =	$p->getTask("rgslccorr","RGS_lc_generator")->getParams();
				my $params = " ";
				for my $key ( keys %$myParams ) {
        			$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
				}
    						
				if (exists $myParams->{"evlist"}) {
	        		$rgsLCLog->info("rgslccorr: Using users' event file: [ $myParams->{\"evlist\"}->getValue()] ");
	        	}
	        	else {
	        		$params = $params." evlist=$test_rgs1evt[1] ";
	        	}        		
	        	if (exists $myParams->{"srclist"} )	{
		       		$rgsLCLog->info("rgslccorr: Using users' source list file: [ $myParams->{\"srclist\"}->getValue()] ");
		      	}
		       	else {
		       		$params = $params." srclist=$test_rgs1src[1] ";
		       	}        	
		       	if ( exists $myParams->{"outputsrcfilename"}) {
		       		$rgsLCLog->info("rgslccorr: Using users' output source file name: [ $myParams->{\"outputsrcfilename\"}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." outputsrcfilename=$rgs1_sourcelc_file ";
		       	}        		
		       	if (exists $myParams->{"outputbkgfilename"}) {
		       		$rgsLCLog->info("rgslccorr: Using users' background file name: [ $myParams->{\"outputbkgfilename\"}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." outputbkgfilename=$rgs1_bkglc_file ";
		       	}
		       	if (exists $myParams->{"sourceid"}) {
		       		$rgsLCLog->info("rgslccorr: Using users' sourceid value: [ $myParams->{\"sourceid\"}->getValue()] ");		        		
		       	}	
		       	else
		       	{
		       		$params = $params." sourceid=$rgs1_srcid ";
		       	}		     		     
		        				     		     

				@args = ("rgslccorr  $params");
		
		    	 system(@args)== 0 or &error_code(7);	
			}
		}      
	}
	
	if ( ($odf_object->RGS2() eq "no") ) 
	{
		$logger->info( "\n---->INSTRUMENT RGS2: Not selected for calculating light curve");
	}
	else
	{
		#.. RGS2 Lightcurve
		$logger->info( "\n---->Calculating RGS2 light curve");
		@rgsExposures = &getRGSExposures("RGS2");
		for (my $count=0;$count<=$#rgsExposures;$count++)
		{
			my $currentExpo = $rgsExposures[$count];			
			$p = $currentExpo->getProduct("lightcurve");
			
		    my $rgs2_timebinsize =  $p->getTask("rgslccorr","RGS_lc_generator")->getParam("timebinsize")->getValue();	
			my $rgs2_sourcelc_file = $lcurve_directory.$source_name."_rgs2.lc";
			my $rgs2_bkglc_file = $lcurve_directory.$source_name."_rgs2_bkg.lc";
			my @test_rgs2evt=&test_rgs2eventfiles();
		
			$logger->info( "   \#> RGS2 Event List already exist: $test_rgs2evt[1]");
			
			my @test_rgs2src=&test_rgs2SRCfiles();
			$logger->info( "   \#> RGS2 Source List already exist: $test_rgs2src[1] ");
				
			if ($test_rgs2evt[0]) {	
				$logger->info( "  rgs2 : Processing LCurve for Time Bin: $rgs2_timebinsize.");
		
			   	chomp(my $rgs2_srcid = `fkeyprint infile=$test_rgs2src[1]+$ext keynam=PRIMESRC outfil=STDOUT exact=yes| sed '/^#/d' | grep PRIMESRC | head -1 | awk '{print \$2}' `);
		     	
		     	#.. Reading input parameters... and passing them to the SAS task call
				$myParams =	$p->getTask("rgslccorr","RGS_lc_generator")->getParams();
				my $params = " ";
				for my $key ( keys %$myParams ) {
        			$params = $params." $key=\"".$myParams->{$key}->getValue()."\" ";
				}			

				if ( exists $myParams->{"evlist"}) {
	        		$rgsLCLog->info("rgslccorr: Using users' event file: [ $myParams->{\"evlist\"}->getValue()] ");
	        	}
	        	else {
		       		$params = $params." evlist=$test_rgs2evt[1] ";
	        	}        		
	        	if (exists $myParams->{"srclist"})	{
	       			$rgsLCLog->info("rgslccorr: Using users' source list file: [ $myParams->{\"srclist\"}->getValue()] ");
	        	}
		       	else {
	        		$params = $params." srclist=$test_rgs2src[1] ";
	        	}        	
	        	if (exists $myParams->{"outputsrcfilename"}) {
	       			$rgsLCLog->info("rgslccorr: Using users' output source file name: [ $myParams->{\"outputsrcfilename\"}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." outputsrcfilename=$rgs2_sourcelc_file ";
		       	}        		
		       	if ( exists $myParams->{"outputbkgfilename"}) {
		       		$rgsLCLog->info("rgslccorr: Using users' background file name: [ $myParams->{\"outputbkgfilename\"}->getValue()] ");
		       	}
		       	else {
		       		$params = $params." outputbkgfilename=$rgs2_bkglc_file ";
		       	}
		       	if ( exists $myParams->{"sourceid"}) {
	      			$rgsLCLog->info("rgslccorr: Using users' sourceid value: [ $myParams->{\"sourceid\"}->getValue()] ");		        		
	        	}	
	        	else
		       	{
	        		$params = $params." sourceid=$rgs2_srcid ";
		       	}		     		     
				

				@args = ("rgslccorr $params");
		
		    	system(@args)== 0 or &error_code(7);	
			}
		}     
	}	
    
    return(1);
}


1;
