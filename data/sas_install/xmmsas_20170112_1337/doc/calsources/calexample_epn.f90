!
!   calexample_epn.f90 --- example program to show usage of the CAL for EPN
!
!   DESCRIPTION:
!       This acts as an example program to show how the CAL
!       is supposed to be used from SAS tasks written in Fortran90.
!
!   AUTHOR:
!       U. Lammers, Fri Nov 14 12:08:05 MET 1997
!
!   $Header: /sasbuild/sas_git_repo/cvs_copy/sasdev/sas/packages/cal/f90test/calexample_epn.f90,v 1.24 2013/10/30 10:50:55 rsaxton Exp $
!
program calexample_epn

use cal             ! use the Calibration Access Layer
implicit none
    integer                        :: i, j, ccdNr, ei, sysTypeNr
    integer(int16)                 :: itmp
    integer(int16), dimension(:), pointer :: &
                                   rawX => null(), rawY => null(), &
                                   badPixType => null(), yextent => null()
    logical, dimension(:), pointer :: uplinked => null()
    integer(int16), dimension(:), pointer :: corval => null()
    integer(int16), dimension(0:5) :: &
                                   rawXtest = (/1, 23, 34, 56, 58, 64/),&
                                   rawYtest = (/1, 12, 134, 199, 123, 99/)
    character(len=2)               :: ccdid
    integer                        :: ccdidlen
    real(double)                   :: cenx, ceny

    real(double), dimension(:), pointer :: xmilli => null(), ymilli => null(), zmilli => null()
    real(single), dimension(EPN_MIN_X:EPN_MAX_X,EPN_MIN_Y:EPN_MAX_Y):: &
                                           rbadpixmap
    integer(int16), dimension(:,:), pointer :: ibadpixmap => null()
    real(double), dimension(0:99)  :: xvec, yvec
    real(double), dimension(0:4)   :: psfenergies = &
                             (/10., 500., 2500., 8000., 15000./)
    real(single), dimension(0:11)   :: clevels = &
            (/0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9/)
    real(single), dimension(0:5)   :: tr

    type(BoresightT)                       :: boresight
    real(double), dimension(:,:), pointer  :: matrix => null()
    real(single), dimension(:,:), pointer  :: PSFmap => null()
    type(PsfT)                      :: psf
    type(PatternFractionServerT)    :: pfds;
    type(CurveT)                    :: curve
    type(PsfWindowT)                :: window
    real(double), dimension(:), pointer :: pattFracChan => null()

    real(double)               :: focalLength, plateScaleX
    character(len=*), parameter     :: myBadPixFile = &
                                      'epn_badpix.ccf'
    type(CalInfo)                   :: badPixFileInfo
    type(ModeParameterDataType)     :: modeParameters

    real(single), dimension(:,:), pointer :: medmap => null()
    real(single), dimension(:,:), pointer :: moff => null()
    real(single), dimension(:,:,:), pointer :: noisemap => null()
    real(single), dimension(:), pointer :: hlo => null(), hhigh => null()
    real(single), dimension(:), pointer :: xrlc => null()

    logical                       :: withGainTiming
    real(double)                  :: Ne
    real(double), dimension(:), pointer :: pc => null(), cc => null(), ce => null()
    
    
    !
    !   set the state of the CAL from the contents of an ODF science file -
    !   in the absence of real example file set the state explicitely
    !
    !call CAL_setStateFromScienceFile('epn.fits')
    call CAL_setState(EPN, ccdChipId=EPN_CCD_NW, ccdNodeId = 0)
    
    !
    !   select low-accuracy calibration, e.g., parametric PSFs
    !
    call CAL_setState(accuracyLevel = ACCURACY_LOW)

    !
    !   check details of EPN BadPixel file in CCF and replace it with
    !   local version
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

    do ccdNr=EPN_CCD_FIRST, EPN_CCD_LAST
        call CAL_setState(ccdChipId = ccdNr)
        call CAL_getBadPixelList(rawX, rawY, badPixType, yextent,&
             & uplinked)
        write (*, *) 'EPN chip #', ccdNr, ' has ', size(rawX), ' bad&
             & pixels:'
        write (*, *) '   x    y   defect  y-extent uplinked'
        do i=0, size(rawX)-1
           write(*, '(I5,I5,I9,I10,5X,L1)') rawX(i), rawY(i),&
                & badPixType(i), yextent(i), uplinked(i)
        enddo
        call CAL_releaseMemory(rawX, rawY)
        call CAL_releaseMemory(badPixType, yextent)
        call CAL_releaseMemory(uplinked)
    enddo

    write(*, *)
    call CAL_setState(ccdChipId = EPN_CCD_5)
    if (CAL_isPixelBad(2_int16, 131_int16, defect=itmp) .and. itmp&
         & .eq. HOT) then
          write(*, *) 'Pixel of EPN CCD #5 (2,131) is hot'
    endif

    call CAL_setState(ccdChipId = EPN_CCD_1)
    call CAL_getBadPixelMap(ibadpixmap)
