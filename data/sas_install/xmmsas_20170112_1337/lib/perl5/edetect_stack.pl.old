#! /usr/bin/perl -w
#
# edetect_stack
#
# Simultaneous EPIC source detection run on multiple images and observations
#
# Author: Iris Traulsen (itraulsen@aip.de)
#
# Description:
#
#
# Mandatory Parameters:
#
#
# Optional Parameters:
#
#
# Input Files:
#         event lists (PPS products or user generated)
#         attitude files
#
# Output Files:
#         emldetect source list
#         esensmap sensitivity maps
#
# SAS Calls:
#         attcalc
#         evselect
#         eexpmap
#         emask
#         eboxdetect (local mode)
#         esplinemap
#         eboxdetect (map mode)
#         esensmap
#         emosaic
#         eboxdetect (map mode, stacked)
#         emldetect  (stacked)
#
# FTOOLS Calls: none (using CFITSIO and SimpleFITS)
#
# Intermediate Products:
#         images                           (evselect)
#         exposure maps                    (eexpmap)
#         detection masks                  (emask)
#         local-mode box source lists      (eboxdetect)
#         background maps                  (esplinemap)
#         map-mode box source lists        (eboxdetect)
#         stacked map-mode box source list (eboxdetect)
#         "raw" max-likelihood source list (emldetect)
#
# Stages: 1. runattcalc
#         2. runevselectimages
#         3. runeexpmap
#         4. runemask
#         5. runeboxdetectlocal
#         6. runesplinemap
#         7. runeboxdetectmap
#         8. runesensmap
#         9. runemosaic
#        10. runeboxdetectstack
#        11. runemldetect
#        12. finalize
# 

use SAS;
use Getopt::Long;
use File::Copy;
use List::Util;
use SimpleFITS;
# use DAL;  # note: seems to be even slower than SimpleFITS/CFITSIO

use strict;

# other constants
use constant PI => (4 * atan2 (1, 1));
use constant PI180 => (PI/180.);


sub edetect_stack {

########################################
## INTERNAL PARAMETERS OF SAS TASKS
# - NEED TO BE UPDATED IN CASE THE TASKS ARE UPDATED
our $maskthr = 0.15;                      # psfthreshold in emldetect; FIXED
# parameter imagebuffersize will be determined from image headers
our $imagebuffersize = 640;               # imagebuffersize in emldetect
our $autodetbuffersize = 0;
########################################
## INTERNAL PARAMETERS OF EDETECT_STACK
# maximum allowed distance between neighboured pointings: 2*12.0 arcmin
our $maxdist = 24.0;
# default energy bands and ecfs: see below, subroutine sort_inputfiles
########################################

# require code from external files
require "stack_sourcelist.pl";



################################################################################
## INITIALIZE VARIABLES

## global hash of input parameters
# Will be filled with scalars and arrays by stack_data().
# Risks: May be confusing, may be changed accidentally.
# Advantages: Only one "our" declaration, can be passed to sub routines.

our %inpar;
my $nsets = 0;
# manage code stages:
our @stagepointers;

## array of input OBS_IDs + exposure counter, used to identify individual
## pointings, instruments, filter
# i.e.: in case of mosaicking mode, run emosaic_prep first
our @pntids;
our @instrs;
our %instrnames;
$instrnames{"PN"} = "EPN";
$instrnames{"M1"} = "EMOS1";
$instrnames{"M2"} = "EMOS2";
# indicator of valid combinations of pointings and instruments
our %expisset;     # {pointing}{instrument}; 1 or undefined

## hashes holding the file name for all intermediate products, identified by
## pointing id (-> @pntids), instrument (-> @instrs), and energy band, if
## applicable.
## (driven by the idea of high flexibility in input formats:
##  user-friendly, developer-unfriendly)
# input event lists
our %infiles;
# output event lists   (<- attcalc)
our %evfiles;
# images               (<- evselect)
our %imfiles;
# exposure maps        (<- eexpmap)
our %exfiles;
# detection masks      (<- emask)
our %dmfiles;
# background maps      (<- esplinemap)
our %bkfiles;
# sensitivity maps     (<- esensmap)
our %snfiles;
# optionally: vignetted exposure maps (eexpmap / esplinemap)
our %vifiles;
# and using a similar structure: ECFs for all pointings and instruments
our %ecfhash;
# "by hand": attitude files and summary files sorted by OBS_IDs
our %atthash;
our %sumhash;

## hash of arrays: default ecfs - addressed by filter and instr id, holds arrays
our %ecfs;

# temporary variables
my $testfile;
my @tmpkeys;
my $tmpfiles;
my $myempty="";
my $newfits;
my $tmpcdelt1l;
my $tmpcdelt2l;

################################################################################
## PRELIMINARIES

# test for existence of SAS_CCF
if (! defined $ENV{'SAS_CCF'}) {
	SAS::error("CIFMissing", 
		   "Environment variable \'SAS_CCF\' is not set.")
}

# get and set task parameters
SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
	     "Sorting input data. This will take some time ".
	     "for compressed input files.");
stack_data();
my @bandnos = (0..$#{$inpar{pimin}});




################################################################################
## RUN PREPARATORY TASKS PER OBSERVATION

for my $ipnt (0 .. $#pntids) {                 ##### main LOOP OVER OBSERVATIONS

    my $obsid = substr($pntids[$ipnt], 0, 10);
    if ($inpar{minstage} < 9) {
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "Processing observation".
		     " with (internal) pointing id $pntids[$ipnt].");
    }

# ATTCALC
# set reference coordinate system in event lists

    # output event lists   (<- attcalc)
    if ($#{$inpar{att_eventset}} == 0) {           # single entry: default names
	# relies on input event files
	%evfiles = default_names($inpar{prefix}.$inpar{att_eventset}[0]);
    } else {                              # several entries: user-supplied names
	%evfiles = sort_inputfiles(\@{$inpar{att_eventset}});
    }

    if ($inpar{runattcalc}) {                                  ### IF RUNATTCALC

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Establishing common coordinate system via ATTCALC.");

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		# choose sum file (ccf has to be set by the user!!)
		$ENV{'SAS_ODF'} = $sumhash{$obsid};
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			  "Setting SAS_ODF to $sumhash{$obsid} .");

		# copy event list to working directory
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			     "Copying ".
			     "$infiles{$pntids[$ipnt]}{$instr} ".
			     "to ".
			     "$evfiles{$pntids[$ipnt]}{$instr}");
		copy($infiles{$pntids[$ipnt]}{$instr},  
			   $evfiles{$pntids[$ipnt]}{$instr})
		    or die SAS::error("FileNotCopied", "Could not copy ".
				      "$infiles{$pntids[$ipnt]}{$instr} ".
				      "to ".
				      "$evfiles{$pntids[$ipnt]}{$instr}.".
				      "Please make sure that you have read ".
				      "and write access.");

	    	# run attcalc
		run_sastask("attcalc".             # don't forget the blanks ...
			    " eventset=$evfiles{$pntids[$ipnt]}{$instr}".
			    " withatthkset=1".                           # fixed
			    " atthkset=$atthash{$obsid}".
			    " refpointlabel=user".                       # fixed
			    " nominalra=$inpar{att_nominalra}".
			    " nominaldec=$inpar{att_nominaldec}".
			    " imagesize=$inpar{att_imagesize}"
		    );                                            

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                      ### END IF RUNATTCALC



