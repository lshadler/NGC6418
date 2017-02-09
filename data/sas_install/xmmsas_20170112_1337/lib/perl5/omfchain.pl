#! /usr/bin/perl -w
#
# OMFCHAIN
#
# XMM Pipeline Processing System OMFCHAIN script
#
# Author: Jon Rainger (jfr@mssl.ucl.ac.uk)
#         Vladimir Yershov (vny@mssl.ucl.ac.uk) May 31, 2001
#
# Description: This script runs the tasks required for to produce
#              PPS products from Fast Mode ODFs.
# Usage: 
#  PPSSUMM -infile input_filename -outfile output_filename -noclobber noclobber
#
# $Id: module.f90,v 2.0 2001/05/31 10:21:08 gvacanti Exp $
#
#
# 16.05.2001 VNY - Modified output file names 
# 21.05.2001 VNY - Converts output PS graph to PDF 
# 25.05.2001 VNY - Produces time series and PDF-files for all sources detected in the window 
# 28.05.2001 VNY - INT-file extention has been replaced with FIT (files BGDREG, BGRATE, SRCREG, SCRATE)
# 29.05.2001 VNY - tmp_eventlist_1 was replaced with  $PPS_eventlist_file in the second call for the OMPREP routine.
# 31.05.2001 VNY - omfchain to be called as a subroutine  
# 31.05.2001 VNY - conversion of the output OSW images to the sky coordinates   
# 05.06.2001 VNY - two new parameteres have been added to omlcbuild: wdxset and sourcelistset
#                    (in order to correct the photoun counts)
# 06.06.2001 VNY - omlcbuild calculates correction for the counts loss
# 27.06.2001 VNY - Magnitudes are calculated for the light curve
# 03.07.2001 VNY - input file check flags added
# 04.07.2001 VNY - dummy flat field file created (FFX) in case it doesn't exist
# 04.07.2001 VNY - dealing with the absence of the tracking history file
# 05.07.2001 VNY - bkginner=2 bkgouter=3 parametera added to omregion routine call (default is 1 and 2)
# 10.07.2001 VNY - bkginner and bkgouter parameters have been modified : (bkinner=1.2 and bkgouter=1.8) 
# 13.07.2001 VNY - binsize parameter for lcplot routine has been set to 1 (was 5 by deafault)
# 16.07.2001 VNY - calculation of distance between two close source is corrected                              
# 07.08.2001 VNY - fixed 12-pixel radius is used for the source extraction region (omregion routine)
# 15.08.2001 VNY - new parameter has been added to OMLCBUILD
# 24.09.2001 VNY - the new parameter (thxset) has been removed from OMLCBUILD
# 29.09.2001 VNY - dependencies have been actualised (OMFASTSHIFT V1.17->V1.18, OMTHCONV V1.24->V1.25
# 22.10.2001 VNY - the use of the tmp_eventlist_1 name has been removed (the file doesn't exist)
# 16.11.2001 VNY - The names have been changed for the Tracking History Plot, Tracking Star Timeseries,
#                    and OSW Source List files (initial letter F replaced with P converting them
#                    to pipeline products). PNG-extention of the Tracking History Plot file was
#                    replaced with the extention .PS (Postscript file).
# 14.12.2001 VNY. - additional input parameters have been introduced in order to make possible
#                    online changes of the source extraction radius, as well as some parameters
#                    for online improvment of the  source detectability by omdetect 
#
# 08.01.2002 VNY -   dependencies file updated to work with ssclib V2.0
#
# 28.01.2002 VNY -   (V1.22.1) parameter types have been updated in the omfchain.par file
# 28.01.2002 VNY -   (V1.22.2) comment on the creation of the Log-file has been removed
# 05.03.2002 VNY -   (V1.22.3) missed file in the test directory has been restored
# 22.03.2002 VNY -   (V1.22.5) missed orbit file in the test directory has been restored;
#                    smooth size parameter is set to 12 (its default value was 64 that 
#                    exceeds the Fast mode window size)
# 18.04.2002 VNY -   (V.1.22.7) default value for the source extraction radius has been
#                    reduced downto 6 pixels in order to increase signal-to-noise ratio.
# 10.06.2002 VNY -   Modified to make it look in the correct directory
#                    for the SAS summary file when SAS_ODF has been set to point to the
#                    file (fixes SPR 2899). A bug with redirection of the FFX-file has been
#                    fixed (SPR-2900).
# 11.06.2002 VNY -   Formation of the list of the input ODF file names 
#                    is updated in order to cope with the local codification table at Jupiter
#                    machine (SPR-2876)
#
# 26.09.2002 VNY -   changed the parameter modeset in the call to omprep. When it is call for the first
#                    time modeset=3 (before it was 1), which means "tracking mode". The second call 
#                    is kept with modeset=1
# 27.09.2002 VNY -   updated DEPEND file (dependence on DSSLIB changed from 3.16 to 4.0) 
# 07.04.2003 VNY -   the variable redirect is initialised at the beginning    
# 13.06.2003 VNY -   the task is cleaned from the PERL-5 error messages, when it works in the strict mode
# 29.09.2003 VNY - the code for creation of a flat field in the case of no fiding it is uncommented 
#                  (it was switched off for test purporses, and left off by a mistake) 
# 28.01.2004 VNY - fixing the problem when omfastflat could not find 
#                  the flat field file (FFX) created in the output 
#                  directory on the previos step
# 01.02.2004 VNY - the  above problem (SSC-SPR-3238) is fixed. Fixing the
#                  problem when the chain crashes for the verbosity 
#                  levels higher than seven.
# 11.02.2004 VNY   parameter --odf has been removed from the calling
#                  sequence of omprep
# 24.02.2004 VNY   The statement use DAL has been removed, since it is not necessary anymore
# 28.05.2004 VNY   Correction in GetCurrentDirectory subroutine to protect 
#                  it from failure during the test in Mac-machines 
# 15.06.2005 VNY  Protected agains a crash when finds a magnifier filter exposure in the 
#                 data set, thus, enabling further processing of the rest of the files 
#                 in the ODF (fixing the SSC-SPR-3480) 
# 10.11.2005 VNY  The use of the region file is adjusted in accordance to the changes
#                 in this file introduced by omdetect (SSC-SPR-3538): since now this file
#                 contains an extra line (header) which must be taking into account 
#                 when determining the nimber of sources detected by omdetect
# 18.05.2006 VNY  Analysing the OMFAE1 header of the input event-list file to get the
#                 sampling time. If this sampling time is larger than the time given by
#                 the timebinsize parameter then the former time is used for the time binning
#                 (SSC-SPR-3598)
# 23.05.2006 VNY  A protection against producing an empty PDF-file is introduced (in the case 
#                 when omlcbuild has not produced the light-curve PS-plot) -SSC-SPR-3604
# 07.06.2007 VNY Increasing the source extraction radius for very bright sources, 
#                which are badly affected by coincidence losses and modulo-8 noise 
#                in order to avoid negative background counts, which might happen when 
#                applying the standard background calculation procedure to the corrupted
#                sources whereas it is designed for the normal sources (fixing
#                SSC-SPR-3144)
# 20.05.2008     The default value for the parameter nsigma is set to 3 instead of 2,
#                which would improve source detection (reducing the number of spurions
#                sources in the fast window)
# 2009.11.27     Introduced the usage of the imaging data to calculate the background level
# 2010.01.26     Introduced the parameter controlling the background subtraction (subtractbkg=yes/no)
#                Introduced the parameter psfphotometryenabled=yes/no used in omdetect 
# 2010.02.18     The default value of the parameter "bkgfromimage" is set to "no".
#                Protected against the cut-off the tail of the postscript filename by pgplot in lcplot
# 2010.04.21     Introduced a new optional parameter "maxrawcountrate" required by the
#                task omdetect
# 2011.06.07     Introduced a new parameter rawattitude for averaging raw attitude data. 
#                In the case the tracking history file is absent, the raw attitudes are
#                averaged during the whole exposure, otherwise, during the first 20 seconds;
#                also cheching for the presence of the raw attitude file (RAS)
#
# 2011.10.05     wrongly placed into the version 1.38 the changes are restored here:
#                2011.10.04: Improved the processing of bright source exposures: 
#                in order to exclude random jumps of the count rates when 
#                the mod8factor exceeds the 0.35 threshold 
#                the analysis of the mod8-factor is made only for the first exposure
#                of the series. The rest of the exposures are processed with the same 
#                extraction radius as was decided for the first exposure (no matter was
#                it increased or left to be normal)
# 2013.02.27     Removed an extra FAST-mode data set from the test folder (to reduce the
#                test processing time) 
# 2014-05-08     (vny) fixed a bug resulting in a wrong size of the accompanying imaging-mode
#                file (was checking the extension 0 instead of 1) 
# 2014-05-11 (vny) fixed the test code by setting the parameter bkgfromimage to NO 
#                as the test data does not contain the imaging file with the keyword NAXIS1 
#                in the first extension

