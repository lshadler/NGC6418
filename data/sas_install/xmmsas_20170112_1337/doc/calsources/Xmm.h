//-----------------------------------------------------------------------------
//
//						XMM Science Analysis System (SAS)
//					   (c) 1997 - 2010 European Space Agency
//
//-----------------------------------------------------------------------------
//
//	Xmm.h	--- container class for XMM-related constant data
//
//	DESCRIPTION:
//		Classes declared herein define interface to inquire information
//		about XMM and its payload in a convenient form. Examples are
//		the retrieval of constant parameters like the mission
//		reference time or the pixel dimensions of the instrument CCDs.
//
//	CHANGE HISTORY:
//		UL, 1997-??-??: 1.0.0: - first version
//		UL, 1998-08-11: 2.0.0: - added methods to EPNcam
//		UL, 1999-01-29: 2.1.0: - fixes to make it build under egcs-1.1.1
//		UL, 1999-03-09: 2.2.0: - minX/maxX swapped for RGScam
//		UL, 1999-03-29: 2.3.0: - general overhaul:
//									o added Xmm::missionStartTime
//									o added Xmm::missionEndTime
//									o make distinction between data mode
//									  and camera mode - corresponding types
//									  are DataMode and Mode
//									o added several methods to XXXcam classes
//									  for inquiring defaultModes/Filters, etc.
//		UL, 1999-04-12: 2.4.0: - added XmmInstrument::nFilters
//		UL, 1999-05-12: 2.5.0: - added eChannels() methods to RGScam
//		UL, 1999-06-11: 2.6.0: - added nominal orbital parameters
//		UL, 1999-06-15: 2.7.0: - added EPNcam::toQuadrantColumnNumber()
//		UL, 1999-06-18: 2.7.1: - added another version of
//								 EPNcam::toQuadrantColumnNumber()
//		UL, 1999-06-24: 2.7.2: - changed intialization of single global
//								 XmmPayLoad object
//		UL, 1999-10-20: 2.8.2: - added periodicHKmodes to XmmInstrument()
//							   - added DataModes HK_P7, HK_P8, HK_P9
//							   - removed DataMode: SUMMARY_PERIODIC_HOUSKEEPING
//								 (see [1] for details)
//		UL, 2000-03-17: 2.9.0: - added XmmInstrument::RGSinChain()
//		UL, 2000-04-10: 2.10.0:- brought list of data modes in line with
//								 issue 2.4 of [1]
//		UL, 2000-09-05: 2.11.0:- RGS DPP-Non-Periodic HK split in kind 1+2
//								 following corresponding change in ODF-ICD;
//								 for backward compatibilty old "DPH" will
//								 still be recognized
//		UL, 2000-09-21: 2.12.0:- toMode() now returns pair<Mode, bool>;
//								 second is set to false if the mode could
//								 not be uniquely determined; methods
//								 also takes 'silent' argument to suppress
//								 all warning messages
//		UL, 2000-09-29: 2.13.0:- modesVec() -> modes()
//							   - filtersVec() -> filters()
//							   - nodesVec() -> nodes()
//							   - changed EPN mode/filter names (no more
//								 prefix "Epn")
//		UL, 2000-10-17: 2.14.0:- added XmmInstrument::scienceDataModes()
//		UL, 2000-11-07: 2.15.0:- EMOScam::toMode() now takes also CCD ID
//								 as argument
//		UL, 2001-01-05: 2.16.0:- removed orbitalElements constant;
//							   - XmmOrbitSimulator is now time dependent
//								 as the orbital elements change strongly
//								 with time
//		UL, 2001-02-28: 2.17.0:- added couple of new classes:
//									* XmmGroundStation
//									* XmmMission
//		UL, 2001-03-22: 2.18.0:- added
//									* XmmInstrument::toHBR(Ccd)
//									* XmmInstrument::over/under/ScanX/Y()
//									* XmmInstrument::offsetX/Y()
//		UL, 2001-03-30: 2.19.0:- renamed data mode
//									Xmm::ATTITUDE -> Xmm::AttitudeHistory
//								 and added
//									Xmm::RAW_ATTITUDE
//		UL, 2001-07-16: 2.20.0:- added
//									* Xmm::scienceEngineeringDataModes()
//		UL, 2001-11-22: 2.21.0:- Xmm::toInstrument() now also accepts the
//								 short instrument names M1/M2/PN/R1/R2/OM
//		UL, 2002-02-19: 2.22.0:- added XmmInstrument::focusCcd()/isImaging()
//		UL, 2002-09-09: 2.23.0:- added New Norcia GS
//		UL, 2003-03-12: 2.24.0:- extended list of MODES
//		UL, 2003-04-03: 2.25.0:- added XmmInstrument::timeResolution()
//		RDS, 2003-12-05: 2.25.0:- added SYSPEAK_DIAGNOSTIC
//		RDS, 2004-06-29: 2.26.0:- added HBR_OFFSET_DATA
//
//	REFERENCES:
//		[1]: ICD: Observation and Slew Data Files, K. Galloway
//
//	$Header: /sasbuild/repositories/sasdev/sas/packages/caloalutils/src/Xmm.h,v 1.49 2010/11/16 13:52:51 aibarra Exp $
//