# EVSELECT
# produce images per instrument per energy band

    # images               (<- evselect)
    if ($#{$inpar{ev_imageset}} == 0) {            # single entry: default names
	%imfiles = default_names($inpar{prefix}.$inpar{ev_imageset}[0]);
    } else {                              # several entries: user-supplied names
	%imfiles = sort_inputfiles(\@{$inpar{ev_imageset}});
    }

    if ($inpar{runevselectimages}) {                    ### IF RUNEVSELECTIMAGES

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Producing images via EVSELECT.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		# variable holding the count number in the output images
		my $testsum = 0;

		for my $iband (0..$#{$inpar{pimin}}) {       ### loop over bands

		    # construct filtering expression, according to 2XMM
                    # documentation, to XSA v8 PPS files (SAS v12).
		    # edetect_stack does not provide the option to change the
		    # filtering expression (intentionally! signed: the
		    # developer). If users would prefer different filtering,
		    # they should filter their event lists and/or create their
		    # own input images.
		    my $filtexpr = "";
		    if ( (substr $instr, 0, 1) eq "P" ) {
			if ( ($inpar{pimin}[$iband] == 200 &&
			      $inpar{pimax}[$iband] == 500) ||
			     ($inpar{pimin}[$iband] == 500 &&
			      $inpar{pimax}[$iband] == 1000) ) {
			   $filtexpr = "(FLAG & 0x2fb002c)==0 && (RAWY>12) && ";
			} else {
			   $filtexpr = "(FLAG & 0x2fb0024)==0 && (RAWY>12) && ";
			}
			if ( $inpar{pimin}[$iband] == 200 &&
			     $inpar{pimax}[$iband] == 500 ) {
			    $filtexpr = $filtexpr . "PATTERN==0 && ";
			} else {
			    $filtexpr = $filtexpr . "PATTERN<=4 && ";
			}
		    }
		    if ( (substr $instr, 0, 1) eq "M" ) {
			$filtexpr = "(FLAG & 0x766ba000)==0 && ";
			$filtexpr = $filtexpr . "PATTERN<=12 && ";
		    }
		    $filtexpr = $filtexpr . 
			    "PI>$inpar{pimin}[$iband] && ".
			    "PI<=$inpar{pimax}[$iband]";

		    my $outimage = ename($imfiles{$pntids[$ipnt]}{$instr},
					 $inpar{pimin}[$iband], 
					 $inpar{pimax}[$iband]);

		    # run evselect
		    run_sastask("evselect".    # and don't forget the blanks ...
				" imageset=$outimage".
				" table=$evfiles{$pntids[$ipnt]}{$instr}".
				" expression=\'$filtexpr\'".
				" filtertype=expression".                # fixed
				" xcolumn=$inpar{ev_xcolumn}".
				" ycolumn=$inpar{ev_ycolumn}".
				" imagebinning=binSize".                 # fixed
				" ximagebinsize=$inpar{ev_ximagebinsize}".
				" yimagebinsize=$inpar{ev_yimagebinsize}".
				" withxranges=$inpar{ev_withxranges}".
				" ximagemin=$inpar{ev_ximagemin}".
				" ximagemax=$inpar{ev_ximagemax}".
				" withyranges=$inpar{ev_withyranges}".
				" yimagemin=$inpar{ev_yimagemin}".
				" yimagemax=$inpar{ev_yimagemax}".
			      " withimagedatatype=$inpar{ev_withimagedatatype}".
				" imagedatatype=$inpar{ev_imagedatatype}"
			);

		}                                 ### end loop over energy bands

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                               ### END IF RUNEVSELECTIMAGES


    # catch empty images  --- in any case (= not only when evselect is called)
    if ($inpar{maxstage} > 1) {

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		# variable holding the count number in the output images
		my $testsum = 0;

		for my $iband (0..$#{$inpar{pimin}}) {       ### loop over bands

		    my $outimage = ename($imfiles{$pntids[$ipnt]}{$instr},
					 $inpar{pimin}[$iband], 
					 $inpar{pimax}[$iband]);
		    
		    my $fits = SimpleFITS->open($outimage,
						type=>"image",
						access=>"readonly");
		    # if file is found ...
		    if ($fits->status() == 0) {
			# ... read it
			$fits->SimpleFITS::readpix({}, my $imageref);
			$fits->close();
			# calculate total number of counts
			$testsum = $testsum + (List::Util::sum @$imageref);
			# if file is not found
		    } else {
			SAS::warning("ImageNotFound", 
				     "Image $outimage not found. You'll".
				     " probably run into troubles later-on.\n");
		    }

		}                                 ### end loop over energy bands

		# and if all images of this instrument are empty
		if ($testsum == 0) {
		    # deactivate indicator
		    delete $expisset{$pntids[$ipnt]}{$instr};
		    delete $imfiles{$pntids[$ipnt]}{$instr};
		    SAS::warning("InstrumentIgnored", 
				 "All images for $instrnames{$instr} are empty".
				 " in the pointing $pntids[$ipnt]. It is".
				 " therefore removed from the input list.\n");
		}

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                    ### end if maxstage > 1


# EEXPMAP
# produce exposure maps per instrument

    # exposure maps        (<- eexpmap)
    if ($#{$inpar{eexp_expimageset}} == 0) {       # single entry: default names
	%exfiles = default_names($inpar{prefix}.$inpar{eexp_expimageset}[0]);
    } else {                              # several entries: user-supplied names
	%exfiles = sort_inputfiles(\@{$inpar{eexp_expimageset}});
    }
    # optionally: vignetted exposure maps for esplinemap
    # initialize with ""
    @{$vifiles{$_}}{@instrs} = ("")x(@instrs) for (@pntids);
    # expand if required
    if ($inpar{esp_fitmethod} eq "model") {
	if ($#{$inpar{esp_expimagesetvig}} == 0) { # single entry: default names
	    %vifiles = default_names($inpar{prefix}.$inpar{esp_expimagesetvig}[0]);
	} else {                          # several entries: user-supplied names
	    %vifiles = sort_inputfiles(\@{$inpar{esp_expimagesetvig}});
	}
    }

    if ($inpar{runeexpmap}) {                                  ### IF RUNEEXPMAP

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Producing exposure maps via EEXPMAP.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		for my $iband (0..$#{$inpar{pimin}}) {       ### loop over bands

		    # run eexpmap
		    run_sastask("eexpmap".    # and don't forget the blanks ...
				" expimageset=".
			  	        (ename($exfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])).
				" imageset=".
			  	        (ename($imfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])).
				" attitudeset=$atthash{$obsid}".
				" eventset=$evfiles{$pntids[$ipnt]}{$instr}".
				" pimin=$inpar{pimin}[$iband]".
				" pimax=$inpar{pimax}[$iband]".
				" withvignetting=0"                      # fixed
			);

		    # all esplinemap fit methods are supported:
		    # vignetted exposure maps needed in case of fitmethod model
		    if ($inpar{esp_fitmethod} eq "model") {
			run_sastask("eexpmap".              # and the blanks ...
				  " expimageset=".
			  	        (ename($vifiles{$pntids[$ipnt]}{$instr},
				    	       $inpar{pimin}[$iband], 
				    	       $inpar{pimax}[$iband])).
				  " imageset=".
			  	        (ename($imfiles{$pntids[$ipnt]}{$instr},
				  	       $inpar{pimin}[$iband], 
				  	       $inpar{pimax}[$iband])).
				  " attitudeset=$atthash{$obsid}".
				  " eventset=$evfiles{$pntids[$ipnt]}{$instr}".
				  " pimin=$inpar{pimin}[$iband]".
				  " pimax=$inpar{pimax}[$iband]".
				  " attrebin=$inpar{eexp_attrebin}".
				  " withvignetting=1"                    # fixed
			);
		    }

		}                                 ### end loop over energy bands

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                      ### END IF RUNEEXPMAP



# EMASK
# produce detection masks per instrument

    # detection masks      (<- emask)
    if ($#{$inpar{emask_detmaskset}} == 0) {       # single entry: default names
	%dmfiles = default_names($inpar{prefix}.$inpar{emask_detmaskset}[0]);
    } else {                              # several entries: user-supplied names
	%dmfiles = sort_inputfiles(\@{$inpar{emask_detmaskset}}, 1);
    }

    if ($inpar{runemask}) {                                      ### IF RUNEMASK

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Producing detection masks via EMASK.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		# use "mean" energy band for exposure image  [+0.5 for rounding]
		my $mband = int(0.5+ $#{$inpar{pimin}}/2);

		# run emask
		run_sastask("emask".           # and don't forget the blanks ...
			    " detmaskset=$dmfiles{$pntids[$ipnt]}{$instr}".
			    " expimageset=".
			  	        (ename($exfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$mband], 
					       $inpar{pimax}[$mband])).
			    " threshold1=$inpar{emask_threshold1}".
			    " threshold2=$inpar{emask_threshold2}".
			    " withregionset=$inpar{emask_withregionset}".
			    " regionset=$inpar{prefix}.".
        			                    "$inpar{emask_regionset}"
			);

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                        ### END IF RUNEMASK



# EBOXDETECT
# produce one local-mode box source list
    if ($inpar{runeboxdetectlocal}) {                  ### IF RUNEBOXDETECTLOCAL

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		   "--- Producing local-mode box source list via EBOXDETECT.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	# determine imagebuffersize from image header keywords; any image
	$testfile = (ename((values %{$imfiles{$pntids[0]}})[0],
			      $inpar{pimin}[0], 
			      $inpar{pimax}[0]));
	# test for file existence
	if (-e "$testfile") {
	    # get CDELT1L, CDELT2L header keywords,
	    # which should reflect the image binning,
	    # and NAXIS1, NAXIS2, which give the actual image size
	    @tmpkeys = fits_get_headerkey($testfile, 0, 
					  "NAXIS1", "NAXIS2",
					  "CDELT1L", "CDELT2L");
	    # calculate imagebuffersize - default 640 for binning 80x80.
	    # increase for smaller bins (= more pixels),
	    # decrease for larger bins (= less pixels)   [+0.5 for rounding]
	    $imagebuffersize = 
		int(0.5+ 51200 / ( List::Util::max @tmpkeys[2..3] ) );
	    # reduce it to image size of smaller images
	    # Well, actually, we could also deactivate withimagebuffersize,
	    # but it shouldn't make a difference, so ...
	    $imagebuffersize = List::Util::min ( $imagebuffersize ,
				 List::Util::max (@tmpkeys[0..1]) );
	    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			 "Determined parameter value of imagebuffersize to".
			 " $imagebuffersize pixels from image $testfile.");
	    $autodetbuffersize = 1;
	} else {
	    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			 "Could not find image file $testfile to determine the".
			 " optimum parameter value of imagebuffersize. Will ".
			 "use the default ($imagebuffersize).");
	}

	# number of "populated" instruments:
	$nsets = List::Util::sum 
	    (map { exists $expisset{$pntids[$ipnt]}{$_} } @instrs);

	# run eboxdetect
	run_sastask("eboxdetect".              # and don't forget the blanks ...
		    " boxlistset=$inpar{eboxl_boxlistset}[$ipnt]".
		    " usemap=0".                                         # fixed
		    " imagesets=\'".
		         (concat_names_pi( \%imfiles, \$pntids[$ipnt], 
					   \@instrs, \@bandnos ))."\'".
		    " withexpimage=1".                                   # fixed
		    " expimagesets=\'".
		         (concat_names_pi( \%exfiles, \$pntids[$ipnt], 
					   \@instrs, \@bandnos ))."\'".
		    " withdetmask=1".                                    # fixed
		    " detmasksets=\'".
		         (concat_names( \%dmfiles, \$pntids[$ipnt] ))."\'".
		    " ecf=\'".
		         (concat_names( \%ecfhash, \$pntids[$ipnt] ))."\'".
		                                # energy bands times instruments
		    " pimin=\'".(join(" ", (@{$inpar{pimin}}) x $nsets))."\'".
		    " pimax=\'".(join(" ", (@{$inpar{pimax}}) x $nsets))."\'".
		    " withimagebuffersize=1".                            # fixed
		    " imagebuffersize=$imagebuffersize".
		    " likemin=$inpar{eboxl_likemin}".
		    " boxsize=$inpar{eboxl_boxsize}".
		    " nruns=$inpar{eboxl_nruns}"
	    );

	## n.b.: We keep empty output lists, but capture them before srcmatch

	# re-set $nsets: we will need to re-determine it for other obsids and
	# for the stacked task runs
	$nsets=0;

    }                                              ### END IF RUNEBOXDETECTLOCAL



# ESPLINEMAP
# produce background maps per instrument per energy band

    # background maps      (<- esplinemap)
    if ($#{$inpar{esp_bkgimageset}} == 0) {        # single entry: default names
	%bkfiles = default_names($inpar{prefix}.$inpar{esp_bkgimageset}[0]);
    } else {                              # several entries: user-supplied names
	%bkfiles = sort_inputfiles(\@{$inpar{esp_bkgimageset}});
    }

    if ($inpar{runesplinemap}) {                            ### IF RUNESPLINEMAP

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Producing background maps via ESPLINEMAP.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");


	# both fit methods are supported:
	# copy %exfiles and %vifiles to temporary hashes corresponding to 
	# esplinemap parameters expimageset and expimageset2
	my %tmpexp1;
	my %tmpexp2;
	# 1. model:  expimageset  =   vignetted exposure maps (%vifiles)
	#      opt.: expimageset2 = unvignetted exposure maps (%exfiles)
	if ($inpar{esp_fitmethod} eq "model") {
	    %tmpexp1 = %vifiles;
	    %tmpexp2 = %exfiles;
	} else {
	# 2. spline/smooth: expimageset  = unvignetted exposure maps (%exfiles)
	    %tmpexp1 = %exfiles;
	    %tmpexp2 = %vifiles;
	}

	if ($inpar{esp_fitmethod} eq "spline") {
	# determine number of nodes from image size, if not provided by user
	unless ($inpar{with_esp_nsplinenodes}) {
	    # get image size from an input image
	    $testfile = (ename((values %{$imfiles{$pntids[0]}})[0],
			      $inpar{pimin}[0], 
			      $inpar{pimax}[0]));
	    # test for file existence
	    if (-e "$testfile") {
		# get image size from NAXIS keywords
		@tmpkeys = fits_get_headerkey($testfile, 0, "NAXIS1", "NAXIS2");
		# set number of spline nodes. Currently: one per 50 pixels.
		$inpar{esp_nsplinenodes} = 
		    int(0.5+ sqrt( List::Util::max @tmpkeys ) / 2 );
#		    int(0.5+ ( List::Util::max @tmpkeys ) / 50 );
		# currently: minimum of 10, maximum of 40 nodes
		$inpar{esp_nsplinenodes} = 10
		    if $inpar{esp_nsplinenodes} < 10;
		$inpar{esp_nsplinenodes} = 40
		    if $inpar{esp_nsplinenodes} > 40;
		# info
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			     "Setting number of spline nodes to ".
			     "$inpar{esp_nsplinenodes}, determined from ".
			     "image $testfile.");
	    } else {
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			     "Could not find image file $testfile to ".
			     "determine the optimum number of spline nodes. ".
			     "Will use the default ".
			     "($inpar{esp_nsplinenodes}).");
	    }
	}
	}
	# start
	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

                for my $iband (0..$#{$inpar{pimin}}) {       ### loop over bands

                    # run esplinemap
                    run_sastask("esplinemap".  # and don't forget the blanks ...
                               " bkgimageset=".
                                       (ename($bkfiles{$pntids[$ipnt]}{$instr},
                                              $inpar{pimin}[$iband], 
                                              $inpar{pimax}[$iband])).
                               " boxlistset=$inpar{eboxl_boxlistset}[$ipnt]".
                               " imageset=".
                                       (ename($imfiles{$pntids[$ipnt]}{$instr},
                                              $inpar{pimin}[$iband], 
                                              $inpar{pimax}[$iband])).
                               " withexpimage=1".                        # fixed
                               " expimageset=".
                                       (ename($tmpexp1{$pntids[$ipnt]}{$instr},
                                              $inpar{pimin}[$iband], 
                                              $inpar{pimax}[$iband])).
                               " withdetmask=1".                         # fixed
                               " detmaskset=$dmfiles{$pntids[$ipnt]}{$instr}".
                               " idband=".($iband+1).                    # fixed
                               " pimin=$inpar{pimin}[$iband]".
                               " pimax=$inpar{pimax}[$iband]".
                               " scut=$inpar{esp_scut}".
                               " mlmin=$inpar{esp_mlmin}".
                               " nsplinenodes=$inpar{esp_nsplinenodes}".
                               " excesssigma=$inpar{esp_excesssigma}".
                               " nfitrun=$inpar{esp_nfitrun}".
                               " snrmin=$inpar{esp_snrmin}".
                               " smoothsigma=$inpar{esp_smoothsigma}".
                               " withcheese=$inpar{esp_withcheeseimage}".
                               " cheeseimageset=".    # only, if withcheeseimage
				       ( ($inpar{esp_withcheeseimage}) ?
					 efname($inpar{prefix}.
						$inpar{esp_cheeseimageset},
						$pntids[$ipnt],  $instr,
						$inpar{pimin}[$iband], 
						$inpar{pimax}[$iband])
					 : "\'\'" ).
                               " withcheesemask=$inpar{esp_withcheesemask}".
                               " cheesemaskset=".    # only, if withcheeseimage
				       ( ($inpar{esp_withcheeseimage}) ?
					 efname($inpar{prefix}.
						$inpar{esp_cheesemaskset},
					       $pntids[$ipnt],  $instr,
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])
					 : "\'\'" ).
                               " withootset=".( $instr eq "PN" ? 1 : 0 ).# fixed
			       " ooteventset=".
				       "\'$evfiles{$pntids[$ipnt]}{$instr}\'".
                               " fitmethod=$inpar{esp_fitmethod}".
                               " withexpimage2=$inpar{esp_withexpimage2}".
                               " expimageset2=".        # only, if withexpimage2
                                       ( ($inpar{esp_withexpimage2}) ?
					 ename($tmpexp2{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])
					 : "\'\'" )
                        );

		}                                 ### end loop over energy bands

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                   ### END IF RUNESPLINEMAP

                                                        

