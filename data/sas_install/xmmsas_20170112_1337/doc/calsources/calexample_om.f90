!
!   calexample_om.f90 --- example program to show usage of the CAL for OM
!
!   DESCRIPTION:
!       This acts as an example program to show how the CAL
!       is supposed to be used from SAS tasks written in Fortran90.
!
!   AUTHOR:
!       U. Lammers, Fri Nov 14 12:08:05 MET 1997
!
!   $Header: /sasbuild/sas_git_repo/cvs_copy/sasdev/sas/packages/cal/f90test/calexample_om.f90,v 1.20 2007/04/26 09:36:05 rsaxton Exp $
!
program calexample_om

use cal             ! use the Calibration Access Layer
implicit none

    integer                        :: i, j

    real(double)                    :: stdCol12, stdMag2, &
                                       stdCol12e, stdMag2e, mag

    type(OMframeParameters)                      :: frameParameters
    type(OmFluxConvF)               :: fcf

    real(kind=single), dimension(:, :), pointer  :: psf => null()
    real(kind=double)                            :: plateScale, rawRate, &
                                                    naturalRate, magnitude

    integer(int16)                 :: itmp
    integer(int16), dimension(:), pointer :: &
                                   rawX => null(), rawY => null(), badPixType => null(),&
                                   yextent => null()
    logical, dimension(:), pointer :: uplinked => null()
    integer(int16), dimension(0:5) :: &
                                   rawXtest = (/1, 23, 34, 56, 118, 567/),&
                                   rawYtest = (/1, 234, 43, 56, 98, 876/)
    real(single), dimension(0:5)   :: rawXtestreal, rawYtestreal
    real(double)                   :: lambda
    real(single), dimension(:), pointer :: deltaX => null(), deltaY => null()
!    character(len=2)               :: ccdid
!    integer                        :: ccdidlen
!    real(single)                   :: cenx, ceny

    real(double), dimension(:), pointer :: xmilli => null(), ymilli => null(), zmilli => null()
    real(single), dimension(OM_MIN_X:OM_MAX_X,OM_MIN_Y:OM_MAX_Y):: &
                                           rbadpixmap
    integer(int16), dimension(:,:), pointer :: ibadpixmap => null()
    real(single), dimension(0:5)   :: tr

    type(BoresightT)                       :: boresight
    real(double), dimension(:,:), pointer  :: matrix => null()
    real(single), dimension(:,:), pointer  :: largeSenseMap => null(), pixelSenseMap => null()
    real(double)                   :: focalLength, plateScaleX

    character(len=*), parameter    :: myBadPixFile = &
                                      'om_badpix.ccf'
    type(CalInfo)                  :: badPixFileInfo

    real(double), dimension(:), pointer  :: dc => null()

    !
    !   set the state of the CAL from the contents of an ODF science file -
    !   in the absence of real example file set the state explicitely;
    !   select low-accuracy calibration, e.g., parametric PSFs
    !
    !call CAL_setStateFromScienceFile('om.fits')
    call CAL_setState(OM, 1, 0, accuracyLevel = ACCURACY_LOW)

    !
    !   check details of OM BadPixel file in CCF and replace it with local
    !   version
    !
    call CAL_ccfInfo('BADPIX', badPixFileInfo)
    call writeCalFileInfo(badPixFileInfo)

    call CAL_setCalibrationFile(myBadPixFile)

    call CAL_ccfInfo('BADPIX', badPixFileInfo)
    call writeCalFileInfo(badPixFileInfo)

    !
    !   get bad pixel table
    !
    write(*, *)
    write(*, *) 'Getting bad pixel tables'

    call CAL_getBadPixelList(rawX, rawY, badPixType, yextent, uplinked)
    write (*, *) 'OM detector chip has ', size(rawX), ' bad pixels:'
    write (*, *) '   x    y   defect  severity   y-extent uplinked'
    do i=0, size(rawX)-1
          write(*, '(I5,I5,I9,I9,I10,5X,L1)') rawX(i), rawY(i), &
                mod(badPixType(i), 10_int16), badPixType(i)/10, yextent(i), &
                uplinked(i)
    enddo
    call CAL_releaseMemory(rawX, rawY)
    call CAL_releaseMemory(badPixType, yextent)
    call CAL_releaseMemory(uplinked)

    write(*, *)
    if (CAL_isPixelBad(14_int16, 33_int16, defect=itmp) .and. itmp .eq. HOT) &
    then
          write(*, *) 'Pixel (14,43) is hot'
    endif

    call CAL_getBadPixelMap(ibadpixmap)
