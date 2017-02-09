# Need a driver, with the same name as the task itself
#
# For more info about using the DAL and the parameter interface refer
# to the SAS documentation.
#
use SAS::param;
use SAS::error;
use SAS;
sub perltask {
    print "Parameter sval:->",stringParameter("sval"),"<-\n";
    SAS::error::message($SAS::AppMsg,$SAS::SilentMsg,"message AppMsg|SilentMsg");
}