# EBOXDETECT
# produce one map-mode box source list
    if ($inpar{runeboxdetectmap}) {                      ### IF RUNEBOXDETECTMAP

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		   "--- Producing map-mode box source list via EBOXDETECT.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	# determine imagebuffersize from header keywords, if not already done
	if ($autodetbuffersize == 0) {
	    $testfile = (ename((values %{$imfiles{$pntids[0]}})[0],
			       $inpar{pimin}[0], 
			       $inpar{pimax}[0]));
	    # test for file existence
	    if (-e "$testfile") {
		# get CDELT1L, CDELT2L header keywords,
		# which should reflect the image binning
		@tmpkeys = fits_get_headerkey($testfile, 0, 
					      "CDELT1L", "CDELT2L");
		# calculate imagebuffersize - default 640 for binning 80x80.
		# increase for smaller bins (= more pixels),
		# decrease for larger bins (= less pixels)   [+0.5 for rounding]
		$imagebuffersize = 
		    int(0.5+ 51200 / ( List::Util::max @tmpkeys ) );
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			     "Determined parameter value of imagebuffersize to".
			     " $imagebuffersize pixels from image $testfile.");
		$autodetbuffersize = 0;   # re-set it for the next pointing
	    } else {
		SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			     "Could not find image file $testfile to determine".
			     " the optimum parameter value of imagebuffersize.".
			     " Will use the default ($imagebuffersize).");
	    }
	}

	# number of "populated" instruments:
	$nsets = List::Util::sum 
	    (map { exists $expisset{$pntids[$ipnt]}{$_} } @instrs);

	# run eboxdetect
	run_sastask("eboxdetect".              # and don't forget the blanks ...
		    " boxlistset=$inpar{eboxm_boxlistset}[$ipnt]".
		    " usemap=1".                                         # fixed
		    " imagesets=\'".
		         (concat_names_pi( \%imfiles, \$pntids[$ipnt], 
					   \@instrs, \@bandnos ))."\'".
		    " bkgimagesets=\'".
		         (concat_names_pi( \%bkfiles, \$pntids[$ipnt], 
					   \@instrs, \@bandnos ))."\'".
		    " withexpimage=1".                                   # fixed
		    " expimagesets=\'".
		         (concat_names_pi( \%exfiles, \$pntids[$ipnt], 
					   \@instrs, \@bandnos ))."\'".
		    " withdetmask=1".                                    # fixed
		    " detmasksets=\'".
		         (concat_names( \%dmfiles, \$pntids[$ipnt] ))."\'".
		    " ecf=\'".
		         (concat_names( \%ecfhash, \$pntids[$ipnt] ))."\'".
		                                # energy bands times instruments
		    " pimin=\'".(join(" ", (@{$inpar{pimin}}) x $nsets))."\'".
		    " pimax=\'".(join(" ", (@{$inpar{pimax}}) x $nsets))."\'".
		    " withimagebuffersize=1".                            # fixed
		    " imagebuffersize=$imagebuffersize".
		    " likemin=$inpar{eboxm_likemin}".
		    " boxsize=$inpar{eboxm_boxsize}".
		    " nruns=$inpar{eboxm_nruns}".
		    " hrdef=\'$inpar{eboxm_hrdef}\'"
	    );

	## n.b.: We keep empty output lists, but capture them before srcmatch

	# re-set $nsets: we will need to re-determine it for other obsids and
	# for the stacked task runs
	$nsets=0;

    }                                                ### END IF RUNEBOXDETECTMAP



# ESENSMAP
# sensitivity maps are created for informational purposes
# and not used within the task
    if ($inpar{runesensmap}) {                                ### IF RUNESENSMAP

	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "--- Producing sensitivity maps via ESENSMAP.");
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

	# sensitivity maps     (<- esensmap)
	if ($#{$inpar{esen_sensimageset}} == 0) {  # single entry: default names
	    %snfiles = default_names($inpar{prefix}.
				     $inpar{esen_sensimageset}[0]);
	} else {                          # several entries: user-supplied names
	    %snfiles = sort_inputfiles(\@{$inpar{esen_sensimageset}});
	}

	for my $instr (@instrs) {                      ### loop over instruments

	    if (exists $expisset{$pntids[$ipnt]}{$instr}) {  ### if input exists

		for my $iband (0..$#{$inpar{pimin}}) {       ### loop over bands

		    # run esensmap
		    run_sastask("esensmap".    # and don't forget the blanks ...
				" sensimageset=".
				        (ename($snfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])).
				" detmasksets=$dmfiles{$pntids[$ipnt]}{$instr}".
				" expimagesets=".
				        (ename($exfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])).
				" bkgimagesets=".
				        (ename($bkfiles{$pntids[$ipnt]}{$instr},
					       $inpar{pimin}[$iband], 
					       $inpar{pimax}[$iband])).
				# lower limit is 1.0
				" mlmin=".( $inpar{eml_mlmin} > 1.0 ? 
					    $inpar{eml_mlmin} : 1.0 )
			);

		}                                 ### end loop over energy bands

	    }                                       ### end if input file exists

	}                                          ### end loop over instruments

    }                                                     ### END IF RUNESENSMAP

}                                          ##### END main LOOP OVER OBSERVATIONS


# EMOSAIC IMAGES
if ($inpar{runemosaic}) {                                      ### IF RUNEMOSAIC

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		 "--- Producing illustrating mosaic images via EMOSAIC.");

    # per instrument
    for my $iinstr (0..$#instrs) {
	run_sastask("emosaic".
		    " mosaicedset=".
		              "$inpar{prefix}"."$inpar{emos_mosaicedset}".
		    "_$instrs[$iinstr].fits".
		    " imagesets=\'".(concat_names_pi( \%imfiles, \@pntids, 
						      \$instrs[$iinstr],
						      \@bandnos ))."\'"
	    );
    }
    # per energy band
    for my $iband (0..$#{$inpar{pimin}}) {
	run_sastask("emosaic".
		    " mosaicedset=".
		                 (ename("$inpar{prefix}".
					"$inpar{emos_mosaicedset}_EPIC.fits",
					$inpar{pimin}[$iband], 
					$inpar{pimax}[$iband])).
		    " imagesets=\'".(concat_names_pi( \%imfiles, \@pntids, 
						      \@instrs, 
						      \$bandnos[$iband] ))."\'"
	    );
    }
    # total
    run_sastask("emosaic".
		" mosaicedset=".
	            "$inpar{prefix}"."$inpar{emos_mosaicedset}_EPIC.fits".
		" imagesets=\'".(concat_names_pi( \%imfiles, \@pntids, 
						  \@instrs, \@bandnos ))."\'"
	);

}                                                          ### END IF RUNEMOSAIC



################################################################################
## RUN STACKED SOURCE DETECTION ON ALL OBSERVATIONS