#ifndef XMM_H
#define XMM_H

#include <string>
#include "common.h"
#include "STime.h"
#include "Celestial.h"				//	RAD_TO_DEG
#include "KeplerOrbitSimulator.h"	//	OrbitalElements
#include "EarthPositionLocator.h"
#include "errstr.h"

class Attributable;

class Xmm {
public:
	static const STime missionReferenceTime;	//	set to:
												//	1998-01-01T00:00:00.00" TT
												//  = 1997-12-31T23:58.816 UTC
	static const STime missionStartTime;		//	set to launch date:
												//	1999-12-08T14:37:00.00"
	static const STime missionEndTime;			//	set to launch date +
												//	10 years


	//
	//	definition of instrument identifiers
	//
	enum Instrument {
				   INSTRUMENT_NONE = -1,
				   SC, XRT1, XRT2, XRT3, EMOS1, EMOS2, EPN, ERM, RGS1, RGS2,
				   OM };

	static const unsigned N_INSTRUMENTS = OM + 1;

	#define INSTRUMENT_STRINGS \
				  "XMM", "XRT1", "XRT2", "XRT3", "EMOS1", "EMOS2", "EPN", \
				  "ERM", "RGS1", "RGS2", "OM"

	#define INSTRUMENT_SHORT_STRINGS \
				  "SC", "X1", "X2", "X3", "M1", "M2", "PN", "RM", \
				  "R1", "R2", "OM"
	//
	//	Xmm::toInstrument("EMOS1") == Xmm::EMOS1
	//	Xmm::toInstrument("M1") == Xmm::EMOS1
	//	Xmm::toString(Xmm::EMOS1) == "EMOS1"
	//
	static Instrument toInstrument(const std::string &insString);
	static const std::string &toString(Instrument instr,
									   bool shortForm = false);


	//
	//	definition of CCD id type
	//
	typedef unsigned Ccd;
	static const Ccd CCD_NONE = 0;


	//
	//	definition pertaining to CCD readout nodes
	//
	enum Node { NODE_NONE = -1, PRIMARY_NODE, REDUNDANT_NODE };

	static const unsigned N_NODES = REDUNDANT_NODE + 1;

	#define NODE_STRINGS \
				  "PRIMARY", "REDUNDANT"

	static const std::vector<Node> emptyNodeVec;


	//
	//	Xmm::toNode("PRIMARY") == Xmm::PRIMARY_NODE
	//	Xmm::toString(Xmm::PRIMARY_NODE) == "PRIMARY"
	//
	static Node toNode(const std::string &nodeString);
	static Node toNode(unsigned nodeId);
	static const std::string &toString(Node node);


	//
	//	definition of instrument data modes / data file types
	//	NOTE: If changed corresponding declarations in caloaldefs.f90
	//		  must be adapted as well
	//
	enum DataMode {
		DATA_MODE_NONE = -1,

		//	EMOS
		IMAGING, TIMING, REDUCED_IMAGING, COMPRESSED_TIMING, AUXILIARY,
		DATA_DIAGNOSTIC, DATA_OFFSET_VARIANCE, COUNTING_CYCLE_REPORT,
		PERIODIC_HOUSEKEEPING,
		HBR_CONFIG_HOUSEKEEPING, HBR_BUFFER_HOUSEKEEPING,
		HBR_THRESHOLD_HOUSEKEEPING, EXTRAHEATING_CONF_HOUSEKEEPING,
		THERMAL_HOUSEKEEPING, BRIGHT_PIXEL_HOUSEKEEPING,

		//	EPN not in above list
		BURST, OFFSET_DATA, HBR_OFFSET_DATA, NOISE_DATA, DISCARDED_LINES_DATA,
		MAIN_PERIODIC_HOUSEKEEPING, ADD_PERIODIC_HOUSEKEEPING,

		//	ERM not in avove list
		ERM_COUNT_RATE, ERM_SPECTRA,

