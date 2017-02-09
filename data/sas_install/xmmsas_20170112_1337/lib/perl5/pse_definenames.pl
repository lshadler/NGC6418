## @method void define_names()
# Define directory and file names
# @return Void

#========================================================================
sub pse_definenames() {

    use vars qw(
   	 $analysis_action 
    	$Analysis_directory 
		$results_directory 
		$images_directory  
		$spectra_directory 
		$gti_directory     
		$lcurve_directory  
		$pn_directory      
		$mos_directory   
		$rgs_directory   
		$om_directory   
		$epatplot_directory
		$analysis_log
		);
		
#.. Define Working Directories    
    $results_directory   = $Analysis_directory."results/";
    $images_directory    = $Analysis_directory."images/";
    $spectra_directory   = $Analysis_directory."spectra/";
    $gti_directory       = $Analysis_directory."gti/";
    $lcurve_directory    = $Analysis_directory."lcurve/";
    $pn_directory        = $Analysis_directory."pn/";
    $mos_directory       = $Analysis_directory."mos/";
    $rgs_directory       = $Analysis_directory."rgs/";
    $om_directory        = $Analysis_directory."om/";
    $epatplot_directory  = $Analysis_directory."epatplot/";

#.. Log File path and name
    $analysis_log        = $Analysis_directory."analysis\_".$odf_object->getObsId."\_".$odf_object->getSourceName."_".$analysis_action."\.log";	
    return(0);
}


sub create_epic_filenames()
{
	my @files = &get_EPIC_eventfiles();
}

## @method get_EPIC_eventfiles()
# Get the EPIC-pn Imaging Event List
# @return File Names

