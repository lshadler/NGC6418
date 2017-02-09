!------------------------------------------------------------------------------
!
!                       XMM Science Analysis System (SAS)
!                     (c) 1997 - 2010 European Space Agency
!
!------------------------------------------------------------------------------
!
!   oal.f90 --- ODF Access Layer interface specifications ---
!
!   DESCRIPTION:
!       This modules contains the interface specifications for the
!       ODF Access Layer which provides ODF-related utility functions
!       for the SAS tasks.
!
!   EXPORTED FUNCTIONS:
!       All functions exported by this module start with "OAL_" - this
!       substring is omitted in the following list:
!
!       OAL control:
!       ------------
!       openOdf                 --- open an Observation Data File (ODF)
!       setState                --- define the OAL state
!       getState                --- retrieve OAL state infos
!
!       ODF access:
!       -----------
!       selectScope             --- number exposures for instrument/type pair
!       selectExposure          --- number of available files for exposure
!       selectScopeAndExposure  --- number of available files for exposure
!       selectFile              --- get ODF file name
!       expandSetName           --- expand a file name from symbolic form
!       frameCounterToObt       --- convert CCD frame counters OBT tag
!       obtToTimeTag            --- convert OBT tag to time tag
!       ertToTimeTag            --- convert ERT string to time tag
!       getAttitude             --- get actual S/C attitude
!       getPosition             --- get S/C position
!       getBadPixelList         --- get list of bad pixels
!
!       inquiry and auxiliary:
!       ----------------------
!       odfInfo                 --- inquire information about open ODF
!       proposalInfo            --- inquire information about proposal
!       exposureInfo            --- inquire information about selected exposure
!       hasIPPV                 --- check if IPPV with given name exists
!       getIPPVstring           --- retrieve IPPV as string value
!       getIPPVreal             --- retrieve IPPV as real value
!       getIPPVint              --- retrieve IPPV as integer value
!       hasconfIPPV             --- check if config  IPPV with given name exists
!       getconfIPPVstring       --- retrieve config IPPV as string value
!       getconfIPPVreal         --- retrieve config IPPV as real value
!       getconfIPPVint          --- retrieve config IPPV as integer value
!       toAttitudeMatrix        --- convert (Ra/Dec/APos) typle into att.matrix
!       toEulerAngles           --- convert (Ra/Dec/APos) into 321 Euler angles
!       addCommonAttributes     --- add OAL-related attributes to data set
!       releaseMemory           --- free up dynamically allocated memory
!
!   CHANGE HISTORY:
!       UL, 1997-11-12: 1.0.0: - first version
!       UL, 1998-??-??: 1.1.0: - 'OAL_frameCounterToObt' and 'OAL_obtToTimeTag'
!                                combined into 'OAL_frameCounterToTime'
!                              - various minor changes
!       UL, 1998-08-20: 2.0.0: - dropped 'status'/'verbosity'/
!                                'observationStartDate' from state
!                              - dropped 'OAL_error' routine
!                              - new boolean state variable 'attitudefromAhf'
!                                which selects either the Attitude History File
!                                or the OM tracking history file as source
!                                of attitude data
!                              - 'directoryName' fields added to OAL_odfInfo
!                              - new auxiliary functions 'OAL_toAttitudeMatrix'
!                              - renamed
!                                    'OAL_selectType' -> 'OAL_selectScope'
!                                    'OAL_openODF'    -> 'OAL_openOdf'
!                              - new enquiry function 'OAL_exposureInfo'
!                              - new routine 'OAL_releaseMemory'
!                              - types of return values from 'OAL_getAttitude'
!                                and 'OAL_getPosition' have changed
!                              - 'OAL_frameCounterToTime' has been split into
!                                'OAL_frameCounterToObt' and 'OAL_obtToTimeTag'
!       UL, 1998-09-30: 2.1.0: - new inquiry function OAL_proposalInfo
!       UL, 1998-10-15: 2.2.0: - two additional fields
!                                'scheduled/actualExposureLength' in
!                                'ExposureInfoType'
!                              - additional field 'isSlew' in 'OdfInfoType'
!                              - new inquiry function 'OAL_activeFilter'
!       UL, 1999-02-03: 2.3.0: - added toEulerAngles routine
!                              - ProposalInfoType%Institute is now 80 chars
!       UL, 1999-02-22: 2.4.0: - dropped field 'scheduled/actualExposureLength'
!                                as these can now be calculated with new
!                                routine: 'toTimeTag' in caloaldefs.h
!       UL, 1999-04-01: 2.5.0: - made OAL_setState an interface routine
!                                which is overloaded with three subroutines
!                                to set the state from
!                                   a) explicit list of values
!                                   b) name of data set
!                                   c) reference to data set Block
!                              - updated documentation to be in line with
!                                new list of modes
!       UL, 1999-06-03: 3.0.0: - removed obsolete vector-length arguments
!                                from vector processing routines
!                              - added ertToTimeTag
!       UL, 1999-06-15: 3.1.0: - getPosition() also returns velocity vector
!                                optionally
!       UL, 1999-08-18: 3.2.0: - made getPosition/getAttitude logical functions
!                                return false when no position/attitude info
!                                is available for requested time
!       UL, 1999-12-16: 3.3.0: - added IPPV related inquiry functions
!       UL, 2000-02-24: 3.4.0: - getPosition() returns optionally also
!                                revolution number
!       UL, 2000-05-31: 3.5.0: - added
!                                    * OAL_hasAssociatedSet()
!                                    * OAL_selectAssociatedSet()
!       UL, 2000-06-15: 3.6.0: - added
!                                    * OAL_hasSet()
!       UL, 2000-09-26: 3.7.0: - added OAL_getIPPVint()
!                              - OAL_getPPPVstring() is now a function
!                              - removed obsolete OAL_activeFilter()
!       UL, 2001-03-08: 3.8.0: - SpacecraftAttitudeType now comes from
!                                CalOalDefs in caloalutils
!       UL, 2001-03-23: 3.9.0: - added
!                                    * OAL_getBadPixelList
!       UL, 2001-08-10: 4.0.0: - added optional 'exposureId' parameter to
!                                setState() to support exposure selection
!                                by ODF exposure designator e.g. "U571"
!                              - added arguments 'scheduled'/'exposureNrOdf'
!                                to getState()
!                              - added
!                                   * OAL_selectScopeAndExposure()
!                              - added 'instrExposureId' argument to setState()
!       RDS, 2003-12-04: 4.1.0: - added OAL_getRGSDiagImage()
!       RDS, 2003-12-12: 4.1.1: - removed OAL_getRGSDiagImage()
!       RDS, 2006-1-10: 4.2: - added OAL_hasconfIPPV and associated gets
!
!   AUTHOR:
!       UL, Wed Nov 12 18:03:35 WET 1997
!
!   REFERENCES:
!       [1]: Software Specification Document for the XMM Science Analysis
!            Subsystem, M. Dahlem et. al., 
!
!   $Header: /sasbuild/repositories/sasdev/sas/packages/oal/f90/oal.f90,v 1.35 2013/01/18 13:57:28 rsaxton Exp $
!
module Oal
    use CalOalDefs
    use OalTypes
    use types

    implicit none

    interface
    !------------------------------------------------------------------------
    !                    the subroutine interface                           !
    !------------------------------------------------------------------------

        !
        ! ---( control functions )------------------------------------------
        ! 
        subroutine OAL_setStateFromSetName(scienceFileName)
            character(len=*), intent(in)                :: scienceFileName
        end subroutine


        subroutine OAL_openOdf(directoryName)
            character(len=*), intent(in)    :: directoryName
        end subroutine


        subroutine OAL_getState(instrument, dataMode, exposureNr, scheduled, &
                                ccdNr, nodeNr, attitudeFromAhf, &
                                exposureNrOdf, timeJumpThreshold)
            use types
            integer(kind=int32), optional, intent(out)  :: instrument, &
                                               dataMode, &
                                               exposureNr, &
                                               ccdNr, &
                                               nodeNr, &
                                               exposureNrOdf, &
                                               timeJumpThreshold
            logical, optional, intent(out)               :: attitudeFromAhf, &
                                                            scheduled
        end subroutine


        !
        ! ---( ODF access functions )----------------------------------------
        !
        integer function OAL_selectScope(instrument, dataMode)
            integer, intent(in)             :: instrument, &
                                               dataMode
        end function


        integer function OAL_selectExposure(exposureNr)
            integer, intent(in)             :: exposureNr
        end function


        integer function OAL_selectScopeAndExposure(instrument, exposureId)
            integer, intent(in)             :: instrument
            character(len=*), intent(in)    :: exposureId
        end function


        subroutine OAL_selectFile(ccdNr, fileName)
            integer, intent(in)             :: ccdNr
            character(len=*), intent(out)   :: fileName
        end subroutine


        character(len=256) function OAL_selectSet(ccdNr)
            integer, intent(in)             :: ccdNr
        end function


        logical function OAL_hasSet(ccdNr)
            integer, intent(in)             :: ccdNr
        end function


        logical function OAL_hasAssociatedSet(dataMode)
            integer, intent(in)             :: dataMode
        end function


        character(len=256) function OAL_selectAssociatedSet(dataMode)
            integer, intent(in)             :: dataMode
        end function


        subroutine OAL_expandFileName(odfFileName, fileName)
            character(len=*), intent(in)    :: odfFileName
            character(len=*), intent(out)   :: fileName
        end subroutine


        character(len=256) function OAL_expandSetName(odfSetName)
            character(len=*), intent(in)    :: odfSetName
        end function


        subroutine OAL_frameCounterToObt(frameCounter, obt)
            use types
            integer(kind=int32), dimension(:), intent(in):: frameCounter
            real(kind=double), dimension(:), pointer     :: obt
        end subroutine


        subroutine OAL_obtToTimeTag(obt, time)
            use types
            real(kind=double), dimension(:), intent(in)  :: obt
            real(kind=double), dimension(:), pointer     :: time
        end subroutine


        function OAL_ertToTimeTag(ertString) result(result)
            use types
            real(kind=double)                           :: result
            character(len=*), intent(in)                :: ertString
        end function


        logical function OAL_getAttitude(timeTag, att)
            use CalOalDefs
            real(kind=double), intent(in)       :: timeTag
            type(SpacecraftAttitudeType), intent(out) &
                                                :: att
        end function


        logical function OAL_getPosition(timeTag, position, velocity, &
                                         revolution)
            use OalTypes
            real(kind=double), intent(in)      :: timeTag
            type(CartesianVectorType), intent(out) :: position
                                              ! Cartesian coordinates of
                                              ! spacecraft position in mean,
                                              ! geocentric, equatorial
                                              ! J2000 reference frame
            type(CartesianVectorType), intent(out), optional :: velocity
                                              ! Cartesian velocity vector
                                              ! in km/s
            real(kind=double), intent(out), optional         :: revolution
        end function


        logical function OAL_getBadPixelList(rawX, rawY, &
                                             type, yextent, uplinked)
            use types
            integer(kind=int16), dimension(:), pointer  :: rawX, rawY, &
                                                           type, yextent
            logical, dimension(:), pointer              :: uplinked
        end function


        !
        ! ---( inquiry / utility routines )---------------------------------
        !
        subroutine OAL_odfInfo(odfInfos)
            use OalTypes
            type(OdfInfoType), intent(out)  :: odfInfos
        end subroutine


        subroutine OAL_proposalInfo(proposalInfo)
            use OalTypes
            type(ProposalInfoType), intent(out)  :: proposalInfo
        end subroutine


        subroutine OAL_exposureInfo(exposureInfo)
            use OalTypes
            type(ExposureInfoType), intent(out)  :: exposureInfo
        end subroutine


        logical function OAL_hasIPPV(keyword)
            use types
            character(len=*), intent(in)     :: keyword
        end function


        character(len=32) function OAL_getIPPVstring(keyword)
            use types
            character(len=*), intent(in)     :: keyword
        end function


        function OAL_getIPPVint(keyword) result(value)
            use types
            integer(kind=int32)                 :: value
            character(len=*), intent(in)     :: keyword
        end function


        function OAL_getIPPVreal(keyword) result(value)
            use types
            real(kind=double)                :: value
            character(len=*), intent(in)     :: keyword
        end function

        logical function OAL_hasconfIPPV(keyword)
            use types
            character(len=*), intent(in)     :: keyword
        end function
                                                                                
                                                                                
        character(len=32) function OAL_getconfIPPVstring(keyword)
            use types
            character(len=*), intent(in)     :: keyword
        end function
                                                                                
                                                                                
        function OAL_getconfIPPVint(keyword) result(value)
            use types
            integer(kind=int32)                 :: value
            character(len=*), intent(in)     :: keyword
        end function
                                                                                
                                                                                
        function OAL_getconfIPPVreal(keyword) result(value)
            use types
            real(kind=double)                :: value
            character(len=*), intent(in)     :: keyword
        end function


        subroutine OAL_toAttitudeMatrix(att, matrix)
            use CalOalDefs
            type(SpacecraftAttitudeType), intent(in) :: att
            real(kind=double), dimension(0:2,0:2), intent(out) :: matrix
        end subroutine

        subroutine OAL_toEulerAngles(matrix, eulerAngles)
            use OalTypes
