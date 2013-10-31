global class BingGeoCodeMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        
        String GeoCodeResponse = '';
        System.Httpresponse ReturnValue = new System.Httpresponse();
        
        system.debug('Request = ' + req.getEndpoint());
        
        // only give responses to the chicago and auburn test addresses
        if (req.getEndpoint().contains('Chicago') == true) {

            if (req.getEndpoint().contains('dev.virtualearth.net') == true) {
                GeoCodeResponse = '{"authenticationResultCode":"ValidCredentials","brandLogoUri":"dev.virtualearth.net","copyright":"Copyright Â© 2013 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.","resourceSets":[{"estimatedTotal":1,"resources":[{"__type":"Location:schemas.microsoft.com","bbox":[41.876760146198826,-87.681675929771572,41.884485581340179,-87.667841892494025],"name":"1901 W Madison St, Chicago, IL 60612","point":{"type":"Point","coordinates":[41.8806228637695,-87.6747589111328]},"address":{"addressLine":"1901 W Madison St","adminDistrict":"IL","adminDistrict2":"Cook Co.","countryRegion":"United States","formattedAddress":"1901 W Madison St, Chicago, IL 60612","locality":"Chicago","postalCode":"60612"},"confidence":"High","entityType":"Address","geocodePoints":[{"type":"Point","coordinates":[41.8806228637695,-87.6747589111328],"calculationMethod":"Parcel","usageTypes":["Display"]},{"type":"Point","coordinates":[41.8813285827637,-87.6747741699219],"calculationMethod":"Interpolation","usageTypes":["Route"]}],"matchCodes":["Good"]}]}],"statusCode":200,"statusDescription":"OK","traceId":"477354429021490a8d3a3ff30b60de91|CH1M001460|02.00.117.1500|CH1MSNVM001400, EWRIPEVM000249"}';
            }
        } else if (req.getEndpoint().contains('Auburn') == true) {
            if (req.getEndpoint().contains('dev.virtualearth.net') == true) {
                GeoCodeResponse = '{"authenticationResultCode":"ValidCredentials","brandLogoUri":"http:dev.virtualearth.netBrandinglogo_powered_by.png","copyright":"Copyright Â© 2013 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.","resourceSets":[{"estimatedTotal":1,"resources":[{"__type":"Location:http:schemas.microsoft.comsearchlocalwsrestv1","bbox":[32.591870925007449,-85.496324381620383,32.5995963601488,-85.48409859201243],"name":"S Donahue Dr, Auburn, AL 36832","point":{"type":"Point","coordinates":[32.595733642578125,-85.4902114868164]},"address":{"addressLine":"S Donahue Dr","adminDistrict":"AL","adminDistrict2":"Lee Co.","countryRegion":"United States","formattedAddress":"S Donahue Dr, Auburn, AL 36832","locality":"Auburn","postalCode":"36832"},"confidence":"Medium","entityType":"RoadBlock","geocodePoints":[{"type":"Point","coordinates":[32.595733642578125,-85.4902114868164],"calculationMethod":"Interpolation","usageTypes":["Display","Route"]}],"matchCodes":["Good","UpHierarchy"]}]}],"statusCode":200,"statusDescription":"OK","traceId":"0708c1354ca24977abb59f267e803dcb|CH1M001476|02.00.117.1500|CH1MSNVM001390, EWRIPEVM000240, CH1MSNVM004051"}';
            }           
        } 
                
        ReturnValue.setBody(GeoCodeResponse);
        
        return ReturnValue;
        
    } // HTTPResponse
    
} // BingGeoCodeMock