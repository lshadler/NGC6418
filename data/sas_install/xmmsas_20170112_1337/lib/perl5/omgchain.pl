#! /usr/bin/perl -w
#
# OMGCHAIN
#
# XMM Pipeline Processing System OMGCHAIN script
#
# Author: Vladimir Yershov (vny@mssl.ucl.ac.uk) May 31, 2001
#
# Description: This script runs the tasks required for to produce
#              PPS products from Grism Mode ODFs.
# Usage: 
#  omgchain -infile input_filename -outfile output_filename -noclobber noclobber
#
# $Id: module.f90,v 1.1 2003/03/06 10:21:08 gvacanti Exp $
#
#
# 27.10.2003 VNY - Created as a new task  
# 29.10.2009 VNY - checked the correctness of the usage of the input and output directories
# 31.10.2003 VNY - new parameters passed to omgprep 
# 07.11.2003 VNY parameters for image smoothing removed
# 10.11.2003 VNY protected against crushing if omgrismplot produced no plots
# 02.12.2003 VNY parameters src2spectrum and spectrumlegth are removed as misleading   
# 26.01.2004 VNY parameter extractionmode is activated           
# 01.02.2004 VNY Protected against crashing when the verbosity level is 
#            higher than seven.
# 03.02.2004 VNY two optional parameters to be used by omgrismplot are
#            included (plotflux and bkgdyscale)
# 24.02.2004 VNY use DAL was removed since it is not necessary anymore
# 19.03.2004 VNY adjusting the parameters spectrumHalfWidth, bkgWidth, etc. to better UV-extraction
# 20.05.2004 VNY ASCII-region file renamed from g.... to p.... (that 
#            is to be a product);
#            Engineering-2 sub-window files are sorted at the input 
#            according to their names in order to ensure the combination
#            of these sub-windows into a single full-frame image 
#            (SSC-SPR-3324)
# 29.05.2004 VNY Correction in the subroutine GetODFDirectory in order 
#            to protect the task from failing during its test on Mac-machines 
# 14.07.2004 VNY Default values for the spectra and background extraction 
#            regions are increased from 3 to 6 pixels; 
# 26.07.2004 VNY New parameters are included to control the output file names
#            in omgrism task (outspectralistset, extractfieldspectra)
# 27.07.2004 VNY Separate (new) file is introduced for the spectra regions
#   (SPR-3365)
# 08.09.2004 VNY setting the parameter outspectralistfile for the task omgrism 
# so as to produce the spectra list even if the field objects spectra are 
# not requested (SSC-SPR-3382).
# 30.05.2006 (VNY) Introducing OMATT for omputing the RA 
#             and DECs of the sources (the version 1.2 derived from 1.1, SSC-SPR-3605)
# 05.06.2006 (VNY) Skipping further processing of the exposure if its image is 
#             too small fot the spectrum extraction (analysing the exit flag of 
#             omgprep-1.1.1, SSC-SPR-3606)
# 09.11.2006 (VNY) the OMATT parameter is modified to produce the grism sky image.
#             Now the grism sky coordinates are computed with higher accuracy
#             (SSC-SPR-3633) 
# 31.01.2007 (VNY) the file names are modified such that they include the symbol 
#            with the observation mode idenifies (S, U or X). Previosly this symbol
#            was fixed (S) since it was thought that the observations are always sheduled. 
#            (fixing SSC-SPR-3646)
# 22.05.2007 (VNY)   The default parameter for the width of the spectrum extraction 
#             region was set to 8 pixels because this is what actually was used in 
#             the task omgrism due to a small bug. The bug was fixed in Omgrism-1.17 
#             (accompanying the SSC-SPR-3660) so that omgchain is also adjusted to 
#             keep the spectrum extraction region the same as before.  
# 2.11.2007 (VNY) Added a parameter for controlling the output of the new region
#            file with the newly detected point sources 
# 01.05.2008 (VNY) Adding new parameters to omgrismplot to plot spectra extraction
#             regions overlaying the grism rotated image
# 09.09.2008 (VNY) Adding new parameter to omgprep (produceunscatteredimage) to 
#            remove scattered light (central enhancement) from the rotated image
# 17.09.2008 (VNY) Introducing the parameter "removescatteredlight" (yes/no) to
#            enable the removing of the background scattered light features
# 20.07.2010 (VNY) Protected against a bug in pgplot which resulted in file
#            name truncation and disappearance of the output files (SSC-SPR-6622).
#
#use DAL;
use SAS;

