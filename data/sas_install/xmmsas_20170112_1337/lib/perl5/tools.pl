## @file
# Analysis tools. This module provides a set of general tools that are used by
# the rest of the modules of the analysis package.

use Switch;

#========================================================================
use vars qw($pi $deg2rad $rad2deg);
$pi=3.1415926;
$deg2rad=(2.*$pi)/360.;
$rad2deg=360./(2.*$pi);

## @method float ra($source_name)
# Returns the RA of a given source through a call to NED in units of deg
# @param source_name Source Name
# @return Source RA

#========================================================================
sub ra(){
# Makes a calle to NED
    my $source_name = $_[0];
    
    @out  = split /\s/,`$ned_coord_directory$ned_coord_script $source_name`;
    if ($out[0] eq "Target") {
	$ra = 0.;
    } else {
	$ra = $out[0];
    } 
    return($ra);
}

## @method float dec($source_name)
# Returns the DEC of a given source through a call to NED in units of deg
# @param source_name Source Name
# @return Source RA

#========================================================================
sub dec(){
# Makes a calle to NED
    my $source_name = $_[0];
    
    @out = split /\s/,`$ned_coord_directory$ned_coord_script $source_name`;
    if ($out[0] eq "Target") {
	$dec = 0.;
    } else {
	$dec = $out[1];
    }
    return($dec);
}  

## @method float Angular_separation($ra1, $ra2, $dec1,$dec2)
# Computes the angular separation between two sources in units of deg
# @param ra1 RA of Source 1
# @param ra2 RA of Source 2
# @param dec1 DEC of Source 1
# @param dec2 DEC of Source 2
# @return Source Angular Separation

#========================================================================
sub Angular_separation(){

    my $ra1  = $_[0];
    my $ra2  = $_[1];
    my $dec1 = $_[2];
    my $dec2 = $_[3];

    my $delta_alpha = ($ra2-$ra1);
    my $num = sqrt(
                   (cos($dec2*$deg2rad)*sin($delta_alpha*$deg2rad))**2
                   +(cos($dec1*$deg2rad)*sin($dec2*$deg2rad)
                     -sin($dec1*$deg2rad)*cos($dec2*$deg2rad)*cos($delta_alpha*$deg2rad))**2
                   );
    my $den = sin($dec1*$deg2rad)*sin($dec2*$deg2rad)
        +cos($dec1*$deg2rad)*cos($dec2*$deg2rad)*cos($delta_alpha*$deg2rad);
        
    if ($den != 0.) {
    	$val = $rad2deg*atan2($num,$den);
    	return($val);
    }
    return(1000.);
}



## @method void addsourcetoregionfile($region_file,$x,$y,$R1, $R2, $color, $text, $region_type, $coord_type  )
# Creates a region file that can be read by ds9*
# (http://www.physics.louisville.edu/help/ds9/region.html)
# @param region_file Region File Name
# @param x X-coord of the center of region
# @param y Y-coord of the center of region
# @param R1 radius of inner Circle / X-size of Box
# @param R2 radius of outer Circle(annulus) / Y-size of Box
# @param color Color of region
# @param text Text to be assigned to the region
# @param region_type Region Type (Regions Supported: Circle, Annulus, Box)
# @param coord_type Type of Coordinates (FK5, IMAGE, PHYSICAL, ....)
# @return Void

#========================================================================
sub addsourcetoregionfile(){

    my $region_file = $_[0];
    my $x           = $_[1];
    my $y           = $_[2];
    my $R1          = $_[3];
    my $R2          = $_[4];
    my $color       = $_[5];
    my $text        = $_[6];
    my $region_type = $_[7];
    my $coord_type  = $_[8];
	
    open (REGIONFILE, ">>$region_file") or die "couldn't open file $region_file: $! \n";

    if ($region_type eq "circle") {print REGIONFILE "$coord_type\;circle($x,$y,$R2) \# color=$color text=\"$text\" \n";}
    if ($region_type eq "annulus") {print REGIONFILE "$coord_type\;annulus($x,$y,$R1,$R2) \# color=$color text=\"$text\" \n";}
    if ($region_type eq "box") {print REGIONFILE "$coord_type\;box($x,$y,$R1,$R2) \# color=$color text=\"$text\" \n";}

    close(REGIONFILE);
    return(1);
}