!    call pgbeg(0, ' ', 1, 1)
!    call pgenv(real(EPN_MIN_X, single), real(EPN_MAX_X, single),&
!         & real(EPN_MIN_Y, single), real(EPN_MAX_Y, single), 1, 1)
!    call pglab('(x [pixel])', '(y [pixel])', 'Bad Pixel Map for EPN&
!         & CCD #1')
!    tr(0) = 0.;
!    tr(1) = 1.;
!    tr(2) = 0.;
!    tr(3) = 0.;
!    tr(4) = 0.;
!    tr(5) = 1.;
!    rbadpixmap = real(ibadpixmap, single)
!    call pgimag(rbadpixmap, size(rbadpixmap, 1), size(rbadpixmap, 2),&
!         & 1, size(rbadpixmap, 1), 1, size(rbadpixmap, 2), 1., 13.,&
!         & tr);
    call CAL_releaseMemory(ibadpixmap)
!    call pgpage

    !
    !   get boresight matrix valid at start of observation
    !
    boresight = CAL_getBoresight(0.d0)
    matrix => CAL_toDirectionCosineMatrix(boresight)
    write(*, *)
    write(*, *) 'boresight misalignment matrix for EPN at star of obs.:'
    do i=0, 2
        write(*, '(3(F6.3, 1X))') (matrix(i, j), j=0, 2)
    enddo

    !
    !   misc data
    !
    call CAL_getMiscellaneousData('FOCAL_LENGTH', focalLength)
    call CAL_getMiscellaneousData('PLATE_SCALE_X', plateScaleX);
    write(*, *)
    write(*, *) 'Focal length of telescope is [m]: ', focalLength    
    write(*, *) 'Plate scale is [arcsrc/pixel]   : ', plateScaleX

    !
    !   pixel to mm
    !
    call CAL_setState(randomize = .false.)
    call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli)
    call CAL_sacCoordToCamCoord2(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord2ToCamCoord1(xmilli, ymilli, zmilli, xmilli,ymilli,zmilli)
    call CAL_camCoord1ToChipCoord(xmilli, ymilli, zmilli, rawX, rawY)
    write(*, *)
    write(*, *) 'conversion of pixel to mm and vice versa:'
    do i=0, size(rawXtest)-1
       write(*, '(I3, A1, I3, A1, 3F10.3, 1X, A1, 1X, I3, A1, I3)')&
            & rawXtest(i), '/', rawYtest(i), '=', xmilli(i),&
            & ymilli(i), zmilli(i), '=', rawX(i), '/', rawY(i)
    enddo
    call CAL_releaseMemory(xmilli, ymilli, zmilli)
    call CAL_releaseMemory(rawX, rawY)
    
    !
    !   produce plot showing CCDs in focal plane
    !
!    call pgenv(-480., -580., 50., -50., 1, 1)
!    call pglab('(S/C z [mm])', '(S/C y [mm])', 'EPN-1 CCD layout')

    do i=EPN_CCD_FIRST, EPN_CCD_LAST
        call CAL_setState(ccdChipId = i)
        rawXtest(0) = EPN_MIN_X
        rawXtest(1) = EPN_MAX_X
        rawXtest(2) = EPN_MAX_X
        rawXtest(3) = EPN_MIN_X
        rawXtest(4) = EPN_MIN_X
        rawYtest(0) = EPN_MIN_Y
        rawYtest(1) = EPN_MIN_Y
        rawYtest(2) = EPN_MAX_Y
        rawYtest(3) = EPN_MAX_Y
        rawYtest(4) = EPN_MIN_Y
        call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli, zmilli)
        cenx = .25*(zmilli(0) + zmilli(1) + zmilli(2) + zmilli(3))
        ceny = .25*(ymilli(0) + ymilli(1) + ymilli(2) + ymilli(3))
