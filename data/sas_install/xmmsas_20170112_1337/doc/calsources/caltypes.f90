!------------------------------------------------------------------------------
!
!						XMM Science Analysis System (SAS)
!					   (c) 1997-2010 European Space Agency
!
!------------------------------------------------------------------------------
!
!	caltypes.f90  --- CAL specific data types
!
!	CHANGE HISTORY:
!		UL, 1997-07-25: 1.0.0: - first version
!       UL, 2001-02-13: 1.1.0: - various additions
!       UL, 2001-03-08: 1.2.0: - various additions
!       UL, 2001-12-05: 1.3.0: - added INVALID_BAD_PIXEL_TABLE_CODE
!       UL, 2002-01-18: 1.4.0: - changed symbolic constant GRADE_...
!                                to be in line with CcdQuantumDataServer defs
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
!   $Header: /sasbuild/repositories/sasdev/sas/packages/cal/f90/caltypes.f90,v 1.17 2009/07/23 09:04:13 rsaxton Exp $
!
module CalTypes
use types
implicit none
    !
    !   bad-pixel defect types
    !
    integer(kind=int32), parameter, public  :: &
                                    INTACT      = 0, &
                                    HOT         = 1, &
                                    FLICKERING  = 2, &
                                    DEAD        = 3, &
                                    PIN_HOLE    = 4, &
                                    UNSPECIFIED = 5

    !
    !   type of events
    !
    integer(kind=int32), parameter, public  :: &
                                    GRADE_SINGLE = 0, &
                                    GRADE_DOUBLE = 1, &
                                    GRADE_TRIPLE = 2, &
                                    GRADE_QUADRUPLE = 3, &
                                    GRADE_SD     = 4, &
                                    GRADE_SDTQ   = 5, &
                                    ALL_GRADES = GRADE_SDTQ

    !
    !   types of physical coordinate systems
    !
    integer(kind=int32), parameter, public  :: &
                                    SPACECRAFT_SYSTEM  = 0, &
                                    DETECTOR_GEOCENTER_SYSTEM = 1, &
                                    DETECTOR_OPTICSCENTER_SYSTEM = 2
    integer(kind=int32), parameter, public  :: &
                                    SACCOORD = 0, &
                                    CAMCOORD1 = 1, &
                                    CAMCOORD2 = 2, &
                                    CHIPCOORD = 3, &
                                    PIXCOORD1 = 4, &
                                    PIXCOORD0 = 5, &
                                    TELCOORD  = 6, &
                                    ROWCOORD = 7


    !
    !   invalid Bad-Pixel Table code; return value of CAL_getBadPixelCode()/
    !   CAL_getAduconvCode() if information on code is not present in CCF
    !
    character(len=9), parameter, public :: INVALID_BAD_PIXEL_TABLE_CODE = &
                                                                    '0_000_UNK'


	!
	!	accuracy levels
	!
	integer(kind=int32), parameter, public	:: &
                                    ACCURACY_LOW = 0, &
									ACCURACY_MEDIUM = 1, &
                                    ACCURACY_EXTENDED = 2, &
			! ACCURACY_HIGH = 3
									ACCURACY_ELLBETA = 3, &
                                   ! ACCURACY_HIGH = 4
									ACCURACY_SLEW= 4, &
                                    ACCURACY_HIGH = 5


   	type CalInfo
   		sequence
        character(len=10)   ::  instrument  ! instrument name
        character(len=20)   ::  calType     ! calibration file type
   		character(len=256)	::	fileName	! full absolute name
   		character(len=80)	::	date, &		! creation DATE
                           		valDate, &	! VALDATE
                       			extSequ, &	! EXTSEQU
                   				extSequId	! EXTSEQID
   		integer(kind=int32)	::	issue		! issue number
   	end type


    type BoresightT
        sequence
        integer, pointer :: ptr
    end type


    type EulerAngles321
        sequence
        real(kind=double)   :: phi, theta, psi
    end type


	type ContaminationDataType
		sequence							! because we overlay this
											! with a corresponding
											! C struct
        integer             :: TBS          ! to be specified
    end type


    type IntervalT
        sequence
        real(kind=double)               :: lower, upper
    end type


    type ValueErrorT
        sequence
        real(kind=double)               :: value, error
    end type


    type ValueAsymmetricErrorT
        sequence
        real(kind=double)               :: value, errorMinus, errorPlus
    end type


	type ModeParameterDataType
		sequence							! because we overlay this
											! with a corresponding
											! C struct
        real(kind=single)   :: integrationTime, &
                               shiftTime
        real(kind=double)   :: frameTime
        real(kind=single)   :: cycleTime, &
                               timeResolution, &
                               dutyCycle, &
                               smearedFraction, &
                               pointSourcePileUp, &
                               limitingFlux
        integer(kind=int16) :: underscanX, &
                               overscanX, &
                               underscanY, &
                               overscanY, &
                               windowX0, &
                               windowY0, &
                               windowDX, &
                               windowDY
  	end type

    !
    !   OM
    !
    type OMframeParameters
        sequence
        real(kind=double)     :: nHorizontalPixels, &
                                 nVerticalPixels, &
                                 verticalTransferTime, &
                                 horizontalTransferTime, &
                                 nVerticalPixelsImage, &
                                 verticalHorizontalSwitchTime, &
                                 horizontalVerticalSwitchTime, &
                                 redundantCcdOffset
    end type


    type OmColorTransformatorT
        sequence
        integer, pointer :: ptr
    end type
    
    type OmFluxConvF
        sequence
        real(kind=double)     :: cfwd, &
                                 cfab, &
                                 zpab, &
                                 cfvega, &
                                 zpvega
    end type
    


    !
    !   PSF related
    !
    type PsfT
        sequence
        integer, pointer :: ptr
    end type


    type OmPsfT
        sequence
        integer, pointer :: ptr
    end type


    type PsfBinSizeT
        sequence
        real(kind=double)       :: binX, binY
    end type


    type PsfWindowT
        sequence
        real(kind=double)       :: halfX, halfY
    end type


    type PsfValidityRangesT
        sequence
        real(kind=double)       :: eMin, eMax, &
                                   thetaMin, thetaMax, &
                                   phiMin, phiMax
    end type

    !
    !   curve
    !
    type CurveT
        sequence
        integer, pointer :: ptr
    end type


    !
    !   PatternFractionDataServer
    !
    type PatternFractionServerT
        sequence
        integer, pointer :: ptr
    end type
end module CalTypes