## @method void produce_ps_file($fits_file,$region_file,$title,$ps_file)
# Creates a ps image file from a fits image file (call to ds9)
# @param fits_file Fits File Name
# @param region_file Region File Name
# @param title Title ofImage
# @param ps_file Postscript File Name
# @return Void

#========================================================================
sub produce_ps_file(){

    my $fits_file    = $_[0];
    my $region_file  = $_[1];
    my $title        = $_[2];
    my $ps_file      = $_[3];

    my @args = ("ds9 -cmap invert yes -cmap b -cmap value 1.15 .13 -fits $fits_file -region $region_file -zoom to fit -title $title -print destination file -print filename $ps_file -print palette rgb -print level 1 -print resolution 300 -print -exit");
    system(@args);                   # == 0 or &error_code(5); NOTE: If I put this bit it wont run on the grid    
    return(1);

#Another command to produce images
#implot set=pn_img_gtifiltered_smooth.img colourmap=4 device=/PS srclisttab=../images/pn_emllist.fits.gz expression='(ID_BAND==0)' -i ccf.cif gridstyle='grid' withsrclisttab=y srccolour=4 radiusstyle='user' userradius=200.

}


sub deg2hour()
{
	$deg = $_[0];
	
	$hour = $deg*0.0666667;
	$HH = int($hour);
	
	$rest = ($hour - int($hour)) * 60.;
	$MM = int($rest);
	$SS = ($rest - $MM)*60.;
	 
	return("$HH:$MM:$SS");

}

sub deg2sexa()
{
	$degrees = $_[0];
	$neg = 0;
	if ($degrees < 0) {
		$neg = 1;
		$degrees = -$degrees;
	}
	$deg = int($degrees);
	
	$min = int(($degrees - $deg)*60.);
	$sec = (($degrees - $deg)*60. - $min)*60.;
	if ($neg == 1) { $deg = -$deg; }
	
	return("$deg:$min:$sec");
	
}
## @sub event_file_spectralinf($event_file, $instr)
# Extract information from an spectral event file
# @param event_file Event File Name
# @param instr Instrument
# @return Live Time, Background Scale Factor, Area Scale factor

#========================================================================
sub event_file_spectralinf(){

    my $event_file = $_[0];
    my $instr      = $_[1];

#.. Print information from fits spectral file
#.. NOTE: In this type of file EXPOSURE=Weighted live time of CCDs in extraction region

    chomp(my $live_time      = `fkeyprint infile=$event_file+1 keynam=EXPOSURE outfil=STDOUT exact=yes | grep EXPOSURE | tail -1 | cut -c11-30`);
    $live_time =~ s/\s+//;
    $live_time =~ s/\'+//;
    if ($live_time eq "EXPOSURE" || $live_time eq "" || $live_time == 0) {$live_time ="unknown";}

    $backsale = &getbackscale($event_file,1);
    $areascal = &getareascale($event_file,1);

    $logger->info( "   \#> Information from Spectra File: $event_file");
    $logger->info( "       $instr Live Time : $live_time (Weighted live time of CCDs in extraction region) ");   
    $logger->info( "       $instr Backscale : $backsale   ");    
    $logger->info( "       $instr Areascale : $areascal   ");      

    return($live_time,$backsale,$areascal);
}

## @sub event_file_inf($event_file, $instr)
# Extract information from an event file
# @param event_file Event File Name
# @param instr Instrument
# @return Mode, Filter, Submode, UTC Date, Duration, ON Time,Live Time, Obs Start, Obs End

