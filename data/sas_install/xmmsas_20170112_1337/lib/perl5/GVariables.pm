## @file
# Define Global Variables

package GVariables;

##################################################
## the object constructor (simplistic version)  ##
##################################################
sub new {
    my $self ={};    
    $self->{SRC_Name}            ="[SourceName]";
    $self->{SRC_OBSID}           ="[ObsID]";
    $self->{SRC_EXP}             ="[Exposure]";
    $self->{WITH_EPIC_SRC_COORDS}=undef;
    $self->{SRC_RA}              =undef;
    $self->{SRC_DEC}             =undef; 
    $self->{EPN}				 =undef;
    $self->{EPN_exposures}		 =[];
    $self->{EMOS1}				 =undef;
    $self->{EMOS1_exposures}	 =[];
    $self->{EMOS2}				 =undef;
    $self->{EMOS2_exposures}	 =[];
    $self->{RGS}				 =undef;
    $self->{RGS_exposures}		 =[];
    $self->{OM}					 =undef;
    $self->{OM_exposures}		 =[];
    $self->{epic_instrument}	 =undef;
    $self->{ANA_epatplot}	     =undef;

######################################
########## GTI FILTERING #############
######################################

    $self->{GTI_optimize_SN_flag}=undef;
    $self->{GTI_m1energy_cut}  =undef;
    $self->{GTI_m2energy_cut}  =undef;
    $self->{GTI_pnenergy_cut}    =undef;
    $self->{GTI_m1_Rate}       =undef;
    $self->{GTI_m2_Rate}       =undef;
    $self->{GTI_pn_Rate}         =undef;
    $self->{GTI_timebin}         =undef;

########################################
###### EDETECT CHAIN VARIABLES #########
########################################

    $self->{EDC_pn_ene_low}      =[];
    $self->{EDC_pn_ene_high}     =[];
    $self->{EDC_m1_ene_low}      =[];
    $self->{EDC_m1_ene_high}     =[];
    $self->{EDC_m2_ene_low}      =[];
    $self->{EDC_m2_ene_high}     =[];
    $self->{EDC_pn_likelihood_detection} =undef;
    $self->{EDC_mos_likelihood_detection}=undef;
    $self->{EDC_sourcematch}=undef;
    $self->{EDC_cameramatch}=undef;
    $self->{OM_sourcematch} =undef;
 
##########################################
#### SIGNAL TO NOISE OPTIMIZATION  #######
#### FOR HIGH BACKGROUND FILTERING #######
########################################## 

    $self->{PG_pn_srcregion}        =undef;
    $self->{PG_pn_bkgregion}        =undef;
    $self->{PG_pn_srcregion_X}      =undef;
    $self->{PG_pn_srcregion_Y}      =undef;
    $self->{PG_pn_srcregion_R1}     =undef;
    $self->{PG_pn_srcregion_R2}     =undef;
    $self->{PG_pn_srcregion_XLength}=undef;
    $self->{PG_pn_srcregion_YLength}=undef;
    $self->{PG_pn_bkgregion_X}      =undef;
    $self->{PG_pn_bkgregion_Y}      =undef;
    $self->{PG_pn_bkgregion_R1}     =undef;
    $self->{PG_pn_bkgregion_R2}     =undef;
    $self->{PG_pn_bkgregion_XLength}=undef;
    $self->{PG_pn_bkgregion_YLength}=undef;
    $self->{PG_pn_areafactor}       =undef;
 
    $self->{PG_m1_srcregion}        =undef;
    $self->{PG_m1_bkgregion}        =undef;
    $self->{PG_m1_srcregion_X}      =undef;
    $self->{PG_m1_srcregion_Y}      =undef;
    $self->{PG_m1_srcregion_R1}     =undef;
    $self->{PG_m1_srcregion_R2}     =undef;
    $self->{PG_m1_srcregion_XLength}=undef;
    $self->{PG_m1_srcregion_YLength}=undef;
    $self->{PG_m1_bkgregion_X}      =undef;
    $self->{PG_m1_bkgregion_Y}      =undef;
    $self->{PG_m1_bkgregion_R1}     =undef;
    $self->{PG_m1_bkgregion_R2}     =undef;
    $self->{PG_m1_bkgregion_XLength}=undef;
    $self->{PG_m1_bkgregion_YLength}=undef;
    $self->{PG_m1_areafactor}       =undef;

    $self->{PG_m2_srcregion}        =undef;
    $self->{PG_m2_bkgregion}        =undef;
    $self->{PG_m2_srcregion_X}      =undef;
    $self->{PG_m2_srcregion_Y}      =undef;
    $self->{PG_m2_srcregion_R1}     =undef;
    $self->{PG_m2_srcregion_R2}     =undef;
    $self->{PG_m2_srcregion_XLength}=undef;
    $self->{PG_m2_srcregion_YLength}=undef;
    $self->{PG_m2_bkgregion_X}      =undef;
    $self->{PG_m2_bkgregion_Y}      =undef;
    $self->{PG_m2_bkgregion_R1}     =undef;
    $self->{PG_m2_bkgregion_R2}     =undef;
    $self->{PG_m2_bkgregion_XLength}=undef;
    $self->{PG_m2_bkgregion_YLength}=undef;
    $self->{PG_m2_areafactor}       =undef;
    
    $self->{PG_pn_src_expr}    	    =undef;
    $self->{PG_pn_bkg_expr}         =undef;
    $self->{PG_m1_src_expr}         =undef;
    $self->{PG_m1_bkg_expr}         =undef;
    $self->{PG_m2_src_expr}         =undef;
    $self->{PG_m2_bkg_expr}         =undef;
    
    $self->{PG_timebinning} =undef;
    $self->{PG_timestart}   =undef;
    $self->{PG_timeend}     =undef;
    $self->{PG_minpi}       =undef;
    $self->{PG_maxpi}       =undef;
    
    
#####################################
#### LIGHTCURVE VARAIBLES ###########
#####################################
       
   	$self->{LC_pn_interactivity}	= undef;
   	$self->{LC_m1_interactivity}	= undef;
   	$self->{LC_m2_interactivity}	= undef;
   	$self->{LC_pn_exposure}		 	= undef;
   	$self->{LC_m1_exposure}		 	= undef;
   	$self->{LC_m2_exposure}		 	= undef;
   	$self->{display_ds9_LC_pn_exposure} = undef;
   	$self->{display_ds9_LC_m1_exposure} = undef;
   	$self->{display_ds9_LC_m1_exposure} = undef;
    $self->{LC_pn_e1_low}     		=undef;
    $self->{LC_pn_e1_up}      		=undef;
    $self->{LC_m1_e1_low}     		=undef;
    $self->{LC_m1_e1_up}      		=undef;
    $self->{LC_m2_e1_low}     		=undef;
    $self->{LC_m2_e1_up}      		=undef; 
    $self->{LC_pn_srcregion}        =undef;
    $self->{LC_pn_bkgregion}        =undef;
    $self->{LC_pn_srcregion_X}      =undef;
    $self->{LC_pn_srcregion_Y}      =undef;
    $self->{LC_pn_srcregion_R1}     =undef;
    $self->{LC_pn_srcregion_R2}     =undef;
    $self->{LC_pn_srcregion_XLength}=undef;
    $self->{LC_pn_srcregion_YLength}=undef;
    $self->{LC_pn_bkgregion_X}      =undef;
    $self->{LC_pn_bkgregion_Y}      =undef;
    $self->{LC_pn_bkgregion_R1}     =undef;
    $self->{LC_pn_bkgregion_R2}     =undef;
    $self->{LC_pn_bkgregion_XLength}=undef;
    $self->{LC_pn_bkgregion_YLength}=undef;
    $self->{LC_pn_areafactor}       =undef;
    $self->{LC_m1_srcregion}        =undef;
    $self->{LC_m1_bkgregion}        =undef;
    $self->{LC_m1_srcregion_X}      =undef;
    $self->{LC_m1_srcregion_Y}      =undef;
    $self->{LC_m1_srcregion_R1}     =undef;
    $self->{LC_m1_srcregion_R2}     =undef;
    $self->{LC_m1_srcregion_XLength}=undef;
    $self->{LC_m1_srcregion_YLength}=undef;
    $self->{LC_m1_bkgregion_X}      =undef;
    $self->{LC_m1_bkgregion_Y}      =undef;
    $self->{LC_m1_bkgregion_R1}     =undef;
    $self->{LC_m1_bkgregion_R2}     =undef;
    $self->{LC_m1_bkgregion_XLength}=undef;
    $self->{LC_m1_bkgregion_YLength}=undef;
    $self->{LC_m1_areafactor}       =undef;
    $self->{LC_m2_srcregion}        =undef;
    $self->{LC_m2_bkgregion}        =undef;
    $self->{LC_m2_srcregion_X}      =undef;
    $self->{LC_m2_srcregion_Y}      =undef;
    $self->{LC_m2_srcregion_R1}     =undef;
    $self->{LC_m2_srcregion_R2}     =undef;
    $self->{LC_m2_srcregion_XLength}=undef;
    $self->{LC_m2_srcregion_YLength}=undef;
    $self->{LC_m2_bkgregion_X}      =undef;
    $self->{LC_m2_bkgregion_Y}      =undef;
    $self->{LC_m2_bkgregion_R1}     =undef;
    $self->{LC_m2_bkgregion_R2}     =undef;
    $self->{LC_m2_bkgregion_XLength}=undef;
    $self->{LC_m2_bkgregion_YLength}=undef;
    $self->{LC_m2_areafactor}       =undef;
    
    $self->{LC_pn_src_expr}    	    =undef;
    $self->{LC_pn_bkg_expr}         =undef;
    $self->{LC_m1_src_expr}         =undef;
    $self->{LC_m1_bkg_expr}         =undef;
    $self->{LC_m2_src_expr}         =undef;
    $self->{LC_m2_bkg_expr}         =undef;

    $self->{LC_pn_timebinsize}  =undef;   
    $self->{LC_m1_timebinsize}  =undef;   
    $self->{LC_m2_timebinsize}  =undef;
    
#####################################
###### SPECTRA VARAIBLES ############
#####################################   

   	$self->{SPC_pn_interactivity}	 = undef;
   	$self->{SPC_m1_interactivity}	 = undef;
   	$self->{SPC_m2_interactivity}	 = undef;
   	$self->{SPC_pn_exposure}		 = undef;
   	$self->{SPC_m1_exposure}		 = undef;
   	$self->{SPC_m2_exposure}		 = undef;
   	$self->{display_ds9_SPC_pn_exposure} = undef;
   	$self->{display_ds9_SPC_m1_exposure} = undef;
   	$self->{display_ds9_SPC_m2_exposure} = undef;
    $self->{SPC_pn_e1_low}           = undef;
    $self->{SPC_pn_e1_up}            = undef;
    $self->{SPC_m1_e1_low}           = undef;
    $self->{SPC_m1_e1_up}            = undef;
    $self->{SPC_m2_e1_low}           = undef;
    $self->{SPC_m2_e1_up}            = undef;  
    $self->{SPC_pn_srcregion}        =undef;
    $self->{SPC_pn_bkgregion}        =undef;
    $self->{SPC_pn_srcregion_X}      =undef;
    $self->{SPC_pn_srcregion_Y}      =undef;
    $self->{SPC_pn_srcregion_R1}     =undef;
    $self->{SPC_pn_srcregion_R2}     =undef;
    $self->{SPC_pn_srcregion_XLength}=undef;
    $self->{SPC_pn_srcregion_YLength}=undef;
    $self->{SPC_pn_bkgregion_X}      =undef;
    $self->{SPC_pn_bkgregion_Y}      =undef;
    $self->{SPC_pn_bkgregion_R1}     =undef;
    $self->{SPC_pn_bkgregion_R2}     =undef;
    $self->{SPC_pn_bkgregion_XLength}=undef;
    $self->{SPC_pn_bkgregion_YLength}=undef;
    $self->{SPC_pn_areafactor}       =undef;
    $self->{SPC_m1_srcregion}        =undef;
    $self->{SPC_m1_bkgregion}        =undef;
    $self->{SPC_m1_srcregion_X}      =undef;
    $self->{SPC_m1_srcregion_Y}      =undef;
    $self->{SPC_m1_srcregion_R1}     =undef;
    $self->{SPC_m1_srcregion_R2}     =undef;
    $self->{SPC_m1_srcregion_XLength}=undef;
    $self->{SPC_m1_srcregion_YLength}=undef;
    $self->{SPC_m1_bkgregion_X}      =undef;
    $self->{SPC_m1_bkgregion_Y}      =undef;
    $self->{SPC_m1_bkgregion_R1}     =undef;
    $self->{SPC_m1_bkgregion_R2}     =undef;
    $self->{SPC_m1_bkgregion_XLength}=undef;
    $self->{SPC_m1_bkgregion_YLength}=undef;
    $self->{SPC_m1_areafactor}       =undef;
    $self->{SPC_m2_srcregion}        =undef;
    $self->{SPC_m2_bkgregion}        =undef;
    $self->{SPC_m2_srcregion_X}      =undef;
    $self->{SPC_m2_srcregion_Y}      =undef;
    $self->{SPC_m2_srcregion_R1}     =undef;
    $self->{SPC_m2_srcregion_R2}     =undef;
    $self->{SPC_m2_srcregion_XLength}=undef;
    $self->{SPC_m2_srcregion_YLength}=undef;
    $self->{SPC_m2_bkgregion_X}      =undef;
    $self->{SPC_m2_bkgregion_Y}      =undef;
    $self->{SPC_m2_bkgregion_R1}     =undef;
    $self->{SPC_m2_bkgregion_R2}     =undef;
    $self->{SPC_m2_bkgregion_XLength}=undef;
    $self->{SPC_m2_bkgregion_YLength}=undef;
    $self->{SPC_m2_areafactor}       =undef;
    
    $self->{SPC_pn_src_expr}    	 =undef;
    $self->{SPC_pn_bkg_expr}         =undef;
    $self->{SPC_m1_src_expr}         =undef;
    $self->{SPC_m1_bkg_expr}         =undef;
    $self->{SPC_m2_src_expr}         =undef;
    $self->{SPC_m2_bkg_expr}         =undef;
    
    
    $self->{LC_rgs1_orders}        ="1 2";
    $self->{LC_rgs1_timebinsize}   =200;
    $self->{LC_rgs2_orders}        ="1 2";
    $self->{LC_rgs2_timebinsize}   =200;
    
######################################
########## RGS VARIABLES #############
######################################    
	$self->{RGS_withsrc}  =undef;
	$self->{RGS_srcstyle} = undef;
	$self->{RGS_srcra} = undef;
	$self->{RGS_srcdec}=undef;
	$self->{RGS_srcdisp}=undef;
	$self->{RGS_srcxdsp}=undef;
	$self->{RGS_srclabel}=undef;
	$self->{RGS_srcrate}=undef;
	$self->{RGS_keepcool}=undef;
	$self->{RGS_rejflags}=undef;
	$self->{RGS_spectrumbinnig}=undef; 
    	   
    bless($self);          
    return $self;
}


