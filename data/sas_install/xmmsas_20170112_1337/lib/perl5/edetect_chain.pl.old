#! /usr/bin/perl -w
#
# edetect_chain
#
# Simultaneous epic source detection run on multiple
# images
#
# Author: Georg Lamer (glamer@aip.de)
#
# Description:
#
# This SAS task runs the tasks of the XMM SAS source detection
# tasks simultaneously on the images specified by the user. Images from different energy bands as well as from different EPIC
# instruments can be combined arbitrarily.
#
# Mandatory Parameters:
#
#

    use SAS;
#    use DAL;
    use strict;

sub edetect_chain{


    my ($ds,$i,$nima,$nband,$nband2,@amplo,@amphi,@image);
    my (@evlist,@instr,$p);
    my (@iminstr,@evinstr,@m1list,@m2list,@pnlist,$m1ev,$m2ev,$pnev);
    my ($nm1,$nm2,$npn,$nevli);
    my (@pnlow,@pnhi,@m1low,@m1hi,@m2low,@m2hi);
    my ($pnexp, $m1exp, $m2exp);
    my ($pnexp2, $m1exp2, $m2exp2);
    my ($pnmask, $m1mask, $m2mask);
    my ($pnpimin, $pnpimax, $m1pimin, $m1pimax, $m2pimin, $m2pimax);
    my ($tmp, $firstexp);
    my (@pnecf,@m1ecf,@m2ecf,@in_ecf);
    my ($necf,$pnecfstr,$m1ecfstr,$m2ecfstr);

    my ($idband,$imageset, $expimageset, $bkgimageset, $sourcemap, $sensimageset, $expimageset2, $cheeseset);

    ## internal limits of eboxdetect and emldetect                  (IT 2016/04)
    my $maxbands = 6;
    my $maxima = 240;

    # test for existence of SAS_CCF                                 (IT 2016/04)
    if (! defined $ENV{'SAS_CCF'}) {
	SAS::error("CIFMissing", 
		   "Environment variable \'SAS_CCF\' is not set.")
    }

#get task parameters:
# general parameters:
    $nima=parameterCount("imagesets");
    $nband=parameterCount("pimin");
    $nband2=parameterCount("pimax");
    $necf=parameterCount("ecf");
    if ($nband != $nband2 || $nima != $nband){
	## re-activated - IT 2016/04
        SAS::error("ParameterError","imagesets, pimin, pimax must have same number of values.");
    }
    # total number of images in eboxdetect and emldetect (shouldn't be a
    # problem at all)                                             --- IT 2016/04
    if ($nima > $maxima) {
	SAS::error("TooManyImages", "eboxdetect and emldetect accept up to 240 input images.");
    }

    if ($necf != $nima){ 
#        SAS::warning("ParameterMismatch","Number of ecf values not equal to number of images");
    }
    for ($i = 0; $i < $nima; $i++) {
        $amplo[$i] = intParameter("pimin",$i);
        if  ($amplo[$i] < 100) {
            $amplo[$i] = 100;

        }
        $amphi[$i] = intParameter("pimax",$i);
        $image[$i] = stringParameter("imagesets",$i);
        # initialise @in_ecf to 1.0
        $in_ecf[$i] = 1.0;
    }
    for ($i = 0; $i < $necf; $i++) {
        $in_ecf[$i] = realParameter("ecf",$i);
    }

    $nevli=parameterCount("eventsets"); if ($nevli <= 3) { for ($i =
    0; $i < $nevli; $i++) { $evlist[$i] =
    stringParameter("eventsets",$i); } } else { SAS::error("ParameterError","maximum number of eventsets (3) exceeded."); }


# reading INSTRUME keywords, sorting images by instrument

    $nm1=0; $nm2=0; $npn=0;

    for ($i = 0; $i < $nima; $i++) {
             if(system("fkeypar fits=$image[$i]+0 key=INSTRUME")){
#             SAS::fatal("ErrFkeypar","Cannot run ftools task fkeypar");
             }
             chomp($iminstr[$i]=`pget fkeypar value`);


            if ($iminstr[$i] =~ /EPN/ ) {
                $pnlist[$npn]=$image[$i];
                $pnlow[$npn]=$amplo[$i];
                $pnhi[$npn]=$amphi[$i];
                $pnecf[$npn]=$in_ecf[$i];
                $npn++;
            }
           if ($iminstr[$i] =~ /EMOS1/ ) {
	        $m1list[$nm1]=$image[$i];
                $m1low[$nm1]=$amplo[$i];
                $m1hi[$nm1]=$amphi[$i];
                $m1ecf[$nm1]=$in_ecf[$i];
                $nm1++;
            }
           if ($iminstr[$i] =~ /EMOS2/ ) {
 	        $m2list[$nm2]=$image[$i];
                $m2low[$nm2]=$amplo[$i];
                $m2hi[$nm2]=$amphi[$i];
                $m2ecf[$nm2]=$in_ecf[$i];
                $nm2++;
            }


    }
    for ($i = 0; $i < $nevli; $i++) {

             $evlist[$i] =~ s/\:EVENTS//;
             if(system("fkeypar fits=$evlist[$i]+0 key=INSTRUME")){
#             SAS::fatal("ErrFkeypar","Cannot run ftools task fkeypar");
             }
             chomp($evinstr[$i]=`pget fkeypar value`);

            if ($evinstr[$i] =~ /EPN/ ) {
                $pnev=$evlist[$i];
            }
           if ($evinstr[$i] =~ /EMOS1/ ) {
	        $m1ev=$evlist[$i];
            }
           if ($evinstr[$i] =~ /EMOS2/ ) {
                $m2ev=$evlist[$i]
            }


    }

    ## check number of energy bands per instrument (cf. SPR-7360) --- IT 2016/04
    if ($nband > $maxbands*(($npn>0)+($nm1>0)+($nm2>0))
	|| $npn > $maxbands || $nm1 > $maxbands || $nm2 > $maxbands) {
	SAS::error("TooManyBands", "eboxdetect and emldetect accept up to six energy bands per instrument.");
    }





    my $attfile=stringParameter("attitudeset");
    my $likemin=realParameter("likemin");
    my $make_newexpmap=booleanParameter("witheexpmap");
# eexpmap parameters:
    my $eex_attrebin=realParameter("eex_attrebin");
# emask parameters:
    my $emask_threshold1=realParameter("emask_threshold1");
    my $emask_threshold2=realParameter("emask_threshold2");
# eboxdetect parameters:
    my $eboxlocallist=stringParameter("eboxl_list");
    my $eboxmaplist=stringParameter("eboxm_list");
    my $eboxl_likemin=realParameter("eboxl_likemin");
    my $eboxm_likemin=realParameter("eboxm_likemin");
    my $ebox_withdetmask=booleanParameter("ebox_withdetmask");
    my $ebox_withexpimage=booleanParameter("ebox_withexpimage");
    my $ebox_boxsize=intParameter("ebox_boxsize");
#    my $ebox_boxprio=realParameter("ebox_boxprio");
# esplinemap parameters:
    my $esp_withdetmask=booleanParameter("esp_withdetmask");
    my $esp_nsplinenodes=intParameter("esp_nsplinenodes");
    my $esp_scut=realParameter("esp_scut");
    my $esp_excesssigma=realParameter("esp_excesssigma");
    my $esp_withexpimage=booleanParameter("esp_withexpimage");
    my $esp_withcheese=booleanParameter("esp_withcheese");
    my $esp_nfitrun=intParameter("esp_nfitrun");
    my $esp_withootset=booleanParameter("esp_withootset");
    my $esp_ooteventset=stringParameter("esp_ooteventset");
    my $esp_fitmethod=stringParameter("esp_fitmethod");
    my $esp_withexpimage2=booleanParameter("esp_withexpimage2");
# emldetect parameters:
    my $emllistset=stringParameter("eml_list");
    my $eml_ecut=realParameter("eml_ecut");
    my $eml_scut=realParameter("eml_scut");
    my $eml_fitextent=booleanParameter("eml_fitextent");
    my $eml_fitnegative=booleanParameter("eml_fitnegative");
    my $eml_determineerrors=booleanParameter("eml_determineerrors");
    my $eml_nmaxfit=intParameter("eml_nmaxfit");
    my $eml_nmulsou=intParameter("eml_nmulsou");
    my $eml_withsourcemap=booleanParameter("eml_withsourcemap");
    my $eml_withdetmask=booleanParameter("eml_withdetmask");
    my $eml_dmlextmin=realParameter("eml_dmlextmin");
    my $eml_extentmodel=stringParameter("eml_extentmodel");
    my $eml_maxextent=realParameter("eml_maxextent");
    my $eml_withthreshold=booleanParameter("eml_withthreshold");
    my $eml_threshold=realParameter("eml_threshold");
    my $eml_threshcolumn=stringParameter("eml_threshcolumn");
    my $eml_withtwostage=booleanParameter("eml_withtwostage");
    my $eml_psfmodel=stringParameter("psfmodel");
### IT 2012/03
# eboxdetect and emldetect parameters:
# cf. SPR-6547 and Helpdesk http://xmm2.esac.esa.int/xmmhelp/SASv10.0?id=41696
    my $eml_withimagebuffersize=booleanParameter("withimagebuffersize");
    my $eml_imagebuffersize=intParameter("imagebuffersize");
# esensmap parameters:
    my $esen_mlmin=realParameter("esen_mlmin");


# if esp_fitmethod "model" and  make_newexpmap are selected,
# create non-vignetted exposure maps and override esp_withexpimage2 flag:
      my $novig = 0;
    if ($esp_fitmethod =~ /^[mM]/ && $make_newexpmap) {
         $novig = 1;
         $esp_withexpimage2 = 1;
    }

    if ($esp_fitmethod =~ /^[sS]/) {
          $esp_withexpimage2 = 0;
    }


##########################################################################
# making exposure maps and masks (eexpmap)
    $pnpimin = "";
    $pnpimax = "";
    $pnexp = "";
    $pnexp2 = "";
    $pnmask="";
    if ($npn > 0) {
        foreach  (@pnlist) {
            $tmp=modify($_,"exp");
            $pnexp .= "$tmp ";
            $tmp=modify($_,"expnovig");
            $pnexp2 .= "$tmp ";
         }


	foreach  (@pnlow) {$pnpimin .= "$_ "}
        foreach  (@pnhi) {$pnpimax .= "$_ "}

        if ($pnev eq "") {
#             SAS::warning("NoEvlist","No event list for EPN specified, no EXPOSURE information");
	     $pnev = $pnlist[0];
        }


        $firstexp=modify($pnlist[0],"exp");
        if ($novig) {
          $firstexp=modify($pnlist[0],"expnovig");
        }
        if ($make_newexpmap) {
          my $c_eexpmap  = "eexpmap imageset=$pnlist[0] eventset=$pnev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$pnexp\" pimin=\"$pnpimin\" pimax=\"$pnpimax\" ";
          $c_eexpmap .= "attrebin=$eex_attrebin";

	  runtask($c_eexpmap);
        }
        if ($novig) {
          my $c_eexpmap  = "eexpmap imageset=$pnlist[0] eventset=$pnev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$pnexp2\" pimin=\"$pnpimin\" pimax=\"$pnpimax\" ";
          $c_eexpmap .= "withvignetting=no ";
          $c_eexpmap .= "attrebin=$eex_attrebin";

	  runtask($c_eexpmap);
        }
        $pnmask=modify($pnlist[0],"mask");
        my $c_mask = "emask expimageset=$firstexp detmaskset=$pnmask ";
        $c_mask .= "threshold1=$emask_threshold1 threshold2=$emask_threshold2";

        runtask($c_mask);
    }

    $m1pimin = "";
    $m1pimax = "";
    $m1exp = "";
    $m1mask="";
    if ($nm1 > 0) {
        foreach  (@m1list) {
            $tmp=modify($_,"exp");
            $m1exp .= " $tmp";
            $tmp=modify($_,"expnovig");
            $m1exp2 .= " $tmp";
                         }
	foreach  (@m1low) {$m1pimin .= "$_ "} 
        foreach  (@m1hi) {$m1pimax .= "$_ "}

        if ($m1ev eq "") {
#             SAS::warning("NoEvlist","No event list for EMOS1 specified, no EXPOSURE information");
	     $m1ev = $m1list[0];
        }


        $firstexp=modify($m1list[0],"exp");
        if ($novig) {
          $firstexp=modify($m1list[0],"expnovig");
        }

        if ($make_newexpmap) {
          my $c_eexpmap  = "eexpmap " . "imageset=$m1list[0] " . "eventset=$m1ev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$m1exp\" pimin=\"$m1pimin\" pimax=\"$m1pimax\" ";
          $c_eexpmap .= "attrebin=$eex_attrebin";
	  runtask($c_eexpmap);
        }

        if ($novig) {
          my $c_eexpmap  = "eexpmap " . "imageset=$m1list[0] " . "eventset=$m1ev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$m1exp2\" pimin=\"$m1pimin\" pimax=\"$m1pimax\" ";
          $c_eexpmap .= "withvignetting=no ";
          $c_eexpmap .= "attrebin=$eex_attrebin";
	  runtask($c_eexpmap);
        }


        $m1mask=modify($m1list[0],"mask");
        my $c_mask = "emask  expimageset=$firstexp detmaskset=$m1mask ";
        $c_mask .= "threshold1=$emask_threshold1 threshold2=$emask_threshold2";

        runtask($c_mask);
    }

    $m2pimin = "";
    $m2pimax = "";
    $m2exp = "";
    $m2mask = "";
    if ($nm2 > 0) {
        foreach  (@m2list) {
            $tmp=modify($_,"exp");
            $m2exp .= " $tmp";
            $tmp=modify($_,"expnovig");
            $m2exp2 .= " $tmp";
         }
	foreach  (@m2low) {$m2pimin .= "$_ "}
        foreach  (@m2hi) {$m2pimax .= "$_ "}

        if ($m2ev eq "") {
#             SAS::warning("NoEvlist","No event list for EMOS2 specified, no EXPOSURE information");
	     $m2ev = $m2list[0];
        }


        $firstexp = modify($m2list[0],"exp");
        $m2mask = modify($m2list[0],"mask");
        my $c_mask = "emask  expimageset=$firstexp detmaskset=$m2mask ";
        $c_mask .= "threshold1=$emask_threshold1 threshold2=$emask_threshold2";
        if ($make_newexpmap) {
          my $c_eexpmap  = "eexpmap " . "imageset=$m2list[0] " . "eventset=$m2ev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$m2exp\" pimin=\"$m2pimin\" pimax=\"$m2pimax\" ";
          $c_eexpmap .= "attrebin=$eex_attrebin";
          runtask($c_eexpmap);
        }
        if ($novig) {
          my $c_eexpmap  = "eexpmap " . "imageset=$m2list[0] " . "eventset=$m2ev attitudeset=$attfile "; 
          $c_eexpmap .= "expimageset=\"$m2exp2\" pimin=\"$m2pimin\" pimax=\"$m2pimax\" ";
          $c_eexpmap .= "withvignetting=no ";
          $c_eexpmap .= "attrebin=$eex_attrebin";
          runtask($c_eexpmap);
        }

        runtask($c_mask);
    }


# eboxdetect (local mode)

    my $imagesets = "";
    $pnecfstr="";
    $m1ecfstr="";
    $m2ecfstr="";

    foreach  (@pnlist) {$imagesets .= "$_ "}
    foreach  (@m1list) {$imagesets .= "$_ "}
    foreach  (@m2list) {$imagesets .= "$_ "}
    foreach  (@pnecf) {$pnecfstr .= "$_ "}
    foreach  (@m1ecf) {$m1ecfstr .= "$_ "}
    foreach  (@m2ecf) {$m2ecfstr .= "$_ "}



    my $ecf = "$pnecfstr $m1ecfstr $m2ecfstr";
    my $expimagesets = "$pnexp $m1exp $m2exp";
    my $pimin = "$pnpimin $m1pimin $m2pimin";
    my $pimax = "$pnpimax $m1pimax $m2pimax";
    my $detmasksets = "$pnmask $m1mask $m2mask";

    my $c_eboxdetect = "eboxdetect imagesets=\"$imagesets\"  expimagesets=\"$expimagesets\" ";
    $c_eboxdetect .=  "detmasksets=\"$detmasksets\" boxlistset=$eboxlocallist ";
    $c_eboxdetect .=  "pimin=\"$pimin\" pimax=\"$pimax\" ecf=\"$ecf\" ";
    $c_eboxdetect .=  "likemin=$eboxl_likemin usemap=false boxsize=$ebox_boxsize ";
    $c_eboxdetect .=  "withexpimage=$ebox_withexpimage withdetmask=$ebox_withdetmask ";
    $c_eboxdetect .=  "withimagebuffersize=$eml_withimagebuffersize " ;
    $c_eboxdetect .=  "imagebuffersize=$eml_imagebuffersize " ;
#    $c_eboxdetect .=  "boxprio=$ebox_boxprio";
#    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_eboxdetect");
    runtask($c_eboxdetect);

# make the background maps (esplinemap)

    my $bgdlist="";
    $idband=1;
    foreach  (@pnlist) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $expimageset2 = modify($_,"expnovig");
        $bkgimageset = modify($_,"bkg");
        $cheeseset = modify($_,"cheese");
        $bgdlist .= "$bkgimageset ";


        my $c_esplinemap =  "esplinemap boxlistset=$eboxlocallist imageset=$imageset ";
        $c_esplinemap .= "expimageset=$expimageset withexpimage=$esp_withexpimage cheeseimageset=$cheeseset ";
        $c_esplinemap .= "bkgimageset=$bkgimageset detmaskset=$pnmask withcheese=$esp_withcheese ";
        $c_esplinemap .= "withdetmask=$esp_withdetmask nsplinenodes=$esp_nsplinenodes ";
        $c_esplinemap .= "idband=$idband scut=$esp_scut excesssigma=$esp_excesssigma ";
        $c_esplinemap .= "nfitrun=$esp_nfitrun  withootset=$esp_withootset ";
        $c_esplinemap .= "fitmethod=$esp_fitmethod withexpimage2=$esp_withexpimage2 expimageset2=$expimageset2  ";
        $c_esplinemap .= "ooteventset=$esp_ooteventset pimin=\"$pnlow[$idband-1]\"  pimax=\"$pnhi[$idband-1]\" ";
	$idband++;
#        SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_esplinemap"); 
        runtask($c_esplinemap);
    }
    $idband=1;
    foreach  (@m1list) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $expimageset2 = modify($_,"expnovig");
        $bkgimageset = modify($_,"bkg");
        $cheeseset = modify($_,"cheese");
        $bgdlist .= "$bkgimageset ";


        my $c_esplinemap =  "esplinemap boxlistset=$eboxlocallist imageset=$imageset ";
        $c_esplinemap .= "expimageset=$expimageset withexpimage=$esp_withexpimage cheeseimageset=$cheeseset ";
        $c_esplinemap .= "bkgimageset=$bkgimageset detmaskset=$m1mask withcheese=$esp_withcheese ";
        $c_esplinemap .= "withdetmask=$esp_withdetmask nsplinenodes=$esp_nsplinenodes ";
        $c_esplinemap .= "idband=$idband scut=$esp_scut excesssigma=$esp_excesssigma ";
        $c_esplinemap .= "fitmethod=$esp_fitmethod withexpimage2=$esp_withexpimage2 expimageset2=$expimageset2  ";
        $c_esplinemap .= "nfitrun=$esp_nfitrun  withootset=no pimin=\"$m1low[$idband-1]\"  pimax=\"$m1hi[$idband-1]\"  "; 
	$idband++;
