## @file
# Run XMM Point Source Analysis Chain.
# @par Main PROGRAM
# @par xmmextractor
# @par PURPOSE:
#        -# Run cifbuild and odfingest over an ODF
#        -# Produce Event List: run epproc, emproc, rgsproc and omichain
#        -# Compute GTI: run tabgtigen
#        -# Produce images of MOS/EPIC field of view
#           detected sources: run edetect_chain 
#        -# Spectral Analysis of epic and rgs point sources: 
#        -# Produce Background Subtracted Light Curves for epic and rgs,        
#        -# Produce OM
#
# @par Usage :
#          perl xmmextractor
# @par EXAMPLE
# perl xmmextractor sourcename=CDFSJ03324-2741B obsid=0108060501 analysisoption=all 
# @par DATE  
# 21 Aug 2006
#
# @par Version History
#     - 21 Aug 2006 : ICP : conversion from tcsh to pl script 
#     -  1 Nov 2006 : ICP : add new IDL template to creat Light Curves
#     - 24 Nov 2006 : ICP : add new XSPEC template files to create spectra and
#                           work out counts in different energy ranges
#     - 10 Aug 2007 : ICP : Add file with Global variables
#     - 25 Oct 2007 : ICP : Add file with OBSID Structure
#     - 25 Feb 2008 : ICP : Add RGS and OM analysis
# 	  - 22 Mar 2008 : AI  : SAS Skelton
#     - 11 Jun 2008 : AI  : Light curve functionality implemented
#     - 23 Oct 2008 : AI  : PG signal to noise implemented
#
# @par AUTHOR 
# Ignacio de la Calle and Aitor Ibarra

####################################################################
# PROGRAM: xmmextractor
#-------------------------------------------------------------------
# @par 
# PURPOSE: 
#        1) Run cifbuild and odfingest over an ODF
#        2) Produce Event List: run epproc, emproc, rgsproc and omichain
#        3) Compute GTI: run tabgtigen
#        4) Produce images of MOS/EPIC field of view
#           detected sources: run edetect_chain 
#        5) Spectral Analysis of epic and rgs point sources:            
#        6) Produce Background Subtracted Light Curves for epic and rgs, 
#           
#              
# Usage :
#--------------------------------------------------------------------
# DATE  : 21 Aug 2006
#
# Version History
#     - 21 Aug 2006 : ICP : conversion from tcsh to pl script 
#     -  1 Nov 2006 : ICP : add new IDL template to creat Light Curves
#     - 24 Nov 2006 : ICP : add new XSPEC template files to create spectra and
#                           work out counts in different energy ranges
#     - 10 Aug 2007 : ICP : Add file with Global variables
#     - 25 Oct 2007 : ICP : Add file with OBSID Structure
#     - 25 Feb 2008 : ICP : Add RGS and OM analysis
#
# AUTHOR: Ignacio de la Calle and Aitor Ibarra
#####################################################################



#..
#..Start with code execution
#..

sub xmmextractor ()
{	
use Math::Trig;
use File::Path;
use strict;
use warnings;
use SAS;
use Switch;
use strict;
use Log::Log4perl qw(get_logger);
use File::Find;

require "run_cifbuild.pl";
require "produce_eventlist.pl";
require "produce_epiceventlist.pl";
require "produce_rgseventlist.pl";
require "produce_omeventlist.pl";
require "compute_gti.pl";
require "run_edetectchain.pl";
require "produce_lightcurve.pl";
require "produce_spectrum.pl";
require "tools.pl";
require "pse_parameters_init.pl";
require "pse_obsid_structure.pl";
require "PG_gti_filter.pl";
require "run_epatplot.pl";
require "calculate_Signal2Noise.pl";

require "GVariables.pm";
require "pse_definenames.pl";
require "check_Spectra_Files.pl";
require "prepare_region_log_file.pl";
require "prepare_spectra.pl";
require "run_eregionanalyse.pl";

require "parseXMLConfFile.pl";



	#.. Define Global Variables
    use vars qw(%action_to_take
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
		$gv
		$PG_flagCall
		$outputfile
		$odf_object
		@exposures
		$doc
		$initlogConf
		$logger
		$eventLog
		$gtiLog		
		$specLog
		$lcLog
		$rgsLog
		$rgsLCLog
		$omLog
		$edectLog
		$scienceLog
		);

&init();
&run();

&error_code(0);
&pse_do_exit(0);
}