sub print {
    my $self=shift;
    print "---> xmmextractor variables <----\n";
    print "perl xmmextractor ";
    print "sourcename=$self->{SRC_Name} ";    
	print "obsid=$self->{SRC_OBSID} ";
	print "SRC_exposure=$self->{SRC_EXP} "; 
	print "epicsrc=$self->{WITH_EPIC_SRC_COORDS} ";
	print "ra=$self->{SRC_RA} ";
	print "dec=$self->{SRC_DEC} ";
	print "EPN=$self->{EPN} ";
	@tmp=$self->EPN_exposures;
	print "EPN_exposures=@tmp ";
	print "EMOS1=$self->{EMOS1} ";
	@tmp=$self->EMOS1_exposures;
	print "EMOS1_exposures=@tmp ";
	print "EMOS2=$self->{EMOS2} ";
	@tmp=$self->EMOS2_exposures;
	print "EMOS2_exposures=@tmp ";
	print "RGS=$self->{RGS} ";
	@tmp=$self->RGS_exposures;
	print "RGS_exposures=@tmp ";
	print "OM=$self->{OM} ";
	@tmp=$self->OM_exposures;
	print "OM_exposures=@tmp ";
	print "epic_instrument=$self->{epic_instrument} ";
	print "runepatplot=$self->{ANA_epatplot} ";

######################################
########## GTI FILTERING #############
######################################	
	print "m1energy_cut=$self->{GTI_m1energy_cut} ";
	print "m2energy_cut=$self->{GTI_m2energy_cut} ";
	print "pnenergy_cut=$self->{GTI_pnenergy_cut} ";
	print "m1_Rate=$self->{GTI_m1_Rate} ";
	print "m2_Rate=$self->{GTI_m2_Rate} ";
	print "pn_Rate=$self->{GTI_pn_Rate} ";
	print "timebin=$self->{GTI_timebin} ";

########################################
###### EDETECT CHAIN VARIABLES #########
########################################

	@tmp=$self->EDC_pn_ene_low;
	print "EDC_pn_ene_low=@tmp ";
	@tmp=$self->EDC_pn_ene_high;
	print "EDC_pn_ene_high=@tmp ";
	@tmp=$self->EDC_m1_ene_low;
	print "EDC_m1_ene_low=@tmp ";
	@tmp=$self->EDC_m1_ene_high;
	print "EDC_m1_ene_high=@tmp ";
	@tmp=$self->EDC_m2_ene_low;
	print "EDC_m2_ene_low=@tmp ";
	@tmp=$self->EDC_m2_ene_high;
	print "EDC_m2_ene_high=@tmp ";
	print "pn_likelihood_detection=$self->{EDC_pn_likelihood_detection} ";
	print "mos_likelihood_detection=$self->{EDC_mos_likelihood_detection} ";
	print "sourcematch=$self->{EDC_sourcematch} ";
	print "cameramatch=$self->{EDC_cameramatch} ";
	print "om_sourcematch=$self->{OM_sourcematch} ";

##########################################
#### SIGNAL TO NOISE OPTIMIZATION  #######
#### FOR HIGH BACKGROUND FILTERING #######
########################################## 

	print "PG_optimize_SN=$self->{GTI_optimize_SN_flag} ";
	print "PG_pn_srcregion=$self->{PG_pn_srcregion} ";
	print "PG_pn_bkgregion=$self->{PG_pn_bkgregion} ";
	print "PG_pn_srcregion_X=$self->{PG_pn_srcregion_X} ";
	print "PG_pn_srcregion_Y=$self->{PG_pn_srcregion_Y} ";
	print "PG_pn_srcregion_R1=$self->{PG_pn_srcregion_R1} ";
	print "PG_pn_srcregion_R2=$self->{PG_pn_srcregion_R2} ";
	print "PG_pn_srcregion_XLength=$self->{PG_pn_srcregion_XLength} ";
	print "PG_pn_srcregion_YLength=$self->{PG_pn_srcregion_YLength} ";
	print "PG_pn_bkgregion_X=$self->{PG_pn_bkgregion_X} ";
	print "PG_pn_bkgregion_Y=$self->{PG_pn_bkgregion_Y} ";
	print "PG_pn_bkgregion_R1=$self->{PG_pn_bkgregion_R1} ";
	print "PG_pn_bkgregion_R2=$self->{PG_pn_bkgregion_R2} ";
	print "PG_pn_bkgregion_XLength=$self->{PG_pn_bkgregion_XLength} ";
	print "PG_pn_bkgregion_YLength=$self->{PG_pn_bkgregion_YLength} ";
	print "PG_pn_areafactor=$self->{PG_pn_areafactor} ";
	print "PG_m1_srcregion=$self->{PG_m1_srcregion} ";
	print "PG_m1_bkgregion=$self->{PG_m1_bkgregion} ";
	print "PG_m1_srcregion_X=$self->{PG_m1_srcregion_X} ";
	print "PG_m1_srcregion_Y=$self->{PG_m1_srcregion_Y} ";
	print "PG_m1_srcregion_R1=$self->{PG_m1_srcregion_R1} ";
	print "PG_m1_srcregion_R2=$self->{PG_m1_srcregion_R2} ";
	print "PG_m1_srcregion_XLength=$self->{PG_m1_srcregion_XLength} ";
	print "PG_m1_srcregion_YLength=$self->{PG_m1_srcregion_YLength} ";
	print "PG_m1_bkgregion_X=$self->{PG_m1_bkgregion_X} ";
	print "PG_m1_bkgregion_Y=$self->{PG_m1_bkgregion_Y} ";
	print "PG_m1_bkgregion_R1=$self->{PG_m1_bkgregion_R1} ";
	print "PG_m1_bkgregion_R2=$self->{PG_m1_bkgregion_R2} ";
	print "PG_m1_bkgregion_XLength=$self->{PG_m1_bkgregion_XLength} ";
	print "PG_m1_bkgregion_YLength=$self->{PG_m1_bkgregion_YLength} ";
	print "PG_m1_areafactor=$self->{PG_m1_areafactor} ";
	print "PG_m2_srcregion=$self->{PG_m2_srcregion} ";
	print "PG_m2_bkgregion=$self->{PG_m2_bkgregion} ";
	print "PG_m2_srcregion_X=$self->{PG_m2_srcregion_X} ";
	print "PG_m2_srcregion_Y=$self->{PG_m2_srcregion_Y} ";
	print "PG_m2_srcregion_R1=$self->{PG_m2_srcregion_R1} ";
	print "PG_m2_srcregion_R2=$self->{PG_m2_srcregion_R2} ";
	print "PG_m2_srcregion_XLength=$self->{PG_m2_srcregion_XLength} ";
	print "PG_m2_srcregion_YLength=$self->{PG_m2_srcregion_YLength} ";
	print "PG_m2_bkgregion_X=$self->{PG_m2_bkgregion_X} ";
	print "PG_m2_bkgregion_Y=$self->{PG_m2_bkgregion_Y} ";
	print "PG_m2_bkgregion_R1=$self->{PG_m2_bkgregion_R1} ";
	print "PG_m2_bkgregion_R2=$self->{PG_m2_bkgregion_R2} ";
	print "PG_m2_bkgregion_XLength=$self->{PG_m2_bkgregion_XLength} ";
	print "PG_m2_bkgregion_YLength=$self->{PG_m2_bkgregion_YLength} ";
	print "PG_m2_areafactor=$self->{PG_m2_areafactor} ";
	print "PG_pn_src_expr=$self->{PG_pn_src_expr} ";
	print "PG_pn_bkg_expr=$self->{PG_pn_bkg_expr} ";
	print "PG_m1_src_expr=$self->{PG_m1_src_expr} ";
	print "PG_m1_bkg_expr=$self->{PG_m1_bkg_expr} ";
	print "PG_m2_src_expr=$self->{PG_m2_src_expr} ";
	print "PG_m2_bkg_expr=$self->{PG_m2_bkg_expr} ";
	
	
	print "PG_timebinning=$self->{PG_timebinning} ";
	print "PG_timestart=$self->{PG_timestart} ";
	print "PG_timeend=$self->{PG_timeend} ";
	print "PG_minpi=$self->{PG_minpi} ";
	print "PG_maxpi=$self->{PG_maxpi} ";


###############################
#### LIGHT CURVE VARIABLES ####
###############################	
	print "LC_pn_interactivity=$self->{LC_pn_interactivity} ";
	print "LC_m1_interactivity=$self->{LC_m1_interactivity} ";
	print "LC_m2_interactivity=$self->{LC_m2_interactivity} ";
	print "LC_pn_exposure=$self->{LC_pn_exposure} ";
	print "LC_m1_exposure=$self->{LC_m1_exposure} ";
	print "LC_m2_exposure=$self->{LC_m2_exposure} ";
	print "display_ds9_LC_pn_exposure=$self->{display_ds9_LC_pn_exposure} ";
	print "display_ds9_LC_m1_exposure=$self->{display_ds9_LC_m1_exposure} ";
	print "display_ds9_LC_m2_exposure=$self->{display_ds9_LC_m2_exposure} ";
	print "LC_pn_e1_low=$self->{LC_pn_e1_low} ";
	print "LC_pn_e1_up=$self->{LC_pn_e1_up} ";
	print "LC_m1_e1_low=$self->{LC_m1_e1_low} ";
	print "LC_m1_e1_up=$self->{LC_m1_e1_up} ";
	print "LC_m2_e1_low=$self->{LC_m2_e1_low} ";
	print "LC_m2_e1_up=$self->{LC_m2_e1_up} ";
	print "LC_pn_srcregion=$self->{LC_pn_srcregion} ";
	print "LC_pn_bkgregion=$self->{LC_pn_bkgregion} ";
	print "LC_pn_srcregion_X=$self->{LC_pn_srcregion_X} ";
	print "LC_pn_srcregion_Y=$self->{LC_pn_srcregion_Y} ";
	print "LC_pn_srcregion_R1=$self->{LC_pn_srcregion_R1} ";
	print "LC_pn_srcregion_R2=$self->{LC_pn_srcregion_R2} ";
	print "LC_pn_srcregion_XLength=$self->{LC_pn_srcregion_XLength} ";
	print "LC_pn_srcregion_YLength=$self->{LC_pn_srcregion_YLength} ";
	print "LC_pn_bkgregion_X=$self->{LC_pn_bkgregion_X} ";
	print "LC_pn_bkgregion_Y=$self->{LC_pn_bkgregion_Y} ";
	print "LC_pn_bkgregion_R1=$self->{LC_pn_bkgregion_R1} ";
	print "LC_pn_bkgregion_R2=$self->{LC_pn_bkgregion_R2} ";
	print "LC_pn_bkgregion_XLength=$self->{LC_pn_bkgregion_XLength} ";
	print "LC_pn_bkgregion_YLength=$self->{LC_pn_bkgregion_YLength} ";
	print "LC_pn_areafactor=$self->{LC_pn_areafactor} ";
	print "LC_m1_srcregion=$self->{LC_m1_srcregion} ";
	print "LC_m1_bkgregion=$self->{LC_m1_bkgregion} ";
	print "LC_m1_srcregion_X=$self->{LC_m1_srcregion_X} ";
	print "LC_m1_srcregion_Y=$self->{LC_m1_srcregion_Y} ";
	print "LC_m1_srcregion_R1=$self->{LC_m1_srcregion_R1} ";
	print "LC_m1_srcregion_R2=$self->{LC_m1_srcregion_R2} ";
	print "LC_m1_srcregion_XLength=$self->{LC_m1_srcregion_XLength} ";
	print "LC_m1_srcregion_YLength=$self->{LC_m1_srcregion_YLength} ";
	print "LC_m1_bkgregion_X=$self->{LC_m1_bkgregion_X} ";
	print "LC_m1_bkgregion_Y=$self->{LC_m1_bkgregion_Y} ";
	print "LC_m1_bkgregion_R1=$self->{LC_m1_bkgregion_R1} ";
	print "LC_m1_bkgregion_R2=$self->{LC_m1_bkgregion_R2} ";
	print "LC_m1_bkgregion_XLength=$self->{LC_m1_bkgregion_XLength} ";
	print "LC_m1_bkgregion_YLength=$self->{LC_m1_bkgregion_YLength} ";
	print "LC_m1_areafactor=$self->{LC_m1_areafactor} ";
	print "LC_m2_srcregion=$self->{LC_m2_srcregion} ";
	print "LC_m2_bkgregion=$self->{LC_m2_bkgregion} ";
	print "LC_m2_srcregion_X=$self->{LC_m2_srcregion_X} ";
	print "LC_m2_srcregion_Y=$self->{LC_m2_srcregion_Y} ";
	print "LC_m2_srcregion_R1=$self->{LC_m2_srcregion_R1} ";
	print "LC_m2_srcregion_R2=$self->{LC_m2_srcregion_R2} ";
	print "LC_m2_srcregion_XLength=$self->{LC_m2_srcregion_XLength} ";
	print "LC_m2_srcregion_YLength=$self->{LC_m2_srcregion_YLength} ";
	print "LC_m2_bkgregion_X=$self->{LC_m2_bkgregion_X} ";
	print "LC_m2_bkgregion_Y=$self->{LC_m2_bkgregion_Y} ";
	print "LC_m2_bkgregion_R1=$self->{LC_m2_bkgregion_R1} ";
	print "LC_m2_bkgregion_R2=$self->{LC_m2_bkgregion_R2} ";
	print "LC_m2_bkgregion_XLength=$self->{LC_m2_bkgregion_XLength} ";
	print "LC_m2_bkgregion_YLength=$self->{LC_m2_bkgregion_YLength} ";
	print "LC_m2_areafactor=$self->{LC_m2_areafactor} ";
	print "LC_pn_src_expr=$self->{LC_pn_src_expr} ";
	print "LC_pn_bkg_expr=$self->{LC_pn_bkg_expr} ";
	print "LC_m1_src_expr=$self->{LC_m1_src_expr} ";
	print "LC_m1_bkg_expr=$self->{LC_m1_bkg_expr} ";
	print "LC_m2_src_expr=$self->{LC_m2_src_expr} ";
	print "LC_m2_bkg_expr=$self->{LC_m2_bkg_expr} ";
	print "LC_pn_timebinsize=$self->{LC_pn_timebinsize} ";
	print "LC_m1_timebinsize=$self->{LC_m1_timebinsize} ";
	print "LC_m2_timebinsize=$self->{LC_m2_timebinsize} ";
#####################################
###### SPECTRA VARAIBLES ############
#####################################  
	print "SPC_pn_interactivity=$self->{SPC_pn_interactivity}";
	print "SPC_m1_interactivity=$self->{SPC_m1_interactivity}";
	print "SPC_m2_interactivity=$self->{SPC_m2_interactivity}";
	print "SPC_pn_exposure=$self->{SPC_pn_exposure}";
	print "SPC_m1_exposure=$self->{SPC_m1_exposure}";
	print "SPC_m2_exposure=$self->{SPC_m2_exposure}";
	print "display_ds9_SPC_pn_exposure=$self->{display_ds9_SPC_pn_exposure}";
	print "display_ds9_SPC_m1_exposure=$self->{display_ds9_SPC_m1_exposure}";
	print "display_ds9_SPC_m2_exposure=$self->{display_ds9_SPC_m2_exposure}";
	print "SPC_pn_e1_low=$self->{SPC_pn_e1_low} ";
	print "SPC_pn_e1_up=$self->{SPC_pn_e1_up} ";
	print "SPC_m1_e1_low=$self->{SPC_m1_e1_low} ";
	print "SPC_m1_e1_up=$self->{SPC_m1_e1_up} ";
	print "SPC_m2_e1_low=$self->{SPC_m2_e1_low} ";
	print "SPC_m2_e1_up=$self->{SPC_m2_e1_up} ";
	print "SPC_pn_srcregion=$self->{SPC_pn_srcregion} ";
	print "SPC_pn_bkgregion=$self->{SPC_pn_bkgregion} ";
	print "SPC_pn_srcregion_X=$self->{SPC_pn_srcregion_X} ";
	print "SPC_pn_srcregion_Y=$self->{SPC_pn_srcregion_Y} ";
	print "SPC_pn_srcregion_R1=$self->{SPC_pn_srcregion_R1} ";
	print "SPC_pn_srcregion_R2=$self->{SPC_pn_srcregion_R2} ";
	print "SPC_pn_srcregion_XLength=$self->{SPC_pn_srcregion_XLength} ";
	print "SPC_pn_srcregion_YLength=$self->{SPC_pn_srcregion_YLength} ";
	print "SPC_pn_bkgregion_X=$self->{SPC_pn_bkgregion_X} ";
	print "SPC_pn_bkgregion_Y=$self->{SPC_pn_bkgregion_Y} ";
	print "SPC_pn_bkgregion_R1=$self->{SPC_pn_bkgregion_R1} ";
	print "SPC_pn_bkgregion_R2=$self->{SPC_pn_bkgregion_R2} ";
	print "SPC_pn_bkgregion_XLength=$self->{SPC_pn_bkgregion_XLength} ";
	print "SPC_pn_bkgregion_YLength=$self->{SPC_pn_bkgregion_YLength} ";
	print "SPC_pn_areafactor=$self->{SPC_pn_areafactor} ";
	print "SPC_m1_srcregion=$self->{SPC_m1_srcregion} ";
	print "SPC_m1_bkgregion=$self->{SPC_m1_bkgregion} ";
	print "SPC_m1_srcregion_X=$self->{SPC_m1_srcregion_X} ";
	print "SPC_m1_srcregion_Y=$self->{SPC_m1_srcregion_Y} ";
	print "SPC_m1_srcregion_R1=$self->{SPC_m1_srcregion_R1} ";
	print "SPC_m1_srcregion_R2=$self->{SPC_m1_srcregion_R2} ";
	print "SPC_m1_srcregion_XLength=$self->{SPC_m1_srcregion_XLength} ";
	print "SPC_m1_srcregion_YLength=$self->{SPC_m1_srcregion_YLength} ";
	print "SPC_m1_bkgregion_X=$self->{SPC_m1_bkgregion_X} ";
	print "SPC_m1_bkgregion_Y=$self->{SPC_m1_bkgregion_Y} ";
	print "SPC_m1_bkgregion_R1=$self->{SPC_m1_bkgregion_R1} ";
	print "SPC_m1_bkgregion_R2=$self->{SPC_m1_bkgregion_R2} ";
	print "SPC_m1_bkgregion_XLength=$self->{SPC_m1_bkgregion_XLength} ";
	print "SPC_m1_bkgregion_YLength=$self->{SPC_m1_bkgregion_YLength} ";
	print "SPC_m1_areafactor=$self->{SPC_m1_areafactor} ";
	print "SPC_m2_srcregion=$self->{SPC_m2_srcregion} ";
	print "SPC_m2_bkgregion=$self->{SPC_m2_bkgregion} ";
	print "SPC_m2_srcregion_X=$self->{SPC_m2_srcregion_X} ";
	print "SPC_m2_srcregion_Y=$self->{SPC_m2_srcregion_Y} ";
	print "SPC_m2_srcregion_R1=$self->{SPC_m2_srcregion_R1} ";
	print "SPC_m2_srcregion_R2=$self->{SPC_m2_srcregion_R2} ";
	print "SPC_m2_srcregion_XLength=$self->{SPC_m2_srcregion_XLength} ";
	print "SPC_m2_srcregion_YLength=$self->{SPC_m2_srcregion_YLength} ";
	print "SPC_m2_bkgregion_X=$self->{SPC_m2_bkgregion_X} ";
	print "SPC_m2_bkgregion_Y=$self->{SPC_m2_bkgregion_Y} ";
	print "SPC_m2_bkgregion_R1=$self->{SPC_m2_bkgregion_R1} ";
	print "SPC_m2_bkgregion_R2=$self->{SPC_m2_bkgregion_R2} ";
	print "SPC_m2_bkgregion_XLength=$self->{SPC_m2_bkgregion_XLength} ";
	print "SPC_m2_bkgregion_YLength=$self->{SPC_m2_bkgregion_YLength} ";
	print "SPC_m2_areafactor=$self->{SPC_m2_areafactor} ";
	print "SPC_pn_src_expr=$self->{SPC_pn_src_expr} ";
	print "SPC_pn_bkg_expr=$self->{SPC_pn_bkg_expr} ";
	print "SPC_m1_src_expr=$self->{SPC_m1_src_expr} ";
	print "SPC_m1_bkg_expr=$self->{SPC_m1_bkg_expr} ";
	print "SPC_m2_src_expr=$self->{SPC_m2_src_expr} ";
	print "SPC_m2_bkg_expr=$self->{SPC_m2_bkg_expr} ";
######################################
########## RGS VARIABLES #############
######################################    
	print "LC_rgs1_orders=$self->{LC_rgs1_orders} ";	
	print "LC_rgs1_timebinsize=$self->{LC_rgs1_timebinsize} ";
	print "LC_rgs2_orders=$self->{LC_rgs2_orders} ";
	print "LC_rgs2_timebinsize=$self->{LC_rgs2_timebinsize} ";
	print "RGS_withsrc=$self->{RGS_withsrc} ";
	print "RGS_srcstyle=$self->{RGS_srcstyle} ";
	print "RGS_srcra=$self->{RGS_srcra} ";
	print "RGS_srcdec=$self->{RGS_srcdec} ";
	print "RGS_srcdisp=$self->{RGS_srcdisp} ";
	print "RGS_srcxdsp=$self->{RGS_srcxdsp} ";
	print "RGS_srclabel=$self->{RGS_srclabel} ";
	print "RGS_srcrate=$self->{RGS_srcrate} ";
	print "RGS_keepcool=$self->{RGS_keepcool} ";
	print "RGS_rejflags=$self->{RGS_rejflags} ";
	print "RGS_spectrumbinnig=$self->{RGS_spectrumbinnig}\n";	
	print "---> xmmextractor variables <----\n";
}