#========================================================================
sub event_file_inf(){
#.. Print fits file information

    my $event_file = $_[0];
    my $instr      = $_[1];
    my $currentLog = $_[2];
    
    $ext = 1;
    if ($instr eq "om"){$ext = 0;}

    chomp(my $rows   = `fstruct $event_file+$ext colinfo=no | grep BINTABLE | awk \'\{print \$6\}\'`);
    $rows     =~ s/\s+//;
    $rows     =~ s/\'+//;
    if ($rows eq "") {$rows ="unknown";}

    chomp(my $tstart   = `fdump $event_file+$ext outfile=STDOUT columns=TIME ROWS=1 prhead=no showcol=no prdata=yes showunit=no showrow=no showscale=no`);
    $tstart     =~ s/\s+//;
    $tstart     =~ s/\'+//;
    if ($tstart eq "") {$tstart ="unknown";}

    chomp(my $tend   = `fdump $event_file+$ext outfile=STDOUT columns=TIME ROWS=$rows prhead=no showcol=no prdata=yes showunit=no showrow=no showscale=no`);
    $tend     =~ s/\s+//;
    $tend     =~ s/\'+//;
    if ($tend eq "") {$tend ="unknown";}

    $dmode        = &getdatamode($event_file,$ext);
    $mode         = &getsubmode($event_file,$ext);
    $filter       = &pse_getfilter($event_file,$ext);
    $utc_obsdate  = &getdate_obs($event_file,$ext);
    $obs_duration = &getduration($event_file,$ext);
    $ontime       = &getontime($event_file,$ext);
    $livetime     = &getlivetime($event_file,$ext);
    $exposure     = &getexposure($event_file,$ext);
 
    $currentLog->info( "   \#> Information from Event File: $event_file ");
    $currentLog->info( "       $instr OBS DATE          : $utc_obsdate  ");
    $currentLog->info( "       $instr OBS STARTING TIME : $tstart (1st Event)");
    $currentLog->info( "       $instr OBS ENDING TIME   : $tend (Last Event)");
    $currentLog->info( "       $instr EXPOSURE ID  : $exposure ");
    $currentLog->info( "       $instr OBS DURATION : $obs_duration   ");
    $currentLog->info( "       $instr OBS ONTIME   : $ontime   ");
    $currentLog->info( "       $instr OBS LIVETIME : $livetime  ");
    $currentLog->info( "       $instr D MODE       : $dmode  ");
    $currentLog->info( "       $instr SUBMODE      : $mode   ");
    $currentLog->info( "       $instr FILTER       : $filter ");	  
 

    &pse_fill_structure($odf_object->getObsId,$instr,'date',$utc_obsdate);
    &pse_fill_structure($odf_object->getObsId,$instr,'starting_time',$tstart);
    &pse_fill_structure($odf_object->getObsId,$instr,'ending_time',$tend);
    &pse_fill_structure($odf_object->getObsId,$instr,'duration',$obs_duration);
    &pse_fill_structure($odf_object->getObsId,$instr,'ontime',$ontime);
    &pse_fill_structure($odf_object->getObsId,$instr,'livetime',$livetime);
    &pse_fill_structure($odf_object->getObsId,$instr,'mode',$dmode);
    &pse_fill_structure($odf_object->getObsId,$instr,'submode',$mode);
    &pse_fill_structure($odf_object->getObsId,$instr,'filter',$filter);
    &pse_fill_structure($odf_object->getObsId,$instr,'exposure',$exposure);
 
    return($mode,$filter,$dmode,$utc_obsdate,$obs_duration,$ontime,$livetime,$tstart,$tend);
}

## @sub setcoordinates($event_file)
# Check if we have to set the coordinates
# @return 

