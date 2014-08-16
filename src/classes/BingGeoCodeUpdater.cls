public with sharing class BingGeoCodeUpdater implements GeoCodeService{ 

	public class BingJSONPoint { 
		string[] coordinates;
		string type;
	} // BingJSONPoint
	
	public class BingJSONResource {

		string name;
		BingJSONPoint point;

		string confidence;
        string entityType;
		
	} // BingJSONResource
	
	public class BingJSONResourceSets {
		string estimatedTotal;
		BingJSONResource[] resources;
	} // BingJSONResourceSets
	
	public class BingJSONResponse {
		string authenticationResultCode;
		string brandLogoUri;
		string copyright;
		BingJSONResourceSets[] resourceSets;
		string statusCode;
		string statusDescription;
		string traceId;

		public BingJSONResponse(string A, string B, string C, BingJSONResourceSets[] RS, string SC, string SD, string T) {
			authenticationResultCode = A;
			brandLogoUri = B;
			copyright = C;
			resourceSets = RS;
			statusCode = SC;
			statusDescription = SD;
			traceId = T;			
		} // init

	} // BingJSONResponse

	public class BingJSONResponseStatus {
		string statusCode;
		string statusDescription;		
	} // BingJSONResponseStatus
	
    public string getAPIKey() {
        string ReturnValue = '';
        
        DC_GG__GeoCodeSettings__c BingAPIKey = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (BingAPIKey !=null && BingAPIKey.DC_GG__BingMapsKey__c != null) ReturnValue = BingAPIKey.DC_GG__BingMapsKey__c;
        
        return ReturnValue;
    } // getAPIKey

    public GeoCodeResult GeoCodeAddress(String StreetAddress, String City, String State, String PostalCode, String Country) 
    {
        GeoCodeResult CurrentGeoCodeResult = new GeoCodeResult();
        CurrentGeoCodeResult.Engine = 'Bing';
        
        // format the string for the Bing Maps engine
        String FormattedAddress = BuildAddressString(StreetAddress, City, State, PostalCode, Country);
        
        String key = getAPIKey();

        if (key == '') {
            CurrentGeoCodeResult.Status = 'NO_API_KEY';
        } else if (!String.isBlank(FormattedAddress)) {
            
            try {
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
	
				BingJSONResponseStatus ResponseStatus = (BingJSONResponseStatus) JSON.deserialize(GeoCodeResponse.getBody(), BingJSONResponseStatus.class);
	            system.debug('Status = ' + ResponseStatus.statusCode);
	            system.debug('StatusDescription = ' + ResponseStatus.statusDescription);
				
				CurrentGeoCodeResult.Status = ResponseStatus.statusDescription;
				
				if (ResponseStatus.statusDescription == 'OK') {
					// Transform the response into our custom classes . . .
					BingJSONResponse Response = (BingJSONResponse) JSON.deserialize(GeoCodeResponse.getBody(), BingJSONResponse.class);
	            
		            // Send the current data to the parse method with the response body
		            // This is so it can update the wrapper class instance with the parsed data
		            //CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, GeoCodeResponse.getBody());
		              CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, Response);
				}
				
			} catch (Exception e) {
							
				CurrentGeoCodeResult.Status = 'APEX_EXCEPTION';
	
				String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
				CurrentGeoCodeResult.TraceMessage = ExceptionDetails;
	
				CurrentGeoCodeResult.TimeStamp = System.now();			 
				return CurrentGeoCodeResult;
						 
			} // try & catch on update - just in case we hit any JSON parsing errors
            
        } else {
            CurrentGeoCodeResult.Status = 'BLANK_ADDRESS';
        } // FormattedAddress.length() > 0
        
        CurrentGeoCodeResult.TimeStamp = System.now();
        
        return CurrentGeoCodeResult;
    } // GeoCodeAddress

    private static GeoCodeResult ParseGeoCodeJSONReponse(GeoCodeResult IncomingGeoCodeResult, BingJSONResponse R) {
          
        GeoCodeResult ReturnGeoCodeResult = IncomingGeoCodeResult;
        system.debug('resourceSets.size = ' + R.resourceSets.size());

 		for (BingJSONResourceSets RS : R.resourceSets) {
 			system.debug('RS.estimatedTotal = ' + RS.estimatedTotal);
 			
 			for (BingJSONResource Rec : RS.resources) {

				system.debug('Rec.name = ' + Rec.name);
		
				system.debug('Coordinates.size =' + Rec.point.coordinates.size());

				if (Rec.point.coordinates.size() == 2) {
					
					ReturnGeoCodeResult.Quality = Rec.confidence;

					ReturnGeoCodeResult.Latitude = Double.valueOf(Rec.point.coordinates.get(0));
					system.debug('Found Latitude: ' + ReturnGeoCodeResult.Latitude);
					
					ReturnGeoCodeResult.Longitude = Double.valueOf(Rec.point.coordinates.get(1));
					system.debug('Found Longitude: ' + ReturnGeoCodeResult.Longitude);
					
					break;
				} // sanity check for coords size
         		
         		if (ReturnGeoCodeResult.Latitude != null) {
         			break;
         		} // only take the top result
         				
 			} // loop thru resources
 			
 		} // loop thru resourceSets

        return ReturnGeoCodeResult;
 		
    } // GeoCodeResult


    // this method builds the string for use in the URL
    private static string BuildAddressString(String Street, String City, String State, String PostalCode, String Country) {
    
        // Example String: /US/WA/98052/Redmond/1%20Microsoft%20Way
    
        // Note that 1+Microsoft+Way is techinically in the UTF-8 spec the same as above
        // however, Microsoft doesn't follow that and must have %20 so we can't use urlEncode function
    
        String Address = '';

        // if no country, assume US.  This is for Bing Maps bug.
        if (String.isBlank(Country) == true) Country = 'US';

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