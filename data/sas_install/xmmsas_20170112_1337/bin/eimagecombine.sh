#!/bin/bash
# NAME: eimagecombine.sh
# VERSION: 0.8
#
# Developer: Richard Sturm, Nicolas Clerc                          MPE Garching
#
################################################################################




#----------------------------------------------------------------------------------------------------definitions
#merge_prefix=MERGED_
#smoothstyle=simple  #adaptive
#width=2.12
#ecut=1000.
#maskindividual=1
#keepinterstage=1
#minwidth=2.12
#maxwidth=42.6
#desiredsnr=6.0 
#nconvolvers=50
#templatebands='0 1 2 3 4'
#exposureband=0
#n_max=12


merge_prefix=${1}
smoothstyle=${2}
convolverstyle=${3}
width=${4}
ecut=${5}
maskindividual=${6}
withcheckinput=${7}
withaddimages=${8}
withcombineimages=${9}
withasmooth=${10}
keepinterstage=${11}
n_max=${12}
epn_weight=${13}
em1_weight=${14}
em2_weight=${15}
templatebands=${16}
exposureband=${17}
minwidth=${18}
maxwidth=${19}
desiredsnr=${20}
nconvolvers=${21}
withuserwidths=${22}
userwidths=${23}
normalize=${24}
widthliststyle=${25}




#---ouput strings
prefix="eimagecombine:"
warning_prefix="eimagecombine: WARNING:"
error_prefix="eimagecombine: ERROR:"





#---for parallelisation
running=''
n_runing=0
#n_max=10  #set above
trap "kill 0; exit" SIGINT # SIGTERM EXIT
function wait_parallel {
    new_pid=$!
    running="$running $new_pid"
    n_runing=$(($n_runing+1))
    while [ $n_runing -ge $n_max ]; do
        running_old=$running

        #check if a processes terminated
        for pid in $running_old; do
            if [ ! -d /proc/$pid ] ; then
                running=''
                n_runing=0

                #update running processes
                for pid in $running_old; do
                    if [ -d /proc/$pid  ] ; then
                        running="$running $pid"
                        n_runing=$(($n_runing+1))
                    fi
                done
                break
            fi
        done
        
        sleep 1
    done
}

#EXAMPLE:
#for file in a b c d e f; do
#
#    (  echo run_a_command $file
#        sleep 2
#    ) &
#
#    wait_parallel
#done
#wait




function def_filename {
    #sets a parameter (named=$1) to a filename (named=$2), prefering the unziped file
    unset $1
    def_filename_tmp=${2/%.gz/}
    if [ -e $def_filename_tmp ]; then eval $1=$def_filename_tmp
    elif [ -e $def_filename_tmp.gz ]; then eval $1=$def_filename_tmp.gz
    fi
}  







#----------------------------------------------------------------------------------------------------preparations

INST=({'PN','M1','M2'})
filetype=({'',oot,fwc,exp})
filename=({'images','out-of-time images','filter-wheel-closed images','exposure maps'})




#get number of energy bands
if [ ${maskindividual} = 1 -o ${withcheckinput} = 1 -o ${withaddimages} = 1 ]; then
    tmp=(`ls P[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]{PN,M1,M2}?[0-9][0-9][0-9]_ima_{[0-9],[0-9][0-9],[0-9][0-9][0-9]}.fits{,.gz} 2> /dev/null`)
    eband=(`for file in ${tmp[@]}; do  echo ${file} | awk -F[_.] '{print $3}'  ; done  | sort -u`)
elif  [ ${withcombineimages} = 1 ]; then
    tmp=(`ls ${merge_prefix}{PN,M1,M2}_ima_{[0-9],[0-9][0-9],[0-9][0-9][0-9]}.fits{,.gz} 2> /dev/null`)
    eband=(`for file in ${tmp[@]}; do  echo ${file} | awk -F[_.] '{print $4}'  ; done  | sort -u`)