use SAS;
#
my ($redirect, $periodic_file_flag, $non_periodic_file_flag, $flatfield_file_flag);
my ($date, $comment, $timebinsize, $create, $text1, $inp_directory);
my ($text2, $out_directory,  $FFXFiles, $PFXFiles, $RFXFiles, $THXFiles);
my ($WDXFiles, $FAEFiles, $IMIFiles, $file);
my ($p1, $p2, $p3, $p4, $p5, %ffx_list, %file_list, $flatfield_filename, $in_orbit_flat_field_filename);
my ($flatfield,  %orb_list, $periodic_hk_filename, $non_periodic_hk_filename);
my ($message, $fileName, $orb_key, $obs_key, %obs_list, $obs_list_name, %exp_list, $exp_list_name);
my (%exp_list_imi, %win_list_imi);
my ($exp_key, $tracking_history_filename, $sas_dir, $window_data_filename);
my ($s, $tracking_history_plot_filename, $tracking_history_timeseries_filename);
my ($arg_list, %win_list, $win_list_name, $win_key, $eventlist_filename);
my ($raw_image, $flat_field_product_filename);
my ($osw_list_intermediary_detect_filename, $image_pps_product_filename, $modulo_8_product_filename);
my ($sky_coord_pps_product_filename, $region_file, $PPS_eventlist_file, $background_output);
my ($signifimage_output);
my ($omdetect_nsigma, $nSources, $source, $source_key, $source_rates_file, $back_region_file);
my ($full_rates_file);
my ($back_rates_file, $lightcurve_pps_file, $lightcurve_plot_file, $lightcurve_pdf_file);
my ($omregion_srcradius, $omregion_bkginner);
my ($omregion_srcradius2, $omregion_bkginner2, $omregion_bkgouter2);
my ($omregion_bkgouter, $source_region_file, $thx_file, $nph_file, $peh_file, $wdx_file);
my ($tracking_history_fileneame, $SASFILE, @SASFiles, $SASFile, $omdetect_contrast);
my ($line, $omdetect_smoothsize, $omdetect_boxscale, $omdetect_maxscale);
my ($dtcorrection, $bkgFromImage, $ignoreMod8noise,$subtractBkg, $psfPhotometryEnabled);
my ($maxRawCountRate);
my $rawattitude=0;
my $tracking_history_found=0;
my $RASFiles=0;
my $globalmod8flag; # the flag indicating the the mod8-threshold should be applied to all exposures
my $firstExposureFlag;
 
sub omfchain 
{
 # VNY 01.02.2004 To fix the problem when the task cannot read its 
 # input parameters for verbosity levels > 7, the current verbosity 
 # is temporarily diminished until the parameters are read
 #
    my $SASVERBOSITY = " ";
    if (exists($ENV{SAS_VERBOSITY}))
    {
	$SASVERBOSITY = $ENV{SAS_VERBOSITY};
    }
    else
    {
	$SASVERBOSITY = "5";
	$ENV{SAS_VERBOSITY} = "5";
    }
    if ($SASVERBOSITY > 7) 
    {
	$ENV{SAS_VERBOSITY} = "5";
    }

    #*****************************************************
    # For test purposes only - BLANK OUT THE FOLLOWING
    # subroutine call before uploading
    # !!!!!!!!!!!!!!!! DO NOT FORGET !!!!!!!!!!!!!!!!!!!!!
    #*****************************************************
    # VNY 07.04.2003 When &CreateLogFile is commented then the 
    # variable redirect is not defined. Definig it for this case
    $redirect=0; 
#    &CreateLogFile;

    #*******************************
    # Set up the directory paths
    #*******************************
    &SetUpDirectoryPaths;

    $periodic_file_flag = 0;
    $non_periodic_file_flag = 0;
    $flatfield_file_flag = 0;


    #$taskname = 'OMFCHAIN';
    #$VERSION = '1.42.4';
    $date = &date_time;

    #12.12.2001 VNY adding parameters    
    $comment = stringParameter("comment");
    $timebinsize = realParameter("timebinsize");
    
    $create = " Running SAS task $name V$VERSION $date";
    $text1 = " Input directory = $inp_directory";
    $text2 = " Output directory = $out_directory";

    &HighlightedMessage("*", $create,$comment, "   ", $text1, $text2);

    #*********************************
    # Get the parameters for omdetect
    #*********************************

    &GetOmdetectParameters;
    &GetOmregionParameters;

    #print("L225  omdetect_nsigma=$omdetect_nsigma \n");
 
###################################################   
#    $dtcorrection = intParameter("dtcorrection");
    $dtcorrection=0;
###################################################
    $bkgFromImage = booleanParameter("bkgfromimage");
    #print("L235 bkgFromImage=$bkgFromImage \n");
    $ignoreMod8noise = booleanParameter("ignoremod8noise");
    $subtractBkg = booleanParameter("subtractbkg");

    # 2011-06-07 new parameter rawattitude
    $rawattitude = intParameter("rawattitude");

# Return SAS_VERBOSITY to its requested level
    if ($SASVERBOSITY > 7) 
    {
	$ENV{SAS_VERBOSITY} = $SASVERBOSITY;
    }

    #************************************************
    # Get a list of the files in the current directory
    #************************************************

    &GetListOfDataFiles;

    #print("========================= \n");
    #foreach $win_key (keys(%exp_list_imi))
    #{
    #	print("win_key= $win_key  exp_list_imi=$exp_list_imi{$win_key} \n");
    #}

    #************************************************** 
    # Check for the presence of the house keeping files
    #**************************************************
    &CheckForHouseKeepingFiles;

    #print("L216 FFXFiles=$FFXFiles \n");

    #*********************************
    # Get a flatfield image
    #*********************************
    if($FFXFiles == 0)
    {
        $fileName = &CreateFlatFieldImage;           
        $ffx_list{"$p1$p2"} = $fileName;
    }            
      
    # Run the pipeline.
    # Loop over all orbits.
    
    foreach $orb_key (sort(keys(%orb_list)))
    {
	#********************************************
	# Process the data for each orbit in the list
	#********************************************
	&ProcessOrbit($orb_key);  

    } # foreach orb_key
} # sub omfchain