#========================================================================
sub setcoordinates(){
	#.. Test for odfingest file and set ENV variable     
    @test_odfingest=&test_odfingest();
    my $odfingestfile=$test_odfingest[1];
    if (!$test_odfingest[0]) {	
		&run_odfingest();
    }
   
    if (!$test_odfingest[0]) {$logger->error("      Run odfingest first "); &error_code(255);}
    &set_odfingest($odfingestfile);
    
	
	if (($odf_object->getRA != -999) && ($odf_object->getDEC != -999))
		{
			$logger->info( "   \#> Using user defined coordinates");
			
			$ra = $odf_object->getRA;
			$dec = $odf_object->getDEC;
			
			$logger->info( "   \#> RA_OBJ = $ra");			
			$logger->info( "   \#> DE_OBJ = $dec");
		
		}
	elsif (($odf_object->getRA == -999) && ($odf_object->getDEC == -999))
		{
			$logger->info("   \#> Not user defined coordinates found. Using the SUM.SAS RA_OBJ and DE_OBJ coordinates.");

			my $ra = &getobsra($odfingestfile);
			my $dec =	&getobsdec($odfingestfile);
			$odf_object->setRA($ra);
			$odf_object->setDEC($dec);

			$logger->info( "   \#> RA_OBJ = $ra");
			$logger->info( "   \#> DE_OBJ = $dec");
			
		} 
	else
		{
			$logger->info( "   \#> One of the source coordinates is not set. Please, check your input parameters");

			&error_code(102) && return;
		}
	
	return(1);
}

## @sub getobsra($event_file)
# Get Observation RA
# @param event_file Event File Name
# @return Observation RA

#========================================================================
sub getobsra(){
    my $event_file = $_[0]; 
    
    chomp(my $obj_ra   = `grep "Target Right Ascension" $event_file  | awk '{print \$1} '`);
    $obj_ra     =~ s/\s+//;    
    $obj_ra = ($obj_ra*15.);
    return($obj_ra);
}

## @sub getobsdec($event_file)
# Get Observation DEC
# @param event_file Event File Name
# @return Observation DEC

#========================================================================
sub getobsdec(){
    my $event_file = $_[0]; 
    
    chomp(my $obj_dec   = `grep "Target Declination" $event_file  | awk '{print \$1} '`);
    $obj_dec     =~ s/\s+//;    
    
    return($obj_dec);
}

## @sub getdatamode($event_file,$ext)
# Get Exposure Mode
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Exposure Mode

#========================================================================
sub getdatamode(){
    my $event_file = $_[0]; 
    my $ext        = $_[1]; 
    chomp(my $dmode   = `fkeyprint infile=$event_file+$ext keynam=DATAMODE outfil=STDOUT exact=yes | grep DATAMODE | tail -1 | cut -c12-20`);
    $dmode     =~ s/\s+//;
    $dmode     =~ s/\'+//;
    if ($dmode eq "DATAMODE" || $dmode eq "") {$dmode ="unknown";}
    return($dmode);
}

## @sub getsubmode($event_file,$ext)
# Get Exposure Submode
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Exposure Submode

#========================================================================
sub getsubmode(){
    my $event_file = $_[0]; 
    my $ext        = $_[1]; 
    chomp(my $mode   = `fkeyprint infile=$event_file+$ext keynam=SUBMODE outfil=STDOUT exact=yes | grep SUBMODE | tail -1 | cut -c12-28`);
 	$mode =~ s/^\s+//;
	$mode =~ s/\s+$//;
    $mode =~ s/^\'+//;
    $mode =~ s/\'+$//;
    if ($mode eq "SUBMODE" || $mode eq "") {$mode ="unknown";}
    
    return($mode);
}

## @sub pse_getfilter($event_file,$ext)
# Get Exposure Filter
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Exposure Filter

#========================================================================
sub pse_getfilter(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];  
    chomp(my $filter = `fkeyprint infile=$event_file+$ext keynam=FILTER outfil=STDOUT exact=yes | grep FILTER | tail -1 | cut -c12-25`);
    $filter    =~ s/\s+\'+//;
    $filter    =~ s/\'+//;
    if ($filter eq "FILTER" || $filter eq "" || $filter eq "UNKNOWN") {$filter ="unknown";}
    return($filter);
}

## @sub getdate_obs($event_file,$ext)
# Get Observation Date
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Observation Date

