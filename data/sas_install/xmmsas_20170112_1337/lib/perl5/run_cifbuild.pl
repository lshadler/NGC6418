## @file
# Run the SAS tasks cifbuild and odfingest

## @method void run_cifbuild()
# Runs the SAS tasks cifbuild and odfingest
# @return Void

#========================================================================
sub run_cifbuild(){
	#... Check if HEASOFT is set.
	&check_HEASOFT();
	#.. Check if SAS_ODF is set.
	&check_SASODF();
	
    chdir ($Analysis_directory);

#.. Run cifbuild
    $logger->info("\n----> Running cifbuild ..... ");

#.. Print sas_setup
    &print_sas_setup();

#.. Test for ccf file
    @test_ccf=&test_ccf();
    my $ccffile=$test_ccf[1];
    if ($test_ccf[0]) {             # If ccf file already exist ...

		$logger->info("   \#> ccf File has already been produced ..... ");
	
		&set_ccf($ccffile);

		$logger->info("   \#> ccf File: $ccffile ");
		$logger->info("   \#> cifbuild OK:");
    } else {                       # If ccf file does not exist ...

		@args = ("cifbuild","withccfpath=yes","ccfpath=$ENV{'SAS_CCFPATH'}","fullpath=yes"); 
		system(@args) == 0 or &error_code(2);
	
	#.. Test for ccf file. 	
		@test_ccf=&test_ccf();
		my $ccffile=$test_ccf[1];
		if ($test_ccf[0]) {
	
		    &set_ccf($ccffile);
		    $logger->info("   \#> ccf File: $ccffile");
		    $logger->info("   \#> cifbuild OK");	   	   
		} else {
		    $logger->error("   \#> File $ccffile does not exist .... Exiting");
		    &error_code(2);	
		}

    }


#.. Run odfingest
    $logger->info("\n----> Running odfingest .....");

#.. Test for odfingest file first and delete if it exist, i.e., ALWAYS run odfingest
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];

    if (!$test_odfingest[0]){
#.. Run odfingest
	    &run_odfingest();  
	    #.. Test for odfingest file.     
    	@test_odfingest=&test_odfingest();
    	$odfingestfile=$test_odfingest[1];  
    }

    if ($test_odfingest[0]) { 

		$logger->info("   \#> Summary File: $odfingestfile "); 
		
		&set_odfingest($odfingestfile);
		$logger->info("   \#> odfingest OK ");

    } else {
	
		$logger->error("   \#> odfingest file does not exist .... Exiting ");
		&error_code(2);
	
    }
    $logger->info( "\n----> Working out cifbuild and odfingest. Finished");
    &error_code(0) && return;
}

## @method void run_odfingest()
# Runs the SAS tasks odfingest
# @return Void

#========================================================================
sub run_odfingest(){
    @args = ("odfingest");
    system(@args) == 0 or &error_code(2);
    return(1);
}

## @method test_ccf()
# Test for the existance of a CCF file
# @return File Name

#========================================================================
sub test_ccf{
    $logger->info("   #> Checking existance of CCF file ... "); 
    chdir ($Analysis_directory);
    my $ccffile = $Analysis_directory."ccf.cif";
    if (-e $ccffile) {    
		$logger->info("File found"); 
		return(1,$ccffile);
    }
    $logger->info("CCF File DOES NOT EXIST ... Running ..."); 
    return(0,"No File");
}

## @method void set_ccf()
# Sets the environment variable SAS_CCF
# @return Void

#========================================================================
sub set_ccf{
    $ENV{'SAS_CCF'} = $_[0];
    $logger->info("   \#> SAS_CCF: $ENV{'SAS_CCF'}");
    return(1);
}

## @method check_SASODF()
# Test for the existance of a SAS_ODF enviroment variable
# 

#========================================================================
sub check_SASODF{ 
	$logger->info("   #> Checking existance of SAS_ODF environment variable ...");
    if (!exists $ENV{'SAS_ODF'})
	{
		$logger->error("   #> SAS_ODF environment variable does not exist ...");
		$logger->error("   #> Please, set the SAS_ODF enviroment variable.");
		&error_code(1);
	} 
	else
	{
		#... Check if the directory exists...
		if (-d $ENV{'SAS_ODF'}) {
			$logger->info("   #> \$SAS_ODF = $ENV{'SAS_ODF'} ... DONE");
		}
		elsif (-e $ENV{'SAS_ODF'} ) {
			$logger->info("   #> \$SAS_ODF = $ENV{'SAS_ODF'} ... DONE");
		}
		else {
			$logger->error("   #> The directory \$SAS_ODF = $ENV{'SAS_ODF'} does not exists...");
			&error_code(1);
		}
				
	}
}

## @method check_HEASOFT()
# Test for the existance of a HEASOFT software
# 

#========================================================================
sub check_HEASOFT{ 
	$logger->info("   #> Checking existance of HEASOFT software ... ");
    if (!exists $ENV{'HEADAS'})
	{
		$logger->error("   #> HEADAS environment variable does not exist ... ");
		$logger->error("   #> Please, set the HEADAS enviroment variable and initialize the software.");
		&error_code(2);
	} 
	else
	{
		$logger->info("   #> \$HEADAS = $ENV{'HEADAS'} ... DONE");
				
	}

}

## @method test_odfingest()
# Test for the existance of a SUM.SAS file
# @return File Name

#========================================================================
sub test_odfingest{ 

    $logger->info("   #> Checking existance of SUM.SAS file ... "); 
    chdir ($Analysis_directory);
    @SAS_list         = glob('*SUM.SAS');
    if ($#SAS_list == 0) {                    
	my $odfingestfile = $Analysis_directory.$SAS_list[0];
	$logger->info("File found.");
	return (1,$odfingestfile);
    }     
    $logger->info("SUM.SAS file DOES NOT EXIST ... Running..."); 
    return (0,"No File");
}

## @method void set_odfingest()
# Sets the environment variable SAS_ODF
# @return Void

#========================================================================
sub set_odfingest{
    $ENV{'SAS_ODF'} = $_[0];
    $logger->info("   \#> NEW SAS_ODF: $ENV{'SAS_ODF'} ");
    return(1);
}
1;
