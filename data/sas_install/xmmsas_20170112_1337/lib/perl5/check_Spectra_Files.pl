

sub check_GTIs_Files()
{
		my $instrument = $_[0];
		my $exposure = $_[1];
		my $mode = $_[2];
		my $type = $_[3];
		my $source_name = $_[4];
		#.. Test for existance of GTI files		

		my $flag = "epic_".$type."_flag";
	    @epic_GTI=&test_epic_gtifile($instrument,$exposure,$mode);   # EPIC	   
	    if ($epic_GTI[0]){
			@epic_infoGTI=&gti_file_inf($epic_GTI_file,$instrument);
			if ($epic_infoGTI[0] != 0.0){$epic_GTI_file=$epic_GTI[1];				
			} else {$$flag = 0;}
	    } else {$$flag = 0;}
}

sub check_Spectra_Files()
{
		my $inst = $_[0];
		my $exposure = $_[1];
		my $mode = $_[2];
		my $type = $_[3];
		my $source_name = $_[4];
		
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

		my $flag = "epic_".$type."_flag";	
	    @test_epicEvt=&test_epiceventfiles($inst,$exposure,$mode);   # EPIC Event Files
	    if ($test_epicEvt[0]) {
			$epic_event_list=$test_epicEvt[1];
			&event_file_inf($epic_event_list,$instrument,$logger);
	    } else {$$flag = 0;}
	    
}



1;