#
my ($input_image_filename);
my ($redirect, $periodic_file_flag, $non_periodic_file_flag, $flatfield_file_flag);
my ($taskname, $date, $ommodmap_nsig, $ommodmap_nbox, $comment, $nsigma);#$timebinsize);
my ($create, $text1, $inp_directory, $text2, $out_directory, $orb_key, %file_list);
my (%mode_list, $mode_key);
my (%orb_list, $orbit_key, %obs_list, $message, $obs_key, %exp_list, $in_orbit_flat_field_filename);
my ($exp_key, $tracking_history_filename, $sas_dir, $periodic_hk_filename, $non_periodic_hk_filename);
my ($window_data_filename, $s, $tracking_history_plot_filename, $tracking_history_timeseries_filename);
my (%win_list, $win_key, $number_of_grisms, $image_filename, $intermediate_image_filename, $line, $filter_id);
my ($grism_id, $arg_list, $raw_image, $out_flat_filename);
my ($osw_list_intermediary_detect_filename, $second_osw_list_intermediary_detect_filename);
my ($image_pps_product_filename, $detectorCoordImageFileName, $rotatedImageFileName, $skyCoordImageFileName);
my ($smoothRotatedImageFileName, $modulo_8_product_filename, $sky_coord_pps_product_filename);
my ($undistImageFileName, $unscatteredImageFileName, $bkgImageFileName); 
my ($region_file, $second_region_file, $PPS_eventlist_file, $background_output);
my ($signifimage_output, $grismOutFileName,  $flat_field_filename);
my ($omgprep_usecat, $level_image_file);
my ($nSources, $source, $source_key);
my ($spectrum_pps_file, $spectrum_plot_file, $spectrum_pdf_file, $spectrum_pps_fileL);
my ($spectrum_plot_fileL, $spectrum_pdf_fileL, $spectrum_pps_fileR, $spectrum_plot_fileR);
my ($spectrum_plot_file0, $spectrum_PDF_file0);
my ($spectrum_pdf_fileR, $thx_file, $nph_file, $peh_file, $wdx_file, $SASFile, $SASFILE);
my ($exposureNo, $exposureSchedule, @ExposureNoList, %ExposureScheduleList, $filterName);
my (%ExposureFilterList, $pos, @FilterList, @ExposureFilterList, @EngineeringModeIMIList);
my (@E2IMIList, @E4IMIList, %ExposureType, $FFXFiles, $PFXFiles, $RFXFiles, $THXFiles);
my ($WDXFiles, $FAEFiles, $IMIFiles, $file);
my ($hasFF, $ffName, $workingDir, $combine, $mod8correction);
my ($bkgOffsetLeft, $bkgWidthLeft, $bkgOffsetRight, $bkgWidthRight, $spectrumLengthU, $spectrumLengthV);
my ($spectrumHalfWidth, $imageSmoothBoxWidth, $imageSmoothBoxHeight, $spectrumSmoothLength);
my ($src2spectrum, $src2spectrumU,  $src2spectrumV, $spectrumLength, $plotBinSize);
my ($extractionMode);
my ($scaleBkgPlot, $plotFlux);
my ($extractFieldSpectra, $outSpectraListFileName, $spectraRegionFileName, $spectraRegionPlotName);
my ($spectraRegionPDF, $addedRegionFile, $removeScatteredLight);
 
#    my (%wx0_list,%wy0_list, %wdx_list, %wdy_list, %filter_list);
sub omgchain 
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

    $redirect = 0;
    #*****************************************************
    # For test purposes only - BLANK OUT THE FOLLOWING
    # subroutine call before uploading
    # !!!!!!!!!!!!!!!! DO NOT FORGET !!!!!!!!!!!!!!!!!!!!!
    #*****************************************************
#    &CreateLogFile;


    #*******************************
    # Set up the directory paths
    #*******************************
    &SetUpDirectoryPaths;

    $periodic_file_flag = 0;
    $non_periodic_file_flag = 0;
    $flatfield_file_flag = 0;

    $taskname = 'OMGCHAIN';

    #$VERSION = '1.10';
    $date = &date_time;
    
    #$ommodmap_nsig=3;
    #$ommodmap_nbox=16; 
    # VNY 30.05.2008
    $ommodmap_nsig=6;
    $ommodmap_nbox=16; 

    # getting parameters    
    $comment = stringParameter("comment");
    $nsigma = realParameter("nsigma"); # The sigma parameter to define the detection level for omdetect
    #  New parameter combine (for the possibility to combine the Engineering-2 data)
    $combine = booleanParameter("combine");
    # 12.09.2008 New parameter to enable removing the scattered light (central enhancement)
    $removeScatteredLight=booleanParameter("removescatteredlight");

    $mod8correction = intParameter("mod8correction");
#
    $bkgOffsetLeft = realParameter("bkgoffsetleft");
    $bkgWidthLeft = realParameter("bkgwidthleft");
    $bkgOffsetRight = realParameter("bkgoffsetright");
    $bkgWidthRight = realParameter("bkgwidthright");

    $scaleBkgPlot = booleanParameter("scalebkgplot");
    $plotFlux = intParameter("plotflux");

# VNY 26.07.2004
    $extractFieldSpectra = booleanParameter("extractfieldspectra");
    $addedRegionFile = booleanParameter("addedregionfile");
    $spectrumLengthU = 1000.0;
    $spectrumLengthV = 400.0;
    $spectrumHalfWidth = realParameter("spectrumhalfwidth");

    $src2spectrumU = 1100.0;
    $src2spectrumV = 800.0;

    $spectrumSmoothLength = intParameter("spectrumsmoothlength");
    $extractionMode=intParameter("extractionmode");
    $imageSmoothBoxWidth = 10.0;
    $imageSmoothBoxHeight = 10.0;
    $plotBinSize = intParameter("plotbinsize");
#
    if ($plotBinSize == 0) { $plotBinSize=1};

    $create = " Running SAS task $taskname V$VERSION $date";
    $text1 = " Input directory = $inp_directory";
    $text2 = " Output directory = $out_directory";

    &HighlightedMessage("*", $create,$comment, "   ", $text1, $text2);

    if ($combine)
    {
	$message="Engineering-2 Mode sub-windows (if they exist) will be combined";
    }
    else
    {
	$message="Engineering-2 Mode windows will not be combined"; 
    }
    &Message($message);

# Return SAS_VERBOSITY to its requested level
    if ($SASVERBOSITY > 7) 
    {
	$ENV{SAS_VERBOSITY} = $SASVERBOSITY;
    }

    #************************************************
    # Get a list of the files in the current directory
    #************************************************
    &GetListOfDataFiles;
    #foreach $mode_key (keys(%mode_list))
    #{
    #print("L202 mode_key=$mode_key   mode_list: $mode_list{$mode_key}\n")
    #}

    #************************************************** 
    # Check for the presence of the house keeping files
    #**************************************************
    &CheckForHouseKeepingFiles;

      
    # Run the chain.
    # Loop over all observations.
    foreach $orb_key (keys(%orb_list))
    {
	#********************************************
	# Process the data for each orbit in the list
	#********************************************
	&ProcessOrbit($orb_key);  
    } # foreach orb_key
} # sub omfchain