sub getGlobalVar {
    my $self=shift;
    return $self;
}

##############################################
## methods to access per-object data        ##
##                                          ##
## With args, they set the value.  Without  ##
## any, they only retrieve it/them.         ## 
##############################################

sub SRC_Name {
    my $self=shift;
    if (@_) { $self->{SRC_Name} =shift }
    return $self->{SRC_Name};
}
sub SRC_OBSID {
    my $self=shift;
    if (@_) { $self->{SRC_OBSID} =shift }
    return $self->{SRC_OBSID};
}
sub SRC_EXP {
    my $self=shift;
    if (@_) { $self->{SRC_EXP} =shift }
    return $self->{SRC_EXP};
}
sub WITH_EPIC_SRC_COORDS{ 
    my $self=shift; 
    if (@_) { $self->{WITH_EPIC_SRC_COORDS}=shift }
    return $self->{WITH_EPIC_SRC_COORDS};
}
sub SRC_RA {
    my $self=shift;
    if (@_) { $self->{SRC_RA} =shift }
    return $self->{SRC_RA};
}
sub SRC_DEC {
    my $self=shift;
    if (@_) { $self->{SRC_DEC} =shift }
    return $self->{SRC_DEC};
}

sub EDC_sourcematch {
    my $self=shift;
    if (@_) { $self->{EDC_sourcematch} =shift }
    return $self->{EDC_sourcematch};
}
sub EDC_cameramatch {
    my $self=shift;
    if (@_) { $self->{EDC_cameramatch} =shift }
    return $self->{EDC_cameramatch};
}
sub EDC_pn_ene_low {
    my $self=shift;
    if (@_) { @{ $self->{EDC_pn_ene_low} }=@_ }
    return @{ $self->{EDC_pn_ene_low} };
}
sub EDC_pn_ene_high {
    my $self=shift;
    if (@_) { @{ $self->{EDC_pn_ene_high} }=@_ }
    return @{ $self->{EDC_pn_ene_high} };
}
sub EDC_m1_ene_low {
    my $self=shift;
    if (@_) { @{ $self->{EDC_m1_ene_low} }=@_ }
    return @{ $self->{EDC_m1_ene_low} };
}
sub EDC_m1_ene_high {
    my $self=shift;
    if (@_) { @{ $self->{EDC_m1_ene_high} }=@_ }
    return @{ $self->{EDC_m1_ene_high} };
}
sub EDC_m2_ene_low {
    my $self=shift;
    if (@_) { @{ $self->{EDC_m2_ene_low} }=@_ }
    return @{ $self->{EDC_m2_ene_low} };
}
sub EDC_m2_ene_high {
    my $self=shift;
    if (@_) { @{ $self->{EDC_m2_ene_high} }=@_ }
    return @{ $self->{EDC_m2_ene_high} };
}
sub EDC_pn_likelihood_detection {
    my $self=shift; 
    if (@_) { $self->{EDC_pn_likelihood_detection}=shift }
    return $self->{EDC_pn_likelihood_detection};
}
sub EDC_mos_likelihood_detection {
    my $self=shift; 
    if (@_) { $self->{EDC_mos_likelihood_detection}=shift }
    return $self->{EDC_mos_likelihood_detection};
}
sub OM_sourcematch {
    my $self=shift; 
    if (@_) { $self->{OM_sourcematch}=shift }
    return $self->{OM_sourcematch};
}
sub GTI_optimize_SN_flag {
    my $self=shift; 
    if (@_) { $self->{GTI_optimize_SN_flag}=shift }
    return $self->{GTI_optimize_SN_flag};
}
sub GTI_m1energy_cut {
    my $self=shift; 
    if (@_) { $self->{GTI_m1energy_cut}=shift }
    return $self->{GTI_m1energy_cut};
}
sub GTI_m2energy_cut {
    my $self=shift; 
    if (@_) { $self->{GTI_m2energy_cut}=shift }
    return $self->{GTI_m2energy_cut};
}
sub GTI_pnenergy_cut {
    my $self=shift; 
    if (@_) { $self->{GTI_pnenergy_cut}=shift }
    return $self->{GTI_pnenergy_cut};
}
sub GTI_m1_Rate {
    my $self=shift; 
    if (@_) { $self->{GTI_m1_Rate}=shift }
    return $self->{GTI_m1_Rate};
}
sub GTI_m2_Rate {
    my $self=shift; 
    if (@_) { $self->{GTI_m2_Rate}=shift }
    return $self->{GTI_m2_Rate};
}
sub GTI_pn_Rate {
    my $self=shift; 
    if (@_) { $self->{GTI_pn_Rate}=shift }
    return $self->{GTI_pn_Rate};
}
sub GTI_timebin {
    my $self=shift; 
    if (@_) { $self->{GTI_timebin}=shift }
    return $self->{GTI_timebin};
}


