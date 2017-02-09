## @file
# Exposure Global Variables definition for ODF

package GVODF;


sub new {
    my $class = shift;
	my $self = {};	
	bless $self, $class;     
    return $self;
}

sub setAnalysisOption {
    my ( $self, $option ) = @_;
    $self->{_option} = $option if defined($option);
    return $self->{_option};
}

sub getAnalysisOption {
	 my( $self ) = @_;
    return $self->{_option};
}

sub setEPICsrc {
    my ( $self, $withepicsrc ) = @_;
    $self->{_withepicsrc} = $withepicsrc if defined($withepicsrc);
    return $self->{_withepicsrc};
}

sub getEPICsrc {
	 my( $self ) = @_;
    return $self->{_withepicsrc};
}

sub setRA {
    my ( $self, $ra ) = @_;
    $self->{_ra} = $ra if defined($ra);
    return $self->{_ra};
}

sub getRA {
	 my( $self ) = @_;
    return $self->{_ra};
}

sub setDEC {
    my ( $self, $dec ) = @_;
    $self->{_dec} = $dec if defined($dec);
    return $self->{_dec};
}

sub getDEC {
	 my( $self ) = @_;
    return $self->{_dec};
}

sub setSourceName {
    my ( $self, $sourceName ) = @_;
    $self->{_sourceName} = $sourceName if defined($sourceName);
    return $self->{_sourceName};
}

sub getSourceName {
	 my( $self ) = @_;
    return $self->{_sourceName};
}

sub setObsId {
    my ( $self, $obsId ) = @_;
    $self->{_obsId} = $obsId if defined($obsId);
    return $self->{_obsId};
}

sub getObsId {
	 my( $self ) = @_;
    return $self->{_obsId};
}

sub setEPN()
{
	my ( $self, $processEPN ) = @_;
    $self->{_processEPN} = $processEPN if defined($processEPN);
    return $self->{_processEPN};
}

sub EPN()
{
	 my( $self ) = @_;
    return $self->{_processEPN};
}


sub setEMOS1()
{
	my ( $self, $processEMOS1 ) = @_;
    $self->{_processEMOS1} = $processEMOS1 if defined($processEMOS1);
    return $self->{_processEMOS1};
}

sub EMOS1()
{
	 my( $self ) = @_;
    return $self->{_processEMOS1};
}
sub setEMOS2()
{
	my ( $self, $processEMOS2 ) = @_;
    $self->{_processEMOS2} = $processEMOS2 if defined($processEMOS2);
    return $self->{_processEMOS2};
}

sub EMOS2()
{
	 my( $self ) = @_;
    return $self->{_processEMOS2};
}

sub setRGS1()
{
	my ( $self, $processRGS1 ) = @_;
    $self->{_processRGS1} = $processRGS1 if defined($processRGS1);
    return $self->{_processRGS1};
}

sub RGS1()
{
	 my( $self ) = @_;
    return $self->{_processRGS1};
}
sub setRGS2()
{
	my ( $self, $processRGS2 ) = @_;
    $self->{_processRGS2} = $processRGS2 if defined($processRGS2);
    return $self->{_processRGS2};
}

sub RGS2()
{
	 my( $self ) = @_;
    return $self->{_processRGS2};
}

sub setOM()
{
	my ( $self, $processOM ) = @_;
    $self->{_processOM} = $processOM if defined($processOM);
    return $self->{_processOM};
}

sub OM()
{
	 my( $self ) = @_;
    return $self->{_processOM};
}

sub setOM_sourcematch()
{
	my ( $self, $OM_sourcematch ) = @_;
    $self->{_OM_sourcematch} = $OM_sourcematch if defined($OM_sourcematch);
    return $self->{_OM_sourcematch};
}

sub getOM_sourcematch()
{
	 my( $self ) = @_;
    return $self->{_OM_sourcematch};
}

sub print()
{
	my( $self ) = @_;
	printf("ODF info: %s %s %s %s %s %s\n",$self->getAnalysisOption(), $self->getEPICsrc(),
		$self->getRA(), $self->getDEC(), $self->getSourceName(), $self->getObsId());
		
	printf("ODF info: %s %s %s %s %s %s\n", $self->EPN(), $self->EMOS1(), $self->EMOS2(),
		$self->RGS1(), $self->RGS2(), $self->OM());
}


1;
