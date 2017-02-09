!
!   calexample_emos.f90 --- example program to show usage of the CAL for MOS
!
!   DESCRIPTION:
!       This acts as an example program to show how the CAL
!       is supposed to be used from SAS tasks written in Fortran90.
!
!   AUTHOR:
!       U. Lammers, Fri Nov 14 12:08:05 MET 1997
!
!   $Header: /sasbuild/sas_git_repo/cvs_copy/sasdev/sas/packages/cal/f90test/calexample_emos.f90,v 1.28 2003/10/24 15:29:58 rsaxton Exp $
!
program calexample_emos

use cal             ! use the Calibration Access Layer
implicit none

    integer                        :: i, j, ccdNr, nodeNr, ei, ch, sysTypeNr
    integer(int16)                 :: itmp
    integer(int16), dimension(:), pointer :: &
                                   rawX => null(), rawY => null(), badPixType => null(), &
                                   yextent => null()
    logical, dimension(:), pointer :: uplinked => null()
    integer(int16), dimension(0:6) :: &
                                  rawXtest = (/1, 23, 34, 56, 118, 300, 567/),&
                                  rawYtest = (/1, 234, 43, 56, 98, 300, 576/),&
                                  Ein = (/123, 456, 789, 999, 364, 654, 888/)
    real(single), dimension(:), pointer   :: PHAreal => null()
    real(single), dimension(:), pointer   :: EinReal => null()
    real(double)                   :: cenx, ceny

    real(single), dimension(:), pointer  :: diffuseBackSpec => null(), particleBackSpec => null()
    integer(int16), dimension(:), pointer :: piVecDiff => null(), piVecPart => null()
    real(double)                          :: theta

    real(double), dimension(:), pointer :: xmilli => null(), ymilli => null(), zmilli => null()
    real(single), dimension(EMOS_MIN_X:EMOS_MAX_X,EMOS_MIN_Y:EMOS_MAX_Y):: &
                                           rbadpixmap
    integer(int16), dimension(:,:), pointer :: ibadpixmap => null()
    real(single), dimension(0:99)  :: xvec, yvec
    real(single), dimension(0:4095) :: pivec, respvec
    real(single), dimension(0:4095,0:4095) :: rmfmap    ! that is a big array
    real(double), dimension(:), pointer :: response => null(), response2 => null()
    integer(int16), dimension(:), pointer :: channels => null()
    real(double), dimension(:), pointer   :: Emin => null(), Emax => null()
    integer(int16)                  :: channel, channel2
    real(double), dimension(0:4)   :: psfenergies = &
                        (/10., 500., 2500., 8000., 12000./)
    real(single), dimension(0:11)   :: clevels = &
            (/0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9/)
    real(single), dimension(0:5)   :: tr
    real(double), dimension(0:5)   :: time

    type(BoresightT)                       :: boresight
    real(double), dimension(:,:), pointer  :: matrix => null(), matrix2 => null()
    type(EulerAngles321)                   :: bsangles
    real(single), dimension(:,:), pointer  :: PSFmap => null()
    type(PsfT)                      :: psf
    type(PsfWindowT)                :: window
    real(double)               :: focalLength, plateScaleX
    character(len=*), parameter     :: myBadPixFile = &
                                      'emos1_badpix.ccf'
    character(len=*), parameter     :: instrument = 'EMOS1'
    type(CalInfo)                   :: badPixFileInfo
    type(ModeParameterDataType)     :: modeParameters

    write(*, *) 'EMOS1 is instrument number :', instId('EMOS1')

    !
    !   set the state of the CAL from the contents of an ODF science file -
    !   in the absence of real example file set the state explicitely
    !
    !call CAL_setStateFromScienceFile('emos1.fits')
    call CAL_setState(EMOS1, ccdChipId=EMOS_CCD_CENTRAL, ccdNodeId=0, &
                      ccdModeId = 0)
    
    !
    !   select low-accuracy calibration, e.g., parametric PSFs
    !
    call CAL_setState(accuracyLevel = ACCURACY_LOW)

    !
    !   check details of EMOS BadPixel file in CCF and replace it with local
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

    do ccdNr=EMOS_CCD_FIRST, EMOS_CCD_LAST
       do nodeNr=0, 1
           call CAL_setState(ccdChipId = ccdNr, ccdNodeId = nodeNr)
           call CAL_getBadPixelList(rawX, rawY, badPixType, yextent, uplinked)
           write (*, *) 'EMOS1 chip #', ccdNr, '/', nodeNr, ' has ', &
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
    call CAL_setState(ccdChipId = EMOS_CCD_5CLOCK, ccdNodeId = 0)
    if (CAL_isPixelBad(17_int16, 474_int16, defect=itmp) .and. &
        itmp .eq. FLICKERING) &
    then
          write(*, *) 'Pixel (17/474) of EMOS CCD #2 is flickering'
    endif

    call CAL_setState(ccdChipId = EMOS_CCD_CENTRAL)
    call CAL_getBadPixelMap(ibadpixmap)