##########################################
#### SIGNAL TO NOISE OPTIMIZATION  #######
#### FOR HIGH BACKGROUND FILTERING #######
########################################## 

sub PG_pn_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion}=shift }
    return $self->{PG_pn_srcregion};
}          
sub PG_pn_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion}=shift }
    return $self->{PG_pn_bkgregion};
}    
sub PG_pn_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_X}=shift }
    return $self->{PG_pn_srcregion_X};
}    
sub PG_pn_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_Y}=shift }
    return $self->{PG_pn_srcregion_Y};
}    
sub PG_pn_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_R1}=shift }
    return $self->{PG_pn_srcregion_R1};
}    
sub PG_pn_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_R2}=shift }
    return $self->{PG_pn_srcregion_R2};
}    
sub PG_pn_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_XLength}=shift }
    return $self->{PG_pn_srcregion_XLength};
}    
sub PG_pn_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_srcregion_YLength}=shift }
    return $self->{PG_pn_srcregion_YLength};
}    
sub PG_pn_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_X}=shift }
    return $self->{PG_pn_bkgregion_X};
}    
sub PG_pn_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_Y}=shift }
    return $self->{PG_pn_bkgregion_Y};
}      
sub PG_pn_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_R1}=shift }
    return $self->{PG_pn_bkgregion_R1};
}    
sub PG_pn_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_R2}=shift }
    return $self->{PG_pn_bkgregion_R2};
}    
sub PG_pn_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_XLength}=shift }
    return $self->{PG_pn_bkgregion_XLength};
}    
sub PG_pn_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkgregion_YLength}=shift }
    return $self->{PG_pn_bkgregion_YLength};
}    
sub PG_pn_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_areafactor}=shift }
    return $self->{PG_pn_areafactor};
}        

