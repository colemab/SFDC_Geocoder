/*
    04/28/2013 TC -
        This is the context class in the strategy design pattern
        for our geocoding tool.  
        
        Here is sample code:
        
        GeoCoder GC = new GeoCoder('Bing');
        GC.GeoCodeAddress('251 South Donahue Drive', 'Auburn', 'AL', '35244', 'US');    
        
        And of course you could do this instead:
        GeoCoder GC = new GeoCoder('Google');
        GC.GeoCodeAddress('251 South Donahue Drive', 'Auburn', 'AL', '35244', 'US');
        
        or this:    
        GeoCoder GC = new GeoCoder('MapQuest');
        GC.GeoCodeAddress('251 South Donahue Drive', 'Auburn', 'AL', '35244', 'US');
        
*/
public with sharing class GeoCoder {
    
    // This custom exception will be thrown when a service can't be found by name
    public class NameException extends Exception{}

    // This map will hold all of the services
    public static final Map<String,GeoCodeService> GeoCodeServices;
    
    // Use reflection to populate the map upon load of the class
    static{
        
        // Pull back the active settings
        DC_GG__GeoCodeSettings__c CustomSetting_ServiceNames =  DC_GG__GeoCodeSettings__c.getInstance('Active');
        
        // initalize the list so we don't reference a null object
        List<string> GeoCodeServiceNames = new List<String>();
        
        // If the instance was found and a value, split it by commas and put them into the list
        if (CustomSetting_ServiceNames !=null && CustomSetting_ServiceNames.DC_GG__GeoCodeServiceNames__c != null) GeoCodeServiceNames = CustomSetting_ServiceNames.DC_GG__GeoCodeServiceNames__c.split(',');
        
        // initalize the map so we don't reference a null object
        GeoCodeServices = new Map<String,GeoCodeService>();
        
        // loop thru the list and try to populate the map
        for(String name : GeoCodeServiceNames) {
            try {
                    GeoCodeServices.put(name,(GeoCodeService)Type.forName(name+'GeoCodeUpdater').newInstance());
            } catch(Exception e) {continue;} // skip bad names silently
            
        } // for(String name : GeoCodeServices) {
         
    } // static

    private GeoCodeService CurrentGeoCodeService;
    
    public GeoCoder(String ServiceName) {
        if(!GeoCodeServices.containsKey(ServiceName)) throw new NameException(ServiceName);
        CurrentGeoCodeService = GeoCodeServices.get(ServiceName);
    } // constructor
    
    public GeoCodeResult GeoCodeAddress(String StreetAddress, String City, String State, String PostalCode, String Country)
    {
        return CurrentGeoCodeService.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
    } // GeoCodeAddress

} // GeoCoder