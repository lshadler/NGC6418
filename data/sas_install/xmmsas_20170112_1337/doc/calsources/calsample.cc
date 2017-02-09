//
//	test the cal
//
#include <iostream>
#include "CalServer.h"
#include "Xmm.h"

using namespace std;

int main()
{
	calServer.setInstrument(Xmm::EMOS1);
	calServer.state()->ccd()->set(EMOScam::CCD_1);
	calServer.state()->node()->set(EMOScam::PRIMARY_NODE);

	BadPixelDataServer *bpds = 0; bpds = calServer.getAtom(bpds);
	BadPixelMap badPixelMap = bpds->map();
	cout << "number of bad pixels: "<<badPixelMap.size()<<endl;
	const BadPixel *b;
	cout <<"Pixel (100/100) is ";
	if ((b = badPixelMap.isPixelBad(PixelLocation(100, 100))))
		cout<<"bad\n";
	else
		cout<<"not bad\n";

	cout <<"Pixel (541/300) is ";
	if ((b = badPixelMap.isPixelBad(PixelLocation(541, 300)))) {
		cout<<"bad\n";
		cout<<"yextent :  "<<b->yextent()<<endl
			<<"type    :  "<<(unsigned)b->type()<<endl
			<<"uplinked:  "<<(b->uplinked() ? "Y" : "N")<<endl;
	} else
		cout<<"not bad\n";

	cout<<"Boresight matrices:\n";
	for (unsigned i = 0; i < xmmPayLoad.instruments().size(); ++i) {
		XmmInstrument *ins = xmmPayLoad.instruments()[i];
		if (ins->id() == Xmm::ERM || ins->id() == Xmm::RGS1 ||
			ins->id() == Xmm::RGS2)
			continue;

		calServer.setInstrument(ins->id());

		Boresight *bs = 0; bs = calServer.getAtom(bs);
		cout<<"\nBoresightMatrix for "<<toString(ins->id())<<endl;
		AttitudeMatrix mat = bs->matrix(0.);
		cout<<mat<<endl;

		EulerAngles ea313 = mat.toEulerAngles(),
					ea321 = mat.toEulerAngles(EulerAngles::Euler321);
		cout<<"As Euler-313 angles:\n";
		cout<<"phi   = "<<ea313.phi() * RAD_TO_DEG<<endl;
		cout<<"theta = "<<ea313.theta() * RAD_TO_DEG<<endl;
		cout<<"psi   = "<<ea313.psi() * RAD_TO_DEG<<endl;

		cout<<"As Euler-321 angles:\n";
		cout<<"phi   = "<<ea321.phi() * RAD_TO_DEG<<endl;
		cout<<"theta = "<<ea321.theta() * RAD_TO_DEG<<endl;
		cout<<"psi   = "<<ea321.psi() * RAD_TO_DEG<<endl;

		cout<<"matrix from angles:\n";
		ea321 = bs->angles(0.);
		cout<<ea321.toMatrix()<<endl;
	}

	calServer.setInstrument(Xmm::EMOS1);
	calServer.ccf()->registerNewCifEntry("mymiscdata.ds");
	MiscDataServer *miscData = 0; miscData = calServer.getAtom(miscData);
	cout<<"focal length         : "<<miscData->get("FOCAL_LENGTH")<<endl
		<<"plate scale          : "<<miscData->get("PLATE_SCALE_X")<<endl
		<<"thermal exp          : "<<miscData->get("SI_THERMAL_EXP")<<endl
		<<"illegal parm         : ";
	if (miscData->has("WHATEVER"))
		cout<<miscData->get("WHATEVER");
	else
		cout<<"does not exist in CCF";
	cout<<"MM_TZ (from Lincoord): "<<miscData->get("LINCOORD:LINCOORD%MM_TZ")<<endl;
	cout<<"MM_TX (indirect)     : "<<miscData->get("MOS_MM_TX")<<endl;
	cout<<endl;

	ModeParameters *modeParam = 0; modeParam = calServer.getAtom(modeParam);
	cout<<"integration time : "<<modeParam->integrationTime()<<endl
		<<"shift time       : "<<modeParam->shiftTime()<<endl
		<<"underscan X      : "<<modeParam->underX()<<endl
		<<"overscan X       : "<<modeParam->overX()<<endl
		<<"smeared fraction : "<<modeParam->smearedFraction()<<endl;

   /* Test whether the windowing works */
    short rawx=50, rawy=604;
    CCDwindow *ccdwindow = new CCDwindow(modeParam->windowX0(),
                                         modeParam->windowY0(),
                        (modeParam->windowX0()+modeParam->windowDX()-1),
                        (modeParam->windowY0()+modeParam->windowDY()-1));

    if ( ccdwindow->isPixelInside(PixelLocation(rawx,rawy)) )
        cout<<"Pixel ("<<rawx<<","<<rawy<<") is inside window"<<endl;
    else
        cout<<"Pixel ("<<rawx<<","<<rawy<<") is outside window"<<endl;

   /* CTI corrector */
	CtiCorrector *ctiCorrector = 0; ctiCorrector = calServer.getAtom(ctiCorrector);
	cout<<"serial  : "<<ctiCorrector->serialCoefficients()[0][0]<<endl
		<<"        : "<<ctiCorrector->serialCoefficients()[0][1]<<endl
		<<"parallel: "<<ctiCorrector->parallelCoefficients()[0][0]<<endl
		<<"        : "<<ctiCorrector->parallelCoefficients()[0][1]<<endl;

	PatternLibServer *pattLib = 0; pattLib = calServer.getAtom(pattLib);
	cout<<"We have "<<pattLib->patterns()<<endl;

	for (unsigned n=0; n<10; ++n) {
		cout<<"patterns #"<<n<<":\n";
		const EventPattern &p = pattLib->pattern(n);
		for (unsigned n=0; n<p.xExtent(); ++n) {
			for (unsigned m=0; m<p.yExtent(); ++m)
				cout<<static_cast<int>(p[n][m])<<" ";
			cout<<endl;
		}
	}

	//	create an OM engine
	calServer.setInstrument(Xmm::OM);
	calServer.state()->filter()->set(Xmm::UVW1);
	/* AI gcc4 porting
	 * ‘bpds2’ may be used uninitialized in this function => ...
	 */
	BadPixelDataServer *bpds2 = 0;
	bpds2 = calServer.getAtom(bpds2);
	BadPixelMap badPixMap = bpds2->map();

	const BadPixel *badPixPtr = badPixMap.isPixelBad(PixelLocation(959, 1445));
	if (badPixPtr)
		cout<<"severity: "<<badPixPtr->severity()<<endl;
	OmFlatFieldServer *ffs = 0; ffs = calServer.getAtom(ffs);
	cout<<Xmm::toString(xmmPayLoad.emos1.id())<<endl;
	cout<<Xmm::toString(xmmPayLoad.rgs1.id())<<endl;

    // RGS cool pixels
	calServer.setInstrument(Xmm::RGS1);
	calServer.state()->ccd()->set(RGScam::CCD_1);
	calServer.state()->node()->set(RGScam::PRIMARY_NODE);

	RgsCoolPixDataServer *cpds = 0; cpds = calServer.getAtom(cpds);
	BadPixelMap coolPixelMap = cpds->map();
	cout << "number of bad pixels: "<<coolPixelMap.size()<<endl;
	cout <<"Pixel (62,1) is ";
	if ((b = coolPixelMap.isPixelBad(PixelLocation(62,1))))
		cout<<"bad\n";
	else
		cout<<"not bad\n";

    /* Add to bad pixel map
    BadPixelMap::const_iterator itr;
    for ( itr = coolPixelMap.begin(); itr != coolPixelMap.end(); ++itr ) {
        const PixelLocation &coordPair = itr->second.where();
        const BadPixel &bp = itr->second;
        badPixelMap[coordPair] = bp;
    }
    cout << "number of bad pixels: "<<badPixelMap.size()<<endl;
    */

	return 0;
}