#=========================================================================
#
# OMGCHAIN subroutine section
#
#=========================================================================
#***************************
# Subroutine ProcessOrbit
#***************************
sub ProcessOrbit($)
{
    my ($orb_key) = @_; 

    $message = "      Processing orbit ". $orb_key;
    &HighlightedMessage("*", $message);
    foreach $obs_key (keys(%obs_list))
    {
	$message = "       Observation $obs_key \n";
	&Message($message);
	if ($hasFF)
	{
	    #$message = "Using flatfield $in_orbit_flat_field_filename \n";
	    $message="Using flatfield (hasFF= $hasFF) \n";
	    &Message($message);  
	    $message="ffName= $ffName \n";
	    &Message($message);
	    $flat_field_filename=$ffName;
	}
	else
	{
	    $flat_field_filename="";
	}
	# Loop over all exposures.
	foreach $exp_key (sort(keys(%exp_list)))
	{
	    &ProcessExposure($orb_key, $obs_key, $exp_key);
	} # foreach exp_key
    } # foreach obs_key
} # end ProcessOrbit

#******************************
# Subroutine ProcessExposure
#******************************
sub ProcessExposure($)
{
    my ($orb_key, $obs_key, $exp_key) = @_; 
    my ($wx0, $wy0, $wdx, $wdy, $gwin_key);
    my (%wx0_list,%wy0_list, %wdx_list, %wdy_list, %filter_list);
    my (%process_list);
    my (@vis_win, @vis_wx0, @vis_wy0, @vis_wdx, @vis_wdy, @vis_proc, $vis_index);
    my (@uv_win, @uv_wx0, @uv_wy0, @uv_wdx, @uv_wdy, @uv_proc, $uv_index);

    $message = "           Exposure  ". $exp_key;
    &HighlightedMessage("*",$message);
    # Check consistency of odf.

    if (exists($file_list{$orb_key . $obs_key . $exp_key . "00THX"})) 
    {
	$message = "Tracking history file: O.K.";
	&Message($message);
	$tracking_history_filename = $file_list{ $orb_key . $obs_key . $exp_key . "00THX"};
    }	 
    else    
    {
	$message = "Tracking history file for the exposure $exp_key is missing";
	&Message($message);
	$sas_dir = $ENV{SAS_DIR};
	#***********************************
	# Create a dummy THX
	#***********************************
	$message = "Creating a dummy file for tracking history";
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
	$message = "Window data file for the exposure $exp_key is missing";
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
	$tracking_history_plot_filename = "p" . $obs_key . "OM" . $s . $exp_key . "TSHPLT" . "0000.PS";
        ## 
	$message = "Tracking history plot file: " . $tracking_history_plot_filename;
	&Message($message);
        ##                 
	$s= substr($non_periodic_hk_filename, 18, 1);
	$tracking_history_timeseries_filename =  "p" . $obs_key . "OM" . $s .  $exp_key . "TSTRTS0000.FIT";
        ##   VNY 07.03.03
	$message = "Tracking history timeseries file: " . $tracking_history_timeseries_filename;
	&Message($message);
        ##
#### Check if the windows in the given exposure are splits of the larger window
#######################     
	$number_of_grisms=0;
	$vis_index=0; $uv_index=0;
	# VNY 20.05.2004 Sorting the window keys list in order to get the subwindows 
	# in the increasing order 
	#foreach $win_key (keys(%win_list))
	foreach $win_key (sort(keys(%win_list)))
	{ 
	    if (exists($file_list{$orb_key . $obs_key . $exp_key . $win_key . "IMI"}))
	    {
		$image_filename = $file_list{$orb_key . $obs_key . $exp_key . $win_key . "IMI"};     
		if (open(IMIFILE, $inp_directory . '/' . $image_filename))
		{
		    $message="Found image file $image_filename"; 
		    &Message($message);
		}
		$line=<IMIFILE>;
		$filter_id=0;
		if ($line=~/FILTER  = +(\d\d\d\d)/i) 
		{ 
		    $filter_id=$1;
		}
		elsif ($line=~/FILTER  = +(\d\d\d)/i) 
		{
		    $filter_id=$1;
		}
		$wx0=-1; $wy0=-1; $wdx=-1; $wdy=-1;
		if ($line=~/WINDOWX0= +(\d\d\d\d)/i || $line=~/WINDOWX0= +(\d\d\d)/i || $line=~/WINDOWX0= +(\d\d)/i || $line=~/WINDOWX0= +(\d)/i)
		{
		    $wx0=$1;
		}
		if ($line=~/WINDOWY0= +(\d\d\d\d)/i || $line=~/WINDOWY0= +(\d\d\d)/i || $line=~/WINDOWY0= +(\d\d)/i || $line=~/WINDOWY0= +(\d)/i)
		{
		    $wy0=$1;
		}
	
		if ($line=~/WINDOWDX= +(\d\d\d\d)/i || $line=~/WINDOWDX= +(\d\d\d)/i || $line=~/WINDOWDX= +(\d\d)/i || $line=~/WINDOWDX= +(\d)/i)
		{
		    $wdx=$1;
		}
		if ($line=~/WINDOWDY= +(\d\d\d\d)/i || $line=~/WINDOWDY= +(\d\d\d)/i || $line=~/WINDOWDY= +(\d\d)/i || $line=~/WINDOWDY= +(\d)/i)
		{
		    $wdy=$1;
		}
		close(IMIFILE);
		#$message="L361  Image file closed";
		#&Message($message);
		##
		#print "L364 filter_id=$filter_id \n";
		if ($filter_id==200) # add to the list of visual grism images
		{
		    $vis_win[$vis_index]=$win_key;
		    $vis_wx0[$vis_index]=$wx0;
		    $vis_wy0[$vis_index]=$wy0;
		    $vis_wdx[$vis_index]=$wdx;
		    $vis_wdy[$vis_index]=$wdy;
		    $vis_proc[$vis_index]=1;
		    $vis_index++;
		}
		if ($filter_id==1000) # add to the list of UV grism images
		{
		    $uv_win[$uv_index]=$win_key;
		    $uv_wx0[$uv_index]=$wx0;
		    $uv_wy0[$uv_index]=$wy0;
		    $uv_wdx[$uv_index]=$wdx;
		    $uv_wdy[$uv_index]=$wdy;
		    $uv_proc[$uv_index]=1;
		    $uv_index++;
		}
	    } # if exists IMI
	} # foreach win_key 
#######################
# Produce tracking history products.
	# Process UV-images
	if ($uv_index > 0)
	{
	    &ProcessWindows($orb_key, $obs_key, $exp_key, $filter_id, $uv_index, @uv_win, @uv_wx0, @uv_wy0, @uv_wdx, @uv_wdy, @uv_proc);
	}
        #
	# Process Visual images
	if ($vis_index > 0)
	{
	    &ProcessWindows($orb_key, $obs_key, $exp_key, $filter_id, $vis_index, @vis_win, @vis_wx0, @vis_wy0, @vis_wdx, @vis_wdy, @vis_proc);
	} 
#
    } # if exists (WDX NPH PEX)
    else
    {
	$message = "*** Warning ***";
	&Message($message);
	
	$message = "Exposure ". $exp_key . " in observation " . $obs_key . " is missing a file";
	&Message($message);
                   
	$thx_file = $orb_key . "_" . $obs_key . "_OMS" . $exp_key . "00THX.FIT";
	$message = "Please check if the file  ". $thx_file . " is in the ODF";
	&Message($message);
	
	$nph_file = $orb_key . "_" . $obs_key . "_OMS" . $exp_key . "00NPH.FIT";
	$message = "Please check if the file  ". $nph_file . " is in the ODF";
	&Message($message);
	
	$peh_file = $orb_key . "_" . $obs_key . "_OMS" . $exp_key . "00PEH.FIT";
	$message = "Please check if the file  ". $peh_file . " is in the ODF";
	&Message($message);
           
        
	$wdx_file = $orb_key . "_" . $obs_key . "_OMS" . $exp_key . "00WDX.FIT";
	$message = "Please check if the file  ". $wdx_file . " is in the ODF";
	&Message($message);
    }
} # end sub ProcessExposure