!        call pgline(5, zmilli, ymilli)
!        call pgnumb(i, 0, 1, ccdid, ccdidlen)
!        call pgsch(2.)
!        call pgptxt(cenx, ceny, 0., .5, ccdid)
!        call pgsch(1.)
!        call pgarro(zmilli(0), ymilli(0), zmilli(1), ymilli(1))
!        call pgptxt(zmilli(1), ymilli(1), 0., .5, 'x')
!        call pgarro(zmilli(0), ymilli(0), zmilli(3), ymilli(3))
!        call pgptxt(zmilli(3), ymilli(3), 0., .5, 'y')

        call CAL_releaseMemory(xmilli, ymilli, zmilli)
    enddo

    do sysTypeNr=DETECTOR_GEOCENTER_SYSTEM, DETECTOR_OPTICSCENTER_SYSTEM
        write(*, *) 'coordinate system: ', sysTypeNr

        !
        !   produce plot showing CCDs in focal plane
        !
!        call pgenv(-50., 50., -50., 50., 1, 1)
!        call pglab('(DET x [mm])', '(DET y [mm])', 'EPN CCD layout')

        do i=EPN_CCD_FIRST, EPN_CCD_LAST
            call CAL_setState(ccdChipId = i)
            rawXtest(0) = EPN_MIN_X
            rawXtest(1) = EPN_MAX_X
            rawXtest(2) = EPN_MAX_X
            rawXtest(3) = EPN_MIN_X
            rawXtest(4) = EPN_MIN_X
            rawYtest(0) = EPN_MIN_Y
            rawYtest(1) = EPN_MIN_Y
            rawYtest(2) = EPN_MAX_Y
            rawYtest(3) = EPN_MAX_Y
            rawYtest(4) = EPN_MIN_Y
            call CAL_rawXY2mm(rawXtest, rawYtest, xmilli, ymilli,&
                 & zmilli, sysTypeNr)
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
    enddo

    
    !
    !   mode parameters
    !
    call CAL_getModeParameters(modeParameters)
!    write(*, *) 'Mode parameters:'
!    write(*, *) 'integration time [ms]: ', modeParameters%integrationTime
    write(*, *) 'frame time [ms]      : ', modeParameters%frameTime
!    write(*, *) 'cycle time [ms]      : ', modeParameters%cycleTime
!    write(*, *) 'time resolution [ms] : ', modeParameters%timeResolution
!    write(*, *) 'duty cycle [%]       : ', modeParameters%dutyCycle
!    write(*, *) 'smeared fraction [%] : ', modeParameters%smearedFraction
!    write(*, *) 'limiting flux [mCrab]: ', modeParameters%limitingFlux

    !
    !   get PSF map
    !
