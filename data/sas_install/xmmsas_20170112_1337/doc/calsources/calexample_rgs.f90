!
!   calexample_rgs.f90 --- example program to show usage of the CAL for RGS
!
!   DESCRIPTION:
!       This acts as an example program to show how the CAL
!       is supposed to be used from SAS tasks written in Fortran90.
!
!   AUTHOR:
!       U. Lammers, Fri Nov 14 12:08:05 MET 1997
!
!   $Header: /sasbuild/sas_git_repo/cvs_copy/sasdev/sas/packages/cal/f90test/calexample_rgs.f90,v 1.15 2003/10/03 14:15:40 sasbuild Exp $
!
program calexample_rgs

use cal             ! use the Calibration Access Layer
implicit none
    integer                        :: i, j, ccdNr, nodeNr
    integer(int16)                 :: itmp
    integer(int16), dimension(:), pointer :: &
                                   rawX => null(), rawY => null(), &
                                   badPixType => null(), yextent => null()
    logical, dimension(:), pointer :: uplinked => null()
    integer(int16), dimension(0:5) :: &
                                   rawXtest = (/1, 23, 34, 56, 118, 567/),&
                                   rawYtest = (/1, 234, 43, 56, 98, 876/)
    character(len=2)               :: ccdid
    integer                        :: ccdidlen
    real(double)                   :: cenx, ceny, cenz

    real(double), dimension(:), pointer :: xmilli => null(), ymilli => null(),&
                                           zmilli => null()
    real(single), dimension(RGS_MIN_X:RGS_MAX_X,RGS_MIN_Y:RGS_MAX_Y):: &
                                           rbadpixmap
    integer(int16), dimension(:,:), pointer :: ibadpixmap => null()
    real(single), dimension(0:5)   :: tr

    type(BoresightT)                       :: boresight
    real(double), dimension(:,:), pointer  :: matrix => null()
    real(double)               :: focalLength, plateScaleX
    character(len=*), parameter     :: myBadPixFile = &
                                      'rgs1_badpix.ccf'
    type(CalInfo)                   :: badPixFileInfo

    !
    !   set the state of the CAL from the contents of an ODF science file -
    !   in the absence of real example file set the state explicitely
    !
    !call CAL_setState('rgs1.fits')
    call CAL_setState(RGS1, ccdChipId=RGS_CCD_1, ccdNodeId=0, &
                      ocb=1, randomize = .false.)
    
    !
    !   select low-accuracy calibration, e.g., parametric PSFs
    !
    call CAL_setState(accuracyLevel = ACCURACY_LOW)

    !
    !   check details of RGS BadPixel file in CCF and replace it with local
    !   version
    !
    call CAL_ccfInfo('BADPIX', badPixFileInfo)
    call writeCalFileInfo(badPixFileInfo)

    !
    !   get bad pixel table
    !
    write(*, *)
    write(*, *) 'Getting bad pixel tables'

    do ccdNr=RGS_CCD_FIRST, RGS_CCD_LAST
       do nodeNr=0, 1
           call CAL_setState(ccdChipId = ccdNr, ccdNodeId = nodeNr)
           call CAL_getBadPixelList(rawX, rawY, badPixType, yextent, uplinked)
           write (*, *) 'RGS1 chip #', ccdNr, '/', nodeNr, ' has ', &
                 size(rawX), ' bad pixels:'
           write (*, *) '   x    y   defect  y-extent uplinked'
           do i=0, size(rawX)-1
              write(*, '(I5,I5,I9,I10,5X,L1)') rawX(i), rawY(i), &
                    badPixType(i), yextent(i), uplinked(i)
           enddo
           call CAL_releaseMemory(rawX, rawY)
           call CAL_releaseMemory(badPixType, yextent)
           call CAL_releaseMemory(uplinked)
       enddo
    enddo

    write(*, *)
    call CAL_setState(ccdChipId = RGS_CCD_2, ccdNodeId = 0)
    if (CAL_isPixelBad(14_int16, 33_int16, defect=itmp) .and. itmp .eq. HOT) &
    then
          write(*, *) 'Pixel of RGS1 CCD #2 (14,43) is hot'
    endif

    call CAL_setState(ccdChipId = RGS_CCD_1)
    call CAL_getBadPixelMap(ibadpixmap)

