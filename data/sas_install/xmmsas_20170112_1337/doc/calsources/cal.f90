!------------------------------------------------------------------------------
!
!						XMM Science Analysis System (SAS)
!					   (c) 1997-2010 European Space Agency
!
!------------------------------------------------------------------------------
!
!	cal.f90	--- Calibration Access Layer interface specifications ---
!
!	DESCRIPTION:
!		This modules contains the interface specifications for the
!		Calibration Access Layer which provides calibration information to
!       SAS tasks.
!
!	EXPORTED FUNCTIONS:
!		All functions exported by this module start with "CAL_" - this
!		substring is omitted in the following list:
!
!		CAL control:
!		------------
!		ccfInfo                 --- query details about cal. file instance
!		getState                --- retrieve CAL state infos
!       integerToReal           --- convert integer to real vector
!		openCCF                 --- open a Calibration Index File (CIF)
!       realToInteger           --- convert real to integer vector
!		setCalibrationFile      --- define calibration file to be used
!       setRandom               --- control random number generator
!		setState                --- define/modify state of the CAL (explicitely
!                                   or from contents of data set)
!       releaseMemory           --- release allocated memory
!
!       retrieval of calibration data (generic)
!       ---------------------------------------
!       getBackgroundMap       --- background map
!       getBadPixelList        --- obtain list of bad pixels
!       getBadPixelMap         --- bad pixel list as 2D map
!       getBoresightMatrix     --- boresight misalignment matrix
!       getCamCoord2ToSacCoord --- CC2->SACCOORD matrix
!       getContaminationData   --- contamintation data
!       getBadPixelTableCode   --- get code of Bad-Pixel tables in CCF
!       getAduconvCode         --- get code of ADUCONV table data
!       getDiffuseXBackground  --- retrieve the diffuse X-ray background
!       getEbounds             --- energy boundary information from RMF
!       getEbins               --- energy bins from RMF
!       getEffectiveArea       --- effective area curve
!       getEventPatterns       --- get event pattern library
!       getFilterTransmission  --- filter transmission value
!       getFOVmap              --- get FOV map
!       getHKwindows           --- HK parameter windows
!       hasMiscellaneousData   --- check if miscellaneous data item exists
!       getMiscellaneousData   --- miscellanesous data
!       getMiscellaneousDataValue
!       getMiscellaneousDataCcd
!                              --- getMiscellaneousData as function
!       getModeParameters      --- timing related CCD mode parameters
!       getPSF                 --- get access to PSF
!       getParticleBackground  --- retrieve particle background spectrum
!       getQuantumEfficiency   --- quatum efficiency curves
!       getRedistribution      --- return PI response for an input energy
!       getVignettingFactor    --- vigentting factor for off-axis angle
!       isPixelBad             --- check if a given pixel is bad
!       psfPointValue          --- evaluate PSF at point in focal plane
!       psfSetPosAngle         --- define new position angle
!       psfBinSizeChangeable   --- inquire if PSF bin size can be changed
!       psfSetBinSize          --- define new PSF bin size
!       psfBinSize             --- inquire PSF bin size
!       psfValidityRanges      --- inquire PSF validity ranges (E, theta)
!       psfImage               --- obtain map representation of PSF
!       psfEnboxedEnergy       --- comp. box containing given energy fraction
!       psfEncircledEnergy     --- comp. circle containing given energy frac.
!       psfpsfCentreOffset     --- offset of PSF centre from nominal position
!       curveValueAt           --- compute curve at given abcissa value
!       curveWeightedIntegralOver
!                              --- compute weighted integral over abscissarange
!       getPatternFractionServer
!                              --- get handle to pattern fraction data server
!       patternFractionAt      --- register position in pattern fraction server
!       getPatternFractionTotalQE
!                              --- get total QE curve from patt fraction server
!       getPatternFractionInEnergy
!                              --- pattern fraction curve in energy space
!       getPatternFractionInChannel
!                              --- pattern fraction vector in channel space
!
!       EPIC:
!       -----
!       getMOSoffsets          --- access offset vectors
!       getMOSdarkFrameMap     --- access darkframe maps
!
!       perform calibration of data:
!       ----------------------------
!
!       coordinate transformations:
!       --------------------------
!       rawXY2mm                --- pixel coordinates to physical position
!       pixCoord0ToPixCoord1    --- PIXCOORD0 -> PIXCOORD1
!       pixCoord1ToChipCoord    --- PIXCOORD1 -> CHIPCOORD
!       chipCoordToPixCoord1    --- CHIPCOORD -> PIXCOORD1
!       chipCoordToCamCoord1    --- CHIPCOORD -> CAMCOORD1
!       camCoord1ToChipCoord    --- CAMCOORD1 -> CHIPCOORD
!       camCoord1ToChipRealCoord    --- CAMCOORD1 -> CHIPCOORD
!       camCoord1ToCamCoord2    --- CAMCOORD1 -> CAMCOORD2
!       camCoord2ToCamCoord1    --- CAMCOORD2 -> CAMCOORD1
!       camCoord2ToSacCoord     --- CAMCOORD2 -> SACCOORD
!       sacCoordToCamCoord2     --- SACCOORD -> CAMCOORD2
!       sacCoordToRowCoord      --- SACCOORD -> ROWCOORD
!       rowCoordToSacCoord      --- ROWCOORD -> SACCOORD
!       camCoord2ToTelCoord     --- CAMCOORD2 -> TELCOORD
!       telCoordToCamCoord2     --- TELCOORD -> CAMCOORD2
!
!       generic:
!       --------
!       correctTime            --- correct event times
!       offsetCorrect          --- correct for offset
!       gainCorrect            --- PHA value to PI (gain correction)
!       piToeV                 --- PI to eV conversion
!
!		EPIC:
!		-----
!       mosCtiCorrect          --- CTI correction of energy data (EMOS)
!       pnCtiCorrect           --- CTI correction of energy data (EPN)
!       pnGainCorrect          --- gain correction for PN
!       pnAdditionalGainCtiCorrect
!                              --- additonal gain/CTI corrections
!       pnGainTimingCorrect    --- special gain correction in TI mode
!       pnGainBurstCorrect     --- special gain correction in BU mode
!       pnGainEffCorrect       --- special gain correction in EFF mode
!       pnReEmissionThreshold  --- compute re-emission threshold from E, T
!       pnRateDependentPhaParam  
!                              --- compute the rate dependent PHA parameter - b
!       pnMedianMap            --- get the median map from the reject CCF
!       pnMasterOffset         --- get the master offset map from the reject CCF
!       pnMasterClosedOffset   --- get the master offset map from the reject CCF
!       pnOffsetCorrValues     --- get the offset correction values from reject CCF
!       pnNoiseMap             --- get the rawx values and associated noise maps
!
!		RGS:
!		----
!       rgsCtiCorrect          --- CTI correction of energy data (RGS)
!       rgsGetCrossPSF         --- the PSF in cross-dispersion direction
!       rgsGetEventThresholds  --- retrieve rejection and acceptance thresh
!       rgsGetLSF              --- the RGS Line Spread Function
!       rgsGetEffectiveArea    --- effective area
!       rgsGetRedistribution   --- the RGS CCD redistribution function
!       rgsGetRefinedWaveScale --- refinement of the RGS wavelength scale
!       rgsOffsetCorrect       --- offset correction for RGS

