/*
    04/28/2013 TC -
        This is the interface in the strategy design pattern
        for our geocoding tool.  This interface will be used
        by the various different geocoder classes to call
        different services (i.e. google, bing, etc) 
*/
public interface GeoCodeService {

    GeoCodeResult GeoCodeAddress(String StreetAddress, String City, String State, String PostalCode, String Country);

} // GeoCodeService