sub getLogfileName
{
	my $var = $_[0];
	
	return $var."_app.log";	

}


sub getEventLogName()
{
	return $results_directory . "event_" . $odf_object->getSourceName . "\.log";
}


sub getGTILogName()
{
	return $results_directory."gtievent_".$odf_object->getSourceName."\.log";
}

sub getSpecLogName()
{
	return $results_directory."spectra_".$odf_object->getSourceName."\.log";
}

sub getLCLogName()
{
	return $results_directory."lcurve_".$odf_object->getSourceName."\.log";
}

sub getRGSLCLogName()
{
	return $results_directory."rgs_lcurve_".$odf_object->getSourceName."\.log";
}


sub getRGSLogName()
{
	return $results_directory."rgs_".$odf_object->getSourceName."\.log";
}


sub getOMLogName()
{
	return $results_directory."om_chain_".$odf_object->getSourceName."\.log";
}

sub getEdetectLogName()
{
  return $results_directory."edetect_chain_".$odf_object->getSourceName."\.log";
}

sub getScienceLogName()
{
  return $results_directory."science_".$odf_object->getSourceName."\.log";
}

## @method void logInit()
## Initializes the logging system
sub logInit() {
	
	#.. Initialize logger system

 $initlogConf = q(
    log4perl.logger = INFO, AppWarn, AppError, AppInfo

	 		
        # Filter to match level ERROR
    log4perl.filter.MatchError = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchError.LevelToMatch  = ERROR
    log4perl.filter.MatchError.AcceptOnMatch = true

        # Filter to match level WARN
    log4perl.filter.MatchWarn  = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchWarn.LevelToMatch  = WARN
    log4perl.filter.MatchWarn.AcceptOnMatch = true

        # Filter to match level INFO
    log4perl.filter.MatchInfo  = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchInfo.LevelToMatch  = INFO
    log4perl.filter.MatchInfo.AcceptOnMatch = true

        # Error appender
    log4perl.appender.AppError = Log::Log4perl::Appender::File
    log4perl.appender.AppError.filename = xmmextractor.err
    log4perl.appender.AppError.layout   = SimpleLayout
    log4perl.appender.AppError.Filter   = MatchError

        # Warning appender
    log4perl.appender.AppWarn = Log::Log4perl::Appender::File
    log4perl.appender.AppWarn.filename = xmmextractor.warn
    log4perl.appender.AppWarn.layout   = SimpleLayout
    log4perl.appender.AppWarn.Filter   = MatchWarn

        # Info appender
    log4perl.appender.AppInfo = Log::Log4perl::Appender::File
    log4perl.appender.AppInfo.filename = xmmextractor.info
    log4perl.appender.AppInfo.layout   = SimpleLayout
    log4perl.appender.AppInfo.Filter   = MatchInfo

    
);

Log::Log4perl->init(\$initlogConf);

$logger = get_logger();    

#.. Initialize logger system
	
}

