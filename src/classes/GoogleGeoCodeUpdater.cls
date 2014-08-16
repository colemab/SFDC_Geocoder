public with sharing class GoogleGeoCodeUpdater implements GeoCodeService{ 

	// inner class for JSON deserialization
	public class GoogleJSONLatLng {
		string lat;
		string lng;
		
		public GoogleJSONLatLng(string La, string Ln) {
			lat = La;
			lng = Ln;
		} // init
		
	} // GoogleJSONLatLng
	
	// inner class for JSON deserialization
	public class GoogleJSONgeometry {
		GoogleJSONLatLng location; // the geocoded lat/long value
		/*
		location_type:
		google.maps.GeocoderLocationType.ROOFTOP indicates that the returned result reflects a precise geocode.
		google.maps.GeocoderLocationType.RANGE_INTERPOLATED indicates that the returned result reflects an approximation (usually on a road) interpolated between two precise points (such as intersections). Interpolated results are generally returned when rooftop geocodes are unavailable for a street address.
		google.maps.GeocoderLocationType.GEOMETRIC_CENTER indicates that the returned result is the geometric center of a result such as a polyline (for example, a street) or polygon (region).
		google.maps.GeocoderLocationType.APPROXIMATE indicates that the returned result is approximate
		*/
		string location_type;
	} // GoogleJSONgeometry

	// inner class for JSON deserialization
	public class GoogleJSONAddressComponents {
		string short_name;
   		string long_name;
   		string[] postcode_localities;
   		string[] types;		 
   		
   		public GoogleJSONAddressComponents(string sname, string lname, string[] p_localities, string[] t) {
   				short_name = sname;
   				long_name = lname;
   				postcode_localities = p_localities;
   				types = t;
   		} // init
   		
	} // GoogleJSONAddressComponents

	// individual results from google - for JSON deserialization
	public class GoogleJSONResult {
		
		/*
		types[] is an array indicating the type of the returned result. 
		This array contains a set of zero or more tags identifying the type of feature returned in the result. 
		For example, a geocode of "Chicago" returns "locality" which indicates that "Chicago" is a city,
		and also returns "political" which indicates it is a political entity. */
		String[] Types;
		
		/*
		Formatted_address is a string containing the human-readable address of this location. 
		Often this address is equivalent to the "postal address," which sometimes differs from country to country.
		*/
		String Formatted_address;
		
		// address_components[] is an array containing the separate address components, as explained above.
		GoogleJSONAddressComponents[] address_components;
		
		/*
		Partial matches most often occur when the requested street address does not exist in the specific locality.
		Partial matches may also be returned when a request matches two or more locations in the same locality. 
		For example, "21 Henr St, Bristol, UK" will return a partial match for both Henry Street and 
		Henrietta Street. Note that if a request includes a misspelled address component, the geocoding 
		service may suggest an alternate address. Suggestions triggered in this way will not be marked as a 
		partial match. 		
		*/
		boolean partial_match;
		
		GoogleJSONgeometry geometry;
		
		public GoogleJSONResult(String[] T, String F_address, GoogleJSONAddressComponents[] a_components, boolean match, GoogleJSONgeometry g) {
			Types = T;
			Formatted_address = F_address;
			address_components = a_components;
			partial_match = match;
			geometry = g;
		} // init
		
	} // GoogleJSONResult

	// main class used for JSON deserialization
	public class GoogleJSONResponse {
				
		GoogleJSONResult[] Results;
		String Status;
				
		public GoogleJSONResponse(GoogleJSONResult[] R, String S) {
			
			Status = S;
			Results = R;
					
		} // init
		
	} // GoogleJSONResponse
	
	// place holder class to get just the status
	public class GoogleJSONResponseStatus {
		String Status;
	} // GoogleJSONResponseStatus
	
    public string getAPIKey() {
        string ReturnValue = '';
        
        DC_GG__GeoCodeSettings__c GoogleAPIKey = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (GoogleAPIKey !=null && GoogleAPIKey.DC_GG__GoogleKey__c != null) ReturnValue = GoogleAPIKey.DC_GG__GoogleKey__c;
        
        return ReturnValue;
    } // getAPIKey
    	     
    
    private static string FilterStreetAddress(String Street) {
        
        string returnValue = '';
        
        if(Street != '') {

        	// Google doesn't geocode PO Boxes well (i.e. shows them outside of the USA sometimes)
        	// so don't include them in the address string
        	string StreetUPPER = Street.toUpperCase();
        	StreetUPPER = StreetUPPER.replace('.', '');
        	system.debug('StreetUPPER = ' + StreetUPPER);

        	// remove line 2 data as it often confuses google
        	if (Street.contains('\n')) {
        		String[] StreetLines = Street.split('\n');
        		Street = StreetLines[0];
        		system.debug('Street is now one line: ' + Street);
        	} // check for mutiple lines        	

        	if (!StreetUPPER.contains('PO BOX') && !StreetUPPER.contains('P O BOX') && !StreetUPPER.contains('BOX ')) {
            	system.debug('did not find PO Box!');
				returnValue = Street;
        	} // check for PO Box
        	
        } // Street != null
    	
    	return returnValue;
    	
    } // FilterStreetAddress
    	     
    private static string BuildAddressString(String Street, String City, String State, String PostalCode, String Country) {
    	String Address = '';

        if(Street != '') {
            Address = EncodingUtil.urlEncode(Street,'UTF-8')+ ',+';        	
        } // Street != ''
        
        if(City != null && State != null) {
            Address = Address + EncodingUtil.urlEncode(City,'UTF-8')+ ',+' +
                      EncodingUtil.urlEncode(State,'UTF-8');
        } // City != null &&  State != null
        if(PostalCode != null) {
        	
        	// Google doesn't do well with 9 digit postal codes that don't have a dash
        	// it tries to interpret them as zip codes for non US areas (i.e. Spain)        	
			if (PostalCode.length() >5 ) {
					string Left5 = PostalCode.substring(0,5);
					string Rest = PostalCode.substring(5, PostalCode.length());

					// put the dash back in - if it is missing
					if (!Rest.startswith('-')) {
						Rest = '-' + Rest;
					}
					// If the +4 (with a dash) isn't 5 chars then discard it
					if (Rest.length() != 5) {
						Rest = '';
					}
					PostalCode = Left5 + Rest;
			} // check for zip over 5
			
			system.debug('PostalCode = ' + PostalCode);			        	        	
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
      	CurrentGeoCodeResult.Engine = 'Google';
      	
		String GeoCodeRequestURL = '';
		String AddressRequestURL = '';
        
        StreetAddress = FilterStreetAddress(StreetAddress);
                	
        AddressRequestURL = BuildAddressString(StreetAddress, City, State, PostalCode, Country);

        String key = getAPIKey();

        if (key == '') {
            CurrentGeoCodeResult.Status = 'NO_API_KEY';	        
        } else if (!String.isBlank(AddressRequestURL)) {
	          
			HttpRequest GeoCodeRequest = new HttpRequest();
	        Http GeoCodeHttp = new Http();
	           
	        GeoCodeRequest.setMethod('GET');
	        
	        try {
		        /*
		        	07/18/2014 - Added component filtering
		        	https://developers.google.com/maps/documentation/geocoding/#ComponentFiltering
		        */   
		        
		        GeoCodeRequestURL = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + AddressRequestURL;	          
				
				list<String> ComponentFilterURL = new list<string>(); 
				string FinalComponentFilterURL = '';		
				
				// only use the postal code with a street address - otherwise city / state works better	
				// for some reason people w/o street addresses are more likely to have typo in zip code 		
				if (StreetAddress != '' && PostalCode != '') {
					// use the left 5 of the postal code when populated
					// zip codes are less likely to have typo's than city names				
					ComponentFilterURL.add('postal_code:' + PostalCode.substring(0,5));
				} else if (City != '') {
					// otherwise use the city name
					ComponentFilterURL.add('locality:' + City);
				} else if (State != '') {
					ComponentFilterURL.add('administrative_area:' + State);
				} // check for postal code / city
	
				if (Country != '') {
					ComponentFilterURL.add('country:' + Country);
				} // check for country
				
				if (ComponentFilterURL.size() > 0) {
					FinalComponentFilterURL = '&components=';
					for (String S : ComponentFilterURL) {
						FinalComponentFilterURL += EncodingUtil.urlEncode(S,'UTF-8') + '|';	
					} // loop thru ComponentFilterURL
					system.debug('FinalComponentFilterURL = ' + FinalComponentFilterURL);
					GeoCodeRequestURL += FinalComponentFilterURL;
				} // check for empty list						
				
				GeoCodeRequestURL += '&key=' + key;
				
				system.debug('Request URL was: ' + GeoCodeRequestURL);
				CurrentGeoCodeResult.RequestURL = GeoCodeRequestURL;
				      				
				GeoCodeRequest.setEndpoint(GeoCodeRequestURL);
	   			GeoCodeRequest.setTimeout(120000);
	   			
				HttpResponse GeoCodeResponse = GeoCodeHttp.send(GeoCodeRequest);
				
				GoogleJSONResponseStatus ReponseStatus = (GoogleJSONResponseStatus) JSON.deserialize(GeoCodeResponse.getBody(), GoogleJSONResponseStatus.class);
				system.debug('ReponseStatus  = ' + ReponseStatus.Status);  
				CurrentGeoCodeResult.Status = ReponseStatus.Status;
				
				if (ReponseStatus.Status == 'OK') {
					
					// Transform the response into our custom classes . . .
					GoogleJSONResponse Response = (GoogleJSONResponse) JSON.deserialize(GeoCodeResponse.getBody(), GoogleJSONResponse.class);
					
					// Now process the data in those custom classes . . . 
					CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, Response);
													
				} // if (ReponseStatus.Status == 'OK') {
			} catch (Exception e) {
							
				CurrentGeoCodeResult.Status = 'APEX_EXCEPTION';
	
				String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
				CurrentGeoCodeResult.TraceMessage = ExceptionDetails;
	
				CurrentGeoCodeResult.TimeStamp = System.now();			 
				return CurrentGeoCodeResult;
						 
			} // try & catch on update - just in case we hit any JSON parsing errors
			
		} else {
			CurrentGeoCodeResult.Status = 'BLANK_ADDRESS';   			          
     	} // if (AddressRequestURL != '') {   
        		
		CurrentGeoCodeResult.TimeStamp = System.now();
		
		return CurrentGeoCodeResult;
 	} // GeocodeAddress
     
    private static GeoCodeResult ParseGeoCodeJSONReponse(GeoCodeResult IncomingGeoCodeResult, GoogleJSONResponse R) {
          
        GeoCodeResult ReturnGeoCodeResult = IncomingGeoCodeResult;
                   
 		system.debug('Results.size = ' + R.Results.size());
 	
 		for (GoogleJSONResult Rec : R.Results) {			
 			system.debug('Formatted Address = ' + Rec.Formatted_address);
			// Since we are using filtered results, we will use the first entry we find
			if (ReturnGeoCodeResult.Longitude == null || ReturnGeoCodeResult.Latitude == null) {
				ReturnGeoCodeResult.Longitude = Double.valueOf(Rec.geometry.location.lng);
				system.debug('Found Longitude: ' + ReturnGeoCodeResult.Longitude);									
	 
				ReturnGeoCodeResult.Latitude = Double.valueOf(Rec.geometry.location.lat);                          
				system.debug('Found Latitude: ' + ReturnGeoCodeResult.Latitude);
				
				ReturnGeoCodeResult.Quality = Rec.geometry.location_type;
				
				break;
			} // check for long / lat         																			
 						         						         			
 		} // loop thru results         	
		        
        return ReturnGeoCodeResult;
          
    } // GeoCodeResult
     
} // end GoogleGeoCodeUpdater class