# update list of instruments - observations may have been removed from the list
for my $iinst (reverse (0..$#instrs)) {
    # remove instrument from list if not set for any pointing id
    splice @instrs, $iinst, 1 
	if (List::Util::sum
	    (map { exists $expisset{$_}{$instrs[$iinst]} } @pntids) == 0);
}


# EBOXDETECT in map mode on mosaicked images
# 1. mosaic input files
# 2. run eboxdetect
# 3. combine all map-mode eboxdetect lists
if ($inpar{runeboxdetectstack}) {                      ### IF RUNEBOXDETECTSTACK

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		 "--- Running EBOXDETECT in map mode on stacked observations.");
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

    ## mosaicked images
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		 "--- Producing mosaic input files for EBOXDETECT".
		 " per instrument and energy band via EMOSAIC.");
    # images, background maps, exposure maps per instrument and energy band
    my @mosaics = ( "",
		    "",
		    "",
	            "" );
    my @mossets = ( \@{$inpar{ev_imageset}},
		    \@{$inpar{esp_bkgimageset}},
		    \@{$inpar{eexp_expimageset}},
		    \@{$inpar{emask_detmaskset}} );
    my @mosname = ( $inpar{ev_imageset}[0],
		    $inpar{esp_bkgimageset}[0],
		    $inpar{eexp_expimageset}[0],
		    $inpar{emask_detmaskset}[0] );
    my @moshash = ( \%imfiles,
		    \%bkfiles,
		    \%exfiles,
		    \%dmfiles );
    for my $cnt (0..$#mossets-1) {                        # loop over file types
	# check $mosname
	$mosname[$cnt] = ${$mossets[$cnt]}[0]
	    if (scalar(@{$mossets[$cnt]}) == 1);
	for my $instr (@instrs) {                        # loop over instruments
	    for my $iband (0..$#{$inpar{pimin}}) {      # loop over energy bands
		# string of input files: check whether it is empty
		$tmpfiles = "";
		$tmpfiles .= (defined(${$moshash[$cnt]}{$_}{$instr})
			      && ${$moshash[$cnt]}{$_}{$instr} ne "")
		    ? ename(${$moshash[$cnt]}{$_}{$instr},
			    $inpar{pimin}[$iband], 
			    $inpar{pimax}[$iband])." "
		    : ""
		    for (@pntids);
		if ($tmpfiles ne "") {
		    # output file name
		    my $outfile = ename( "$inpar{prefix}".
					 "$mosname[$cnt]"."$instr".".fits",
					 $inpar{pimin}[$iband], 
					 $inpar{pimax}[$iband] );
		    $mosaics[$cnt] .= "$outfile ";
		    # call emosaic
		    run_sastask("emosaic".
				" mosaicedset=$outfile".
				" imagesets=\'$tmpfiles\'"
			);
		    # add fake EXP_ID, needed by eboxdetect
		    $newfits = 
			SimpleFITS->readonly((split(" ",$tmpfiles))[0]);
		    $newfits
			->readkey("CDELT1L", $tmpcdelt1l)
			->readkey("CDELT2L", $tmpcdelt2l)
			;
		    $newfits->close;
		    $newfits = 
			SimpleFITS->readwrite($outfile);
		    $newfits
			->writekey("EXP_ID", "1", "Fake exposure identifier")
			->writekey("CDELT1L", $tmpcdelt1l, "tmpcdetlt1l")
			->writekey("CDELT2L", $tmpcdelt2l, "tmpcdetlt2l")
			;			
		    $newfits->close;
		}
	    }                                       # end loop over energy bands
	}                                            # end loop over instruments
    }                                                 # end loop over file types
    # detection masks per instrument
    # (eboxdetect checks only for zero / non-zero values -> masks can be added)
    my $cnt = $#mossets;
    for my $instr (@instrs) {                            # loop over instruments
	$tmpfiles = "";
	# string of input files: check whether it is empty
	my $tmpfiles = "";
	$tmpfiles .= (defined(${$moshash[$cnt]}{$_}{$instr})
		      && ${$moshash[$cnt]}{$_}{$instr} ne "")
	    ? "${$moshash[$cnt]}{$_}{$instr}"." "
	    : ""
	    for (@pntids);
	if ($tmpfiles ne "") {
	    # output file name
	    my $outfile = "$inpar{prefix}"."$mosname[$cnt]"."$instr".".fits";
	    $mosaics[$cnt] .= "$outfile ";
	    # call emosaic
	    run_sastask("emosaic".
			" mosaicedset=$outfile".
			" imagesets=\'$tmpfiles\'"
		);
	    # add header keywords needed by eboxdetect
	    $newfits = 
		SimpleFITS->readonly((split(" ",$tmpfiles))[0]);
	    $newfits
		->readkey("CDELT1L", $tmpcdelt1l)
		->readkey("CDELT2L", $tmpcdelt2l)
		;
	    $newfits->close;
	    $newfits = 
		SimpleFITS->readwrite($outfile);
	    $newfits
		->writekey("EXP_ID", "1", "Fake exposure identifier")
		->writekey("CDELT1L", $tmpcdelt1l, "tmpcdetlt1l")
		->writekey("CDELT2L", $tmpcdelt2l, "tmpcdetlt2l")
		;			
	    $newfits->close;
	}
    }                                                # end loop over instruments


    # run eboxdetect on mosaicked images
    run_sastask("eboxdetect".                  # and don't forget the blanks ...
		" boxlistset=$inpar{eboxs_intermediate}".
		" usemap=1".                                             # fixed
		" imagesets=\'$mosaics[0]\'".
		" bkgimagesets=\'$mosaics[1]\'".
		" withexpimage=1".                                       # fixed
		" expimagesets=\'$mosaics[2]\'".
		" withdetmask=1".                                        # fixed
		" detmasksets=\'$mosaics[3]\'".
		" ecf=\'".                                               # fixed
		  (join(" ", 
			((0.0) x (scalar @{$inpar{pimin}} * scalar @instrs) )
		   ))."\'".
		" pimin=\'".
		  (join(" ", (@{$inpar{pimin}}) x scalar @instrs))."\'".
		" pimax=\'".
		  (join(" ", (@{$inpar{pimax}}) x scalar @instrs))."\'".
		" withimagebuffersize=0".                                # fixed
		" likemin=$inpar{eboxs_likemin}".
		" boxsize=$inpar{eboxs_boxsize}".
		" nruns=$inpar{eboxs_nruns}".
		" hrdef=\'$inpar{eboxs_hrdef}\'"
	    );


    # test file existence of boxlistsets and add them to the srcmatch input
    # if they are not empty
    my $eboxinput="";
    my @tmpkeys = fits_get_headerkey($inpar{eboxs_intermediate}, 0, 
				     "NDETECT", "XBINSIZE", "YBINSIZE");
    if ($tmpkeys[0] > 0) {
	$eboxinput .= "$inpar{eboxs_intermediate}";
    } else {
	SAS::warning("EmptySourceList","eboxdetect source list ".
		     $inpar{eboxs_intermediate}." is empty. Skipping it.");
    }
    if ($#{$inpar{eboxm_boxlistset}} > -1) {
	foreach my $testfile (@{$inpar{eboxm_boxlistset}}) {
	    if (-e $testfile) {
		my @tmpkeys = fits_get_headerkey($testfile, 0, "NDETECT");
		if ($tmpkeys[0] > 0) {
		    $eboxinput .= " $testfile" if $tmpkeys[0];
		} else {
		    SAS::warning("EmptySourceList","eboxdetect source list ".
				 $testfile." is empty. Skipping it.");
		}
	    }
	}
    }
    if ($eboxinput eq "" ) {
	die SAS::error("EmptySourceList", "Input source list to emldetect ".
		       "is empty. Exiting.");
    }
    
    # srcmatch: combine all eboxdetect map-mode list = emldetect input list
    run_sastask("srcmatch".                    # and don't forget the blanks ...
		" inputlistsets=\'$eboxinput\'".
		" outputlistset=\'$inpar{eboxs_boxlistset}\'". # fixed suffix
		" htmloutput=\'\'".                      # fixed: no html output
		" maxerr=-".
		        2.*sqrt(2)*(List::Util::min ($tmpkeys[1], $tmpkeys[2]))
	);

    # combine the EP_DET_ML columns of the merged output list into one LIKE
    # column holding their maximum likelihood per detection. emldetect will
    # use this LIKE column to sort the input detections by descending
    # likelihood.
    my $fits = SimpleFITS->open($inpar{eboxs_boxlistset}, 
				access=>"readwrite", type=>"table");
    ($fits->status() == 0) 
        or SAS::error("FileNotFound", 
		      "Could not open $inpar{eboxs_boxlistset}. ".
                      "File not found or unreadable: ".
		      "Check output of the previous srcmatch command.");
    # get EP_DET_ML array
    $fits
	->readcol("EP_DET_ML", {}, my $epdetml)
	->nrows(my $nrows)
	->insertcol({TTYPE=>["LIKE", "Maximum likelihood"], TFORM=>"E"});
    my $tmpncol = ($#{$epdetml}+1)/$nrows;
    # write maxima to LIKE column
    $fits->writecol("LIKE", {rows=>[$_]}, 
		    List::Util::max @${epdetml[($_-1)*$tmpncol..$_*$tmpncol-1]})
	for (1..$nrows);
    # and close the file
    $fits->close();

}                                                  ### END IF RUNEBOXDETECTSTACK


# EMLDETECT stacking
if ($inpar{runemldetect}) {                                  ### IF RUNEMLDETECT

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		 "--- Running EMLDETECT on stacked observations.");
    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "");

    # determine imagebuffersize from image header keywords (binsize)
    my $testfile = (ename((values %{$imfiles{$pntids[0]}})[0],
			  $inpar{pimin}[0], 
			  $inpar{pimax}[0]));
    # test for file existence
    if (-e "$testfile") {
	# get CDELT1L, CDELT2L header keywords,
	# which should reflect the image binning
	my @tmpkeys = fits_get_headerkey($testfile, 0, "CDELT1L","CDELT2L");
	# calculate imagebuffersize - default 640 for binning 80x80.
	# increase for smaller bins (= more px), decrease for larger bins
	$imagebuffersize = int( 51200 / ( List::Util::max @tmpkeys ) );
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "Determined parameter value of imagebuffersize to".
		     " $imagebuffersize pixels from image $testfile.");
    } else {
	SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		     "Could not find image file $testfile to determine ".
		     "the optimum parameter value of imagebuffersize. ".
		     "Will use the default ($imagebuffersize).");
    }

    # num. of "populated" instruments (if not already determined for eboxdetect)
    if ($nsets == 0) {
	for my $pntid (@pntids) {
	    $nsets += List::Util::sum 
		(map { exists $expisset{$pntid}{$_} } @instrs);
	}
    }

    # (default) names of source images
    my $scfiles=$inpar{eml_sourceimagesets};
    if ($inpar{eml_withsourcemap}) {
	my %scfiles = 
	    default_names($inpar{prefix}.$inpar{eml_sourceimagesets});
	$scfiles = (concat_names_pi( \%scfiles, \@pntids, 
				     \@instrs, \@bandnos ));
    }

    # run emldetect
    run_sastask("emldetect".                   # and don't forget the blanks ...
		" mllistset=$inpar{eml_mllistset}".
		" boxlistset=$inpar{eboxs_boxlistset}".
		" withsourcemap=$inpar{eml_withsourcemap}".
		" sourceimagesets=\'$scfiles\'".
		" imagesets=\'".
		         (concat_names_pi( \%imfiles, \@pntids, 
					   \@instrs, \@bandnos ))."\'".
		" bkgimagesets=\'".
		         (concat_names_pi( \%bkfiles, \@pntids, 
					   \@instrs, \@bandnos ))."\'".
		" withexpimage=1".                                       # fixed
		" expimagesets=\'".
		         (concat_names_pi( \%exfiles, \@pntids, 
					   \@instrs, \@bandnos ))."\'".
		" withdetmask=1".                                        # fixed
		" detmasksets=\'".
		         (concat_names( \%dmfiles, \@pntids ))."\'".
		" ecf=\'".
		         (concat_names( \%ecfhash, \@pntids ))."\'".
		                                # energy bands times instruments
		" pimin=\'".(join(" ", (@{$inpar{pimin}}) x $nsets))."\'".
		" pimax=\'".(join(" ", (@{$inpar{pimax}}) x $nsets))."\'".
		" withimagebuffersize=1".                                # fixed
		" imagebuffersize=$imagebuffersize".
		" withrawrows=1".                                        # fixed
		" psfmodel=$inpar{eml_psfmodel}".
                " mlmin=$inpar{eml_mlmin}".
		" dmlextmin=$inpar{eml_dmlextmin}".
		" fitextent=$inpar{eml_fitextent}".
		" minextent=$inpar{eml_minextent}".
		" maxextent=$inpar{eml_maxextent}".
		" nmaxfit=$inpar{eml_nmaxfit}".
		" nmulsou=$inpar{eml_nmulsou}".
		" fitposition=$inpar{eml_fitposition}".
		" determineerrors=$inpar{eml_determineerrors}".
		" ecut=$inpar{eml_ecut}".
		" scut=$inpar{eml_scut}".
		" hrpndef=\'$inpar{eml_hrpndef}\'".
		" hrm1def=\'$inpar{eml_hrm1def}\'".
		" hrm2def=\'$inpar{eml_hrm2def}\'".
		" extentmodel=$inpar{eml_extentmodel}".
		" withthreshold=$inpar{eml_withthreshold}".
		" threshold=$inpar{eml_threshold}".
		" threshcolumn=$inpar{eml_threshcolumn}".
		" withhotpixelfilter=$inpar{eml_withhotpixelfilter}".
		" withtwostage=$inpar{eml_withtwostage}".
		" withxidband=$inpar{eml_withxidband}".
		" xidfixed=$inpar{eml_xidfixed}".
		" xidecf=\'$inpar{eml_xidecf}\'".
		" xidpndef=\'$inpar{eml_xidpndef}\'".
		" xidm1def=\'$inpar{eml_xidm1def}\'".
		" xidm2def=\'$inpar{eml_xidm2def}\'"                        
	    );


}                                                        ### END IF RUNEMLDETECT



# PRODUCE FINAL SOURCE LIST
if ($inpar{finalize}) {                                          ### IF FINALIZE

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
		 "--- Producing final source list.");

    # add information about task parameters
    my $hdrinfo="edetect_stack ".
	"attitudesets='".(join(' ', sort values %atthash))."' ".
	"summarysets='".(join(' ', sort values %sumhash))."' ";
    $hdrinfo.="$_=".(ref($inpar{$_}) eq 'ARRAY' 
		     ? "'".(join(' ', @{$inpar{$_}}))."' " 
		     : "$inpar{$_} ") for (sort keys %inpar);

    # call stack_sourcelist
    stack_sourcelist( $inpar{eml_mllistset}, 
		      $inpar{srclistset},
		      $inpar{mlmin},
		      $inpar{eml_hrpndef}, 
		      $inpar{eml_hrm1def}, 
		      $inpar{eml_hrm2def},
		      $hdrinfo              );

}                                                            ### END IF FINALIZE








######################################################### END MAIN EDETECT_STACK
################################################################################







################################################################################
########################################################################### DATA


################################################################################
## GET AND SET TASK PARAMETERS as "global" variables