## @method void logInit()
## Initializes the logging system
sub logProductsInit() {
	
	#.. Initialize logger system

 my $conf = q(

  	# Evtent appender
    log4perl.category.Event.Proc          = INFO, EventLogfile
    log4perl.appender.EventLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.EventLogfile.filename = \
    sub { return getEventLogName(); }
    log4perl.appender.EventLogfile.layout   = SimpleLayout

   	# GTIEvt appender: Output GTI filtered event file log information
    log4perl.category.GTIEvt.Proc          = INFO, GTIEvtLogfile
    log4perl.appender.GTIEvtLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.GTIEvtLogfile.filename = \
    sub { return getGTILogName(); }
    log4perl.appender.GTIEvtLogfile.layout   = SimpleLayout
    
    	# Edetect appender: Output edetect chain log information
    log4perl.category.Edetect.Proc          = INFO, EdetectLogfile
    log4perl.appender.EdetectLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.EdetectLogfile.filename = \
    sub { return getEdetectLogName(); }
    log4perl.appender.EdetectLogfile.layout   = SimpleLayout
    
    	# Spectrum appender: Output spectral log information
    log4perl.category.Spectrum.Proc          = INFO, SpectrumLogfile
    log4perl.appender.SpectrumLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.SpectrumLogfile.filename = \
    sub { return getSpecLogName(); }
    log4perl.appender.SpectrumLogfile.layout   = SimpleLayout
    
       	# EPIC lightcurve appender: Output light curve log information
    log4perl.category.EPICLC.Proc          = INFO, EPICLCLogfile
    log4perl.appender.EPICLCLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.EPICLCLogfile.filename = \
    sub { return getLCLogName(); }
    log4perl.appender.EPICLCLogfile.layout   = SimpleLayout
    
       	# RGS lightcurve appender: Output light curve log information
    log4perl.category.RGS.Proc          = INFO, RGSLogfile
    log4perl.appender.RGSLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.RGSLogfile.filename = \
    sub { return getRGSLogName(); }
    log4perl.appender.RGSLogfile.layout   = SimpleLayout
    
      	# RGS lightcurve appender: Output light curve log information
    log4perl.category.RGSLC.Proc          = INFO, RGSLCLogfile
    log4perl.appender.RGSLCLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.RGSLCLogfile.filename = \
    sub { return getRGSLCLogName(); }
    log4perl.appender.RGSLCLogfile.layout   = SimpleLayout
    
      	# OM lightcurve appender
    log4perl.category.OM.Proc          = INFO, OMLogfile
    log4perl.appender.OMLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.OMLogfile.filename = \
    sub { return getOMLogName(); }
    log4perl.appender.OMLogfile.layout   = SimpleLayout

     	# Science log appender
    log4perl.category.Science.Proc     = INFO, ScienceLogfile
    log4perl.appender.ScienceLogfile          = Log::Log4perl::Appender::File
    log4perl.appender.ScienceLogfile.filename = \
    sub { return getScienceLogName(); }
    log4perl.appender.ScienceLogfile.layout   = SimpleLayout
        
);

$conf = $initlogConf.$conf;
Log::Log4perl->init(\$conf);

$eventLog = Log::Log4perl::get_logger("Event::Proc");

$gtiLog = Log::Log4perl::get_logger("GTIEvt::Proc");
$specLog = Log::Log4perl::get_logger("Spectrum::Proc");
$lcLog = Log::Log4perl::get_logger("EPICLC::Proc");
$rgsLCLog = Log::Log4perl::get_logger("RGSLC::Proc");
$rgsLog = Log::Log4perl::get_logger("RGS::Proc");
$omLog = Log::Log4perl::get_logger("OM::Proc");
$edectLog = Log::Log4perl::get_logger("Edetect::Proc");

$scienceLog = Log::Log4perl::get_logger("Science::Proc");

#.. Initialize logger system
	
}

## @method void init()
# Initializes the analysis program: init variables, set output log flags, 
# read analysis options from command line, etc.
# @return Void

#========================================================================
sub init() {   

#... Init logging system
	&logInit();

#... We need to initialize this variable before calling odfParamCreator
 	chomp($Analysis_directory = `pwd`);
 	$Analysis_directory = $Analysis_directory."/";

	
#... Check if we are runnig xmmextractor using an input parameter file.
#... If there isn't any parameter, we firt assume that we have to run  
#... cifbuild + odfingest and then we run odfParamCreator
	my $file = "";
	my $paramFile = "xmmextractor_init_".&getCurrentDate().".xml";
	if (@ARGV)
	{
		$file = &pse_parameters_init(@ARGV);
	}
	else
	{
		&run_cifbuild();
		my @args = ("odfParamCreator","outputFileName=$paramFile");
    	system(@args)== 0 or &error_code(5);
    	$file = $paramFile;
    	$outputfile = "default";
	}
	 
#.. New Variable definition	
    $odf_object = new GVODF();
   	
	&parseXMLConfFile($file); 	  

	
	#.. Init Names Read from Command Line
    $analysis_action    = 0;    

#.. Init Program Parameters
	$analysis_action = $odf_object->getAnalysisOption();	    
	#.. Define the actions to take according to Analysis Option
    %action_to_take = (
		       '0:all' => \&run_all,		       
		       'cifbuild' => \&run_cifbuild,
		       '1:events' => \&produce_eventlist,	       
		       '2:gti' => \&compute_gti,
		       '3:edetectchain' => \&run_edetectchain,
		       '4:epatplot' => \&epatplot,
		       '5:epic_spectra' => \&produce_spectrum,
		       '6:epic_lightcurve' => \&produce_lightcurve,
		       '7:rgs_lightcurve' => \&produceRGSLightcurves,		       		      
		       );    

#.. Define Directory and File names
    &pse_definenames();

#... Creating directory tree
	&startup();


#.. Init Structure for instrument information
    &pse_obsid_structure();
   
#... Init logging system
	&logProductsInit();

#.. Init PG flag
	$PG_flagCall = 0;


    
    return(0);
}


