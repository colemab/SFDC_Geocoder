public with sharing class MapQuestGeoCodeUpdater implements GeoCodeService{

	// Copyright info from map quest
	public class MapQuestJSONCopyright {
		string text;
		string imageUrl;
		string imageAltText;
		public MapQuestJSONCopyright(string T, string U, string A) {
			text = T;
			imageUrl = U;
			imageAltText = A;
		} // init
	} // MapQuestJSONCopyright
	
	// info from MapQuest - for JSON deserialization
	public class MapQuestJSONInfo {
		string statuscode;
		MapQuestJSONCopyright copyright;
		string[] messages;
		public MapQuestJSONInfo(string S, MapQuestJSONCopyright C, string[] M) {
			statuscode = S;
			copyright = C;
			messages = M;
		} // init
	} // MapQuestJSONInfo

	// options from MapQuest - for JSON deserialization
	public class MapQuestJSONOptions {
		string maxResults;
		string thumbMaps;
		string ignoreLatLngInput;
		
		public MapQuestJSONOptions(string M, string T, string I) {
			maxResults = M;
			thumbMaps = T;
			ignoreLatLngInput = I;
		} // init
	} // MapQuestJSONOptions

	// inner class for JSON deserialization
	public class MapQuestJSONLatLng {
		string lat;
		string lng;
		
		public MapQuestJSONLatLng(string La, string Ln) {
			lat = La;
			lng = Ln;
		} // init
		
	} // MapQuestJSONLatLng

	public class MapQuestJSONLocations {		
			string street;
			string adminArea6;
			string adminArea6Type; // usually Neighborhood
			string adminArea5;
			string adminArea5Type; // usually City
			string adminArea4;
			string adminArea4Type; // usually County
			string adminArea3;
			string adminArea3Type; // usually State
			string adminArea1;
			string adminArea1Type; // usually Country
			string postalCode;
			string geocodeQualityCode;
			string geocodeQuality;
			string dragPoint;
			string sideOfStreet;
			string linkId;
			string unknownInput;
			string type;
			
			MapQuestJSONLatLng latLng;
	} // MapQuestJSONLocations
	
	// individual results from MapQuest - for JSON deserialization
	public class MapQuestJSONResult {
		MapQuestJSONLocations[] locations;
		
		public MapQuestJSONResult(MapQuestJSONLocations[] L) {
			locations = L;
		} // init
	} // MapQuestJSONResult
	
	// main class used for JSON deserialization
	public class MapQuestJSONResponse {
		// http://www.mapquestapi.com/geocoding/#response
		MapQuestJSONInfo info;
		MapQuestJSONOptions options;
		MapQuestJSONResult[] results;
		
		public MapQuestJSONResponse(MapQuestJSONInfo I, MapQuestJSONOptions O, MapQuestJSONResult[] R) {
			info = I;
			options = O;
			results = R;
		} // init
	} // MapQuestJSONResponse
    
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

			// Transform the response into our custom classes . . .
			MapQuestJSONResponse Response = (MapQuestJSONResponse) JSON.deserialize(GeoCodeResponse.getBody(), MapQuestJSONResponse.class);
                        
            // Send the current data to the parse method with the response body
            // This is so it can update the wrapper class instance with the parsed data
            CurrentGeoCodeResult = ParseGeoCodeJSONReponse(CurrentGeoCodeResult, Response);
            
        } else {
            CurrentGeoCodeResult.Status = 'BLANK_ADDRESS';
        } // FormattedAddress.length() > 0
        
        CurrentGeoCodeResult.TimeStamp = System.now();
        
        return CurrentGeoCodeResult;
    } // GeoCodeAddress

    private static GeoCodeResult ParseGeoCodeJSONReponse(GeoCodeResult IncomingGeoCodeResult, MapQuestJSONResponse Response) {
 
        GeoCodeResult ReturnGeoCodeResult = IncomingGeoCodeResult;
          
        String StatusResult = '';
         
        system.debug('Status Code =  ' + Response.Info.statuscode );
        system.debug('Results size = ' + Response.results.size());

		// mapquest passes a Zero when everything went fine - map to OK
		if (Response.Info.statuscode == '0') {
      	
  	 	  	ReturnGeoCodeResult.Status = 'OK';
  	 	  	  
        	if (Response.results.size() > 0) {
            		if (Response.results[0].locations.size() > 0) {

            			system.debug('Lat = ' + Response.results[0].locations[0].latLng.lat);
            			system.debug('Lng = ' + Response.results[0].locations[0].latLng.lng);
						ReturnGeoCodeResult.Latitude = Double.valueOf(Response.results[0].locations[0].latLng.lat);                          	                                																										
						ReturnGeoCodeResult.Longitude = Double.valueOf(Response.results[0].locations[0].latLng.lng);

            		} // check for locations
        	} // check for results
		} else {
			ReturnGeoCodeResult.Status = Response.Info.statuscode;	
	 	} // check for status code
		                                                                             
			// Lat 39.390897  and Long -99.066067
			// are default values for the middle of the country - ignore these!
			if (ReturnGeoCodeResult.Latitude == 39.390897 &&
				ReturnGeoCodeResult.Longitude == -99.066067) {
				system.debug('MapQuest returned default US value - IGNORING!'); 
            	ReturnGeoCodeResult.Longitude = 0;
            	ReturnGeoCodeResult.Latitude = 0;
            } // check for bad results
                     
        return ReturnGeoCodeResult;
          
    } // ParseGeoCodeJSONReponse        


    // this method builds the string for use in the URL
    public static string BuildAddressString(String Street, String City, String State, String PostalCode, String Country) {
        String Address = '';
	
        if(Street != null) {
            Address = EncodingUtil.urlEncode(Street,'UTF-8')+ ',+';
        } // Street != null
        
        if(City != null && State != null) {
            Address = Address + EncodingUtil.urlEncode(City,'UTF-8')+ ',+' +
                      EncodingUtil.urlEncode(State,'UTF-8');
        } else if(City != null) {
			Address = Address + EncodingUtil.urlEncode(City,'UTF-8');
		} else if(State != null) {		        		
            Address = Address + EncodingUtil.urlEncode(State,'UTF-8');        
        } // City != null &&  State != null
        
        if(PostalCode != null) {
            Address = Address  + ',+' + EncodingUtil.urlEncode(PostalCode,'UTF-8');
        } // zip ! = null

        if(Country != null) {
            Address = Address  + ',+' + EncodingUtil.urlEncode(Country,'UTF-8')+ ',+';
        } // Country != null
	    
	    system.debug('BuildAddressString: ' + Address);
	        		                
        return Address;
        
    } // BuildAddressString     
    
} // MapQuestGeoCodeUpdater