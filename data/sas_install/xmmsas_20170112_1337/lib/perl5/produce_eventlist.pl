## @file
# Master file for producing event list for EPIC, RGS and OM

## @method void produce_eventlist()
# Starts and controls the production of the Event Lists for EPIC, RGS and OM.
# @return Void

#========================================================================
sub produce_eventlist(){
#.. Run epproc, emproc and rgsproc
    $logger->info("\n----> Start Analysis <----");

    $epic_pn_flag     = 0;
    $epic_mos1_flag   = 0;
    $epic_mos2_flag   = 0;
	if (($odf_object->EPN() eq "yes") || ($odf_object->EMOS1() eq "yes") || ($odf_object->EMOS2() eq "yes") ) {
		&produce_epiceventlist();
		&create_epic_filenames();
		$epic_pn_flag = &test_existance_epicfiles("EPN");
		$epic_mos1_flag = &test_existance_epicfiles("EMOS1");
		$epic_mos2_flag = &test_existance_epicfiles("EMOS2");
		
	}
	
    $epic_pn_flag_msg = "FAILED";
    $epic_mos1_flag_msg = "FAILED";
    $epic_mos2_flag_msg = "FAILED";    
	if ( lc($odf_object->EPN()) eq "no" ) {
		$epic_pn_flag_msg = "NOT DONE";
		$epic_pn_flag = 1;
	} elsif($epic_pn_flag) { 
		 $epic_pn_flag_msg = "OK";
	}
	
	if ( lc($odf_object->EMOS1()) eq "no" ) {
		$epic_mos1_flag_msg = "NOT DONE";
		$epic_mos1_flag = 1;
	} elsif ($epic_mos1_flag) {
		$epic_mos1_flag_msg = "OK";
	}
	if ( lc($odf_object->EMOS2()) eq "no" ) {
		$epic_mos2_flag_msg = "NOT DONE";
		$epic_mos2_flag = 1;
	} elsif ( $epic_mos2_flag) { 
		$epic_mos2_flag_msg = "OK";
	}
	
    $rgs1_flag      = 0;
    $rgs2_flag      = 0;
	if ( ($odf_object->RGS1() eq "yes") || ($odf_object->RGS2() eq "yes") ){  
		&produce_rgseventlist; 	
		my @test_rgs1evt=&test_rgs1eventfiles();
		$rgs1_flag = $test_rgs1evt[0];	
		my @test_rgs2evt=&test_rgs2eventfiles();
		$rgs2_flag = $test_rgs2evt[0];	

	} 
    $rgs1_flag_msg  = "FAILED";
    $rgs2_flag_msg  = "FAILED";
	if ( lc($odf_object->RGS1()) eq "no" ) {
		$rgs1_flag_msg = "NOT DONE"; 
		$rgs1_flag = 1;
	} elsif ($rgs1_flag) {
		$rgs1_flag_msg  = "OK";
	}
	if ( lc($odf_object->RGS2()) eq "no" ) {
		$rgs2_flag_msg = "NOT DONE";
		$rgs2_flag = 1;
	} elsif ($rgs2_flag) { 
		$rgs2_flag_msg  = "OK";
	}

    $om_flag       = 0;
    $om_flag_msg   = "FAILED";

    
	if(lc($odf_object->OM()) eq "yes"){ 		
		&produce_omeventlist;
		my @test_om = &test_omeventfiles();
		my @test_fom = &test_omfeventfiles();
		my @test_gom = &test_omgeventfiles();
		if ($test_om[0] || $test_fom[0] || $test_gom[0]) {
			$om_flag = 1;
		}
	} 

	if (lc($odf_object->OM()) eq "no"){ 
		$om_flag_msg = "NOT DONE"; 
		$om_flag = 1;
	} elsif($om_flag)
	{
		$om_flag_msg  = "OK";
	}


    $logger->info( "\n----> Summary of Analysis <---- ");
    $logger->info( "   \#> EPIC PN Analysis Flag : $epic_pn_flag_msg");
    $logger->info( "   \#> EPIC MOS1 Analysis Flag : $epic_mos1_flag_msg");
    $logger->info( "   \#> EPIC MOS2 Analysis Flag : $epic_mos2_flag_msg"); 
    $logger->info( "   \#> RGS1 Analysis Flag  : $rgs1_flag_msg");
    $logger->info( "   \#> RGS2 Analysis Flag  : $rgs2_flag_msg");
    $logger->info( "   \#> OM Analysis Flag   : $om_flag_msg");
    $logger->info( "------------------------------- ");

    if (!$epic_pn_flag ) {
    	&error_code(31);
    } elsif (!$epic_mos1_flag ) {
		&error_code(32);
    } elsif ( !$epic_mos2_flag ) {
		&error_code(33);
	} elsif ( !$rgs1_flag ) {
    	&error_code(34);
    } elsif ( !$rgs2_flag ) {
   	 	&error_code(35);	
    } elsif( !$om_flag){ 
		&error_code(36);
    }else { $logger->info( "\n----> Working out XMM-Newton event lists. Finished"); &error_code(0); }


    return(0);
}
1;