## @method void startup()
# Start analysis
# @return Void

#========================================================================
sub startup(){

	
#.. Set variables

    my $source_obsID = $odf_object->getObsId();
    my $source_name  = $odf_object->getSourceName();
    my $source_ra    = $odf_object->getRA();
    my $source_dec   = $odf_object->getDEC();


	$logger->info("----> Creating Directory Structure<----");                                  
	$logger->info("Analysis directory : $Analysis_directory.");   


#.. Create Analysis Directory
    my $A_STATUS="OK";
    if (!-e $Analysis_directory) {
	mkpath ($Analysis_directory,0,0755) or die "Cannot mkdir $Analysis_directory: $!";
	$A_STATUS="CREATED";
    }
#.. Create Directory Structure
    my $R_STATUS="OK";
    if (!-e $results_directory) {
	mkdir ($results_directory, 0755) or die "Cannot mkdir newdir: $!"; 
	$R_STATUS="CREATED";
    }
    
    my $I_STATUS="OK";
    if (!-e $images_directory) {
	mkdir ($images_directory, 0755) or die "Cannot mkdir newdir: $!";
	$I_STATUS="CREATED";
    }
    
    my $S_STATUS="OK";
    if (!-e $spectra_directory) {
	mkdir ($spectra_directory, 0755) or die "Cannot mkdir newdir: $!";
	$S_STATUS="CREATED";
    }
    
    my $PN_STATUS="OK";
    if ($odf_object->EPN() eq "yes") {
	    if (!-e $pn_directory) {
		mkdir ($pn_directory, 0755) or die "Cannot mkdir newdir: $!";
		$PN_STATUS="CREATED";
    	}
    }
    else 
    {
    	$PN_STATUS="NOT CREATED";
    }
    
    my $MOS_STATUS="OK";
    if (($odf_object->EMOS1() eq "yes") || ($odf_object->EMOS2() eq "yes")) {
    	if (!-e $mos_directory) {
		mkdir ($mos_directory, 0755) or die "Cannot mkdir newdir: $!";
		$MOS_STATUS="CREATED";
    	}
    }
    else 
    {
    	$MOS_STATUS="NOT CREATED";
    }
    
    my $RGS_STATUS="OK";
    if (($odf_object->RGS1() eq "yes") || ($odf_object->RGS2() eq "yes")) {
    	if (!-e $rgs_directory) {
		mkdir ($rgs_directory, 0755) or die "Cannot mkdir newdir: $!";
		$RGS_STATUS="CREATED";
    	}
    }
    else
    {
    	$RGS_STATUS="NOT CREATED";	
    }

    my $OM_STATUS="OK";
    if ($odf_object->OM() eq "yes") {
	    if (!-e $om_directory) {
		mkdir ($om_directory, 0755) or die "Cannot mkdir newdir: $!";
		$OM_STATUS="CREATED";
    	}
    }
    else
    {
    	$OM_STATUS="NOT CREATED";	
    }
    
    my $GTI_STATUS="OK";
    if (!-e $gti_directory) {
	mkdir ($gti_directory, 0755) or die "Cannot mkdir newdir: $!";
	$GTI_STATUS="CREATED";
    }
    
    my $LCU_STATUS="OK";
    if (!-e $lcurve_directory) {
	mkdir ($lcurve_directory, 0755) or die "Cannot mkdir newdir: $!";
	$LCU_STATUS="CREATED";
    }
    
    my $EPATPLOT_STATUS="OK";
    if (!-e $epatplot_directory) {
	mkdir ($epatplot_directory, 0755) or die "Cannot mkdir newdir: $!";
	$EPATPLOT_STATUS="CREATED";
    }
 

	$logger->info( "\n----> Creating Directory Structure");                                  
	$logger->info( "      Analysis directory : $Analysis_directory ... $A_STATUS");   
	$logger->info( "      Results directory : $results_directory   ... $R_STATUS");   
	$logger->info( "      GTI directory     : $gti_directory       ... $GTI_STATUS");  
	$logger->info( "      Images directory  : $images_directory    ... $I_STATUS");  
	$logger->info( "      Light C directory : $lcurve_directory    ... $LCU_STATUS"); 
	$logger->info( "      Spectra directory : $spectra_directory   ... $S_STATUS");  
	$logger->info( "      pn directory      : $pn_directory        ... $PN_STATUS");  
	$logger->info( "      mos directory     : $mos_directory       ... $MOS_STATUS");  	
	$logger->info( "      rgs directory     : $rgs_directory       ... $RGS_STATUS");  	
	$logger->info( "      om directory      : $om_directory        ... $OM_STATUS");  
	$logger->info( "      epatplot directory: $epatplot_directory  ... $EPATPLOT_STATUS");  	


 	
#.. Initial OBSID instrument structure variables
    &pse_print_obsid_instruments();

    return(0);
}