		//	RGS not in above list
		DATA_SPECTROSCOPY, HIGH_TIME_RESOLUTION, FULL_PERIODIC_HOUSEKEEPING,
		TEMP_PERIODIC_HOUSEKEEPING, DPP_HOUSEKEEPING,
		DPP_HOUSEKEEPING_1, DPP_HOUSEKEEPING_2, SYSPEAK_DIAGNOSTIC,

		//	OM not in above list
		DATA_FAST, ENGINEERING1, ENGINEERING2, ENGINEERING3, ENGINEERING4,
		ENGINEERING5, ENGINEERING6, ENGINEERING7, PRIORITY_FIELD_ACQUISITION,
		PRIORITY_WINDOW_DATA, PRIORITY_FAST, TRACKING_HISTORY,
		REFERENCE_FRAME, NON_PERIODIC_HOUSEKEEPING,

		//	S/C not in above list
		ATTITUDE_HISTORY, RAW_ATTITUDE, DUMMY_ATTITUDE, PREDICTED_ORBIT,
		RECONSTRUCTED_ORBIT, TIME_CORRELATION, RECONSTRUCTED_TIME_CORRELATION,
		HK_P1, HK_P2, HK_P3, HK_P4, HK_P5, HK_P6, HK_P7,
		HK_P8, HK_P9,

		//	general
		SUMMARY_INFORMATION
	};

	static const unsigned N_DATA_MODES = SUMMARY_INFORMATION + 1;

	#define DATA_MODE_STRINGS \
		  "Imaging", "Timing", "ReducedImaging", "CompressedTiming",	\
		  "Auxiliary", "Diagnostic", "OffsetVariance",					\
		  "CountingCycleReport", "PeriodicHousekeeping",				\
		  "HBRConfigurationNonPeriodicHousekeeping",					\
		  "HBRBufferSizeNonPeriodicHousekeeping",						\
		  "HBRThresholdValuesNonPeriodicHousekeeping",					\
		  "ExtraheatingConfigurationNonPeriodicHousekeeping",			\
		  "ThermalMonitoringLimitsNonPeriodicHousekeeping",				\
		  "BrightPixelTableNonPerodicHousekeeping",						\
																		\
		  "Burst", "OffsetData", "OffsetData", "NoiseData", 			\
          "DiscardedLinesData",											\
		  "MainPeriodicHousekeeping", "AdditionalPeriodicHousekeeping",	\
																		\
		  "ERMCountRate", "ERMSpectra",									\
																		\
		  "Spectroscopy", "HighTimeResolution",							\
		  "FullPeriodicHousekeeping",									\
		  "CCDTemperaturePeriodicHousekeeping",							\
		  "DPPNonPeriodicHousekeeping",									\
		  "DPPNonPeriodicHousekeeping1", "DPPNonPeriodicHousekeeping2",	\
          "SyspeakDiagnostic",                                          \
																		\
		  "Fast", "Engineering1", "Engineering2", "Engineering3",		\
		  "Engineering4", "Engineering5", "Engineering6",				\
		  "Engineering7",												\
		  "PriorityFieldAcquisition",									\
		  "PriorityWindowData", "PriorityFast", "TrackingHistory",		\
		  "ReferenceFrame", "NonPeriodicHousekeeping",					\
																		\
		  "AttitudeHistory", "RawAttitude", "DummyAttitude",			\
		  "PredictedOrbit",												\
		  "ReconstructedOrbit", "TimeCorrelation",						\
		  "ReconstructedTimeCorrelation",								\
		  "HK1", "HK2", "HK3", "HK4", "HK5", "HK6", "HK7", "HK8", "HK9",\
		  "SummaryInformation"

	static const std::vector<DataMode> emptyDataModeVec;

	//
	//	Xmm::toDataMode("IMAGING") == Xmm::IMAGING
	//	Xmm::toString(Xmm::IMAGING) == "IMAGING"
	//
	static DataMode toDataMode(const std::string &modeString);
	static const std::string &toString(DataMode dataMode);


	//
	//	definition of camera modes
	//	NOTE: If changed corresponding declarations in caloaldefs.f90
	//		  must be adapted as well
	//
	enum Mode {
		MODE_NONE = -1,

		//	EMOS
		PRIME_FULL_WINDOW, PRIME_PARTIAL_RFS, PRIME_PARTIAL_W2,
		PRIME_PARTIAL_W3, PRIME_PARTIAL_W4, PRIME_PARTIAL_W5,
		PRIME_PARTIAL_W6, FAST_UNCOMPRESSED, FAST_COMPRESSED,
        PRIME_FULL_WIN3X3,
		OFFSET_VARIANCE, CCD_DIAGNOSTIC,
		DIAGNOSTIC_1X1, DIAGNOSTIC_3X3,
		EXTRA_HEATING_ANNEALING, EXTRA_HEATING_DEICING,
		EXTRA_HEATING_DECONTAM, IN_FLIGHT_TEST,
		PRIME_FULL_NO_BPMASK, DIAGNOSTIC_1X1_RPP, // SCR 117