sub ProcessWindows($)
{
   my ($orb_key, $obs_key, $exp_key, $filter_id, $index, @mixed) = @_;
   my (@win, @wx0, @wy0, @wdx, @wdy, @proc);
   my ($wx_edge, $dx_edge, $wy_edge, $dy_edge);
   my (@comb_list, $icomb, $ii, $jj, $kk, $grism_id);

   $message=" Filter value does not correspond to a grism";
   if ($filter_id==200) 
   {
       $grism_id="Grism 2 (visual)";
       $message= ("Filter value corresponds to $grism_id");
   }
   if ($filter_id==1000) 
   {
       $grism_id="Grism 1 (UV)";
       $message= ("Filter value corresponds to $grism_id");
   }
   &Message($message);

   # Recovering the six lists of parameters
   if ($index > 0)
   {
       $ii=0;
       while ($ii < $index)
       {
	   $win[$ii]=$mixed[$ii];
	   $wx0[$ii]=$mixed[$ii+$index];
	   $wy0[$ii]=$mixed[$ii+2*$index];
	   $wdx[$ii]=$mixed[$ii+3*$index];
	   $wdy[$ii]=$mixed[$ii+4*$index];
	   $proc[$ii]=$mixed[$ii+5*$index];
	   $ii++;
       }
   }

   $ii=0;
   while ($ii < $index)
   {
       if ($proc[$ii] >=0)
       {
	   $wx_edge=$wx0[$ii]; $dx_edge=$wdx[$ii]; $wy_edge=$wy0[$ii]; $dy_edge=$wdy[$ii];
	   $message= "Window $win[$ii] will be processed";
	   &Message($message);

	   $icomb=0;
	   $comb_list[$icomb]=$win[$ii];
	   # Combine images only if the parameter $combine is yes
	   if ($combine)
	   {
	       $jj=$ii;
	       while ($jj < $index-1)
	       {
		   $jj++;
		   if ($wx0[$jj] == $wx_edge+$dx_edge && $wy0[$jj] == $wy_edge && $wdy[$jj] == $dy_edge)
		   {
		       $icomb++;
		       $comb_list[$icomb]=$win[$jj];
		       $wx_edge=$wx_edge+$dx_edge;
		       $dx_edge=$wdx[$jj];
		       $wy_edge=$wy0[$jj];
		       $dy_edge=$wdy[$jj];
		       $proc[$jj]=-1;
		   }
	       }

	       #  Check if the iput files exist
	       $kk=0;
	       while ($kk <= $icomb)
	       {

		   if (exists($file_list{$orb_key . $obs_key . $exp_key . $comb_list[$kk] . "IMI"}))
		   {
		       $input_image_filename = $file_list{$orb_key . $obs_key . $exp_key . $comb_list[$kk] . "IMI"};
		   }
		   $kk++;
	       }
	   } # end if combine == yes
	   # Processing the list of windows (some of which can be combined
	   # at the previous steps)
	   $kk=@comb_list; 
	   &ProcessWindow($orb_key, $obs_key, $exp_key, @comb_list);
       } # end if win[ii]>=0
       else
       {
	   $message="The window $win[$ii] is in the combined list and will not be processed ";
	   &Message($message);
       }
       $ii++;
   } # end while $ii <= $index
} # end sub ProcessWindows

