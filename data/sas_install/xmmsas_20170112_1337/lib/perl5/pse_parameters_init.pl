## @file
# Initialize analysis parameters

#========================================================================
sub pse_parameters_init(){

#.. Read Script Options  
    my $line="@ARGV"; 
    my @save;
    my $source_name; my $source_obsID; my $source_ra; my $source_dec;
    if ( @save = grep /^\-p/ , @ARGV) {
       &pse_usage();
    };

    if ( @save = grep /^-d/ , @ARGV) {
#	     system("sasdialog $name");
#		 my $x = $? >> 8;
#    	 exit($x);
		$logger->info( "Option not yet implemented.");      
    }


#.. Default parameters (Start)
    
#.. Get the file name
	my $file = "";
    if ( @save = grep /^paramfile=/ , @ARGV) {
      $file  ="$save[-1]";
      $file  =~ s/^.*=//; 
    }else { &error_code(101); }
	
    if ( @save = grep /^outputfile=/ , @ARGV) {
      $outputfile  ="$save[-1]";
      $outputfile  =~ s/^.*=//; 
    }else { $outputfile="default"; }

	
    return($file);
}
1;
