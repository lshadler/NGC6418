#!/bin/bash

#---input files
evtfile=${1}   #mandatory
ootfile=${2}   #not mand. (def='')
attfile=${3}   #mandatory for mosaic-mode or if exposures are calculated (def='')
fwcfile=${4}   #mandatory
gtifile=${5}   #not mand. (def='')

#---setup
lenoise=${6}
exposure=${7}
mask=${8}
threshold1=${9}
threshold2=${10}


# at the moment, the following parameters are defined separately 
# (and not as an "expression"-string, since some must not be used below for individual selections (e.g. is the user selects FLAG==0, no events outside the FoV can be selected to scale the detector-background images)
pimin=${11}
pimax=${12}
patmin=${13}
patmax=${14}
flag=${15}
flag_corner=${16}


#---further image parameters, definition analogously as for attcalc
withattcalc=${17} #boolean
nominalra=${18}   #not mand. def=''
nominaldec=${19}  #not mand. def=''
imagesize=${20}   #not mand. def=''

withbadpixupdate=${21}
usefwc=${22}            
withwindowmode=${23}    


#---image parameters analogously as for evselect (might be modified e.g. to calculate mosaic images)
# ximagemin=1
# ximagemax=640
# yimagemin=1
# yimagemax=640
# imagebinning=binSize
# ximagebinsize=40
# yimagebinsize=40
# ximagesize=600
# yimagesize=600
# squarepixels=no
# raimagecenter=0
# decimagecenter=0
# imagedatatype=Real64
# withimagedatatype=no 
# withcelestialcenter=no
# withxranges=no
# withyranges=no 
# im="updateexposure=yes writedss=yes withimageset=yes xcolumn=X ycolumn=Y squarepixels=${squarepixels} imagebinning=${imagebinning} ximagebinsize=${ximagebinsize} yimagebinsize=${yimagebinsize} ximagesize=${ximagesize} yimagesize=${yimagesize} ximagemin=${ximagemin} yimagemin=${yimagemin} withxranges=${withxranges} withyranges=${withyranges} ximagemax=${ximagemax} yimagemax=${yimagemax} withcelestialcenter=${withcelestialcenter} raimagecenter=${raimagecenter} decimagecenter=${decimagecenter} imagedatatype=${imagedatatype} withimagedatatype=${withimagedatatype}"

im=${24}






#---output strings
prefix="eimageget:"
warning_prefix="eimageget: WARNING:"
error_prefix="eimageget: ERROR:"


#---other local variables:
ccds=({x,01,02,03,04,05,06,07,08,09,10,11,12})
ccd_used=({1,1,1,1,1,1,1,1,1,1,1,1,1})    # 0: ccd not used,   1: ccd used in all images,   2: ccd not used in fwc-images but in all other images
LENOIS=({0,0,0,0,0,0,0,0,0,0,0,0,0})  

# regions for EPIC detector corners:
reg_corners_pn='((DETX,DETY) IN polygon(-13118.214,14388.613,-13133.5,13602.5,-14433.5,12642.5,-15453.5,11452.5,-16183.5,10572.5,-17133.5,9342.5,-17443.5,8832.5,-17913.5,8142.5,-18093.5,7792.5,-18233.5,7792.5,-18248.471,14388.613)||(DETX,DETY) IN polygon(-17863.5,-10507.5,-16973.5,-11787.5,-16023.5,-13007.5,-14803.5,-14377.5,-13803.5,-15257.5,-13123.5,-15637.5,-13123.5,-16607.5,-18206.04,-16610.933,-18203.5,-9967.5,-18083.5,-9967.5)||(DETX,DETY) IN polygon(13636.5,-10017.5,13836.5,-10007.5,13836.5,-16607.5,8716.5,-16607.5,8716.5,-15807.5,9556.5,-15127.5,10666.5,-14027.5,11746.5,-12927.5,12516.5,-11857.5,13256.5,-10787.5)||(DETX,DETY) IN polygon(8716.5,13412.5,8716.5,14392.5,13836.5,14392.5,13836.5,7792.5,13506.5,8192.5,12996.5,9022.5,12266.5,10072.5,11766.5,10692.5,10856.5,11692.5,9896.5,12532.5,8916.5,13252.5))'