#========================================================================
sub getdate_obs(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];  
    chomp($utc_obsdate   = `fkeyprint infile=$event_file+$ext keynam=DATE_OBS outfil=STDOUT exact=yes | grep DATE_OBS | tail -1 | cut -c12-34`);
    if ($utc_obsdate eq "" || $utc_obsdate eq "DATE_OBS") 
    {chomp($utc_obsdate     = `fkeyprint infile=$event_file+$ext keynam=DATE-OBS outfil=STDOUT exact=yes | grep DATE-OBS | tail -1 | cut -c12-34`);}
    $utc_obsdate  =~ s/\s+//;
    $utc_obsdate  =~ s/(\'\/)//;
    if ($utc_obsdate eq "DATE-OBS" || $utc_obsdate eq ""){$utc_obsdate="unknown";}
    return($utc_obsdate);
}

## @sub getduration($event_file,$ext)
# Get Observation Duration Time in seconds
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Observation Duration Time in seconds

#========================================================================
sub getduration(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];   
    chomp(my $obs_duration  = `fkeyprint infile=$event_file+$ext keynam=DURATION outfil=STDOUT exact=yes | grep DURATION | tail -1 | cut -c11-30`);
    $obs_duration =~ s/\s+//;
    if ($obs_duration eq "" || $obs_duration eq "DURATION") 
    {chomp($obs_duration  = `fkeyprint infile=$event_file+$ext keynam=TELAPSE outfil=STDOUT exact=yes | grep TELAPSE | tail -1 | cut -c11-30`);}
    $obs_duration =~ s/\s+//;
    if ($obs_duration eq "TELAPSE" || $obs_duration eq "" || $obs_duration == 0){$obs_duration="unknown";}
    return($obs_duration);
}

## @sub getontime($event_file,$ext)
# Get Observation ON Time in seconds
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Observation ON Time in seconds

#========================================================================
sub getontime(){
    my $event_file = $_[0]; 
    my $ext        = $_[1]; 
    chomp(my $ontime        = `fkeyprint infile=$event_file+$ext keynam=ONTIME outfil=STDOUT exact=yes | grep ONTIME | tail -1 | cut -c11-30`);
    $ontime    =~ s/\s+//;
    if ($ontime eq "ONTIME" || $ontime eq "" || $ontime == 0){$ontime="unknown";}
    return($ontime);
}

## @sub getlivetime($event_file,$ext)
# Get Observation Live Time in seconds
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Observation Live Time in seconds

#========================================================================
sub getlivetime(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];     
    chomp(my $livetime      = `fkeyprint infile=$event_file+$ext keynam=LIVETIME outfil=STDOUT exact=yes | grep LIVETIME | tail -1 | cut -c11-30`);
    $livetime  =~ s/\s+//;
    if ($livetime eq "LIVETIME" || $livetime eq "" || $livetime == 0){$livetime="unknown";}
    return($livetime);
}

## @sub getexposure($event_file,$ext)
# Get Observation Exposure in seconds
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Observation Exposure in seconds

#========================================================================
sub getexposure(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];
    chomp(my $exposure      = `fkeyprint infile=$event_file+$ext keynam=EXPIDSTR outfil=STDOUT exact=yes | grep EXPIDSTR | tail -1 | cut -c12-17`);
    $exposure =~ s/\s+//;
    if ($exposure eq "EXPIDSTR" || $exposure eq "EXPIDS" || $exposure eq ""){$exposure="unknown";}
    return($exposure);
} 

## @sub getinstrume($event_file,$ext)
# Get instrument
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Instrument name

#========================================================================
sub getinstrume(){
    my $event_file = $_[0]; 
    my $ext        = $_[1];
    chomp(my $inst      = `fkeyprint infile=$event_file+$ext keynam=INSTRUME outfil=STDOUT exact=yes | grep INSTRUME | tail -1 | cut -c12-17`);
    $inst =~ s/\s+//;
    if ($inst ne "EPN" && $inst ne "EMOS1" && $inst ne "EMOS2"){&error_code(255);}
    return($inst);
} 