		//	EPN not in above list
		PRIME_FULL_WINDOW_EXTENDED,
		PRIME_LARGE_WINDOW, PRIME_SMALL_WINDOW,
		FAST_TIMING, FAST_BURST, PRIME_FULL_OFFSET,
		PRIME_LARGE_OFFSET, OFFSET, NOISE, DIAGNOSTIC,
		PRIME_FULL_WINDOW_MASKED, PRIME_FULL_WINDOW_LOWGAIN, // SCR 117

		//	RGS not in above list
		SPECTROSCOPY, HIGH_EVENT_RATE,
		HIGH_EVENT_RATE_WITH_SES, HIGH_EVENT_RATE_WITH_SER,
		HIGH_TIME_RESOLUTION_SINGLE_CCD, HIGH_TIME_RESOLUTION_MULTIPLE_CCD,
		DIAGNOSTIC_2X2, DIAGNOSTIC_4X4, DIAGNOSTIC_5X5, SPECTROSCOPY_TEST,
		DIAGNOSTIC_TEST,
		SPECTROSCOPY_BASELINE, SPECTROSCOPY_1X1, READOUT_STORAGE_SECTION, // SCR 117
		SPECTROSCOPY_SMALL_WINDOW,
		//	OM
		IMAGE, FAST,
		RAW_DATA_BLUE_DSP12, RAW_DATA_BLUE_DSP1, RAW_DATA_BLUE_DSP2,
        CENTROIDING_DATA, FULL_FRAME, CENTROIDING_CONFIRMATION,
		INTENSIFIER_CHARACTERISTICS, FLATFIELDING, DARK_LOW, DARK_HIGH,
		FLAT_FIELD_LOW, FLAT_FIELD_HIGH
	};

	static const unsigned N_MODES = FLAT_FIELD_HIGH + 1;
	// SCR 117
	#define MODE_STRINGS \
		"PrimeFullWindow", "PrimePartialRFS", "PrimePartialW2",			\
		"PrimePartialW3", "PrimePartialW4", "PrimePartialW5",			\
		"PrimePartialW6", "FastUncompressed", "FastCompressed",			\
		"PrimeFullWin3x3", 												\
		"OffsetVariance",												\
		"CcdDiagnostic", "Diagnostic1x1", "Diagnostic3x3",				\
		"ExtraHeatingAnnealing",										\
		"ExtraHeatingDeicing", "ExtraHeatingDecontam", "InFligtTest",	\
		"PrimeFullNoBadPixelMask", "Diagnostic1x1ResetPerPixel",		\
																		\
		"PrimeFullWindowExtended",										\
		"PrimeLargeWindow", "PrimeSmallWindow",							\
		"FastTiming", "FastBurst", "PrimeFullOffset",					\
		"PrimeLargeOffset", "Offset", "Noise", "Diagnostic",			\
		"PrimeFullWindowMasked", "PrimeFullWindowLowGain",              \
																		\
		"Spectroscopy", "HighEventRate",								\
		"HighEventRateWithSES", "HighEventRateWithSER",					\
		"HighTimeResolutionSingleCcd", "HighTimeResolutionMultipleCcd",	\
		"Diagnostic2x2", "Diagnostic4x4", "Diagnostic5x5",				\
		"SpectroscopyTest",	"DiagnosticTest", "SpectroscopyBaseline",   \
		"Spectroscopy1x1", "ReadoutStorageSection", 					\
		"SpectroscopySmallWindow",										\
																		\
		"Image", "Fast",												\
		"RawDataBlueDsp12",	"RawDataBlueDsp1", "RawDataBlueDsp2",		\
		"CentroidingData", "FullFrame", "CentroidingConfirmation",		\
		"IntensifierCharacteristics", "FlatFielding",					\
		"DarkLow", "DarkHigh", "FlatFieldLow", "FlatFieldHigh"

	static const std::vector<Mode> emptyModeVec;

	//
	//	Xmm::toMode("PrimeFullWindow") == Xmm::PRIME_FULL_WINDOW
	//	Xmm::toString(Xmm::PRIME_FULL_WINDOW) == "PrimeFullWindow"
	//
	static Mode toMode(const std::string &modeString);
	static Mode toMode(unsigned modeId);
	static const std::string &toString(Mode modeId);

    //
    //  definition of filter identifiers
    //  e.g. Xmm::GRISM1              -> integer specifying OM grism filter
    //
    enum Filter {
		FILTER_NONE = -1,