#=========================================================================
#
# OMFCHAIN subroutine section
#
#=========================================================================


sub ExtractKeyword($)
{
    my ($inp_filename,$keyword, $lnumber)=@_;
    # keyword is the keyword to extract from the bloc lnumber 
    my ($keywordValue, $keywordFilename, $tmpline, @words);
    $keywordFilename="omfchain_tmp2_".$lnumber . ".txt";
    my $i=0;
    $arg_list=$inp_filename .
	"+$lnumber $keyword > $out_directory/$keywordFilename";
    #print("L302 arg_list=$arg_list \n");
    system("fkeyprint $arg_list") && die ("fkeyprint $keyword failed \n");
    #  Extact the keyword from tmp.txt
    open(KWD, "$out_directory/$keywordFilename") || die "Can't open $keywordFilename";
    while ($tmpline=<KWD>)
    {
	#print("L309 i=$i tmpline=$tmpline \n");
	if ($tmpline =~ /^$keyword/)
	{
	    chop ($tmpline);
	    @words=split(/[\t ]+/,$tmpline);
	    my $nwords=@words;
	    #print("L314 nwords=$nwords words: \n");
	    #for (my $j=0; $j<$nwords; $j++){
	    #	print("L317 j=$j word=$words[$j] \n");
	    #}
	    #print("\n---\n");
	    $keywordValue=$words[1];
	    if ($keyword eq "NAXIS1" || $keyword  eq "NAXIS2"){
		$keywordValue=$words[2];
	    }
	    #print("L247 lnumber=$lnumber keyword=$keyword  keywordValue=$keywordValue \n");		    
	}
    }
    close(KWD);
    #print ("L251 unlinking the file $out_directory/$keywordFilename \n");
    unlink("$out_directory/$keywordFilename");
    return($keywordValue);
}


#************************************************************
# Subroutine GetListOfDataFiles
# Get a list of file names in the current working directory.
#************************************************************
sub GetListOfDataFiles
{
    
  opendir(INDIR, $inp_directory) ||
  SAS::fatal("OMFCHAIN", "Unable to open $inp_directory");
      
    $FFXFiles = 0;
    $PFXFiles = 0;
    $RFXFiles = 0;
    $THXFiles = 0;
    $WDXFiles = 0;
    $FAEFiles = 0;
    $IMIFiles = 0;
    $RASFiles = 0;

# Sort the file names according to observation, exposure, window and file type.

#while ($file = readdir(INDIR))
#    {

  foreach $file (glob("$inp_directory/*"))
    {
	$file=~ s/^.+\///;
	
	#if ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM[S|U|X]([0-9a-zA-Z]{3})([0-9]{2})([A-Z]{3}).FIT/i)
	if (($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM[S|U|X]([0-9a-zA-Z]{3})([0-9]{2})([A-Z]{3}).FIT/i)
	    || ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_SCX([0-9a-zA-Z]{3})([0-9]{2})([A-Z]{3})./i))
	{ 

	    $p1=$1; $p2=$2; $p3=$3; $p4=$4;$p5=$5; 
	    #print("p1=$p1 p2=$p2 p3=$p3 p4=$p4 p5=$p5 \n");
	    

            # File list.
            $file_list{"$p1$p2$p3$p4$p5"} = "$file";
            if ($file =~ /FFX/i)
	    {

                $FFXFiles = $FFXFiles + 1;  
		$ffx_list{"$p1$p2"} = "$file";
		$flatfield_filename = $file;
		$in_orbit_flat_field_filename = $inp_directory . '/' . $file;;  
		$flatfield_file_flag = 1;
	    }
            else
	    {
		if ($file !~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})PEH.FIT/i
		  && $file !~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})NPH.FIT/i)    
		    {
			
			$flatfield = $file;
			

			if ($file =~/FAE/i)
			{
			    
			    # Orbit number list
			    $orb_list{$p1}="$p1";                         

			    # Observation list.
			    #${${"$p1"}{$p2}} = "$p1$p2";
			    $obs_list{"$p2"} = "$p1";

			    # Exposure list.
			    #${${"$p1$p2"}{$p3}} = "$p1$p2$p3";
			    $exp_list{"$p3"} = "$p2";

		            # Window list. 
                            #${${"$p1$p2$p3"}{$p4}} = "$p1$p2$p3$p4";
                            $win_list{"$p4"} = "$p3";

                            $FAEFiles = $FAEFiles + 1;
                        }
               
                        if  ($file=~ /IMI/i)
		        {
			    
			    # Exposure list for the imaging data.
			    $exp_list_imi{"$p3$p4"} = "$file";

		            # Window list for the imaging data. 
                            $win_list_imi{"$p4"} = "$p3";

		          $IMIFiles = $IMIFiles + 1;
	                }
			if ($file =~ /RAS/i) # raw attitude file
	                {
			  
                          $RASFiles = $RASFiles + 1;
		      } 

	                if ($file =~ /PFX/i)
	                {
                          $PFXFiles = $PFXFiles + 1;
                        } 
                        if ($file =~ /RFX/i)
                        {               
                          $RFXFiles = $RFXFiles + 1;
                        } 
                        if ($file =~ /THX/i)
                        {
                           $THXFiles = $THXFiles + 1;
                        } 
                        if ($file =~ /WDX/i)
                        {               
                           $WDXFiles = $WDXFiles + 1;
                        } 

                 } # if file!=PEH 	
                 else
                {
		#*****************************************
		# Pick-up the House Keeping files here.
		#*****************************************
 
		     if ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})PEH.FIT/i)
                     {
                        $periodic_hk_filename = $file;
		        $periodic_file_flag = 1;
	             }
	             if($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})NPH.FIT/i)
	             {
		        $non_periodic_hk_filename = $file;
		        $non_periodic_file_flag = 1;
	             }

                  } # else
              } # else
        } # if file=fit 
    } #while

closedir(INDIR);
} # end GetListOfDataFiles

#**************************************************
# Check for the presence of the house keeping files
#**************************************************
sub CheckForHouseKeepingFiles
{
   if($periodic_file_flag == 0)
   {
       $message = "The ODF does NOT contain a Periodic Housekeeping file. Please insert into the ODF.";
       &Message($message);
       SAS::fatal("Task Failure","Incomplete ODF.");
   }

   if($non_periodic_file_flag == 0)
   {
       $message = "The ODF does NOT contain a Non Periodic Housekeeping file. Please insert into the ODF.";
       &Message($message);

       SAS::fatal("Task Failure","incomplete ODF.");
   }
} # end sub CheckForHouseKeepingFiles

