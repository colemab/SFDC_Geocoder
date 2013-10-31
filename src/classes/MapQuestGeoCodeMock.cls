global class MapQuestGeoCodeMock implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        
        String GeoCodeResponse = '';
        System.Httpresponse ReturnValue = new System.Httpresponse();
        
        system.debug('Request = ' + req.getEndpoint());
        
        // only give responses to the chicago and auburn test addresses
        if (req.getEndpoint().contains('Chicago') == true) {

            if (req.getEndpoint().contains('mapquestapi.com') == true) {
                GeoCodeResponse = '{"results":[{"locations":[{"latLng":{"lng":-87.674375,"lat":41.881334},"adminArea4":"Cook County","adminArea5Type":"City","adminArea4Type":"County","adminArea5":"Chicago","street":"1901 W Madison St","adminArea1":"US","adminArea3":"IL","type":"s","displayLatLng":{"lng":-87.67424,"lat":41.881329},"linkId":858678060,"postalCode":"60612-2459","sideOfStreet":"R","dragPoint":false,"adminArea1Type":"Country","geocodeQuality":"ADDRESS","geocodeQualityCode":"L1AAA","adminArea3Type":"State"}],"providedLocation":{"location":"1901 W. Madison St., Chicago, IL, 60612, US, "}}],"options":{"ignoreLatLngInput":true,"maxResults":1,"thumbMaps":false},"info":{"copyright":{"text":"© 2013 MapQuest, Inc.","imageUrl":"http://api.mqcdn.com/res/mqlogo.gif","imageAltText":"© 2013 MapQuest, Inc."},"statuscode":0,"messages":[]}}';
            }
            
        } else if (req.getEndpoint().contains('Auburn') == true) {
        
            if (req.getEndpoint().contains('mapquestapi.com') == true) {
                GeoCodeResponse = '{"results":[{"locations":[{"latLng":{"lng":-85.490415,"lat":32.603257},"adminArea4":"Lee County","adminArea5Type":"City","adminArea4Type":"County","adminArea5":"Auburn","street":"251 S Donahue Dr","adminArea1":"US","adminArea3":"AL","type":"s","displayLatLng":{"lng":-85.490417,"lat":32.603389},"linkId":759271923,"postalCode":"36849","sideOfStreet":"R","dragPoint":false,"adminArea1Type":"Country","geocodeQuality":"ADDRESS","geocodeQualityCode":"L1AAC","adminArea3Type":"State"}],"providedLocation":{"location":"251 South Donahue Drive, Auburn, AL, 35244, US, "}}],"options":{"ignoreLatLngInput":true,"maxResults":1,"thumbMaps":false},"info":{"copyright":{"text":"© 2013 MapQuest, Inc.","imageUrl":"http://api.mqcdn.com/res/mqlogo.gif","imageAltText":"© 2013 MapQuest, Inc."},"statuscode":0,"messages":[]}}';
            }                       
        } 
        

        ReturnValue.setBody(GeoCodeResponse);
        
        return ReturnValue;
        
    } // HTTPResponse
    
} // MapQuestGeoCodeMock