reg_corners_m1='((DETX,DETY) IN polygon(250.5,-17689.5,6393.988,-17632.868,6493.988,-17032.868,7753.988,-16522.868,9733.988,-15472.868,11843.988,-13972.868,13043.988,-12892.868,13043.988,-17642.868,2730.5,-19419.5,250.5,-19489.5)||(DETX,DETY) IN polygon(-19729.5,6390.5,-15819.5,6400.5,-16229.5,6000.5,-16669.5,5290.5,-17119.5,3970.5,-17319.5,2910.5,-17546.012,1667.1316,-17736.012,67.131579,-17626.012,-1382.8684,-17556.012,-3042.8684,-17109.5,-5329.5,-16509.5,-6589.5,-19726.012,-6602.8684)||(DETX,DETY) IN polygon(16753.988,-5842.8684,17303.988,-4012.8684,17683.988,-1742.8684,17633.988,1397.1316,17333.988,3517.1316,16753.988,5417.1316,16213.988,6217.1316,19833.988,6217.1316,19813.988,-6742.8684,16243.988,-6752.8684)||(DETX,DETY) IN polygon(-38.5,19634.5,-38.5,17204.5,-2589.5,17040.5,-5219.5,16430.5,-7019.5,15780.5,-8369.5,15090.5,-10209.5,13990.5,-11679.5,12750.5,-12906.012,11517.132,-12906.012,19637.132)||(DETX,DETY) IN polygon(-13076.012,-11752.868,-11576.012,-13312.868,-9896.012,-14602.868,-7976.012,-15822.868,-5729.5,-16869.5,-5719.5,-17579.5,-299.5,-17639.5,-289.5,-19539.5,-2389.5,-19499.5,-8369.5,-18699.5,-10099.5,-18199.5,-13066.012,-17832.868)||(DETX,DETY) IN polygon(373.98804,19547.132,13033.988,19537.132,13043.988,12317.132,11803.988,13477.132,10323.988,14527.132,8503.988,15637.132,6013.988,16617.132,3133.988,17257.132,353.98804,17327.132))'


reg_corners_m2='((DETX,DETY) IN polygon(250.5,-17689.5,5850.5,-17639.5,5850.5,-17039.5,7780.5,-16089.5,9670.5,-14979.5,11760.5,-13509.5,13070.5,-12139.5,13080.5,-17579.5,2730.5,-19419.5,250.5,-19489.5)||(DETX,DETY) IN polygon(-19729.5,6390.5,-15819.5,6400.5,-16229.5,6000.5,-16669.5,5290.5,-17119.5,3970.5,-17319.5,2910.5,-17479.5,1630.5,-17539.5,130.5,-17539.5,-1399.5,-17409.5,-2659.5,-17259.5,-4209.5,-17109.5,-5329.5,-16509.5,-6589.5,-19779.5,-6599.5)||(DETX,DETY) IN polygon(16480.5,-5419.5,17060.5,-3669.5,17230.5,-1859.5,17420.5,60.5,17195.5,2134.5,16715.5,4414.5,15880.5,6240.5,19820.5,6220.5,19890.5,-6639.5,16030.5,-6609.5)||(DETX,DETY) IN polygon(-13039.5,19650.5,-29.5,19640.5,-39.5,17070.5,-2589.5,17040.5,-5219.5,16430.5,-7019.5,15780.5,-8369.5,15090.5,-10209.5,13990.5,-11679.5,12750.5,-13089.5,11320.5)||(DETX,DETY) IN polygon(-13189.5,-11719.5,-11619.5,-13489.5,-9969.5,-14709.5,-8019.5,-15889.5,-5729.5,-16869.5,-5719.5,-17579.5,-299.5,-17639.5,-289.5,-19539.5,-2389.5,-19499.5,-8369.5,-18699.5,-10099.5,-18199.5,-13149.5,-17889.5)||(DETX,DETY) IN polygon(230.5,19590.5,13047.5,19594.5,13040.5,11660.5,11440.5,13250.5,9890.5,14380.5,8170.5,15370.5,5780.5,16410.5,3120.5,17140.5,220.5,17230.5))'





#----test input

if [ -z "${evtfile}" ]; then
    echo "${error_prefix} evtfile is not defined"; exit
else
    if  [ ! -e ${evtfile} ] ; then
        echo "${error_prefix} ${evtfile} (event file) not found"; exit
    fi  
fi


if [ ${usefwc} = 1 ]; then   
    if [ -z "${fwcfile}" ]; then
        echo "${error_prefix} fwcfile is not defined"; exit
    else
        if  [ ! -e ${fwcfile} ] ; then
            echo "${error_prefix} ${fwcfile} (filter-whele-closed file) not found"; exit
        fi      
    fi
fi

if [ -z "${ootfile}" ]; then
    useoot=0  #a warning for pn-exposures will be given below
else
    if  [ ! -e ${ootfile} ] ; then
        echo "${error_prefix} ${ootfile} (out-of-time file) not found"; exit
    else useoot=1
    fi  
fi

if [ -z "${gtifile}" ]; then
    usegti=0  
    echo "${warning_prefix} no good-time-interval file defined, no time selection will be applied"