## @sub getnumberofentries($event_file,$ext)
# Get Number of Entries on an Event File
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Number of Entries

#========================================================================
sub getnumberofentries(){  
    my $event_file = $_[0];
    my $ext        = $_[1];
    chomp(my $entries = `fkeyprint infile=$event_file+$ext keynam=NAXIS2 outfil=STDOUT exact=yes | grep NAXIS2 | tail -1 | cut -c12-30`);
    $entries =~ s/\s+//;
    if ($entries eq "") {$entries =-1.;}
    return($entries);	
}

## @sub getbackscale($event_file,$ext)
# Get background scaling factor
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Backscale

#========================================================================
sub getbackscale(){  
    my $event_file = $_[0];
    my $ext        = $_[1];
    chomp(my $backsale       = `fkeyprint infile=$event_file+$ext keynam=BACKSCAL outfil=STDOUT exact=yes | grep BACKSCAL | tail -1 | cut -c11-30`);
    $backsale =~ s/\s+//;
    $backsale =~ s/\'+//;
    if ($backsale eq "BACKSCAL" || $backsale eq "" || $backsale == 0) {$backsale ="unknown";}
    return($backsale);	
}

## @sub getareascale($event_file,$ext)
# Get area scaling factor
# @param event_file Event File Name
# @param ext Extension of FITS file
# @return Areascale

#========================================================================
sub getareascale(){  
    my $event_file = $_[0];
    my $ext        = $_[1];    
    chomp(my $areascal       = `fkeyprint infile=$event_file+$ext keynam=AREASCAL outfil=STDOUT exact=yes | grep AREASCAL | tail -1 | cut -c11-30`);
    $areascal =~ s/\s+//;
    $areascal =~ s/\'+//;    
    if ($areascal eq "AREASCAL" || $areascal eq "" || $areascal == 0) {$areascal ="unknown";}
    return($areascal);	
}


## @sub gti_file_inf($event_file, $instr)
# Extract information from an GTI file
# @param event_file GTI File Name
# @param instr Instrument
# @return Sum of GTI

#========================================================================
sub gti_file_inf(){

    my $event_file = $_[0];
    my $instr      = $_[1];

    chomp(my $gti_time =`fkeyprint infile=$event_file+1 keynam=ONTIME outfil=STDOUT exact=yes | grep ONTIME | tail -1 | cut -c10-30`);
    $gti_time  =~ s/\s+//;    
    $gtiLog->info( "   \#> Information from GTI File: $event_file ");
    $gtiLog->info( "      $instr Sum of all Good Time Intervals  : $gti_time  ");

    return($gti_time);	
}

## @method void produce_image($event_file,$image_file,$instr)
# Produce EPIC Images
# @param event_file Name of Event File
# @param image_file Name of Image File
# @param instr Instrument
# @return Void

#========================================================================
sub produce_image(){ 

    my $event_file = $_[0];
    my $image_file = $_[1];
    my $instr      = $_[2];

    $logger->info( "   \#> Producing image from $event_file .... ");
        
    if ($instr eq "pn") {$expr="\#XMMEA_EP";}
    if ($instr eq "m1"){$expr="\#XMMEA_EM";}
    if ($instr eq "m2"){$expr="\#XMMEA_EM";}

    my $mode = $obsid_instruments{$odf_object->getObsId}{$instr}{"mode"};
    if ($mode eq "IMAGING" || $mode eq "imaging") { 
	$xbin = 80; 
	$ybin = 80;
	$xval = "X"; 
	$yval = "Y"; 
    } elsif (($mode eq "TIMING" || $mode eq "timing")
	     && ($instr eq "pn")) {
	$xbin = 1; 
	$ybin = 1; 
	$xval = "RAWX"; 
	$yval = "RAWY"; 
    } elsif (($mode eq "TIMING" || $mode eq "timing")
	&& ($instr eq "m1" || $instr eq "m2")) {
	$xbin = 1; 
	$ybin = 1; 
	$xval = "RAWX"; 
	$yval = "TIME"; 
    } else {
	$logger->error("ERROR producing image:  $image_file");
	
	return(0);
    }

    @args = ("evselect table=\"$event_file\" expression=\"$expr\" withimageset=yes imageset=\"$image_file\" imagebinning=binSize ximagebinsize=$xbin yimagebinsize=$ybin xcolumn=\"$xval\" ycolumn=\"$yval\"");
    system(@args) == 0 or &error_code(6);

    $logger->info("Image: Done");
 
    return(1);
}

