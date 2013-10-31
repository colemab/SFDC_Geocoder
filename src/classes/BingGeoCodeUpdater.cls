public with sharing class BingGeoCodeUpdater implements GeoCodeService{ 

    public string getAPIKey() {
        string ReturnValue = '';
        
        DC_GG__GeoCodeSettings__c BingAPIKey = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (BingAPIKey !=null && BingAPIKey.DC_GG__BingMapsKey__c != null) ReturnValue = BingAPIKey.DC_GG__BingMapsKey__c;
        
        return ReturnValue;
    } // getAPIKey

    public GeoCodeResult GeoCodeAddress(String StreetAddress, String City, String State, String PostalCode, String Country) 
    {
        GeoCodeResult CurrentGeoCodeResult = new GeoCodeResult();
        
        // format the string for the Bing Maps engine
        String FormattedAddress = BuildAddressString(StreetAddress, City, State, PostalCode, Country);
        
        String key = getAPIKey();

        if (key == '') {
            CurrentGeoCodeResult.Status = 'NO_API_KEY';
        } else if (!String.isBlank(FormattedAddress)) {
            
            string GeoCodeRequestURL = 'http://dev.virtualearth.net/REST/v1/Locations'+ FormattedAddress + '?key=' + key + '&maxResults=1';
            CurrentGeoCodeResult.RequestURL = GeoCodeRequestURL;
            system.debug('Request URL was: ' + GeoCodeRequestURL);
            
            // Setup and make the HTTP callout
            HttpRequest GeoCodeRequest = new HttpRequest();
            Http GeoCodeHttp = new Http();               
            GeoCodeRequest.setMethod('GET');            
            GeoCodeRequest.setEndpoint(GeoCodeRequestURL);
            GeoCodeRequest.setTimeout(120000);
            
            HttpResponse GeoCodeResponse = GeoCodeHttp.send(GeoCodeRequest);
            
            // Send the current data to the parse method with the response body
            // This is so it can update the wrapper class instance with the parsed data
            CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, GeoCodeResponse.getBody());
            
        } else {
            CurrentGeoCodeResult.Status = 'BLANK_ADDRESS';
        } // FormattedAddress.length() > 0
        
        CurrentGeoCodeResult.TimeStamp = System.now();
        
        return CurrentGeoCodeResult;
    } // GeoCodeAddress

    private static GeoCodeResult ParseGeoCodeJSONReponse(GeoCodeResult IncomingGeoCodeResult, String ResponseBody) {
 
        GeoCodeResult ReturnGeoCodeResult = IncomingGeoCodeResult;
          
        JSONParser parser = JSON.createParser(ResponseBody);
        
        String StatusResult = '';
         
        system.debug('ResponseBody = ' + ResponseBody);

         while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                (parser.getText() == 'statusDescription')) {
                    parser.nextToken();
                    StatusResult = parser.getText();
                    system.debug('Status was: ' + StatusResult);
                    ReturnGeoCodeResult.Status = StatusResult;
                    break;
            } // if status          
         }  // loop thru looking for Status
          
        if (StatusResult == 'OK') {
            // parse the results from the start again
            parser = JSON.createParser(ResponseBody);
            while (parser.nextToken() != null) {
                                                                                 
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                (parser.getText() == 'coordinates')) {
                                
                                // skip to the [
                                parser.nextToken();
                                
                                // now get the first value
                                parser.nextToken(); 
                                ReturnGeoCodeResult.Latitude = parser.getDoubleValue();                          
                                system.debug('Found Latitude: ' + ReturnGeoCodeResult.Latitude);                                    
    
                                // now get the 2nd value
                                parser.nextToken();                                                                                                                  
                                ReturnGeoCodeResult.Longitude = parser.getDoubleValue();
                                system.debug('Found Longitude: ' + ReturnGeoCodeResult.Longitude);                                  
                                 
                            } // if point    
                                         
                } // while (parser.nextToken() != null)
            } // if (ReturnGeoCodeResult.Status == 'OK') {         
        return ReturnGeoCodeResult;
          
    } // ParseGeoCodeJSONReponse        


    // this method builds the string for use in the URL
    private static string BuildAddressString(String Street, String City, String State, String PostalCode, String Country) {
    
        // Example String: /US/WA/98052/Redmond/1%20Microsoft%20Way
    
        // Note that 1+Microsoft+Way is techinically in the UTF-8 spec the same as above
        // however, Microsoft doesn't follow that and must have %20 so we can't use urlEncode function
    
        String Address = '';

        if(Country != null) {
           Country = Country.Replace(' ', '%20');
           Address += '/' + Country;         
        } // Country
         
        if(State != null) {
           State = State.Replace(' ', '%20');
           Address += '/' + State;         
        } // State
         
        if(PostalCode != null) {
           PostalCode = PostalCode.Replace(' ', '%20');
           Address += '/' + PostalCode;                  
        } // Postal Code
         
        if(City != null) {
           City = City.Replace(' ', '%20');
           Address += '/' + City;                           
        } // City
                  
        if(Street != null) {
           // Bing has some issues:
           //     1. It wants %20 instead of spaces
           //     2. It won't geocode PO Boxes to the city - so remove them
           //     3. It doesn't like the # symbol in the address so remove them
           //     4. It won't process an address than ends in a period
           
           Street = Street.Replace(' ', '%20');
           	           
           Street = Street.toUpperCase();
           Street = Street.Replace('P.O. BOX', '');
           
           Street = Street.Replace('#', '');
           
           // Bing has problems with addresses that end in periods, so just remove them
           if (Street.EndsWith('.') == true ) {
           		Street = Street.RemoveEnd('.');
           }
           Address += '/' + Street;                           
        } // Street
        
        // remove any line breaks
        Address = Address.replace('\n',' ');
        Address = Address.replace('\r',' ');
		 
        return Address;

    } // BuildAddressString    
        
} // BingGeoCodeUpdater