sub PG_m1_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion}=shift }
    return $self->{PG_m1_srcregion};
}          
sub PG_m1_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion}=shift }
    return $self->{PG_m1_bkgregion};
}    
sub PG_m1_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_X}=shift }
    return $self->{PG_m1_srcregion_X};
}    
sub PG_m1_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_Y}=shift }
    return $self->{PG_m1_srcregion_Y};
}    
sub PG_m1_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_R1}=shift }
    return $self->{PG_m1_srcregion_R1};
}    
sub PG_m1_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_R2}=shift }
    return $self->{PG_m1_srcregion_R2};
}    
sub PG_m1_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_XLength}=shift }
    return $self->{PG_m1_srcregion_XLength};
}    
sub PG_m1_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_srcregion_YLength}=shift }
    return $self->{PG_m1_srcregion_YLength};
}    
sub PG_m1_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_X}=shift }
    return $self->{PG_m1_bkgregion_X};
}    
sub PG_m1_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_Y}=shift }
    return $self->{PG_m1_bkgregion_Y};
}    
sub PG_m1_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_R1}=shift }
    return $self->{PG_m1_bkgregion_R1};
}    
sub PG_m1_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_R2}=shift }
    return $self->{PG_m1_bkgregion_R2};
}    
sub PG_m1_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_XLength}=shift }
    return $self->{PG_m1_bkgregion_XLength};
}    
sub PG_m1_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkgregion_YLength}=shift }
    return $self->{PG_m1_bkgregion_YLength};
}    
sub PG_m1_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_areafactor}=shift }
    return $self->{PG_m1_areafactor};
}        

