!------------------------------------------------------------------------------
!
!						XMM Science Analysis System (SAS)
!					   (c) 1997-2010 European Space Agency
!
!------------------------------------------------------------------------------
!
!	oaltypes.f90  --- OAL specific data types
!
!	CHANGE HISTORY:
!		UL, 1997-07-25: 1.0.0: - first version
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
!   $Header: /sasbuild/repositories/sasdev/sas/packages/oal/f90/oaltypes.f90,v 1.3 2003/06/16 08:41:35 gvacanti Exp $
!
module OalTypes
use types
implicit none

    !
    !   ODF info type
    !
    type OdfInfoType
        sequence
        logical     :: isSlew                  ! Is this a slew ODF?
        integer     :: revolutionNr, &         ! revolution (orbit) number
                       nrFiles                 ! number of file in this ODF
        character(len=10)   :: &
                       proposalId, &           ! proposal number this ODF
                                               ! belongs to
                       observationId           ! observation sequence number
        character(len=25)   :: &
                       observationStartTime, & ! as scheduled
                       observationEndTime      ! as scheduled
        character(len=1024) :: &
                       directoryName           ! where is this ODF?
    end type

    type ProposalInfoType
        sequence
        character(len=80)   :: GoName          ! name of the GO
        character(len=80)   :: GoInstitute     ! institute of the GO
        character(len=120)  :: GoAddress       ! postal address of the GO
        character(len=80)   :: GoEmail         ! e-mail address of the GO
        character(len=2)    :: AO              ! AO of proposal
        character(len=2)    :: scienceType     ! science type
        character(len=20)   :: targetName      ! name of the target
        real(kind=double)   :: targetRa, &     ! Ra of target [decimal deg]
                               targetDec, &    ! Dec of target [decimal deg]
                               obsDuration, &  ! duration of observation [s]
                               boresightRa, &  ! Ra of boresight
                               boresightDec    ! Dec of boresight
        character(len=3)    :: posAngleConstLo, &
                               posAngleConstHi ! position angle constraints
        character(len=2)    :: posAngleOrigRef ! position angle origin refer.
        integer(kind=int16) :: emos1Prio, emos2Prio, epnPrio, &
                               rgs1Prio, rgs2Prio, omPrio
                                               ! instrument priorities
    end type


    !
    !   exposure info
    !
    type ExposureInfoType
        sequence
        integer     :: number                  ! exposure sequence number
        logical     :: scheduled               ! was exposure scheduled?
        integer     :: type                    ! 0=Science, 1=calibration
        character(len=25)   :: &
                       scheduledStartTime, &   ! name says it
                       scheduledEndTime, &     !   "    "   "
                       actualStartTime, &      !   "    "   "
                       actualEndTime           !   "    "   "
    end type

    type EulerAnglesType
        sequence
        real(kind=double)   :: phi, theta, psi
                                              ! 321 Euler angles
                                              ! corresponding to successive
                                              ! rotation around 3-2-1 axes
    end type


    !
    !   position type
    !
    type CartesianVectorType
        sequence
        real(kind=double)  :: x, y, z
    end type

end module OalTypes