#******************************
# Subroutine ProcessWindow
#******************************
sub ProcessWindow($)
{
    my ($orb_key,$obs_key, $exp_key, @comb_list) = @_;
    my ($i_win, $n_win); # Number of windows in the list
    my ($combinedFileName, $arg_list, $kk);
    my (@ExposureImageList, $combinedImageWasProduced);
    my ($mode_symbol);

    $n_win=@comb_list;
    #$message="The combined list for this window contains $n_win elements";
    #&Message($message);

#  creating the list of files for OMCOMB
    $combinedFileName="g" . $obs_key . "OMS" . $exp_key . "CIMAGE0000.FIT";
    $mode_symbol="S";
    $combinedImageWasProduced=0;

    $message = "Number of sub-windows found: $n_win ";
    &Message($message);  

    # Combining images if comb_list contains four elements, otherwise process only the first image
    if ($combine  && $n_win == 4)
    {
	$kk=0;
	while ($kk < $n_win)
	{
	    if (exists($file_list{$orb_key . $obs_key . $exp_key . $comb_list[$kk] . "IMI"}))
	    {
		$ExposureImageList[$kk] = $inp_directory . '/' . $file_list{$orb_key . $obs_key . $exp_key . $comb_list[$kk] . "IMI"};
		$mode_symbol=$mode_list{$orb_key . $obs_key . $exp_key . $comb_list[$kk] . "IMI"};
		$combinedFileName="g" . $obs_key . "OM" .$mode_symbol . $exp_key . "CIMAGE0000.FIT";
	    }
	    $kk++;
	}    
	$message = "... Combining sub-windows (Engineering-2 Mode data) ... ";
	&Message($message);  
	&HighlightedMessage("*", "... omcomb ...");

	$arg_list= "imagesets=\"" . "@ExposureImageList" . "\"" . " outset=\"" . "$out_directory" . '/' . "$combinedFileName" . "\"";
	print(" omcomb arguments:  $arg_list \n");
   
        system ("omcomb $arg_list") && SAS::fatal("Task Failure", "omcomb");
	$message="... Produced a combined image $combinedFileName ... ";
	&Message($message);
	$combinedImageWasProduced=1;
    }
    $i_win=0;
    # Processing windows.
    $message = "... Running Tracking tasks ... ";
    ###&Message($message);  
    #
    # omprep.
# Loop over all windows.
#  Temporarily the window are processes one by one (without combining them) 
    $i_win=0;
    # Processing only the first image 
    #while ($i_win < $n_win)
    {

	# Check consistancy of odf.
	if (exists($file_list{$orb_key . $obs_key . $exp_key . $comb_list[$i_win] . "IMI"}))
	{
	    $message =  " Window $comb_list[$i_win]";
	    &HighlightedMessage("-", $message);
	    # Set variables.
	    if ($combine && $combinedImageWasProduced)
	    {
		$input_image_filename= $out_directory . '/' . $combinedFileName;
	    }
	    else
	    {
		$input_image_filename = $inp_directory . '/' . $file_list{$orb_key . $obs_key . $exp_key . $comb_list[$i_win] . "IMI"};
	    }
	    ### VNY 07.03.03 Check if the filter is grism
	    $message = "Image file name: ". $input_image_filename;
	    &Message($message);
	    if (open(IMIFILE, $input_image_filename))
	    {
		#$message="Image file opened"; 
		#&Message($message);
	        $line=<IMIFILE>;
		$filter_id=0;
		if ($line=~/FILTER  = +(\d\d\d\d)/i) 
		{
		    $filter_id=$1;
		}
		elsif ($line=~/FILTER  = +(\d\d\d)/i) 
		{
		    $filter_id=$1;
		}

		close(IMIFILE);
		#$message=" Image file closed";
		#&Message($message);
		### Processing only the grism images  
		if ($filter_id==200 || $filter_id==1000)
		{
		    $message="Filter value does not correspond to a grism";
		    if ($filter_id==200) 
		    {
			$grism_id="Grism 2 (visual)";
			$message="Filter value corresponds to $grism_id";
		    }
		    if ($filter_id==1000) 
		    {
			$grism_id="Grism 1(UV)";
			$message="Filter value corresponds to $grism_id";
		    }
		    &Message($message);
###
		    $raw_image =  "g" . $input_image_filename;
		    #$s = substr($input_image_filename,18, 1);		    
		    #$s="S";
		    $s=$mode_symbol;

		    $out_flat_filename = "g" . $obs_key . "OM" . $s .  $exp_key . "FLAFLD" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $osw_list_intermediary_detect_filename = "p" . $obs_key . "OM" . $s .  $exp_key . "SWSRLI" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $second_osw_list_intermediary_detect_filename = "p" . $obs_key . "OM" . $s .  $exp_key . "SWSRLI" . substr($comb_list[$i_win], 1,1) . "001.FIT";
		    $image_pps_product_filename = "p" . $obs_key . "OM" . $s .  $exp_key . "IMAGE_" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $intermediate_image_filename = "g" . $obs_key . "OM" . $s .  $exp_key . "IMAGEI" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $detectorCoordImageFileName = "g" . $obs_key . "OM" . $s .  $exp_key . "IMAGE_" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $skyCoordImageFileName = "g" . $obs_key . "OM" . $s .  $exp_key . "SIMAGE" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $rotatedImageFileName = "p" . $obs_key . "OM" . $s .  $exp_key . "RIMAGE" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $smoothRotatedImageFileName = "s" . $obs_key . "OM" . $s .  $exp_key . "IMAGE_" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $undistImageFileName = "u" . $obs_key . "OM" . $s .  $exp_key . "IMAGE_" . substr($comb_list[$i_win], 1,1) . "000.FIT";

		    $unscatteredImageFileName = "g" . $obs_key . "OM" . $s .  $exp_key . "RIMNSC" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $bkgImageFileName = "g" . $obs_key . "OM" . $s .  $exp_key . "RIMBKG" . substr($comb_list[$i_win], 1,1) . "000.FIT";

		    $modulo_8_product_filename = "g" . $obs_key . "OM" . $s .  $exp_key . "MOD8MP" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $sky_coord_pps_product_filename = "p" . $obs_key . "OM" . $s . $exp_key . "SIMAGE" . substr($comb_list[$i_win], 1,1) . "000.FIT";
		    $region_file = "p" . $obs_key . "OM" . $s .  $exp_key . "REGION" . substr($comb_list[$i_win], 1,1) . "000.ASC";
		    $second_region_file = "p" . $obs_key . "OM" . $s .  $exp_key . "REGION" . substr($comb_list[$i_win], 1,1) . "001.ASC";
		    $spectraRegionFileName = "p" . $obs_key . "OM" . $s .  $exp_key . "SPCREG" . substr($comb_list[$i_win], 1,1) . "001.ASC";
		    $PPS_eventlist_file = "g" . $obs_key . "OM" . $s .  $exp_key . "EVLIST" . substr($comb_list[$i_win], 1,1) . "000.FIT";

		    $spectraRegionPlotName = "p" . $obs_key . "OM" . $s .  $exp_key . "SPCREG" . substr($comb_list[$i_win], 1,1) . "001.PS";
		    $spectraRegionPDF = "p" . $obs_key . "OM" . $s .  $exp_key . "SPCREG" . substr($comb_list[$i_win], 1,1) . "001.PDF";		    
# temporary files for testing purposes
		    $background_output= "tmp_background" . $obs_key . "OM" . $s .  $exp_key . "BACKGR" . substr($comb_list[$i_win], 1,1) .  ".FIT";
		    $signifimage_output="tmp_signifimage"  . $obs_key . "OM" . $s .  $exp_key . "SIGNIF" . substr($comb_list[$i_win], 1,1) . ".FIT";
		    $grismOutFileName="p" . $obs_key . "OM" . $s .  $exp_key . "SPECTR" . substr($comb_list[$i_win], 1,1) . "000.FIT"; 
# VNY 26.07.2004
################

		    if ($extractFieldSpectra)
		    {
			$message="Available spectra of the field objects will be extracted (by request)";
			$outSpectraListFileName="p" . $obs_key . "OM" . $s .  $exp_key . "SPECLI" . substr($comb_list[$i_win], 1,1) . "000.FIT"; 
			&Message($message);
		    } 
		    else
		    {
			$message="Extraction of the target object spectrum (no field spectra will be extracted)";
			&Message($message);
			$outSpectraListFileName="";
# VNY 07.09.2004 producing the output spectra list for both cases
			$outSpectraListFileName="p" . $obs_key . "OM" . $s .  $exp_key . "SPECLI" . substr($comb_list[$i_win], 1,1) . "000.FIT"; 
		    }
################ 
	
# Produce fast mode products.

		    $message = "...  Running Grism Mode tasks ... ";
		    &Message($message);
#############
		    #*********************************
		    # omprep
		    #*********************************
		    &HighlightedMessage("*", "omprep");
		        $arg_list = "set=$input_image_filename" .
			    " nphset=$inp_directory/$non_periodic_hk_filename" .
			    " pehset=$inp_directory/$periodic_hk_filename" .
			    " wdxset=$inp_directory/$window_data_filename" .
                            " modeset=4" .
			    " outset=$out_directory/$intermediate_image_filename";
		    &Message("omprep $arg_list");
    #**************************************************************
    # Modified so that if omprep fails it just skips the observation,
    # but does not kill the chain (1.11.2000)
    #**************************************************************
    system("omprep $arg_list");

    my $exit_value = $? >> 8;   # 0 okay, 1 call fatal called, or some other disaster
    if ($exit_value == 1) # Failure in omprep 
    { 
        &HighlightedMessage("*", "omprep has detected an error- this observation will not be processed");
        return;

    }     

##############
   
		    #***************************************
		    # ommodmap
		    #***************************************
		    &HighlightedMessage("*", "... ommodmap ...");
		       $arg_list = "set=$out_directory/$intermediate_image_filename" .
			" flatset=$flat_field_filename" .
			    #" applyflat=yes" .
				#" multiplyflat=yes" .
				    " mod8product=yes" .
					" mod8set=$out_directory/$modulo_8_product_filename" .
					    " outset=$out_directory/$detectorCoordImageFileName" .
						" outflatset=$out_directory/$out_flat_filename" . 
						    " nsig=$ommodmap_nsig" .
							" nbox=$ommodmap_nbox" .
							    " mod8correction=$mod8correction";  
		    &Message("ommodmap $arg_list");
		    system("ommodmap $arg_list") && SAS::fatal("Task Failure","ommodmap failed.");
		    
		    #***********************************************
		    # omgprep
		    #***********************************************
		    &HighlightedMessage("*", "... omgprep ...");	    
		    $omgprep_usecat="F";
#		    $arg_list = "set=$out_directory/$detectorCoordImageFileName" .
#			#" sourcelistset=$out_directory/$osw_list_intermediary_detect_filename" . 
#			    " outset=$out_directory/$rotatedImageFileName";# .
#				 #   " undistset=$out_directory/$undistImageFileName";

#		    $arg_list = "set=$out_directory/$detectorCoordImageFileName" .
#			    " outset=$out_directory/$rotatedImageFileName" .
#				    " undistset=$out_directory/$undistImageFileName";

		    print(" removeScatteredLight= $removeScatteredLight\n");
		    if ($removeScatteredLight) 
		    {
			$arg_list = "set=$out_directory/$detectorCoordImageFileName" .
			    " outset=$out_directory/$rotatedImageFileName" .
			       " undistset=$out_directory/$undistImageFileName".
			         " removescatteredlight=$removeScatteredLight".
			             " backgroundset=$out_directory/$bkgImageFileName";
		    }
		    else
		    {
			$arg_list = "set=$out_directory/$detectorCoordImageFileName" .
			    " outset=$out_directory/$rotatedImageFileName" .
			       " undistset=$out_directory/$undistImageFileName";
		    }
		    
		    &Message("omgprep $arg_list");
		    system("omgprep $arg_list");

		    my $exit_value2 = $? >> 8;   # 0 okay, otherwise do not continue
		    #print(" ------------------------ \n");
		    #print(" exit_value2=$exit_value2 \n");
		    #print(" ------------------------ \n");

		    if ($exit_value2 == 1) # Failure in omgprep 
		    { 
			&HighlightedMessage("*", "omgprep has detected a problem  - this exposure will not be processed");
			return;			
		    }     

		    $level_image_file="LEVEL.FIT";
		    
		    #**************************************************
		    # omdetect (principal run)
		    #**************************************************
		    $message = " ... omdetect ... ";
		    &HighlightedMessage("*", $message);
		    #$arg_list = "nsigma=2" .
		    $arg_list = "nsigma=$nsigma" .
			#" minsignificance=0" .
			#" set=$out_directory/$smoothRotatedImageFileName" .
			    " set=$out_directory/$rotatedImageFileName" .
			    #" levelimage=$out_directory/$level_image_file" .
				" regionfile=$out_directory/$second_region_file" .  
				    " outset=$out_directory/$second_osw_list_intermediary_detect_filename" ;
               
		    &Message("omdetect $arg_list");
		    
		    system("omdetect $arg_list") && die("omdetect failed\n");

		    # ***********************************************
		    $nSources=0; # Number of lines in the region_file
		    open (REGFILE, "$out_directory/$second_region_file");
		    while ($line=<REGFILE>)
		    {
			$nSources=$nSources+1;
		    }
		    
		    $message = " Number of detected sources = ". $nSources;
		    &Message($message);
		    
		    close(REGFILE);          

		    #********************************************************
		    #   OMATT 
		    #*********************************************************
        
		    &HighlightedMessage("*", "... omatt ... ");
                    
		    $arg_list = "set=" .  $out_directory . '/' . $rotatedImageFileName . 
			" sourcelistset=" .  $out_directory . '/' . $second_osw_list_intermediary_detect_filename  . 
			" ppsoswset=" .  $out_directory . '/' . $skyCoordImageFileName .
			" usecat=F" ;
                                 
                     
                      system("omatt $arg_list") && SAS::fatal("Task Failure","omatt failed.");

		    #***************************************
		    # omgrism
		    #***************************************
		    &HighlightedMessage("*", "... omgrism ...");
		    
		    $arg_list = "set=$out_directory/$rotatedImageFileName" .
			" sourcelistset=$out_directory/$second_osw_list_intermediary_detect_filename" .
			    " outset=$out_directory/$grismOutFileName" . 
			  " bkgoffsetleft=$bkgOffsetLeft" .
			      " bkgwidthleft=$bkgWidthLeft" .
				  " bkgoffsetright=$bkgOffsetRight" .
				      " bkgwidthright=$bkgWidthRight" .
					  " spectrumhalfwidth=$spectrumHalfWidth" .
				     " spectrumsmoothlength=$spectrumSmoothLength" .
					 " extractionmode=$extractionMode".
					     " extractfieldspectra=$extractFieldSpectra" .
						 " regionfile=$out_directory/$second_region_file" .
						     " spectraregionfile=$out_directory/$spectraRegionFileName" .  
							 " outspectralistset=$outSpectraListFileName" .
							    " addedregionfile=$addedRegionFile";
		    
		    &Message("omgrism $arg_list");
		    system("omgrism $arg_list") && SAS::fatal("Task Failure","omgrism failed.");
		    
		    #$message = " Number of detected sources = ". $nSources;
		    #&Message($message);

		    #****************************************
		    # omgrismplot (V1.1)
		    #****************************************
		    ### calling a new version of OMGRISMPLOT for plotting all the spectra in one file
		    $spectrum_plot_file0 = "g" . $obs_key . "OM" . $s .  $exp_key . "SPECTR" . substr($comb_list[$i_win], 1,1) . "000.PS";
		    $spectrum_PDF_file0 = "p" . $obs_key . "OM" . $s .  $exp_key . "SPECTR" . substr($comb_list[$i_win], 1,1) . "000.PDF";
		    if ( -e $out_directory . '/' . $grismOutFileName)
		    {
			$message = "... omgrismplot ...  ";
			&HighlightedMessage("*",$message);
			&Message("OMGRISM spectrum pps file:  $grismOutFileName");
			
			### 10.10.05 reducing the string in calling PGBEG by setting the PGPLOT_TYPE variable
			$ENV{PGPLOT_TYPE}="ps";
						
			$arg_list = "set=" .  $out_directory . '/' . $grismOutFileName .
			    " scalebkgplot=$scaleBkgPlot" . 
				" binsize=$plotBinSize" . 
				    " plotflux=$plotFlux" . 
					#" plotfile=" .  $out_directory . '/' . $spectrum_plot_file0 .
					" plotfile=t.ps" .
					  " spectraregionfile=". $out_directory . '/' . $spectraRegionFileName .
                                            #" regionplotfile=" . $out_directory . '/' . $spectraRegionPlotName .
                                            " regionplotfile=r.ps" .
					      " rotatedimageset=" . $out_directory . '/' . $rotatedImageFileName ;

			# The pgplot program truncates the long file names, so using a short name
			# and renaming it

			system("omgrismplot $arg_list") && die("omgrismplot failed\n");

			rename("t.ps", "$out_directory/$spectrum_plot_file0");
			rename("r.ps", "$out_directory/$spectraRegionPlotName");
			print("spectraRegionFileName=$out_directory/$spectraRegionFileName \n");
# converts PS to PDF
			if ( -e $out_directory . '/' . $spectrum_plot_file0)
			{
			    &Message("Converting the spectrum PostScript file to PDF"); 
			    system ("ps2pdf  " . $out_directory . '/' . $spectrum_plot_file0 . '  ' .  $out_directory . '/' . $spectrum_PDF_file0 );
			}
			else {
			    &Message("The required spectrum PostScript file is missing"); 
			}

			if ( -e $out_directory . '/' . $spectraRegionPlotName)
			{
			    &Message("Converting the spectrum region PostScript file to PDF"); 
			    system ("ps2pdf  " . $out_directory . '/' . $spectraRegionPlotName . '  ' .  $out_directory . '/' . $spectraRegionPDF );
			}
			else {
			    &Message("The spectrum region PostScript file is missing"); 
			}

		    }
		    else
		    {
			&Message("File $grismOutFileName does not exist: no plot produced"); 
		    }

		} # if grism_id=200 or 1000
	    } # if open IMI
	    else
	    {
		$message="Failure openning the image file to be processed"; 
		&Message($message);
	    }
	} #if exists IMI
	else
	{
	    $message="Image file for this window does not exist"; 
	    &Message($message);
	}
	$i_win++;
    } # for each win_key

# Clean things up and do some stuff.

    unlink($out_directory . '/' . "tmp_tracking");
} # end sub ProcessWindow