#ifdef  NAGf90Fortran
            real(kind=double), dimension(:,:), intent(in) :: matrix
#else
            real(kind=double), dimension(:,:), intent(in), contiguous :: matrix
#endif
            type(EulerAnglesType), intent(out)       :: eulerAngles
        end subroutine


        subroutine OAL_addCommonAttributes(set)
            use dal
            type(DataSetT), intent(inout)                 :: set
        end subroutine

    end interface


    interface OAL_setState
        subroutine OAL_setState1(instrument, dataMode, exposureNr, scheduled, &
                                 ccdNr, nodeNr, attitudeFromAhf, &
                                 instrExposureId, timeJumpThreshold)
            use types
            integer(kind=int32), optional, intent(in)   :: instrument, &
                                               dataMode, &
                                               exposureNr, &
                                               ccdNr, &
                                               nodeNr, &
                                               timeJumpThreshold
            character(len=*), optional, intent(in)      ::instrExposureId
            logical, optional, intent(in)               :: attitudeFromAhf, &
                                                           scheduled
        end subroutine

        subroutine OAL_setState2(dataSetName)
            character(len=*), intent(in)                :: dataSetName
        end subroutine


        subroutine OAL_setState3(inSet)
            use dal
            type(DataSetT), intent(in)                      :: inSet
        end subroutine


        subroutine OAL_setState4(inBlock)
            use dal
            type(BlockT), intent(in)                        :: inBlock
        end subroutine
    end interface


    interface OAL_releaseMemory
        subroutine OAL_releaseMemoryReal2OneDim(a1, a2, a3)
            use types
            real(kind=double), dimension(:), pointer       :: a1
            real(kind=double), dimension(:), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine OAL_releaseMemoryInt2OneDim(a1, a2, a3)
            use types
            integer(kind=int16), dimension(:), pointer     :: a1
            integer(kind=int16), dimension(:), pointer, optional &
                                                           :: a2, a3
        end subroutine

        subroutine CAL_releaseMemoryLogicalOneDim(a1, a2, a3)
            use types
            logical, dimension(:), pointer                 :: a1
            logical, dimension(:), pointer, optional       :: a2, a3
        end subroutine

    end interface

end module Oal
