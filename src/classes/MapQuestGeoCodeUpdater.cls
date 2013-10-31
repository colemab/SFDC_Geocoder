public with sharing class MapQuestGeoCodeUpdater implements GeoCodeService{
    
    public string getAPIKey() {
        string ReturnValue = '';
        
        DC_GG__GeoCodeSettings__c MQAPIKey = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (MQAPIKey !=null && MQAPIKey.DC_GG__MapQuestKey__c != null) ReturnValue = MQAPIKey.DC_GG__MapQuestKey__c;
        
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
            
            string GeoCodeRequestURL = 'http://www.mapquestapi.com/geocoding/v1/address?key=' + key + '&location=' + FormattedAddress + '&inFormat=kvp&maxResults=1&outFormat=json&thumbMaps=false&ignoreLatLngInput=true';
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
                (parser.getText() == 'statuscode')) {
                    parser.nextToken();
                    StatusResult = parser.getText();
                    system.debug('Status was: ' + StatusResult);
                    // mapquest passes a Zero when everything went fine - map to OK
                    if (StatusResult == '0') StatusResult = 'OK';
                    ReturnGeoCodeResult.Status = StatusResult;
                    break;
            } // if status          
         }  // loop thru looking for Status
          
        if (StatusResult == 'OK') {
            
            // parse the results from the start again
            parser = JSON.createParser(ResponseBody);
            
            while (parser.nextToken() != null) {
                                                                                 
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                                (parser.getText() == 'displayLatLng')) {
                                
                                // skip the {
                                parser.nextToken();                             
                                
                                // look for the lng tag
                                parser.nextToken();
                                
                                if (parser.getText() == 'lng') {
                                    parser.nextToken();                                 
                                    ReturnGeoCodeResult.Longitude = parser.getDoubleValue();
                                    system.debug('Found Longitude: ' + ReturnGeoCodeResult.Longitude);

                                    parser.nextToken();

                                    if (parser.getText() == 'lat') {
                                        parser.nextToken(); 
                                        ReturnGeoCodeResult.Latitude = parser.getDoubleValue();                          
                                        system.debug('Found Latitude: ' + ReturnGeoCodeResult.Latitude);
                                        break;                                    
                                    } // lat
                                    
                                } // lng                                  
                                
                                     
                            } // if point    
                                         
                } // while (parser.nextToken() != null)
            } // if (ReturnGeoCodeResult.Status == 'OK') {         
        return ReturnGeoCodeResult;
          
    } // ParseGeoCodeJSONReponse        


    // this method builds the string for use in the URL
    private static string BuildAddressString(String Street, String City, String State, String PostalCode, String Country) {
        String Address = '';
	
        if(Street != null) {
            Address = EncodingUtil.urlEncode(Street,'UTF-8')+ ',+';
        } // Street != null
        
        if(City != null && State != null) {
            Address = Address + EncodingUtil.urlEncode(City,'UTF-8')+ ',+' +
                      EncodingUtil.urlEncode(State,'UTF-8');
        } // City != null &&  State != null
        if(PostalCode != null) {
            Address = Address  + ',+' + EncodingUtil.urlEncode(PostalCode,'UTF-8');
        } // zip ! = null

        if(Country != null) {
            Address = Address  + ',+' + EncodingUtil.urlEncode(Country,'UTF-8')+ ',+';
        } // Country != null
	        		                
        return Address;
        
    } // BuildAddressString     
    
} // MapQuestGeoCodeUpdater