## @method void run()
# Run a single analysis action
# @return Void

#========================================================================
sub run(){
#.. Take action based on the user's choice

    if (defined $action_to_take{$analysis_action}) {
		$action_to_take{$analysis_action}->();
		#.. Before exiting, we will print to the stdout the value of the global variables.	
		chdir ($Analysis_directory);	
		if ($outputfile eq "default")
		{
			$outputfile = &getCurrentDate();	
			$outputfile = "xmmextractor_".$outputfile.".xml";		
		}	
	   	 $doc->toFile($outputfile,0);      		                            
	} else {
		$logger->error("Analysis option not recognized.");
		&error_code(255);
    } 
  
    return(0);
}

## @method void run_all()
# Run the analysis actions
# @return Void

#========================================================================
sub run_all(){
#.. Run all tasks
	
    $logger->info( "\n----> Running all tasks ....");
    $action_to_take{"cifbuild"}->();    
    $action_to_take{"1:events"}->();    
    $action_to_take{"2:gti"}->();
    $action_to_take{"3:edetectchain"}->();
    $action_to_take{"4:epatplot"}->();
    $action_to_take{"5:epic_spectra"}->();
    $action_to_take{"6:epic_lightcurve"}->();
    $action_to_take{"7:rgs_lightcurve"}->();
     
#.. Before exiting, we will print to the stdout the value of the global variables.	
        
	chdir ($Analysis_directory);		
	$doc->toFile($outputfile);
	
    return(0);
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
		     '1' => "   \#> SAS_ODF does not exists",
		     '2' => "   \#> HEADAS not installed",
		     '31' => "   \#> Error: Producing EPN event files",
		     '32' => "   \#> Error: Producing MOS1 event files",
		     '33' => "   \#> Error: Producing MOS2 event files",
		     '3' => "    \#> Error: Producing RGS1 or RGS2 event files",
   		     '34' => "   \#> Error: Producing RGS1 event files",
		     '35' => "   \#> Error: Producing RGS2 event files",
		     '36' => "   \#> Error: Producing OM event files",		        		     
		     '4' => "   \#> Error: Computing GTI",
		     '5' => "   \#> Error: Running edetect_chain",
		     '6' => "   \#> Error: Producing Spectrum",
		     '7' => "   \#> Error: Producing Light Curves",
		     '8' => "	\#> Error: Producing epatplot",
		     '9' => "	\#> Error: Running ecoordconv",
		     '10' => "   \#> Error: Running PG_gti_filter",
		     '101' => "   \#> Error: paramfile not found",
		     '255' => "   \#> Error: Running xmmextractor",
		     );     

   if (defined $error_code{$error_signal}) {
	my $msg = $error_code{$error_signal};
	if ($error_signal == 0)
	{
		$logger->info("$msg");
	}
	else
	{
		$logger->error("$msg");
	}
	if ($error_signal == 101)
	{
		&pse_do_exit($error_signal);		
	}
    } 

    return(0);
}

## @method void pse_usage()
# Print help lines onto the screen
# @return Void

#========================================================================
sub pse_usage(){
#..Print Help message
	print "#>xmmextractor paramfile=myParamFile.xml outputfile=myFile.xml\n";
#    system("listparams xmmextractor");
#    my $x = $? >> 8;
       
    &pse_do_exit(0);

}


#========================================================================

## @method void pse_do_exit($exit_code)
# Exit analysis program
# @param exit_code Exit code to be output on exit
# @return Void

#========================================================================    
sub pse_do_exit(){        	

#.. Define exit code

    my $exit_code = $_[0];

    exit $exit_code;
    return(0);
}

1;

