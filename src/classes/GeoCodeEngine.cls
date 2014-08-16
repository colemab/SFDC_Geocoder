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


	/*	
		// this method is used for debugging of individual accounts
	*/   
	    public static void GeoCodeAccountByID (Id AccountID) {
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
	/**/
	
	// Note that this method doesn't need to be bulkified because it will be called from
	// batch apex that will only pass in one record at a time.  This is due to the call out limits,
	// which prevent from processing more than one record at a time.
	
    public static void GeoCodeAccount(Account A) {
        
        GeoCodeingResultsList = new List<GeoCodeResult>();
        
        GeoCodeResult BillingGeoCodeResult;
        GeoCodeResult ShippingGeoCodeResult;
		GeoCodeResult ExceptionGeoCodeResult;
                       		                        
        // make all of the callouts before doing any field updates        
        try {
	        // only spend callouts on addresses that need updating
	        if (A.DC_GG__BillingNeedsGeocodeUpdated__c == 'True') {
	        	system.debug('Geocoding Billing Address . . . ');
	            BillingGeoCodeResult = GeoCodeAddress(A.ID, A.BillingStreet, A.BillingCity, A.BillingState, A.BillingPostalCode, A.BillingCountry);
	        } // if (A.DC_GG__BillingNeedsGeocodeUpdated__c == 'True') {
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.TraceMessage = ExceptionDetails;

			ExceptionGeoCodeResult.TimeStamp = System.now();			 
			ExceptionGeoCodeResult.RecordID = A.ID;
			 
            // Log the Error
            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
						 
		} // try & catch on update - just in case we hit any JSON parsing errors

		try {        
	        // only spend callouts on addresses that need updating
	        if (A.DC_GG__ShippingNeedsGeocodeUpdated__c == 'True') {
	        	system.debug('Geocoding Shipping Address . . . ');
	            ShippingGeoCodeResult = GeoCodeAddress(A.ID, A.ShippingStreet, A.ShippingCity, A.ShippingState, A.ShippingPostalCode, A.ShippingCountry);
	        } // if (A.DC_GG__ShippingNeedsGeocodeUpdated__c == 'True') {
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.TraceMessage = ExceptionDetails;

			ExceptionGeoCodeResult.TimeStamp = System.now();			 
			ExceptionGeoCodeResult.RecordID = A.ID;
			 
            // Log the Error
            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
						 
		} // try & catch on update - just in case we hit any JSON parsing errors
		
		
        // now set the values - if you did this after a call out you would get an error        
        // only update the record if it was geocoded!
        if (BillingGeoCodeResult != null) {        	
        	
        	system.debug('BillingGeoCodeResult != Null');
        	system.debug('BillingGeoCodeResult.Status =' + BillingGeoCodeResult.Status);
        	
            // only set the fields if the values were not null
            if (BillingGeoCodeResult.HasResults == true) {
                A.BillingGeoCodeData__Latitude__s = BillingGeoCodeResult.Latitude;
                A.BillingGeoCodeData__Longitude__s = BillingGeoCodeResult.Longitude;
                A.DC_GG__BillingGeoCodeEngine__c = BillingGeoCodeResult.Engine;
                A.DC_GG__BillingGeoCodeQuality__c = BillingGeoCodeResult.Quality;
            } else if (BillingGeoCodeResult.Status == 'BLANK_ADDRESS') {
				// clear any long/lat data when the address is blank
				A.BillingGeoCodeData__Latitude__s = null;
                A.BillingGeoCodeData__Longitude__s = null;            	
            } // if (BillingGeoCodeResult.HasResults == true) {
            
            A.BillingLastGeocoded__c = BillingGeoCodeResult.TimeStamp.addMinutes(1);
            
            // in case an internal exception was logged, this will make sure the record ID is correct
            if (BillingGeoCodeResult.RecordID == null) {
            	BillingGeoCodeResult.RecordID = A.ID;
            }
            
        } else if (ShippingGeoCodeResult != null) {
            // One address could have been geocoded and thus will update the record
            // Then the other address will be seen as needing to be updated
            // And this can cause the account to process over and over again 
            // so updating the 'other' time will prevent this.                  
            A.BillingLastGeocoded__c = ShippingGeoCodeResult.TimeStamp.addMinutes(1);                     
        } // if (BillingGeoCodeResult != null) {

        // only update the record if it was geocoded!
        if (ShippingGeoCodeResult != null) {

        	system.debug('ShippingGeoCodeResult != Null');
        	system.debug('ShippingGeoCodeResult.Status =' + ShippingGeoCodeResult.Status);
        	
            // only set the fields if the values were not null
            if (ShippingGeoCodeResult.HasResults == true) {
                A.ShippingGeoCodeData__Latitude__s = ShippingGeoCodeResult.Latitude;
                A.ShippingGeoCodeData__Longitude__s = ShippingGeoCodeResult.Longitude;
                A.DC_GG__ShippingGeoCodeEngine__c = ShippingGeoCodeResult.Engine;
                A.DC_GG__ShippingGeoCodeQuality__c = ShippingGeoCodeResult.Quality;                
            } else if (ShippingGeoCodeResult.Status == 'BLANK_ADDRESS') {
				// clear any long/lat data when the address is blank
				A.ShippingGeoCodeData__Latitude__s = null;
                A.ShippingGeoCodeData__Longitude__s = null;            	
            } // if (ShippingGeoCodeResult.HasResults == true) {
            
            A.ShippingLastGeocoded__c = ShippingGeoCodeResult.TimeStamp.addMinutes(1);

            // in case an internal exception was logged, this will make sure the record ID is correct
            if (ShippingGeoCodeResult.RecordID == null) {
            	ShippingGeoCodeResult.RecordID = A.ID;
            }
            
        } else if (BillingGeoCodeResult != null) {
            // One address could have been geocoded and thus will update the record
            // Then the other address will be seen as needing to be updated
            // And this can cause the account to process over and over again 
            // so updating the 'other' time will prevent this.                  
            A.ShippingLastGeocoded__c = BillingGeoCodeResult.TimeStamp.addMinutes(1);
        } // if (ShippingGeoCodeResult != null) {

		try {
			
			if (Schema.Sobjecttype.Account.isUpdateable()) {
        		// save the results to the record                               	
        		update A;
			} else {
				ExceptionGeoCodeResult = new GeoCodeResult();
				ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';
	
				ExceptionGeoCodeResult.RequestURL = 'Record was not updateable.  Check permissions';
				ExceptionGeoCodeResult.TimeStamp = System.now();			 
				ExceptionGeoCodeResult.RecordID = A.ID;

	           // Log the Error
	            GeoCodeingResultsList.add(ExceptionGeoCodeResult);
						
			} // if (Schema.Sobjecttype.Account.isUpdateable()) {
        	
		} catch (Exception e) {
						
			ExceptionGeoCodeResult = new GeoCodeResult();
			ExceptionGeoCodeResult.Status = 'APEX_EXCEPTION';

			String ExceptionDetails = 'Exception Type Name: ' + e.getTypeName() + ' --- Exception Message: ' + e.getMessage() + ' --- Exception Cause: ' + e.getCause() + ' --- Exception LineNumber: ' + e.getLineNumber();
			ExceptionGeoCodeResult.TraceMessage = ExceptionDetails;

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
            
            // convert nulls to blanks
            if (StreetAddress == null) StreetAddress ='';
            if (City == null) City ='';
            if (State == null) State ='';
            if (Postalcode == null) Postalcode ='';
            if (Country == null) Country ='';
            
            // clean up any non standard zip codes
            Postalcode = Postalcode.replaceAll('-', '');
            if (Postalcode.length() > 5 && Postalcode.length() != 9) {
            	Postalcode = Postalcode.substring(0,5);
            } 
            
            Map<String,String>  TerritoriesToCountries = GeoCodeEngine.getTerritoriesToCountries();
            
            // if the state is a known value then set the country to a known value
            // the google engine uses filter components.  Filtering on the country
            // can help catch errors with an invalid zip code.
            if (TerritoriesToCountries.containsKey(State.toUpperCase())) {
            	Country = TerritoriesToCountries.get(State.toUpperCase());
            	system.debug('Found State: ' + State + ' in ' + Country);
            } // TerritoriesToCountries.containsKey(State.toUpper())
            
            string BlankAddressCheckString = StreetAddress + City + State + Postalcode; 
            system.debug('BlankAddressCheckString = ' + BlankAddressCheckString);
    		        
            if(String.isBlank(BlankAddressCheckString) == false) {
            	            
	            /*
	             2/18/2014 TC - Removing google as an option until they remove the connection limit.
	             7/8/2014 TC - Google has re-enabled API access
	            */

	            // Try Google First
	            GeoCoder GC = new GeoCoder('Google');
	            CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
	            CurrentResult.RecordID = RecordID;
	            
	            // Log our result
	            GeoCodeingResultsList.add(CurrentResult);

	            if (CurrentResult.HasResults == false && SystemHasCalloutsRemaining() == true) {	            
						// Try Bing when Google Fails and we have callouts remaining	            	    
	                    GC = new GeoCoder('MapQuest');
	                    CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
	                    CurrentResult.RecordID = RecordID;
	                    
	                    // Log our result
	                    GeoCodeingResultsList.add(CurrentResult);
		                
		                // try Bing when MapQuest Fails and we have callouts remaining
		                if (CurrentResult.HasResults == false && SystemHasCalloutsRemaining() == true) {
							system.debug('No results, looking at BING.');
			                GC = new GeoCoder('Bing');
			                CurrentResult = GC.GeoCodeAddress(StreetAddress, City, State, PostalCode, Country);
			                CurrentResult.RecordID = RecordID;
			                
			                // Log our result
			                GeoCodeingResultsList.add(CurrentResult);
		                    	        
		                } // try Bing if MapQuest failed                 
	            	} // try MapQuest if Google Failed
		        } else {
		        		system.debug('Address was blank!');
		        		CurrentResult.Status = 'BLANK_ADDRESS';
		        		CurrentResult.TimeStamp = System.now();
		        } // address has data
	        
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
                        CurrentLogEntry.DC_GG__Trace_Message__c = CurrentResult.TraceMessage;
                        
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
    	
    	// Moved core logic to the TrimLogsBeforeID method so it could recursively call it self but keep the same max ID.
    	TrimLogsBeforeID(GetMaxTrimID());
    	
    } // TrimLogEntries
    
    public static void TrimLogsBeforeID(Decimal LastIDToKeep) {
        
        system.debug('LastIDToKeep = ' + LastIDToKeep);
        
        if (LastIDToKeep > 0) {
        	
        	// 2000 rows is the max that SOQL supports in a single query
            List<DC_GG__Geocoder_Log__c> RecordsToDelete = [
                Select ID, NAME from DC_GG__Geocoder_Log__c WHERE DC_GG__NameNumber__c <= :LastIDToKeep ORDER BY ID LIMIT 2000
            ];
            
            if (RecordsToDelete.isEmpty() == false) {
            	
            	if (Schema.Sobjecttype.DC_GG__Geocoder_Log__c.isDeletable()) {            	            		
            		
            		system.debug('Records to Delete: ' + RecordsToDelete.Size());
            		delete RecordsToDelete;
            		
            		// recursively call the function to delete more logs. If more than 2000 logs need to be deleted, they can't be deleted in one call.
            		TrimLogsBeforeID(LastIDToKeep);
            		
            	} // isDeletable()
            	
            } // if (RecordsToDelete.isEmpty() == false) {
            
        } // if (LastIDToKeep > 0) { 
           	
    } // TrimLogsBeforeID

    // This finds the setting for how many log entries to keep
    public static decimal GetMaxLogSizeSetting() {

        decimal ReturnValue = 0;
        
        DC_GG__GeoCodeSettings__c MaxLogSize = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (MaxLogSize !=null && MaxLogSize.DC_GG__MaxLogSize__c != null) ReturnValue = MaxLogSize.DC_GG__MaxLogSize__c;
        
        system.debug('MaxLogSize Setting: ' + ReturnValue);
        return ReturnValue;
        
    } // GetMaxLogSizeSetting
    
    public static decimal GetMaxLogID() {
    	
    	DC_GG__Geocoder_Log__c MaxLog = [Select NAME, DC_GG__NameNumber__c from DC_GG__Geocoder_Log__c ORDER BY CreatedDate DESC LIMIT 1];
    	
    	Decimal MaxValue = MaxLog.DC_GG__NameNumber__c;
    	
        system.debug('Max Log ID: ' + MaxValue);
        return MaxValue;    	
        
    } // GetMaxLogSetting
        
    // this will find the last ID to keep
    public static decimal GetMaxTrimID() {
        
        Decimal ReturnValue = 0;
        Decimal MaxValue = GetMaxLogID();                
        Decimal MaxLogSize = GetMaxLogSizeSetting();
        
        // if we have no records, lets not try to set a negative value
        if(MaxValue > MaxLogSize) {
            ReturnValue = MaxValue - MaxLogSize;            
        } // if(MaxValue > MaxLogSize)
        
        system.debug('MaxTrimID: ' + ReturnValue);
        return ReturnValue;
        
    } //GetMaxTrimID
    
	public static Map<String,String>  getTerritoriesToCountries() {
		
		// used to enforce country level filters
		Map<String,String> TerritoriesToCountries = new Map<String,String>();		
		
		TerritoriesToCountries.put('AL','US');
		TerritoriesToCountries.put('ALABAMA','US');
		
		TerritoriesToCountries.put('AK','US');
		TerritoriesToCountries.put('ALASKA','US');
				
		TerritoriesToCountries.put('AZ','US');
		TerritoriesToCountries.put('ARIZONA','US');
				
		TerritoriesToCountries.put('AR','US');
		TerritoriesToCountries.put('ARKANSAS','US');
				
		TerritoriesToCountries.put('CA','US');
		TerritoriesToCountries.put('CALIFORNIA','US');
				
		TerritoriesToCountries.put('CO','US');
		TerritoriesToCountries.put('COLORADO','US');
				
		TerritoriesToCountries.put('CT','US');
		TerritoriesToCountries.put('CONNECTICUT','US');
				
		TerritoriesToCountries.put('DE','US');
		TerritoriesToCountries.put('DELAWARE','US');
				
		TerritoriesToCountries.put('DC','US');
		TerritoriesToCountries.put('DIST OF COLUMBIA','US');
				
		TerritoriesToCountries.put('FL','US');
		TerritoriesToCountries.put('FLORIDA','US');		
		
		TerritoriesToCountries.put('GA','US');
		TerritoriesToCountries.put('GEORGIA','US');
		
		TerritoriesToCountries.put('HI','US');
		TerritoriesToCountries.put('HAWAII','US');
		
		TerritoriesToCountries.put('ID','US');
		TerritoriesToCountries.put('IDAHO','US');
		
		TerritoriesToCountries.put('IL','US');
		TerritoriesToCountries.put('ILLINOIS','US');
		
		TerritoriesToCountries.put('IN','US');
		TerritoriesToCountries.put('INDIANA','US');
		
		TerritoriesToCountries.put('IA','US');
		TerritoriesToCountries.put('IOWA','US');
		
		TerritoriesToCountries.put('KS','US');
		TerritoriesToCountries.put('KANSAS','US');
		
		TerritoriesToCountries.put('KY','US');
		TerritoriesToCountries.put('KENTUCKY','US');
		
		TerritoriesToCountries.put('LA','US');
		TerritoriesToCountries.put('LOUISANA','US');
		
		TerritoriesToCountries.put('ME','US');
		TerritoriesToCountries.put('MAINE','US');
		
		TerritoriesToCountries.put('MD','US');
		TerritoriesToCountries.put('MARYLAND','US');
		
		TerritoriesToCountries.put('MA','US');
		TerritoriesToCountries.put('MASSACHUSETTS','US');
		
		TerritoriesToCountries.put('MI','US');
		TerritoriesToCountries.put('MICHIGAN','US');
		
		TerritoriesToCountries.put('MN','US');
		TerritoriesToCountries.put('MINNESOTA','US');
		
		TerritoriesToCountries.put('MS','US');
		TerritoriesToCountries.put('MISSISSIPPI','US');
		
		TerritoriesToCountries.put('MO','US');
		TerritoriesToCountries.put('MISSOURI','US');
		
		TerritoriesToCountries.put('MT','US');
		TerritoriesToCountries.put('MONTANA','US');
		
		TerritoriesToCountries.put('NE','US');
		TerritoriesToCountries.put('NEBRASKA','US');
		
		TerritoriesToCountries.put('NV','US');
		TerritoriesToCountries.put('NEVADA','US');
		
		TerritoriesToCountries.put('NH','US');
		TerritoriesToCountries.put('NEW HAMPSHIRE','US');
		
		TerritoriesToCountries.put('NJ','US');
		TerritoriesToCountries.put('NEW JERSEY','US');
		
		TerritoriesToCountries.put('NM','US');
		TerritoriesToCountries.put('NEW MEXICO','US');
		
		TerritoriesToCountries.put('NY','US');
		TerritoriesToCountries.put('NEW YORK','US');
		
		TerritoriesToCountries.put('NC','US');
		TerritoriesToCountries.put('NORTH CAROLINA','US');
		
		TerritoriesToCountries.put('ND','US');
		TerritoriesToCountries.put('NORTH DAKOTA','US');
		
		TerritoriesToCountries.put('OH','US');
		TerritoriesToCountries.put('OHIO','US');
		
		TerritoriesToCountries.put('OK','US');
		TerritoriesToCountries.put('OKLAHOMA','US');
		
		TerritoriesToCountries.put('OR','US');
		TerritoriesToCountries.put('OREGON','US');
		
		TerritoriesToCountries.put('PA','US');
		TerritoriesToCountries.put('PENNSYLVANIA','US');
		
		TerritoriesToCountries.put('RI','US');
		TerritoriesToCountries.put('RHODE ISLAND','US');
		
		TerritoriesToCountries.put('SC','US');
		TerritoriesToCountries.put('SOUTH CAROLINA','US');
		
		TerritoriesToCountries.put('SD','US');
		TerritoriesToCountries.put('SOUTH DAKOTA','US');
		
		TerritoriesToCountries.put('TN','US');
		TerritoriesToCountries.put('TENNESSEE','US');
		
		TerritoriesToCountries.put('TX','US');
		TerritoriesToCountries.put('TEXAS','US');
		
		TerritoriesToCountries.put('UT','US');
		TerritoriesToCountries.put('UTAH','US');
		
		TerritoriesToCountries.put('VT','US');
		TerritoriesToCountries.put('VERMONT','US');
		
		TerritoriesToCountries.put('VA','US');
		TerritoriesToCountries.put('VIRGINIA','US');
		
		TerritoriesToCountries.put('WA','US');
		TerritoriesToCountries.put('WASHINGTON','US');
		
		TerritoriesToCountries.put('WV','US');
		TerritoriesToCountries.put('WEST VIRGINA','US');
		
		TerritoriesToCountries.put('WI','US');
		TerritoriesToCountries.put('WISCONSIN','US');
		
		TerritoriesToCountries.put('WY','US');
		TerritoriesToCountries.put('WYOMING','US');
		
		return TerritoriesToCountries;
				
	} // getTerritoriesToCountries    
	
} // GeoCodeEngine