else
    if  [ ! -e ${gtifile} ] ; then
        echo "${error_prefix} ${gtifile} (good-time-interval file) not found"; exit
    else usegti=1
    fi  
fi

if [ -z "${attfile}" ]; then
    if [ ${withattcalc} == 1 ] ; then echo "${error_prefix} withattcalc is set to \"yes\", but no attfile is defined"; exit; fi
    if [ ${exposure} == 1 ] ; then echo "${error_prefix} withexposure is set to \"yes\", but no attfile is defined"; exit; fi
else
    if  [ ! -e ${attfile} ] ; then
        if [ ${withattcalc} == 1 ] ; then echo "${error_prefix} withattcalc is set to \"yes\", but ${attfile} (attitude file) not found"; exit;fi
        if [ ${exposure} == 1 ] ; then echo "${error_prefix} withexposure is set to \"yes\", but ${attfile} (attitude file) not found"; exit;fi
    fi  
fi
 

if [ \( ! -n "$nominalra" \) -a \( ${withattcalc} == 1 \) ] ; then echo "${error_prefix} withattcalc is set to \"yes\", but parameter nominalra is not given"; exit; fi
if [ \( ! -n "$nominaldec" \) -a \( ${withattcalc} == 1 \) ] ; then echo "${error_prefix} withattcalc is set to \"yes\", but parameter nominaldec is not given"; exit; fi
if [ \( ! -n "$imagesize" \) -a \( ${withattcalc} == 1 \) ] ; then echo "${error_prefix} withattcalc is set to \"yes\", but parameter imagesize is not given"; exit; fi
if [ ${mask} = 1 -a ${exposure} = 0 ]; then echo "${warning_prefix} withmaskset is set to \"yes\", but withexposure is set to \"no\": No mask will be created";fi








#-------get some information from the eventfile

