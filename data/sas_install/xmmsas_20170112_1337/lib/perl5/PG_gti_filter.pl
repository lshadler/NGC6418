## @file
# GTI Filtering based on S/N

#========================================================================
sub PG_gti_filter(){
	
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $fileMode = $_[2];
	my $expoObj = $_[3];
	my $epic_event_list = $_[4];
    
    $logger->info( "\n----> Running PG GTI Filtering for $_[0] .....");

#.. Define Global Variables
    $logger->info( "   \#> Defining File Names for PG GTI Filtering .....");

    use vars qw($intrument
		$event_list
		$bkg_event_list
		$eregionanal_file
		$image_file
		$lc_src_outfile
		$lc_bkg_outfile 
		$lc_src_counts_file
		$lc_bkg_counts_file
		$pnidl_scriptfile_name
		$m1idl_scriptfile_name
		$m2idl_scriptfile_name
		 );

		my $inst = "";
		if ($instrument eq "pn") {		 
			$inst = "EPN";
		} elsif ($instrument eq "m1") {
			$inst = "EMOS1";
		} elsif ($instrument eq "m2") {
			$inst = "EMOS2";
		}

#.. Check if the user has defined its own coordinates
	&setcoordinates();	
	
    my $source_obsid = $odf_object->getObsId;
    my $source_name  = $odf_object->getSourceName;
    my $src_ra       = $odf_object->getRA;
    my $src_dec      = $odf_object->getDEC;

    $bkg_event_list     = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_bkg_event_list.fits";
    $src_regionset      = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_src_region.ds";
    $bkg_regionset      = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_bkg_region.ds";   
    $src_list           = $images_directory.$instrument."_".$exposure."_".$fileMode."_emllist.fits";
    $image_file         = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_img_raw.img";
    $eregionanal_file   = $spectra_directory.$source_name."_".$instrument."_".$exposure."_".$fileMode."_eregionanalyse.txt";
    $lc_src_outfile     = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_lightcurve_src_newgti.fit";
    $lc_bkg_outfile     = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_lightcurve_bkg_newgti.fit";
    $lc_src_counts_file = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_lc_counts_src.txt";
    $lc_bkg_counts_file = $gti_directory."PG_".$instrument."_".$exposure."_".$fileMode."_lc_counts_bkg.txt";
	

	#.. Area Factor
	my $epic_areafactor = "PG_" . $instrument . "_areafactor";

	$event_list = $epic_event_list;	

    $logger->info( "Done.");

#.. Get Starting and Ending Time of the Observation
	
    my $mode    = $obsid_instruments{$source_obsid}{$instrument}{'mode'};
    my $submode = $obsid_instruments{$source_obsid}{$instrument}{'submode'};
    my $tstart  = $obsid_instruments{$source_obsid}{$instrument}{'starting_time'}; 
    my $tend    = $obsid_instruments{$source_obsid}{$instrument}{'ending_time'};
	
#.. Generating the ligth curve off the source and the background ...'

#.. Produce Instrument Image (needed by eregioanalyse) and also needed to create the background light curve
#.. without sources
    &produce_image($event_list,$image_file,$instrument);
	

#.. The PG optimization can be executed without the interactive mode. In case the user enables the interactive mode,
#.. we have to disable the call to eregionanalyse so the user will use their own regions.

	my($bore_img_x,$bore_img_y
	   	,$bore_optrad_asec,$bore_optradius
	   	,$bore_img_xbkg,$bore_img_ybkg
	   	,$bkg_inner_rad_asec,$bkg_inner_rad
	   	,$bkg_outer_rad_asec,$bkg_outer_rad) = (0,0,0,0,0,0,0,0,0,0);	
	
	if ($expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","GTIFiltering_interactivity")->getParam("interactivity")->getValue() eq "no")
	{
	    #.. Using the instrument image to work out the source centroid
	   
	   	($bore_img_x,$bore_img_y
	    	,$bore_optrad_asec,$bore_optradius 
	    	,$bore_img_xbkg,$bore_img_ybkg
	    	,$bkg_inner_rad_asec,$bkg_inner_rad
	    	,$bkg_outer_rad_asec,$bkg_outer_rad)
	   		=&run_eregionanalyse($image_file,$src_ra,$src_dec,$instrument,$submode,$eregionanal_file,"PG",$expoObj);
	   			
	#.. Something has gone wrong so wont produce anything
	
	    if ($bore_optrad_asec == 300){                          # Something has gone wrong so wont produce spectra. 300 is maximum allowed value.
			my $rate = 1000.;                                    # set to silly default value
			#.. Fill XML structure properly
			$expoObj->getProduct("GTIFiltering")->getTask("tabgtigen","gti_creation")->getParam("expression")->setValue("RATE&lt;=$rate");
			&error_code(10); 
			return(0);
	    }
		#.. Default source and background shapes
		$expoObj->set_bkg_region("circle");
		$expoObj->set_src_region("annulus");

	    {$expoObj->set_bkg_X($bore_img_xbkg);}    
    	{$expoObj->set_bkg_Y($bore_img_ybkg);} 
    	{$expoObj->set_bkg_innerrimg($bkg_inner_rad);}
    	{$expoObj->set_bkg_outerrimg($bkg_outer_rad);}
    	{$expoObj->set_src_X($bore_img_x);}
    	{$expoObj->set_src_Y($bore_img_y);}
    	{$expoObj->set_src_roptimg($bore_optradius);}
	}
	else
	{		
		$expoObj->set_src_roptimg($expoObj->get_src_inner_roptimg);
	}

#.. Set the values of the PG_ parameters: source/background center and radii set to the values found with eregionanalyse
	my $tbin = $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("binning")->getValue();# secs (default value)
	my $pmin = $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("minpi")->getValue();# secs (default value)	
	my $pmax = $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("maxpi")->getValue();# secs (default value)
	 
	if ($expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("tstart")->getValue() == 0)
	{
	    $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("tstart")->setValue($tstart); # secs
	} 
	if ($expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("tstart")->getValue() == 0)
	{ 
	    $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("tend")->setValue($tend); # secs
	} 


    $src_area = $pi*$expoObj->get_src_roptimg*$expoObj->get_src_roptimg;
	  
    $areaType = $expoObj->get_bkg_region();	   	      
    if (uc($areaType) eq "CIRCLE" )
    {
	    $bkg_area = $pi*$pi*$expoObj->get_bkg_innerrimg*$expoObj->get_bkg_innerrimg;				    	   
    }
    else
    {
	    $bkg_area = $pi*$expoObj->get_bkg_outerrimg*$expoObj->get_bkg_outerrimg
		- $pi*$expoObj->get_bkg_innerrimg*$expoObj->get_bkg_innerrimg;
    }
	
    my $val = 0;    		
    if ($bkg_area != 0) {$val = ($src_area/$bkg_area); }
        
    #.. Fill XML structure properly
    $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("areafactor")->setValue($val);

    $logger->info( "   \#> Source and Background Extraction Regions to be used:");
    $logger->info( "       $instrument ");
    $logger->info( "         $instrument Region SRC : ",$expoObj->get_src_region);
    $logger->info( "         $instrument SRC XC     : ",$expoObj->get_src_X);
    $logger->info( "         $instrument SRC YC     : ",$expoObj->get_src_Y);
    $logger->info( "         $instrument SRC RC     : ",$expoObj->get_src_roptimg);
    $logger->info( "         $instrument Region BKG : ",$expoObj->get_bkg_region);
    $logger->info( "         $instrument BKG XC     : ",$expoObj->get_bkg_X);
    $logger->info( "         $instrument BKG YC     : ",$expoObj->get_bkg_Y);
    $logger->info( "         $instrument BKG RC     : ",$expoObj->get_bkg_innerrimg," - ",$expoObj->get_bkg_outerrimg);
    $logger->info( "         $instrument BKG AREA SCALE FACTOR : ",$expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("areafactor")->getValue()," (Only area taken into account)");
    if ($expoObj->get_bkg_outerrimg == 6000){$logger->warn( "         WARNING : $instrument regions : Maximum allowed radius reached");}


#.. Produce background event list with sources removed to work out background rates: run edetect_chain, region and eveselect

    &get_bkg_filterset($event_list, $instrument);

#.. Produce Source and Background light Curves
 	my $optimize_SN_flag = $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("PG_optimize_SN")->getValue();	
    &PG_produce_lightcurve_file($expoObj->get_src_region,$instrument,$event_list,$lc_src_outfile,"SRC",$tbin,$tstart,$tend,$expoObj->get_src_X,$expoObj->get_src_Y,$expoObj->get_bkg_region,$expoObj->get_bkg_X,$expoObj->get_bkg_Y,$pmin,$pmax,$expoObj->get_src_roptimg,$expoObj->get_bkg_innerrimg,$expoObj->get_bkg_outerrimg);  # Source LC    
    if ( lc($optimize_SN_flag) eq "yes") {
	    &PG_produce_lightcurve_file($expoObj->get_bkg_region,$instrument,$event_list,$lc_bkg_outfile,"BKG",$tbin,$tstart,$tend,$expoObj->get_src_X,$expoObj->get_src_Y,$expoObj->get_bkg_region,$expoObj->get_bkg_X,$expoObj->get_bkg_Y,$pmin,$pmax,$expoObj->get_src_roptimg,$expoObj->get_bkg_innerrimg,$expoObj->get_bkg_outerrimg);} # BKG LC
	else {
	    &PG_produce_lightcurve_file("annulus",$instrument,$bkg_event_list,$lc_bkg_outfile,"BKG",$tbin,$tstart,$tend,$expoObj->get_src_X,$expoObj->get_src_Y,$expoObj->get_bkg_region,$expoObj->get_bkg_X,$expoObj->get_bkg_Y,$pmin,$pmax,$expoObj->get_src_roptimg,$expoObj->get_bkg_innerrimg,$expoObj->get_bkg_outerrimg);} # BKG LC
	

#.. Extraction of the Counts columns....

    &PG_extract_counts($lc_src_outfile,$lc_src_counts_file); # Source
    &PG_extract_counts($lc_bkg_outfile,$lc_bkg_counts_file); # BKG

#.. Run procedure to optimize S/N

    my $rate    = 1000.; # set to silly default value
    my $src_rad = 1000.; # set to silly default value
    my $max_sn  = 1000.; # set to silly default value 
#..    ($src_rad,$max_sn,$rate)=&PG_IDL_Optimize_SN($source_name,$instrument,$mode,$lc_src_counts_file,$lc_bkg_counts_file,$expoObj->get_src_roptimg,$expoObj->get_bkg_inerrimg,$expoObj->get_bkg_outerrimg,$tbin);
    my $areafac = $expoObj->getProduct("GTIFiltering")->getTask("xmmextractor","SN_optimization")->getParam("areafactor")->getValue();		
	
    ($src_rad,$max_sn,$rate)=&PG_Optimize_SN($source_name,$instrument,$mode,$lc_src_counts_file,$lc_bkg_counts_file,$tbin,$expoObj->get_src_roptimg,$expoObj->get_bkg_innerrimg,$expoObj->get_bkg_outerrimg,$areafac);
#.. Set the values of the correspondent GTI_ parameters 
    $logger->info( "#PG rate value calculated for $inst: $rate c/s");
    $logger->info( "This rate will be used for GTI filtering");
    $expoObj->getProduct("GTIFiltering")->getTask("tabgtigen","gti_creation")->getParam("expression")->setValue("RATE <= $rate");     

    &error_code(0);
    return(0);

}

#========================================================================
sub get_bkg_filterset(){

    my $event_list = $_[0];
    my $instr      = $_[1];

    chdir($gti_directory); 
    &run_edetectchain;
    chdir($gti_directory); 

    if ($instr eq "pn") {$expr="\#XMMEA_EP && (FLAG==0) && (PATTERN<=4) && region($bkg_regionset:REGION)";}
    if ($instr eq "m1" or $instr eq "m2") {$expr="\#XMMEA_EM && (FLAG==0) && (PATTERN<=12) && region($bkg_regionset:REGION)";}

   @args = ("region eventset=$event_list tempset=temp.ds srclisttab=$src_list operationstyle=global shrinkconfused=yes radiusstyle=contour bkgratestyle=col regionset=$src_regionset bkgregionset=$bkg_regionset");
    system(@args)== 0 or &error_code(10);

    @args = ("evselect table=$event_list filteredset=$bkg_event_list expression=\"$expr\"");
    system(@args)== 0 or &error_code(10);
    return(1);
}

#========================================================================
sub PG_produce_lightcurve_file(){
    
# Produce an event file for a given region and energy range  

    my $region     = $_[0];
    my $instr      = $_[1];
    my $event_file = $_[2];
    my $outfile    = $_[3];
    my $type       = $_[4];
    my $T          = $_[5];
    my $tstart     = $_[6];
    my $tstop      = $_[7];
    my $XC         = $_[8];
    my $YC         = $_[9];
    my $bkg_region = $_[10];
	my $BKG_XC     = $_[11];
	my $BKG_YC     = $_[12];
	my $E1         = $_[13];
    my $E2         = $_[14];
    my $RSRC       = $_[15];
    my $RBKG1      = $_[16];
    my $RBKG2      = $_[17];


    if ($instr eq "pn") {$expr="\#XMMEA_EP && (FLAG==0) && (PATTERN<=4) && (PI>=$E1) && (PI<=$E2)";}
    if ($instr eq "m1" or $instr eq "m2") {$expr="\#XMMEA_EM && (FLAG==0) && (PATTERN<=12) && (PI>=$E1) && (PI<=$E2)";}
	
	if ($type eq "SRC") 
	{
	    if (lc($region) eq "circle") {$areaexpr="((X,Y) in circle($XC,$YC,$RSRC))";}
    	if (lc($region) eq "annulus") {$areaexpr="((X,Y) in annulus($XC,$YC,$RBKG1,$RBKG2))";}
	}
	else
	{
	    if (lc($region) eq "circle") {$areaexpr="((X,Y) in circle($BKG_XC,$BKG_YC,$RBKG1))";}
    	if (lc($region) eq "annulus") {$areaexpr="((X,Y) in annulus($BKG_XC,$BKG_YC,$RBKG1,$RBKG2))";}		
	}
    $logger->info( "\n   \#> Producting Light Curve Files ... ");
    $logger->info( "     $instr : $region ($areaexpr): Energy Range: $E1 - $E2 keV ");
    $logger->info( "     $instr : $region ($areaexpr): Time Bining : $T sec");
    $logger->info( "     (Event File : $event_file )");
    $logger->info( "     (Output File: $outfile) ");
 
    @args = ("evselect table=$event_file:EVENTS withrateset=yes rateset=$outfile maketimecolumn=yes timecolumn=TIME timebinsize=$T expression=\"$expr \&\& $areaexpr\" makeratecolumn=no withtimeranges=yes timemin=$tstart timemax=$tstop");

    system(@args)== 0 or &error_code(10);
    
    return(1);
}

#========================================================================
sub PG_extract_counts(){
    
    my $event_file  = $_[0];
    my $out_file    = $_[1];

    @args = ("rm -f $out_file");
    system(@args)== 0 or &error_code(10);

    @args = ("fdump $event_file+1 $out_file \"COUNTS TIME\" - prhead=no showcol=no prdata=yes showunit=no showrow=no");
    system(@args)== 0 or &error_code(10);

    my $temp_out_file = "temp.txt";
    @args = ("grep -v \^\$ $out_file | awk '{print \$1\" \"\$2}' > $temp_out_file");
    system(@args);
    @args = ("mv -f $temp_out_file $out_file");
    system(@args);

    return(1);
}

#========================================================================
sub PG_Optimize_SN(){
   $logger->info( "    PG_Optimize_SN: ");   
    my $source_name     = $_[0];
    my $instrument      = $_[1];
    my $frame           = $_[2];
    my $src_counts_file = $_[3];
    my $bkg_counts_file = $_[4];
    $T                  = $_[5];
    $RSRC               = $_[6];
    $annulus[0]         = $_[7];
    $annulus[1]         = $_[8];
#.. Get ratio of souce to background area
    my $area_ratio = $_[9];

    $rectangle[0]  = 0.;
    $rectangle[1]  = 0.;

    my $bkg_lc_points;
    chomp($bkg_lc_points    = `grep -v \^\$ $bkg_counts_file | wc | awk '{print \$1}'`);
    my $src_lc_points;
    chomp($src_lc_points    = `grep -v \^\$ $src_counts_file | wc | awk '{print \$1}'`);

#.. Get vectors with source and background counts
    open(INPUT, "$src_counts_file") or die "Cant open output file: $! \n";    
    while (defined(my $line=<INPUT>)) {
	chomp($line);
	($cts,$t) = split/\s/,$line;
	push(@src_counts,$cts);
	push(@src_time,$t);
    }
    close(INPUT);
    open(INPUT, "$bkg_counts_file") or die "Cant open output file: $! \n";
    while(defined(my $line=<INPUT>)) {
	chomp($line);
	($cts,$t) = split/\s/,$line;
	push(@bkg_counts,$cts);
	push(@bkg_time,$t);
    }
    close(INPUT);
    
#.. Get array with bin time (should be the same length for src_counts and bkg_counts)
    for ($count = 0; $count <= $#src_counts; $count++){$time_bin_array[$count]=$T;}
    

#.. Correct Background counts by BACKSCALE
    for ($count = 0; $count <= $#bkg_counts; $count++){$bkg_scaled_counts[$count]=$area_ratio*$bkg_counts[$count];}

#.. Workout Background corrected Source Count
    for ($count = 0; $count <= $#src_counts; $count++){$bkgclean_src_counts[$count]=$src_counts[$count]-$bkg_scaled_counts[$count];} 
    
#.. Workout Count Rates
    for ($count = 0; $count <= $#time_bin_array; $count++){
	$src_ctr[$count]=$src_counts[$count]/$time_bin_array[$count];
	$bkg_ctr[$count]=$bkg_counts[$count]/$time_bin_array[$count];
	$bkg_scaled_ctr[$count]=$bkg_scaled_counts[$count]/$time_bin_array[$count];
        $bkgclean_src_ctr[$count]=$bkgclean_src_counts[$count]/$time_bin_array[$count];	
    }

#.. Workout Cumulative Time Array
    $cont     = 1;
    while ($cont <= $#time_bin_array+1){
	$cont_in    = $cont;
	$time_cum   = 0;
	while ($cont_in <= $#time_bin_array+1){
	    $time_cum  = $time_cum + $time_bin_array[$cont_in-1];
	    $cont_in++;
	}
	$cum_time_bin_array[$cont-1]  = $time_cum - $T/2.0; # Place in center of Bin
	$cont++;
    }
    @cum_time_bin_array = reverse(@cum_time_bin_array);     # Sort out in increasing order
    
#.. Output to a file these values

    my $counts_file = "PG_counts.dat";
    open(COUNTS, "> $counts_file") or die "Cant open output file: $! \n";    #open for write, overwrite
     for ($count = 0; $count <= $#cum_time_bin_array; $count++){
	 $t_bin=$count+1;
	 printf COUNTS "%d %.1f %d %d %.6f %.6f \n",$t_bin,$cum_time_bin_array[$count],$src_counts[$count],$bkg_counts[$count],$bkg_scaled_counts[$count],$bkgclean_src_counts[$count];
     }
    close(COUNTS);
    $counts_desc_file = "PG_counts_desc_file.dat";
    open(SN_DESC, "> $counts_desc_file") or die "Cant open output file: $! \n";      #open for write, overwrite
    printf SN_DESC "CHANNEL E\n";
    printf SN_DESC "TIME D Time\n";
    printf SN_DESC "SRC D Counts\n";
    printf SN_DESC "BKG D Counts\n";
    printf SN_DESC "BKG_SC D counts\n";
    printf SN_DESC "BKG_CL D Counts\n";
    close(SN_DESC);
	$out_counts_file="PG_".$source_name."_".$instrument.".fits";
	
   &create_fits_table($counts_desc_file,$counts_file,$out_counts_file,"COUNTS");
    
    
    my $rates_file = "PG_rates.dat";
    open(RATES, "> $rates_file") or die "Cant open output file: $! \n";    #open for write, overwrite
     for ($count = 0; $count <= $#cum_time_bin_array; $count++){
	 $t_bin=$count+1;
	 printf RATES "%d %.1f %.6f %.6f %.6f %.6f \n",$t_bin,$cum_time_bin_array[$count],$src_ctr[$count],$bkg_ctr[$count],$bkg_scaled_ctr[$count],$bkgclean_src_ctr[$count];
     }
    close(RATES);
  	$rates_desc_file = "PG_rates_desc_file.dat";
    open(SN_DESC, "> $rates_desc_file") or die "Cant open output file: $! \n";      #open for write, overwrite
    printf SN_DESC "CHANNEL E\n";
    printf SN_DESC "TIME D Time\n";
    printf SN_DESC "SRC D Rate\n";
    printf SN_DESC "BKG D Rate\n";
    printf SN_DESC "BKG_SC D Rate\n";
    printf SN_DESC "BKG_CL D Rate\n";
    close(SN_DESC);
	$out_rates_file="PG_rates.fits";
	
   &create_fits_table($rates_desc_file,$rates_file,$out_rates_file,"RATES");   
   
#.. Sort out in increasing order counts and count rates, according to background count rate

    my $jcont=1; 
    while ($jcont <= $#bkg_counts+1){
	$lowest = $bkg_counts[$jcont-1];
	$icont=$jcont;
	while ($icont <= $#bkg_counts+1){
	    if ($bkg_counts[$icont-1] < $lowest){
		$lowest = $bkg_counts[$icont-1];
		
		$temp   = $src_counts[$jcont-1];
		$src_counts[$jcont-1] = $src_counts[$icont-1];
		$src_counts[$icont-1] = $temp;

		$temp   = $bkg_counts[$jcont-1];
		$bkg_counts[$jcont-1] = $bkg_counts[$icont-1];
		$bkg_counts[$icont-1] = $temp;

		$temp   = $bkg_scaled_counts[$jcont-1];
		$bkg_scaled_counts[$jcont-1] = $bkg_scaled_counts[$icont-1];
		$bkg_scaled_counts[$icont-1] = $temp;	    
		
		$temp   = $bkgclean_src_counts[$jcont-1];
		$bkgclean_src_counts[$jcont-1] = $bkgclean_src_counts[$icont-1];
		$bkgclean_src_counts[$icont-1] = $temp;
		
		$temp   = $src_ctr[$jcont-1];
		$src_ctr[$jcont-1] = $src_ctr[$icont-1];
		$src_ctr[$icont-1] = $temp;
		
		$temp   = $bkg_ctr[$jcont-1];
		$bkg_ctr[$jcont-1] = $bkg_ctr[$icont-1];
		$bkg_ctr[$icont-1] = $temp;	    
		
		$temp   = $bkg_scaled_ctr[$jcont-1];
		$bkg_scaled_ctr[$jcont-1] = $bkg_scaled_ctr[$icont-1];
		$bkg_scaled_ctr[$icont-1] = $temp;	    
		
		$temp   = $bkgclean_src_ctr[$jcont-1];
		$bkgclean_src_ctr[$jcont-1] = $bkgclean_src_ctr[$icont-1];
		$bkgclean_src_ctr[$icont-1] = $temp;	   
	    }
	    $icont++;
	} 
	$jcont++;
    }

#.. Workout cumulative count and count rate vectors and S/N vector (the final vectors have to be inverted)

    $cont     = 1;
    while ($cont <= $#src_counts+1){
	$cont_in          = $cont;
	$src_cum          = 0;
	$bkg_cum          = 0;
	$bkg_scaled_cum   = 0;
	$bkgclean_src_cum = 0;
	while ($cont_in <= $#src_counts+1){
	    $src_cum          = $src_cum + $src_counts[$cont_in-1];
	    $bkg_cum          = $bkg_cum + $bkg_counts[$cont_in-1];
	    $bkg_scaled_cum   = $bkg_scaled_cum + $bkg_scaled_counts[$cont_in-1];
	    $bkgclean_src_cum = $bkgclean_src_cum + $bkgclean_src_counts[$cont_in-1];
	    $cont_in++;
	}
	$cum_src_counts[$cont-1]          = $src_cum;
	$cum_bkg_counts[$cont-1]          = $bkg_cum;
	$cum_bkg_scaled_counts[$cont-1]   = $bkg_scaled_cum;
	$cum_bkgclean_src_counts[$cont-1] = $bkgclean_src_cum;

	$sn[$cont-1] = ($cum_src_counts[$cont-1]-$area_ratio*$cum_bkg_counts[$cont-1])
	    /sqrt($cum_src_counts[$cont-1]+$area_ratio*$area_ratio*$cum_bkg_counts[$cont-1]); 
	$cont++;
    }

    @cum_src_counts          = reverse(@cum_src_counts);
    @cum_bkg_counts          = reverse(@cum_bkg_counts);
    @cum_bkg_scaled_counts   = reverse(@cum_bkg_scaled_counts);
    @cum_bkgclean_src_counts = reverse(@cum_bkgclean_src_counts);
    @sn                      = reverse(@sn);

    for ($count = 0; $count <= $#cum_src_counts; $count++){
	$cum_src_ctr[$count]=$cum_src_counts[$count]/$cum_time_bin_array[$count];
	$cum_bkg_ctr[$count]=$cum_bkg_counts[$count]/$cum_time_bin_array[$count];  
	$cum_bkg_scaled_ctr[$count]=$cum_bkg_scaled_counts[$count]/$cum_time_bin_array[$count];
        $cum_bkgclean_src_ctr[$count]=$cum_bkgclean_src_counts[$count]/$cum_time_bin_array[$count];	
    }

 #.. Percentage vectors

    $max_sn = 0;
    $cont   = 1;
    while ($cont <= $#sn+1){                   # get maximum s/n
	$i = $sn[$cont-1];
	if ($i > $max_sn){$max_sn = $i; $max_sn_index = $cont-1;}
	$cont++;
    }
    $max_t = 0;
    $cont   = 1;
    while ($cont <= $#cum_time_bin_array+1){   # get maximum time
	$i = $cum_time_bin_array[$cont-1];
	if ($i > $max_t){$max_t = $i; $max_t_index = $cont-1;}
	$cont++;
    } 

    $cont   = 1;
    while ($cont <= $#sn+1){  
	$per_sn[$cont-1]                     = 100.0*($sn[$cont-1]/$max_sn);                       # Signal to Noise
	$per_cum_time_bin_array[$cont-1]     = 100.0*($cum_time_bin_array[$cont-1]/$max_t);
	$per_ratio_bkg_src_counts[$cont-1]   = 100.0*($cum_bkg_scaled_counts[$cont-1]/$cum_bkgclean_src_counts[$cont-1]);        # Ratio Background to Source
	$per_bkgclean_src_counts[$cont-1]    = 100.0*($cum_bkgclean_src_counts[$cont-1]/$cum_bkgclean_src_counts[$max_t_index]); # Source Counts
	$per_bkg_scaled_counts[$cont-1]      = 100.0*($cum_bkg_scaled_counts[$cont-1]/$cum_bkg_scaled_counts[$max_t_index]);     # Background Counts
	$per_bkgclean_src_counts_te[$cont-1] = $cum_time_bin_array[$cont-1]*($cum_bkgclean_src_counts[$max_t_index]/$max_t);     # Source Counts Theoretical
	$cont++;
    }

    $cont   = 1;
    while ($cont <= $#sn+1){ 
	$per_per_ratio_bkg_src_counts[$cont-1]   = 100.0*($per_ratio_bkg_src_counts[$cont-1]/$per_ratio_bkg_src_counts[$max_t_index]); # Background to Source	
	$per_per_bkgclean_src_counts_te[$cont-1] = 100.0*($per_bkgclean_src_counts_te[$cont-1]/$per_bkgclean_src_counts_te[$max_t_index]);         
	$cont++;
    }

#.. Output Some Information

    $logger->info( "   \#> PG Summary ");
    $logger->info( "      Max S/N                                       : $max_sn ");
    $logger->info( "      Optimum Background Count Rate Cut (cts/sec)   : $bkg_ctr[$max_sn_index]");
    $logger->info( "       At this Background Count Rate Cut: "); 
    $logger->info( "        Source Radius (image units)                 : $RSRC ");
    $logger->info( "        Inner Annulus Radius (image units)          : $annulus[0]");
    $logger->info( "        Outer Annulus Radius (image units)          : $annulus[1]");
    $logger->info( "        Ratio Source/BKG Region                     : $area_ratio");
    $logger->info( "        Counts Source Region (cts)                  : $cum_src_counts[$max_sn_index]");
    $logger->info( "        Total Background Counts (cts)               : $cum_bkg_counts[$max_sn_index]");
    $logger->info( "        Background Counts Source Region(cts)        : $cum_bkg_scaled_counts[$max_sn_index]");
    $logger->info( "        Exposure Time (sec)                         : $cum_time_bin_array[$max_sn_index]");

    my $sn_file = "PG_sn.dat";
    open(SN, "> $sn_file") or die "Cant open output file: $! \n";      #open for write, overwrite
      for ($count = 0; $count <= $#time_bin_array; $count++){
         $t_bin=$count+1;
         printf SN "%d %.6f %.6f %.6f \n",$t_bin,$bkg_ctr[$count],$sn[$count],$per_ratio_bkg_src_counts[$count]
     }
    close(SN);
#.. Create FITS Table
#.. We use the standard ftool program "fcreate" to create a fits file from the ASCII file
#.. First we have to create a file with the column description file called 
    $sn_desc_file = "PG_sn_desc_file.dat";
    open(SN_DESC, "> $sn_desc_file") or die "Cant open output file: $! \n";      #open for write, overwrite
    printf SN_DESC "CHANNEL E\n";
    printf SN_DESC "BKG D Rate\n";
    printf SN_DESC "SN D Signal2Noise\n";
    printf SN_DESC "ratio D \n";
    close(SN_DESC);
	$out_sn_file="PG_sn.fits";
	
   &create_fits_table($sn_desc_file,$sn_file,$out_sn_file,"Signal2Noise");    
    
    my $per_file = "PG_percentages.dat";
    open(PER, "> $per_file") or die "Cant open output file: $! \n";    #open for write, overwrite
     for ($count = 0; $count <= $#time_bin_array; $count++){
	 $t_bin=$count+1;
	 printf PER "%.6f %.6f %.6f %.6f %.6f\n",$bkg_ctr[$count],$per_per_ratio_bkg_src_counts[$count],$per_bkgclean_src_counts[$count],$per_bkg_scaled_counts[$count],$per_per_bkgclean_src_counts_te[$count]
     }
    close(PER);

 	$percent_desc_file = "PG_percentages_desc_file.dat";
    open(SN_DESC, "> $percent_desc_file") or die "Cant open output file: $! \n";      #open for write, overwrite   
    printf SN_DESC "BKG D Rate\n";
    printf SN_DESC "PER D Percentage\n";
    printf SN_DESC "PER_BKGCL D Percentage\n";    
    printf SN_DESC "PER_BKGSC D Percentage\n";
    printf SN_DESC "PP_BKGCL D Percentage\n";
    close(SN_DESC);
	$out_per_file="PG_percentages.fits";
	
   &create_fits_table($percent_desc_file,$per_file,$out_per_file,"PERCENT");

   &merge_fits_files($out_counts_file,$out_rates_file,$out_sn_file,$out_per_file);

    return($RSRC,$max_sn,$bkg_ctr[$max_sn_index]);
}
#========================================================================
sub create_fits_table{
# Use files: PG_rates(1st,2nd plots) dat PG_sn.dat(3rd,4th plots) PG_percentages.dat(5rd,6th,7th,8th plots
#..    fcreate TMPJNKtempl TMPJNKdata TMPJNKfits2 extname="PG"; 
    $logger->info( "PG: Creating FITS files ");
    $desc_file = $_[0];
    $sn_file = $_[1];
    $out_file= $_[2];   
    $ext_name = $_[3];
    
    @args = ("fcreate $desc_file $sn_file $out_file clobber=yes extname=$ext_name" ) ;
    system(@args) == 0 or &error_code(10);    
    return(1);
}

#========================================================================
#========================================================================
sub merge_fits_files{
# Use files: PG_rates(1st,2nd plots) dat PG_sn.dat(3rd,4th plots) PG_percentages.dat(5rd,6th,7th,8th plots
#..    fcreate TMPJNKtempl TMPJNKdata TMPJNKfits2 extname="PG"; 
      $logger->info( "PG: Merging FITS files ");
    $file1 = $_[0];
    $file2 = $_[1]."[1]";
    $file3= $_[2]."[1]";   
    $file4 = $_[3]."[1]";

	$file_append=$file1."[1]";
    @args = ("fappend $file2 $file_append" ) ;
    system(@args) == 0 or &error_code(10);
    $file_append=$file1."[2]";
    @args = ("fappend $file3 $file_append" ) ;
    system(@args) == 0 or &error_code(10);
    $file_append=$file1."[3]";
    @args = ("fappend $file4 $file_append" ) ;
    system(@args) == 0 or &error_code(10);    
 
    return(1);
}

#========================================================================
sub PG_IDL_Optimize_SN(){
    
    my $source_name     = $_[0];
    my $instrument      = $_[1];
    my $frame           = $_[2];
    my $src_counts_file = $_[3];
    my $bkg_counts_file = $_[4];
    $RSRC          = $_[5];
    $annulus[0]    = $_[6];
    $annulus[1]    = $_[7];
    $T             = $_[8];
    my $lc_points;
    chomp($lc_points    = `grep -v \^\$ $bkg_counts_file | wc | awk '{print \$1}'`);

    my $opt = 0;
    if ($frame eq "PrimeFullWindowExtended" || $frame eq "PrimeFullWindow") {
	$opt = 1;
    } elsif ($frame eq "PrimeLargeWindow") {
	$opt = 2;
    } elsif ($frame eq "PrimeSmallWindow" || $frame eq "PrimePartialW2") {
	$opt = 3;
    }
 
    

    $rectangle[0]  = 0.;
    $rectangle[1]  = 0.;
    
    my $idl_init_file     = $Script_directory."xmm_idl_init.pro";
    my $idl_logfile_name  = $gti_directory."PG_gti_new.log";

    my $templatefile_name  = $Script_directory."IDL\_gti\_new\.template";      # Master template file
    my $scriptfile_name    = $Script_directory."default\.pro";
    if ($instrument eq "pn")   {$scriptfile_name = $pnidl_scriptfile_name;}           
    if ($instrument eq "m1") {$scriptfile_name = $m1idl_scriptfile_name;}           
    if ($instrument eq "m2") {$scriptfile_name = $m2idl_scriptfile_name;} 

    open MASTER_TEMPLATE,  "<$templatefile_name";
    open OUTPUT,           ">$scriptfile_name ";
    
    while (defined(my $template_line=<MASTER_TEMPLATE>)) {
	chomp($template_line);
	$template_line =~ s/%P1\b/$source_name/g;
	$template_line =~ s/%P2\b/PG/g;
    	$template_line =~ s/%P3\b/$lc_points/g;
    	$template_line =~ s/%P4\b/$src_counts_file/g;
    	$template_line =~ s/%P5\b/$bkg_counts_file/g;
    	$template_line =~ s/%P6\b/$T/g;
    	$template_line =~ s/%P7\b/$opt/g;
    	$template_line =~ s/%P8\b/$RSRC/g;
    	$template_line =~ s/%P9\b/0/g;
    	$template_line =~ s/%P10\b/$rectangle[0]/g;
    	$template_line =~ s/%P11\b/$rectangle[1]/g;
    	$template_line =~ s/%P12\b/$annulus[0]/g;
    	$template_line =~ s/%P13\b/$annulus[1]/g;    	
	$template_line =~ s/%P14\b/$instrument/g;
	$template_line =~ s/%P15\b/$idl_logfile_name/g;
	print OUTPUT "$template_line \n";
    }
    close(OUTPUT);
    close(MASTER_TEMPLATE);

    @args = ("idl $idl_init_file $scriptfile_name");
    system(@args) == 0 or &error_code(10);

#. Read IDL log file
    $src_rad       = $RSRC; # default
    $max_sn        = 1000.; # default
    $bkg_count_rate= 1000.; # default

    open INFO,  "<$idl_logfile_name";
    while (defined(my $template_line=<INFO>)) {
	chomp($template_line);
	@split = split/:/,$template_line;
	if ($template_line =~ m/^SourceRadius/i){$src_rad=$split[1]; $src_rad =~ s/\s+//;}
	if ($template_line =~ m/^Max_SN/i){$max_sn=$split[1]; $max_sn =~ s/\s+//;}
	if ($template_line =~ m/^CountRate/i){$bkg_count_rate=$split[1]; $bkg_count_rate=~ s/\s+//;}
    }
    close(INFO);

    return($src_rad,$max_sn,$bkg_count_rate);
}
1;