!    call pgbeg(0, ' ', 1, 1)
!    call pgenv(real(EMOS_MIN_X, single), real(EMOS_MAX_X, single), &
!               real(EMOS_MIN_Y, single), real(EMOS_MAX_Y, single), 1, 1)
!    call pglab('(x [pixel])', '(y [pixel])', &
!         'Bad Pixel Map for central EMOS-1 CCD')
!    tr(0) = 1.
!    tr(1) = 1.
!    tr(2) = 0.
!    tr(3) = 1.
!    tr(4) = 0.
!    tr(5) = 1.
!    rbadpixmap = real(ibadpixmap, single)
!    call pgscir(0, 1)
!    call pgimag(rbadpixmap, size(rbadpixmap, 1), size(rbadpixmap, 2), &
!                1, size(rbadpixmap, 1), 1, size(rbadpixmap, 2), &
!                0., 13., tr)
!    call pgpixl(i32badpixmap, size(i32badpixmap, 1), size(i32badpixmap, 2), &
!                1, size(i32badpixmap, 1), 1, size(i32badpixmap, 2), &
!                real(EMOS_MIN_X, single), real(EMOS_MAX_X, single), &
!                real(EMOS_MIN_Y, single), real(EMOS_MAX_Y, single))
    call CAL_releaseMemory(ibadpixmap)

    !
    !   get boresight matrix
    !
    write(*, *) 'Boresight Misalignment Matrix:'
    boresight = CAL_getBoresight(0.d0)
    matrix => CAL_toDirectionCosineMatrix(boresight)
    do i=0, 2
        write(*, '(3(F12.8, 1X))') (matrix(i, j), j=0, 2)
    enddo

    bsangles = CAL_toEulerAngles(boresight)
    write(*, *) 'Corresponding 3-2-1 Euler angles:'
    write(*, *) 'phi   = ', bsangles%phi
    write(*, *) 'theta = ', bsangles%theta
    write(*, *) 'psi   = ', bsangles%psi

    matrix2 => CAL_toDirectionCosineMatrix(bsangles)
    write(*, *) 'Converted back to direction cosine matrix:'
    write(*, *)
    do i=0, 2
        write(*, '(3(F12.8, 1X))') (matrix2(i, j), j=0, 2)
    enddo

    call CAL_releaseMemory(matrix)
    call CAL_releaseMemory(matrix2)

    !
    !   misc data
    !
    call CAL_getMiscellaneousData('FOCAL_LENGTH', focalLength)
    call CAL_getMiscellaneousData('PLATE_SCALE_X', plateScaleX)
    write(*, *)
    write(*, *) 'Focal length of telescope is [m]: ', focalLength    
    write(*, *) 'Plate scale is [arcsrc/pixel]   : ', plateScaleX

    !
    !   pixel to mm
    !
    call CAL_setState(randomize = .false.)
    call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli, &
                      SACCOORD)
    call CAL_sacCoordToCamCoord2(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord2ToCamCoord1(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord1ToChipCoord(xmilli, ymilli, zmilli, rawX, rawY)
    call CAL_setState(ccdNodeId = EMOS_REDUNDANT_NODE)
    call CAL_chipCoordToPixCoord1(rawX, rawY, rawX, rawY)
    call CAL_setState(ccdNodeId = EMOS_PRIMARY_NODE)
    write(*, *)
    write(*, *) 'conversion of pixel to mm and vice versa (red node):'
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
    do nodeNr=EMOS_PRIMARY_NODE, EMOS_REDUNDANT_NODE
        write(*, *) 'node ', nodeNr
!        call pgenv(-50., 50., -50., 50., 1, 1)
!        call pglab('(S/C z [mm])', '(S/C y [mm])', 'EMOS-1 CCD layout')
       do i=EMOS_CCD_CENTRAL, EMOS_CCD_7CLOCK
            call CAL_setState(ccdChipId = i, ccdNodeId = nodeNr)
            rawXtest(0) = EMOS_MIN_X
            rawXtest(1) = EMOS_MAX_X
            rawXtest(2) = EMOS_MAX_X
            rawXtest(3) = EMOS_MIN_X
            rawXtest(4) = EMOS_MIN_X
            rawYtest(0) = EMOS_MIN_Y
            rawYtest(1) = EMOS_MIN_Y
            rawYtest(2) = EMOS_MAX_Y
            rawYtest(3) = EMOS_MAX_Y
            rawYtest(4) = EMOS_MIN_Y
            call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli, &
                              SPACECRAFT_SYSTEM)
            cenx = .25*(zmilli(0) + zmilli(1) + zmilli(2) + zmilli(3))
            ceny = .25*(ymilli(0) + ymilli(1) + ymilli(2) + ymilli(3))
!            call pgline(5, zmilli, ymilli)
!            call pgnumb(i, 0, 1, ccdid, ccdidlen)
!            call pgsch(2.)
!            call pgptxt(cenx, ceny, 0., .5, ccdid)
!            call pgsch(1.)
!            call pgarro(zmilli(0), ymilli(0), zmilli(1), ymilli(1))
!            call pgptxt(zmilli(1), ymilli(1), 0., .5, 'x')
!            call pgarro(zmilli(0), ymilli(0), zmilli(3), ymilli(3))
!            call pgptxt(zmilli(3), ymilli(3), 0., .5, 'y')

            call CAL_releaseMemory(xmilli, ymilli, zmilli)
        enddo
    enddo

    do sysTypeNr=DETECTOR_GEOCENTER_SYSTEM, DETECTOR_OPTICSCENTER_SYSTEM
        write(*, *) 'coordinate system: ', sysTypeNr
        !
        !   produce plot showing CCDs in focal plane
        !
       do nodeNr=EMOS_PRIMARY_NODE, EMOS_REDUNDANT_NODE
            write(*, *) 'node ', nodeNr
!            call pgenv(-50., 50., -50., 50., 1, 1)
!            call pglab('(DET x [mm])', '(DET y [mm])', 'EMOS-1 CCD layout')
            do i=EMOS_CCD_CENTRAL, EMOS_CCD_7CLOCK
                call CAL_setState(ccdChipId = i, ccdNodeId = nodeNr, &
                                  randomize = .false.)
                rawXtest(0) = EMOS_MIN_X
                rawXtest(1) = EMOS_MAX_X
                rawXtest(2) = EMOS_MAX_X
                rawXtest(3) = EMOS_MIN_X
                rawXtest(4) = EMOS_MIN_X
                rawYtest(0) = EMOS_MIN_Y
                rawYtest(1) = EMOS_MIN_Y
                rawYtest(2) = EMOS_MAX_Y
                rawYtest(3) = EMOS_MAX_Y
                rawYtest(4) = EMOS_MIN_Y
                call CAL_rawXY2mm(rawXtest, rawYtest, &
                                  xmilli, ymilli, zmilli, sysTypeNr)
                cenx = .25*(xmilli(0) + xmilli(1) + xmilli(2) + xmilli(3))
                ceny = .25*(ymilli(0) + ymilli(1) + ymilli(2) + ymilli(3))
!                call pgline(5, xmilli, ymilli)
!                call pgnumb(i, 0, 1, ccdid, ccdidlen)
!                call pgsch(2.)
!                call pgptxt(cenx, ceny, 0., .5, ccdid)
!                call pgsch(1.)
!                call pgarro(xmilli(0), ymilli(0), xmilli(1), ymilli(1))
!                call pgptxt(xmilli(1), ymilli(1), 0., .5, 'x')
!                call pgarro(xmilli(0), ymilli(0), xmilli(3), ymilli(3))
!                call pgptxt(xmilli(3), ymilli(3), 0., .5, 'y')

                call CAL_releaseMemory(xmilli, ymilli, zmilli)
            enddo
        enddo
    enddo


    !
    !   mode parameters
    !
    call CAL_getModeParameters(modeParameters)
    write(*, *) 'Mode parameters:'
    write(*, *) 'integration time [ms]: ', modeParameters%integrationTime
    write(*, *) 'shift time [ms]      : ', modeParameters%shiftTime
    write(*, *) 'frame time [ms]      : ', modeParameters%frameTime
    write(*, *) 'cycle time [ms]      : ', modeParameters%cycleTime
    write(*, *) 'time resolution [ms] : ', modeParameters%timeResolution
    write(*, *) 'duty cycle [%]       : ', modeParameters%dutyCycle
    write(*, *) 'smeared fraction [%] : ', modeParameters%smearedFraction
    write(*, *) 'point src pile up    : ', modeParameters%pointSourcePileUp
    write(*, *) 'limiting flux [mCrab]: ', modeParameters%limitingFlux

    write(*, *) 'underscan X [pixel]  : ', modeParameters%underscanX
    write(*, *) 'overscan X [pixel]   : ', modeParameters%overscanX
    write(*, *) 'underscan Y [pixel]  : ', modeParameters%underscanY
    write(*, *) 'overscan Y [pixel]   : ', modeParameters%overscanY
    write(*, *) 'window X0 [pixel]    : ', modeParameters%windowX0
    write(*, *) 'window Y0 [pixel]    : ', modeParameters%windowY0
    write(*, *) 'window DX [pixel]    : ', modeParameters%windowDX
    write(*, *) 'window DY [pixel]    : ', modeParameters%windowDY

    !
    !   CTI correction
    !
    call CAL_setState(ccdChipId = EMOS_CCD_CENTRAL, ccdNodeId = 0)
    call CAL_integerToReal(Ein, EinReal)
    call CAL_mosCtiCorrect(time, rawXtest, rawYtest, EinReal, PHAreal)
    write(*, *)
    write(*, *) 'CIT correction'
    write(*, *) 'pixel#   X   Y  E(unc) E1(corr)'
    do i=0, size(rawXtest)-1
        write(*, '(I7, I4, I4, I9, F9.3)') i, rawXtest(i), rawYtest(i), &
             Ein(i), PHAreal(i)
    enddo

    !
    !   get PSF map
    !
!    call pgenv(0., 20., 0., 1.1, 0, 20)
!    call pglab('(r [0.5 arcsec])', '(PSF [norm])', 'on-axis PSF (Pearson-VII)')

    write(*, *)
    write (*, *) 'PSF maps'
    window%halfX = 2._double
    window%halfY = 2._double

    do ei=0, size(psfenergies)-1
        write(*, *) 'for energy ', psfenergies(ei), ' eV ...'
        psf = CAL_getPsf(psfenergies(ei), 0._double, 0._double)
        call CAL_psfImage(psf, window, PSFmap)
        do i=0, 39
           xvec(i) = real(i, single)
           yvec(i) = PSFmap(40+i, 40)
        enddo
        call CAL_releaseMemory(PSFmap)
!        call pgsci (ei+1)
!        call pgline(40, xvec, yvec)
    enddo

    !
    !   draw a contour map
    !
    call CAL_psfImage(psf, window, PSFmap)
    do i=0, 4
        write(*, '(5F10.4, 1X)') (PSFmap(i+38, j+38), j=0, 4)
    enddo
    tr(0) = -20.5
    tr(1) = .5
    tr(2) = 0.
    tr(3) = -20.5
    tr(4) = 0.
    tr(5) = .5
!    call pgenv(-20., 20., -20., 20., 1, 1)
!    call pglab('(rx [arcsec])', 'ry [arcsec])', 'on-axis PSF (Pearson-VII)')
!    call pgcont(PSFmap, size(PSFmap, 1), size(PSFmap, 2), &
!                1, size(PSFmap, 1), 1, size(PSFmap, 2), clevels, &
!                size(clevels), tr)
    call CAL_releaseMemory(PSFmap)


    !
    !   filter transmission and quantum efficiency and large pixels
    !
    call CAL_setState(filterId=THIN1)
    write (*, *) 'Filter transmission at E=2000 keV for Thin1 filter:'
    write (*, *) CAL_getFilterTransmission(2000._double, 0._double, 0._double)
    write (*, *) 'integrated over 100 eV:'
    write (*, *) CAL_getFilterTransmission(2000._double, 2100._double, &
                                           0._double, 0._double)

    write (*, *) 'Quantum efficiency at E=2000 keV for pattern 0:'
    write (*, *) CAL_getQuantumEfficiency(2000._double, 300_int16, 300_int16,0)
    write (*, *) 'integrated over 100 eV:'
    write (*, *) CAL_getQuantumEfficiency(2000._double, 2100._double, &
                                          300_int16, 300_int16, 0)
    write (*, *) 'Large pattern size at E=2000 eV: '
    write (*, *) CAL_getLargePatternSize(2000._double)

    !
    !   RMF
    !
    write(*, *)
    write (*, *) 'EMOS response (all grades)'
!    call pgenv(0., 2500., 0., .06, 0, 0)
!    call pglab('(PI [channel])', '(W [norm])', &
!               'unperturbed EMOS response (singles only)')

!    do ei=0, size(psfenergies) - 1
!        call CAL_getRedistribution(psfenergies(ei), response, &
!                        ALL_GRADES, channel)
!        write(*, *) 'Number of channels: ', size(response)
!        write(*, *) 'for energy ', psfenergies(ei), ' eV / chan= ', channel
!        do i=0, size(response)-1
!           pivec(i) = real(i, single)
!           respvec(i) = real(response(i), single)
!        enddo
!        call CAL_releaseMemory(response)
!        call pgsci (ei+1)
!        call pgline(4096, pivec, respvec)
!    enddo

!    write (*, *) 'Redistribution on binnedPI axis at 2500 eV'
!    call CAL_getRedistribution(2500._double, response, ALL_GRADES, channel)
!    call CAL_getBinnedPIeBounds(channels, Emin, Emax)
!    call CAL_getRedistribution(2500._double, Emin, Emax, &
!                               response2, ALL_GRADES, channel2)
!    write(*, *) 'peak channels: ', channel, channel2
!    write(*, *) 'number of channels: ', size(response), size(response2)
!    do i=0, size(response)-1, 100
!        write(*, *) i, response(i), response2(i)
!    enddo


    !
    !   background - particle
    !
    call CAL_getParticleBackground(0._double, 0._double, 0._double, &
                                   particleBackSpec, piVecPart)

    do ei=0, size(piVecPart)-1
        pivec(ei) = real(piVecPart(ei), single)
        respvec(ei) = real(particleBackSpec(ei), single)
    enddo
!    call pgenv(0., 4096., 0., 1.e-8, 0, 0)
!    call pglab('(PI [chan])', 'bg [Hz/mm**2/chan])', 'particle background')
!    call pgline(size(piVecPart), pivec, respvec)

    !
    !   background - diffuse X-rays
    !
!    call pgenv(0., 1000., 0., 1.e-5, 0, 0)
!    call pglab('(PI [chan])', 'bg [Hz/mm**2/chan])', &
!               'diffuse X-ray background')

    write(*, *)
    write (*, *) 'diffuse X-ray background'

    do ei=0, 10, 2
        theta = real(ei, double) * 60.     ! theta in arcsec
        write(*, *) 'at theta = ', theta
        call CAL_getDiffuseXBackground(0._double, theta, 0._double, &
                                       diffuseBackSpec, piVecDiff)
        do i=0, size(piVecDiff)-1
            pivec(i) = real(piVecDiff(i), single)
            respvec(i) = real(diffuseBackSpec(i), single)
        enddo
!        call pgsci (ei+1)
!        call pgline(size(piVecDiff), pivec, respvec)
        call CAL_releaseMemory(diffuseBackSpec)
        call CAL_releaseMemory(piVecDiff)
    enddo


    !
    !   RMF as graymap
    !
!    call CAL_getEbounds(channels, Emin, Emax)
!    do i=0, size(channels)-1
!        ch = channels(i)
!        if (mod(ch, 100) .eq. 0) then
!            write(*, *) ch, Emin(ch), Emax(ch)
!        endif
!        call CAL_getRedistribution(.5*(Emin(ch)+Emax(ch)), response, &
!                    ALL_GRADES, channel)
!        do j=0, size(response)-1
!            rmfmap(j, ch) = real(response(j), single)
!        enddo
!        call CAL_releaseMemory(response)
!    enddo
!    tr(0) = 0.
!    tr(1) = 1.
!    tr(2) = 0.
!    tr(3) = 0.
!    tr(4) = 0.
!    tr(5) = 1.
!    call pgbeg(0, '?  ', 1, 1)
!    call pgenv(0., 4096., 0., 4096., 1, 1)
!    call pglab('PI [channel]', 'E [channel])', 'RMF map')
!    call pggray(rmfmap, size(rmfmap, 1), size(rmfmap, 2), 1, size(channels)-1,&
!                1, size(channels)-1, .01, 0., tr)
!    call pgend
end program


subroutine writeCalFileInfo(badPixFileInfo)
use CAL
type(CalInfo), intent(in)   :: badPixFileInfo

    write(*, *) 'EMOS BadPixel calibration file:'
    write(*, *) 'instrument        : ', badPixFileInfo%instrument
    write(*, *) 'type              : ', badPixFileInfo%calType
    write(*, *) 'name              : ', badPixFileInfo%fileName
    write(*, *) 'creation date     : ', badPixFileInfo%date
    write(*, *) 'validity date     : ', badPixFileInfo%valDate
    write(*, *) 'issue number      : ', badPixFileInfo%issue
end subroutine