#************************************************************
# Subroutine GetListOfDataFiles
# Get a list of file names in the current working directory.
#************************************************************
sub GetListOfDataFiles
{
    my ($p1, $p2, $p3, $p4, $p5, $p6);
    my (%ffx_list);
  opendir(INDIR, $inp_directory) || SAS::fatal("OMGCHAIN", "Unable to open $inp_directory");

  # Sort the file names according to observation, exposure, window and file type.
  #$flat_field_filename=$inp_directory . '/superflat_withoutLED.fits';
  $periodic_file_flag = 0;
  $non_periodic_file_flag = 0;      

  $FFXFiles = 0;
  $PFXFiles = 0;
  $RFXFiles = 0;
  $THXFiles = 0;
  $WDXFiles = 0;
  $FAEFiles = 0;
  $IMIFiles = 0;

# Sort the file names according to observation, exposure, window and file type.

#while ($file = readdir(INDIR))
#    {
# VNY 11.06.2002 Changes in order to make it working at Jupiter machine
foreach $file (glob("$inp_directory/*"))
    {
	$file=~ s/^.+\///;
	#if ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM[S|U|X]([0-9a-zA-Z]{3})([0-9]{2})([A-Z]{3}).FIT/i)
	if ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([A-Z]{1})([0-9a-zA-Z]{3})([0-9]{2})([A-Z]{3}).FIT/i)
	{ 

	    #$p1=$1;$p2=$2;$p3=$3;$p4=$4;$p5=$5; #  V.Y. 01.05.2001
	    $p1=$1;$p2=$2;$p3=$4;$p4=$5;$p5=$6; #  V.Y. 31.01.2007
	    $p6=$3;
	    #print("L923 p1=$p1 p2=$p2 p3=$p3 p4=$p4 p5=$p5 p6=$p6\n");
            # File list.
            $file_list{"$p1$p2$p3$p4$p5"} = "$file";
            $mode_list{"$p1$p2$p3$p4$p5"} = "$p6";

            if ($file =~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM[S|U|X][0-9a-zA-Z]{3}[0-9]{2}FFX.FIT/i)
	    {
                $FFXFiles = $FFXFiles + 1;  
		$ffx_list{"$p1$p2"} = "$inp_directory/$file";
		$flat_field_filename = $file;
		$in_orbit_flat_field_filename = $file;;  
		$flatfield_file_flag = 1;
	    }
            else
	    {

		if ($file !~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})PEH.FIT/i
			 && $file !~ /^([0-9A-Z]{4})_([0-9A-Z]{10})_OM([[0-9a-zA-Z]{4})([0-9]{2})NPH.FIT/i)
       
		    {
			#$flatfield = $file;
	       
			if ($file =~/IMI/i)
			{
							       
			    # Orbit number list
			    $orb_list{$p1}="$p1";

			    # Observation list.
			    $obs_list{"$p2"} = "$p1";

			    # Exposure list.
			    $exp_list{"$p3"} = "$p2";

		            # Window list. 
                            $win_list{"$p4"} = "$p3";

                            $IMIFiles = $IMIFiles + 1;
                        }
               
                        if  ($file=~ /FAE/i)
		        {
		          $FAEFiles = $FAEFiles + 1;
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

} # end sub GetListOfDataFiles

#**************************************************
# sub CheckForHouseKeepingFiles
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
} #end sub  CheckForHouseKeepingFiles



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
    open (STDOUT, ">omgchain_log");
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

#******************************
# Subroutine GetODFDirectory
# Retrieves the directory-path
# of the ODF data files.
#******************************
sub GetODFDirectory($)
{
    my ($SASFile) = @_;  
    my ($directory, $length);
    open (SASFILE, $SASFile) || SAS::fatal("OMGCHAIN","Unable to open SAS SUMMARY FILE $SASFILE"); 
 
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
            #    $directory = substr($SASFile, 0, $length - 32);
            #}
            close SASFILE;
            return $directory; 
             
        }
    }
    close SASFILE;
    SAS::fatal("OMGCHAIN", "Unable to find the ODF directory path");

}
#*******************************
# sub SetUpDirectoryPaths
#*******************************
sub SetUpDirectoryPaths
{
    my ($ffdirectory, $i, $input, @SASFiles, $length, $directory);
    my ($position);
    $inp_directory = stringParameter("inpdirectory");
    if ($inp_directory eq "")
    {        
	# Test VNY 11.06.03 (search for the flat-field file)
	$hasFF=0;
        $ffdirectory = $ENV{SAS_DIR} . "/packages";
	$workingDir=$0;

	$position=index($workingDir, "/bin");
	#if ($position >= 0)
	#{
	    #print(" position of the /bin pattern= $position \n");
	#}
	#else
	#{
	    #print (" OMGCHAIN L972: /bin/omgchain was not found \n");
	#}
	if (opendir (FFDIR, $ffdirectory))
	{
	    # Check if the Flat Field file is there
	    $ffName=$ffdirectory . "/omgchain/test/superflat_withoutLED.fit";

	    if (open(FFFILE, "$ffName")) 
	    {
		$hasFF=1;
		close(FFFILE);
	    }
	    else
	    {

		$ffName=substr($workingDir, 0, $position) ;
		#print(" new ff-directory= $ffName \n");
		$ffName = $ffName .  "/packages/omgchain/test/superflat_withoutLED.fit";
		#print(" new ff-name= $ffName \n");
		if (open(FFFILE, "$ffName"))
		{
		    $hasFF=1;
		    close(FFFILE);
		}
		else
		{
		    #print (" OMGCHAIN L999: there is no ff-file at all \n");
		}
	    }
	    closedir (FFDIR);
	}

	
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
#sub GetOmdetectParameters
#{
#    $omdetect_nsigma = realParameter("nsigma");
#    $omdetect_contrast = realParameter("contrast");
#    $omdetect_smoothsize = realParameter("smoothsize");
#    $omdetect_boxscale = intParameter("boxscale");
#    $omdetect_maxscale = intParameter("maxscale");
#
#}

#************************************
# Sub GetOmdetectParameters
#************************************
#sub GetOmregionParameters
#{
#    $omregion_srcradius = realParameter("srcradius");
#    $omregion_bkginner = realParameter("bkginner");
#    $omregion_bkgouter = realParameter("bkgouter");
#}

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





