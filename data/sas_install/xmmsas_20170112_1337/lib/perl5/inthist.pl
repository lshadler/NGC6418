#! /usr/bin/perl -w
# 
# Usage :
#
#   inthist -sets="List of input images in the default imaging bands"
#           -exposuresets="List of the exposure maps for the corresponding 
#                          images in sets"
#           -tmpflatsets="List of the temporary flatfielded images"
#           -binsiz="Size of the rebinned pixels in degrees for histogramming"
#           -histo="Name of the output Post Script file containing plots 
#                   of the histograms" 
#
#   Read input command line options: 
#        sets=$img[] exposuresets=$expm[] tmpflatsets=$flatimg[]
#        binsize=$binpixsize outfile=$histofile 
#         
#
#
# ------------------------------------------------------
# Define variables   
# ------------------------------------------------------ 

use SAS;
use strict;

sub inthist{
    
    my ($b,$band,$binpixsize,$expmContent  );
    my ($fits,$hdu,$histofile,$i,$imgContent,$j,$key,$opts);
    my ($nbands,$nhdus,$str_flat);
    my ($msg,$idmess);
    my ($nimgs,$nexps,$nflats);
    my($stat,$status);
    my ($at,$ds,$tb,$has);
    my ($imgList,$expmList);

    my @expm=();
    my @flatimg=();
    my @img=();

# ------------------------------------------------------ 
# Read input  parameters
# ------------------------------------------------------ 

    $nimgs=parameterCount("sets");
    $msg="Reading $nimgs EPIC images...\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);
    for($i=0;$i<$nimgs;$i++){
	$img[$i]=stringParameter("sets",$i);
    }
    $nexps=parameterCount("exposuresets");
    $msg="Reading $nexps EPIC exposure maps...\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);
    for($i=0;$i<$nexps;$i++){
	$expm[$i]=stringParameter("exposuresets",$i);
    }
    $nbands=$nimgs;

    $msg="Working with $nbands energy bands\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);

    $nflats=parameterCount("tmpflatsets");
    $msg="Reading $nflats temporary flatfield file(s)...\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);

    if($nflats > 0){
	for($i=0;$i<$nflats;$i++){
	    $flatimg[$i]=stringParameter("tmpflatsets",$i);
	}
    }
    
    $binpixsize=realParameter("binsize");
    $histofile=stringParameter("outfile");
    
    
# ------------------------------------------------------ 
#     Read parameters in parametercs Lists
# ------------------------------------------------------ 

    if($nimgs != $nexps){
      SAS::error("IncNumImg","N. of images= $nimgs different from N. of Exposure maps=$nexps\n");
    }
    
    if($nflats >0){
      if($nimgs != $nflats){
	SAS::error("IncNumImg","N. of images=$nimgs different from N. of files for Flat images=$nflats\n");
      }
      $str_flat="'";
      for($j=0;$j<$nflats;$j++){
	if($j==0){
	  $str_flat = $str_flat . $flatimg[$j];
	}else{
	  $str_flat = $str_flat . " " . $flatimg[$j];
	}
      }
      $str_flat .= "'";
    }else{ 
      $str_flat="'";
      for($j=0;$j<$nbands;$j++){
	$flatimg[$j]="flat_".$j.".img";
	if($j==0){
	  $str_flat = $str_flat . $flatimg[$j];
	}else{
	  $str_flat = $str_flat . " " . $flatimg[$j];
	}
      }
      $str_flat .= "'";
    }
    
# ------------------------------------------------------ 
#     Check : input FITS files are IMAGE Products: images/exposure maps
# ------------------------------------------------------ 

    for ($b=0;$b<$nbands;$b++){
      $key=" ";
      if(system("fstruct $img[$b] >/dev/null")){
	SAS::error("ErrFstruct","Cannot run fstruct for \"$img[$b]\"\n");
      }
      $nhdus=`pget fstruct totalhdu`;
      for ($hdu=0;$hdu<$nhdus;$hdu++){
	$imgContent=$img[$b]."+".$hdu;
        if(system("fkeypar fitsfile=$imgContent keyw='CONTENT'")){
	  SAS::error("ErrFkeypar","Cannot run fkeypar to read CONTENT from \"$img[$b]\"\n");
	}
	$key=`pget fkeypar value`;
	chomp($key);
	($key =~ /EPIC\s*IMAGE/) && last;
      }
      unless($key =~ /EPIC\s*IMAGE/){
	SAS::warning("NotImage","Input image: $img[$b] is not an EPIC IMAGE file\n");
      }
      
      $key=" ";
      if(system("fstruct $expm[$b] >/dev/null")){
	SAS::error("ErrFstruct","Cannot run fstruct for \"$expm[$b]\"\n");
      }
      $nhdus=`pget fstruct totalhdu`;

      for ($hdu=0;$hdu<$nhdus;$hdu++){
	$expmContent=$expm[$b]."+".$hdu;
	if(system("fkeypar fitsfile=$expmContent keyw='CONTENT'")){
	  SAS::error("ErrFkeypar","Cannot run fkeypar to read CONTENT from \"$expmContent\n");
	}
	$key=`pget fkeypar value`;
	chomp($key);
	($key =~ /EPIC\s*EXPOSURE\s*MAP\s*/) && last;
      }
      unless($key =~ /EPIC\s*EXPOSURE\s*MAP/){
	SAS::warning("NotExpMap","Input Map:$expm[$b],is not an EPIC EXPOSURE MAP\n");
      }
    }


#
# ------------------------------------------------------ 
#  1) Flatfield the IMAGES with the EXPOS MAP: ARITHMETIC
#       Input:  IMG_file_in_band
#               EXPOS_MAP_file_in_band
# 
#       Output: FLAT_IMG_file_in_band
# ------------------------------------------------------ 
#

    $msg="Flatfielding input images with their respective exposure maps...\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);

    for ($b=0;$b<$nbands;$b++){
	$band=$b+1;
	SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);
	if(system("farith infil1=$img[$b] infil2=$expm[$b] outfil=$flatimg[$b] ops=DIV datatype='-' blank=-1 null=no copyprime=yes clobber=yes")){
	  (-e $flatimg[$b]) && unlink($flatimg[$b]);
	  SAS::error("ErrFarith","Cannot divide:$img[$b] and $expm[$b]\n");
	}
    }
    
#
# ------------------------------------------------------ 
#  2) Run Intmakehist to obtain the histograms
#       Input:  FLAT_IMG_files
# 
#       Output: HISTOGRAMS_file
# ------------------------------------------------------ 
#
    $msg="Entering routine intmakehist to create intensity histograms...\n";
    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,$msg);


    if(system("intmakehist sets=$str_flat binsize=$binpixsize plotfile=$histofile")){   
	for ($b=0;$b<$nbands;$b++) {
	    (-e $flatimg[$b]) && unlink($flatimg[$b]);
	}
      SAS::error("ErrIntmakehist","Error running INTMAKEHIST\n");
    }
    for ($b=0;$b<$nbands;$b++) {
	(-e $flatimg[$b]) && unlink($flatimg[$b]);
    }

}