!    call pgbeg(0, ' ', 1, 1)
!    call pgenv(real(RGS_MIN_X, single), real(RGS_MAX_X, single), &
!               real(RGS_MIN_Y, single), real(RGS_MAX_Y, single), 1, 1)
!    call pglab('(x [pixel])', '(y [pixel])', &
!         'Bad Pixel Map for central RGS-1 CCD')
!    tr(0) = 0.;
!    tr(1) = 1.;
!    tr(2) = 0.;
!    tr(3) = 0.;
!    tr(4) = 0.;
!    tr(5) = 1.;
!    rbadpixmap = real(ibadpixmap, single)
!    call pgimag(rbadpixmap, size(rbadpixmap, 1), size(rbadpixmap, 2), &
!                1, size(rbadpixmap, 1), 1, size(rbadpixmap, 2), &
!                1., 13., tr);
    call CAL_releaseMemory(ibadpixmap)

    !
    !   get boresight matrix
    !
    boresight = CAL_getBoresight(0.d0)
    matrix => CAL_toDirectionCosineMatrix(boresight)
    write(*, *)
    write(*, *) 'boresight misalignment matrix for RGS1 at start of obs:'
    do i=0, 2
        write(*, '(3(F6.3, 1X))') (matrix(i, j), j=0, 2)
    enddo

    !
    !   misc data
    !
    call CAL_getMiscellaneousData('FOCAL_LENGTH', focalLength)
    call CAL_getMiscellaneousData('MM_PER_PIXEL_X', plateScaleX);
    write(*, *)
    write(*, *) 'Focal length of telescope is [m]: ', focalLength    
    write(*, *) 'Plate scale is [mm/pixel]   : ', plateScaleX

    !
    !   pixel to mm
    !
    call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli)
    call CAL_sacCoordToCamCoord2(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord2ToCamCoord1(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord1ToChipCoord(xmilli, ymilli, zmilli, rawX, rawY)
    write(*, *)
    write(*, *) 'conversion of pixel to mm and vice versa:'
    do i=0, size(rawXtest)-1
       write(*, '(I3, A1, I3, A1, 3F10.3, 1X, A1, 1X, I3, A1, I3)') &
            rawXtest(i), '/', rawYtest(i), '=', &
            xmilli(i), ymilli(i), zmilli(i), '=', rawX(i), '/', rawY(i)
    enddo
    call CAL_releaseMemory(xmilli, ymilli, zmilli)
    call CAL_releaseMemory(rawX, rawY)


    !
    !   produce plot showing CCDs in focal plane
    !
    do nodeNr=0, 1
        write(*, *) 'node ', nodeNr
!        call pgenv(-130., 130., -20., 20., 1, 1)
!        call pglab('(DET x [mm])', '(DET y [mm])', 'RGS CCD layout')

        do i=RGS_CCD_FIRST, RGS_CCD_LAST
            call CAL_setState(ccdChipId = i, ccdNodeId = nodeNr)
            rawXtest(0) = RGS_MIN_X
            rawXtest(1) = RGS_MAX_X
            rawXtest(2) = RGS_MAX_X
            rawXtest(3) = RGS_MIN_X
            rawXtest(4) = RGS_MIN_X
            rawYtest(0) = RGS_MIN_Y
            rawYtest(1) = RGS_MIN_Y
            rawYtest(2) = RGS_MAX_Y
            rawYtest(3) = RGS_MAX_Y
            rawYtest(4) = RGS_MIN_Y
            call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli, &
                              DETECTOR_GEOCENTER_SYSTEM)
            cenx = .25*(xmilli(0) + xmilli(1) + xmilli(2) + xmilli(3))
            ceny = .25*(ymilli(0) + ymilli(1) + ymilli(2) + ymilli(3))
!            call pgline(5, xmilli, ymilli)
!            call pgnumb(i, 0, 1, ccdid, ccdidlen)
!            call pgsch(2.)
!            call pgptxt(cenx, ceny, 0., .5, ccdid)
!            call pgsch(1.)
!            call pgarro(xmilli(0), ymilli(0), xmilli(1), ymilli(1))
!            call pgptxt(xmilli(1), ymilli(1), 0., .5, 'x')
!            call pgarro(xmilli(0), ymilli(0), xmilli(3), ymilli(3))
!            call pgptxt(xmilli(3), ymilli(3), 0., .5, 'y')

            call CAL_releaseMemory(xmilli, ymilli, zmilli)
        enddo

!        call pgenv(-130., 130., -20., 20., 1, 1)
!        call pglab('(DET x [mm])', '(DET z [mm])', 'RGS CCD layout')

        do i=RGS_CCD_FIRST, RGS_CCD_LAST
            call CAL_setState(ccdChipId = i, ccdNodeId = nodeNr)
            rawXtest(0) = RGS_MIN_X
            rawXtest(1) = RGS_MAX_X
            rawXtest(2) = RGS_MAX_X
            rawXtest(3) = RGS_MIN_X
            rawXtest(4) = RGS_MIN_X
            rawYtest(0) = RGS_MIN_Y
            rawYtest(1) = RGS_MIN_Y
            rawYtest(2) = RGS_MAX_Y
            rawYtest(3) = RGS_MAX_Y
            rawYtest(4) = RGS_MIN_Y
            call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli, &
                              DETECTOR_GEOCENTER_SYSTEM)
            cenx = .25*(xmilli(0) + xmilli(1) + xmilli(2) + xmilli(3))
            cenz = .25*(zmilli(0) + zmilli(1) + zmilli(2) + zmilli(3))
!            call pgline(5, xmilli, zmilli)
!            call pgnumb(i, 0, 1, ccdid, ccdidlen)
!            call pgsch(2.)
!            call pgptxt(cenx, cenz, 0., .5, ccdid)
!            call pgsch(1.)
!            call pgarro(xmilli(0), zmilli(0), xmilli(1), zmilli(1))
!            call pgptxt(xmilli(1), zmilli(1), 0., .5, 'x')
!            call pgarro(xmilli(0), zmilli(0), xmilli(3), zmilli(3))
!            call pgptxt(xmilli(3), zmilli(3), 0., .5, 'z')

            call CAL_releaseMemory(xmilli, ymilli, zmilli)
        enddo
    enddo

!    call pgend
end program


subroutine writeCalFileInfo(badPixFileInfo)
use CAL
type(CalInfo), intent(in)   :: badPixFileInfo

    write(*, *) 'RGS BadPixel calibration file:'
    write(*, *) 'instrument        : ', badPixFileInfo%instrument
    write(*, *) 'type              : ', badPixFileInfo%calType
    write(*, *) 'name              : ', badPixFileInfo%fileName
    write(*, *) 'creation date     : ', badPixFileInfo%date
    write(*, *) 'validity date     : ', badPixFileInfo%valDate
    write(*, *) 'issue number      : ', badPixFileInfo%issue
end subroutine