!    call pgenv(0., 20., 0., 1.1, 0, 20)
!    call pglab('(r [0.5 arcsec])', '(PSF [norm])', 'on-axis PSF&
!         & (Pearson-VII)')

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
    tr(0) = -20.5;
    tr(1) = .5;
    tr(2) = 0.;
    tr(3) = -20.5;
    tr(4) = 0.;
    tr(5) = .5;
!    call pgenv(-20., 20., -20., 20., 1, 1)
!    call pglab('(rx [arcsec])', 'ry [arcsec])', 'on-axis PSF (Pearson-VII)')
!    call pgcont(PSFmap, size(PSFmap, 1), size(PSFmap, 2), &
!                1, size(PSFmap, 1), 1, size(PSFmap, 2), clevels, &
!                size(clevels), tr)
    call CAL_releaseMemory(PSFmap)
!    call pgend


    !
    !   pattern fraction data
    !
    pfds = CAL_getPatternFractionServer()
    call CAL_patternFractionAt(pfds, 20_int16, 100_int16)
    curve = CAL_getPatternFractionTotalQE(pfds)
    write(*, *) 'Total QE at E=2000 eV', CAL_curveValueAt(curve, 2000._double)

    curve = CAL_getPatternFractionInEnergy(pfds, GRADE_DOUBLE)
    write(*, *) 'Fraction of doubles at E=2000 eV', &
            CAL_curveValueAt(curve, 2000._double)

    pattFracChan => CAL_getPatternFractionInChannel(pfds, GRADE_SINGLE)
    write(*, *) 'Size of pattern fraction array', size(pattFracChan)
    do i=0, 100
        write(*, *) i, pattFracChan(i)
    enddo
                                          
    !
    !   epn-reject quantities
    !
    call CAL_setState(ccdChipId = EPN_CCD_5)
    call CAL_setState(ccdModeId=PRIME_FULL_WINDOW)

    call CAL_pnMedianMap(medmap) 
    call CAL_pnMasterOffset(moff) 
    call CAL_pnOffsetCorrValues(hlo, hhigh, corval)
    call CAL_pnNoiseMap(rawX, noisemap)
    write(*, *)
    write(*, *) 'pn reject - medianmap(25,20) ',medmap(24,19)
    write(*, *) ' masterOff(1,194) ',moff(0,192)
    write(*, *) 'rawx ',rawX(0), 'noise map(25,189) ',noisemap(0,24,188)
    write(*, *) 'offset corr ',hlo(1),hhigh(1),corval(1)
    write(*, *)
    !call CAL_releaseMemory(medmap, noisemap)
    call CAL_releaseMemory(medmap)
    !call CAL_releaseMemory(noisemap)
    call CAL_releaseMemory(rawX, corval)
    call CAL_releaseMemory(hlo, hhigh) 

    ! Comment out until CCF is released
    !call CAL_setState(ccdChipId = EPN_CCD_4)
    !call CAL_setState(ccdModeId=FAST_TIMING)
    !call CAL_pnMasterClosedOffset(moff, xrlc)
    !write(*, *) 'pn reject - masterClosed(22,145) ',moff(21,144)
    !call CAL_setState(ccdModeId=FAST_BURST)
    !call CAL_pnMasterClosedOffset(moff, xrlc)
    !write(*, *) 'pn reject BURST - masterClosed(22,145) ',moff(21,144)
    !write(*, *) 'pn reject - X-ray loading coeefs ',xrlc(0),xrlc(1)
    !write(*, *)
    !

    !
    !   epn rate-dependent params
    !
    withGainTiming=.false.
    Ne=400.0
    call CAL_setState(ccdModeId=FAST_TIMING)
    call CAL_pnRateDependentPhaParam(Ne, withGainTiming, pc, cc, ce)
    write(*, *) 'pn rate dep constants: ',pc(0),pc(1),pc(2)
    write(*, *) 'pn rate dep coeffs: ',cc(0),cc(1),cc(2)
    write(*, *) 'pn rate dep errors: ',ce(0),ce(1),ce(2)

    ! BURST mode 
    write(*,*) 'Burst mode rate dependent coefficients'
    call CAL_setState(ccdModeId=FAST_BURST)
    call CAL_pnRateDependentPhaParam(Ne, withGainTiming, pc, cc, ce)
    write(*, *) 'pn rate dep constants: ',pc(0),pc(1),pc(2)
    write(*, *) 'pn rate dep coeffs: ',cc(0),cc(1),cc(2)
    write(*, *) 'pn rate dep errors: ',ce(0),ce(1),ce(2)
   
    ! Full window mode which should return zeroes
    call CAL_setState(ccdModeId=PRIME_FULL_WINDOW)
    call CAL_pnRateDependentPhaParam(Ne, withGainTiming, pc, cc, ce)
    write(*, *) 'pn rate dep constants: ',pc(0),pc(1),pc(2)
    write(*, *) 'pn rate dep coeffs: ',cc(0),cc(1),cc(2)
    write(*, *) 'pn rate dep errors: ',ce(0),ce(1),ce(2)

end program


subroutine writeCalFileInfo(badPixFileInfo)
use CAL
type(CalInfo), intent(in)   :: badPixFileInfo

    write(*, *) 'EPN BadPixel calibration file:'
    write(*, *) 'instrument        : ', badPixFileInfo%instrument
    write(*, *) 'type              : ', badPixFileInfo%calType
    write(*, *) 'name              : ', badPixFileInfo%fileName
    write(*, *) 'creation date     : ', badPixFileInfo%date
    write(*, *) 'validity date     : ', badPixFileInfo%valDate
    write(*, *) 'issue number      : ', badPixFileInfo%issue
end subroutine