#        SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_esplinemap");
        runtask($c_esplinemap);
    }
    $idband=1;
    foreach  (@m2list) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $expimageset2 = modify($_,"expnovig");
        $bkgimageset = modify($_,"bkg");
        $cheeseset = modify($_,"cheese");
        $bgdlist .= "$bkgimageset ";

        my $c_esplinemap =  "esplinemap boxlistset=$eboxlocallist imageset=$imageset ";
        $c_esplinemap .= "expimageset=$expimageset withexpimage=$esp_withexpimage cheeseimageset=$cheeseset ";
        $c_esplinemap .= "bkgimageset=$bkgimageset detmaskset=$m2mask  withcheese=$esp_withcheese ";
        $c_esplinemap .= "withdetmask=$esp_withdetmask nsplinenodes=$esp_nsplinenodes ";
        $c_esplinemap .= "idband=$idband scut=$esp_scut excesssigma=$esp_excesssigma ";
        $c_esplinemap .= "fitmethod=$esp_fitmethod withexpimage2=$esp_withexpimage2 expimageset2=$expimageset2  ";
        $c_esplinemap .= "nfitrun=$esp_nfitrun withootset=no  pimin=\"$m2low[$idband-1]\"  pimax=\"$m2hi[$idband-1]\" ";
	$idband++;
        runtask($c_esplinemap);
    }


