!
!   oalexample.f90 --- example program to show usage of the OAL
!
!   DESCRIPTION:
!       This acts as an example program to show how the OAL
!       is supposed to be used from SAS tasks written in Fortran90.
!
!   AUTHOR:
!       UL, Tue Nov 25 14:28:46 MET 1997
!
!   $Header: /sasbuild/repositories/sasdev/sas/packages/oal/f90test/oalexample.f90,v 1.22 2003/06/16 08:41:35 gvacanti Exp $
!
program oalexample

use dal
use oal             ! use the ODF Access Layer
use caloaldefs
use errorhandling

    implicit none
    type(DataSetT)                      :: set

    character(len=*), parameter         :: odfDir = '../odf'
    type(OdfInfoType)                   :: odfinfos
    type(ProposalInfoType)              :: propInfos
    type(ExposureInfoType)              :: expInfos
    integer                             :: nExps, nCCDs, nodeNr
    character(len=256)                  :: fileName

    !
    !   open the ODF in directory odfDir and obtain infos
    !
    call OAL_openOdf(odfDir)   ! open the ODF in directory '../odf'
    call OAL_odfInfo(odfinfos)
    write(*, *) 'XMM ODF in directory ', odfDir
    write(*, *) 'revolution number          : ', odfinfos%revolutionNr
    write(*, *) 'proposal id                : ', odfinfos%proposalId
    write(*, *) 'observation id             : ', odfinfos%observationId
    write(*, *) 'total number of files      : ', odfinfos%nrFiles
    write(*, *) 'observation start time     : ', odfinfos%observationStartTime
    write(*, *) 'observation start time [s] : ', &
        toTimeTag(odfinfos%observationStartTime)
    write(*, *) 'observation end time       : ', odfinfos%observationEndTime
    write(*, *) 'observation end time [s]   : ', &
        toTimeTag(odfinfos%observationEndTime)
    write(*, *) '=> length of obs in [s]    : ', &
        toTimeTag(odfinfos%observationEndTime) - &
        toTimeTag(odfinfos%observationStartTime)
    write(*, *) 'directory                  : ', odfinfos%directoryName(1:70)
    if (odfInfos%isSlew) then
        write(*, *) 'type of ODF                : SLEW'
    else
        write(*, *) 'type of ODF                : POINTING'
    endif
    write(*, *)

    call OAL_proposalInfo(propInfos)
    write(*, *) 'GO name                    : ', propInfos%GoName
    write(*, *) 'GO institute               : ', propInfos%GoInstitute
    write(*, *) 'GO address                 : ', propInfos%GoAddress
    write(*, *) 'GO e-mail                  : ', propInfos%GoEmail
    write(*, *) 'AO                         : ', propInfos%AO
    write(*, *) 'science type               : ', propInfos%scienceType
    write(*, *) 'target name                : ', propInfos%targetName
    write(*, *) 'target RA                  : ', propInfos%targetRa
    write(*, *) 'target Dec                 : ', propInfos%targetDec
    write(*, *) 'duration of observation [s]: ', propInfos%obsDuration
    write(*, *) 'boresight RA               : ', propInfos%boresightRa
    write(*, *) 'boresight Dec              : ', propInfos%boresightDec
    write(*, *) 'position angle constr (lo) : ', propInfos%posAngleConstLo
    write(*, *) 'position angle constr (hi) : ', propInfos%posAngleConstHi
    write(*, *) 'position angle orig. ref.  : ', propInfos%posAngleOrigRef
    write(*, *) 'EMOS1 priority             : ', propInfos%emos1Prio
    write(*, *) 'EMOS2 priority             : ', propInfos%emos2Prio
    write(*, *) 'EPN priority               : ', propInfos%epnPrio
    write(*, *) 'RGS1 priority              : ', propInfos%rgs1Prio
    write(*, *) 'RGS2 priority              : ', propInfos%rgs2Prio
    write(*, *) 'OM priority                : ', propInfos%omPrio

    write(*, *)
    nExps = OAL_selectScope(XMM, SUMMARY_INFORMATION)
    call OAL_selectFile(0, fileName);
    write(*, *) 'name of the ODF summary file is : ', fileName(1:80)
    write(*, *)

    !
    !   specify which instrument/modes one is interested in
    !
    nExps = OAL_selectScope(EMOS1, IMAGING)
    write(*, '("number of EMOS1 exposures in IMAGE mode     : ", I3)') nExps

    !
    !   select data from first exposure
    !
    nCCDs = OAL_selectExposure(1);
    write(*, '("number of files in exposure #1 (diff. CCDs): ", I3)') nCCDs

    !
    !   select data from central CCD
    !
    call OAL_selectFile(EMOS_CCD_CENTRAL, fileName)
    write(*, *) 'event list file name central CCD  : ', fileName(1:80)
    call OAL_getState(nodeNr = nodeNr)
    write(*, *) 'events read through node          : ', nodeNr
    write(*, *)

    !
    !   inquire information about exposure 1
    !
    nCCds = OAL_selectExposure(1)
    call OAL_setState(nodeNr = 0)
    call OAL_exposureInfo(expInfos)
    write(*, *) 'Exposure number            : ', expInfos%number
    write(*, *) 'is this exposure scheduled?: ', expInfos%scheduled
    if (expInfos%type == 0) then
        write(*, *) 'type of exposure           : SCIENCE'
    else
        write(*, *) 'type of exposure           : CALIBRATION'
    endif
    write(*, *) 'Scheduled start time       : ', &
            expInfos%scheduledStartTime(1:23)
    write(*, *) 'Scheduled end   time       : ', &
            expInfos%scheduledEndTime(1:23)
    write(*, *) 'scheduled exposure length  : ', &
            toTimeTag(expInfos%scheduledEndTime(1:23)) - &
            toTimeTag(expInfos%scheduledStartTime(1:23))
    write(*, *) 'actual    start time       : ', &
            expInfos%actualStartTime(1:23)
    write(*, *) 'actual end time            : ', &
            expInfos%actualEndTime(1:23)
    write(*, *) 'actual exposure length     : ', &
            toTimeTag(expInfos%actualEndTime(1:23)) - &
            toTimeTag(expInfos%actualStartTime(1:23))

    !
    !   convert frame counter to time tag
    !
    call frameCountersToTimes


    !
    !   attitude data retrieval
    !
    call attitudeData


    !
    !   position data retrieval
    !
    call positionData

    set = dataSet("test.dat", CREATE)
    call OAL_addCommonAttributes(set)
    call release(set)

    call message(AppMsg, Verbose, 'oalexample Ok')