		//	EMOS/EPN
		OPEN, CLOSED, THIN1, THIN2, MEDIUM, THICK,
		CAL_OPEN, CAL_CLOSED, CAL_THIN1, CAL_THIN2, CAL_MEDIUM, CAL_THICK,

		//	OM
		BLOCKED, UVW2, UVM2, UVW1, U, B, V, WHITE, MAGNI, GRISM1, GRISM2,
		GRISM10, GRISM20, BARRED_U };

	static const unsigned N_FILTERS = BARRED_U + 1;

	#define FILTER_STRINGS \
		"Open", "Closed", "Thin1", "Thin2", "Medium", "Thick", "CalOpen",	\
		"CalClosed", "CalThin1", "CalThin2", "CalMedium", "CalThick",		\
																			\
		"Blocked", "UVW2", "UVM2", "UVW1", "U", "B", "V", "White",			\
		"Magnifier", "Grism1", "Grism2", "Grism10", "Grism20", "BarredU"

	static const std::vector<Filter> emptyFilterVec;

	//
	//	Xmm::toFilter("Magnifier") == MAGNI
	//	Xmm::toString(Xmm::MAGNI) == "Magnifier"
	//
	static Filter toFilter(const std::string &filterString);
	static Filter toFilter(unsigned filterId);
	static const std::string &toString(Filter filter);

	inline static Instrument behindTelescope(Instrument instr)
	{
		switch (instr) {
			case EMOS1 :
			case RGS1  : return XRT1;
			case EMOS2 :
			case RGS2  : return XRT2;
			case EPN   : return XRT3;
			default	   : return instr;
		}
	}

	static double toTimeTag(const STime &time)
		{ return time - missionReferenceTime; }
	static double toTimeTag(const std::string &time)
		{ return toTimeTag(STime(time)); }

private:
	//	private constructor to prevent instantiation
	Xmm() {}
};

typedef Xmm::Instrument	Instrument;	//	Instrument identifier
typedef Xmm::Ccd		Ccd;		//	CCD identifier
typedef Xmm::Node		Node;		//	node identifier
typedef Xmm::DataMode	DataMode;	//	data mode
typedef Xmm::Mode		Mode;		//	mode identifier
typedef Xmm::Filter		Filter;		//	filter identifier

std::ostream &operator<<(std::ostream &os, Instrument instrument);
//std::ostream &operator<<(std::ostream &os, Ccd ccd);
std::ostream &operator<<(std::ostream &os, Node node);
std::ostream &operator<<(std::ostream &os, Mode mode);
std::ostream &operator<<(std::ostream &os, DataMode mode);
std::ostream &operator<<(std::ostream &os, Filter filter);


class XmmInstrument {
public:
	XmmInstrument() {}
	virtual ~XmmInstrument() {}
	virtual Xmm::Instrument id() const			{ return Xmm::SC; }
	virtual bool isImaging() const				{ return true; }

	virtual Xmm::Instrument behindTelescope() const
	{ return Xmm::behindTelescope(id()); }
	virtual Xmm::Instrument RGSinChain() const	{ return id(); }
	virtual unsigned nCcds() const				{ return 0; }
	virtual Ccd centralCcd() const				{ return 0; }
	virtual Ccd focusCcd() const				{ return centralCcd(); }

	virtual unsigned nNodes() const				{ return nodes().size(); }
	virtual const std::vector<Node> &nodes() const
												{ return Xmm::emptyNodeVec; }

	virtual const std::vector<Mode> &modes() const
												{ return Xmm::emptyModeVec; }
	virtual unsigned nModes() const				{ return modes().size(); }
	virtual unsigned modeIndex(Mode) const;
	virtual Mode defaultMode() const			{ return modes()[0]; }

	virtual const std::vector<DataMode> &periodicHKmodes() const;
	virtual const std::vector<DataMode> &scienceDataModes() const;
	virtual const std::vector<DataMode> &scienceEngineeringDataModes() const;

	virtual const std::vector<Filter> &filters() const
												{ return Xmm::emptyFilterVec; }
	virtual unsigned nFilters() const			{ return filters().size(); }
	virtual unsigned filterIndex(Filter) const;
	virtual Filter defaultFilter() const		{ return filters()[0]; }

	virtual unsigned minX() const				{ return 0; }
	virtual unsigned maxX() const				{ return 0; }
	virtual unsigned minY() const				{ return 0; }
	virtual unsigned maxY() const				{ return 0; }
	virtual unsigned eChannels() const			{ return 0; }