sub stack_data {

# general parameters
# lists: counter & (sorted) array
                        # n.b. parameterCount()>=1 : default value is always set
#        input: either (list of) file name(s) or name of an ASCII file
    ## read all parameters except for summary and attitude files into inpar hash
    @{$inpar{eventsets}} = get_filelist("eventsets");
    $inpar{mlmin}     = realParameter("mlmin");  
    push @{$inpar{pimin}}, intParameter("pimin", $_)
	for 0 .. parameterCount("pimin")-1;
    push @{$inpar{pimax}}, intParameter("pimax", $_)
	for 0 .. parameterCount("pimax")-1;
    push @{$inpar{ecf}}, realParameter("ecf", $_)
	for 0 .. parameterCount("ecf")-1;
    $inpar{srclistset} = stringParameter("srclistset");
    # stages parameters are used temporarily to define the stages array at the
    # end of the subroutine
    $inpar{minstage} = stringParameter("minstage");
    $inpar{maxstage} = stringParameter("maxstage");
    $inpar{informational} = stringParameter("informational");
    $inpar{prefix} = stringParameter("prefix");

# per task:
# one boolean parameter to decide whether task should be run
# one string parameter with file base names:
#                      output files, if task is run
#                      input files for the following stuff, if task isn't run
# parameter names are the task-parameter names with a task-specific prefix

# attcalc parameters
    $inpar{runattcalc} = booleanParameter("runattcalc");
    push @{$inpar{att_eventset}}, stringParameter("att_eventset", $_)
	for 0..parameterCount("att_eventset")-1 ;
    $inpar{with_att_nominalcoord} = booleanParameter("with_att_nominalcoord");
    $inpar{att_nominalra} = realParameter("att_nominalra");
    $inpar{att_nominaldec} = realParameter("att_nominaldec");
    $inpar{with_att_imagesize} = booleanParameter("with_att_imagesize");
    $inpar{att_imagesize} = realParameter("att_imagesize");

# evselect parameters
    $inpar{runevselectimages} = booleanParameter("runevselectimages");
    push @{$inpar{ev_imageset}}, stringParameter("ev_imageset", $_)
	for 0..parameterCount("ev_imageset")-1 ;
    $inpar{ev_xcolumn} = stringParameter("ev_xcolumn");
    $inpar{ev_ycolumn} = stringParameter("ev_ycolumn");
    $inpar{ev_ximagebinsize} = realParameter("ev_ximagebinsize");
    $inpar{ev_yimagebinsize} = realParameter("ev_yimagebinsize");
    $inpar{ev_withxranges} = booleanParameter("ev_withxranges");
    $inpar{ev_ximagemin} = realParameter("ev_ximagemin");
    $inpar{ev_ximagemax} = realParameter("ev_ximagemax");
    $inpar{ev_withyranges} = booleanParameter("ev_withyranges");
    $inpar{ev_yimagemin} = realParameter("ev_yimagemin");
    $inpar{ev_yimagemax} = realParameter("ev_yimagemax");
    $inpar{ev_withimagedatatype} = booleanParameter("ev_withimagedatatype");
    $inpar{ev_imagedatatype} = stringParameter("ev_imagedatatype");


# eexpmap parameters
    $inpar{runeexpmap} = booleanParameter("runeexpmap");
    push @{$inpar{eexp_expimageset}}, stringParameter("eexp_expimageset", $_)
	for 0..parameterCount("eexp_expimageset")-1 ;
    $inpar{eexp_attrebin} = realParameter("eexp_attrebin");


# emask parameters
    $inpar{runemask} = booleanParameter("runemask");
    push @{$inpar{emask_detmaskset}}, stringParameter("emask_detmaskset", $_)
	for 0..parameterCount("emask_detmaskset")-1 ;
    $inpar{emask_threshold1} = realParameter("emask_threshold1");
    $inpar{emask_threshold2} = realParameter("emask_threshold2");
    $inpar{emask_withregionset} = booleanParameter("emask_withregionset");
    $inpar{emask_regionset} = stringParameter("emask_regionset");


# eboxdetect parameters (local mode, per observation)
    $inpar{runeboxdetectlocal} = booleanParameter("runeboxdetectlocal");
    push @{$inpar{eboxl_boxlistset}}, stringParameter("eboxl_boxlistset", $_)
	for 0..parameterCount("eboxl_boxlistset")-1 ;
    $inpar{eboxl_likemin} = realParameter("eboxl_likemin");
    $inpar{eboxl_boxsize} = intParameter("eboxl_boxsize");
    $inpar{eboxl_nruns} = intParameter("eboxl_nruns");


# esplinemap parameters
    $inpar{runesplinemap} = booleanParameter("runesplinemap");  
    push @{$inpar{esp_bkgimageset}}, stringParameter("esp_bkgimageset", $_)
	for 0..parameterCount("esp_bkgimageset")-1 ;
    $inpar{esp_scut} = realParameter("esp_scut");
    $inpar{esp_mlmin} = realParameter("esp_mlmin");
    $inpar{with_esp_nsplinenodes} = booleanParameter("with_esp_nsplinenodes");
    $inpar{esp_nsplinenodes} = intParameter("esp_nsplinenodes");
    $inpar{esp_excesssigma} = realParameter("esp_excesssigma");
    $inpar{esp_nfitrun} = intParameter("esp_nfitrun");
    $inpar{esp_snrmin} = realParameter("esp_snrmin");
    $inpar{esp_smoothsigma} = realParameter("esp_smoothsigma");
    $inpar{esp_withcheeseimage} = booleanParameter("esp_withcheeseimage");
    $inpar{esp_cheeseimageset} = stringParameter("esp_cheeseimageset");
    $inpar{esp_withcheesemask} = booleanParameter("esp_withcheesemask");
    $inpar{esp_cheesemaskset} = stringParameter("esp_cheesemaskset");
    $inpar{esp_fitmethod} = stringParameter("esp_fitmethod");
    push @{$inpar{esp_expimagesetvig}},stringParameter("esp_expimagesetvig", $_)
	for 0..parameterCount("esp_expimagesetvig")-1;
    $inpar{esp_withexpimage2} = booleanParameter("esp_withexpimage2");


# eboxdetect parameters (map mode, per observation)
    $inpar{runeboxdetectmap} = booleanParameter("runeboxdetectmap");
    push @{$inpar{eboxm_boxlistset}}, stringParameter("eboxm_boxlistset", $_)
	for 0..parameterCount("eboxm_boxlistset")-1 ;
    $inpar{eboxm_likemin} = realParameter("eboxm_likemin");
    $inpar{eboxm_boxsize} = intParameter("eboxm_boxsize");
    $inpar{eboxm_nruns} = intParameter("eboxm_nruns");
    $inpar{eboxm_hrdef} = stringParameter("eboxm_hrdef");


# emosaic parameters
    $inpar{runemosaic} = booleanParameter("runemosaic");    
    $inpar{emos_mosaicedset} = stringParameter("emos_mosaicedset");


# esensmap parameters
    $inpar{runesensmap} = booleanParameter("runesensmap");  
    push @{$inpar{esen_sensimageset}}, stringParameter("esen_sensimageset", $_)
	for 0..parameterCount("esen_sensimageset")-1 ;


# eboxdetect parameters (map mode, stacked observations) 
    $inpar{runeboxdetectstack} = booleanParameter("runeboxdetectstack");
    $inpar{eboxs_boxlistset} = stringParameter("eboxs_boxlistset");
    $inpar{eboxs_likemin} = realParameter("eboxs_likemin");
    $inpar{eboxs_boxsize} = intParameter("eboxs_boxsize");
    $inpar{eboxs_nruns} = intParameter("eboxs_nruns");
    $inpar{eboxs_hrdef} = stringParameter("eboxs_hrdef");


# emldetect parameters
    $inpar{runemldetect} = booleanParameter("runemldetect");  
    $inpar{eml_mllistset} = stringParameter("eml_mllistset");
    $inpar{eml_psfmodel} = stringParameter("eml_psfmodel");   
    $inpar{eml_mlmin} = realParameter("eml_mlmin");
    $inpar{eml_dmlextmin} = realParameter("eml_dmlextmin");
    $inpar{eml_fitextent} = booleanParameter("eml_fitextent");
    $inpar{eml_minextent} = realParameter("eml_minextent");
    $inpar{eml_maxextent} = realParameter("eml_maxextent");
    $inpar{eml_nmaxfit} = intParameter("eml_nmaxfit");
    $inpar{eml_nmulsou} = intParameter("eml_nmulsou");
    $inpar{eml_fitposition} = booleanParameter("eml_fitposition");
    $inpar{eml_determineerrors} = booleanParameter("eml_determineerrors");
    $inpar{eml_ecut} = realParameter("eml_ecut");
    $inpar{eml_scut} = realParameter("eml_scut");
    $inpar{eml_withsourcemap} = booleanParameter("eml_withsourcemap");
    $inpar{eml_sourceimagesets} = stringParameter("eml_sourceimagesets");
    $inpar{eml_hrpndef} = stringParameter("eml_hrpndef");
    $inpar{eml_hrm1def} = stringParameter("eml_hrm1def");
    $inpar{eml_hrm2def} = stringParameter("eml_hrm2def");
    $inpar{eml_extentmodel} = stringParameter("eml_extentmodel");
    $inpar{eml_withthreshold} = booleanParameter("eml_withthreshold");
    $inpar{eml_threshold} = realParameter("eml_threshold");
    $inpar{eml_threshcolumn} = stringParameter("eml_threshcolumn");
    $inpar{eml_withhotpixelfilter} = booleanParameter("eml_withhotpixelfilter");
    $inpar{eml_withtwostage} = booleanParameter("eml_withtwostage");
    $inpar{eml_withxidband} = booleanParameter("eml_withxidband");
    $inpar{eml_xidfixed} = booleanParameter("eml_xidfixed");
    $inpar{eml_xidecf} = stringParameter("eml_xidecf");
    $inpar{eml_xidpndef} = stringParameter("eml_xidpndef");
    $inpar{eml_xidm1def} = stringParameter("eml_xidm1def");
    $inpar{eml_xidm2def} = stringParameter("eml_xidm2def");

# stack_sourcelist parameters
    $inpar{finalize} = booleanParameter("finalize");    



######################
## Set stages pointers
    ## initialize
    @stagepointers = (
	\$inpar{runattcalc}, 
	\$inpar{runevselectimages}, 
	\$inpar{runeexpmap}, 
	\$inpar{runemask}, 
	\$inpar{runeboxdetectlocal}, 
	\$inpar{runesplinemap}, 
	\$inpar{runeboxdetectmap}, 
	\$inpar{runesensmap}, 
	\$inpar{runemosaic}, 
	\$inpar{runeboxdetectstack}, 
	\$inpar{runemldetect},
	\$inpar{finalize}
	);
    my @tmpnames = qw/runattcalc
                   runevselectimages
                   runeexpmap
                   runemask
                   runeboxdetectlocal
                   runesplinemap
                   runeboxdetectmap
                   runesensmap
                   runemosaic
                   runeboxdetectstack
                   runemldetect
                   finalize/;
    ## modify stagepointers, if minstage and/or maxstage are set
    ## -> precedence over run* parameters
    # convert string input into index
    if ( $inpar{minstage} !~ /^[0-9.EeDd]+$/ ) {
	my ($tmpind) = grep { $tmpnames[$_] eq $inpar{minstage} } 0..$#tmpnames;
	# use reasonable result as minstage index, throw error otherwise
	if (defined $tmpind) {
	    $inpar{minstage}=$tmpind;
	} else {
	    die SAS::error("ParameterError", 
			   "Unknown value of parameter minstage.");
	}
    } else {      # subtract 1 to use minstage as array index
	$inpar{minstage} -=1 ;
    }
    if ( $inpar{maxstage} !~ /^[0-9.EeDd]+$/ ) {
	my ($tmpind) = grep { $tmpnames[$_] eq $inpar{maxstage} } 0..$#tmpnames;
	# use reasonable result as maxstage index, throw error otherwise
	if (defined $tmpind) {
	    $inpar{maxstage}=$tmpind;
	} else {
	    die SAS::error("ParameterError", 
			   "Unknown value of parameter maxstage.");
	}
     } else {      # subtract 1 to use maxstage as array index
	$inpar{maxstage} -=1 ;
    }
    # set pointers
    if ( ($inpar{minstage} > 0) 
	 || ($inpar{maxstage} < $#stagepointers) ) {
	${$stagepointers[$_]} = 0 
	    for (0..$#stagepointers);
	${$stagepointers[$_]} = 1 
	    for ($inpar{minstage}..$inpar{maxstage});
    }

    ## adjust informational output according to "informational" 
    if ( lc $inpar{informational} eq "all" ) {
	$inpar{esp_withcheeseimage} = 1;
	$inpar{esp_withcheesemask} = 1;
	$inpar{runesensmap} = 1;
	$inpar{runemosaic} = 1;
	$inpar{eml_withsourcemap} = 1;
    }
    if ( lc $inpar{informational} eq "none" ) {
	$inpar{esp_withcheeseimage} = 0;
	$inpar{esp_withcheesemask} = 0;
	$inpar{runesensmap} = 0;
	$inpar{runemosaic} = 0;
	$inpar{eml_withsourcemap} = 0;
    }


########################################################################
# SUMHASH, ATTHASH, REFERENCE COORDINATES AND IMAGE SIZE

    # coordinate arrays, used to derive reference position and image size
    my @ahfra;
    my @ahfde;
    my @ahfpa;

    ## attitude- and summarysets: read directly into {att,sum}hashes, if needed
    if ($inpar{runattcalc}) {                                  ### if runattcalc
	for my $sumfile (get_filelist("summarysets")) {
	    # test for file existence
	    open FILE, '<', $sumfile
		or SAS::error("FileNotFound", "Could not open $sumfile. ".
			      "File not found or unreadable.");
	    # get OBS_ID from file and use it as sumhash identifier
	    while (<FILE>) { $sumhash{substr($_,0,10)} = $sumfile
				 and last if (($_ =~ "Observation Identifier") || 
					      ($_ =~ "Observation/Slew Identifier"))}
	    close FILE;
	}

	for my $atfile (get_filelist("attitudesets")) {
                                                    ### loop over attitude files
	    # test for file existence
	    if (! -e "$atfile") {
		SAS::error("FileNotFound", "Could not open $atfile. ".
			   "File not found or unreadable.");
	    }
	    # get header keyword from 0th extension
	    # and use it as atthash identifier
	    $atthash{(fits_get_headerkey($atfile, 0, "OBS_ID"))[0]} = $atfile;

	    # information used to determine reference coordinates and image size

	    # minimum and maximum (telescope) coordinates AHFRA, AHFDEC 
	    # from attitude files

	    # open fits file (readonly)
	    my $fits = SimpleFITS->open($atfile, type=>"table", 
					access=>"readonly");
	    ($fits->status() == 0) 
		or SAS::error("FileNotFound", 
			      "Could not open $atfile.".
			      " File not found or unreadable.");
	    # get coordinate columns
	    $fits->SimpleFITS::readcol("AHFRA",  {}, my $ahfraref);
	    $fits->SimpleFITS::readcol("AHFDEC", {}, my $ahfderef);
	    # close fits file
	    $fits->close();
	    # get minimum and maximum right ascension and declination
	    push @ahfra, ((List::Util::min @$ahfraref), 
			  (List::Util::max @$ahfraref));
	    push @ahfde, ((List::Util::min @$ahfderef),
			  (List::Util::max @$ahfderef));
	    # get position angle
	    my @posang = fits_get_headerkey($atfile, 0, "MAHFPA");
	    push @ahfpa, (abs(sin(PI180*$posang[0]))
			  + abs(cos(PI180*$posang[0])));

	}                                       ### end loop over attitude files


	# reference coordinates and imagesize:
	# min, max, mean of nominal coordinates of observations
	my $ramin = List::Util::min @ahfra;
	my $ramax = List::Util::max @ahfra;
	my $demin = List::Util::min @ahfde;
	my $demax = List::Util::max @ahfde;

	# reference coordinates, if not given by user
	unless ($inpar{with_att_nominalcoord}) {             
	    $inpar{att_nominalra}  = 0.5 * ($ramin + $ramax);
	    $inpar{att_nominaldec} = 0.5 * ($demin + $demax);
	    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			 "Setting reference R.A. to $inpar{att_nominalra}");
	    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			 "Setting reference DEC. to $inpar{att_nominaldec}");
	}
	# reference (half) imagesize, if not given by user:
	# maximum distance + field of view (0.36 deg), assuming small distances
	# (should be accurate enough): dRA ~ ( RA2 - RA1 ) * cos( DEC ) [radian]
	unless ($inpar{with_att_imagesize}) {                          # degrees
	    my $tmpsize = List::Util::max 
	     ( ($ramax-$inpar{att_nominalra})*cos(PI180*$inpar{att_nominaldec}),
	       ($inpar{att_nominalra}-$ramin)*cos(PI180*$inpar{att_nominaldec}),
	       ($demax-$inpar{att_nominaldec}),
	       ($inpar{att_nominaldec}-$demin) );
	    $inpar{att_imagesize} = $tmpsize + 0.275*(List::Util::max @ahfpa);
                                         # half the field of view plus something
	    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, 
			 "Setting mosaic half-image size to ".
			 "$inpar{att_imagesize} degrees");
	}

    }                              ### end if runattcalc / reference coordinates