end program


subroutine frameCountersToTimes
    use types
    use dal
    use oal
    use errorhandling

    type(DataSetT) set
    type(TableT) tab
    type(ColumnT) col
    integer(kind=int32), dimension(:), pointer :: i32 => null()
    integer(kind=int32), dimension(0:10)       :: framenr
    real(kind=double), dimension(:), pointer :: obtTags => null(), timeTags => null()
    character(len=256)                  :: fileName
    integer                             :: i

    !
    !   doing conversion for EMOS1
    !
    fileName = OAL_expandSetName('odf(EMOS1, AUXIL, 1, 0)')
    write(*, *) 'Reading frame numbers from EMOS1 aux file: ', &
        fileName(1:80);
    set = dataSet(fileName, READ)
    tab = table(set, 0)
    col = column(tab, "FRAME", READ)
    i32 => int32Data(col)
    do i = 0, 10
        framenr(i) = i32(i)
    enddo

    call OAL_frameCounterToObt(framenr, obtTags)
    call OAL_obtToTimeTag(obtTags, timeTags)
    write(*, *) 'Frame-# COBT                 time tag'
    do i=0, 10
        write(*, *) i32(i)
        if (obtTags(i)>0.) &
        write(*, '(I3, 3X, F20.6, 1X, F20.6)') i32(i), obtTags(i), timeTags(i)
    enddo

    call OAL_releaseMemory(obtTags, timeTags)
    call release(col)
    call release(set)

    !
    !   doing conversion for EPN
    !
    write(*, *)
    call OAL_setState(EPN, ccdNr=4)
    fileName = OAL_expandSetName('odf(EPN, IMA, 1, 4)')
    write(*, *) 'Reading frame numbers from EPN IMA file - ccd 4: ', &
        fileName(1:80)
    set = dataSet(fileName, READ)
    tab = table(set, 0)
    col = column(tab, "FRAME", READ)
    i32 => int32Data(col)
    do i = 0, 10
        framenr(i) = i32(i)
    enddo
    call OAL_frameCounterToObt(framenr, obtTags)
    call OAL_obtToTimeTag(obtTags, timeTags)
    write(*, *) 'Frame-# COBT                 time tag'
    do i=0, 11-1
        if (obtTags(i) > 0.)  &
        write(*, '(I3, 3X, F20.6, 1X, F20.6)') i32(i), obtTags(i), timeTags(i)
    enddo

    call OAL_releaseMemory(obtTags, timeTags)
    call release(col)
    call release(set)

    call OAL_setState(EMOS1, 0, 1)