## @method void produce_smooth_image($event_file,$image_file,$smoothimage_file,$instr)
# Produce EPIC Images
# @param event_file Name of Event File
# @param image_file Name of Image File
# @param smoothimage_file Name of Smooth Image File
# @param instr Instrument
# @return Void

#========================================================================
sub produce_smooth_image(){   

    my $event_file       = $_[0];
    my $image_file       = $_[1];
    my $smoothimage_file = $_[2];
    my $instr            = $_[3];

    $logger->info("   \#> Producing smooth image from $event_file  .... ");

    if ($instr eq "pn") {$expr="\#XMMEA_EP";}
    if ($instr eq "m1"){$expr="\#XMMEA_EM";}
    if ($instr eq "m2"){$expr="\#XMMEA_EM";}

    my $mode = $obsid_instruments{$odf_object->getObsId}{$instr}{"mode"};
    if ($mode eq "IMAGING" || $mode eq "imaging") { 
	$xbin = 80; 
	$ybin = 80;
	$xval = "X"; 
	$yval = "Y"; 
    } elsif (($mode eq "TIMING" || $mode eq "timing")
	     && ($instr eq "pn")) {
	$xbin = 1; 
	$ybin = 1; 
	$xval = "RAWX"; 
	$yval = "RAWY"; 
    } elsif (($mode eq "TIMING" || $mode eq "timing")
	&& ($instr eq "m1" || $instr eq "m2")) {
	$xbin = 1; 
	$ybin = 1; 
	$xval = "RAWX"; 
	$yval = "TIME"; 
    } else {
	$logger->error("ERROR producing smooth image");
	
	return(0);
    }

    @args = ("evselect table=\"$event_file\" expression=\"$expr\" withimageset=yes imageset=\"$image_file\" imagebinning=binSize ximagebinsize=$xbin yimagebinsize=$ybin xcolumn=\"$xval\" ycolumn=\"$yval\"");   	
    system(@args) == 0 or &error_code(6);  
       
    @args = ("(asmooth inset=$image_file outset=$smoothimage_file smoothstyle=simple convolverstyle=gaussian width=2.5) >& /dev/null");
    system(@args) == 0 or &error_code(6);

    $logger->info("Smooth image created. OK"); 
    
    return(1);
}

## @method void print_sas_setup()
# Prints SAS Setup parameters
# @return Void

#========================================================================
sub print_sas_setup(){
#.. Print out of SAS set-up
    
    my $sas_info = `printenv | grep SAS | grep -v CLASSPATH`;
    #@args = ("printenv | grep SAS | grep -v CLASSPATH");
    #system(@args) == 0 or &error_code(3);

	$logger->info("   \#> This is the current SAS set-up:");
	$logger->info("\n$sas_info");
	
    return(1);
}   

## @method string check_sourceName($file)
# Replace any "+" character in the $fileName by "_"
# return: valid file name

#=====================================================================
sub check_sourceName()
{
	my $validName = $_[0];
	#... Replacing "+" character by "_"
	$validName =~ s/\+/\_/;
	#... Replacing " " character by "_"
	$validName =~ s/\ /\_/;
	
	return ($validName);
	
}