#***************************
# Subroutine ProcessOrbit
#***************************
sub ProcessOrbit($)
{
    my ($orb_key) = @_; 

    $message = "      Processing orbit ". $orb_key;
    &HighlightedMessage("*", $message);
    $globalmod8flag=0;
    $firstExposureFlag=0;

    # Loop over al observations
    #foreach $obs_key (keys(%{"$obs_list_name"}))
    foreach $obs_key (keys(%obs_list))
    {
	$message = "       Observation $obs_key \n";
        &Message($message);
	$message = "Using flatfield $in_orbit_flat_field_filename \n";
	&Message($message);      
	# Loop over all exposures.
	#foreach $exp_key (sort(keys(%{"$exp_list_name"})))
	foreach $exp_key (sort(keys(%exp_list)))
	{
	    &ProcessExposure($orb_key, $obs_key, $exp_key);
	} # foreach exp_key
      } # foreach obs_key
} # end sub ProcessOrbit


#****************************************************
# Subroutine ProcessExposure
#****************************************************
sub ProcessExposure($)
{
    my ($orb_key, $obs_key, $exp_key) = @_; 
    my ($mod8corrupted, $mod8flag);
    my ($has_imaging_window, $imaging_window_filename);

    $message = "           Exposure  ". $exp_key;
    &HighlightedMessage("*",$message);
	
    # Check for the presence of the imaging data file
    $has_imaging_window=0;
    #2014-05-11 VNY: check for the presence og the imaging-mode file
    # only if the parameter bkgfromimage was set to yes
    if ($bkgFromImage){
	#print("L540 bkgFromImage=$bkgFromImage \n");

        # RDS - check if file types exist
        my $fileIMI = "";
	if (exists($file_list{$orb_key . $obs_key . $exp_key . "00IMI"})) 
	{
           $fileIMI = "00IMI";
        } elsif (exists($file_list{$orb_key . $obs_key . $exp_key . "01IMI"}))
        {
           $fileIMI = "01IMI"; 
        } elsif (exists($file_list{$orb_key . $obs_key . $exp_key . "02IMI"}))
        {
           $fileIMI = "02IMI"; 
        } 
	    
        # RDS - if one exists process it
        if (index($fileIMI,"IMI") != -1) 
        {
	   $imaging_window_filename = $inp_directory . '/' . 
                 $file_list{ $orb_key . $obs_key . $exp_key . $fileIMI};
	   $has_imaging_window=1;
	    #print("L544 imaging_window_filename=$imaging_window_filename \n");
	    #print("L542 imaging_window_filename=$imaging_window_filename \n");
	    
	    # check the size of the imaging data	
	   my $keyword="NAXIS1";
	    #print("L548 calling ExtractKeyword \n");
	    # 2014-05-08 changing lnumber=0 to lnumber=1 as the 0-value correspond to the wrong fits extension
	   my $lnumber=1; 
	   my $naxis1size=&ExtractKeyword($imaging_window_filename,$keyword,$lnumber);
	    #print("L550 lnumber=$lnumber \n");
	    #print("L551 naxis1size=$naxis1size \n");
           my $winum = substr $fileIMI, 0, 2; # RDS

	   if ($naxis1size<40){
		# this is the FAST image (not imaging)
	      $has_imaging_window=0; 
	   } else {
		$message = "Imaging-mode window$winum: O.K. ";
		&Message($message);
	   }
	    #print("L559 has_imaging_window=$has_imaging_window \n");
	}
    } # if bkgFromImage

    #print("L547 has_imaging_window=$has_imaging_window \n");
    #if ($has_imaging_window)
    #{
#	print("L550 the imaging window will be used: \n");
#	print("imaging window filename= $imaging_window_filename \n");
    #}


    # Check for the consistency of the odf.
    if (exists($file_list{$orb_key . $obs_key . $exp_key . "00THX"})) 
    {

	$tracking_history_found=1; 
	$message = "Tracking history file: O.K.";
	&Message($message);
	$tracking_history_filename = $inp_directory . '/' 
	    . $file_list{ $orb_key . $obs_key . $exp_key . "00THX"};
    }	 
    else    
    {
	$tracking_history_found=0; 
	$message = " Tracking history file $tracking_history_fileneame is missing";
	&Message($message);
        $sas_dir = $ENV{SAS_DIR};
        #***********************************
        # Create a dummy name to fool OMPREP
        #***********************************
	$message = "Creating a dummy name for tracking history file ";
	&Message($message);	
	$tracking_history_filename = "DUMMYTHX.FIT";  
     }
     if (exists($file_list{$orb_key . $obs_key .  $exp_key . "00WDX"})) 
     {       
        $message =  "Window data file: O.K.";
	&Message($message); 
     }	 
     else    
     {
	 $message = "Window data file " . $file_list{$orb_key . $obs_key .  $exp_key . "00WDX"} . 
	     " is missing";
         &Message($message);
     }

     if(exists($file_list{$orb_key . $obs_key .  $exp_key . "00WDX"}) &&
                 exists($file_list{$orb_key.$obs_key."00000NPH"}) &&
                 exists($file_list{$orb_key.$obs_key."00000PEH"}))
     {
         # Set pipeline variables.
	 $periodic_hk_filename = $file_list{$orb_key.$obs_key."00000PEH"};
         $non_periodic_hk_filename = $file_list{$orb_key.$obs_key."00000NPH"}; # Modified $obs_key
         $window_data_filename = $file_list{$orb_key.$obs_key.$exp_key."00WDX"};

         # Extraction of the Exposure Flag
         $s = substr($window_data_filename, 18, 1);
         $tracking_history_plot_filename = "P" . $obs_key . "OM" . $s . $exp_key 
	     . "TSHPLT" . "0000.PS";        
         $s= substr($non_periodic_hk_filename, 18, 1);
         $tracking_history_timeseries_filename =  "P" . $obs_key . "OM" 
	     . $s .  $exp_key . "TSTRTS0000.FIT";

         # Produce tracking history products.
         $message = "... Running Tracking tasks ... ";
         &Message($message);

	 
	 #*******************************************************************
	 # 2011-06-07 Modify the value of the parameter rawattitude 
	 # if the tracking history file was not found
	 #*******************************************************************
	 if ($RASFiles>0){
	     if ($tracking_history_found==0){
		 # the parameter rawattitude =2 is for averaging along the whole exposure
		 $rawattitude=2;
		 my $message = sprintf("%s", "Raw attitude will be averaged for the whole exp.time ");
		 SAS::message($SAS::AppMsg, $SAS::SparseMsg, $message);
	     }
	     else{
		 if ($rawattitude==1){
		     # the parameter rawattitude =1 is for averaging during the first 20s
		     my $message = sprintf("%s", "Raw attitude will be averaged for the first 20s of exposure");
		     SAS::message($SAS::AppMsg, $SAS::SparseMsg, $message);
		 }
	     }
	 }
	 else {
	     $rawattitude=0;
	     my $message = sprintf("%s", "NB: Raw attitude file not found (skipping) ...");
	     SAS::message($SAS::AppMsg, $SAS::SparseMsg, $message);
	 }
          
	 #************************************************************  
         # omprep.
	 #************************************************************
         $message = " ... omprep ...";
         &HighlightedMessage("*", $message);
 
         $arg_list = "set=" .  $tracking_history_filename .
    " nphset=" . $inp_directory . '/' .$non_periodic_hk_filename .
    " pehset=" . $inp_directory . '/' .$periodic_hk_filename .
    " wdxset=" . $inp_directory . '/' .$window_data_filename .
    " rawattitude=" . $rawattitude .
    " outset=" . $out_directory . '/' . "tmp_tracking" .
    " modeset=3";
                      
        system("omprep $arg_list") && die("omprep failed\n");

	#************************************************************
        # omdrifthist.
	#************************************************************
        $message = " ... omdrifthist ... ";
        &HighlightedMessage("*", $message);
        $arg_list = "set=" . $out_directory . '/' .  "tmp_tracking" .
    " plotfile=" . $out_directory . '/' . $tracking_history_plot_filename ;                   
        system("omdrifthist $arg_list") && die("omdrifthist failed\n");

	#************************************************************
        # omthconv.
	#************************************************************
               $message = " ... omthconv ...";
               &HighlightedMessage("*", $message);

               $arg_list = "thxset=" .  $out_directory . '/' ."tmp_tracking" .
                           " nphset=" .  $inp_directory . '/' . $non_periodic_hk_filename .
                           " outset=" .  $out_directory . '/' . $tracking_history_timeseries_filename .
                           " modeset=1";

                system("omthconv $arg_list") && die("omthconv failed\n");

#************************************************************
# Loop over all windows.
#************************************************************
        foreach $win_key (keys(%win_list))
                 {

# Check consistancy of odf.
                  if (exists($file_list{$orb_key . $obs_key . $exp_key . $win_key . "FAE"}))
                     {
                     $message =  " ******          Science Window $win_key    ******";
		     &HighlightedMessage("*", $message);

# Set pipeline variables.

$eventlist_filename = $file_list{$orb_key . $obs_key . $exp_key . $win_key . "FAE"};
#$raw_image =  "F" . substr($eventlist_filename, 1,24) . "IMI.FIT";
$s = substr($eventlist_filename, 18, 1);
$raw_image = "F" . $obs_key . "OM" . $s .  $exp_key . "FIMAGE" . substr($win_key, 1,1) . "000.FIT";
$flat_field_product_filename = "F" . $obs_key . "OM" . $s .  $exp_key 
    . "FLAFLD" . substr($win_key, 1,1) . "000.FIT";
$osw_list_intermediary_detect_filename = "P" . $obs_key . "OM" . $s .  $exp_key 
    . "SWSRLI" . substr($win_key, 1,1) . "000.FIT";
$image_pps_product_filename = "P" . $obs_key . "OM" . $s .  $exp_key . "IMAGE_" 
    . substr($win_key, 1,1) . "000.FIT";
$modulo_8_product_filename = "F" . $obs_key . "OM" . $s .  $exp_key . "MOD8MP" 
    . substr($win_key, 1,1) . "000.FIT";
$sky_coord_pps_product_filename = "P" . $obs_key . "OM" . $s . $exp_key . "SIMAGE" 
    . substr($win_key, 1,1) . "000.FIT";
$region_file = "F" . $obs_key . "OM" . $s .  $exp_key . "REGION" 
    . substr($win_key, 1,1) . "000.ASC";
$PPS_eventlist_file = "F" . $obs_key . "OM" . $s .  $exp_key . "EVLIST" 
    . substr($win_key, 1,1) . "000.FIT";

# temporary files for testing purposes
$background_output= "tmp_background" . $obs_key . "OM" . $s .  $exp_key . "BACKGR" 
   . substr($win_key, 1,1) .  ".FIT";
$signifimage_output="tmp_signifimage"  . $obs_key . "OM" . $s .  $exp_key . "SIGNIF" 
   . substr($win_key, 1,1) . ".FIT";

#-----
# VNY 07.02.07 fstruct and fkeyprint do not work properly at msslck
#----------------------------------------------------------------------------------------
# VNY 18.05.2006 before running the tasks we have to check whether the sampling interval 
# is smaller then the value of the timebinsize parameter
#----------------------------------------------------------------------------------------
################################################################################
# N.B. temporarily and only for MSSLCK system the following three lines are  
#      commented, with the sampletime variable set to 512. For releasing the
#      task the lines must be uncommented
		     $arg_list="INFILE=$inp_directory/$eventlist_filename" . 
			 " OUTFILE=!$out_directory/omfchain_tmp1.txt";
		     system("fstruct $arg_list");
################################################################################
		     my $keyword="SAMPTIME";
		     my $lnumber=1;
		     my ($samptime, $path_event_filename);
		     $path_event_filename="$inp_directory/$eventlist_filename";
		     ##############################################################
		     # The following line is also commented only for the MSSLCK usage
		     $samptime=&ExtractKeyword($path_event_filename,$keyword,$lnumber);
		     ##############################################################
		     # vny 07.02.07 temprorarily setting samptime to 512
		     # before uploading the task this line must be commented
		     # at the same time when the above lines are uncommented
		     #$samptime=512;
		     #############################################################
		     $samptime=$samptime/1024;
		     #print("L737 samptime=$samptime \n");
		     ##############################################################
		     # The following line is also commented only for the MSSLCK usage
		     unlink("$out_directory/omfchain_tmp1.txt");
		     ##############################################################
		     if ($samptime > $timebinsize)
		     {
			 $message="Sampling interval is larger than binning (setting the binning time to $samptime seconds)\n";
			 &Message($message);
			 $timebinsize=$samptime;
		     }

#----------------------------------------------------------------------------------------- 
# Produce fast mode products.
                     $message = "...  Running Fast Mode tasks ... ";
                     &Message($message);                    

#************************************************************
# omprep second run
#************************************************************
                     $message = " ... omprep ... ";           
                     &HighlightedMessage("*", $message);

                       $arg_list = "set=" .  $inp_directory . '/' . $eventlist_filename .
                                 " nphset=" .  $inp_directory . '/' . $non_periodic_hk_filename .
                                 " pehset=" .  $inp_directory . '/' . $periodic_hk_filename .
                                 " wdxset=" .  $inp_directory . '/' . $window_data_filename .
                                 " outset=" .  $out_directory . '/' . $PPS_eventlist_file .
				 " rawattitude=" . $rawattitude .
                                 " modeset=1";

                      system("omprep $arg_list") && die("omprep failed\n");
#************************************************************
# evselect.
#************************************************************
                     $message = " ... evselect ... (generating raw image from events) ";
                     &HighlightedMessage("*",$message);

                     $arg_list = " table=" .  $out_directory . '/' . $PPS_eventlist_file .
                                 " xcolumn=RAWX" .
                                 " ycolumn=RAWY" .
                                 " withimageset=true" . 
                                 " imageset=" .  $out_directory . '/' . $raw_image;

                     system("evselect $arg_list") && die("evselect failed\n");
#************************************************************
# omfastshift.
#************************************************************
                     $message = " ... omfastshift ... ";
                     &HighlightedMessage("*",$message);

                     $arg_list = " nphset="  .  $inp_directory . '/' . $non_periodic_hk_filename .
			 " set="  .  $out_directory . '/' . $PPS_eventlist_file .
			     " thxset=" .  $out_directory . '/' . "tmp_tracking" ;

                      system("omfastshift $arg_list") && die("omfastshift failed\n");
#************************************************************
# omfastflat.
#************************************************************
                     $message = " ... omfastflat ...  ";
                     &HighlightedMessage("*",$message); 


                     $arg_list = "set=" .  $out_directory . '/' . $PPS_eventlist_file . 
                                 " slewflatset=" . $in_orbit_flat_field_filename .
                                 " fastimgset=" .  $out_directory . '/' . $image_pps_product_filename .
                                 " oswflatset=" .  $out_directory . '/' . $flat_field_product_filename ;

                     system("omfastflat $arg_list") && die("omfastflat failed\n");
# VNY 06.06.2007 The header of the file $image_pps_product_filename now contains the keyword MOD8FLAG, which is
# set to 1 if the image ic modulo-8 corrupted. In this case we have to increase the source extraction radius
# to prevent negative backgrouns rates
# VNY 26.01.2010 This header is now has also the keyword MOD8FACT (real value), which indicated the 
# degree of the mod-8 modulation of the image (from 0 to 1) 
#
#  Checking for the keyword MOD8FLAG
		     if (open(IMIFILE, $out_directory . '/' . $image_pps_product_filename))
		     {
			 #$message="Found image file $image_pps_product_filename"; 
			 #&Message($message);
			 $mod8flag=-1;
		     }
		     $line=<IMIFILE>;
		     $mod8corrupted=0;
		     $mod8flag=-1; 
		     if ($line=~/MOD8FLAG= +(\d\d\d\d)/i || $line=~/MOD8FLAG= 
                       +(\d\d\d)/i || $line=~/MOD8FLAG= +(\d\d)/i || $line=~/MOD8FLAG= +(\d)/i)
		     {
			 $mod8flag=$1;
		     }

		     #****************************************************
		     # 2011-10-04 vny: increase the source extraction region
		     # only if the first exposure was flagged for this increase
		     #******************************************************
		     if ($firstExposureFlag==0){
			 $firstExposureFlag=1; # processed the first exposure
			 $globalmod8flag=$mod8flag;;
		     }

		     #print "L660 mod8flag= $mod8flag \n";
		     #print "*********************************** \n";
		     if ($globalmod8flag == 1 && $ignoreMod8noise==0)
		     {
			 $mod8corrupted=1;
			 $message="Increasing the source extraction region for the mod-8 corrupted image"; 
			 &Message($message);
		     }
		     if ($globalmod8flag == 1 && $ignoreMod8noise==1)
                     {
			$mod8corrupted=2; 
                     }
		     close(IMIFILE);
# omdetect.
    #
    #**************************************************
    # omdetect
    #**************************************************
    $message = " ... omdetect ... ";
    &HighlightedMessage("*", $message);
    $arg_list = "nsigma=$omdetect_nsigma" .
                " set=$out_directory/$image_pps_product_filename" . 
                " regionfile=$out_directory/$region_file" .  
                " outset=$out_directory/$osw_list_intermediary_detect_filename" .
		" psfphotometryenabled=$psfPhotometryEnabled" .
		" maxrawcountrate=$maxRawCountRate";


    &Message("omdetect $arg_list");
                            
                      system("omdetect $arg_list");

		     my $exit_value = $? >> 8;   # 0 okay, 1 call fatal called, or some other disaster
		     if ($exit_value == 1) # Failure in omprep 
		     { 
			 &HighlightedMessage("*", "OMDETECT has detected an error- this observation will not be processed");
			 return;
			 
		     }    
# ommat.

                     $message = "... omatt ... ";
                     &HighlightedMessage("*", $message);
                    
                     $arg_list = "set=" .  $out_directory . '/' . $image_pps_product_filename . 
                                 " sourcelistset=" .  $out_directory . '/' . $osw_list_intermediary_detect_filename  . 
                                 " ppsoswset=" .  $out_directory . '/' . $sky_coord_pps_product_filename .
                                 " usecat=F" ;
                                 
                            

                      system("omatt $arg_list") && die("omatt failed\n");

		     # 10.11.2005 Since now the region file has an extra line (header)
                      $nSources=-1; # Number of lines in the region_file
                      open (REGFILE, "$out_directory/$region_file");
                      while ($line=<REGFILE>)
                      {
			  $nSources=$nSources+1;
		      }
                      
                      $message = " Number of detected sources = ". $nSources;
                      &Message($message);
                     
                      close(REGFILE);                     
# omregion.
		     
#### 18.05.2009 limiting the number of sources if it is unrealistic
		      if ($nSources > 20)
		      {
			  $message=" The number of sources exceeds a reasonable value (setting to 1)";
			  &Message($message);
			  $nSources=1;
		      }
# 25.05.2001 VNY loop over all  detected sources 
         for ($source=1; $source<=$nSources; $source++)
                {
		    $source_key=sprintf("%03X", $source-1);
		    $message = "Source  = ". $source . '(' . $source_key . ')';
		    &HighlightedMessage("*",$message);

		    $message = "... omregion ...  ";
		    &HighlightedMessage("*",$message);
# VNY 26.02.2004 checking extraction from the full window
 $full_rates_file = "FULL" . $exp_key . "SCRATE" . substr($win_key, 1,1) . $source_key . ".FIT";
                    
  $source_rates_file = "F" . $obs_key . "OM" . $s . $exp_key . "SCRATE" . substr($win_key, 1,1) 
      . $source_key . ".FIT";
  $back_region_file = "F" . $obs_key . "OM" . $s . $exp_key . "BGDREG" . substr($win_key, 1,1) 
       . $source_key . ".FIT";
  $source_region_file = "F" . $obs_key . "OM" . $s . $exp_key . "SRCREG" . substr($win_key, 1,1) 
         . $source_key .  ".FIT"; 
  $back_rates_file = "F" . $obs_key . "OM" . $s . $exp_key . "BGRATE" . substr($win_key, 1,1) 
         . $source_key . ".FIT";
  $lightcurve_pps_file = "P" . $obs_key . "OM" . $s . $exp_key . "TIMESR" . substr($win_key, 1,1) 
        . $source_key .".FIT"; 
  $lightcurve_plot_file = "F" . $obs_key . "OM" . $s .  $exp_key . "TIMESR" . substr($win_key, 1,1) 
         . $source_key . ".PS";
  $lightcurve_pdf_file = "P" . $obs_key . "OM" . $s .  $exp_key . "TIMESR" . substr($win_key, 1,1) 
         .  $source_key .".PDF";

# omregion_srcradius should be negative in order to force the same radius for all exposures
		    $omregion_srcradius2=-12.0; # this is the increased value used for the mod-8 corrupted images
		    $omregion_bkginner2=3.0; # the background radius is increased to force the background to zero
		    $omregion_bkgouter2=3.1;
		    #print "L762 omregion_srcradius2=$omregion_srcradius2 \n";
		    #print "L763 omregion_srcradius=$omregion_srcradius \n";
		    if ($mod8corrupted==1 && $ignoreMod8noise==0)
		    {
			$arg_list = "set=".  $out_directory . '/' . $osw_list_intermediary_detect_filename .
			    " srcnumber=$source" .
			    " srcradius=$omregion_srcradius2" . 
			    " nfwhm=3" .
			    " bkginner=$omregion_bkginner2" .
			    " bkgouter=$omregion_bkgouter2" . 
			    " bkgfile=".  $out_directory . '/' . $back_region_file .
			    " srcfile=" .  $out_directory . '/' . $source_region_file ;
			#print "L733 processing with omregion_srcradius2 \n";
			$message = " Increasing the source extraction radius to $omregion_srcradius2 (for the mod-8 corrupted image)";
			&Message($message);
		    }
		    else
		    {
			$arg_list = "set=".  $out_directory . '/' . $osw_list_intermediary_detect_filename .
			    " srcnumber=$source" .
			    " srcradius=$omregion_srcradius" . 
			    " nfwhm=3" .
			    " bkginner=$omregion_bkginner" .
			    " bkgouter=$omregion_bkgouter" . 
			    " bkgfile=".  $out_directory . '/' . $back_region_file .
			    " srcfile=" .  $out_directory . '/' . $source_region_file ;
		    }
		    &Message("omregion $arg_list");

		    system("omregion $arg_list") && die("omregion failed\n");		 

# evselect.

		    $message = "... evselect ... (extracting SOURCE counts) ";
		    &HighlightedMessage("*",$message);
  
# VNY test 18.03.2004
# $arg_list = "expression=\"((WIN_FLAG .eq. 0) .and. (region($out_directory/$source_region_file, CORR_X, CORR_Y)))\"" .
#			         " table=" .  $out_directory . '/' . $PPS_eventlist_file .
#                                 " xcolumn=CORR_X" .
#                                 " ycolumn=CORR_Y" .
#                                 " maketimecolumn=true" . 
#                                 " withrateset=T" .
#                                 " timebinsize=$timebinsize" . #10.0
#				 " rateset=" .  $out_directory . '/' .  $source_rates_file ;
  
 $arg_list = "expression=\"((WIN_FLAG .eq. 0) .and. (region($out_directory/$source_region_file, CORR_X, CORR_Y)))\"" .
			         " table=" .  $out_directory . '/' . $PPS_eventlist_file .
#                                 " xcolumn=CORR_X" .
#                                 " ycolumn=CORR_Y" .
                                 " maketimecolumn=true" . 
                                 " withrateset=T" .
                                 " timebinsize=$timebinsize" . #10.0
				 " rateset=" .  $out_directory . '/' .  $source_rates_file ;

		    system("evselect $arg_list") && die("evselect failed\n");
# evselect.

		    $message = "... evselect ... (extracting BACKGROUND counts)  ";
		    &HighlightedMessage("*",$message);

# Test VNY 18.03.2004                   
# $arg_list = "expression=\"WIN_FLAG .eq. 0 && region($out_directory/$back_region_file, CORR_X, CORR_Y)\"" .                                            " table=" . $out_directory . '/' . $PPS_eventlist_file .
#                                 " timecolumn=TIME" .
#                                 " xcolumn=CORR_X" .
#                                 " ycolumn=CORR_Y" .
#                                 " withrateset=true" .
#                                 " timebinsize=$timebinsize". # 10.0
#                                 " maketimecolumn=true" .
#                                 " rateset=" . $out_directory . '/' .  $back_rates_file ;
 $arg_list = "expression=\"WIN_FLAG .eq. 0 && region($out_directory/$back_region_file, CORR_X, CORR_Y)\"" .                                            " table=" . $out_directory . '/' . $PPS_eventlist_file .
                                 " timecolumn=TIME" .
#                                 " xcolumn=CORR_X" .
#                                 " ycolumn=CORR_Y" .
                                 " withrateset=true" .
                                 " timebinsize=$timebinsize". # 10.0
                                 " maketimecolumn=true" .
                                 " rateset=" . $out_directory . '/' .  $back_rates_file ;

                                  system("evselect $arg_list") && die("evselect failed\n");
# omlcbuild.

		    $message = "... omlcbuild ... ";
		    &HighlightedMessage("*",$message);

		    if ($has_imaging_window)
		    {		    
			$arg_list = "srcregionset=" .  $out_directory . '/' . $source_region_file .
			    " bkgregionset=" .  $out_directory . '/' . $back_region_file .
			    " srcrateset=" .  $out_directory . '/' . $source_rates_file .
			    " bkgrateset=" .  $out_directory . '/' . $back_rates_file .
			    " sourcelistset=" . $out_directory . '/' . $osw_list_intermediary_detect_filename .    
			    " wdxset=" . $inp_directory . '/' . $window_data_filename .
			    " outset=" .  $out_directory . '/' . $lightcurve_pps_file .
			    " mod8corrupted=" . $mod8corrupted .
			    " imageset=" . $imaging_window_filename .
			    " bkgfromimage=" . $bkgFromImage .
			    #" dtcorrection=" . $dtcorrection .
			    #" ignoremod8noise=" . $ignoreMod8noise .
			    " subtractbkg=" . $subtractBkg;

		    } 
		    else
		    {
			$arg_list = "srcregionset=" .  $out_directory . '/' . $source_region_file .
			    " bkgregionset=" .  $out_directory . '/' . $back_region_file .
			    " srcrateset=" .  $out_directory . '/' . $source_rates_file .
			    " bkgrateset=" .  $out_directory . '/' . $back_rates_file .
			    " sourcelistset=" . $out_directory . '/' . $osw_list_intermediary_detect_filename .    
			    " wdxset=" . $inp_directory . '/' . $window_data_filename .
			    " outset=" .  $out_directory . '/' . $lightcurve_pps_file .
			    " mod8corrupted=" . $mod8corrupted .
			    #" dtcorrection=" . $dtcorrection .
			    #" ignoremod8noise=" . $ignoreMod8noise .
			    " subtractbkg=" . $subtractBkg;
		    }

                     system("omlcbuild $arg_list") && die("omlcbuild failed\n");

# V.Ye. 15.05.2001 - draw the PS light curve 
# lcplot.
		     $message = "... lcplot ...  ";
		     &HighlightedMessage("*",$message);
                    
                     $arg_list = "set=" .  $out_directory . '/' . $lightcurve_pps_file .
			         " binsize=1" . 
                                 #" plotfile=" .  $out_directory . '/' . $lightcurve_plot_file ;
		                 " plotfile=" .  $out_directory . '/t.ps';
         
                      system("lcplot $arg_list") && die("lcplot failed\n");
		      rename("$out_directory/t.ps", "$out_directory/$lightcurve_plot_file");


# converts PS to PDF ( VNY 21.05.2001)
#------------------------------------------------------------
#  protection against creating of empty PDF-files if te PS-plot file doesn't exist (23.05.06)
		    if ( -e $out_directory . '/' . $lightcurve_plot_file)
		    {
			system ("ps2pdf  " . $out_directory . '/' . $lightcurve_plot_file . '  ' .  $out_directory . '/' . $lightcurve_pdf_file );
		    }
#------------------------------------------------------------
                  } # for source=1, nSources

                     } #if exists FAE
                  } # for each win_key

# Clean things up and do some stuff.

               unlink($out_directory . '/' . "tmp_tracking");

               } # if exists THX
            else
               {
		   $message = "*** Warning ***";
		   &Message($message);
                  
		   $message = "Exposure ". $exp_key . " in observation " . $obs_key . " is misseing a file";
		   &Message($message);
                   
                   $thx_file = "RRRR_" . $obs_key . "_OMS" . $exp_key . "00THX.FIT";
		   $message = "Please check file  ". $thx_file . " is in the ODF";
		   &Message($message);
                  
                   $nph_file = "RRRR_" . $obs_key . "_OMS" . $exp_key . "00NPH.FIT";
		   $message = "Please check file  ". $nph_file . " is in the ODF";
		   &Message($message);
                  
                   $peh_file = "RRRR_" . $obs_key . "_OMS" . $exp_key . "00PEH.FIT";
		   $message = "Please check file  ". $peh_file . " is in the ODF";
		   &Message($message);
           
        
		   $wdx_file = "RRRR_" . $obs_key . "_OMS" . $exp_key . "00WDX.FIT";
		   $message = "Please check file  ". $wdx_file . " is in the ODF";
		   &Message($message);
		  
               }
} # end sub ProcessExposure

