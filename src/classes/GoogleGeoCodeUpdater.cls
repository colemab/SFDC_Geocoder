public with sharing class GoogleGeoCodeUpdater implements GeoCodeService{ 
    	     
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
         
    public GeoCodeResult GeoCodeAddress(String StreetAddress, String City, String State, String PostalCode, String Country)
    {
        
      	GeoCodeResult CurrentGeoCodeResult = new GeoCodeResult();
      	
		String GeoCodeRequestURL = '';
		String AddressRequestURL = '';
        
        AddressRequestURL = BuildAddressString(StreetAddress, City, State, PostalCode, Country);
        
		if (!String.isBlank(AddressRequestURL)) {
	          
			HttpRequest GeoCodeRequest = new HttpRequest();
	        Http GeoCodeHttp = new Http();
	           
	        GeoCodeRequest.setMethod('GET');
	           
	        GeoCodeRequestURL = 'http://maps.googleapis.com/maps/api/geocode/json?address='+ AddressRequestURL + '&sensor=false';	          
			system.debug('Request URL was: ' + GeoCodeRequestURL);
			CurrentGeoCodeResult.RequestURL = GeoCodeRequestURL;
			      				
			GeoCodeRequest.setEndpoint(GeoCodeRequestURL);
   			GeoCodeRequest.setTimeout(120000);
   			
			HttpResponse GeoCodeResponse = GeoCodeHttp.send(GeoCodeRequest);
			CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, GeoCodeResponse.getBody()); 
		
		} else {
			CurrentGeoCodeResult.Status = 'BLANK_ADDRESS';   			          
     	} // if (AddressRequestURL != '') {   
		
		CurrentGeoCodeResult.TimeStamp = System.now();
		
		return CurrentGeoCodeResult;
 	} // GeocodeAddress
     
    private static GeoCodeResult ParseGeoCodeJSONReponse(GeoCodeResult IncomingGeoCodeResult, String ResponseBody) {
          
         GeoCodeResult ReturnGeoCodeResult = IncomingGeoCodeResult;
          
         JSONParser parser = JSON.createParser(ResponseBody);
         
         system.debug('ResponseBody = ' + ResponseBody);
          
         while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                (parser.getText() == 'Status')) {
                	parser.nextToken();
                	system.debug('Status was: ' + parser.getText());
					ReturnGeoCodeResult.Status = parser.getText();
					break;
			} // if status         	
         }  // loop thru looking for Status
         
         if (ReturnGeoCodeResult.Status == 'OK') {
	         while (parser.nextToken() != null) {                                                                             
	                        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
	                            (parser.getText() == 'location')) {
	                             								
								while (parser.nextToken() != JSONToken.END_OBJECT){
									String CurrentTextValue = parser.getText();
									parser.nextToken();	
									
									if (CurrentTextValue == 'lng') {
			                            ReturnGeoCodeResult.Longitude = parser.getDoubleValue();
			                            system.debug('Found Longitude: ' + ReturnGeoCodeResult.Longitude);									
									} else if (CurrentTextValue == 'lat') {
			                            ReturnGeoCodeResult.Latitude = parser.getDoubleValue();                          
			                            system.debug('Found Latitude: ' + ReturnGeoCodeResult.Latitude);
									} else {
										system.debug('CurrentTextValue = ' + CurrentTextValue);									
									} // search for long / lat markers
								} // while (parser.nextToken() != JSONToken.END_OBJECT){
	                        } // look for location   	                                     
	            } // while (parser.nextToken() != null)
         } // Status = ok         
         
        return ReturnGeoCodeResult;
          
    } // GeoCodeResult
     
} // end GoogleGeoCodeUpdater class