## @method object reference getExpoInfo($inst,$expo,$mode)
sub getExpoInfo()
{
	$inst = $_[0];
	$expo = $_[1];
	$mode = $_[2];

	for (my $count=0;$count<=$#exposures;$count++)
	{
   		my $expoObj = $exposures[$count];    
   		if ( ($expoObj->getInstName() eq $inst) && ($expoObj->getExpId eq $expo) 
   			&&  ($expoObj->getMode()) )
   		{
   			return $expoObj;		
   		}
   			
   		
	}
	
}

## @method bool checkRGSExpoInfo
# Check if both RGS has to be processed and also check 
# parameters for rgsproc
sub checkRGSExpoInfo()
{
	my $val = "yes";
	my $r1Flag = "yes";
	my $r2Flag = "yes";
	my $instexpids = "";
	for (my $count=0;$count<=$#exposures;$count++)
	{
		my $expoObj = $exposures[$count];
		if(($expoObj->getInstName() eq "RGS1"))
		{			
			if(lc($expoObj->getProcess) eq "yes")
			{
				$instexpids = $instexpids."R1".$expoObj->getExpId()." ";
			}
			else {
				$r1Flag = "no";
			}			
		}
		if($expoObj->getInstName() eq "RGS2")
		{
			if(lc($expoObj->getProcess()) eq "yes")
			{
				$instexpids = $instexpids."R2".$expoObj->getExpId()." ";
			} 
			else {
				$r2Flag = "no";
			}			
		}
	}
	
	if ( ($r1Flag eq "no") || ($r2Flag eq "no"))
	{
		$logger->info("Some of the RGS exposures not selected for processing...");
		return 	$instexpids;

	}
	else
	{
		$logger->info( "Processing all exposres of RGS1 and RGS2...");
		$logger->info( "Taking rgsproc parameters from RGS1 first exposure");
		return "";
	}
	
}

## @method object reference getRGSExpoInfo
sub getRGSExpoInfo()
{
	
	for (my $count=0;$count<=$#exposures;$count++)
	{
		my $expoObj = $exposures[$count];

		if( ( ($expoObj->getInstName() eq "RGS1") || ($expoObj->getInstName() eq "RGS2") )  && (lc($expoObj->getProcess()) eq "yes"))
		{
			return $expoObj;
		}
	}
}


sub getRGSExposures()
{
	$expo = $_[0];

	
	@expos = ();
	for (my $count=0;$count<=$#exposures;$count++)
	{
		my $expoObj = $exposures[$count];
		if( ( ($expoObj->getInstName() eq $expo) || ($expoObj->getInstName() eq $expo) )  && (lc($expoObj->getProcess()) eq "yes"))
		{			
			push(@expos,$expoObj);
		}
	}
	
	return @expos;	
}

## @method object reference getRGSExpoInfo
sub getOMScienceModes()
{
	my @omScienceModes = (0,0,0);
	
	for (my $count=0;$count<=$#exposures;$count++)
	{
		my $expoObj = $exposures[$count];

		if( ($expoObj->getInstName() eq "OM")  && 
			(lc($expoObj->getProcess()) eq "yes"))
		{
			my $dat = $expoObj->getExpId();
			my $products = $expoObj->getProducts();
			
			for ($j=0;$j<=$#{$products};$j++)
   			{
   				$product = @{$products}[$j];
	   			##$product->print();

	   			$tasks = $product->getTasks();
   				for ($jj=0;$jj<=$#{$tasks};$jj++)
   				{
	   				$task = @{$tasks}[$jj];
	   				
	   				$currentTask = $task->getTask();
	   				##$task->print();	   	
	   							
	   				switch ($currentTask)
	   				{
	   					case "omichain" { $omScienceModes[0] = 1;}
	   					case "omfchain" { $omScienceModes[1] = 1;}
	   					case "omgchain" { $omScienceModes[2] = 1;}
	   					else {$omLog->error("Unknown data mode");}
	   				}
  				}	   
   			}		
		}
	}
	return @omScienceModes;
}

## @method date getCurrentDate
# Build the current date and return it as a string
sub getCurrentDate()
{

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                          localtime(time);
$year += 1900;

if (length($mon) == 1)
{
    $mon = "0".$mon;
}
$currentDate = $year.$mon.$mday.$hour.$min.$sec;

return $currentDate;
	
}

1;