fkeypar ${evtfile}[0] OBS_ID
obsid=`pget fkeypar.par value`
obsid=${obsid//\'/}

fkeypar ${evtfile}[0] EXPIDSTR
expid=`pget fkeypar.par value`
expid=${expid//\'/}


fkeypar ${evtfile}[0] INSTRUME
inst=`pget fkeypar.par value`
if [ ${inst} = "'EPN'" ]; then     
    ID_INST=0
    ccdmax=12
    corner=$reg_corners_pn
    if [ ! -n "${flag}" ]; then flag="FLAG == 0" ; fi
    if [ ! -n "${flag_corner}" ]; then flag_corner="((FLAG & 0xcfa0000) == 0)" ; fi
    output_prefix=P${obsid}PN${expid}_
    if [ ${useoot} = 0 ] ; then echo "${warning_prefix} No out-of-time file is defined, although the instrument is EPIC-pn";  fi

elif [ ${inst} = "'EMOS1'" ]; then 
    ID_INST=1
    ccdmax=7
    corner=$reg_corners_m1
    if [ ! -n "${flag}" ]; then flag="((FLAG & 0x766ba000) == 0)" ; fi
    if [ ! -n "${flag_corner}" ]; then flag_corner="((FLAG & 0x766aa000) == 0)" ; fi
    output_prefix=P${obsid}M1${expid}_

elif [ ${inst} = "'EMOS2'" ]; then 
    ID_INST=2
    ccdmax=7
    corner=$reg_corners_m2 
    output_prefix=P${obsid}M2${expid}_
    if [ ! -n "${flag}" ]; then flag="((FLAG & 0x766ba000) == 0)" ; fi
    if [ ! -n "${flag_corner}" ]; then flag_corner="((FLAG & 0x766aa000) == 0)" ; fi
else echo "${error_prefix} instrument not recognised"  ; exit 
fi

fkeypar ${evtfile}[0] SUBMODE
submode=`pget fkeypar value`

#test if FWC file matches the event file
if [ ${usefwc} = 1 ]; then   
    fkeypar ${fwcfile}[0] INSTRUME
    inst_fwc=`pget fkeypar.par value`
    
    if [ ${inst} != ${inst_fwc} ]; then 
        echo "${error_prefix} evtfile and fwcfile are not from the same instrument (${inst} vs. ${inst_fwc})"  ; exit 
    fi
    
    fkeypar ${fwcfile}[0] SUBMODE
    submode_fwc=`pget fkeypar value`
    if [ "${submode}" != "${submode_fwc}" ]; then echo "${warning_prefix} Found different modes for evtfile and fwcfile (${submode} vs. ${submode_fwc})"; fi
fi



if [ ${ID_INST} = 0 ] ; then
    if [ ${submode} = "'PrimeFullWindow'" ]; then               submode=full-frame          ;   factoot=0.063
    elif [ ${submode} = "'PrimeFullWindowExtended'" ]; then     submode=extended-full-frame ;   factoot=0.0232
    elif [ ${submode} = "'PrimeLargeWindow'" ]; then            submode=large-window        ;   factoot=0.0015
    elif [ ${submode} = "'PrimeSmallWindow'" ]; then            submode=small-window        ;   factoot=0.011
    else 
        echo "${error_prefix} EPIC-pn mode (${submode}) not supported"
        exit
    fi
    echo "${prefix} EPIC-pn in ${submode} mode, out-of-time images will be weighted with ${factoot}"
    if [ ${submode} = 'large-window' -o ${submode} = 'small-window' ]; then
        if [ ${withwindowmode} = 0 ]; then
            echo "${error_prefix} EPIC-pn is in ${submode} mode. Filter-wheel-closed images cannot be created. Set withwindowmode to 'yes' to create the other image types"
            exit
        elif [ ${withwindowmode} = 1 ]; then
            if [ ${usefwc} = 1 ]; then   
                usefwc=0
                echo "${warning_prefix} EPIC-pn is in ${submode} mode. No filter-wheel-closed images will be created."
            fi
        fi
    fi
elif [ ${ID_INST} = 1 -o ${ID_INST} = 2 ]; then 
    if [ ${submode} = "'PrimeFullWindow'" ]; then      submode='full-frame'    
    elif [ ${submode} = "'PrimePartialW2'" ]; then     submode='small-window'  
    elif [ ${submode} = "'PrimePartialW3'" ]; then     submode='large-window'  
    elif [ ${submode} = "'FastUncompressed'" ]; then   submode='timing'        
    fi
fi








fkeypar ${evtfile}[0] RA_PNT
ra_pnt=`pget fkeypar value`
fkeypar ${evtfile}[0] DEC_PNT
de_pnt=`pget fkeypar value`
fkeypar ${evtfile}[0] PA_PNT 
pa_pnt=`pget fkeypar value`




#---build array from strings of pimin, pimax, patmin, patmax
i=0; j=0
for pi in ${pimin}; do pimin[${i}]=$pi; i=$((${i}+1)); done
for pi in ${pimax}; do pimax[${j}]=$pi; j=$((${j}+1)); done
if [ ${i} -ne ${j} ]; then echo "${error_prefix} Number of energy bands of pimin and pimax inconsistent"; exit; fi

if [ ! -n "${patmin}" ]; then 
    for (( j=0; j<${i}; j++ )); do  patmin[${j}]=0; done
else
    j=0
    for pat in ${patmin}; do patmin[${j}]=$pat; j=$((${j}+1)); done
fi

if [ ${i} -ne ${j} ]; then echo "${error_prefix} Number of energy bands of patmin and pimin inconsistent"; exit; fi



#---if no user-defined pattern selection is given, use:  0-12 (MOS) / 0 (pn, PI<500) / 0-4 (pn, PI>=500)
if [ ! -n "${patmax}" -a ${ID_INST} = 0 ]; then 
    for (( j=0; j<${i}; j++ )); do  
        if [ ${pimin[${j}]} -lt 500 ]; then 
            patmax[${j}]=0;
        else
            patmax[${j}]=4;
        fi
    done
elif [ ! -n "${patmax}" -a ${ID_INST} != 0 ]; then 
    for (( j=0; j<${i}; j++ )); do  
        patmax[${j}]=12
    done
else
    j=0
    for pat in ${patmax}; do patmax[${j}]=$pat; j=$((${j}+1)); done
fi

if [ ${i} -ne ${j} ]; then echo "${error_prefix} Number of energy bands of patmax and pimin inconsistent"; exit; fi




#-----copy/unzip event files
gzip -dfc $evtfile  >tmp_${output_prefix}evtlist.fits
evtfile=tmp_${output_prefix}evtlist.fits

if [ ${usefwc} = 1 ]; then   
    gzip -dfc $fwcfile  >tmp_${output_prefix}fwclist.fits
    fwcfile=tmp_${output_prefix}fwclist.fits
fi

if [ ${useoot} = 1 ]; then 
    gzip -dfc $ootfile  >tmp_${output_prefix}ootlist.fits
    ootfile=tmp_${output_prefix}ootlist.fits
fi



#-----Filter event file and Out-of-Time event file with GTI
if [ ${usegti} = 1 ] ; then
    echo "${prefix} Apply GTI filter (${gtifile})"
    evselect table=${evtfile}:EVENTS filteredset=tmp_${evtfile} expression="GTI(${gtifile},TIME)"
    mv tmp_${evtfile} ${evtfile}
    if [ ${useoot} = 1 ] ; then
        evselect table=${ootfile}:EVENTS filteredset=tmp_${ootfile} expression="GTI(${gtifile},TIME)"
        mv tmp_${ootfile} ${ootfile}
    fi
fi




#-----remove low energy events (to improve performance)
minimumPI=`echo "${pimin[*]}" | tr ' ' '\n' | awk 'NR==1{min=$0}NR>1 && $1<min{min=$1}END{print min}'`
evselect table=${evtfile}:EVENTS filteredset=tmp_${evtfile} expression="PI>=${minimumPI}"
mv tmp_${evtfile} ${evtfile}
if [ ${useoot} = 1 ] ; then
    evselect table=${ootfile}:EVENTS filteredset=tmp_${ootfile} expression="PI>=${minimumPI}"
    mv tmp_${ootfile} ${ootfile}
fi
if [ ${usefwc} = 1 ]; then   
    evselect table=${fwcfile}:EVENTS filteredset=tmp_${fwcfile} expression="PI>=${minimumPI}"
    mv tmp_${fwcfile} ${fwcfile}
fi





#-----check CCDs for noise/mode/exposure and remove if necessary

#Check for missing CCDs  (e.g. MOS1 CCD6)
for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
    test=`fkeyprint ${evtfile}[1] ONTIME | grep "ONTIME${ccds[${ccd}]}" | awk '{print $2}'`
    if [[ ! -n "${test}" ]]; then 
        ccd_used[${ccd}]=0
        comment[${ccd}]='no_data'
        echo "${prefix} No exposure found for EPIC-MOS${ID_INST} CCD${ccd}"
    elif [ `printf "%.0f" $test` = 0 ]; then 
        ccd_used[${ccd}]=0
        comment[${ccd}]='no_data'
        echo "${prefix} No exposure found for EPIC-MOS${ID_INST} CCD${ccd}"
    fi
done



if [ ${ID_INST} = 1 -o ${ID_INST} = 2 ] ; then

    #Check mode of MOS CCD1
    if [ $submode = 'small-window' -o $submode = 'large-window' ]; then  
        if [ ${withwindowmode} = 0 ]; then
            ccd_used[1]=0
            echo "${prefix} EPIC-MOS${ID_INST} CCD1 is in ${submode} mode and will not be used for the images"
        elif [ ${withwindowmode} = 1 ]; then
            ccd_used[1]=2
            echo "${warning_prefix} EPIC-MOS${ID_INST} CCD1 is in ${submode} mode. The CCD will not be included in the filter-wheel-closed images. To remove this CCD from all images, set withwindowmode to 'no'"
        fi
        comment[1]="${submode}_mode"

    elif [ $submode = 'timing' ]; then  
            ccd_used[1]=0
            comment[1]="${submode}_mode"
            echo "${prefix} EPIC-MOS${ID_INST} CCD1 is in ${submode} mode and will not be used for the images"
    fi

    #Check for noisy MOS CCDs
    if [ ${lenoise} = 1 ] ; then
        emtaglenoise eventset="${evtfile}"
        for ccd in 2 3 4 5 6 7 ; do
            fkeypar ${evtfile}[0] LENOIS0${ccd}
            LENOIS[$ccd]=`pget fkeypar value`
            if [ \( -n "${LENOIS[$ccd]}" \) -a \( "${LENOIS[$ccd]}" = 1 \) ]; then  
                ccd_used[${ccd}]=0 
                comment[${ccd}]='noisy'
                echo "${prefix} EPIC-MOS${ID_INST} CCD${ccd} is noisy, will be removed"
            fi
        done
    fi
fi




#remove CCDs that will not be used
for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do


    if [ ${ccd_used[${ccd}]} = 1 ]; then continue; fi


    #remove events from fwc file
    if [ ${usefwc} = 1 ]; then   
        evselect table=${fwcfile} filteredset=tmp_${fwcfile} expression="CCDNR != ${ccd}"
        mv tmp_${fwcfile} ${fwcfile}
    fi


    if [ ${ccd_used[${ccd}]} = 2 ]; then continue; fi


    #remove events from event file
    evselect table=${evtfile} filteredset=${evtfile}.tmp expression="CCDNR != ${ccd}"
    mv ${evtfile}.tmp ${evtfile}
    
    #remove extensions from eventfile
    ext_max=`fstruct ${evtfile} | grep 'BINTABLE' | wc -l`
    for (( ext=1; ext<=${ext_max}; ext++ )); do 
        fkeypar ${evtfile}[$ext] CCDID
        thisCCD=`pget fkeypar value`
        if [ "${thisCCD}" = ${ccd} ]; then
            fdelhdu ${evtfile}[${ext}] N Y
            ext_max=$(($ext_max - 1))
                ext=$(($ext - 1))
        fi
    done
    
done





#-----assure homogeneous bad-pixel selection
if [ ${withbadpixupdate} = 1 ] ; then
    ccd_string_evt=''
    ccd_string_fwc=''
    ccd_string_oot=''
    badpixtables_evt=''
    badpixtables_fwc=''
    badpixtables_oot=''
    
    for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
        if [ ${ccd_used[${ccd}]} = 0 ]; then continue; fi
        ccd_string_evt="${ccd_string_evt} ${ccd}"
        ccd_string_oot="${ccd_string_oot} ${ccd}"
        badpixtables_evt=${badpixtables_evt}' '${evtfile}:BADPIX${ccds[${ccd}]}
        badpixtables_oot=${badpixtables_oot}' '${ootfile}:BADPIX${ccds[${ccd}]}
        if [ ${ccd_used[${ccd}]} = 2 ]; then continue; fi
        ccd_string_fwc="${ccd_string_fwc} ${ccd}"
        badpixtables_fwc=${badpixtables_fwc}' '${fwcfile}:BADPIX${ccds[${ccd}]}
    done

    if [ ${usefwc} = 1 ] ; then
        ebadpixupdate eventset=${evtfile} fromccf=N ccds="${ccd_string_fwc}" badpixtables="${badpixtables_fwc}"
    fi
    if [ ${useoot} = 1 ] ; then
        ebadpixupdate eventset=${evtfile} fromccf=N ccds="${ccd_string_oot}" badpixtables="${badpixtables_oot}"
        ebadpixupdate eventset=${ootfile} fromccf=N ccds="${ccd_string_evt}" badpixtables="${badpixtables_evt}"
    fi
    if [ ${usefwc} = 1 ] ; then
        ebadpixupdate eventset=${fwcfile} fromccf=N ccds="${ccd_string_evt}" badpixtables="${badpixtables_evt}"
    fi
fi








#-----Calculate sky coordinates
if [ ${withattcalc} = 0 ] ; then
    nominalra=${ra_pnt}
    nominaldec=${de_pnt}
    imagesize=0.36
else
    echo "${prefix} Calculate image coordinates for event file"
    attcalc eventset=${evtfile} attitudelabel=ahf atthkset=${attfile} refpointlabel=user nominalra=$nominalra nominaldec=$nominaldec imagesize=$imagesize

    if [ ${useoot} = 1 ] ; then
        echo "${prefix} Calculate image coordinates for out-of-time event file"
        attcalc eventset=${ootfile} attitudelabel=ahf atthkset=${attfile} refpointlabel=user nominalra=$nominalra nominaldec=$nominaldec imagesize=$imagesize
    fi
fi

if [ ${usefwc} = 1 ] ; then
    echo "${prefix} Calculate image coordinates for filter-wheel-closed event file"
    attcalc -w 0 -V 0 eventset=${fwcfile}\
             attitudelabel=fixed\
                   fixedra=${ra_pnt}\
                  fixeddec=${de_pnt}\
             fixedposangle=${pa_pnt}\
              withatthkset=N\
             refpointlabel=user\
                 nominalra=${nominalra}\
                nominaldec=${nominaldec}\
                 imagesize=${imagesize}
fi






#-----determine fwc image weights
if [ ${usefwc} = 1 ] ; then


    #filter for events outside the FoV (not done in loop, because faster)
    selection="${flag_corner} && ${corner}"
    evselect table=${evtfile} filteredset=tmp_${output_prefix}evtlist_outFoV.fits expression="${selection}"
    evselect table=${fwcfile} filteredset=tmp_${output_prefix}fwclist_outFoV.fits expression="${selection}"
    if [ ${useoot} = 1 ] ; then
        evselect table=${ootfile} filteredset=tmp_${output_prefix}ootlist_outFoV.fits expression="${selection}"
    fi

    #get exposures
    E_obs=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
    E_fwc=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
    for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
        if [ ${ccd_used[${ccd}]} = 0 ]; then continue; fi
        E_obs[${ccd}]=`fkeyprint ${evtfile}[1] ONTIME | grep "ONTIME${ccds[${ccd}]}" | awk '{print $2}'`
        E_fwc[${ccd}]=`fkeyprint ${fwcfile}[1] ONTIME | grep "ONTIME${ccds[${ccd}]}" | awk '{print $2}'`
    done

    #get counts in detector corners
    for (( k=0; k<${#pimin[*]}; k++ )); do   #--loop over energy bands
        N_ccd=0
        C_obs=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
        C_oot=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
        C_fwc=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
        factfwc[${k}]=0
        SC_obs=0; SC_fwc=0; SC_oot=0
        
        for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
            
            if [ ${ccd_used[${ccd}]} = 0 ]; then continue; fi
            if [ \( ${ID_INST} -eq 1 -o ${ID_INST} -eq 2 \) -a ${ccd} -eq 1 ] ; then continue; fi
            if [ ${ID_INST} -eq 0 -a ${ccd} -ne 3 -a ${ccd} -ne 6 -a ${ccd} -ne 9 -a ${ccd} -ne 12 ] ; then continue; fi
            
            selection="PI>=${pimin[${k}]} && PI<${pimax[${k}]} && CCDNR==${ccd} && PATTERN>=${patmin[${k}]} && PATTERN<=${patmax[${k}]}"
            
            #counts corner (evt)
            evselect table=tmp_${output_prefix}evtlist_outFoV.fits filteredset=tmp_${output_prefix}list.fits expression="${selection}"
            fkeypar tmp_${output_prefix}list.fits[1] NAXIS2
            C_obs[${ccd}]=`pget fkeypar value`
            
            #counts corner (fwc)
            evselect table=tmp_${output_prefix}fwclist_outFoV.fits filteredset=tmp_${output_prefix}list.fits expression="${selection}"
            fkeypar tmp_${output_prefix}list.fits[1] NAXIS2
            C_fwc[${ccd}]=`pget fkeypar value`
            
            #counts corner (oot)
            if [ ${useoot} = 1 ] ; then
                evselect table=tmp_${output_prefix}ootlist_outFoV.fits filteredset=tmp_${output_prefix}list.fits expression="${selection}"
                fkeypar tmp_${output_prefix}list.fits[1] NAXIS2
                C_oot[${ccd}]=`pget fkeypar value`
            else
                C_oot[${ccd}]=0
            fi
            
            SC_obs=`perl -e "print ${SC_obs}+${C_obs[${ccd}]}"`
            SC_fwc=`perl -e "print ${SC_fwc}+${C_fwc[${ccd}]}"`
            SC_oot=`perl -e "print ${SC_oot}+${C_oot[${ccd}]}"`
            
            if [ ${C_fwc[${ccd}]} != 0 ]; then 
                N_ccd=$((${N_ccd}+1))
                factfwc[${k}]=`perl -e "print ${factfwc[${k}]} +  1.*(${C_obs[${ccd}]}-${factoot}*${C_oot[${ccd}]})/${E_obs[${ccd}]}/${C_fwc[${ccd}]}*${E_fwc[${ccd}]}"`
            fi
            
            
        done

        if [ ${N_ccd} != 0 ]; then 
            factfwc[${k}]=`perl -e "print 1.*${factfwc[${k}]}/${N_ccd}"`
        else
            factfwc[${k}]=0.
        fi      
        
        
        # output count statistics
        echo
        if [ ! -e ${output_prefix}counts.dat ] ; then echo "ID CCD Exp(obs) Exp(fwc) PI(min) PI(max) Cts(obs)  Cts(fwc)  Cts(oot)  Comment">${output_prefix}counts.dat; fi
        echo "ID CCD Exp(obs) Exp(fwc) PI(min) PI(max) Cts(obs)  Cts(fwc)  Cts(oot)  Comment">${output_prefix}counts_${k}.dat
        for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
            echo "${output_prefix:1:16}   ${ccd} ${E_obs[${ccd}]} ${E_fwc[${ccd}]} ${pimin[${k}]} ${pimax[${k}]}  ${C_obs[${ccd}]} ${C_fwc[${ccd}]} ${C_oot[${ccd}]} ${comment[${ccd}]}" >>${output_prefix}counts_${k}.dat
        done
        echo
        echo "${prefix} Summary - count statistics outside of the FoV:"
        cat ${output_prefix}counts_${k}.dat | column -t -s' '
        tail -${ccdmax} ${output_prefix}counts_${k}.dat | column -t -s' ' >> ${output_prefix}counts.dat
        rm ${output_prefix}counts_${k}.dat
        echo; echo "     Weight for ${output_prefix:1:16} filter-wheel-closed data in the (${pimin[${k}]}-${pimax[${k}]}) eV band: ${factfwc[${k}]}" 
        echo "     Weight for ${output_prefix:1:16} filter-wheel-closed data in the (${pimin[${k}]}-${pimax[${k}]}) eV band: ${factfwc[${k}]}" >>${output_prefix}counts.dat

        warninglimit=100
        if [ ${SC_obs} -lt ${warninglimit} ]; then echo "${warning_prefix} low statistics in the shielded area of the event file (${SC_obs} counts) for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})" ; fi
        if [ ${SC_oot} -lt ${warninglimit} -a ${useoot} = 1 ]; then echo "${warning_prefix} low statistics in the shielded area of the out-of-time event file (${SC_oot} counts) for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})"  ; fi
        if [ ${SC_fwc} -lt ${warninglimit} ]; then echo "${warning_prefix} low statistics in the shielded area of the filter-wheel-closed event file (${SC_fwc} counts) for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})"  ; fi
        
        
        #case of no counts -> create images?  I think for pipelines, it is better to create empty images, so only a warning is given here
        if [ ${SC_obs} = 0 ]; then echo "${warning_prefix} Found no events in the shielded area of the event file for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})" ; fi
        if [ ${SC_oot} = 0 -a ${useoot} = 1 ]; then echo "${warning_prefix} Found no events in the shielded area of the out-of-time event file for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})"  ;  fi
        if [ ${SC_fwc} = 0 ]; then echo "${warning_prefix} Found no events in the shielded area of the filter-wheel-closed event file for energyband ${k} (${pimin[${k}]}-${pimax[${k}]})"  ; fi

    
    done #--end loop over energy bands
fi




#-------create images
for (( k=0; k<${#pimin[*]}; k++ )); do   #--loop over energy bands

    echo "${prefix} Create scaled images in the ${pimin[${k}]}-${pimax[${k}]} eV band "

    selection="${flag} && PI>=${pimin[${k}]} && PI<${pimax[${k}]} && PATTERN>=${patmin[${k}]} && PATTERN<=${patmax[${k}]}"

    # extract image
    evselect table=${evtfile} imageset=${output_prefix}ima_${k}.fits expression="${selection}" $im

    # extract OOT image (scaled)
    if [ ${useoot} = 1 ] ; then
        evselect table=${ootfile} imageset=tmp_${output_prefix}ootima.fits expression="${selection}" $im
        fcarith tmp_${output_prefix}ootima.fits ${factoot} ${output_prefix}ima_${k}oot.fits MUL datatype="float" clobber=y
    fi

    # extract FWC image (scaled)
    if [ ${usefwc} = 1 ] ; then

        weight_fwc=({0,0,0,0,0,0,0,0,0,0,0,0,0}) 
        for (( ccd=1; ccd<=${ccdmax}; ccd++ )); do
            if [ "${ccd_used[${ccd}]}" != 1 ]; then continue; fi 
            weight_fwc[${ccd}]=`perl -e "print 1.*${factfwc[${k}]}*${E_obs[${ccd}]}/${E_fwc[${ccd}]}"`
        done

        fcalc ${fwcfile}[1] ${fwcfile}.tmp WEIGHT "${weight_fwc[1]}*(CCDNR==1)+${weight_fwc[2]}*(CCDNR==2)+${weight_fwc[3]}*(CCDNR==3)+${weight_fwc[4]}*(CCDNR==4)+${weight_fwc[5]}*(CCDNR==5)+${weight_fwc[6]}*(CCDNR==6)+${weight_fwc[7]}*(CCDNR==7)+${weight_fwc[8]}*(CCDNR==8)+${weight_fwc[9]}*(CCDNR==9)+${weight_fwc[10]}*(CCDNR==10)+${weight_fwc[11]}*(CCDNR==11)+${weight_fwc[12]}*(CCDNR==12)" clobber=yes
        mv ${fwcfile}.tmp ${fwcfile}
        evselect table=${fwcfile} imageset=${output_prefix}ima_${k}fwc.fits expression="${selection}" withzcolumn=Y withzerrorcolumn=N imagedatatype=Real32 withimagedatatype=1 $im
    fi
done



#-------make exposure maps
if [ ${exposure} = 1 ]; then
    echo "${prefix} Create exposure maps"
    expimageset=''
    for (( k=0; k<${#pimin[*]}; k++ )); do expimageset=$expimageset" ${output_prefix}ima_${k}exp.fits" ; done
    eexpmap imageset=${output_prefix}ima_0.fits \
        eventset=${evtfile} \
        attitudeset=${attfile} \
        expimageset="${expimageset}" \
        pimin="${pimin[*]}" \
        pimax="${pimax[*]}" \
        usefastpixelization=false \
        attrebin=1. \
        withvignetting=yes
    
    # make a mask
    if [ ${mask} = 1 ]; then
        echo "${prefix} Create mask"

#       fimgtrim infile=${output_prefix}ima_0exp.fits outfile=tmp_${output_prefix}ima_mask.fits threshlo=${ecut} threshup=I const_lo=0 clobber=yes
#       fimgtrim infile=tmp_${output_prefix}ima_mask.fits outfile=${output_prefix}ima_mask.fits threshlo=I threshup=1. const_up=1. clobber=yes

        emask expimageset=${output_prefix}ima_0exp.fits \
            detmaskset=${output_prefix}ima_mask.fits \
            threshold1=${threshold1} \
            threshold2=${threshold2} \
            withregionset=no
    fi
fi



#-------clean up
rm -f tmp_${output_prefix}*.*





exit