	virtual unsigned underScanX() const			{ return 0; }
	virtual unsigned overScanX() const			{ return 0; }
	virtual unsigned underScanY() const			{ return 0; }
	virtual unsigned overScanY() const			{ return 0; }
	virtual int offsetX() const					{ return 0; }
	virtual int offsetY() const					{ return 0; }

	virtual unsigned short toHBR(Ccd) const;

		//	maximum time resolution - corresponds to 1 FTFINE unit
	virtual double timeResolution() const		{ return 1./65536.;	} // [s]
		//	16-bit fine time component of Central On-Board Clock will tick
		//	at maximum resolution: 2^-16 sec ~ 15.3 usec
};


struct CoreModeParameters {
	unsigned short	windowX0,
					windowY0,
					windowDX,
					windowDY,
					frameTime;	//	ms
};

//
//	---( EMOScam )-----------------------------------------------------------
//
class EMOScam : public XmmInstrument {
public:
	static const Ccd CCD_1 = 1,
					 CCD_2 = 2,
					 CCD_3 = 3,
					 CCD_4 = 4,
					 CCD_5 = 5,
					 CCD_6 = 6,
					 CCD_7 = 7,
					 CCD_CENTRAL = CCD_1,
					 CCD_5CLOCK = CCD_2,
					 CCD_3CLOCK = CCD_3,
					 CCD_1CLOCK = CCD_4,
					 CCD_11CLOCK= CCD_5,
					 CCD_9CLOCK = CCD_6,
					 CCD_7CLOCK = CCD_7,
					 CCD_FIRST = CCD_1,
					 CCD_LAST = CCD_7;

	unsigned nCcds() const						{ return CCD_LAST; }
	Ccd centralCcd() const						{ return CCD_CENTRAL; }

	static const Node PRIMARY_NODE = Xmm::PRIMARY_NODE;
	const std::vector<Node> &nodes() const		{ return nodesVec; }

	const std::vector<Mode> &modes() const		{ return modesVec; }

	static std::pair<Mode, bool>
				toMode(const std::vector<const Attributable *> &av,
					   const std::vector<CoreModeParameters> &modeParameters,
					   Ccd ccd,
					   bool silent = false);

	const std::vector<DataMode> &periodicHKmodes() const
												{ return periodicHKmodesVec; }
	const std::vector<DataMode> &scienceDataModes() const
												{ return scienceDataModesVec; }
	const std::vector<DataMode> &scienceEngineeringDataModes() const
									{ return scienceEngineeringDataModesVec; }

	const std::vector<Filter> &filters() const	{ return filtersVec; }

	unsigned minX() const						{ return 1; }
	unsigned maxX() const						{ return 600; }
	unsigned minY() const						{ return 1; }
	unsigned maxY() const						{ return 600; }
	unsigned eChannels() const					{ return 4096; }

	unsigned underScanX() const					{ return 5; }
	unsigned overScanX() const					{ return 5; }
	unsigned underScanY() const					{ return 0; }
	unsigned overScanY() const					{ return 2; }
	int offsetX() const							{ return 2; }
	int offsetY() const							{ return 2; }
	unsigned short toHBR(Ccd ccd) const;

	double timeResolution() const				{ return 40.e-6; } // [s]
		//	EPIC-EST-SP-001, page 33

private:
	static const std::vector<Node> nodesVec;
	static const std::vector<Mode> modesVec;
	static const std::vector<DataMode> periodicHKmodesVec;
	static const std::vector<DataMode> scienceDataModesVec;
	static const std::vector<DataMode> scienceEngineeringDataModesVec;
	static const std::vector<Filter> filtersVec;
};

class EMOScam1 : public EMOScam {
public:
	Xmm::Instrument id() const					{ return Xmm::EMOS1; }
	Xmm::Instrument RGSinChain() const			{ return Xmm::RGS1; }
};

class EMOScam2 : public EMOScam {
public:
	Xmm::Instrument id() const					{ return Xmm::EMOS2; }
	Xmm::Instrument RGSinChain() const			{ return Xmm::RGS2; }
};


//
//	---( EPNcam )-----------------------------------------------------------
//
class EPNcam : public XmmInstrument {
public:
	static const Ccd CCD_1		= 1,
					 CCD_2		= 2,
					 CCD_3		= 3,
					 CCD_4		= 4,
					 CCD_5		= 5,
					 CCD_6		= 6,
					 CCD_7		= 7,
					 CCD_8		= 8,
					 CCD_9		= 9,
					 CCD_10		= 10,
					 CCD_11		= 11,
					 CCD_12		= 12,
					 CCD_NW		= CCD_3,
					 CCD_FIRST	= CCD_1,
					 CCD_NE		= CCD_6,
					 CCD_SW		= CCD_12,
					 CCD_LAST	= CCD_12,
					 CCD_SE		= 9;