# do eboxdetect in map mode:



    $c_eboxdetect = "eboxdetect imagesets=\"$imagesets\"  expimagesets=\"$expimagesets\" ";
    $c_eboxdetect .=  "detmasksets=\"$detmasksets\" boxlistset=$eboxmaplist ecf=\"$ecf\" ";
    $c_eboxdetect .=  "pimin=\"$pimin\" pimax=\"$pimax\" usemap=yes withdetmask=$ebox_withdetmask ";
    $c_eboxdetect .=  "bkgimagesets=\"$bgdlist\" withexpimage=$ebox_withexpimage likemin=$eboxm_likemin ";
    $c_eboxdetect .=  "boxsize=$ebox_boxsize ";
    $c_eboxdetect .=  "withimagebuffersize=$eml_withimagebuffersize " ;
    $c_eboxdetect .=  "imagebuffersize=$eml_imagebuffersize " ;
#    $c_eboxdetect .=  "boxprio=$ebox_boxprio";
#    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_eboxdetect");
    runtask($c_eboxdetect);



# do emldetect:




    ($sourcemap = $expimagesets) =~ s/exp\./smap\./g;


    my  $c_emldetect = "emldetect imagesets=\"$imagesets\"  expimagesets=\"$expimagesets\" "; 
    $c_emldetect .= "boxlistset=$eboxmaplist  bkgimagesets=\"$bgdlist\"  mllistset=$emllistset ";
    $c_emldetect .= "pimin=\"$pimin\" pimax=\"$pimax\" ecf=\"$ecf\" mlmin=$likemin ";
    $c_emldetect .= "determineerrors=$eml_determineerrors ecut=$eml_ecut ";
    $c_emldetect .= "scut=$eml_scut fitextent=$eml_fitextent withsourcemap=$eml_withsourcemap ";
    $c_emldetect .= "sourceimagesets=\"$sourcemap\" nmaxfit=$eml_nmaxfit fitnegative=$eml_fitnegative ";
    $c_emldetect .= "nmulsou=$eml_nmulsou dmlextmin=$eml_dmlextmin  ";
    $c_emldetect .= "withdetmask=$ebox_withdetmask detmasksets=\"$detmasksets\" extentmodel=$eml_extentmodel ";
    $c_emldetect .= "withtwostage=$eml_withtwostage withthreshold=$eml_withthreshold threshold=$eml_threshold ";
    $c_emldetect .= "threshcolumn=$eml_threshcolumn maxextent=$eml_maxextent " ;
    $c_emldetect .= "psfmodel=$eml_psfmodel " ;
    $c_emldetect .= "withimagebuffersize=$eml_withimagebuffersize " ;
    $c_emldetect .= "imagebuffersize=$eml_imagebuffersize " ;


