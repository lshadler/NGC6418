!------------------------------------------------------------------------------
!
!                       XMM Science Analysis System (SAS)
!                      (c) 1997-2010 European Space Agency
!
!------------------------------------------------------------------------------
!
!   caloaldefs.f90 --- Definitions related to CAL/OAL ---
!
!   DESCRIPTION:
!       This modules contains definitions of constants and interface
!       specifications of utility routines to be used in conjunction with
!       the CAL and OAL.
!
!   CHANGE HISTORY:
!       UL, 1998-??-??: 1.0.0: - first version
!       UL, 2000-04-10: 1.1.0: - data mode identifiers brought in line
!                                with [1]
!       UL, 2000-03-08: 1.2.0: - added:
!                                   SpacecraftAttitudeType
!                                   EquatorialDirectionType
!       UL, 2003-03-13: 1.3.0: - brought in line with 2.24.0 changes of Xmm.h
!       RDS, 2003-12-05: 1.4.0: - added RGSn_SYSPEAK 
!
!   AUTHOR:
!       U. Lammers, Mon Oct  6 15:32:57 WET DST 1997
!
!   REFERENCES:
!       [1]: Interface Control Document, Observation and Slew Data Files,
!            XMM-SOC-ICD-0004-SSD, issue 2.4, K. Galloway
!
module CalOalDefs
    use types

    implicit none

   	!
	!	instrument names
	!
	integer, parameter, public	::	XMM         = 0, &
                            		XRT1        = 1, XRT2 = 2, XRT3 = 3, &
                                	EMOS1       = 4, EMOS2 = 5, &
                                	EPN         = 6, &
                                	ERM         = 7, &
                                    RGS1        = 8, RGS2 = 9, &
                					OM          = 10

    !
    !   CCD chip/node ID
    !
    integer, parameter, public  ::  CCDNONE         = 0, &  ! illegal number
                                    EMOS_CCD_1      = 1, &
                                    EMOS_CCD_2      = 2, &
                                    EMOS_CCD_3      = 3, &
                                    EMOS_CCD_4      = 4, &
                                    EMOS_CCD_5      = 5, &
                                    EMOS_CCD_6      = 6, &
                                    EMOS_CCD_7      = 7, &
                                    EMOS_CCD_FIRST  = EMOS_CCD_1, &
                                    EMOS_CCD_CENTRAL= EMOS_CCD_1, &
                                    EMOS_CCD_5CLOCK = EMOS_CCD_2, &
                                    EMOS_CCD_3CLOCK = EMOS_CCD_3, &
                                    EMOS_CCD_1CLOCK = EMOS_CCD_4, &
                                    EMOS_CCD_11CLOCK= EMOS_CCD_5, &
                                    EMOS_CCD_9CLOCK = EMOS_CCD_6, &
                                    EMOS_CCD_LAST   = EMOS_CCD_7, &
                                    EMOS_CCD_7CLOCK = EMOS_CCD_7

    integer, parameter, public  ::  EMOS_PRIMARY_NODE = 0, &
                                    EMOS_REDUNDANT_NODE = 1

    integer, parameter, public  ::  EPN_CCD_1       = 1, &
                                    EPN_CCD_2       = 2, &
                                    EPN_CCD_3       = 3, &
                                    EPN_CCD_4       = 4, &
                                    EPN_CCD_5       = 5, &
                                    EPN_CCD_6       = 6, &
                                    EPN_CCD_7       = 7, &
                                    EPN_CCD_8       = 8, &
                                    EPN_CCD_9       = 9, &
                                    EPN_CCD_10      = 10, &
                                    EPN_CCD_11      = 11, &
                                    EPN_CCD_12      = 12, &
                                    EPN_CCD_NW      = EPN_CCD_1, &
                                    EPN_CCD_FIRST   = EPN_CCD_1, &
                                    EPN_CCD_NE      = EPN_CCD_6, &
                                    EPN_CCD_SW      = EPN_CCD_7, &
                                    EPN_CCD_LAST    = EPN_CCD_12, &
                                    EPN_CCD_SE      = 12

    integer, parameter, public  ::  RGS_CCD_1       = 1, &
                                    RGS_CCD_2       = 2, &
                                    RGS_CCD_3       = 3, &
                                    RGS_CCD_4       = 4, &
                                    RGS_CCD_5       = 5, &
                                    RGS_CCD_6       = 6, &
                                    RGS_CCD_7       = 7, &
                                    RGS_CCD_8       = 8, &
                                    RGS_CCD_9       = 9, &
                                    RGS_CCD_FIRST   = RGS_CCD_1, &
                                    RGS_CCD_W       = RGS_CCD_1, &
                                    RGS_CCD_E       = RGS_CCD_9, &
                                    RGS_CCD_LAST    = RGS_CCD_9

    !
    !   instrument modes
    !   Updated in SCR117
    integer, parameter, public  :: &
                                    ! EMOS modes
                                    PRIME_FULL_WINDOW = 0, &
                                    PRIME_PARTIAL_RFS = 1, &
                                    PRIME_PARTIAL_W2 = 2, &
                                    PRIME_PARTIAL_W3 = 3, &
                                    PRIME_PARTIAL_W4 = 4, &
                                    PRIME_PARTIAL_W5 = 5, &
                                    PRIME_PARTIAL_W6 = 6, &
                                    FAST_UNCOMPRESSED = 7, &
                                    FAST_COMPRESSED = 8, &
                                    PRIME_FULL_WIN3X3 = 9, &
                                    OFFSET_VARIANCE = 10, &
                                    CCD_DIAGNOSTIC = 11, &
                                    DIAGNOSTIC_1X1 = 12, &
                                    DIAGNOSTIC_3X3 = 13, &
                                    EXTRA_HEATING_ANNEALING = 14, &
                                    EXTRA_HEATING_DEICING = 15, &
                                    EXTRA_HEATING_DECONTAM = 16, &
                                    IN_FLIGHT_TEST = 17, &
                                    PRIME_FULL_NO_BPMASK = 18, & 
                                    DIAGNOSTIC_1X1_RPP = 19 

    integer, parameter, public  :: &
                                    ! EPN modes (not listed above)
                                    PRIME_FULL_WINDOW_EXTENDED = 20, &
                                    PRIME_LARGE_WINDOW = 21, &
                                    PRIME_SMALL_WINDOW = 22, &
                                    FAST_TIMING = 23, &
                                    FAST_BURST = 24, &
                                    PRIME_FULL_OFFSET = 25, &
                                    PRIME_LARGE_OFFSET = 26, &
                                    OFFSET = 27, &
                                    NOISE = 28, &
                                    DIAGNOSTIC = 29, &
				    PRIME_FULL_WINDOW_MASKED = 30, &
			            PRIME_FULL_WINDOW_LOWGAIN = 31

    integer, parameter, public  :: &
                                    ! RGS modes
                                    SPECTROSCOPY = 32, &
                                    HIGH_EVENT_RATE = 33, &
                                    HIGH_EVENT_RATE_WITH_SES = 34, &
                                    HIGH_EVENT_RATE_WITH_SER = 35, &
                                    HIGH_TIME_RESOLUTION_SINGLE = 36, &
                                    HIGH_TIME_RESOLUTION_MULTIPLE = 37, &
                                    DIAGNOSTIC_2X2 = 38, &
                                    DIAGNOSTIC_4X4 = 39, &
                                    DIAGNOSTIC_5X5 = 40, &
                                    SPECTROSCOPY_TEST = 41, &
                                    DIAGNOSTIC_TEST = 42, &
				    SPECTROSCOPY_BASELINE = 43, &
				    SPECTROSCOPY_1X1 = 44, &
                                    READOUT_STORAGE_SECTION = 45, &
                                    SPECTROSCOPY_SMALL_WINDOW = 46

    integer, parameter, public  :: &
                                    ! OM modes
                                    IMAGE = 47, &
                                    FAST = 48, &
                                    RAW_DATA_BLUE_DSP12 = 49, &
                                    RAW_DATA_BLUE_DSP1 = 50, &
                                    RAW_DATA_BLUE_DSP2 = 51, &
                                    CONTROIDING_DATA = 52, &
                                    FULL_FRAME = 53, &
                                    CENTROIDING_CONFIRMATION = 54, &
                                    INTENSIFIER_CHARACTERISTICS = 55, &
                                    FLATFIELDING = 56, &
                                    DARK_LOW = 57, &
                                    DARK_HIGH = 58, &
                                    FLAT_FIELD_LOW = 59, &
                                    FLAT_FIELD_HIGH = 60

    !
    !   pixel space dimensions
    !
    integer, parameter, public  ::  EMOS_MIN_X  = 1, &
                                    EMOS_MAX_X  = 600, &
                                    EMOS_MIN_Y  = 1, &
                                    EMOS_MAX_Y  = 600, &
                                    EPN_MIN_X   = 1, &
                                    EPN_MAX_X   = 64, &
                                    EPN_MIN_Y   = 1, &
                                    EPN_MAX_Y   = 200, &
                                    RGS_MIN_X   = 1, &
                                    RGS_MAX_X   = 1024, &
                                    RGS_MIN_Y   = 1, &
                                    RGS_MAX_Y   = 384, &
                                    OM_MIN_X    = 1, &
                                    OM_MAX_X    = 2048, &
                                    OM_MIN_Y    = 1, &
                                    OM_MAX_Y    = 2048

    !
    !   filters
    !
    integer, parameter, public  :: &
                                    ! EMOS / EPN
                                    OPEN = 0, &
                                    CLOSED = 1, &
                                    THIN1 = 2, &
                                    THIN2 = 3, &
                                    MEDIUM = 4, &
                                    THICK = 5, &
                                    CAL_OPEN = 6, &
                                    CAL_CLOSED = 7, &
                                    CAL_THIN1 = 8, &
                                    CAL_THIN2 = 9, &
                                    CAL_MEDIUM = 10, &
                                    CAL_THICK = 11

    integer, parameter, public  :: &
                                    ! OM
                                    BLOCKED = 12, &
                                    UVW2 = 13, &
                                    UVM2 = 14, &
                                    UVW1 = 15, &
                                    U = 16, &
                                    B = 17, &
                                    V = 18, &
                                    WHITE = 19, &
                                    MAGNI = 20, &
                                    GRISM1 = 21, &
                                    GRISM2 = 22, &
                                    GRISM10 = 23, &
                                    GRISM20 = 24, &
                                    BARRED_U = 25

    !
    !   data modes
    !
    integer, parameter, public  :: &
                                    ! EMOS
                                    IMAGING                 = 0, &
                                    TIMING                  = 1, &
                                    REDUCED_IMAGING         = 2, &
                                    COMPRESSED_TIMING       = 3, &
                                    AUXILIARY               = 4, &
                                    DATA_DIAGNOSTIC         = 5, &
                                    DATA_OFFSET_VARIANCE    = 6, &
                                    COUNTING_CYCLE_REPORT   = 7, &
                                    PERIODIC_HOUSEKEEPING   = 8, &
                                    HBR_CONFIG_HOUSEKEEPING = 9, &
                                    HBR_BUFFER_HOUSEKEEPING = 10, &
                                    HBR_THRESHOLD_HOUSEKEEPING = 11, &
                                    EXTRAHEATING_CONF_HOUSEKEEPING = 12, &
                                    THERMAL_HOUSEKEEPING    = 13, &
                                    BRIGHT_PIXEL_HOUSEKEEPING = 14, &
                                    ! EPN not in above list
                                    BURST                   = 15, &
                                    OFFSET_DATA             = 16, &
                                    HBR_OFFSET_DATA         = 17, &
                                    NOISE_DATA              = 18, &
                                    DISCARDED_LINES_DATA    = 19, &
                                    MAIN_PERIODIC_HOUSEKEEPING = 20, &
                                    ADD_PERIODIC_HOUSEKEEPING = 21, &
                                    ! ERM not in avove list
                                    ERM_COUNT_RATE          = 22, &
                                    ERM_SPECTRA             = 23, &
                                    ! RGS not in above list
                                    DATA_SPECTROSCOPY       = 24, &
                                    HIGH_TIME_RESOLUTION    = 25, &
                                    FULL_PERIODIC_HOUSEKEEPING = 26, &
                                    TEMP_PERIODIC_HOUSEKEEPING = 27,&
                                    DPP_HOUSEKEEPING        = 28, &
                                    DPP_HOUSEKEEPING_1      = 29, &
                                    DPP_HOUSEKEEPING_2      = 30, &
                                    SYSPEAK_DIAGNOSTIC      = 31

    integer, parameter, public  :: &
                                    ! OM not on above list
                                    DATA_FAST               = 32, &
                                    ENGINEERING1            = 33, &
                                    ENGINEERING2            = 34, &
                                    ENGINEERING3            = 35, &
                                    ENGINEERING4            = 36, &
                                    ENGINEERING5            = 37, &
                                    ENGINEERING6            = 38, &
                                    ENGINEERING7            = 39, &
                                    PRIORITY_FIELD_ACQUISITION = 40, &
                                    PRIORITY_WINDOW_DATA    = 41, &
                                    PRIORITY_FAST           = 42, &
                                    TRACKING_HISTORY        = 43, &
                                    REFERENCE_FRAME         = 44, &
                                    NON_PERIODIC_HOUSEKEEPING =45, &
                                    ! S/C
                                    ATTITUDE                = 46, &
                                    RAW_ATTITUDE            = 47, &
                                    DUMMY_ATTITUDE          = 48, &
                                    PREDICTED_ORBIT         = 49, &
                                    RECONSTRUCTED_ORBIT     = 50, &
                                    TIME_CORRELATION        = 51, &
                                    RECONSTRUCTED_TIME_CORRELATION = 52, &
                                    HK_P1                   = 53, &
                                    HK_P2                   = 54, &
                                    HK_P3                   = 55, &
                                    HK_P4                   = 56, &
                                    HK_P5                   = 57, &
                                    HK_P6                   = 58, &
                                    HK_P7                   = 59, &
                                    HK_P8                   = 60, &
                                    HK_P9                   = 61, &
                                    SUMMARY_INFORMATION     = 62
	!
	!	verbosity levels
	!
	integer, parameter, public	::	MUTE	= 0, &
									NORMAL	= 1, &
									CHATTY	= 2


    !
    ! ---( types used in CAL+OAL )------------------------------------------
    !

    !
    !   attitude type
    !
    type SpacecraftAttitudeType
        sequence
        real(kind=double)  :: ra, dec, &      ! right ascension/declination
                                              ! of star tracker viewing
                                              ! direction [radians]
                                              ! [0<=ra<=2*PI],
                                              ! [-Pi/2<=Dec<=Pi/2]
                              apos            ! astronomical position angle
                                              ! [radians]
    end type


    type EquatorialDirectionType
        sequence
        real(kind=double)  :: ra, dec         ! right ascension/declination
                                              ! [radians];
                                              ! [0<=ra<=2*PI],
                                              ! [-Pi/2<=Dec<=Pi/2]
    end type


    !
    !   InstrumentExposureIdentifier
    !
    type InstrumentExposureIdentifierT
        integer, pointer :: ptr
    end type

    !
    !   translate instrument/mode/filter names to integer Ids and vice versa
    !
    interface instId
        function instIdToInt(name) result(result)
            use types
            integer(kind=int32)              :: result
            character(len=*), intent(in)     :: name
        end function

        character(len=5) function instIdToString(id)
            use types
            integer(kind=int32), intent(in)  :: id
        end function
    end interface

    interface modeId
        function modeIdToInt(name) result(result)
            use types
            integer(kind=int32)              :: result
            character(len=*), intent(in)     :: name
        end function

        character(len=48) function modeIdToString(id)
            use types
            integer(kind=int32), intent(in)  :: id
        end function
    end interface

    interface dataModeId
        function dataModeIdToInt(name) result(result)
            use types
            integer(kind=int32)              :: result
            character(len=*), intent(in)     :: name
        end function

        character(len=48) function dataModeIdToString(id)
            use types
            integer(kind=int32), intent(in)  :: id
        end function
    end interface

    interface filterId
        function filterIdToInt(name) result(result)
            use types
            integer(kind=int32)              :: result
            character(len=*), intent(in)     :: name
        end function

        character(len=16) function filterIdToString(id)
            use types
            integer(kind=int32), intent(in)  :: id
        end function
    end interface

    interface toTimeTag
        !
        !   convert time string in the format: "yyyy-mm-ddThh:mm:ss"
        !   into event time tag
        !
        function stringToTimeTag(timeString) result(result)
            use types
            character(len=*), intent(in)   :: timeString
            real(kind=double)               :: result
        end function
    end interface

    interface toHBR
        !
        !   convert MOS CCD number (1-7) to HBR number
        !
        integer function ccdToHBR(ccd)
            integer, intent(in)            :: ccd
        end function
    end interface

end module CalOalDefs