sub PG_m2_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion}=shift }
    return $self->{PG_m2_srcregion};
}          
sub PG_m2_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion}=shift }
    return $self->{PG_m2_bkgregion};
}    
sub PG_m2_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_X}=shift }
    return $self->{PG_m2_srcregion_X};
}    
sub PG_m2_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_Y}=shift }
    return $self->{PG_m2_srcregion_Y};
}    
sub PG_m2_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_R1}=shift }
    return $self->{PG_m2_srcregion_R1};
}    
sub PG_m2_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_R2}=shift }
    return $self->{PG_m2_srcregion_R2};
}    
sub PG_m2_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_XLength}=shift }
    return $self->{PG_m2_srcregion_XLength};
}    
sub PG_m2_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_srcregion_YLength}=shift }
    return $self->{PG_m2_srcregion_YLength};
}    
sub PG_m2_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_X}=shift }
    return $self->{PG_m2_bkgregion_X};
}    
sub PG_m2_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_Y}=shift }
    return $self->{PG_m2_bkgregion_Y};
}    
sub PG_m2_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_R1}=shift }
    return $self->{PG_m2_bkgregion_R1};
}    
sub PG_m2_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_R2}=shift }
    return $self->{PG_m2_bkgregion_R2};
}    
sub PG_m2_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_XLength}=shift }
    return $self->{PG_m2_bkgregion_XLength};
}    
sub PG_m2_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkgregion_YLength}=shift }
    return $self->{PG_m2_bkgregion_YLength};
}    
sub PG_m2_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_areafactor}=shift }
    return $self->{PG_m2_areafactor};
}        

sub PG_pn_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_src_expr}=shift }
    return $self->{PG_pn_src_expr};
}

sub PG_pn_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_pn_bkg_expr}=shift }
    return $self->{PG_pn_bkg_expr};
}

sub PG_m1_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_src_expr}=shift }
    return $self->{PG_m1_src_expr};
}
sub PG_m1_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_m1_bkg_expr}=shift }
    return $self->{PG_m1_bkg_expr};
}
sub PG_m2_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_src_expr}=shift }
    return $self->{PG_m2_src_expr};
}
sub PG_m2_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{PG_m2_bkg_expr}=shift }
    return $self->{PG_m2_bkg_expr};
}

sub PG_timebinning{
    my $self=shift; 
    if (@_) { $self->{PG_timebinning}=shift }
    return $self->{PG_timebinning};
}
sub PG_timestart{
    my $self=shift; 
    if (@_) { $self->{PG_timestart}=shift }
    return $self->{PG_timestart};
}
sub PG_timeend{
    my $self=shift; 
    if (@_) { $self->{PG_timeend}=shift }
    return $self->{PG_timeend};
}
sub PG_minpi{
    my $self=shift; 
    if (@_) { $self->{PG_minpi}=shift }
    return $self->{PG_minpi};
}      
sub PG_maxpi{
    my $self=shift; 
    if (@_) { $self->{PG_maxpi}=shift }
    return $self->{PG_maxpi};
}      




####################################
######	LIGHTCURVE PARAMETERS ######
####################################

sub LC_pn_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_interactivity}=shift }
    return $self->{LC_pn_interactivity};
} 

sub LC_m1_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_interactivity}=shift }
    return $self->{LC_m1_interactivity};
} 

sub LC_m2_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_interactivity}=shift }
    return $self->{LC_m2_interactivity};
} 

sub LC_pn_exposure{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_exposure}=shift }
    return $self->{LC_pn_exposure};
} 

sub LC_m1_exposure{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_exposure}=shift }
    return $self->{LC_m1_exposure};
} 

sub LC_m2_exposure{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_exposure}=shift }
    return $self->{LC_m2_exposure};
} 

sub display_ds9_LC_pn_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_LC_pn_exposure}=shift }
    return $self->{display_ds9_LC_pn_exposure};
} 

sub display_ds9_LC_m1_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_LC_m1_exposure}=shift }
    return $self->{display_ds9_LC_m1_exposure};
} 

sub display_ds9_LC_m2_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_LC_m2_exposure}=shift }
    return $self->{display_ds9_LC_m2_exposure};
} 


sub LC_pn_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_e1_low}=shift }
    return $self->{LC_pn_e1_low};
}  
sub LC_pn_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_e1_up}=shift }
    return $self->{LC_pn_e1_up};
}  
  
sub LC_m1_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_e1_low}=shift }
    return $self->{LC_m1_e1_low};
}  
sub LC_m1_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_e1_up}=shift }
    return $self->{LC_m1_e1_up};
}  
  
sub LC_m2_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_e1_low}=shift }
    return $self->{LC_m2_e1_low};
}  
sub LC_m2_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_e1_up}=shift }
    return $self->{LC_m2_e1_up};
}  
  
sub LC_pn_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion}=shift }
    return $self->{LC_pn_srcregion};
}          
sub LC_pn_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion}=shift }
    return $self->{LC_pn_bkgregion};
}    
sub LC_pn_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_X}=shift }
    return $self->{LC_pn_srcregion_X};
}    
sub LC_pn_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_Y}=shift }
    return $self->{LC_pn_srcregion_Y};
}    
sub LC_pn_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_R1}=shift }
    return $self->{LC_pn_srcregion_R1};
}    
sub LC_pn_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_R2}=shift }
    return $self->{LC_pn_srcregion_R2};
}    
sub LC_pn_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_XLength}=shift }
    return $self->{LC_pn_srcregion_XLength};
}    
sub LC_pn_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_srcregion_YLength}=shift }
    return $self->{LC_pn_srcregion_YLength};
}    
sub LC_pn_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_X}=shift }
    return $self->{LC_pn_bkgregion_X};
}    
sub LC_pn_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_Y}=shift }
    return $self->{LC_pn_bkgregion_Y};
}      
sub LC_pn_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_R1}=shift }
    return $self->{LC_pn_bkgregion_R1};
}    
sub LC_pn_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_R2}=shift }
    return $self->{LC_pn_bkgregion_R2};
}    
sub LC_pn_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_XLength}=shift }
    return $self->{LC_pn_bkgregion_XLength};
}    
sub LC_pn_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkgregion_YLength}=shift }
    return $self->{LC_pn_bkgregion_YLength};
}    
sub LC_pn_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_areafactor}=shift }
    return $self->{LC_pn_areafactor};
}        

