global class GoogleGeoCodeMock implements HttpCalloutMock {

	global HTTPResponse respond(HTTPRequest req) {
		
		String GeoCodeResponse = '';
		System.Httpresponse ReturnValue = new System.Httpresponse();
		
		system.debug('Request = ' + req.getEndpoint());
		
		// only give responses to the chicago and auburn test addresses
		if (req.getEndpoint().contains('Chicago') == true) {

			if (req.getEndpoint().contains('maps.googleapis.com') == true) {
				// Google Maps response (hard coded)
				GeoCodeResponse = '{   "results" : [      {         "address_components" : [            {               "long_name" : "1901",               "short_name" : "1901",               "types" : [ "street_number" ]            },            {               "long_name" : "West Madison Street",               "short_name" : "W Madison St",               "types" : [ "route" ]            },            {               "long_name" : "Near West Side",               "short_name" : "Near West Side",               "types" : [ "neighborhood", "political" ]            },            {               "long_name" : "Chicago",               "short_name" : "Chicago",               "types" : [ "locality", "political" ]            },            {               "long_name" : "Chicago",               "short_name" : "Chicago",               "types" : [ "administrative_area_level_3", "political" ]            },            {               "long_name" : "Cook",               "short_name" : "Cook",               "types" : [ "administrative_area_level_2", "political" ]            },            {               "long_name" : "Illinois",               "short_name" : "IL",               "types" : [ "administrative_area_level_1", "political" ]            },            {               "long_name" : "United States",               "short_name" : "US",               "types" : [ "country", "political" ]            },            {               "long_name" : "60612",               "short_name" : "60612",               "types" : [ "postal_code" ]            }         ],         "formatted_address" : "1901 West Madison Street, Chicago, IL 60612, USA",         "geometry" : {            "location" : {               "lat" : 41.8806240,               "lng" : -87.67476099999999            },            "location_type" : "ROOFTOP",            "viewport" : {               "northeast" : {                  "lat" : 41.88197298029149,                  "lng" : -87.67341201970848               },               "southwest" : {                  "lat" : 41.87927501970849,                  "lng" : -87.67610998029150               }            }         },         "types" : [ "street_address" ]      }   ],   "status" : "OK"}';
			}
		} else if (req.getEndpoint().contains('Auburn') == true) {
			if (req.getEndpoint().contains('maps.googleapis.com') == true) {
				// Google Maps response (hard coded)
				GeoCodeResponse = '{   "results" : [      {         "address_components" : [            {               "long_name" : "251",               "short_name" : "251",               "types" : [ "street_number" ]            },            {               "long_name" : "North Donahue Drive",               "short_name" : "N Donahue Dr",               "types" : [ "route" ]            },            {               "long_name" : "Auburn",               "short_name" : "Auburn",               "types" : [ "locality", "political" ]            },            {               "long_name" : "Lee",               "short_name" : "Lee",               "types" : [ "administrative_area_level_2", "political" ]            },            {               "long_name" : "Alabama",               "short_name" : "AL",               "types" : [ "administrative_area_level_1", "political" ]            },            {               "long_name" : "United States",               "short_name" : "US",               "types" : [ "country", "political" ]            },            {               "long_name" : "36832",               "short_name" : "36832",               "types" : [ "postal_code" ]            }         ],         "formatted_address" : "251 North Donahue Drive, Auburn, AL 36832, USA",         "geometry" : {            "bounds" : {               "northeast" : {                  "lat" : 32.60943990,                  "lng" : -85.49036289999999               },               "southwest" : {                  "lat" : 32.60943870,                  "lng" : -85.49038130               }            },            "location" : {               "lat" : 32.60943870,               "lng" : -85.49038130            },            "location_type" : "RANGE_INTERPOLATED",            "viewport" : {               "northeast" : {                  "lat" : 32.61078828029149,                  "lng" : -85.48902311970849               },               "southwest" : {                  "lat" : 32.60809031970850,                  "lng" : -85.49172108029150               }            }         },         "partial_match" : true,         "types" : [ "street_address" ]      }   ],   "status" : "OK"}';
			}			
		} 
		
		ReturnValue.setBody(GeoCodeResponse);
		
		return ReturnValue;
		
	} // HTTPResponse
	
} // GoogleGeoCodeMock