#    SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_emldetect");
    runtask($c_emldetect);



# do esensmap:

    foreach  (@pnlist) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $bkgimageset = modify($_,"bkg");
        $sensimageset = modify($_,"sen");


        my $c_esensmap = "esensmap bkgimagesets=$bkgimageset expimagesets=$expimageset ";
	$c_esensmap .= "detmasksets=$pnmask sensimageset=$sensimageset mlmin=$esen_mlmin";
#        SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_esensmap");
        runtask($c_esensmap);
    }
    foreach  (@m1list) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $bkgimageset = modify($_,"bkg");
        $sensimageset = modify($_,"sen");

        my $c_esensmap = "esensmap bkgimagesets=$bkgimageset expimagesets=$expimageset ";
	$c_esensmap .= "detmasksets=$m1mask sensimageset=$sensimageset mlmin=$esen_mlmin";
#        SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_esensmap");
        runtask($c_esensmap);

    }

    foreach  (@m2list) {
        $imageset = $_;
        $expimageset = modify($_,"exp");
        $bkgimageset = modify($_,"bkg");
        $sensimageset = modify($_,"sen");

        my $c_esensmap = "esensmap bkgimagesets=$bkgimageset expimagesets=$expimageset ";
	$c_esensmap .= "detmasksets=$m2mask sensimageset=$sensimageset mlmin=$esen_mlmin";
#        SAS::message($SAS::AppMsg,$SAS::VerboseMsg,"$c_esensmap");
        runtask($c_esensmap);
    }


}
# end edetect_chain


sub runtask{
   my $taskname=$_[0];
   system("$taskname");
   if ($? != 0) {
#       SAS::fatal("TaskFailed","$taskname returned error $?");
       print "error in  $taskname \n";
   }
}

sub modify{
    my $filename = $_[0];
    my $ext = $_[1];
    my $newname ;
    my $temp;

    my @parts=split /\//,$filename;
    my $tail=$parts[-1];
    $tail =~ s/\.gz//;
    $tail =~ s/FTZ/FIT/;
   ($newname = $tail) =~ s/\.[\w\-]/$ext$&/ ;
   if ($& eq "") {
       $newname = $tail.$ext;
   }
   return $newname;
}

