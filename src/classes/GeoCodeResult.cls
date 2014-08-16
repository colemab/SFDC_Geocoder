/*
    04/28/2013 TC -
        This is a wrapper class used to hold the results of a GeoCoding attempt.
        Since you can't have work pending (i.e. set a database field) prior to
        a http request / call out, this wrapper class is used to hold the 
        results in memory when in batch mode.
*/
public with sharing class GeoCodeResult {
    
    // these will get set by the geocoder implementation (i.e. bing, google)
    public double Longitude {get;set;}
    public double Latitude {get;set;}

    public string Status {get;set;}
    public string RequestURL {get;set;} 

    public datetime TimeStamp {get;set;}
    public string TraceMessage {get;set;}

	public string Engine {get;set;}
	public string Quality {get;set;}
    
    // but this will get set by the actual calling program
    public id RecordID {get;set;}        
    
    // this is used to determine if another attempt needs to be made    
    public boolean HasResults {
        get {
        	// 0, 0 is in the middle of the ocean so don't save those records
            if (Longitude != null && Latitude != null && Longitude != 0 && Latitude !=0) {
                return true;
            } else {
                return false;
            } // check for long/lat
        } // get
    } // HasResults
    
} // GeoCodeResult