!    call pgbeg(0, ' ', 1, 1)
!    call pgenv(real(OM_MIN_X, single), real(OM_MAX_X, single), &
!               real(OM_MIN_Y, single), real(OM_MAX_Y, single), 1, 1)
!    call pglab('(x [pixel])', '(y [pixel])', 'Bad Pixel Map for OM CCD')
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

    write(*, *)
    if (CAL_isPixelBad(2046_int16, 1048_int16, defect=itmp) .and. &
        itmp .eq. DEAD) &
    then
          write(*, *) 'Pixel (2046,1048) on OM detector chip is dead'
    endif

    !
    !   distortions
    !
    lambda = 100._double
    rawXtestreal = real(rawXtest, single)
    rawYtestreal = real(rawYtest, single)
    call CAL_setState(filterId = UVW1)
    call CAL_omDistortion(rawXtestreal, rawYtestreal, deltaX, deltaY)

    write (*, *) 'Pixel distortions:'
    do i=0, size(rawXtestreal)-1
        write(*, '(I3, 1X, 2F6.1, 1X, 2F6.1)') i, rawXtestreal(i), &
            rawYtestreal(i), deltaX(i), deltaY(i)
    enddo
    call CAL_releaseMemory(deltaX, deltaY)
    write(*, *)

    !
    !   color transformation elements
    !
    call CAL_omColorTransform(UVW1, V, 4.5_double, 5.6_double, &
                              stdCol12, stdMag2, stdCol12e, stdMag2e)
    write(*, *) 'standard color/magnitude + errors'
    write(*, *) stdCol12, stdCol12e
    write(*, *) stdMag2, stdMag2e
    call CAL_omColorTransform(U, B, 12.0_double, 12.9_double, &
                              stdCol12, stdMag2, stdCol12e, stdMag2e)
    write(*, *) stdCol12, stdCol12e
    write(*, *) stdMag2, stdMag2e
    write(*, *)

    !
    !   Flux conversion factors
    !
    call CAL_setState(filterId = UVW1)
    fcf = CAL_omGetFluxConvFactors()
    write(*, *) 'Flux conversion factors for UVW1 '
    write(*, *) fcf%cfwd
    write(*, *) fcf%cfab
    write(*, *) fcf%cfvega
    write(*, *) fcf%zpab
    write(*, *) fcf%zpvega
    write(*, *)
    !
    !   OM frame parameters (needed to calculate frame time)
    !
    call CAL_omGetFrameParameters(frameParameters)
    write(*, *) 'frame parameters:'
    write(*, *) 'n horizontal pixels     : ', frameParameters%nHorizontalPixels
    write(*, *) 'n vertical pixels       : ', frameParameters%nVerticalPixels
    write(*, *) 'vertical transfer time  : ', &
        frameParameters%verticalTransferTime
    write(*, *) 'horizontal transfer time: ', &
        frameParameters%horizontalTransferTime
    write(*, *) 'vert image pixels       : ', &
        frameParameters%nVerticalPixelsImage
    write(*, *) 'vert->horiz. switch time: ', &
        frameParameters%verticalHorizontalSwitchTime
    write(*, *) 'horiz->vert. switch time: ', &
        frameParameters%horizontalVerticalSwitchTime
    write(*, *) 'redundant CCD y-offset  : ', &
        frameParameters%redundantCcdOffset
    write(*, *)

    !
    !   OM degradation coefficients
    !
    call CAL_omGetDegradationCoeffs(dc)
    write(*, *) 'Degradation coeffs: ',dc(0),dc(1),dc(2)
    !
    !   psf
    !
    call CAL_omGetPSFmap(100.1_double, 100.1_double, 2, 2, 2, 2, &
                         2, 2, 0.5_double, psf)
    write(*, *) 'values of PSF around centroided pixel 100.1/100.1'
    do i=0, size(psf, 1)-1
        write(*, '(100F6.3)') (psf(i, j), j=0, size(psf, 2)-1)
    enddo
    call CAL_releaseMemory(psf)
    write(*, *)
    !
    !   plate scale
    !
    call CAL_omGetPlateScale(lambda, plateScale)
    write(*, *) 'OM platescale: ', plateScale
    write(*, *)

    !
    !   large scale sensitivity variation
    !
    call CAL_setState(filterId = UVW1)
    call CAL_omLargeSenseVariation(2040, 2040, 8, 8, 0._double, largeSenseMap);
    write(*, *) 'extents of large-sense-map ', size(largeSenseMap, 1), &
                'x', size(largeSenseMap, 2)
    do i=0, 7
        write(*, '(100f6.3)') (largeSenseMap(i, j), j=0, 7)
    enddo
    call CAL_releaseMemory(largeSenseMap)
    write(*, *)

    !
    !   pixel to pixel sensitivity variations
    !
    call CAL_omPixelSenseVariation(0, 0, 10, 10, 0._double, pixelSenseMap)
    write(*, *) 'extents of pixel-sense-map ', size(pixelSenseMap, 1), &
                'x', size(pixelSenseMap, 2)
    do i=0, size(pixelSenseMap, 1)-1
        write(*, '(100f6.3)') (pixelSenseMap(i, j), &
                                j=0, size(pixelSenseMap, 2)-1)
    enddo
    call CAL_releaseMemory(pixelSenseMap)
    write(*, *)

    !
    !   count rate conversion
    !
    rawRate = 3.4
    write(*, *) 'count rate conversion:'
    naturalRate = CAL_omPhotoNatural(rawRate, .1_double, .01_double, &
                       .01_double, .false.)
    write(*, *) rawRate, ' -> ', naturalRate
    write(*, *)

    !    
    !   count rate-magnitude conversion
    !
    call CAL_omPhotoMagnitude(naturalRate, magnitude)
    write(*, *) 'count rate-magnitude conversion'
    write(*, *) naturalRate, ' -> ', magnitude

    !
    !   get boresight matrix
    !
    boresight = CAL_getBoresight(0.d0)
    matrix => CAL_toDirectionCosineMatrix(boresight)
    write(*, *)
    write(*, *) 'boresight misalignment matrix for OM'
    do i=0, 2
        write(*, '(3(F6.3, 1X))') (matrix(i, j), j=0, 2)
    enddo

    !
    !   misc data
    !
    !call CAL_getMiscellaneousData('FOCAL_LENGTH', focalLength)
    !call CAL_getMiscellaneousData('PLATE_SCALE_X', plateScaleX);
    write(*, *)
    !write(*, *) 'Focal length of telescope is [m]: ', focalLength    
    !write(*, *) 'Plate scale is [arcsrc/pixel]   : ', plateScaleX

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
    !   produce plot showing CCD in focal plane
    !