sub LC_m1_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion}=shift }
    return $self->{LC_m1_srcregion};
}          
sub LC_m1_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion}=shift }
    return $self->{LC_m1_bkgregion};
}    
sub LC_m1_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_X}=shift }
    return $self->{LC_m1_srcregion_X};
}    
sub LC_m1_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_Y}=shift }
    return $self->{LC_m1_srcregion_Y};
}    
sub LC_m1_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_R1}=shift }
    return $self->{LC_m1_srcregion_R1};
}    
sub LC_m1_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_R2}=shift }
    return $self->{LC_m1_srcregion_R2};
}    
sub LC_m1_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_XLength}=shift }
    return $self->{LC_m1_srcregion_XLength};
}    
sub LC_m1_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_srcregion_YLength}=shift }
    return $self->{LC_m1_srcregion_YLength};
}    
sub LC_m1_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_X}=shift }
    return $self->{LC_m1_bkgregion_X};
}    
sub LC_m1_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_Y}=shift }
    return $self->{LC_m1_bkgregion_Y};
}    
sub LC_m1_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_R1}=shift }
    return $self->{LC_m1_bkgregion_R1};
}    
sub LC_m1_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_R2}=shift }
    return $self->{LC_m1_bkgregion_R2};
}    
sub LC_m1_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_XLength}=shift }
    return $self->{LC_m1_bkgregion_XLength};
}    
sub LC_m1_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkgregion_YLength}=shift }
    return $self->{LC_m1_bkgregion_YLength};
}    
sub LC_m1_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_areafactor}=shift }
    return $self->{LC_m1_areafactor};
}        

sub LC_m2_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion}=shift }
    return $self->{LC_m2_srcregion};
}          
sub LC_m2_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion}=shift }
    return $self->{LC_m2_bkgregion};
}    
sub LC_m2_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_X}=shift }
    return $self->{LC_m2_srcregion_X};
}    
sub LC_m2_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_Y}=shift }
    return $self->{LC_m2_srcregion_Y};
}    
sub LC_m2_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_R1}=shift }
    return $self->{LC_m2_srcregion_R1};
}    
sub LC_m2_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_R2}=shift }
    return $self->{LC_m2_srcregion_R2};
}    
sub LC_m2_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_XLength}=shift }
    return $self->{LC_m2_srcregion_XLength};
}    
sub LC_m2_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_srcregion_YLength}=shift }
    return $self->{LC_m2_srcregion_YLength};
}    
sub LC_m2_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_X}=shift }
    return $self->{LC_m2_bkgregion_X};
}    
sub LC_m2_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_Y}=shift }
    return $self->{LC_m2_bkgregion_Y};
}    
sub LC_m2_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_R1}=shift }
    return $self->{LC_m2_bkgregion_R1};
}    
sub LC_m2_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_R2}=shift }
    return $self->{LC_m2_bkgregion_R2};
}    
sub LC_m2_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_XLength}=shift }
    return $self->{LC_m2_bkgregion_XLength};
}    
sub LC_m2_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkgregion_YLength}=shift }
    return $self->{LC_m2_bkgregion_YLength};
}    
sub LC_m2_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_areafactor}=shift }
    return $self->{LC_m2_areafactor};
}  
      
sub LC_pn_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_src_expr}=shift }
    return $self->{LC_pn_src_expr};
}

sub LC_pn_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_bkg_expr}=shift }
    return $self->{LC_pn_bkg_expr};
}

sub LC_m1_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_src_expr}=shift }
    return $self->{LC_m1_src_expr};
}
sub LC_m1_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_bkg_expr}=shift }
    return $self->{LC_m1_bkg_expr};
}
sub LC_m2_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_src_expr}=shift }
    return $self->{LC_m2_src_expr};
}
sub LC_m2_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_bkg_expr}=shift }
    return $self->{LC_m2_bkg_expr};
}
 
 
 sub LC_pn_timebinsize{ 
    my $self=shift; 
    if (@_) { $self->{LC_pn_timebinsize}=shift }
    return $self->{LC_pn_timebinsize};
}

sub LC_m1_timebinsize{ 
    my $self=shift; 
    if (@_) { $self->{LC_m1_timebinsize}=shift }
    return $self->{LC_m1_timebinsize};
}

sub LC_m2_timebinsize{ 
    my $self=shift; 
    if (@_) { $self->{LC_m2_timebinsize}=shift }
    return $self->{LC_m2_timebinsize};
}


####################################
##### SPECTRA PARAMETERS ###########
####################################

sub SPC_pn_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_interactivity}=shift }
    return $self->{SPC_pn_interactivity};
} 

sub SPC_m1_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_interactivity}=shift }
    return $self->{SPC_m1_interactivity};
} 

sub SPC_m2_interactivity{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_interactivity}=shift }
    return $self->{SPC_m2_interactivity};
} 

sub SPC_pn_exposure{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_exposure}=shift }
    return $self->{SPC_pn_exposure};
} 

sub SPC_m1_exposure{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_exposure}=shift }
    return $self->{SPC_m1_exposure};
} 

sub SPC_m2_exposure{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_exposure}=shift }
    return $self->{SPC_m2_exposure};
} 

sub display_ds9_SPC_pn_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_SPC_pn_exposure}=shift }
    return $self->{display_ds9_SPC_pn_exposure};
} 

sub display_ds9_SPC_m1_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_SPC_m1_exposure}=shift }
    return $self->{display_ds9_SPC_m1_exposure};
} 

sub display_ds9_SPC_m2_exposure{ 
    my $self=shift; 
    if (@_) { $self->{display_ds9_SPC_m2_exposure}=shift }
    return $self->{display_ds9_SPC_m2_exposure};
} 

sub SPC_pn_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_e1_low}=shift }
    return $self->{SPC_pn_e1_low};
}  
sub SPC_pn_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_e1_up}=shift }
    return $self->{SPC_pn_e1_up};
}  
  
sub SPC_m1_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_e1_low}=shift }
    return $self->{SPC_m1_e1_low};
}  
sub SPC_m1_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_e1_up}=shift }
    return $self->{SPC_m1_e1_up};
}  
  
sub SPC_m2_e1_low{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_e1_low}=shift }
    return $self->{SPC_m2_e1_low};
}  
sub SPC_m2_e1_up{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_e1_up}=shift }
    return $self->{SPC_m2_e1_up};
}  
sub SPC_pn_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion}=shift }
    return $self->{SPC_pn_srcregion};
}          
sub SPC_pn_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion}=shift }
    return $self->{SPC_pn_bkgregion};
}    
sub SPC_pn_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_X}=shift }
    return $self->{SPC_pn_srcregion_X};
}    
sub SPC_pn_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_Y}=shift }
    return $self->{SPC_pn_srcregion_Y};
}    
sub SPC_pn_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_R1}=shift }
    return $self->{SPC_pn_srcregion_R1};
}    
sub SPC_pn_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_R2}=shift }
    return $self->{SPC_pn_srcregion_R2};
}    
sub SPC_pn_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_XLength}=shift }
    return $self->{SPC_pn_srcregion_XLength};
}    
sub SPC_pn_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_srcregion_YLength}=shift }
    return $self->{SPC_pn_srcregion_YLength};
}    
sub SPC_pn_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_X}=shift }
    return $self->{SPC_pn_bkgregion_X};
}    
sub SPC_pn_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_Y}=shift }
    return $self->{SPC_pn_bkgregion_Y};
}      
sub SPC_pn_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_R1}=shift }
    return $self->{SPC_pn_bkgregion_R1};
}    
sub SPC_pn_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_R2}=shift }
    return $self->{SPC_pn_bkgregion_R2};
}    
sub SPC_pn_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_XLength}=shift }
    return $self->{SPC_pn_bkgregion_XLength};
}    
sub SPC_pn_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkgregion_YLength}=shift }
    return $self->{SPC_pn_bkgregion_YLength};
}    
sub SPC_pn_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_areafactor}=shift }
    return $self->{SPC_pn_areafactor};
}        