elif  [ ${withasmooth} = 1 ]; then
    tmp=(`ls ${merge_prefix}ima_{[0-9],[0-9][0-9],[0-9][0-9][0-9]}_sub.fits{,.gz} 2> /dev/null`)
    eband=(`for file in ${tmp[@]}; do  echo ${file} | awk -F[_.] '{print $3}'  ; done  | sort -u`)
fi







#define/check template bands
if [ $smoothstyle = "adaptive" ] ; then
    if [ ! -n "${templatebands}" ]; then 
        templatebands=''
        for (( i=0; i<${#eband[*]}; i++ )); do templatebands="${templatebands} ${eband[${i}]}";  done
    else
        for i in ${templatebands}; do
            check=0
            for (( j=0; j<${#eband[*]}; j++ )); do 
                if [ ${i} = ${eband[${j}]} ]; then check=1; break; fi
            done
            if [ ${check} = 0 ]; then
                echo "${error_prefix} Energy band ${i} is given in the parameter 'templatebands', but no files are found for this energy band"
                exit
            fi
        done
    fi
fi




#define/check exposure band
if [ ! -n "${exposureband}" ]; then 
    exposureband=${eband[0]}
else
    check=0
    for (( j=0; j<${#eband[*]}; j++ )); do 
        if [ ${exposureband} = ${eband[${j}]} ]; then check=1; break; fi
    done
    if [ ${check} = 0 ]; then
        echo "${error_prefix} Energy band ${exposureband} is given in the parameter 'exposureband', but no files are found for this energy band"
        exit
    fi
fi





#get exposures
if [ ${maskindividual} = 1 -o ${withcheckinput} = 1 -o ${withaddimages} = 1 ]; then
    exposure=(`ls P[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]{PN,M1,M2}?[0-9][0-9][0-9]_ima*fits*  2> /dev/null | xargs -n1 basename | awk '{print substr($0,2,16)}' |  sort -u`)
fi


#define weights for exposures
if [ ! -n "${epn_weight}" ]; then 
    for (( i=0; i<${#eband[*]}; i++ )); do fact_PN[${i}]=1.0;  done
else
    j=0
    for weigth in ${epn_weight}; do 
        if [ `perl -e "print ${weigth}>0.0?0:1"` = 1 ]; then echo "${error_prefix} A value ($weigth) in epn_weight is out of range"; exit ; fi
        fact_PN[${j}]=$weigth
        j=$((${j}+1))
    done
    if [ ${j} -ne ${#eband[*]} ]; then echo "${error_prefix} Number of energy bands of epn_weight inconsistent with file structure"; exit; fi
fi

if [ ! -n "${em1_weight}" ]; then 
    for (( i=0; i<${#eband[*]}; i++ )); do fact_M1[${i}]=0.4;  done
else
    j=0
    for weigth in ${em1_weight}; do 
        if [ `perl -e "print ${weigth}>0.0?0:1"` = 1 ]; then echo "${error_prefix} A value ($weigth) in em1_weight is out of range"; exit ; fi
        fact_M1[${j}]=$weigth
        j=$((${j}+1))
    done
    if [ ${j} -ne ${#eband[*]} ]; then echo "${error_prefix} Number of energy bands of em1_weight inconsistent with file structure"; exit; fi
fi


if [ ! -n "${em2_weight}" ]; then 
    for (( i=0; i<${#eband[*]}; i++ )); do fact_M2[${i}]=0.4;  done
else
    j=0
    for weigth in ${em2_weight}; do 
        if [ `perl -e "print ${weigth}>0.0?0:1"` = 1 ]; then echo "${error_prefix} A value ($weigth) in em2_weight is out of range"; exit ; fi
        fact_M2[${j}]=$weigth
        j=$((${j}+1))
    done
    if [ ${j} -ne ${#eband[*]} ]; then echo "${error_prefix} Number of energy bands of em2_weight inconsistent with file structure"; exit; fi
fi




if [ ${n_max} -gt 1 ]; then
    echo "${warning_prefix} Will run up to ${n_max} tasks in parallel (controlled by the n_parallel parameter)"
fi









#----------------------------------------------------------------------------------------------------check input images
if [ $withcheckinput = 1 ]; then
    echo "${prefix} Checking input files"
    check=0
    
    # -- A -- Check file exists
    #loop over exposures
    for (( i=0; i<${#exposure[*]}; i++ )); do 
        #loop over file types
 	for (( j=0; j<${#filetype[*]}; j++ )); do 
            if [ ${exposure[${i}]:10:1} = 'M' -a "${filetype[${j}]}" = 'oot' ]; then continue; fi 
            #loop over energy bands
            for (( k=0; k<${#eband[*]}; k++ )); do 
		def_filename test P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits
		# 1- check file exists
		if [ -z "${test}" ]; then 
		    echo "${error_prefix} P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits not found - image set of exposure ${exposure[${i}]} is incomplete"
		    check=1
		fi
	    done
	done
    done
    if [ ${check} = 1 ]; then exit; fi
    
    # -- B -- Check SUBMODE is good
    for (( i=0; i<${#exposure[*]}; i++ )); do 
        #loop over file types
 	for (( j=0; j<${#filetype[*]}; j++ )); do 
            if [ ${exposure[${i}]:10:1} = 'M' -a "${filetype[${j}]}" = 'oot' ]; then continue; fi 
            #loop over energy bands
            for (( k=0; k<${#eband[*]}; k++ )); do 
		def_filename test P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits
		# 2- check mode
		fkeypar ${test}[0] SUBMODE
		submode=`pget fkeypar value`
		if [ ${exposure[${i}]:10:1} = 'M' ]; then
		    #It is a MOS exposure
		    if ! [ ${submode} = "'PrimeFullWindow'" -o ${submode} = "'PrimePartialW2'" -o ${submode} = "'PrimePartialW3'" -o ${submode} = "'FastUncompressed'" ]; then 			echo "${error_prefix} P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits SUBMODE: ${submode} non supported"
		    	check=1
		    fi
		else
		    #It is a PN exposure
		    if ! [ ${submode} = "'PrimeFullWindow'" -o ${submode} = "'PrimeFullWindowExtended'" -o ${submode} = "'PrimeLargeWindow'" -o ${submode} = "'PrimeSmallWindow'" ]; then
		    	echo "${error_prefix} P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits SUBMODE: ${submode} non supported"
		    	check=1
		    fi
		fi
	    done
	done
    done
    if [ ${check} = 1 ]; then exit; fi
    
    
else
    echo "${prefix} Checking input files                     ...skipped (withcheckinput=0)"
fi  #end withcheckinput

###FUTURE DEVELOPMENT:
# check observing modes (observations in window mode) --> done 2015.12.08
# check wcs keywords
# check image size







#----------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------mask all images
#----------------------------------------------------------------------------------------------------------------------------
#
# this step is optional and allows the user to define a mask for each exposure 
# to exclude some regions (e.g. point sources, artefacts (like single reflections) etc...)
#

if [ $maskindividual = 1 ]; then
    echo "${prefix} Mask individual images (optional):"
    tmp=0
    #loop over exposures
    for (( i=0; i<${#exposure[*]}; i++ )); do 


        #Check if a mask is available for this exposure
        unset mask
        mask=(`ls P${exposure[${i}]}_ima_mask.fits{,.gz} 2> /dev/null`)


	#stop here, if no mask exists
        if [ -z ${mask[0]} ]; then continue; fi
	tmp=1


        #Check the extension number of the mask (to support normal masks and the SAS-version of masks, having the image in the 1st extension, not in the 0th)
        test=`fstruct ${mask[0]} | grep  "^ *1" | grep IMAGE `
        if [ ! -n "${test}" ]; then 
            maskext=0
        else
            maskext=1
        fi

        echo "${prefix}    mask images of exposure ${exposure[${i}]} with ${mask[0]}[${maskext}]"

        #loop over file types
        for (( j=0; j<${#filetype[*]}; j++ )); do
            if [ ${exposure[${i}]:10:1} = 'M' -a "${filetype[${j}]}" = 'oot' ]; then continue; fi 

            #loop over energy bands
            for (( k=0; k<${#eband[*]}; k++ )); do 
                
                unset file
                file=(`ls P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits{,.gz} 2> /dev/null`)

                #sequential version
                #farith ${file[0]} ${mask[0]}[1] ${file[0]/.fits/_masked.fits} MUL clobber=yes 

                #parallel version (PFILES MUST BE DEFINED, note also the wait at the end of the last loop)
                (
                    #define pfiles
                    pfiledir=$PWD/pfiles_P${exposure[${i}]}_ima_${eband[${k}]}${filetype[${j}]} 
                    mkdir -p ${pfiledir}
		    #expr not GNU (bug 0007267)
                    #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
		    export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"

                    #mask the images
                    thisoutfile=${file[0]/.fits/_masked.fits}
                    thisoutfile=${thisoutfile/%.gz/}
                    farith ${file[0]} ${mask[0]}[${maskext}] ${thisoutfile} MUL clobber=yes
                    rm -rf ${pfiledir}
                )&
                wait_parallel

            done
        done
    done
    wait
    if [ ${tmp} = 0 ]; then echo "${prefix}    no mask was found"; fi
else
    echo "${prefix} Mask individual images (optional)        ...skipped (maskindividual=0)"
fi  #end maskindividual











#----------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------add individual observations
#----------------------------------------------------------------------------------------------------------------------------
if [ $withaddimages = 1 ]; then
    echo "${prefix} Add images of individual instruments"

    #loop over instruments
    for (( i=0; i<${#INST[*]}; i++ )); do 
        #loop over file types
        for (( j=0; j<${#filetype[*]}; j++ )); do 
            
            if [ ${INST[${i}]} != 'PN' -a "${filetype[${j}]}" = 'oot' ]; then continue; fi
            
            #loop over energy bands
            for (( k=0; k<${#eband[*]}; k++ )); do 
                
                mergelist=${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.lst
                mergefile=${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits
                unset file
                m=0
                
                #loop over exposures
                for (( l=0; l<${#exposure[*]}; l++ )); do 
                    if [ ${exposure[${l}]:10:2} != ${INST[${i}]} ]; then continue; fi
                    
                    if [ -e P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}_masked.fits -a ${maskindividual} = 1 ];    then file[${m}]=P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}_masked.fits;    m=$((${m}+1)); continue; fi
                    if [ -e P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}_masked.fits.gz -a ${maskindividual} = 1 ]; then file[${m}]=P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}_masked.fits.gz; m=$((${m}+1)); continue; fi
                    if [ -e P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}.fits ];          then file[${m}]=P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}.fits;    m=$((${m}+1)); continue; fi
                    if [ -e P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}.fits.gz ];       then file[${m}]=P${exposure[${l}]}_ima_${eband[${k}]}${filetype[${j}]}.fits.gz; m=$((${m}+1)); continue; fi
                    
                done
                
                (               
                    if [ ${#file[*]} = 0 ]; then break
                    elif [ ${#file[*]} = 1 ]; then 
                        gzip -cfd ${file[0]} >${mergefile}
                    elif [ ${#file[*]} -gt 1 ]; then 
                        
                        pfiledir=$PWD/pfiles_${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}${filetype[${j}]}
                        mkdir -p ${pfiledir}
			#expr not GNU (bug 0007267)
                        #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
                        export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"

                        rm -f ${mergelist} ${mergefile}
                        for (( l=1; l<${#file[*]}; l++ )); do 
                            echo ${file[${l}]}',0,0' >>${mergelist}
                        done
                        echo "${prefix}    adding ${filename[${j}]} for EPIC-${INST[${i}]} energy band ${eband[${k}]} ($((${#file[*]})) files)"
                        
                        #fimgmerge can handle only 100 images, but is much faster than using a simple farith loop 
                        #  NOTE: the new version of fimgmerge (HEASOFT 6.16, 2nd July 2014) will have a higher limit, so the >95 case can be removed / or the limit increased to 995 images
                        if [ ${#file[*]} -lt 95 ]; then
                            fimgmerge ${file[0]} @${mergelist} ${mergefile} clobber=yes    1>/dev/null
                            rm -f ${mergelist} 
                        else
                            split -l 95 ${mergelist}  ${mergelist}.
                            sublists=(`ls ${mergelist}.??  2> /dev/null`)
                            fimgmerge ${file[0]} @${sublists[0]} ${mergefile} clobber=yes   1>/dev/null
                            for (( m=1; m<${#sublists[*]}; m++ )); do 
                                fimgmerge ${mergefile}  @${sublists[${m}]} ${mergefile}.tmp clobber=yes   1>/dev/null
                                mv ${mergefile}.tmp ${mergefile}
                            done
                            rm ${mergelist}*
                        fi
                        rm -rf ${pfiledir}
                    fi
                )&
                wait_parallel
                
            done
        done
    done
    wait
    
    
    
    #remove masked images
    if [ $keepinterstage = 0 -a $maskindividual = 1 ]; then
        rm -f P*_ima_*_masked.fits*
    fi
else
    echo "${prefix} Add images of individual instruments     ...skipped (withaddimages=0)"
fi  #end withaddimages























#--------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------combine the instruments
#--------------------------------------------------------------------------------------------------------------------------------------------------
if [ $withcombineimages = 1 ]; then
    echo "${prefix} Combine EPIC instruments"


    #-----------------------------------------------------------------------------------------------------check input files
    #loop over instruments
    for (( i=0; i<${#INST[*]}; i++ )); do 

        #check if this instrument is used
        unset tmp
        tmp=(`ls ${merge_prefix}${INST[${i}]}_ima*.fits{,gz} 2> /dev/null`)
        if [ -z "${tmp[0]}" ]; then continue; fi

        #loop over file types
        for (( j=0; j<${#filetype[*]}; j++ )); do    
            if [ ${INST[${i}]} != 'PN' -a "${filetype[${j}]}" = 'oot' ]; then continue; fi
            #loop over energy bands
            for (( k=0; k<${#eband[*]}; k++ )); do 
                mergefile=${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}${filetype[${j}]}.fits
                if [ ! -e ${mergefile} -a ! -e ${mergefile}.gz ]; then echo "${error_prefix} ${mergefile} not found - image set of co-added images is incomplete" ; exit; fi
            done
        done
    done



    #-----------------------------------------------------------------------------------------------------weight exposures
    echo "${prefix}    weight exposures"

    #loop over instruments
    for (( i=0; i<${#INST[*]}; i++ )); do 
        #loop over energy bands
        for (( k=0; k<${#eband[*]}; k++ )); do 
            
            def_filename infile ${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}exp.fits       
            if [ -z "${infile}" ]; then continue; fi
            
            (   #set pfiles for this subshell
                pfiledir=$PWD/pfiles_${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}exp
                mkdir -p ${pfiledir}
		#expr not GNU (bug 0007267)
                #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
		export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"
                
                #weight exposure
                unset thisweight
                eval thisweight=\${fact_${INST[${i}]}[${k}]}
                fcarith ${infile} ${thisweight} ${merge_prefix}${INST[${i}]}_ima_${eband[${k}]}exp_w.fits MUL clobber=yes
                
                #remove input file
                if [ $keepinterstage = 0 ]; then
                    rm -f ${infile} 
                fi
                
                #remove pfile-directory
                rm -rf ${pfiledir}

            )&
            
            wait_parallel
        done
    done
    wait
    
    
    
    #----------------------------------------------------------------------------------------------------combine images & exposures
    echo "${prefix}    combine images"
    
    for (( k=0; k<${#eband[*]}; k++ )); do 
        (
            pfiledir=$PWD/pfiles_${k}
            mkdir -p ${pfiledir}
            #expr not GNU (bug 0007267)
            #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
	    export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"
            
            mergedexposure=${merge_prefix}ima_${eband[${k}]}exp.fits
            mergedimage=${merge_prefix}ima_${eband[${k}]}_sub.fits
            tmpimage=${merge_prefix}ima_${eband[${k}]}_tmp.fits
            
            ###combine weighted exposures
            tmp=0
            for file in ${merge_prefix}PN_ima_${eband[${k}]}exp_w.fits ${merge_prefix}M1_ima_${eband[${k}]}exp_w.fits ${merge_prefix}M2_ima_${eband[${k}]}exp_w.fits ;do
                if [ -e $file -a $tmp = 0 ]; then
                    cp ${file} ${mergedexposure}
                    tmp=1
                elif [ -e $file -a $tmp = 1 ]; then
                    farith ${mergedexposure} ${file} ${tmpimage} ADD clobber=yes
                    mv ${tmpimage} ${mergedexposure}
                fi
            done

            if [ $keepinterstage = 0 ]; then
                rm -f ${merge_prefix}PN_ima_${eband[${k}]}exp_w.fits ${merge_prefix}M1_ima_${eband[${k}]}exp_w.fits ${merge_prefix}M2_ima_${eband[${k}]}exp_w.fits
            fi
            
            
            ###combine images 
            def_filename pnimage ${merge_prefix}PN_ima_${eband[${k}]}.fits
            def_filename m1image ${merge_prefix}M1_ima_${eband[${k}]}.fits
            def_filename m2image ${merge_prefix}M2_ima_${eband[${k}]}.fits
            
            tmp=0
            for file in ${pnimage} ${m1image} ${m2image}; do
                if [ ! -e $file ]; then continue; fi
                
                def_filename fwcimage ${file/.fits/fwc.fits}
                def_filename ootimage ${file/.fits/oot.fits}
		corimage=${file/.fits/_sub.fits}
		corimage=${corimage/%.gz/}

                #subtract fwc image
                if [ -n "${fwcimage}" ]; then 
                    farith ${file} ${fwcimage} ${corimage} SUB clobber=yes
                    file=${corimage}
                fi
                
                #subtract oot image
                if [ -n "${ootimage}" ]; then 
                    farith ${file} ${ootimage} ${tmpimage} SUB clobber=yes
                    mv ${tmpimage} ${corimage}
                    file=${corimage}
                fi
                
                #add pn and mos images
                if [ $tmp = 0 ]; then
                    cp ${corimage} ${mergedimage}
                    tmp=1
                elif [ $tmp = 1 ]; then
                    farith ${mergedimage} ${corimage} ${tmpimage} ADD clobber=yes
                    mv ${tmpimage} ${mergedimage}
                fi
                
            done
            


            ###clean up
            rm -rf ${pfiledir}
            rm -f ${tmpimage}
            if [ $keepinterstage = 0 ]; then
                rm -f ${merge_prefix}{PN,M1,M2}_ima_${eband[${k}]}{,fwc,oot,_sub}.fits
            fi
        )  & 
        wait_parallel
        
    done
    wait

    


    #-----------------------------------------------------------------------------------------------------create an overall mask
    tmp=0
    unset mask
    mask=${merge_prefix}ima_mask.fits
    exp=${merge_prefix}ima_${exposureband}exp.fits
    echo "${prefix}    create an overall mask (using energy band ${exposureband})"
    
    #make mask
    fimgtrim infile=${exp} outfile=${mask}.tmp threshlo=${ecut} threshup=I const_lo=0 clobber=yes    1>/dev/null
    fimgtrim infile=${mask}.tmp outfile=${mask} threshlo=I threshup=1. const_up=1. clobber=yes    1>/dev/null
    rm  ${mask}.tmp
    

    ###mask images and exposures
    for (( k=0; k<${#eband[*]}; k++ )); do 
        (
            pfiledir=$PWD/pfiles_${k}
            mkdir -p ${pfiledir}
	    #expr not GNU (bug 0007267)
            #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
            export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"
            
            mergedexposure=${merge_prefix}ima_${eband[${k}]}exp.fits
            mergedimage=${merge_prefix}ima_${eband[${k}]}_sub.fits
            tmpimage=${merge_prefix}ima_${eband[${k}]}_tmp.fits
            
            farith ${mergedexposure} ${mask} ${tmpimage} MUL clobber=yes
            mv ${tmpimage} ${mergedexposure}
            farith ${mergedimage} ${mask} ${tmpimage} MUL clobber=yes
            mv ${tmpimage} ${mergedimage}
            
            rm -rf ${pfiledir}
        )  & 
        wait_parallel
    done
    wait    
    

else
    echo "${prefix} Combine EPIC instruments                 ...skipped (withcombineimages=0)"
fi # end of withcombineimages
















#----------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------smooth images
#----------------------------------------------------------------------------------------------------------------------------
if [ $withasmooth = 1 ]; then


    #-----------------------------------------------------------------------------------------------------check input files
    mergefile=${merge_prefix}ima_mask.fits
    if [ ! -e ${mergefile} -a ! -e ${mergefile}.gz ]; then echo "${error_prefix} ${mergefile} not found - image set of combined images is incomplete" ; exit; fi   
    for (( k=0; k<${#eband[*]}; k++ )); do 
        mergefile=${merge_prefix}ima_${eband[${k}]}exp.fits
        if [ ! -e ${mergefile} -a ! -e ${mergefile}.gz ]; then echo "${error_prefix} ${mergefile} not found - image set of combined images is incomplete" ; exit; fi
        mergefile=${merge_prefix}ima_${eband[${k}]}_sub.fits
        if [ ! -e ${mergefile} -a ! -e ${mergefile}.gz ]; then echo "${error_prefix} ${mergefile} not found - image set of combined images is incomplete" ; exit; fi
    done







    def_filename mask ${merge_prefix}ima_mask.fits
    def_filename exp  ${merge_prefix}ima_${exposureband}exp.fits

    #-----------------------------------------------------------------make a smoothing template (only for adaptive smoothing)
    if [ $smoothstyle = "adaptive" ] ; then
        echo "${prefix} Create the smoothing template"
        
        
        
        addimage=${merge_prefix}ima_template.fits
        tmpimage=${merge_prefix}ima_tmp.fits
        invarianceset=${merge_prefix}ima_invar.fits
        convolversset=${merge_prefix}ima_convolversset.fits
        indeximageset=${merge_prefix}ima_indeximageset.fits
        
        ###merge images of the "template" bands to estimate the statistics in the final image
        tmp=0
        for k in ${templatebands}; do 
  
            def_filename mergedimage ${merge_prefix}ima_${eband[${k}]}_sub.fits
            if [ $tmp = 0 ]; then
                cp ${mergedimage} ${addimage}
                tmp=1
            elif [ $tmp = 1 ]; then
                farith ${addimage} ${mergedimage} ${tmpimage} ADD clobber=yes
                mv ${tmpimage} ${addimage}
            fi
        done

        #to estimate invarianceset, ensure that all values are positive
        fimgtrim infile=${addimage} outfile=${invarianceset} threshlo=0 threshup=indef const_lo=0.0 clobber=y  1>/dev/null

        #make smoothing template  for adaptive smoothing
        asmooth inset=${addimage} \
            outset=${tmpimage} \
            withexpimageset=yes \
            expimageset=${exp} \
            withweightset=yes \
            weightset=${exp} \
            withoutmaskset=yes \
            outmaskset=${mask} \
            minwidth=${minwidth} \
            maxwidth=${maxwidth} \
            desiredsnr=${desiredsnr} \
            nconvolvers=${nconvolvers} \
            widthliststyle=${widthliststyle} \
            readvarianceset=yes \
            invarianceset=${invarianceset} \
            writeconvolvers='yes' \
            outconvolversset=${convolversset} \
            withuserwidths=${withuserwidths} \
            userwidths=${userwidths} \
            outindeximageset=${indeximageset} 
    fi
    



    #----------------------------------------------------------------------------------------------------smooth images
    echo "${prefix} Smooth individual images"

    for (( k=0; k<${#eband[*]}; k++ )); do 
        (
            
            def_filename mergedexposure ${merge_prefix}ima_${eband[${k}]}exp.fits
            def_filename mergedimage ${merge_prefix}ima_${eband[${k}]}_sub.fits
            smoothimage=${merge_prefix}ima_${eband[${k}]}_subdiv_smooth.fits
            
            
            if [ $smoothstyle = "simple" ] ; then
                
                asmooth inset=${mergedimage} \
                    withoutmaskset=yes \
                    outmaskset=${mask} \
                    withexpimageset=yes \
                    expimageset=${mergedexposure} \
                    remultiply=no \
                    outset=${smoothimage} \
                    smoothstyle=simple \
                    convolverstyle=${convolverstyle} \
                    normalize=${normalize} \
                    width=${width}         
      
                
            elif [ $smoothstyle = "adaptive" ] ; then
                
                asmooth inset=${mergedimage} \
                    smoothstyle=withset \
                    inconvolversarray=${convolversset} \
                    inindeximagearray=${indeximageset} \
                    readvarianceset=yes \
                    invarianceset=${invarianceset} \
                    withexpimageset=yes \
                    expimageset=${mergedexposure} \
                    remultiply=no \
                    outset=${smoothimage} 
                
                rm -f template.ds
            fi
            
            #clean up
            if [ $keepinterstage = 0 ]; then
                rm -f ${mergedexposure} ${mergedimage}
            fi
            
        )&
        wait_parallel
        
    done
    wait
    
    #clean up
    if [ $keepinterstage = 0 ]; then
        rm -f ${addimage} ${invarianceset} ${indeximageset} ${convolversset}
    fi
    
    
    
    
    
    
    

    ###set unobserved regions to NAN
    tmpimage=${merge_prefix}ima_tmp.fits
    fimgtrim infile=${mask} outfile=${tmpimage} threshlo=0.5 threshup=I const_lo=NAN const_up=1. clobber=yes  1>/dev/null
    
    for (( k=0; k<${#eband[*]}; k++ )); do 
        (
            pfiledir=$PWD/pfiles_${k}
            mkdir -p ${pfiledir}
	    #expr not GNU (bug 0007267)
            #export PFILES="${pfiledir};${PFILES:`expr index "$PFILES" ';'`:${#PFILES}-`expr index "$PFILES" ';'`}"
	    export PFILES="${pfiledir};${PFILES:`echo $PFILES | awk '{print index($0,";")}'`:${#PFILES}-`echo $PFILES | awk '{print index($0,";")}'`}"
            
            smoothimage=${merge_prefix}ima_${eband[${k}]}_subdiv_smooth.fits
            tmp2image=${merge_prefix}ima_${eband[${k}]}_tmp2.fits
            tmp3image=${merge_prefix}ima_${eband[${k}]}_tmp3.fits
            
            
            farith ${smoothimage} ${tmpimage} ${tmp2image} MUL clobber=yes
            fimgtrim infile=${tmp2image} outfile=${tmp3image} threshlo=-990 threshup=I const_lo=NAN const_up=1. clobber=yes  1>/dev/null
            mv ${tmp3image} ${smoothimage}
            
            rm -rf ${pfiledir} ${tmp2image}
        )&
        wait_parallel
        
    done
    wait
    rm $tmpimage 
    
    
    if [ $keepinterstage = 0 ]; then
        rm -f ${mask}
    fi
    
    
else
    echo "${prefix} Smooth individual images                 ...skipped (withasmooth=0)"
fi # end of withasmooth




exit