########################################################################
## SANITY CHECKS, ERRORS, WARNINGS

# mlmin >= eml_mlmin
    if ($inpar{mlmin} < $inpar{eml_mlmin}) {
	SAS::error("ParameterMismatch", 
		   "The final likelihood threshold mlmin must be equal to or ".
		   "greater than eml_mlmin of the intermediate emldetect ".
		   "source list.")
    }

# number of input files
    if (scalar keys %atthash != scalar keys %sumhash) {
	SAS::error("FileMismatch", 
		   "Number of input odf summary files does not match ".
		   "number of input attitude files.")
    }

# number of energy bands
    if ( $#{$inpar{pimin}} != $#{$inpar{pimax}}) {
	SAS::error("ParameterCountMismatch", 
		   "Number of upper energy-band boundaries does not match ".
		   "number of lower energy-band boundaries.")
    }

# number of event lists
    if ($#{$inpar{eventsets}} != 0 && $#{$inpar{att_eventset}} != 0 
	&& $#{$inpar{att_eventset}} != $#{$inpar{eventsets}}) {
	SAS::error("FileMismatch", 
		   "Number of input event files (eventsets) does not match ".
		   "number of output event files (att_eventset).")
    }





######################
## Set default efcs.
## Current values (i.e.: as of July 2013): 3XMM
## Default bands: http://xmmssc-www.star.le.ac.uk/Catalogue/3XMM-DR4/UserGuide_xmmcat.html#TabBands
## Default ecfs:  http://xmmssc-www.star.le.ac.uk/Catalogue/3XMM-DR4/UserGuide_xmmcat.html#TabNewECFs
## Fixed filter wheel positions: Closed, Thin1, Thin2, Medium, Thick, Open

## 1. USER INPUT?

