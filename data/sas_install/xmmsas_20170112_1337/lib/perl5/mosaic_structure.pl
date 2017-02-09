#========================================================================
sub mosaic_structure(){

    use vars qw(%mosaic);
    
    tie %mosaic, "Tie::IxHash";  # Keep the order in which the data is input
        
    return(1);
}

#========================================================================
sub fill_mosaic(){

    my $obsid=$_[0];
    my $instr=$_[1];
    my $ene  =$_[2];
    my $field=$_[3];
    my $value=$_[4];
    
    $mosaic{$obsid}{$instr}{$ene}{$field}=$value;
    
    return(1);
}


#========================================================================
sub print_mosaic(){

    my $obs;
    my $instr;
    my $ene;
    my $field;
    
    print " \n";
    print "----> MOSAIC Structure Information \n";
    print " \n";
    if ($Log_Flag == 0) {
	print MYOUTFILE " \n";
	print MYOUTFILE "----> OBSID Instrument Structure Information \n";
	print MYOUTFILE " \n";
    }
    for $obs ( keys %mosaic) {
	for $instr ( keys %{ $mosaic{$obs}} ) {
	    for $ene ( keys %{ $mosaic{$obs}{$instr} } ) {
		for $field ( keys %{ $mosaic{$obs}{$instr}{$ene} } ) {
		    print "$obs : $instr : $ene : $field : $mosaic{$obs}{$instr}{$ene}{$field} \n";
		    if ($Log_Flag == 0) {print MYOUTFILE "$obs: $instr : $ene : $field : $mosaic{$obs}{$instr}{$ene}{$field} \n";}
		}   
	    }
	    print " \n";
	    if ($Log_Flag == 0) {print MYOUTFILE "\n";}
	}
    }
    
    return(1);
}

##############################################################################
sub get_evt_file(){ 
    my $instr = $_[0];
    if ($instr eq "") {return(0);}
    my $obs   = $_[1];
    if ($obs eq "") {return(0);}
	my $Master_Analysis_path = $_[2];
    #my $expid = $_[3];
    
 	my $corrinstr;
    if ($instr eq "pn") {$path=$pn_path; $corrinstr="EPN"}
    if ($instr eq "mos1"){$path=$mos_path; $corrinstr="EMOS1"}
    if ($instr eq "mos2"){$path=$mos_path; $corrinstr="EMOS2"}
	

    my $firstchar = substr $event_file, 0,1;
    if ($firstchar eq "/") {
    	$event_file = $path.$obsid_instruments{$obs}{$instr}{'EvtFile'};
    	$Master_Analysis_path="";
    }
    else
    {
	    $event_file = $obs."/".$path.$obsid_instruments{$obs}{$instr}{'EvtFile'};
    }
	    
    my $tmp = &basenamenoext($event_file);

 	$lastchar = substr $obs, length($obs)-1,1;
 	
 	if ($lastchar eq "/") {
	 	$expid = substr $obs, length($obs)-4,3;
 	} 
 	else 
 	{
 		$expid = substr $obs, length($obs)-3,3;
 	}
 
## Renamed 	
# 	$mosaicexp = $tmp."_P".$expid.".ds";
	$mosaicexp = $tmp."_AttMod.ds";  	
#    my $tmp_event_file = $Master_Analysis_path.$obs."/".$path.$revnum."_".$obsid."_".$corrinstr."_".$exp."_".$mosaicexp."_ImagingEvts.ds";
	my $tmp_event_file = $obs."/".$path.$mosaicexp;
	
    if (!-e $tmp_event_file) {          #.. Work with a copy of the event file
		system("cp","-f","$event_file","$tmp_event_file");
    }
    
    return($tmp_event_file);
}