#========================================================================
sub get_EPIC_eventfiles() {
	
	my @instruments = ("EPN","EMOS1","EMOS2");
	my @modes = ("ImagingEvts","TimingEvts");
	my @EPIC_Evtlist;
	foreach my $inst (@instruments)
	{
		if ($inst eq "EPN") { 
			chdir($pn_directory);}
		else{ 
			chdir($mos_directory);}
		
		foreach my $mode (@modes)
		{
			my $match = "*".$inst."*".$mode.".ds";

			my @evtlist = glob($match);

			if ( $#evtlist >= 0 ) 
			{
				$logger->info( "   \#> (Instrument: $inst mode: $mode) Event List found: ");
				foreach (@evtlist) { $logger->info( "\t" . $_ ); }

				 push(@EPIC_Evtlist, @evtlist);		
			}
			else 
			{
				$logger->info( "   \#> $inst $mode Event List not found ");		
			}
		}	
	}
	return ( @EPIC_Evtlist );
}

## @method get_File_Info()
# Get the Exposure, Instrument and mode of a file
# @param EPIC file name
# @return $inst, $exposure, $mode
sub get_File_Info()
{
	my $file = $_[0];
	my @pn_chop = (16,20,25,3);
	my @mos_chop = (16,22,27,5);
	my @chop;
	my $length = 11;	
	if ($file =~ m/EPN/) {
		@chop = @pn_chop; 
	}
	else
	{
		@chop = @mos_chop;			
	}

	if ($file =~ m/Timing/) {
		$length = 10;
	}
	my $expo =  substr $file,  $chop[1], 4;
	my $mode = substr $file,  $chop[2], $length;	
	my $inst = substr $file,  $chop[0], $chop[3];	
	

	return($inst,$expo,$mode);
}


## @method get_EPIC_Exposures()
# Create a Hash with all the exposures and the corresponding instrument
# @param EPIC file name array
# @return expoure Hashmap
sub get_EPIC_Exposures()
{
	my %exposures = ();
	my %instruments = ();
	
	my @pn_chop = (16,20,25,3);
	my @mos_chop = (16,22,27,5);
	my @chop;
	my $length = 11;	
	my $old_inst = "";
	my $counter = 0;
	foreach my $file (@_)
	{		
		if ($file =~ m/EPN/) {
			@chop = @pn_chop; 
		}
		else
		{
			@chop = @mos_chop;			
		}

		if ($file =~ m/Timing/) {
			$length = 10;
		}
		else {
			$length = 11;
		}
		my $expo =  substr $file,  $chop[1], 4;
	
		my $mode = substr $file,  $chop[2], $length;
			
		my $inst = substr $file,  $chop[0], $chop[3];
	
		#initial instrument value
		if ($counter == 0) 
		{
			$old_inst=$inst;
		}
		#Check if we have to reset the instrument hash map
		if ($inst ne $old_inst) {
			%instruments = ();
		}
		
		
		push( @{$instruments{$expo}}, $mode );		
		push( @{$exposures{$inst}}, %instruments );

		$counter = $counter + 1;				
 		$old_inst = $inst;
		
	}
	
	return (%exposures);	
}



## @method create_pnProductFileNames($instrumet,$exposure,$mode)
# Create the PN product file names.
# @param instrument
# @param exposure
# @param mode
# @return void

#========================================================================

sub create_pnProductFileNames()
{
	my $instrument = $_[0];
	my $exposure = $_[1];
	my $mode = $_[2];
	
    use vars qw(
	$epic_gti_cleanevents_file         	  
	$epic_gti_image_file               	  
	$epic_gti_smoothimage_file
	$epic_fullimage
	$epic_emllist_file
	$epic_eboxllist_file
	$epic_eboxmlist_file
	$source_epicregion_file        	  
	$epic_eregionanal_file 
	$epic_ecoordconv_file            	  
	$epic_spectral_image_psfile        	  
	$epic_spectral_pileupimage_psfile  	  
	$epic_spectral_region_file       	  
	$epic_spectral_bkgregion_file    
	$epic_spectral_combinedregion_file    
	$epic_ancillary_file               	  
	$epic_redistribution_matrix_file   	  
	$epic_sourcebkgspectrum_file           	  
	$epic_bkgspectrum_file                      	  
	$epic_spectrum_psfile   
	$epic_emllist_file
	$source_epic_region_file
	);
	
	$epic_gti_cleanevents_file         = $gti_directory.$instrument."_".$exposure."_".$mode."_events_gtifiltered.fit";  		       
    $epic_gti_image_file               = $gti_directory.$instrument."_".$exposure."_".$mode."_img_gtifiltered.img";			       
    $epic_gti_smoothimage_file         = $gti_directory.$instrument."_".$exposure."_".$mode."_img_gtifiltered_smooth.img";		       
    $epic_eregionanal_file             = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_eregionanalyse.txt"; 
    $epic_ecoordconv_file              = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_ecoordconv.txt";   
    $epic_emllist_file                 = $images_directory.$instrument."_".$exposure."_".$mode."_emllist\.fits";
    $source_epic_region_file           = $images_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_region\.reg";

    $epic_fullimage      = $images_directory.$instrument."_".$exposure."_".$mode."_image_full\.fits";   
    $epic_emllist_file   = $images_directory.$instrument."_".$exposure."_".$mode."_emllist\.fits";
    $epic_eboxllist_file = $images_directory.$instrument."_".$exposure."_".$mode."_eboxlist_l\.fits";
    $epic_eboxmlist_file = $images_directory.$instrument."_".$exposure."_".$mode."_eboxlist_m\.fits";    		
  	$source_epicregion_file   = $images_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_region\.reg";    
        
    $epic_spectral_image_psfile        = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode.".ps";		       
    $epic_spectral_pileupimage_psfile  = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_pileup.ps";				       
    $epic_spectral_region_file         = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_region.reg";	       
    $epic_spectral_bkgregion_file      = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_bkgregion.reg"; 
    $epic_spectral_combinedregion_file = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_combinedregion.reg"; 
    $epic_ancillary_file               = $odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_src.arf";		       
    $epic_redistribution_matrix_file   = $odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_src.rmf";		       
    $epic_sourcebkgspectrum_file       = $odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_source_spectrum.fits";     
    $epic_bkgspectrum_file             = $odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_background_spectrum.fits"; 
    $epic_spectrum_psfile              = $spectra_directory.$odf_object->getSourceName."_".$instrument."_".$exposure."_".$mode."_spectrum.ps";              
	
}

1;