sub date_time {          # create the file creation datestring

    my ($datestring);
    $datestring = `date -u`;
    chop $datestring;
    return $datestring;
}
#**************************************
# Subroutine Message
#**************************************
sub Message($)
{ 

    my ($message) = @_;  
    if ($redirect eq 5) 
    {
        print("$message \n");
    }
    else  
    {
        SAS::message($SAS::AppMsg, $SAS::SparseMsg, $message);
    }

}

#**************************************
# Subroutine HighlightedMessage
# Outputs lines of text
#**************************************
sub HighlightedMessage($)
{ 
    my ($character, @Messages) = @_;  
   
    my $noLines = @Messages;
    my $maxLength = length($Messages[0]);
    my $i = 0;
    if ($noLines gt 1)
    {
        for ($i = 1; $i < $noLines; $i++)
        {
            if (length($Messages[$i]) gt $maxLength)
	    {
                $maxLength = length($Messages[$i]);
            }
        } 
    }
    
    my $text = "";
   
    for ($i = 0; $i < $maxLength; $i++)
    { 
        $text = $text . $character;
    }
    &Message($text);
    
    for ($i = 0; $i < $noLines; $i++)
    { 
       
        &Message($Messages[$i]);
    }

    &Message($text);   
}

#***************************************
# CreateLogFile
#**************************************
sub CreateLogFile
{
    $redirect = 5;
    open (STDOUT, ">omfchain_log");
    open (STDERR, ">&STDOUT");
    select (STDERR);
}
#***********************************
# Subroutine GetCurrentDirectory
#**********************************
sub GetCurrentDirectory
{
    my ($command, $curdir, $leng);
    $command = "pwd";
    $curdir = `$command`;

    $leng = length($curdir);
    substr($curdir, $leng - 1) = "";    
    return $curdir;
}