##############################################################################
sub get_ori_evt_file(){ 
    my $instr = $_[0];
    if ($instr eq "") {return(0);}
    my $obs   = $_[1];
    if ($obs eq "") {return(0);}
	my $Master_Analysis_path = $_[2];
    #my $expid = $_[3];
    
 	my $corrinstr;
    if ($instr eq "pn") {$path=$pn_path; $corrinstr="EPN"}
    if ($instr eq "mos1"){$path=$mos_path; $corrinstr="EMOS1"}
    if ($instr eq "mos2"){$path=$mos_path; $corrinstr="EMOS2"}
	

    my $firstchar = substr $event_file, 0,1;
    if ($firstchar eq "/") {
    	$event_file = $path.$obsid_instruments{$obs}{$instr}{'EvtFile'};
    	$Master_Analysis_path="";
    }
    else
    {
	    $event_file = $obs."/".$path.$obsid_instruments{$obs}{$instr}{'EvtFile'};
    }
	    
    my $tmp = &basenamenoext($event_file);

 	$lastchar = substr $obs, length($obs)-1,1;
 	
 	if ($lastchar eq"/") {
	 	$expid = substr $obs, length($obs)-4,3;
 	} 
 	else 
 	{
 		$expid = substr $obs, length($obs)-3,3;
 	}
 	
 	$mosaicexp = $tmp."_P".$expid.".ds";
  	
	my $tmp_event_file = $obs."/".$path.$mosaicexp;
	
    return($event_file);
}

##############################################################################
sub get_prep_evt_file(){ 
    my $instr = $_[0];
    if ($instr eq "") {return(0);}
    my $obs   = $_[1];
    if ($obs eq "") {return(0);}
	my $Master_Analysis_path = $_[2];
    #my $expid = $_[3];
    
 	my $corrinstr;
    if ($instr eq "pn") {$path=$pn_path; $corrinstr="EPN"}
    if ($instr eq "mos1"){$path=$mos_path; $corrinstr="EMOS1"}
    if ($instr eq "mos2"){$path=$mos_path; $corrinstr="EMOS2"}
	
    my $event_file = $obs."/".$path.$obsid_instruments{$obs}{$instr}{'EvtFile'};
    my $tmp = &basenamenoext($event_file);
#   	my $tmp = $obsid_instruments{$obs}{$instr}{'EvtFile'};
#   	my $revnum = substr $tmp, 0,4;
#   	my $obsid = substr $tmp, 5,10;
#   	my $exp = substr $tmp, 20,4;	
 	
 	my $expid = substr $obs, length($obs)-3,3;
 	
 	$mosaicexp = $tmp."_P".$expid.".ds";
  	
#    my $tmp_event_file = $Master_Analysis_path.$obs."/".$path.$revnum."_".$obsid."_".$corrinstr."_".$exp."_".$mosaicexp."_ImagingEvts.ds";
	my $tmp_event_file = $obs."/".$path.$mosaicexp;
      
    if (!-e $tmp_event_file) {          #.. Work with a copy of the event file
	system("cp","-f","$Master_Analysis_path$event_file","$Master_Analysis_path$tmp_event_file");
    }
	
    return($tmp_event_file);
}

#========================================================================

## @method void getVersion()
# Get the version number
# @return Void

#========================================================================    
sub getVersion()
{

  my $sasTaskName = $_[0];
  	
  my $ccom="";  
  chomp(my $sasdir = `which $sasTaskName`) ;
 
  my $ii = index($sasdir,"/bin/".$sasTaskName);
  print "index $ii\n";
  if ($ii == -1) { print "Sorry, directory structure of $sasTaskName in $sasdir " .
                   "could not be recognised.\n" ; }
  else {
    $sasdir = substr($sasdir,0,$ii) ;
# Optimize to avoid searching whole directory if standard structure
    $ccom = "packages/$sasTaskName/VERSION" ;
    if ( ! -e $sasdir."/".$ccom ) {
    	 print "sasdir $sasdir\n";
      $ccom = `cd $sasdir; find . -name VERSION | grep emosaicproc` }
    if ( length($ccom) == 0 ) {
      print "Sorry, $sasTaskName 's version number was not found in $sasdir.\n" .
            "Please look in the package documentation.\n" ;
    } else {
      chomp(my $version = `cd $sasdir; cat $ccom`) ;
      $ccom = $sasdir . "/RELEASE" ;
      my $release = "" ;
      if ( -e $ccom ) { chomp($release = `cat $ccom`) }
      print "$sasTaskName $version [$release] \n" ;
    }
  }
  &do_exit(0);
	
}
## @method void usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub usage(){
#..Print Help message
	my $sasTaskName = $_[0];
    system("listparams $sasTaskName");
    my $x = $? >> 8;
       
    &do_exit(0);

}

#========================================================================

## @method void do_exit($exit_code)
# Exit analysis program
# @param exit_code Exit code to be output on exit
# @return Void

#========================================================================    
sub do_exit(){        	

#.. Define exit code

    my $exit_code = $_[0];

    exit $exit_code;
    return(0);
}


1;