	unsigned nCcds() const						{ return CCD_LAST; }
	Ccd focusCcd() const						{ return CCD_4; }

	unsigned nNodes() const						{ return 64; //	one node
															//	per column
												}

	const std::vector<Mode> &modes() const		{ return modesVec; }

	static std::pair<Mode, bool>
				toMode(const std::vector<const Attributable *> &av,
					   const std::vector<CoreModeParameters> &modeParameters,
					   bool silent = false);

	static Mode toMode(const std::string &dataType);

	const std::vector<DataMode> &periodicHKmodes() const
												{ return periodicHKmodesVec;}
	const std::vector<DataMode> &scienceDataModes() const
												{ return scienceDataModesVec; }
	const std::vector<DataMode> &scienceEngineeringDataModes() const
									{ return scienceEngineeringDataModesVec; }

	const std::vector<Filter> &filters() const	{ return filtersVec; }

	unsigned minX() const						{ return 1; }
	unsigned maxX() const						{ return 64; }
	unsigned minY() const						{ return 1; }
	unsigned maxY() const						{ return 200; }
	unsigned eChannels() const					{ return 4096; }

	Xmm::Instrument id() const					{ return Xmm::EPN; }

	double timeResolution() const				{ return 20.48e-6; } // [s]
		//	EPIC-EST-SP-001, page 33

public:
	static unsigned toCcdId(Ccd ccd);
	static unsigned toQuadrantId(Ccd ccd);
	static Ccd toChipNr(Ccd ccd, unsigned quadrant);
	static unsigned toQuadrantColumnNumber(Ccd ccd, unsigned rawX);
	static unsigned toQuadrantColumnNumber(unsigned quadId, unsigned ccdId,
										   unsigned rawX);

private:
	static const std::vector<Mode> modesVec;
	static const std::vector<DataMode> periodicHKmodesVec;
	static const std::vector<DataMode> scienceDataModesVec;
	static const std::vector<DataMode> scienceEngineeringDataModesVec;
	static const std::vector<Filter> filtersVec;
};


//
//	---( ERMcam )-----------------------------------------------------------
//
class ERMcam : public XmmInstrument {
public:
	Xmm::Instrument id() const					{ return Xmm::ERM; }
	bool isImaging() const						{ return false; }
};


//
//	---( RGScam )-----------------------------------------------------------
//
class RGScam : public XmmInstrument {
public:
	static const Ccd CCD_1 = 1,
					 CCD_2 = 2,
					 CCD_3 = 3,
					 CCD_4 = 4,
					 CCD_5 = 5,
					 CCD_6 = 6,
					 CCD_7 = 7,
					 CCD_8 = 8,
					 CCD_9 = 9,
					 CCD_FIRST = CCD_1,
					 CCD_W = CCD_1,
					 CCD_E = CCD_9,
					 CCD_LAST = CCD_9;

	unsigned nCcds() const						{ return CCD_LAST; }
	Ccd centralCcd() const						{ return CCD_5; }

	bool isImaging() const						{ return false; }

	static const Node PRIMARY_NODE = Xmm::PRIMARY_NODE;

	const std::vector<Node> &nodes() const		{ return nodesVec; }
	const std::vector<Mode> &modes() const		{ return modesVec; }

	static std::pair<Mode, bool>
				toMode(const std::vector<const Attributable *> &av,
					   unsigned ocbFactor, bool silent = false);

	const std::vector<DataMode> &periodicHKmodes() const
												{ return periodicHKmodesVec; }
	const std::vector<DataMode> &scienceDataModes() const
												{ return scienceDataModesVec; }
	const std::vector<DataMode> &scienceEngineeringDataModes() const
									{ return scienceEngineeringDataModesVec; }

	Filter defaultFilter() const				{ return Xmm::FILTER_NONE; }

	static const unsigned DEFAULT_OCB = 3;
	static const std::vector<unsigned> ocbs;

	unsigned minX() const						{ return 1; }
	unsigned maxX() const						{ return 1024; }
	unsigned minY() const						{ return 1; }
	unsigned maxY() const						{ return 384; }

	unsigned eChannels() const					{ return 4096; }

	double timeResolution() const				{ return 1./65536.; } // [s]
		//	RGS clock ticks at S/C clock rate

private:
	static const std::vector<Node> nodesVec;
	static const std::vector<Mode> modesVec;
	static const std::vector<DataMode> periodicHKmodesVec;
	static const std::vector<DataMode> scienceEngineeringDataModesVec;
	static const std::vector<DataMode> scienceDataModesVec;
};

class RGScam1 : public RGScam {
public:
	Xmm::Instrument id() const					{ return Xmm::RGS1; }
};