#*********************************************
# CreateFlatFieldImage
#*********************************************
sub CreateFlatFieldImage
{
    my($fileName, $arg_list, $message);
 
       $fileName = substr($flatfield, 0, 15)  . "_OMX00000FFX.FIT";
       $arg_list = "outset=". $out_directory . '/' . $fileName;

       $message = "omflatgen $arg_list";
       SAS::message($SAS::AppMsg, $SAS::SparseMsg, $message);

       system("omflatgen $arg_list") && SAS::fatal("Task Failure", "omflatgen");

       $ffx_list{"$p1$p2"} = $fileName;
# VNY 28.01.2004
#       $in_orbit_flat_field_filename = $fileName;  
       $in_orbit_flat_field_filename = $out_directory .'/' . $fileName;        
       return  $in_orbit_flat_field_filename;
}


#******************************
# Subroutine GetODFDirectory
# Retrieves the directory-path
# of the ODF data files.
#******************************
sub GetODFDirectory($)
{
    my ($SASFile) = @_;  
    my($line, $length, $directory);    
    open (SASFILE, $SASFile) || SAS::fatal("OMFCHAIN","Unable to open SAS SUMMARY FILE $SASFILE");  
    $line = <SASFILE>;
    
    while ($line = <SASFILE>)
    {
        if ($line =~ "PATH")
        {        
            $length = length($line);
            $directory = substr($line, 5, $length - 6);
            #if ($directory eq "." or $directory eq "./")
            #{
            #    $length = length($SASFile);
        #        ###$directory = substr($SASFile, 0, $length - 32);
	#	$directory = substr($SASFile, 0);
        #    }
            close SASFILE;
            return $directory;              
        }
    }
    close SASFILE;
    SAS::fatal("OMFCHAIN", "Unable to find the ODF directory path");

}
#*******************************
# sub SetUpDirectoryPaths
#*******************************
sub SetUpDirectoryPaths
{
    my($input, $pos, $length, $directory);
    $inp_directory = stringParameter("inpdirectory");
    if ($inp_directory eq "")
    {        
        #*************************************************
        # If the SAS_ODF environment variable has been set
        # then set the input directory to it- otherwise
        # set the input directory to the current directory
        #*************************************************
        $input = $ENV{SAS_ODF};
        if ($input eq "")
        {
            $inp_directory = &GetCurrentDirectory;
            $ENV{SAS_ODF} = $inp_directory;  
            @SASFiles = <$inp_directory/*.SAS>;        
            $SASFile = shift @SASFiles;  
        }
        else
        {
            #*************************************************
            # If SAS_ODF is set to a .SAS file then need
            # to get the ODF directory from it
            #************************************************
            $pos = index($input, "SAS");
            if ($pos gt 0) 
            {
	        $length = length($input);
                $directory = substr($input, 1, $length - 4);
                $SASFile = $input;
		$inp_directory = &GetODFDirectory($input);
            }
            else
            {
                $inp_directory = $input;
                @SASFiles = <$inp_directory/*.SAS>;        
                $SASFile = shift @SASFiles;
            }
        }
    }
    $out_directory = stringParameter("outdirectory");
    if ($out_directory eq "")
    {
	$out_directory = &GetCurrentDirectory;
    }
      
    #&Message("inpdirectory = $inp_directory");
    #&Message("outdirectory = $out_directory");
 
}

#************************************
# Sub GetOmdetectParameters
#************************************
sub GetOmdetectParameters
{
    $omdetect_nsigma = realParameter("nsigma");
    $omdetect_contrast = realParameter("contrast");
    $omdetect_smoothsize = realParameter("smoothsize");
    $omdetect_boxscale = intParameter("boxscale");
    $omdetect_maxscale = intParameter("maxscale");
    $psfPhotometryEnabled = booleanParameter("psfphotometryenabled");
    $maxRawCountRate = realParameter("maxrawcountrate");
}

#************************************
# Sub GetOmregiontParameters
#************************************
sub GetOmregionParameters
{
    $omregion_srcradius = realParameter("srcradius");
    $omregion_bkginner = realParameter("bkginner");
    $omregion_bkgouter = realParameter("bkgouter");
}

#*****************************
# Subroutine Display
# Displays the given list
#****************************
sub Display($)
{
    my ($title, @List) = @_;
    my ($i) = 0;
    print("DISPLAYING LIST $title \n"); 
   
    for ($i = 0; $i < @List; $i++)
    {
        print("$i) $List[$i] \n");
    }
}

#***************************
# GetStringParameterList
# Gets the list of strings
# in the command line for a
# specified parameter name
#***************************
sub GetStringParameterList($)
{
    my($parameter) = @_;
    my $num = 0;
    my $i = 0;
    $num = parameterCount($parameter);
    my (@ParameterList) = ();
   
    if ($num eq 0)
    {
        return @ParameterList;
    }  
   for ($i = 0; $i < $num; $i++)
   {
        $ParameterList[$i] = stringParameter($parameter, $i);

    }
    &Display("parameter list", @ParameterList);
    return @ParameterList;    
}





