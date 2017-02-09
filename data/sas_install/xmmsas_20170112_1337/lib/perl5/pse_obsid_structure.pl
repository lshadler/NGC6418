## @file
# Define Analysis Main Structure

#========================================================================
sub pse_obsid_structure(){

    use vars qw(%obsid_instruments);
        
    my $source_obsID = $odf_object->getObsId();
    
    $obsid_instruments{$source_obsID}{'pn'}{'instrument'}     ="pn";       # Init main structure fields
    $obsid_instruments{$source_obsID}{'pn'}{'obsid'}          =$source_obsID;       
    $obsid_instruments{$source_obsID}{'pn'}{'date'}           ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'starting_time'}  ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'ending_time'}    ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'duration'}       ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'ontime'}         ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'livetime'}       ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'mode'}           ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'submode'}        ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'filter'}         ='unknown';
    $obsid_instruments{$source_obsID}{'pn'}{'exposure'}       ='unknown';

    $obsid_instruments{$source_obsID}{'m1'}{'instrument'}   ="m1";
    $obsid_instruments{$source_obsID}{'m1'}{'obsid'}        =$source_obsID;
    $obsid_instruments{$source_obsID}{'m1'}{'date'}         ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'starting_time'}='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'ending_time'}  ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'duration'}     ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'ontime'}       ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'livetime'}     ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'mode'}         ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'submode'}      ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'filter'}       ='unknown';
    $obsid_instruments{$source_obsID}{'m1'}{'exposure'}     ='unknown';


    $obsid_instruments{$source_obsID}{'m2'}{'instrument'}   ="m2";
    $obsid_instruments{$source_obsID}{'m2'}{'obsid'}        =$source_obsID;
    $obsid_instruments{$source_obsID}{'m2'}{'date'}         ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'starting_time'}='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'ending_time'}  ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'duration'}     ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'ontime'}       ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'livetime'}     ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'mode'}         ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'submode'}      ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'filter'}       ='unknown';
    $obsid_instruments{$source_obsID}{'m2'}{'exposure'}     ='unknown';

    $obsid_instruments{$source_obsID}{'rgs1'}{'instrument'}    ="rgs1";
    $obsid_instruments{$source_obsID}{'rgs1'}{'obsid'}         =$source_obsID;
    $obsid_instruments{$source_obsID}{'rgs1'}{'date'}          ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'starting_time'} ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'ending_time'}   ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'duration'}      ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'ontime'}        ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'livetime'}      ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'mode'}          ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'submode'}       ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'filter'}        ='unknown';
    $obsid_instruments{$source_obsID}{'rgs1'}{'exposure'}      ='unknown';
    
    $obsid_instruments{$source_obsID}{'rgs2'}{'instrument'}    ="rgs2";
    $obsid_instruments{$source_obsID}{'rgs2'}{'obsid'}         =$source_obsID;
    $obsid_instruments{$source_obsID}{'rgs2'}{'date'}          ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'starting_time'} ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'ending_time'}   ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'duration'}      ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'ontime'}        ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'livetime'}      ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'mode'}          ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'submode'}       ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'filter'}        ='unknown';
    $obsid_instruments{$source_obsID}{'rgs2'}{'exposure'}      ='unknown';


    $obsid_instruments{$source_obsID}{'om'}{'instrument'}     ="om";
    $obsid_instruments{$source_obsID}{'om'}{'obsid'}          =$source_obsID;
    $obsid_instruments{$source_obsID}{'om'}{'date'}           ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'starting_time'}  ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'ending_time'}    ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'duration'}       ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'ontime'}         ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'livetime'}       ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'mode'}           ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'submode'}        ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'filter'}         ='unknown';
    $obsid_instruments{$source_obsID}{'om'}{'exposure'}       ='unknown';
    
    return(1);
}

## @method void pse_fill_structure($obsid,$instr,$field,$value)
# Fills the value of a given field in the obsid structure
# @param obsid Observation ID
# @param instr Instrument
# @param field Field in the Structure to be filled
# @param value Value of the Field 
# @return Void

#========================================================================
sub pse_fill_structure(){

    my $obsid=$_[0];
    my $instr=$_[1];
    my $field=$_[2];
    my $value=$_[3];
    
    $obsid_instruments{$obsid}{$instr}{$field}=$value;
    
    return(1);
}

## @method void pse_print_obsid_instruments($obsid,$instr,$field)
# Prints the value of a given field in the obsid structure
# @param obsid Observation ID
# @param instr Instrument
# @param field Field in the Structure to be printed
# @return Void

#========================================================================
sub pse_print_obsid_instruments(){

    my $obs;
    my $instr;
    my $field;
    
    $logger->info( "----> OBSID Instrument Structure Information ");
    
    for $obs ( keys %obsid_instruments) {
	for $instr ( keys %{ $obsid_instruments{$obs}} ) {
	    for $field ( keys %{ $obsid_instruments{$obs}{$instr} } ) {
		$logger->info( "$obs : $instr : $field : $obsid_instruments{$obs}{$instr}{$field} ");
	    }
	}
    }
    
    return(1);
}
1;