!		OM:
!		---
!       omDistortion           --- equivalent of rawXY2mm (above) for OM
!       omInverseDistortion    --- Uses the inverse transformation from CCF
!       omColorTransform       --- obtain color transformation matrix
!       omGetFluxConvFactors   --- obtain count rate to flux factors
!       omGetApertureRadius    --- obtain aperture radius of photometric calib.
!       omGetGrismFlux         --- obtain OM grism flux data from CCF
!       omGetGrismWavelength   --- obtain OM grism wavelength data from CCF
!       omGetFrameParameters   --- obtain OM frame parameters
!       omGetPlateScale        --- obtain OM platescale
!       omGetPSFmap            --- get map representation of OM PSF
!       omLargeSenseVariation  --- large scale sensitivity variations
!       omLEDtemplateMap       --- LED illumination template 
!       omPhotoMagnitude       --- convert count rates into magnitude values
!       omPhotoNatural         --- correct raw count rate
!       omPixelSenseVariation  --- pixel-to-pixel sensitivity variations
!       omGetPSF               --- get handle to OM PSF
!       omPsfEncircledEnergy   --- compute EE fraction in a given radius
!       omPsfCircleRadius      --- radius of circle that contains given EE
!
!	CHANGE HISTORY:
!		UL, 1997-07-25: 1.0.0: - first version
!       UL, 1998-10-01: 1.1.0: - added three new routines:
!                                getParticleBackground, getDiffuseXBackground,
!                                rgsRefinedWaveScale
!       UL, 1998-10-21: 1.2.0: - added rgsOffset
!       UL, 1998-11-03: 1.3.0: - made eduTreshold-parameter in getEventPatterns
!                                optional
!       UL, 1998-11-12: 1.4.0: - declaration of return type of
!                                CAL_getMiscDataValue made explicit (fixes
!                                compilation problem in case 'f90 -u'
!                                is used)
!       UL, 1999-03-09: 1.5.0: - changed 'LOW' -> 'ACCURACY_LOW'
!                                        'MEDIUM' -> 'ACCURACY_MEDIUM'
!                                        'HIGH' -> 'ACCURACY_HIGH'
!       UL, 1999-03-16: 1.6.0: - another optional parameter to
!                                CAL_getRedistribution() for selecting
!                                pixel types
!       UL, 1999-04-01: 1.7.0: - made CAL_setState an interface routine
!                                which is overloaded with three subroutines
!                                to set the state from
!                                   a) explicit list of values
!                                   b) name of data set
!                                   c) reference to data set Block
!       UL, 1999-05-31: 2.0.0: - dropped obsolete CAL_error
!                              - dropped obsolete CAL_setStateFromScienceFile
!                              - added CAL_integerToReal
!                              - added CAL_realToInteger
!                              - added CAL_offsetCorrect &
!                                removed CAL_rgsOffset
!                              - renamed CAL_gainCorrection to CAL_gainCorrect
!                              - renamed CAL_xxCTIcorrectin to CAL_xxCtiCorrect
!                              - removed obsolete 'n' (size of input vectors)
!                                from argument lists
!                              - added CAL_pnReEmissionThreshold
!                              - all vector-returning subroutines can now
!                                work with uninitialized pointers or
!                                pointers to already existing vectors (e.g.
!                                Dal columns); in the former case the Cal
!                                allocated memory to hold the result which
!                                has to be deallocated vio CAL_releaseMemory
!                                when no longer needed
!       UL, 1999-06-08: 2.1.0: - added CAL_setRandom
!       UL, 1999-07-09: 2.2.0: - new state variables
!                                   o ocb (on-chip-binning factor)
!                                   o temperatureCamera (temperature of
!                                                        camera structure)
!                              - CAL_rgsOffsetCorrect() added
!       UL, 1999-08-13: 2.3.0: - new coordinate conversion routines added
!                              - added CAL_piTokeV
!       UL, 1999-08-19: 2.4.0: - dropped obsolete state variables:
!                                status/verbosityLevel
!       UL, 1999-08-26: 2.5.0: - dopped obsolete I/Fs:
!                                   o mm2rawXY
!                                   o mm2thetaPhi
!                                   o thetaPhi2mm
!       UL, 1999-09-07: 2.6.0: - added rgsGetEventTresholds
!                              - added hasMiscellaneousData
!                              - added new arguments to rgsCtiCorrect
!                              - added rgsGetRedistribution
!                              - changed piTokeV -> piToeV
!       UL, 1999-09-08: 2.7.0: - type of return value and energy argument of
!                                pnReEmissionThreshold changed to Double
!                              - altered I/F of CAL_rgsGetCrossPsf
!       UL, 1999-11-08: 2.8.0: - added 'CAL_camCoord2ToSacCoordMatrix'
!       UL, 1999-12-17: 2.9.0: - added state variable `temperatureTracking'
!       UL, 2000-01-13: 2.9.1: - brought
!                                   CAL_omDistortion
!                                   CAL_omGetColorTrans
!                                   CAL_photoMagnitude
!                                in line with specs in CAL HB
!                              - new function CAL_omNaturalMagnitude(); is
!                                alias for CAL_photoMagnitude
!       UL, 2000-02-23: 3.0.0: - reconciled I/Fs of
!                                   CAL_getQuantumEfficiency
!                                   CAL_getFilterTransmission
!                                both are functions now which return a single
!                                value for a particular E + location; there
!                                is also a second I/F to these functions
!                                which returns integrated values
!       UL, 2000-03-03: 3.0.1: - added 'extentedSource' parameter to
!                                OM_omPhotoNatural
!       UL, 2000-03-09: 3.1.0: - added CAL_getFOVmap
!       UL, 2000-03-24: 3.2.0: - dropped time arguments of
!                                  CAL_pn{Gain/Cti}Correct
!       UL, 2000-04-13: 3.3.0: - reconciled effective area I/F with C++ I/F
!       UL, 2000-04-25: 3.3.1: - additional quantities returned by
!                                   CAL_getModeParameters
!       UL, 2000-05-05: 3.4.0: - made CAL_getVignettingFactor a function
!                              - corrected spelling error:
!                                   ACCURAY_MEDIUM -> ACCURACY_MEDIUM
!       UL, 2000-05-11: 3.5.0: - introduce dedicated CAL_mosGainCorrect()
!                                which is pattern dependent
!       UL, 2000-05-30: 3.6.0: - provide alternative I/F to EMOS
!                                redistribution in which the caller can
!                                specify the energy axis
!                              - conventional I/F evaluated model now on
!                                energy axis from CCF::REDIST:BINNEDPI_EBOUNDS
!                              - added CAL_getBinnedPIebounds()
!       UL, 2000-07-27: 3.7.0: - added CAL_omLEDtemplateMap()
!       UL, 2000-07-28: 3.8.0: - added CAL_getMOSoffsets()
!                                      CAL_getMOSdarkFrameMap()
!       UL, 2000-09-19: 3.9.0: - added various PSF-related routines
!       UL, 2000-11-01: 3.10.0:- added utility routine associated with
!                                OM color transformation
!                              - broke omColorTransform() up into
!                                   CAL_omGetColorTransformator()
!                                   CAL_omColorTransValidityRange()
!                                   CAL_omStandardColor()
!                                   CAL_omStandardMagnitude()
!       UL, 2001-02-13: 3.11.0:- CAL_omPhotoNatural() has new boolean argument
!                                     empiricalLinearityCorrection
!                              - new routines
!                                   CAL_omColorTransBranches
!                                   CAL_omColorTransSetBranch
!                                   CAL_omColorTransValidityRanges
!                                   CAL_omGetApertureRadius
!       UL, 2001-04-09: 3.12.0:- made FRAME argument of CAL_pnCtiCorrect() of
!                                type int32 (was int16)
!       UL, 2001-04-23: 3.13.0:- changed map type returned by
!                                   CAL_getMOSdarkFrameMap
!                                from int16 to real32
!                              - new state variable 'auxiliaryParameter'
!       UL, 2001-06-01: 3.14.0:- new routines:
!                                   o CAL_omGetPSF()
!                                   o CAL_omPsfEncircledEnergy()
!                                   o CAL_omPsfCircleRadius()
!                                [implements SCR 61: Obtaining the integrated
!                                 PSF function for OM]
!       UL, 2001-09-28: 3.15.0:- added CAL_releaseMemoryInt1ThreeDim
!       UL, 2001-10-17: 3.16.0:- changed type of real-valued arguments to
!                                coordinate conversion routines from
!                                'single' -> 'double'
!       UL, 2001-12-05: 3.17.0:- added CAL_getBadPixelTableCode()/
!                                      CAL_getAduconvCode()
!       UL, 2002-03-05: 3.18.0:- added CAL_toDirectionCosineMatrix
!                                (to replace CAL_getBoresightMatrix)
!       UL, 2002-07-25: 4.0.0: - added CAL_pnAdditionalGainCtiCorrect
!                                      CAL_pnGainTimingCorrect
!                                      CAL_pnGainBurstCorrect
!                                which replace corresponding routines in
!                                calpnalgo
!       UL, 2002-08-02: 4.1.0: - fixed bug in
!                                   CAL_releaseMemoryInt1ThreeDim
!       UL, 2002-08-16: 4.2.0: - added number of functions related to retrieval
!                                of pattern fraction data from CCF
!                                (CAL_getPatternFractionInEnergy, etc.)
!       UL, 2002-12-03: 4.3.0: - state variable 'observationStartTime' renamed
!                                to 'exposureStartTime'
!                              - state variable 'exposureDuration' now settable
!                                /obtainable via setState/getState()
!       UL,RDS, 2003-10-21:4.4.0: - added CAL_omGetGrismFlux/Wavelength()
!       RDS, 2003-11-04:4.4.1: - added CAL_omInverseDistortion
!       RDS, 2003-11-27:4.4.2: - added CAL_pnMedianMap, CAL_pnOffsetCorrValues,
!                                CAL_pnNoiseMap
!       RDS, 2004-08-04:4.5.0: - added CAL_pnGainEffCorrect
!       RDS, 2005-08-31:4.6.0: - added CAL_omGetFluxConvFactors
!       RDS, 2007-01-25:4.6.0: - added CAL_pnMasterOffset
!       RDS, 2007-02-28:4.7.0: - added CAL_omGetDegradationCoeffs
!
!	AUTHOR:
!		U. Lammers, Mon Oct  6 15:32:57 WET DST 1997
!
!	REFERENCES:
!		[1]: Software Specification Document for the XMM Science Analysis
!			 Subsystem, M. Dahlem et al.
!		[2]: Indexing of the XMM Current Calibration File, U. Lammers,
!			 15/07/97
!       [3]: Calibration Access and Data Handbook, C. Erd et al.
!
!	$Header: /sasbuild/repositories/sasdev/sas/packages/cal/f90/cal.f90,v 1.86 2014/03/19 15:50:24 rsaxton Exp $
!
module Cal
    use CalOalDefs
    use CalTypes

	implicit none

	interface

        !-------------------------------------------------------------------
        !------------------  CAL control/infrastructure  -------------------
        !-------------------------------------------------------------------
		subroutine CAL_ccfInfo(calType, calFileInfo)
            use CalTypes
			character(len=*), intent(in)	:: calType
			type(CalInfo), intent(out)      :: calFileInfo
		end subroutine


		subroutine CAL_getState(instrument, ccdChipId, ccdNodeId, &
                                ccdModeId, filterId, &
                                accuracyLevel, &
                                temperature, temperatureCamera, &
                                exposureStartTime, &
                                exposureDuration, &
                                ocb, randomize, temperatureTracking, &
                                auxiliaryParameter)
            use CalTypes
			integer(kind=int32), optional, intent(out)	:: &
					instrument, &           ! current instrument
					ccdChipId, &        	! CCD identifier (>=1)
					ccdNodeId, &            ! the readout node (>=0)
                    ccdModeId, &            ! current mode
					filterId, &             ! a filter Id (>=0)
                    ocb, &                  ! on-chip binning factor
				  	accuracyLevel           ! what it says
			real(kind=double), optional, intent(out)		:: &
					temperature, &          ! [K] CCD temperature
					temperatureCamera, &    ! [K] temperature of camera struct.
                    exposureStartTime, &    ! [d] exposure start time as MJD
                    exposureDuration, &     ! in [s]
                    auxiliaryParameter      ! auxiliary parameter
            logical, optional, intent(in)               :: &
                    randomize, &            ! randomize input quantities
                    temperatureTracking     ! perform T tracking
            
        end subroutine


        subroutine CAL_integerToReal(intVector, realVector)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in) :: intVector
            real(kind=single), dimension(:), pointer      :: realVector
        end subroutine


		subroutine CAL_openCCF(cifName)
			character(len=*), intent(in)	:: cifName
		end subroutine


        subroutine CAL_realToInteger(realVector, integerVector)
            use CalTypes
            real(kind=single), dimension(:), intent(in)   :: realVector
            integer(kind=int16), dimension(:), pointer    :: integerVector
        end subroutine


		subroutine CAL_setCalibrationFile(calibrationFileName)
			character(len=*), intent(in)	:: calibrationFileName
		end subroutine


        subroutine CAL_setRandom(min, max)
            use CalTypes
            real(kind=double), intent(in)                 :: min, max
        end subroutine

        !
        !   for CAL_setState/CAL_releaseMemory - see I/Fs below
        !

        !-------------------------------------------------------------------
        !------------- retrieval of calibration data (generic) --------------
        !-------------------------------------------------------------------
        character(len=9) function CAL_getBadPixelTableCode()
        end function


        character(len=9) function CAL_getAduconvCode()
        end function

        subroutine CAL_getBackgroundMap(time, map)
            use CalTypes
            real(kind=double), intent(in)                  :: time
            real(kind=single), dimension(:,:), pointer     :: map
        end subroutine


		subroutine CAL_getBadPixelList(rawX, rawY, type, yextent, uplinked, &
                                       rawX0, rawY0, rawXsize, rawYsize)
            use CalTypes
			integer(kind=int16), dimension(:), pointer  :: rawX, rawY, &
                                                           type, yextent
            logical, dimension(:), pointer              :: uplinked
            integer(kind=int16), intent(in), optional   :: rawX0, rawY0, &
                                                           rawXsize, rawYsize
		end subroutine


		subroutine CAL_getBadPixelMap(map, rawX0, rawY0, rawXsize, rawYsize)
            use CalTypes
			integer(kind=int16), dimension(:,:), pointer:: map
            integer(kind=int16), intent(in), optional   :: rawX0, rawY0, &
                                                           rawXsize, rawYsize
		end subroutine


        !
        !   Boresight related routines
        !
        function CAL_getBoresight(time) &
            result(boresight)
            use CalTypes
            real(kind=double), intent(in)                  :: time
            type(BoresightT)                               :: boresight
        end function


        subroutine CAL_withSacCoordOrientation(boresight, att)
            use CalTypes
            use CalOalDefs
            type(BoresightT), intent(in)                  :: boresight
            type(SpacecraftAttitudeType), intent(in)      :: att
        end subroutine


        subroutine CAL_projectOntoTelCoord(boresight, srcDirs, theta, phi)
            use CalTypes
            use CalOalDefs
            type(BoresightT), intent(in)                  :: boresight
            type(EquatorialDirectionType), dimension(:), intent(in) &
                                                          :: srcDirs
            real(kind=double), dimension(:), pointer      :: theta, phi
        end subroutine


        function CAL_toEulerAngles(boresight) result(result)
            use CalTypes
            type(BoresightT), intent(in)                   :: boresight
            type(EulerAngles321)                           :: result
        end function


        !
        !   obsolete - to be replaced by:
        !   CAL_toDirectionCosineMatrix(CAL_getBoresight(time))
        !
        subroutine CAL_getBoresightMatrix(time, matrix)
            use CalTypes
            real(kind=double), intent(in)                  :: time
            real(kind=double), dimension(:,:), pointer     :: matrix
        end subroutine


        !
        !   obsolete - to be replaced by:
        !   CAL_toEulerAngles(CAL_getBoresight(time))
        !
        function CAL_getBoresightAngles(time) result(result)
            use CalTypes
            type(EulerAngles321)                           :: result
            real(kind=double), intent(in)                  :: time
        end function


        !
        !   obsolete - to be replaced by:
        !   CAL_toDirectionCosineMatrix(CAL_toEulerAngles( &
        !                                       CAL_getBoresight(time))
        !
        subroutine CAL_euler321toMatrix(eulerAngles, matrix)
            use CalTypes
            type(EulerAngles321)                               :: eulerAngles
            real(kind=double), dimension(0:2,0:2), intent(out) :: matrix
        end subroutine


        subroutine CAL_getCamCoord2ToSacCoord(time, matrix)
            use CalTypes
            real(kind=double), intent(in)                  :: time
            real(kind=double), dimension(:,:), pointer     :: matrix
        end subroutine


        subroutine CAL_getContaminationData(time, contaminationData)
            use CalTypes
            use CalTypes
            real(kind=double), intent(in)               :: time
            type(ContaminationDataType), intent(out)    :: contaminationData
        end subroutine


        subroutine CAL_getDiffuseXBackground(time, theta, phi, spectrum, piVec)
            use CalTypes
            real(kind=double), intent(in)                  :: time, theta, phi
            real(kind=single), dimension(:), pointer       :: spectrum
            integer(kind=int16), dimension(:), pointer     :: piVec
        end subroutine


        subroutine CAL_getEbounds(channels, Emin, Emax)
            use CalTypes
            integer(kind=int16), dimension(:), pointer      :: channels
            real(kind=double), dimension(:), pointer        :: Emin, Emax
        end subroutine


        subroutine CAL_getBinnedPIebounds(channels, Emin, Emax)
            use CalTypes
            integer(kind=int16), dimension(:), pointer      :: channels
            real(kind=double), dimension(:), pointer        :: Emin, Emax
        end subroutine


        subroutine CAL_getEbins(channels, Emin, Emax)
            use CalTypes
            integer(kind=int16), dimension(:), pointer      :: channels
            real(kind=double), dimension(:), pointer        :: Emin, Emax
        end subroutine


        !
        !   for CAL_getEffectiveArea - see I/F below
        !

        subroutine CAL_getEventPatterns(patterns, eduThreshold)
            use CalTypes
            integer(kind=int8), dimension(:,:,:), pointer   :: patterns
            integer(kind=int16), intent(out), optional      :: eduThreshold
        end subroutine


		subroutine CAL_getFOVmap(map, rawX0, rawY0, rawXsize, rawYsize)
            use CalTypes
			integer(kind=int16), dimension(:,:), pointer:: map
            integer(kind=int16), intent(in), optional   :: rawX0, rawY0, &
                                                           rawXsize, rawYsize
		end subroutine


        subroutine CAL_getHKwindows(windowList)
            use CalTypes
            character(len=*), dimension(:), pointer        :: windowList
        end subroutine


        logical function CAL_hasMiscellaneousData(keyword)
            use CalTypes
            character(len=*), intent(in)                   :: keyword
        end function


        logical function CAL_hasMiscellaneousDataCcd(keywordStem)
            use CalTypes
            character(len=*), intent(in)                   :: keywordStem
        end function
          

        subroutine CAL_getMiscellaneousData(keyword, value)
            use CalTypes
            character(len=*), intent(in)                   :: keyword
            real(kind=double), intent(out)                 :: value
        end subroutine


        function CAL_getMiscellaneousDataValue(keyword) result(result)
            use CalTypes
            real(kind=double)                              :: result
            character(len=*), intent(in)                   :: keyword
        end function


        function CAL_getMiscellaneousDataCcd(keywordStem) &
            result(result)
            use CalTypes
            real(kind=double)                              :: result
            character(len=*), intent(in)                   :: keywordStem
        end function


        subroutine CAL_getModeParameters(modeParameters)
            use CalTypes
            type(ModeParameterDataType), intent(out)    :: modeParameters
        end subroutine


        subroutine CAL_getParticleBackground(time, theta, phi, spectrum, piVec)
            use CalTypes
            real(kind=double), intent(in)                  :: time, theta, phi
            real(kind=single), dimension(:), pointer       :: spectrum
            integer(kind=int16), dimension(:), pointer     :: piVec
        end subroutine


        !
        !   pattern data
        !
        function CAL_curveValueAt(curve, abscissaValue) result(ordinateValue)
            use CalTypes
            type(CurveT), intent(in)                      :: curve
            real(kind=double), intent(in)                 :: abscissaValue
            real(kind=double)                             :: ordinateValue
        end function
   
        function CAL_curveWeightedIntegralOver(curve, &
            fromValue, toValue) result(value)
            use CalTypes
            type(CurveT), intent(in)                      :: curve
            real(kind=double), intent(in)                 :: fromValue, &
                                                             toValue
            real(kind=double)                             :: value
        end function


        function CAL_getPatternFractionServer() result(server)
            use CalTypes
            type(PatternFractionServerT)                 :: server
        end function


        subroutine CAL_patternFractionAt(server, chipX, chipY)
            use CalTypes
            type(PatternFractionServerT), intent(in)     :: server
            integer(kind=int16), intent(in)              :: chipX, chipY
        end subroutine


        function CAL_getPatternFractionTotalQE(server) result(curve)
            use CalTypes
            type(PatternFractionServerT), intent(in)     :: server
            type(CurveT)                                 :: curve
        end function


        function CAL_getPatternFractionInEnergy(server, grade) result(curve)
            use CalTypes
            type(PatternFractionServerT), intent(in)     :: server
            integer(kind=int32), intent(in)              :: grade
            type(CurveT)                                 :: curve
        end function


        function CAL_getPatternFractionInChannel(server, grade)result(pattFrac)
            use CalTypes
            type(PatternFractionServerT), intent(in)     :: server
            integer(kind=int32), intent(in)              :: grade
            real(kind=double), dimension(:), pointer     :: pattFrac
        end function


        !
        !   PSF
        !
        function CAL_getPSF(E, theta, phi) result(psf)
            use CalTypes
            real(kind=double), intent(in)                  :: E, theta, phi
            type(PsfT)                                     :: psf
        end function


        function CAL_psfPointValue(psf, x, y) result(value)
            use CalTypes
            type(PsfT)                                    :: psf
            real(kind=double), intent(in)                 :: x, y
            real(kind=double)                             :: value
        end function

        subroutine CAL_psfSetPosAngle(psf, posangle)
            use CalTypes
            type(PsfT)                                    :: psf
            real(kind=double), intent(in)                 :: posangle
        end subroutine


        logical function CAL_psfBinSizeChangeable(psf)
            use CalTypes
            type(PsfT)                                    :: psf
        end function


        subroutine CAL_psfSetBinSize(psf, binSize)
            use CalTypes
            type(PsfT)                                    :: psf
            type(PsfBinSizeT)                             :: binSize
        end subroutine


        function CAL_psfBinSize(psf) result(binSize)
            use CalTypes
            type(PsfT)                                   :: psf
            type(PsfBinSizeT)                            :: binSize
        end function


        function CAL_psfValidityRanges() result(ranges)
            use CalTypes
            type(PsfValidityRangesT)                    :: ranges
        end function


        subroutine CAL_psfImage(psf, window, image)
            use CalTypes
            type(PsfT)                                  :: psf
            type(PsfWindowT)                            :: window
            real(kind=single), dimension(:,:), pointer  :: image
        end subroutine


        function CAL_psfEnboxedEnergy(psf, fraction, aspectRatio) result(box)
            use CalTypes
            type(PsfT)                                  :: psf
            real(kind=double), intent(in)               :: fraction
            real(kind=double), intent(in), optional     :: aspectRatio ! df:1.0
            type(PsfWindowT)                            :: box
        end function


        function CAL_psfEncircledEnergy(psf, fraction) result(radius)
            use CalTypes
            type(PsfT)                                  :: psf
            real(kind=double), intent(in)               :: fraction
            real(kind=double)                           :: radius
        end function


        function CAL_psfCentreOffset(psf) result(offset)
            use CalTypes
            type(PsfT)                                  :: psf
            real(kind=double)                           :: offset
        end function

        function CAL_getVignettingFactor(E, theta, phi) result(factor)
            use CalTypes
            real(kind=double), intent(in)                   :: E, theta, phi
            real(kind=double)                               :: factor
        end function


        logical function CAL_isPixelBad(rawX, rawY, yextent, defect, uplinked)
            use CalTypes
            integer(kind=int16), intent(in)                :: rawX, rawY
            integer(kind=int16), optional, intent(out)     :: yextent
            integer(kind=int16), optional, intent(out)     :: defect
            logical, optional, intent(out)                 :: uplinked
        end function

        !-------------------------------------------------------------------
        !-------  Time jump routine
        !-------------------------------------------------------------------
        function CAL_timeJumpTol(rev) result(tolerance)
            use CalTypes
            integer(kind=int32), intent(in)                 :: rev
            integer(kind=int32)                            :: tolerance
        end function

        

        !-------------------------------------------------------------------
        !-------  routines that perform a calbration task - generic --------
        !-------------------------------------------------------------------

        !
        !   spatial coordinate conversions:
        !
        !   PIXCOORD1 -> CAMCOORD1
        !   PIXCOORD1 -> CAMCOORD2
        !   PIXCOORD1 -> SACCORD
        !
        subroutine CAL_rawXY2mm(rawX, rawY, mmX, mmY, mmZ, coordSysType)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            real(kind=double), dimension(:), pointer        :: mmX, mmY, mmZ
            integer(kind=int32), intent(in), optional       :: coordSysType
        end subroutine


        !   PIXCOORD0 -> PIXCOORD1
        subroutine CAL_pixCoord0ToPixCoord1(telX, telY, rawX, rawY)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: telX, telY
            integer(kind=int16), dimension(:), pointer      :: rawX, rawY
        end subroutine


        !   PIXCOORD1 <-> CHIPCOORD
        subroutine CAL_pixCoord1ToChipCoord(rawX, rawY, chipX, chipY, &
                                            nodes)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            integer(kind=int16), dimension(:), pointer      :: chipX, chipY
            integer(kind=int8), dimension(:), intent(in), optional :: nodes
        end subroutine

        subroutine CAL_chipCoordToPixCoord1(chipX, chipY, rawX, rawY, nodes)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: chipX, chipY
            integer(kind=int16), dimension(:), pointer      :: rawX, rawY
            integer(kind=int8), dimension(:), pointer, optional :: nodes
        end subroutine


        !   CHIPCOORD <-> CAMCOORD1
        subroutine CAL_chipCoordToCamCoord1(chipX, chipY, &
                                            xmm1, ymm1, zmm1)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: chipX, chipY
            real(kind=double), dimension(:), pointer        :: xmm1, ymm1, zmm1
        end subroutine


        subroutine CAL_camCoord1ToChipCoord(xmm1, ymm1, zmm1, &
                                            chipX, chipY, ccds)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: xmm1, ymm1, zmm1
            integer(kind=int16), dimension(:), pointer      :: chipX, chipY
            integer(kind=int8), dimension(:), pointer, optional :: ccds
        end subroutine


        subroutine CAL_camCoord1ToChipRealCoord(xmm1, ymm1, zmm1, &
                                            chipX, chipY, ccds)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: xmm1, ymm1, zmm1
            real(kind=double), dimension(:), pointer      :: chipX, chipY
            integer(kind=int8), dimension(:), pointer, optional :: ccds
        end subroutine


        !   CAMCOORD1 <-> CAMCOORD2
        subroutine CAL_camCoord1ToCamCoord2(xmm1, ymm1, zmm1, &
                                            xmm2, ymm2, zmm2)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: xmm1, ymm1, zmm1
            real(kind=double), dimension(:), pointer        :: xmm2, ymm2, zmm2
        end subroutine

        subroutine CAL_camCoord2ToCamCoord1(xmm2, ymm2, zmm2, &
                                            xmm1, ymm1, zmm1)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: xmm2, ymm2, zmm2
            real(kind=double), dimension(:), pointer        :: xmm1, ymm1, zmm1
        end subroutine


        !   CAMCOORD2 <-> SACCOORD
        subroutine CAL_camCoord2ToSacCoord(xmm2, ymm2, zmm2, &
                                           xmmSc, ymmSc, zmmSc)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: xmm2, ymm2, zmm2
            real(kind=double), dimension(:), pointer     :: xmmSc, ymmSc, zmmSc
        end subroutine

        subroutine CAL_sacCoordToCamCoord2(xmmSc, ymmSc, zmmSc, &
                                           xmm2, ymm2, zmm2)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: xmmSc, ymmSc, zmmSc
            real(kind=double), dimension(:), pointer     :: xmm2, ymm2, zmm2
        end subroutine


        !   SACCOORD <-> ROWCOORD
        subroutine CAL_sacCoordToRowCoord(xmmSc, ymmSc, zmmSc, &
                                          beta, chi)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: xmmSc, ymmSc, zmmSc
            real(kind=double), dimension(:), pointer     :: beta, chi
        end subroutine

        subroutine CAL_rowCoordToSacCoord(beta, chi, &
                                          xmmSc, ymmSc, zmmSc)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: beta, chi
            real(kind=double), dimension(:), pointer     :: xmmSc, ymmSc, zmmSc
        end subroutine


        !   CAMCOORD <-> TELCOORD
        subroutine CAL_camCoord2ToTelCoord(xmm2, ymm2, zmm2, theta, phi)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: xmm2, ymm2, zmm2
            real(kind=double), dimension(:), pointer     :: theta, phi
        end subroutine


        subroutine CAL_telCoordToCamCoord2(theta, phi, xmm2, ymm2, zmm2)
            use CalTypes
            real(kind=double), dimension(:), intent(in)  :: theta, phi
            real(kind=double), dimension(:), pointer     :: xmm2, ymm2, zmm2
        end subroutine


        !
        !   calibration of data (generic)
        !
       subroutine CAL_gainCorrect(time, eIn, eOut, nodes)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: time
            real(kind=single), dimension(:), intent(in)     :: eIn
            real(kind=single), dimension(:), pointer        :: eOut
            integer(kind=int8), dimension(:), intent(in), optional &
                                                            :: nodes
        end subroutine


        subroutine CAL_offsetCorrect(time, eIn, eOut, nodes)
            use CalTypes
            real(kind=double), dimension(:), intent(in)    :: time
            real(kind=single), dimension(:), intent(in)    :: eIn
            real(kind=single), dimension(:), pointer       :: eOut
            integer(kind=int8), dimension(:), intent(in), optional :: &
                                                          nodes
        end subroutine


        subroutine CAL_piToeV(eIn, eOut)
            use CalTypes
            real(kind=single), dimension(:), intent(in)    :: eIn
            real(kind=single), dimension(:), pointer       :: eOut
        end subroutine

        subroutine CAL_eVToPi(eIn, eOut)
            use CalTypes
            real(kind=single), dimension(:), intent(in)    :: eIn
            real(kind=single), dimension(:), pointer       :: eOut
        end subroutine


        !
        !   retrieval of basic calibration data (instrument specific)
        !
        !   1 - EMOS
        !
        subroutine CAL_getMOSoffsets(offX, offY)
            use CalTypes
            integer(kind=int16), dimension(:), pointer    :: offX, offY
        end subroutine


        subroutine CAL_getMOSdarkFrameMap(map)
            use CalTypes
            real(kind=single), dimension(:,:), pointer  :: map
        end subroutine


        !
        !   calibration of data (instrument-specific)
        !
        !   1 - EMOS
        !
        subroutine CAL_mosGainCorrect(time, pattern, eIn, eOut)
            use CalTypes
            real(kind=double), dimension(:), intent(in)    :: time
            integer(kind=int8), dimension(:), intent(in)   :: pattern
            real(kind=single), dimension(:), intent(in)    :: eIn
            real(kind=single), dimension(:), pointer       :: eOut
        end subroutine


        subroutine CAL_mosCtiCorrect(time, rawX, rawY, eIn, eOut)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: time
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            real(kind=single), dimension(:), intent(in)     :: eIn
            real(kind=single), dimension(:), pointer        :: eOut
        end subroutine


        !
        !   2 - EPN
        !
        subroutine CAL_pnCtiCorrect(rawX, rawY, frame, eIn, eOut)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            integer(kind=int32), dimension(:), intent(in)   :: frame
            real(kind=single), dimension(:), pointer        :: eIn
            real(kind=single), dimension(:), pointer        :: eOut
        end subroutine


        subroutine CAL_pnGainCorrect(rawX, rawY, eIn, eOut)
            use CalTypes
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            real(kind=single), dimension(:), intent(in)     :: eIn
            real(kind=single), dimension(:), pointer        :: eOut
        end subroutine


        subroutine CAL_pnAdditionalGainCtiCorrect(eIn, rawY, T, parOut, &
                                                  doTCorr, &
											      doOffsetCorr, &
                                                  doLongTermCTISoftCorr, &
                                                  doLongTermCTIyCorr, &
                                                  doLongTermCTICorr)
            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
            real(kind=single), dimension(:), pointer        :: parOut
            integer(kind=int16), dimension(:), intent(in)   :: rawY
            real(kind=double), intent(in)                   :: T
            logical, intent(in), optional                   :: doTCorr, &
                                                               doOffsetCorr, &
                                                      doLongTermCTISoftCorr, &
                                                      doLongTermCTIyCorr, &
                                                      doLongTermCTICorr
        end subroutine

        subroutine CAL_pnBkgDepGainCorrect(eIn, ndsclin, mipsel, maxmip)

            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
            integer(kind=int32), intent(in)                 :: ndsclin
            integer(kind=int16), intent(in)                 :: mipsel 
            integer(kind=int16), intent(in)                 :: maxmip 

        end subroutine

        subroutine CAL_pnSpatialCtiCorrect(eIn, rawX, rawY)

            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
            integer(kind=int16), dimension(:), intent(in)   :: rawX
            integer(kind=int16), dimension(:), intent(in)   :: rawY

        end subroutine

        subroutine CAL_pnCombinedEventCorrect(eIn, pattId)

            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
            integer(kind=int16), dimension(:), intent(in)   :: pattId

        end subroutine


        subroutine CAL_pnGainTimingCorrect(eIn)
            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
        end subroutine


        subroutine CAL_pnGainBurstCorrect(eIn)
            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
        end subroutine


        subroutine CAL_pnGainEffCorrect(eIn)
            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
        end subroutine

        subroutine CAL_pnGainFfCorrect(eIn)
            use CalTypes
            real(kind=single), dimension(:), intent(inout)  :: eIn
        end subroutine


        function CAL_pnReEmissionThreshold(energy, rawY) result(result)
            use CalTypes
            real(kind=double)                               :: result
            real(kind=double), intent(in)                   :: energy
            integer(kind=int16), intent(in)                 :: rawY
        end function
        
        subroutine CAL_pnRateDependentPhaParam(Ne, withGainTiming, &
                                               pha_constants, &
                                               corr_coeffs, corr_errors)
            use CalTypes
            real(kind=double), intent(in)                   :: Ne
            logical, intent(in)                             :: withGainTiming
            real(kind=double), dimension(:), pointer        :: pha_constants
            real(kind=double), dimension(:), pointer        :: corr_coeffs
            real(kind=double), dimension(:), pointer        :: corr_errors
        end subroutine
        
        subroutine CAL_pnMedianMap(map)
            use CalTypes
            real(kind=single), dimension(:,:), pointer      :: map
        end subroutine

        subroutine CAL_pnMasterOffset(map)
            use CalTypes
            real(kind=single), dimension(:,:), pointer      :: map
        end subroutine

        subroutine CAL_pnMasterClosedOffset(map, xrlCoeff)
            use CalTypes
            real(kind=single), dimension(:,:), pointer      :: map
            real(kind=single), dimension(:), pointer        :: xrlCoeff
        end subroutine

        subroutine CAL_pnOffsetCorrValues(hlow, hhigh, corVals)
            use CalTypes
            real(kind=single), dimension(:), pointer        :: hlow
            real(kind=single), dimension(:), pointer        :: hhigh
            integer(kind=int16),  dimension(:), pointer        :: corVals
        end subroutine

        subroutine CAL_pnNoiseMap(rawx, noiseMap)
            use CalTypes
            integer(kind=int16), dimension(:), pointer :: rawx
            real(kind=single), dimension(:,:,:), pointer    :: noiseMap
        end subroutine 

 
        !
        !   3 - RGS
        !
        subroutine CAL_rgsCtiCorrect(time, rawX, rawY, nodes, shape, &
                                     separation, eIn, eOut)
            use CalTypes
            real(kind=double), dimension(:), intent(in)     :: time        
            integer(kind=int16), dimension(:), intent(in)   :: rawX, rawY
            integer(kind=int8), dimension(:), intent(in)    :: nodes
            integer(kind=int8), dimension(:), intent(in)    :: shape
            integer(kind=int16), dimension(:), intent(in)   :: separation
            real(kind=single), dimension(:), intent(in)     :: eIn
            real(kind=single), dimension(:), pointer        :: eOut
        end subroutine


        subroutine CAL_rgsGetCrossPSF(time, beta, sourceXdisp, xAngles, &
                                      binWidth, distribution)
            use CalTypes
            real(kind=double), intent(in)                 :: time
            real(kind=double), intent(in)                 :: beta, sourceXdisp
            real(kind=double), dimension(:), intent(in)   :: xAngles
            real(kind=double), intent(in)                 :: binWidth
            real(kind=double), dimension(:), pointer      :: distribution
        end subroutine


        subroutine CAL_rgsGetEventThresholds(rejectionThresholds, &
                                             acceptanceThresholds, &
                                             node)
            use CalTypes
            real(kind=single), dimension(:), pointer  :: rejectionThresholds, &
                                                         acceptanceThresholds
            integer(kind=int8), intent(in), optional  :: node
        end subroutine


        subroutine CAL_rgsGetLSF(lambda, theta, phi, diffOrder, &
                                 lambdaMin, lambdaMax, lambdaGrid, lsfProf)
            use CalTypes
            real(kind=double), intent(in)             :: lambda, theta, phi, &
                                                         lambdaMin, lambdaMax
            integer(kind=int32), intent(in)           :: diffOrder
            real(kind=double), dimension(:), pointer  :: lambdaGrid, lsfProf
        end subroutine


        subroutine CAL_rgsGetRedistribution(E, rawX, rawY, rejectionThreshold,&
                                            redistribution, channels)
            use CalTypes
            real(kind=double), intent(in)             :: E, rejectionThreshold
            integer(kind=int16), intent(in)           :: rawX, rawY
            real(kind=double), dimension(:), pointer  :: redistribution
            integer(kind=int16), intent(out), optional:: channels
        end subroutine


        subroutine CAL_rgsGetRefinedWaveScale(time, diffOrder, waveLength)
            use CalTypes
            real(kind=double), dimension(:), intent(in)   :: time
            integer(kind=int16), dimension(:), intent(in) :: diffOrder
            real(kind=double), dimension(:), intent(inout):: waveLength
        end subroutine


        subroutine CAL_rgsOffsetCorrect(time, rawX, rawY, shape, nodes, &
                                        eIn, eOut)
            use CalTypes
            real(kind=double), dimension(:), intent(in)    :: time
            integer(kind=int16), dimension(:), intent(in)  :: rawX, rawY
            integer(kind=int8), dimension(:), intent(in)   :: shape, nodes
            integer(kind=int16), dimension(:), intent(in)  :: eIn
            real(kind=single), dimension(:), pointer       :: eOut
        end subroutine


        !
        !   4 - OM
        !
        subroutine CAL_omDistortion(rawX, rawY, deltaX, deltaY, &
                                    sigmaX, sigmaY, calcMode, nInterPoints)
            use CalTypes
            real(kind=single), dimension(:), intent(in)     :: rawX, rawY
            real(kind=single), dimension(:), pointer        :: deltaX, deltaY
            real(kind=single), dimension(:), pointer, optional :: sigmaX, &
                                                                  sigmaY
            integer(kind=int32), intent(in), optional       :: calcMode, &
                                                               nInterPoints
        end subroutine

        subroutine CAL_omInverseDistortion(rawX, rawY, deltaX, deltaY, &
                                    sigmaX, sigmaY, calcMode, nInterPoints)
            use CalTypes
            real(kind=single), dimension(:), intent(in)     :: rawX, rawY
            real(kind=single), dimension(:), pointer        :: deltaX, deltaY
            real(kind=single), dimension(:), pointer, optional :: sigmaX, &
                                                                  sigmaY
            integer(kind=int32), intent(in), optional       :: calcMode, &
                                                               nInterPoints
        end subroutine


        function CAL_omGetColorTransformator(filter1, filter2) &
            result(colorTrans)
            use CalTypes
            integer(kind=int32), intent(in)              :: filter1, filter2
            type(OmColorTransformatorT)                  :: colorTrans
        end function


        function CAL_omColorTransBranches(colorTrans) result(nBranches)
            use CalTypes
            integer(kind=int8)                           :: nBranches
            type(OmColorTransformatorT), intent(in)      :: colorTrans
        end function


        subroutine CAL_omColorTransSetBranch(colorTrans, branch)
            use CalTypes
            type(OmColorTransformatorT), intent(in)      :: colorTrans
            integer(kind=int8), intent(in)               :: branch
        end subroutine


        function CAL_omColorTransValidityRanges(colorTrans) result(nRanges)
            use CalTypes
            integer(kind=int8)                           :: nRanges
            type(OmColorTransformatorT), intent(in)      :: colorTrans
        end function


        function CAL_omColorTransValidityRange(colorTrans, n) &
                                                            result(valInterval)
            use CalTypes
            type(OmColorTransformatorT), intent(in)      :: colorTrans
            integer(kind=int8), intent(in), optional     :: n
            type(IntervalT)                              :: valInterval
        end function


        function CAL_omStandardColor(colorTrans, magnitude1, magnitude2) &
            result(stdColor)
            use CalTypes
            type(OmColorTransformatorT), intent(in)      :: colorTrans
            real(kind=double), intent(in)                :: magnitude1, &
                                                            magnitude2
            type(ValueErrorT)                            :: stdColor
        end function


        function CAL_omStandardMagnitude(colorTrans, stdColor, magnitude) &
            result(stdMagnitude)
            use CalTypes
            type(OmColorTransformatorT), intent(in)      :: colorTrans
            type(ValueErrorT), intent(in)                :: stdColor
            real(kind=double), intent(in)                :: magnitude
            type(ValueErrorT)                            :: stdMagnitude
        end function

        subroutine CAL_omGetGrismFlux(lamda, isf, isfError)
            use CalTypes
            real(kind=double), dimension(:), pointer     :: lamda, isf, &
                                                            isfError
        end subroutine


        subroutine CAL_omGetGrismWavelength(lamda)
            use CalTypes
            real(kind=double), dimension(:), pointer     :: lamda
        end subroutine


        subroutine CAL_omColorTransform(filter1, filter2, &
                                        magnitude1, magnitude2, &
                                        stdColor12, stdMagnitude2, &
                                        stdColor12Error, stdMagnitude2Error)
            use CalTypes
            integer(kind=int32), intent(in)              :: filter1, filter2
            real(kind=double), intent(in)                :: magnitude1, &
                                                            magnitude2
            real(kind=double), intent(out)               :: stdColor12, &
                                                            stdMagnitude2
            real(kind=double), intent(out), optional     :: stdColor12Error, &
                                                            stdMagnitude2Error
        end subroutine


        function CAL_omGetApertureRadius() result(radius)
            use CalTypes
            real(kind=double)                            :: radius
        end function

        function CAL_omGetFluxConvFactors() result(fcf)
            use CalTypes
            type(OmFluxConvF)                            :: fcf
        end function


        subroutine CAL_omGetFrameParameters(frameParameters)
            use CalTypes
            type(OMframeParameters)   :: frameParameters
        end subroutine

        subroutine CAL_omGetDegradationCoeffs(dc) 
            use CalTypes
            real(kind=double), dimension(:), pointer     :: dc
        end subroutine



        !
        !   PSF
        !
        function CAL_omGetPSF(cenX, cenY, countFrameRateRatio) result(psf)
            use CalTypes
            real(kind=double), intent(in)                  :: cenX, cenY, &
                                                           countFrameRateRatio
            type(OmPsfT)                                   :: psf
        end function


        function CAL_omPsfEncircledEnergy(psf, radius) result(fraction)
            use CalTypes
            type(OmPsfT)                                :: psf
            real(kind=double), intent(in)               :: radius
            real(kind=double)                           :: fraction
        end function


        function CAL_omPsfCircleRadius(psf, fraction) result(radius)
            use CalTypes
            type(OmPsfT)                                :: psf
            real(kind=double), intent(in)               :: fraction
            real(kind=double)                           :: radius
        end function


        subroutine CAL_omGetPSFmap(rawX, rawY, &
                                   nPixelsNegX, nPixelsPosX, &
                                   nPixelsNegY, nPixelsPosY, &
                                   xRes, yRes, &
                                   countFrameRateRatio, &
                                   PSFmap)
            use CalTypes
            real(kind=double), intent(in)           :: rawX, rawY, &
                                                       countFrameRateRatio
            integer(kind=int32), intent(in)         :: nPixelsNegX, &
                                                       nPixelsPosX, &
                                                       nPixelsNegY, &
                                                       nPixelsPosY, &
                                                       xRes, yRes
            
            real(kind=single), dimension(:,:), pointer &
                                                    :: PSFmap
        end subroutine


        subroutine CAL_omGetPlateScale(lambda, plateScale, errorX, errorY)
            use CalTypes
            real(kind=double), intent(in)                   :: lambda
            real(kind=double), intent(out)                  :: plateScale
            real(kind=double), intent(out), optional        :: errorX, errorY
        end subroutine


        subroutine CAL_omLargeSenseVariation(x0, y0, xSize, ySize, lambda, &
                                             senseMap, &
                                             averageFlatField, &
                                             averageFlatFieldError, &
                                             pixelError)
            use CalTypes
            integer(kind=int32), intent(in)            :: x0, y0, xSize, ySize
            real(kind=double), intent(in)              :: lambda
            real(kind=single), dimension(:,:), pointer :: senseMap
            real(kind=double), intent(out), optional   :: averageFlatField, &
                                                        averageFlatFieldError,&
                                                        pixelError
        end subroutine


        subroutine CAL_omLEDtemplateMap(x0, y0, xSize, ySize, map, &
                                        averageIlluCorr, &
                                        averageIlluCorrError, &
                                        pixelError)
            use CalTypes
            integer(kind=int32), intent(in)              :: x0, y0, xSize, &
                                                            ySize
            real(kind=single), dimension(:,:), pointer   :: map
            real(kind=double), intent(out), optional     :: averageIlluCorr, &
                                                        averageIlluCorrError, &
                                                        pixelError
        end subroutine



        subroutine CAL_omPhotoMagnitude(naturalRate, magnitude, &
                                        naturalRateErrorMinus, &
                                        naturalRateErrorPlus, &
                                        magnitudeErrorMinus, &
                                        magnitiudeErrorPlus)
            use CalTypes
            real(kind=double), intent(in)           :: naturalRate
            real(kind=double), intent(out)          :: magnitude
            real(kind=double), intent(in), optional :: naturalRateErrorMinus, &
                                                       naturalRateErrorPlus
            real(kind=double), intent(out), optional:: magnitudeErrorMinus, &
                                                       magnitiudeErrorPlus
        end subroutine


        function CAL_omNaturalMagnitude(naturalRate, &
                                        naturalRateErrorMinus, &
                                        naturalRateErrorPlus, &
                                        magnitudeErrorMinus, &
                                        magnitiudeErrorPlus) result(result)
            use CalTypes
            real(kind=double), intent(in)           :: naturalRate
            real(kind=double), intent(in), optional :: naturalRateErrorMinus, &
                                                       naturalRateErrorPlus
            real(kind=double), intent(out), optional:: magnitudeErrorMinus, &
                                                       magnitiudeErrorPlus
            real(kind=double)                       :: result
        end function


        subroutine CAL_omPixelSenseVariation(x0, y0, xSize, ySize, &
                                             countRateFrameRatio, senseMap, &
                                             averageFlatField, &
                                             averageFlatFieldError, &
                                             pixelError)
            use CalTypes
            integer(kind=int32), intent(in)              :: x0, y0, xSize, &
                                                            ySize
            real(kind=double), intent(in)                :: countRateFrameRatio
            real(kind=single), dimension(:,:), pointer   :: senseMap
            real(kind=double), intent(out), optional   :: averageFlatField, &
                                                        averageFlatFieldError,&
                                                        pixelError
        end subroutine



    end interface


    interface CAL_toDirectionCosineMatrix

        function CAL_toDirectionCosineMatrix1(boresight) result(matrix)
            use CalTypes
            use CalOalDefs
            type(BoresightT), intent(in)                  :: boresight
            real(kind=double), dimension(:,:), pointer    :: matrix
        end function

        function CAL_toDirectionCosineMatrix2(eulerAngles) result(matrix)
            use CalTypes
            type(EulerAngles321)                          :: eulerAngles
            real(kind=double), dimension(:,:), pointer    :: matrix
        end function

    end interface


    interface CAL_getRedistribution

        subroutine CAL_getRedistribution1(eIn, response, eventType,peakChannel)
            use CalTypes
            real(kind=double), intent(in)                   :: eIn
            real(kind=double), dimension(:), pointer        :: response
            integer(kind=int32), intent(in), optional       :: eventType
            integer(kind=int16), intent(out), optional      :: peakChannel
        end subroutine


        subroutine CAL_getRedistribution2(eIn, eAxisLoBounds, eAxisHiBounds, &
                                          response, eventType, peakChannel)
            use CalTypes
            real(kind=double), intent(in)                   :: eIn
            real(kind=double), dimension(0:), intent(in)    :: eAxisLoBounds,&
                                                               eAxisHiBounds
            real(kind=double), dimension(:), pointer        :: response
            integer(kind=int32), intent(in), optional       :: eventType
            integer(kind=int16), intent(out), optional      :: peakChannel
        end subroutine
    end interface


    interface CAL_getQuantumEfficiency

        function CAL_getQuantumEfficiency1(E, rawX, rawY, patternId) &
        result(quantumEff)
            use CalTypes
            integer(kind=int16), intent(in)                 :: rawX, rawY
            real(kind=double), intent(in)                   :: E
            integer(kind=int32), intent(in), optional       :: patternId
            real(kind=double)                               :: quantumEff
        end function

        function CAL_getQuantumEfficiency2(Efrom, Eto, rawX, rawY, patternId) &
        result(quantumEff)
            use CalTypes
            integer(kind=int16), intent(in)                 :: rawX, rawY
            real(kind=double), intent(in)                   :: Efrom, Eto
            integer(kind=int32), intent(in), optional       :: patternId
            real(kind=double)                               :: quantumEff
        end function

    end interface

    interface CAL_getLargePatternSize

        function CAL_getLargePatternSize1(E) &
        result(LargePatts)
            use CalTypes
            real(kind=double), intent(in)                   :: E
            real(kind=double)                               :: LargePatts
        end function

        function CAL_getLargePatternSize2(Efrom, Eto) &
        result(LargePatts)
            use CalTypes
            real(kind=double), intent(in)                   :: Efrom, Eto
            real(kind=double)                               :: LargePatts
        end function

    end interface


    interface CAL_getFilterTransmission

        function CAL_getFilterTransmission1(E, theta, phi) result(transmission)
            use CalTypes
            real(kind=double), intent(in)                   :: E, &
                                                               theta, phi
            real(kind=double)                               :: transmission
        end function

        function CAL_getFilterTransmission2(Efrom, Eto, theta, phi) &
        result(transmission)
            use CalTypes
            real(kind=double), intent(in)                   :: Efrom, Eto, &
                                                               theta, phi
            real(kind=double)                               :: transmission
        end function

    end interface


    interface CAL_correctTime
        subroutine CAL_correctTime1(timeCoordinate)
            use CalTypes
            real(kind=double), dimension(:), intent(inout)  :: timeCoordinate
        end subroutine


        subroutine CAL_correctTime2(timeCoordinate, rawY)
            use CalTypes
            real(kind=double), dimension(:), intent(inout)  :: timeCoordinate
            integer(kind=int16), dimension(:), intent(in)   :: rawY
        end subroutine


        subroutine CAL_correctTime3(timeCoordinate, rawY, sourceY)
            use CalTypes
            real(kind=double), dimension(:), intent(inout)  :: timeCoordinate
            integer(kind=int16), dimension(:), intent(in)   :: rawY
            integer(kind=int16), intent(in)                 :: sourceY
        end subroutine
    end interface


    interface CAL_omPhotoNatural
        function CAL_omPhotoNatural0(rawRate, frameTime, &
                                     deadFrac, eventLoss, &
                                     extendedSource, &
                                     rawRateErrorMinus, rawRateErrorPlus, &
                                     naturalRateErrorMinus, &
                                     naturalRateErrorPlus) result(result)
            use CalTypes
            real(kind=double), intent(in)           :: rawRate, &
                                                       frameTime, &
                                                       deadFrac
            logical, intent(in)                     :: extendedSource
            real(kind=double), intent(in)           :: eventLoss
            real(kind=double), intent(in), optional :: rawRateErrorMinus, &
                                                       rawRateErrorPlus
            real(kind=double), intent(out), optional:: naturalRateErrorMinus, &
                                                       naturalRateErrorPlus
            real(kind=double)                       :: result
        end function


        function CAL_omPhotoNatural1(rawRate, frameTime, &
                                     deadFrac, eventLoss, &
                                     extendedSource, &
                                     empiricalLinearityCorrection) &
                                                            result(naturalRate)
            use CalTypes
            type(ValueAsymmetricErrorT)             :: rawRate
            real(kind=double), intent(in)           :: frameTime, &
                                                       deadFrac, &
                                                       eventLoss
            logical, intent(in), optional           :: extendedSource, &
                                                   empiricalLinearityCorrection
            type(ValueAsymmetricErrorT)             :: naturalRate
        end function
    end interface    


    interface CAL_setState
		subroutine CAL_setState1(instrument, ccdChipId, ccdNodeId, &
                                 ccdModeId, filterId, &
                                 accuracyLevel, &
                                 temperature, temperatureCamera, &
                                 exposureStartTime, exposureDuration, &
                                 ocb, randomize, temperatureTracking, &
                                 auxiliaryParameter)
            use CalTypes
			integer(kind=int32), optional, intent(in)	:: &
					instrument, &           ! current instrument
					ccdChipId, &        	! CCD identifier (>=1)
					ccdNodeId, &            ! the readout node (>=0)
                    ccdModeId, &            ! current mode
					filterId, &             ! a filter Id (>=0)
                    ocb, &                  ! on-chip binning factor
				  	accuracyLevel           ! what it says
			real(kind=double), optional, intent(in)		:: &
					temperature, &          ! [K] CCD temperature
					temperatureCamera, &    ! [K] temp. of camera structure
                    exposureStartTime, &    ! [d] observation start time as MJD
                    exposureDuration, &     ! in [s]
                    auxiliaryParameter      ! auxiliary parameter
            logical, optional, intent(in)               :: &
                    randomize, &            ! randomize input quantities
                    temperatureTracking     ! perform T tracking

        end subroutine


        subroutine CAL_setState2(dataSetName)
            character(len=*), intent(in)    :: dataSetName
        end subroutine


        subroutine CAL_setState3(inSet)
            use dal
            type(DataSetT), intent(in)                      :: inSet
        end subroutine


        subroutine CAL_setState4(inBlock)
            use dal
            type(BlockT), intent(in)                        :: inBlock
        end subroutine
    end interface


    !
    !   get effective area
    !
    interface CAL_getEffectiveArea
        function CAL_getEffectiveArea1(E, theta, phi) result(area)
            use CalTypes
            real(kind=double), intent(in)                   :: E, &
                                                               theta, phi
            real(kind=double)                               :: area
        end function

        function CAL_getEffectiveArea2(Efrom, Eto, theta, phi) result(area)
            use CalTypes
            real(kind=double), intent(in)                   :: Efrom, Eto, &
                                                               theta, phi
            real(kind=double)                               :: area
        end function
    end interface


    interface CAL_rgsGetEffectiveArea
        function CAL_rgsGetEffectiveArea1(E, order, theta, phi) result(area)
            use CalTypes
            real(kind=double), intent(in)                   :: E, &
                                                               theta, phi
            integer(kind=int32), intent(in)                 :: order
            real(kind=double)                               :: area
        end function

        function CAL_rgsGetEffectiveArea2(Efrom, Eto, order, theta, phi) &
        result(area)
            use CalTypes
            real(kind=double), intent(in)                   :: Efrom, Eto, &
                                                               theta, phi
            integer(kind=int32), intent(in)                 :: order
            real(kind=double)                               :: area
        end function
    end interface



    !
    !   releasing dynamically allocated memory
    !
    interface CAL_releaseMemory
        subroutine CAL_releaseMemoryInt3OneDim(a1, a2, a3)
            use CalTypes
            integer(kind=int32), dimension(:), pointer     :: a1
            integer(kind=int32), dimension(:), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryInt3TwoDim(a1, a2, a3)
            use CalTypes
            integer(kind=int32), dimension(:, :), pointer  :: a1
            integer(kind=int32), dimension(:, :), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryLogicalOneDim(a1, a2, a3)
            use CalTypes
            logical, dimension(:), pointer                 :: a1
            logical, dimension(:), pointer, optional       :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryReal2OneDim(a1, a2, a3)
           use CalTypes
            real(kind=double), dimension(:), pointer       :: a1
            real(kind=double), dimension(:), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryReal2TwoDim(a1, a2, a3)
            use CalTypes
           real(kind=double), dimension(:, :), pointer     :: a1
           real(kind=double), dimension(:, :), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryInt2OneDim(a1, a2, a3)
            use CalTypes
            integer(kind=int16), dimension(:), pointer     :: a1
            integer(kind=int16), dimension(:), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryInt2TwoDim(a1, a2, a3)
            use CalTypes
            integer(kind=int16), dimension(:, :), pointer  :: a1
            integer(kind=int16), dimension(:, :), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryReal1OneDim(a1, a2, a3)
            use CalTypes
            real(kind=single), dimension(:), pointer      :: a1
            real(kind=single), dimension(:), pointer, optional &
                                                          :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryReal1TwoDim(a1, a2, a3)
            use CalTypes
            real(kind=single), dimension(:, :), pointer   :: a1
            real(kind=single), dimension(:, :), pointer, optional &
                                                          :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryInt1OneDim(a1, a2, a3)
            use CalTypes
            integer(kind=int8), dimension(:), pointer  :: a1
            integer(kind=int8), dimension(:), pointer, optional  :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryInt1ThreeDim(a1, a2, a3)
            use CalTypes
            integer(kind=int8), dimension(:, :, :), pointer  :: a1
            integer(kind=int8), dimension(:, :, :), pointer, optional &
                                                          :: a2, a3
        end subroutine

    end interface

end module Cal