end subroutine



subroutine attitudeData
use types
use oal
use errorhandling
    real(double)                     :: t
    type(SpacecraftAttitudeType)     :: att
    real(double), dimension(0:2,0:2) :: m
    integer                          :: i, j

    call OAL_setState(attitudeFromAhf = .true.)

    write(*, *)

    t =  52215007._double       ! start of exposure - when STime has a
                                ! f90-wrapper we change to a more readable
                                ! form
    if (OAL_getAttitude(t, att)) then
        write(*, '(A,F15.3)') 'Spacecraft attitude at beginning of exposure at ', t
        write(*, '(3F10.5)') att%ra, att%dec, att%apos
    else
        write(*, '(A,F15.3)') 'No attitude at beginning of exposure at ', t
    endif

    t =  52221907._double       ! middle of exposure - when STime has a
                                ! f90-wrapper we change to a more readable
                                ! form
    if (OAL_getAttitude(t, att)) then
       write(*, '(A,F15.3)') 'Spacecraft attitude in middle of exposure at ', t
       write(*, '(3F10.5)') att%ra, att%dec, att%apos
    else
       write(*, '(A,F15.3)') 'No attitude in middle of exposure at ', t
    endif


    t =  52228807._double       ! end of exposure - when STime has a
                                ! f90-wrapper we change to a more readable
                                ! form
    if (OAL_getAttitude(t, att)) then
        write(*, '(A,F15.3)') 'Spacecraft attitude at end of exposure at ', t
        write(*, '(3F10.5)') att%ra, att%dec, att%apos
    else
       write(*, '(A,F15.3)') 'No attitude in middle of exposure at ', t
    endif

    !
    !   compute attitude matrix
    !
    call OAL_toAttitudeMatrix(att, m)
    write(*, *) 'attitude matrix at end of exposure:'
    do i=0, 2
        write(*, '(3F7.4)') (m(i, j), j=0, 2)
    enddo

    write(*, *) 'Special angles:'
    att%ra=54.1674   * 3.1415926535 / 180.
    att%dec=0.5944   * 3.1415926535 / 180.
    att%apos=249.893 * 3.1415926535 / 180.
    call OAL_toAttitudeMatrix(att, m)
    write(*, *) 'attitude matrix at end of exposure:'
    do i=0, 2
        write(*, '(3F7.4)') (m(j, i), j=0, 2)
    enddo

end subroutine



subroutine positionData
use types
use oal
use errorhandling

    real(double)                        :: t
    type(CartesianVectorType)           :: position, velocity

    write(*, *)
    t =  64845121._double       ! start of exposure - when STime has a
                                ! f90-wrapper we change to a more readable
                                ! form
    if (OAL_getPosition(t, position, velocity)) then
        write(*, '(A,F15.3)') 'Spacecraft position/velocity at beginning of exposure at ', t
        write(*, '(3F20.5)') position%x, position%y, position%z
        write(*, '(3F20.5)') velocity%x, velocity%y, velocity%z
    else
        write(*, *) 'No position/velocity data available at beginning of exposure at ', t
    endif
end subroutine
