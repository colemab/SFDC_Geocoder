/*
    04/29/13 TC -
    
    This is the client in the Strategy design pattern:
    
        Context Class:          GeoCoder
        Strategy Interface:     GeoCoderService 
        Concrete Implementations:
                                BingGeoCodeUpdater
                                GoogleGeoCodeUpdater
                                MaqQuestGeoCodeUpdater
                                
        Data Wrapper Class:     GeoCodeResult 
*/
public without sharing class GeoCodeEngine {
    
    public GeoCodeEngine() {
        GeoCodeingResultsList = new List<GeoCodeResult>();
    } // constructor
    
    public static List<GeoCodeResult> GeoCodeingResultsList {get; set;}
            
    // dynamically check the used callouts vs. remaining call outs
    public static boolean SystemHasCalloutsRemaining() {
        boolean returnValue = false;
        if ((Limits.getLimitCallouts() - Limits.getCallouts()) > 0) {
            returnValue = true;
        }
        return returnValue;
    } // SystemHasCalloutsRemaining


    // When you specify future, the method executes when Salesforce has available resources.
    @future(callout=true)   
    public static void FutureGeoCodeAccount (Id AccountID) {
        // Note that currently you can't pass sobjects into async methods, thus the ID being passed instead
        Account A = [
                    SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                           ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                           DC_GG__ShippingNeedsGeocodeUpdated__c, DC_GG__BillingNeedsGeocodeUpdated__c 
                    FROM Account 
                    WHERE id = :AccountID
                ];
                
        GeoCodeAccount(A);
    } // FutureGeoCodeAccount

    public static void GeoCodeAccount(Account A) {
        
        GeoCodeingResultsList = new List<GeoCodeResult>();
        
        GeoCodeResult BillingGeoCodeResult;
        GeoCodeResult ShippingGeoCodeResult;
		GeoCodeResult ExceptionGeoCodeResult;
		                        
        // make all of the callouts before doing any field updates
        
        try {
	        // only spend callouts on addresses that need updating
	        if (A.DC_GG__BillingNeedsGeocodeUpdated__c == 'True') {
	            BillingGeoCodeResult = GeoCodeAddress(A.ID, A.BillingStreet, A.BillingCity, A.BillingState, A.BillingPostalCode, A.BillingCountry);
	        } // if (A.DC_GG__BillingNeedsGeocodeUpdated__c == 'True') {
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.RequestURL = ExceptionDetails;

			ExceptionGeoCodeResult.TimeStamp = System.now();			 
			ExceptionGeoCodeResult.RecordID = A.ID;
			 
            // Log the Error
            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
						 
		} // try & catch on update - just in case we hit any JSON parsing errors

		try {        
	        // only spend callouts on addresses that need updating
	        if (A.DC_GG__ShippingNeedsGeocodeUpdated__c == 'True') {
	            ShippingGeoCodeResult = GeoCodeAddress(A.ID, A.ShippingStreet, A.ShippingCity, A.ShippingState, A.ShippingPostalCode, A.ShippingCountry);
	        } // if (A.DC_GG__ShippingNeedsGeocodeUpdated__c == 'True') {
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.RequestURL = ExceptionDetails;

			ExceptionGeoCodeResult.TimeStamp = System.now();			 
			ExceptionGeoCodeResult.RecordID = A.ID;
			 
            // Log the Error
            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
						 
		} // try & catch on update - just in case we hit any JSON parsing errors
		
		
        // now set the values - if you did this after a call out you would get an error        
        // only update the record if it was geocoded!
        if (BillingGeoCodeResult != null) {
            // only set the fields if the values were not null
            if (BillingGeoCodeResult.HasResults == true) {
                A.BillingGeoCodeData__Latitude__s = BillingGeoCodeResult.Latitude;
                A.BillingGeoCodeData__Longitude__s = BillingGeoCodeResult.Longitude;
            }
            A.BillingLastGeocoded__c = BillingGeoCodeResult.TimeStamp;
        } else if (ShippingGeoCodeResult != null) {
            // One address could have been geocoded and thus will update the record
            // Then the other address will be seen as needing to be updated
            // And this can cause the account to process over and over again 
            // so updating the 'other' time will prevent this.                  
            A.BillingLastGeocoded__c = ShippingGeoCodeResult.TimeStamp;                     
        } // if (BillingGeoCodeResult != null) {

        // only update the record if it was geocoded!
        if (ShippingGeoCodeResult != null) {
            // only set the fields if the values were not null
            if (ShippingGeoCodeResult.HasResults == true) {
                A.ShippingGeoCodeData__Latitude__s = ShippingGeoCodeResult.Latitude;
                A.ShippingGeoCodeData__Longitude__s = ShippingGeoCodeResult.Longitude;
            }
            A.ShippingLastGeocoded__c = ShippingGeoCodeResult.TimeStamp;
        } else if (BillingGeoCodeResult != null) {
            // One address could have been geocoded and thus will update the record
            // Then the other address will be seen as needing to be updated
            // And this can cause the account to process over and over again 
            // so updating the 'other' time will prevent this.                  
            A.ShippingLastGeocoded__c = BillingGeoCodeResult.TimeStamp;
        } // if (ShippingGeoCodeResult != null) {

		try {
			
			if (Schema.Sobjecttype.Account.isUpdateable()) {
        		// save the results to the record                               	
        		update A;
			}
        	
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.RequestURL = ExceptionDetails;

			ExceptionGeoCodeResult.TimeStamp = System.now();			 
			ExceptionGeoCodeResult.RecordID = A.ID;
			 
            // Log the Error
            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
			
			// save the record ID so it can be skipped later on during processing
			DC_GG__SkipRecord__c SkipRecord = new DC_GG__SkipRecord__c();
			SkipRecord.Name = A.ID;
			
			if (Schema.Sobjecttype.DC_GG__SkipRecord__c.isCreateable()) {
				 insert SkipRecord;
			}
								 
		} // try & catch on update - just in case we hit any custom validation errors
        
        // output our log entries
        WriteResultsToLog();
        
        // clean up any old / over size log entries
        TrimLogEntries();
    
    } // GeoCodeAccountBillingAddress
    
    // Attempt to geocode an address based on string - using mutiple services
    public static GeoCodeResult GeoCodeAddress(String RecordID, String StreetAddress, String City, String State, String PostalCode, String Country) {
        GeoCodeResult CurrentResult = new GeoCodeResult(); 
        
        if (SystemHasCalloutsRemaining() == true) {
            
            // if no country, assume US.  This is mainly for Bing Maps bug.
            if (String.isBlank(Country) == true) Country = 'US';
            
            // Try Google First
            GeoCoder GC = new GeoCoder('Google');
            CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
            CurrentResult.RecordID = RecordID;
            
            // Log our result
            GeoCodeingResultsList.add(CurrentResult);
            
            // Try Bing when Google Fails and we have callouts remaining
            if (CurrentResult.HasResults == false && SystemHasCalloutsRemaining() == true) {                
                
                GC = new GeoCoder('Bing');
                CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
                CurrentResult.RecordID = RecordID;
                
                // Log our result
                GeoCodeingResultsList.add(CurrentResult);
                
                // try MapQuest when Bing Fails and we have callouts remaining
                if (CurrentResult.HasResults == false && SystemHasCalloutsRemaining() == true) {
                    
                    GC = new GeoCoder('MapQuest');
                    CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
                    CurrentResult.RecordID = RecordID;
                    
                    // Log our result
                    GeoCodeingResultsList.add(CurrentResult);
        
                } // try MapQuest if Bing failed                
        
            } // try Bing if Google Failed
        
        } // SystemHasCalloutsRemaining == true
        
        return CurrentResult;
                
    } // GeoCodeAddress
    
    // this writes the results to the log object
    public static void WriteResultsToLog() {
        
        if (GeoCodeingResultsList.isEmpty() == false) {
            
            List<DC_GG__Geocoder_Log__c> LogEntriesToInsert = new List<DC_GG__Geocoder_Log__c>();
                
                for(GeoCodeResult CurrentResult : GeoCodeingResultsList) {
                    
                    if (CurrentResult.HasResults == true || CurrentResult.RecordID != null) {
                    
                        DC_GG__Geocoder_Log__c CurrentLogEntry = new DC_GG__Geocoder_Log__c();
                        
                        CurrentLogEntry.DC_GG__Status__c = CurrentResult.Status;
                        CurrentLogEntry.DC_GG__Request_URL__c = CurrentResult.RequestURL;
                        CurrentLogEntry.DC_GG__TimeStamp__c = CurrentResult.TimeStamp;
                        CurrentLogEntry.DC_GG__RecordID__c = CurrentResult.RecordID;
                        
                        LogEntriesToInsert.add(CurrentLogEntry);
                    } // if (CurrentResult.HasResults == true || CurrentResult.RecordID != null) {
                    
                } // loop thru GeoCodeingResultsList
            
            // check to make sure the user has create access 
            if (Schema.Sobjecttype.DC_GG__Geocoder_Log__c.isCreateable()) {                
            	insert LogEntriesToInsert;
            }
            
            // empty the list
            GeoCodeingResultsList.clear();
            
        } // if GeoCodeingResultsList.isEmpty() == false
        
    } // WriteResultsToLog
    
    // this method will be called to keep the log entries at a manageable size (determined by the setting)
    public static void TrimLogEntries() {
        Decimal LastIDToKeep = GetMaxTrimID();
        if (LastIDToKeep > 0) {
            List<DC_GG__Geocoder_Log__c> RecordsToDelete = [
                Select ID, NAME from DC_GG__Geocoder_Log__c WHERE DC_GG__NameNumber__c <= :LastIDToKeep
            ];
            
            if (RecordsToDelete.isEmpty() == false) {
            	if (Schema.Sobjecttype.DC_GG__Geocoder_Log__c.isDeletable()) {
            		delete RecordsToDelete;
            	} // isDeletable()
            } // if (RecordsToDelete.isEmpty() == false) {
        } // if (LastIDToKeep > 0) {
    } // TrimLogEntries

    // This finds the setting for how many log entries to keep
    public static decimal GetMaxLogSizeSetting() {

        decimal ReturnValue = 0;
        
        DC_GG__GeoCodeSettings__c MaxLogSize = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (MaxLogSize !=null && MaxLogSize.DC_GG__MaxLogSize__c != null) ReturnValue = MaxLogSize.DC_GG__MaxLogSize__c;
        
        return ReturnValue;
        
    } // GetMaxLogSizeSetting
        
    // this will find the last ID to keep
    public static decimal GetMaxTrimID() {
        List<AggregateResult> ARList = [Select MAX(NAME) max from DC_GG__Geocoder_Log__c];
        
        Decimal MaxValue = 0;
        Decimal ReturnValue = 0;
        
        for( AggregateResult AR: ARList) {
            MaxValue = Decimal.ValueOf(String.ValueOf(AR.get('max')));
        }
        
        system.debug('Inital Max Value: ' + MaxValue);
        Decimal MaxLogSize = GetMaxLogSizeSetting();
        system.debug('MaxLogSize: ' + MaxLogSize);
        
        // if we have no records, lets not try to set a negative value
        if(MaxValue > MaxLogSize) {
            ReturnValue = MaxValue - MaxLogSize;            
        } // if(MaxValue > MaxLogSize)
        
        return ReturnValue;
        
    } //GetMaxTrimID
} // GeoCodeEngine