# ECFs should be positive, so we just need to check their sum to know whether
# all values are zero
    if (List::Util::sum @{$inpar{ecf}}) {        ### if user input exists
	# concat ECFs per observation-instrument combination (= event file)
	# i.e. one string, made out of (@pimin) ECFs, for each combination.
	# overwrite @{$inpar{ecf}}.
	@{$inpar{ecf}} = 
	                                            ### join ECFs
	                                            ### (e.g. join 5 ECFs)
	    map { join(' ', "@{$inpar{ecf}}[$_..$_+$#{$inpar{pimin}}]") }
	                                            ### for each event list
	                                            ### (e.g. for every 5th ECF)
   	    (grep { !($_ % (@{$inpar{pimin}})) } 0..$#{$inpar{ecf}});

    } else {                                        ### end if user input - else

## 2. or DEFAULT VALUES? (if 3XMM standard energy bands)

        # initialize %ecfs with 0s
	@{$ecfs{$_}}{@instrs}  = (0.0)x(@instrs)
	    for (qw(Open Thin Thic Medi Clos)) ;

        # compare pimin, pimax values with default arrays
        # if all pimin values are equal to pimindef values etc.
	my @pimindef = qw(200 500 1000 2000 4500);
	my @pimaxdef = qw(500 1000 2000 4500 12000);
## a CAL call would be nice ...
	if ($#pimindef == $#{$inpar{pimin}}) {   ### if number of standard bands

	    if ( ( List::Util::sum 
		   (map { $inpar{pimin}[$_] == $pimindef[$_] } 0..$#pimindef)
		   == (@pimindef) ) &&
		 ( List::Util::sum 
		   (map { $inpar{pimax}[$_] == $pimaxdef[$_] } 0..$#pimaxdef)
		   == (@pimaxdef) ) ) {                   ### if standard bands

		# ecfs hash is addressed by filter and instrument id and holds
		# arrays corresponding to the energy bands, where the filter
		# id is given by the first four characters of the filter
		# header keyword

		# band             1       2       3       4       5

		$ecfs{Open}{PN} = "16.9783 10.0696  6.1551  1.9844  0.5782";
		$ecfs{Open}{M1} = " 3.0896  2.1152  2.1387  0.7491  0.1452";
		$ecfs{Open}{M2} = " 3.1094  2.1309  2.1407  0.7531  0.1528";

		$ecfs{Thin}{PN} = " 9.5248  8.1210  5.8670  1.9527  0.5774";
		$ecfs{Thin}{M1} = " 1.7345  1.7461  2.0407  0.7375  0.1450";
		$ecfs{Thin}{M2} = " 1.7336  1.7572  2.0426  0.7418  0.1528";

		$ecfs{Medi}{PN} = " 8.3696  7.8681  5.7673  1.9290  0.5764";
		$ecfs{Medi}{M1} = " 1.5258  1.6974  2.0058  0.7292  0.1451";
		$ecfs{Medi}{M2} = " 1.5223  1.7082  2.0079  0.7333  0.1524";

		$ecfs{Thic}{PN} = " 5.1065  6.0479  4.9893  1.8282  0.5698";
		$ecfs{Thic}{M1} = " 0.9977  1.3792  1.7871  0.6991  0.1430";
		$ecfs{Thic}{M2} = " 0.9907  1.3869  1.7887  0.7030  0.1502";

		$ecfs{Clos}{PN} = " 0.0     0.0     0.0     0.0     0.0   ";
		$ecfs{Clos}{M1} = " 0.0     0.0     0.0     0.0     0.0   ";
		$ecfs{Clos}{M2} = " 0.0     0.0     0.0     0.0     0.0   ";

	    }                                          ### end if standard bands

	}                   	             ### end if number of standard bands

	# energy ranges of XID band
	if ( ($#{$inpar{pimin}} == 0)          &&
	     ($inpar{pimin}[0] == $pimindef[1]) &&
	     ($inpar{pimax}[0] == $pimaxdef[3])  ) { ### if XID band energies

		 $ecfs{Open}{PN} = "5.0980";
		 $ecfs{Open}{M1} = "1.5035";
		 $ecfs{Open}{M2} = "1.5097";

		 $ecfs{Thin}{PN} = "4.5586";
		 $ecfs{Thin}{M1} = "1.3843";
		 $ecfs{Thin}{M2} = "1.3894";
                           
		 $ecfs{Medi}{PN} = "4.4602";
		 $ecfs{Medi}{M1} = "1.3584";
		 $ecfs{Medi}{M2} = "1.3634";
                           
		 $ecfs{Thic}{PN} = "3.7636";
		 $ecfs{Thic}{M1} = "1.2035";
		 $ecfs{Thic}{M2} = "1.2076";
                           
		 $ecfs{Clos}{PN} = "0.0   ";
		 $ecfs{Clos}{M1} = "0.0   ";
		 $ecfs{Clos}{M2} = "0.0   ";

	}                                           ### end if XID band energies
	
    }                                                    ### end else user input


########################################################################
## SORT INPUT / OUTPUT FILES
## (useful, if the user doesn't want to follow the default naming)

    # input event lists
    # - sort them _before_ attitude files: rare cases of wrong FILTER keywords
    #   are corrected by epchain/epproc/epframes, and EXP_ID is set
    # - not needed for last stage
    if ($inpar{minstage} < 11) {
	%infiles = sort_inputfiles(\@{$inpar{eventsets}});
    }

    ### All other file names are set directly before the respective
    ### task stages are run, so we can change them in the course of
    ### further checks (e.g.: empty images).
    
    # eboxdetect lists per pointing (<- eboxdetect)
    # separately: only depending on pointing ids.
    # Assume they are sorted correctly by the user.
    # single entry: expand to default names.
    # several entries: user-supplied names - no changes necessary.
    if ($#{$inpar{eboxl_boxlistset}} == 0) {
	my $tmpbase = $inpar{prefix}.$inpar{eboxl_boxlistset}[0];
	$inpar{eboxl_boxlistset}[$_] = "$tmpbase"."$pntids[$_]".".fits"
	    for 0..$#pntids ;
    }
   if ($#{$inpar{eboxm_boxlistset}} == 0) {
	my $tmpbase = $inpar{prefix}.$inpar{eboxm_boxlistset}[0];
	$inpar{eboxm_boxlistset}[$_] = "$tmpbase"."$pntids[$_]".".fits"
	    for 0..$#pntids ;
    }
    $inpar{eboxs_boxlistset} = 
	"$inpar{prefix}"."$inpar{eboxs_boxlistset}";
    # insert "_intermediate" between basename and suffix of stacked list
    my ($suffix) =  ($inpar{eboxs_boxlistset} =~ /.*(\..*)/) 
	            ? $inpar{eboxs_boxlistset} =~ /.*(\..*)/ : "";
    if ($suffix eq ".gz" || $suffix eq ".GZ") {
	($suffix) = ($inpar{eboxs_boxlistset} =~ /.*(\..*)\.(.*)/)
	            ? $inpar{eboxs_boxlistset} =~ /.*(\..*)\.(.*)/ : "";
    }
    # determine file base
    ($inpar{eboxs_intermediate})
	= ($inpar{eboxs_boxlistset} =~ /(.*)$suffix/);
    $inpar{eboxs_intermediate}
         = $inpar{eboxs_intermediate}."_intermediate".$suffix;

    # other output files
    $inpar{eml_mllistset} = $inpar{prefix}.$inpar{eml_mllistset};
    $inpar{srclistset}    = $inpar{prefix}.$inpar{srclistset};



}                                                             ### END STACK_DATA
################################################################################



################################################################################
## FLEXIBLE INPUT FORMAT FOR FILE-NAME LISTS

sub get_filelist {

    # expecting one argument:
    @==1 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: get_filelist. ".
			 "Blame (or contact) the developer.");

    # input: parameter name
    my $parm = $_[0];

    # output: array of parameter values
    my @parvals;

    # input: either (list of) file name(s) or name of an ASCII file
    # 1. get number of list elements
    my $cnt = parameterCount($parm)-1;

    # 2. read first list element
    my $fst = stringParameter($parm, 0);

    # 3. if single element starting with "@": read ASCII file
    #    else: append list elements to parameter array
    if ( $cnt == 0 && (substr $fst, 0, 1) eq '@' ) {
	$fst = substr $fst, 1;
	open FILE, '<', $fst
	    or SAS::error("FileNotFound", "Could not open $fst. ".
			  "File not found or unreadable.");
	while (<FILE>) { push @parvals, $_ if /\S/ }
	close FILE;
	chomp @parvals;
    } else {
	push @parvals, $fst;
	push @parvals, stringParameter($parm, $_) for 1 .. $cnt;
    }

    # done
    return @parvals;

}                                                           ### END GET_FILELIST



################################################################################
## GET HEADER KEYWORDS FROM INPUT FILES AND SORT THEM INTO STRUCTURE(s)
##
## Important: In principle, the energy bands could be read from the HISTORY
## and other header entries. However, this approach is too complex and too
## risky / too prone to errors. Therefore, this routine checks for pointing
## and instrument identifiers only. STANDARD NOTATION OF THE ENERGY BANDS IN
## THE FILE NAMES IS STILL MANDATORY.

# unique mechanism: cf http://perldoc.perl.org/perlfaq4.html

sub sort_inputfiles {

    # input: list of file names
    my @inlist = @{$_[0]};
    # an additional argument means: use first extension for keywords
    my ($extno) = @_==1 ? 0 : 1;
    # output: hash of file names sorted by pointing identifier and instrument 
    my %filehash;
    my %tmphash;
    # by-product: temporary list of filter names
    my %tmpecfs;

    # temporary arrays holding the header keywords of interest
    my @tmpobsids;
    my @tmpexpids;
    my @tmpinstrs;
    my @tmpfilter;
    my @tmprapnt;
    my @tmpdepnt;
    my @tmppapnt;
    my @tmpdate;
    # temporary array of pointing identifiers
    my @tmppntids;

    # start loop over input files to collect the header keywords
    for my $infile (@inlist) {                          ### loop over input list

	# test for file existence
	if (! -e "$infile") {
	    SAS::error("FileNotFound", "Could not open $infile. ".
		       "File not found or unreadable.");
	}

	# get header keywords from 0th extension (det. masks: 1st extension)
	my @tmpkeys = fits_get_headerkey($infile, $extno, 
					 "OBS_ID", 
					 "EXP_ID",
					 "INSTRUME",
					 "FILTER",
					 "RA_PNT",
					 "DEC_PNT",
					 "PA_PNT",
					 "DATE-OBS");	

	# short instrument names
	$tmpkeys[2] = "PN" if ("$tmpkeys[2]" eq "EPN");
	$tmpkeys[2] = "M1" if ("$tmpkeys[2]" eq "EMOS1");
	$tmpkeys[2] = "M2" if ("$tmpkeys[2]" eq "EMOS2");

	# pass the results to the temporary array
	push @tmpobsids, $tmpkeys[0];           # OBS_ID
	push @tmpexpids, $tmpkeys[1];           # EXP_ID
	push @tmpinstrs, $tmpkeys[2];           # INSTRUME
	push @tmpfilter, $tmpkeys[3];           # FILTER
	push @tmprapnt,  $tmpkeys[4];           # RA_PNT
	push @tmpdepnt,  $tmpkeys[5];           # DEC_PNT
	push @tmppapnt,  $tmpkeys[6];           # PA_PNT
	push @tmpdate,   $tmpkeys[7];           # DATE-OBS

    }                                               ### end loop over input list

 
    # get unique OBS_IDs
    my %seen = ();
    my @obsids = grep { ! $seen{ $_ }++ } @tmpobsids;

    ## first call: set array of instruments if not yet defined
    unless (@instrs) {

	# get unique instruments
	my %seen = ();
	@instrs = grep { ! $seen{ $_ }++ } @tmpinstrs;
    }


    # "Normal" pointings are identified by their OBS_ID and have different
    # EXP_IDs, which encode the instrument.
    # Mosaic-mode observations may have several event lists per instrument
    # with the same OBS_ID, which can be identified by their integer
    # (pseudo-)exposure ID, thanks to emosaic_prep.

    # check number of instruments per OBS_ID
    for my $obs (@obsids) {                                 ### loop over obsids

	# locate all occurrences of $obs in @tmpobsids
	my @ind = grep { $tmpobsids[$_] eq $obs } 0..$#tmpobsids;

	# how often is each instrument listed for this obsid?
	# ("grep" in scalar context)
	my $cnt = 0;                                          # exposure counter
	for my $inst (@instrs) {
	    my $niinst = grep {/$inst/} @tmpinstrs[@ind];
	    $cnt = List::Util::max $cnt, $niinst;
	}

	# If one+ instrument is listed more than once: expids are the same for
	# all instruments of one pointing (-> emosaic_prep).
	# Smallest OBS_ID: 110101.
	my @tmpecnt = grep { $_ == $tmpexpids[$ind[0]]
				 && $_ <= 110100 } (@tmpexpids[@ind]);
	# Otherwise: replace them by zeros.
	if ($#tmpecnt != $#ind && $cnt <= 1) {
	    # work on slice of @tmpexpids
	    my @eislice = @tmpexpids[@ind];
	    # replace
	    $eislice[$_] = "000" for 0..$#eislice;
	    # copy slice back to @tmpexpids;
	    @tmpexpids[@ind] = @eislice;
	}


	# save file name and instrument identifier for all obsid matches
	for my $ii (@ind) {                          ### loop over obsid matches

	    # set pointing identifier
	    my $pnt = "$obs"."E"."$tmpexpids[$ii]";
	    push @tmppntids, $pnt;

	    # set hash entry
	    $tmphash{$pnt}{$tmpinstrs[$ii]} = $inlist[$ii];

	    # activate indicator
	    $expisset{$pnt}{$tmpinstrs[$ii]} = 1;

	    # set ECFs, if given by the user or previously defined
	    if ($inpar{ecfs}[$ii]) {
		$tmpecfs{$pnt}{$tmpinstrs[$ii]} = $inpar{ecfs}[$ii];
	    } else {
		if ( ($tmpfilter[$ii]) 
		     && ($ecfs{substr($tmpfilter[$ii], 0, 4)}{$tmpinstrs[$ii]})
		    ) {
		    $tmpecfs{$pnt}{$tmpinstrs[$ii]} = 
			$ecfs{substr($tmpfilter[$ii], 0, 4)}{$tmpinstrs[$ii]};
		} else {                             # set them to 0.0 otherwise
		    $tmpecfs{$pnt}{$tmpinstrs[$ii]} =
			join(" ", ("0.0")x(@{$inpar{pimin}}));
		}
	    }

	}                                        ### end loop over obsid matches

    }                                                   ### end loop over obsids


    # set array of pointings if not yet defined
    unless (@pntids) {
	# get unique pointing ids and respective indexes (via a hash slice)
	my %indpnt = ();
	@indpnt{@tmppntids} = (0..$#tmppntids);
	@pntids = sort keys %indpnt;

	#############
	## first call: check whether all observations are overlapping
	# straight forward: 
	# - use centers of pointings as nodes
	# - define a path using the nearest node that has not yet been visited
	# - calculate paths starting from each node
	# - if all paths have at least too elements larger than $maxdist, then
	#   we are dealing with non-overlapping (groups of) pointings

	# initialize result array
	my @longpaths = ();
	# loop over nodes
	for my $in (0..$#pntids) {
	    # initialize distance array
	    my @shortest = ();
	    # initialize array with node indexes
	    my @index = map {($_+$in) % scalar @pntids} (0..$#pntids);
	    # calculate path
	    my $ii=0;
	    while ($#index > 1) {
		my @distances = ();
		# coordinates of node $index[$ii]
		my $tmpra = $tmprapnt[$indpnt{$pntids[$index[$ii]]}];
		my $tmpde = $tmpdepnt[$indpnt{$pntids[$index[$ii]]}];
		# strip from index list
		shift @index;
		# calculate distances to all remaining nodes
		my $tmpcos = cos(PI180*$tmpde);
		for my $jj (0..$#index) {
		    # distance in arcmin
		    push @distances, 
			sqrt( ( ($tmpra - $tmprapnt[$indpnt{$pntids[$index[$jj]]}] )*$tmpcos )**2 
			      + ( $tmpde - $tmpdepnt[$indpnt{$pntids[$index[$jj]]}] )**2 )
			* 60.0;
		}   ## end distance array
		# append shortest distance to result array
		push @shortest, List::Util::min @distances;
	    }  # end path loop
	    # close path
	    push @shortest, sqrt( ( ($tmprapnt[$indpnt{$pntids[$index[$ii]]}] - $tmprapnt[$indpnt{$pntids[$in]}] )*cos(PI180*$tmpdepnt[$indpnt{$pntids[$index[$ii]]}]) )**2 + ( $tmpdepnt[$indpnt{$pntids[$index[$ii]]}] - $tmpdepnt[$indpnt{$pntids[$in]}] )**2 )*60.0;

	    # determine number of path segments which are longer than $maxdist
	    my $toolarge = grep {$_ > $maxdist} @shortest;
	    if ($toolarge <= 1) {
		last;
	    }
	    push @longpaths, $toolarge;
	}   # end loop over nodes

	# final result: have we found a path with less than two long segments?
        if (scalar @longpaths > 0) {
	    my $tmpcount = grep {$_ <= 1} @longpaths;
	    if ($tmpcount < 1) { 
		die SAS::error("NotOverlapping", 
			       "One or more pointings do(es) not overlap with".
			       " any other input pointing (maximum distance".
			       " between image centers: 2*12.0 arcmin)");
	    }
	} ### end distance tests


	#############
        # more detailed, if coordinates / image size are set by the user: check
	# whether input attitudes are not overlapping with the analysis region
	if (($inpar{with_att_nominalcoord}) || ($inpar{with_att_imagesize})) {

	    my $cdec = cos(PI180*$inpar{att_nominaldec});
	    my @compcoords = 
		($inpar{att_nominalra},
		 $inpar{att_nominalra} - $inpar{att_imagesize}*$cdec,
		 $inpar{att_nominalra} + $inpar{att_imagesize}*$cdec,
		 $inpar{att_nominaldec},
		 $inpar{att_nominaldec} - $inpar{att_imagesize},
		 $inpar{att_nominaldec} + $inpar{att_imagesize}) ;

	    for my $ipnt (reverse(0..$#pntids)) {      # loop over pointings
		# initialize variable for on-chip testing
		my $onchip;
		# reference coordinates are:
		# right ascension: $tmprapnt[$indpnt{$pntids[$ipnt]}]
		# declination:     $tmpdepnt[$indpnt{$pntids[$ipnt]}]
		# position angle:  $tmppapnt[$indpnt{$pntids[$ipnt]}]
		# starting date:   $tmpdate[$indpnt{$pntids[$ipnt]}]
		for my $ins (qw(EPN EMOS1 EMOS2))   {    # loop over instruments
		    # at least one corner of the analysis region
		    # has to be on a chip
		    for my $icc (0..8) {                     # loop over corners
                                    # Technical remark: Here, we need to capture
                                    # the task output, so the usually used
		                    # "system" is replaced by "open" here.
			open my $spipe, '-|', "esky2det".
			    " ra=".$compcoords[$icc % 3].
			    " dec=".$compcoords[int($icc/3)+3].
			    " datastyle=user".
			    " checkfov=yes".
			    " outunit=raw".
			    " withheader=no".
			    " calinfostyle=user".
			    " instrument=".$ins.
			    " scattra=".$tmprapnt[$indpnt{$pntids[$ipnt]}].
			    " scattdec=".$tmpdepnt[$indpnt{$pntids[$ipnt]}].
			    " scattapos=".$tmppapnt[$indpnt{$pntids[$ipnt]}].
			    " datetime=".$tmpdate[$indpnt{$pntids[$ipnt]}].
			    " -V 0 -w 0"
			    or die SAS::error("TaskError", 
					  "Unexpected error $! occurred when".
					  " trying to execute task esky2det");
			($onchip) = (split /\s+/, "  ".<$spipe>)[4];
   		                 # (split on blanks including beginning of line)
			close $spipe 
			    or die SAS::error("TaskError", 
					  "Unexpected error $! occurred when".
					  " executing task esky2det");
		        # stop testing as soon as a valid chip position is found
			last if ($onchip eq "T");
		    }                                    # end loop over corners
		    # stop testing as soon as a valid chip position is found
		    last if ($onchip eq "T");
		}                                    # end loop over instruments
		# if $onchip is still FALSE, then ignore this pointing
		if ($onchip eq "F") {
		    SAS::warning("PointingIgnored","Pointing $pntids[$ipnt] is not overlapping with the analysis region and therefore ignored.\n");
		    delete $tmphash{$pntids[$ipnt]};
		    delete $ecfhash{$pntids[$ipnt]};
	            delete $expisset{$pntids[$ipnt]};
		    splice @pntids, $ipnt, 1;
		}                                            # end test "onchip"
	    }                                          # end loop over pointings
	}                                          # end if user-set coordinates
    }                                        # end if first call to this routine


    # fill remaining combinations of pointing id and instrument id
    # (for easy access and concatenation of filehash)
    for my $pnt (@pntids) {
	# initialize with ""
	@{$filehash{$pnt}}{@instrs} = ("")x(@instrs);
	@{$ecfhash{$pnt}}{@instrs}  = ("")x(@instrs);
	# overwrite with existing values
	@{$filehash{$pnt}}{keys %{$tmphash{$pnt}}} = values %{$tmphash{$pnt}};
	@{$ecfhash{$pnt}}{keys %{$tmpecfs{$pnt}}}  = values %{$tmpecfs{$pnt}};
    }

    # done
    return %filehash;

}                                                        ### END SORT_INPUTFILES


################################################################################
## FILL HASH WITH DEFAULT FILE NAMES <type><expid><instr><elow>_<ehigh>.fits

sub default_names {

    # expecting one argument:
    @_==1 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: default_names. ".
			 "Blame (or contact) the developer.");

    # input: base name of files
    my $fbase = $_[0];

    # suffix: .fits  -  even when original file is compressed ...
    my $suffix = ".fits";

    # output: hash of file names sorted by pointing identifier and instrument 
    my %filehash;


    # loop over pointing identifiers and instruments
    for my $pntid (@pntids) {
	for my $instr (@instrs) {
	    if (exists $expisset{$pntid}{$instr}) {
		# construct standard file name and save it to the structure
		$filehash{$pntid}{$instr} = 
		    "$fbase"."$pntid"."$instr"."$suffix";
	    } else {
		# or set it to an empty string
		$filehash{$pntid}{$instr} = "";
	    }
	}
    }

    # that's all already
    return %filehash;

}                                                          ### END DEFAULT_NAMES



################################################################################
########################################################################## TASKS


################################################################################
### RUN_SASTASK
sub run_sastask {

    # expecting exactly one argument: the command string
    @_==1 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: run_sastask. ".
			 "Blame (or contact) the developer.");

    SAS::message($SAS::AppMsg, $SAS::VerboseMsg, "Calling: $_[0]");
    system("$_[0]");

##    if ($? == -1 || $? & 127) {
##	SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
##		     "Task ended in error: $_[0]");
    if ($? != 0) {
	SAS::error("TaskError",  "Task ended in error: $_[0]");
    }

}                                                            ### END RUN_SASTASK


################################################################################
########################################################################## UTILS


################################################################################
## EXPAND FILE NAME to <type><expid><instr><elow>_<ehigh>.fits

sub ename {

    # expecting three arguments:
    @_>2 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: ename. ".
			 "Blame (or contact) the developer.");

    # file base name
    my $fbase = $_[0];
    # lower energy boundary
    my $elow  = sprintf("_%05i", $_[1]);
    # upper energy boundary
    my $ehig  = sprintf("_%05i", $_[2]);

    # determine file suffix, respecting gzip suffix .gz
    my ($suffix) = ($fbase =~ /.*(\..*)/) ? $fbase =~ /.*(\..*)/ : "";
    if ($suffix eq ".gz" || $suffix eq ".GZ") {
	($suffix) = ($fbase =~ /.*(\..*)\.(.*)/) 
	            ? $fbase =~ /.*(\..*)\.(.*)/ : "";
    }
    # determine file base
    ($fbase) = $fbase =~ /(.*)$suffix/;

    # insert energy bands
    return "$fbase"."$elow"."$ehig"."$suffix";

}                                                                  ### END ENAME


################################################################################
## EXPAND FILE NAME to <type><pntid><instr><elow>_<ehigh>.fits

sub efname {

    # expecting two up to five arguments:
    @_>1 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: efname. ".
			 "Blame (or contact) the developer.");
    # file base name         (mandatory)
    my $fbase = $_[0];
    # exposure id            (mandatory)
    my $pntid = $_[1];
    # instrument             (if at least three arguments)
    my $instr = @_>2 ? $_[2] : "";
    # lower energy boundary  (if at least four arguments)
    my $elow  = @_>3 ? sprintf("_%05i", $_[3]) : "";
    # upper energy boundary  (if [at least] five arguments)
    my $ehig  = @_>4 ? sprintf("_%05i", $_[4]) : "";
    # suffix: .fits  -  even when original file is compressed ...
    my $suffix = ".fits";

    # short instrument names
    $instr = "PN" if ("$instr" eq "EPN");
    $instr = "M1" if ("$instr" eq "EMOS1");
    $instr = "M2" if ("$instr" eq "EMOS2");

    # compose and return 
    return "$fbase"."$pntid"."$instr"."$elow"."$ehig"."$suffix";

}                                                                 ### END EFNAME




################################################################################
## COLLAPSE FILE NAME HASH TO A SINGLE STRING

sub concat_names {

    # input: reference to hash (slice) of file names
    #        reference to array or scalar of pointing identifiers
    my ( $fref, $pref ) = @_;

    # dereference the file reference
    my %inhash = %$fref;
    # dereference the pointing reference
    my @inpnts;
    # array?
    if (ref($pref) eq 'ARRAY') {
	@inpnts = @$pref;
    # else: scalar (per def.)
    } else {
	# treat it as array anyway
	@inpnts = ( $$pref );
    }

    # concat
    # (remaining double blanks won't hurt ...)
    (my @outstr = 
     map {join('', "@{$inhash{$_}}{@instrs} ")} @inpnts) =~ s/  / /g;

    # output: string
    return "@outstr";

}                                                           ### END CONCAT_NAMES




################################################################################
## COLLAPSE FILE NAME HASH TO A SINGLE STRING, EXPANDING ENERGIES

sub concat_names_pi {

    # input: reference to hash (slice) of file names
    #        reference to array or scalar of pointing identifiers
    #        reference to array or scalar of instruments
    #        reference to array or scalar of energy-band numbers
    my ( $fref, $pref, $iref, $eref ) = @_;

    ## dereference the file reference
    my %inhash = %$fref;
    ## dereference the pointing reference
    my @inpnts;
    # array?
    if (ref($pref) eq 'ARRAY') {
	@inpnts = @$pref;
    # else: scalar (per def.)
    } else {
	# treat it as array anyway
	@inpnts = ( $$pref );
    }
    ## dereference the instrument reference
    my @ininstrs;
    # array?
    if (ref($iref) eq 'ARRAY') {
	@ininstrs = @$iref;
    # else: scalar (per def.)
    } else {
	# treat it as array anyway
	@ininstrs = ( $$iref );
    }
    ## dereference the band reference
    my @inebands;
    # array?
    if (ref($eref) eq 'ARRAY') {
	@inebands = @$eref;
    # else: scalar (per def.)
    } else {
	# treat it as array anyway
	@inebands = ( $$eref );
    }

    # concat
    ### at least, we can be sure to be using the most inefficient way to do it
    my $outstr="";
    for my $pntid (@inpnts) {
	for my $instr (@ininstrs) {
	    if (exists $expisset{$pntid}{$instr}) {
		for my $nband (@inebands) {
		    $outstr .= 
			(ename($inhash{$pntid}{$instr}, 
			       $inpar{pimin}[$nband], 
			       $inpar{pimax}[$nband]))." ";
		}
	    }
	}
    }

    # output: string
    return $outstr;

}                                                        ### END CONCAT_NAMES_PI




################################################################################
## EXTRACT KEYWORD FROM FITS HEADER
# returns an empty string if keyword is not found or empty
# (alternative: Fitsplutils::getattribute(file, key)

sub fits_get_headerkey {

    # expecting at least three arguments:
    @_>2 or SAS::message($SAS::AppMsg, $SAS::SilentMsg, 
			 "Internal code error: function call with wrong ".
			 "number of arguments: fits_get_headerkey. ".
			 "Blame (or contact) the developer.");
    # file name (get it and remove it from the list)
    my $fname = shift @_;
    # extension number
    my $ext = shift @_;
    # key name: $_[2] .. $_[$#_]
    ## -> see below
    # result array
    my $tmpres;
    my @res;

   # open fits file (readonly is a shortcut for open(..., access=>"readonly"))
    my $fits = SimpleFITS->readonly($fname, ext=>$ext);
    ($fits->status() == 0) 
	or SAS::error("FileNotFound", "Could not open $fname. ".
		      "File not found or unreadable.");

    # via cfitsio: allow several keywords in one call to fits_get_headerkey
    for my $key (@_) {
	$fits->readkey($key, $tmpres);
	($fits->status() == 0) 
	    or SAS::error("MissingKeyword",
			  "Keyword $key not found in $fname.");
	push @res, $tmpres;
    }
    # close fits file
    $fits->close();

    return @res;

}                                                     ### END FITS_GET_HEADERKEY

################################################################################

}                                                          ### END EDETECT_STACK

######################################################################## THE END
################################################################################