sub SPC_m1_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion}=shift }
    return $self->{SPC_m1_srcregion};
}          
sub SPC_m1_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion}=shift }
    return $self->{SPC_m1_bkgregion};
}    
sub SPC_m1_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_X}=shift }
    return $self->{SPC_m1_srcregion_X};
}    
sub SPC_m1_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_Y}=shift }
    return $self->{SPC_m1_srcregion_Y};
}    
sub SPC_m1_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_R1}=shift }
    return $self->{SPC_m1_srcregion_R1};
}    
sub SPC_m1_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_R2}=shift }
    return $self->{SPC_m1_srcregion_R2};
}    
sub SPC_m1_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_XLength}=shift }
    return $self->{SPC_m1_srcregion_XLength};
}    
sub SPC_m1_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_srcregion_YLength}=shift }
    return $self->{SPC_m1_srcregion_YLength};
}    
sub SPC_m1_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_X}=shift }
    return $self->{SPC_m1_bkgregion_X};
}    
sub SPC_m1_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_Y}=shift }
    return $self->{SPC_m1_bkgregion_Y};
}    
sub SPC_m1_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_R1}=shift }
    return $self->{SPC_m1_bkgregion_R1};
}    
sub SPC_m1_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_R2}=shift }
    return $self->{SPC_m1_bkgregion_R2};
}    
sub SPC_m1_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_XLength}=shift }
    return $self->{SPC_m1_bkgregion_XLength};
}    
sub SPC_m1_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkgregion_YLength}=shift }
    return $self->{SPC_m1_bkgregion_YLength};
}    
sub SPC_m1_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_areafactor}=shift }
    return $self->{SPC_m1_areafactor};
}        

sub SPC_m2_srcregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion}=shift }
    return $self->{SPC_m2_srcregion};
}          
sub SPC_m2_bkgregion{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion}=shift }
    return $self->{SPC_m2_bkgregion};
}    
sub SPC_m2_srcregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_X}=shift }
    return $self->{SPC_m2_srcregion_X};
}    
sub SPC_m2_srcregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_Y}=shift }
    return $self->{SPC_m2_srcregion_Y};
}    
sub SPC_m2_srcregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_R1}=shift }
    return $self->{SPC_m2_srcregion_R1};
}    
sub SPC_m2_srcregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_R2}=shift }
    return $self->{SPC_m2_srcregion_R2};
}    
sub SPC_m2_srcregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_XLength}=shift }
    return $self->{SPC_m2_srcregion_XLength};
}    
sub SPC_m2_srcregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_srcregion_YLength}=shift }
    return $self->{SPC_m2_srcregion_YLength};
}    
sub SPC_m2_bkgregion_X{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_X}=shift }
    return $self->{SPC_m2_bkgregion_X};
}    
sub SPC_m2_bkgregion_Y{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_Y}=shift }
    return $self->{SPC_m2_bkgregion_Y};
}    
sub SPC_m2_bkgregion_R1{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_R1}=shift }
    return $self->{SPC_m2_bkgregion_R1};
}    
sub SPC_m2_bkgregion_R2{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_R2}=shift }
    return $self->{SPC_m2_bkgregion_R2};
}    
sub SPC_m2_bkgregion_XLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_XLength}=shift }
    return $self->{SPC_m2_bkgregion_XLength};
}    
sub SPC_m2_bkgregion_YLength{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkgregion_YLength}=shift }
    return $self->{SPC_m2_bkgregion_YLength};
}    
sub SPC_m2_areafactor{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_areafactor}=shift }
    return $self->{SPC_m2_areafactor};
}        

sub SPC_pn_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_src_expr}=shift }
    return $self->{SPC_pn_src_expr};
}

sub SPC_pn_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkg_expr}=shift }
    return $self->{SPC_pn_bkg_expr};
}

sub SPC_m1_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_src_expr}=shift }
    return $self->{SPC_m1_src_expr};
}
sub SPC_m1_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkg_expr}=shift }
    return $self->{SPC_m1_bkg_expr};
}
sub SPC_m2_src_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_src_expr}=shift }
    return $self->{SPC_m2_src_expr};
}
sub SPC_m2_bkg_expr{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkg_expr}=shift }
    return $self->{SPC_m2_bkg_expr};
}

sub SPC_pn_src_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_src_ds9region_file}=shift }
    return $self->{SPC_pn_src_ds9region_file};
}

sub SPC_pn_bkg_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_pn_bkg_ds9region_file}=shift }
    return $self->{SPC_pn_bkg_ds9region_file};
}

sub SPC_m1_src_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_src_ds9region_file}=shift }
    return $self->{SPC_m1_src_ds9region_file};
}
sub SPC_m1_bkg_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m1_bkg_ds9region_file}=shift }
    return $self->{SPC_m1_bkg_ds9region_file};
}
sub SPC_m2_src_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_src_ds9region_file}=shift }
    return $self->{SPC_m2_src_ds9region_file};
}
sub SPC_m2_bkg_ds9region_file{ 
    my $self=shift; 
    if (@_) { $self->{SPC_m2_bkg_ds9region_file}=shift }
    return $self->{SPC_m2_bkg_ds9region_file};
}

####################################
##### SPECTRA PARAMETERS ###########
####################################


sub LC_rgs1_orders{ 
    my $self=shift; 
    if (@_) { $self->{LC_rgs1_orders}=shift }
    return $self->{LC_rgs1_orders};
} 

sub LC_rgs1_timebinsize{ 
    my $self=shift; 
    if (@_) { $self->{LC_rgs1_timebinsize}=shift }
    return $self->{LC_rgs1_timebinsize};
}

sub LC_rgs2_orders{ 
    my $self=shift; 
    if (@_) { $self->{LC_rgs2_orders}=shift }
    return $self->{LC_rgs2_orders};
} 

sub LC_rgs2_timebinsize{ 
    my $self=shift; 
    if (@_) { $self->{LC_rgs2_timebinsize}=shift }
    return $self->{LC_rgs2_timebinsize};
}

sub EPN{ 
    my $self=shift; 
    if (@_) { $self->{EPN}=shift }
    return $self->{EPN};
}

sub EPN_exposures {
    my $self=shift;
    if (@_) { @{ $self->{EPN_exposures} }=@_ }
    return @{ $self->{EPN_exposures} };
}
sub EMOS1{ 
    my $self=shift; 
    if (@_) { $self->{EMOS1}=shift }
    return $self->{EMOS1};
}
sub EMOS1_exposures {
    my $self=shift;
    if (@_) { @{ $self->{EMOS1_exposures} }=@_ }
    return @{ $self->{EMOS1_exposures} };
}

sub EMOS2{ 
    my $self=shift; 
    if (@_) { $self->{EMOS2}=shift }
    return $self->{EMOS2};
}
sub EMOS2_exposures {
    my $self=shift;
    if (@_) { @{ $self->{EMOS2_exposures} }=@_ }
    return @{ $self->{EMOS2_exposures} };
}

sub RGS{ 
    my $self=shift; 
    if (@_) { $self->{RGS}=shift }
    return $self->{RGS};
}
sub RGS_exposures {
    my $self=shift;
    if (@_) { @{ $self->{RGS_exposures} }=@_ }
    return @{ $self->{RGS_exposures} };
}

sub OM{ 
    my $self=shift; 
    if (@_) { $self->{OM}=shift }
    return $self->{OM};
}
sub OM_exposures {
    my $self=shift;
    if (@_) { @{ $self->{OM_exposures} }=@_ }
    return @{ $self->{OM_exposures} };
}

sub epic_instrument{ 
    my $self=shift; 
    if (@_) { $self->{epic_instrument}=shift }
    return $self->{epic_instrument};
}

sub ANA_epatplot{ 
    my $self=shift; 
    if (@_) { $self->{ANA_epatplot}=shift }
    return $self->{ANA_epatplot};
}
 

 

sub RGS_withsrc{ 
    my $self=shift; 
    if (@_) { $self->{RGS_withsrc}=shift }
    return $self->{RGS_withsrc};
}

sub RGS_srcstyle{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcstyle}=shift }
    return $self->{RGS_srcstyle};
}

sub RGS_srcra{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcra}=shift }
    return $self->{RGS_srcra};
}

sub RGS_srcdec{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcdec}=shift }
    return $self->{RGS_srcdec};
}

sub RGS_srcdisp{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcdisp}=shift }
    return $self->{RGS_srcdisp};
}

sub RGS_srcxdsp{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcxdsp}=shift }
    return $self->{RGS_srcxdsp};
}

sub RGS_srclabel{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srclabel}=shift }
    return $self->{RGS_srclabel};
}

sub RGS_srcrate{ 
    my $self=shift; 
    if (@_) { $self->{RGS_srcrate}=shift }
    return $self->{RGS_srcrate};
}	

sub RGS_keepcool{ 
    my $self=shift; 
    if (@_) { $self->{RGS_keepcool}=shift }
    return $self->{RGS_keepcool};
}	

sub RGS_rejflags{ 
    my $self=shift; 
    if (@_) { $self->{RGS_rejflags}=shift }
    return $self->{RGS_rejflags};
}		
	
sub RGS_spectrumbinnig{ 
    my $self=shift; 
    if (@_) { $self->{RGS_spectrumbinnig}=shift }
    return $self->{RGS_spectrumbinnig};
}		

1;
