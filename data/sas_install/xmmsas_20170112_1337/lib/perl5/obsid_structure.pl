#========================================================================
sub obsid_structure(){

    use vars qw(%obsid_instruments);
    
    tie %obsid_instruments, "Tie::IxHash";  # Keep the order in which the data is input
        
    return(1);
}

#========================================================================
sub fill_structure(){

    my $obsid=$_[0];
    my $instr=$_[1];
    my $field=$_[2];
    my $value=$_[3];
    
    $obsid_instruments{$obsid}{$instr}{$field}=$value;
    
    return(1);
}
#========================================================================
sub print_obsid_instruments(){

    my $obs;
    my $instr;
    my $field;
    
    print " \n";
    print "----> OBSID Instrument Structure Information \n";
    print " \n";
    if ($Log_Flag == 0) {
	print MYOUTFILE " \n";
	print MYOUTFILE "----> OBSID Instrument Structure Information \n";
	print MYOUTFILE " \n";
    }
    for $obs ( keys %obsid_instruments) {
	for $instr ( keys %{ $obsid_instruments{$obs}} ) {
	    for $field ( keys %{ $obsid_instruments{$obs}{$instr} } ) {
		print "$obs : $instr : $field : $obsid_instruments{$obs}{$instr}{$field} \n";
		if ($Log_Flag == 0) {print MYOUTFILE "$obs: $instr : $field : $obsid_instruments{$obs}{$instr}{$field} \n";}
	    }
	    print " \n";
	    if ($Log_Flag == 0) {print MYOUTFILE "\n";}
	}
    }
    
    return(1);
}

##############################################################################
sub get_singlegti_positions_file(){
    my $instr = $_[0];
    if ($instr eq "") {return(0);}
    my $obs   = $_[1];
    if ($obs eq "") {return(0);}
    
    return($Master_Analysis_path.$obs."/".$gti_path.$obsid_instruments{$obs}{$instr}{'GTIFile_P'});
    return(1);    
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
		     '100' => "   \#> Error: param not found",
		     '101' => "   \#> Error: No event files introduced",
		     '102' => "   \#> Error: gti file with START and STOP time for pointing $obs not found",
		     '103' => "   \#> Error: No ATS file found. Please check SAS_ODF variable",
		     '105' => "   \#> Error: No Attitude file found. Please, use the Attitude file produced by [ep,em]proc or [ep,em]chain",
		     '255' => "   \#> Error: Running psechain",
		     );     

   if (defined $error_code{$error_signal}) {
	my $msg = $error_code{$error_signal};
	print "$msg\n";
	if ($Log_Flag == 0){ print MYOUTFILE "$msg\n";}
	if ($error_signal != 0) {&do_exit($error_signal);}
    } else {
	my $msg = "   \#> Error option not recognized.\n";
	print "$msg\n";
	if ($Log_Flag == 0) {print MYOUTFILE "$msg\n";}
	&error_code(255);
    } 

    return(0);
}

## @method getFile()
# Test for the existence of a SUM.SAS file
# @return File Name

#========================================================================
sub getFile{ 
	my $Analysis_directory = $_[0];
	my $file = $_[1];
    print "   #> Checking existence of $file file in $Analysis_directory... "; 
    chdir ($Analysis_directory);
    @SAS_list         = glob("*".$file."*");
    if ($#SAS_list == 0) {                    
	my $myfile = $SAS_list[0];
	print "OK\n";
	return (1,$myfile);
    }     
    print "DOES NOT EXIST \n"; 
   
    return (0,"No File");
}

#========================================================================
sub getCCFFile{ 

    print "   #> Checking existence of $_[0] file... "; 

    @ccf_file =$ENV{'SAS_CCF'};
     
    if ($#ccf_file == 0) {                    
		print "OK\n";
		return (1,$ccf_file[0]);
    }     
    print "DOES NOT EXIST \n"; 
    return (0,"No File");
}

#========================================================================
sub getSUMFile{ 

    print "   #> Checking existence of $_[0] file... "; 

    @sas_file =$ENV{'SAS_ODF'};
     
    if ($#sas_file == 0) {                    
		print "OK\n";
		return (1,$sas_file[0]);
    }     
    print "DOES NOT EXIST \n"; 
    return (0,"No File");
}

#========================================================================
sub getATSFile{ 

    print "   #> Checking existence of $_[1] file... "; 
	my $sum_sas = $_[0];
	my $file = $_[1];
    chomp (my $odfdir = `grep PATH $sum_sas | awk '{print \$2}'`);
    chdir ($odfdir);
    @SAS_list = glob("*".$file."*");
    if ($#SAS_list == 0) {                    
		my $myfile = $odfdir."/".$SAS_list[0];
		print "OK\n";
		return (1,$myfile);
    }     
    print "DOES NOT EXIST \n"; 
    return (0,"No File");
}

sub basename($) {
 my $file = shift;
 $file =~ s!^(?:.*/)?(.+?)(?:\.[^.])?$!$1!;
 return $file;
}

sub basenamenoext($) {
 my $file = shift;
 $file =~ s!^(?:.*/)?(.+?)(?:\.[^.]*)?$!$1!;
 return $file;

}

sub dirname() {
	my $file = $_[0];
	my $extra_path = $_[1]; 
	$file =~ s!/?[^/]*/*$!!; 
	if (length($file) == 0) {
		$file = ".";
	}
	
	my $char = substr $file, 0,1;
	
	if ($char ne "/")
	{
#		my @Dir = split(/\//, $file);
#		$file = $Dir[$#Dir];
		my $newFile = $extra_path.$file;
		$file = $newFile;
	}
	return $file."/"; 
}

1;