class RGScam2 : public RGScam {
public:
	Xmm::Instrument id() const					{ return Xmm::RGS2; }
};


//
//	---( OMcam )-----------------------------------------------------------
//
class OMcam : public XmmInstrument {
public:
	static const Ccd CCD_1		= 1,
					 CCD_FIRST	= CCD_1,
					 CCD_LAST	= CCD_1;

	unsigned nCcds() const						{ return CCD_LAST; }
	Ccd centralCcd() const						{ return CCD_1; }

	static const Node PRIMARY_NODE = Xmm::PRIMARY_NODE;
	const std::vector<Node> &nodes() const		{ return nodesVec; }
	const std::vector<Mode> &modes() const		{ return modesVec; }

	static std::pair<Mode, bool>
				toMode(const std::vector<const Attributable *> &av,
					   bool silent = false);

	const std::vector<DataMode> &periodicHKmodes() const
												{ return periodicHKmodesVec; }
	const std::vector<DataMode> &scienceDataModes() const
												{ return scienceDataModesVec; }
	const std::vector<DataMode> &scienceEngineeringDataModes() const
									{ return scienceEngineeringDataModesVec; }

	const std::vector<Filter> &filters() const	{ return filtersVec; }

	unsigned minX() const						{ return 1; }
	unsigned maxX() const						{ return 2048; }
	unsigned minY() const						{ return 1; }
	unsigned maxY() const						{ return 2048; }

	Xmm::Instrument id() const					{ return Xmm::OM; }

	double timeResolution() const				{ return 9.765625E-4; } //[s]
		// ODF ICD p. 73, bullet 3

private:
	static const std::vector<Node> nodesVec;
	static const std::vector<Mode> modesVec;
	static const std::vector<DataMode> periodicHKmodesVec;
	static const std::vector<DataMode> scienceDataModesVec;
	static const std::vector<DataMode> scienceEngineeringDataModesVec;
	static const std::vector<Filter> filtersVec;
};


//
//	---( XmmPayLoad )---------------------------------------------------------
//

class XmmPayLoad {
public:
	XmmPayLoad() { }

	static EMOScam1 emos1;
	static EMOScam2 emos2;
	static ERMcam	erm;
	static EPNcam	epn;
	static RGScam1	rgs1;
	static RGScam2	rgs2;
	static OMcam	om;
	static XmmInstrument	xmm;

	static const std::vector<XmmInstrument *> &instruments();
	static const XmmInstrument &instrument(Xmm::Instrument inst);

	~XmmPayLoad() { }
}; // XmmPayLoad()


class XmmDataHandler {
public:
	static double timingDelay() { return 626.17e-6; }
									//	OBDH timing delay; value from
									//	Ed Serpell; email 2001-02-28;
									//	XMCS v72
}; // XmmDataHandler


class XmmOrbitSimulator : public KeplerOrbitSimulator {
public:
	XmmOrbitSimulator(const STime &time = Xmm::missionStartTime);
		//
		//	PURPOSE:
		//		Instantiate XmmOrbitSimulator;
		//		XmmOrbitSimulator::position()/velocity() will receive
		//		time arguments in MET
		//


	~XmmOrbitSimulator() { }
}; // XmmOrbitSimulator()


class XmmGroundStation : public EarthPositionLocator {
public:
	XmmGroundStation(const EarthObject &where, unsigned short id,
					 double timingDelay = 0.);


	unsigned short id() const { return _id; }
		//
		//	RETURNS:
		//		Numerical ID of the station
		//


	double timingDelay() const { return _timingDelay; }
		//
		//	RETURNS:
		//		Time delay of antenna signal time stamping [s]
		//


	~XmmGroundStation() { }

private:
	unsigned short _id;
	double		   _timingDelay;
}; // XmmGroundStation()


class XmmMission {
public:
	static const XmmPayLoad &payLoad();
	static const XmmDataHandler &dataHandler();
	static const XmmOrbitSimulator &orbitSimulator();

	enum GroundStationPlaces { Vilspa1 = 0, Vilspa2, Vilspa3,
							   Perth, Kourou, Santiago, NewNorcia,
							   LASTGS = NewNorcia };
	static const XmmGroundStation &groundStation(GroundStationPlaces place);
	static const XmmGroundStation &groundStation(unsigned short GSID);

private:
	typedef std::vector<XmmGroundStation>	GroundStations;
	static GroundStations	_groundStations;

	static void checkGSset();

	XmmMission() {}
	~XmmMission() {}
}; // XmmMission


//
//	there is a single global instance of an object called
//
//		xmmPayLoad
//
#define xmmPayLoad	XmmMission::payLoad()

#endif