!    call pgenv(-50., 50., -50., 50., 1, 1)
!    call pglab('(S/C z [mm])', '(S/C y [mm])', 'OM CCD layout')

!    rawXtest(0) = OM_MIN_X
!    rawXtest(1) = OM_MAX_X
!    rawXtest(2) = OM_MAX_X
!    rawXtest(3) = OM_MIN_X
!    rawXtest(4) = OM_MIN_X
!    rawYtest(0) = OM_MIN_Y
!    rawYtest(1) = OM_MIN_Y
!    rawYtest(2) = OM_MAX_Y
!    rawYtest(3) = OM_MAX_Y
!    rawYtest(4) = OM_MIN_Y
!    call CAL_rawXY2mm(rawXtest, rawYtest, 5, xmilli, ymilli, zmilli)
!    cenx = .25*(zmilli(0) + zmilli(1) + zmilli(2) + zmilli(3))
!    ceny = .25*(ymilli(0) + ymilli(1) + ymilli(2) + ymilli(3))
!    call pgline(5, zmilli, ymilli)
!    call pgnumb(i, 0, 1, ccdid, ccdidlen)
!    call pgsch(2.)
!    call pgptxt(cenx, ceny, 0., .5, ccdid)
!    call pgsch(1.)
!    call pgarro(zmilli(0), ymilli(0), zmilli(1), ymilli(1))
!    call pgptxt(zmilli(1), ymilli(1), 0., .5, 'x')
!    call pgarro(zmilli(0), ymilli(0), zmilli(3), ymilli(3))
!    call pgptxt(zmilli(3), ymilli(3), 0., .5, 'y')

!    call CAL_releaseMemory(xmilli, ymilli, zmilli)

!    call pgend
end program

subroutine writeCalFileInfo(badPixFileInfo)
use CAL
type(CalInfo), intent(in)   :: badPixFileInfo

    write(*, *) 'OM BadPixel calibration file:'
    write(*, *) 'instrument        : ', badPixFileInfo%instrument
    write(*, *) 'type              : ', badPixFileInfo%calType
    write(*, *) 'name              : ', badPixFileInfo%fileName
    write(*, *) 'creation date     : ', badPixFileInfo%date
    write(*, *) 'validity date     : ', badPixFileInfo%valDate
    write(*, *) 'issue number      : ', badPixFileInfo%issue
end subroutine
