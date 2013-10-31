/*
    04/30/13 TC -
        This batch method is used to avoid govenor limits in salesforce.
        
        Since each apex transaction / instance is currently limited to 10 callouts and
        pending operations (i.e. DML, setting fields, future methods) are not allowed
        after making a call out, batch apex must be used.  
        
        Because each execute call in batch apex as seen as a new transaction, these
        limits can be managed - as long as the batch size / chunck is set properly.
        
        Example Call:
        
            BatchGeocodeAccounts BGA = new BatchGeocodeAccounts();
            database.executebatch(BGA, 1);
    
*/
global class BatchGeocodeAccounts implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    public static decimal getBatchSize_Accounts() {

        decimal ReturnValue = 0;
        
        DC_GG__GeoCodeSettings__c MaxSize = DC_GG__GeoCodeSettings__c.getInstance('Active');
        if (MaxSize !=null && MaxSize.DC_GG__BatchSize__c != null) ReturnValue = MaxSize.DC_GG__BatchSize__c;
        
        return ReturnValue;
        
    } // GetMaxLogSizeSetting
       
   // this method is used to get all reccords that will be processed by execute method
   global Database.QueryLocator start(Database.BatchableContext BC){
                
        Integer MaxSize = Integer.ValueOf(getBatchSize_Accounts());
        
        String Query= 'SELECT ID, Name, BillingState, BillingCity, BillingStreet, BillingPostalCode, BillingCountry, ';
        Query = Query + 'ShippingState, ShippingCity, ShippingStreet, ShippingPostalCode, ShippingCountry, ';
        Query = Query + 'LastModifiedDate, DC_GG__ShippingNeedsGeocodeUpdated__c, DC_GG__BillingNeedsGeocodeUpdated__c ';
        Query = Query + 'FROM Account ';
        Query = Query + 'WHERE DC_GG__BillingNeedsGeocodeUpdated__c = \'True\' OR DC_GG__ShippingNeedsGeocodeUpdated__c = \'True\' ';        
        Query = Query + 'Order By LastModifiedDate ';
        
        if (test.isRunningTest()) MaxSize = 1;
        
        Query = Query + 'LIMIT ' + MaxSize;
        
        system.debug('Query = ' + Query);
        
        return Database.getQueryLocator(query);
   } // start

   global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        // loop thru results  
        for (SObject s : scope) {
            Account A = (Account) s;            
            system.debug('Processing: ' + A.Name + ' - ' + A.Id);

			// search to see if this record was marked for skipping
        	List<DC_GG__SkipRecord__c> SkipRecords = new List<DC_GG__SkipRecord__c>();
        	SkipRecords = [SELECT NAME, ID From DC_GG__SkipRecord__c WHERE Name = :A.Id];
            
            // if the record wasn't found in the skip list, then process it!
            if (SkipRecords.isEmpty() == true) {
            	GeoCodeEngine.GeoCodeAccount(A);
            } // if (SkipRecords.isEmpty() == true) {
        } // loop thru scope
    
   } // execute

   global void finish(Database.BatchableContext BC){
		
		Integer MaxSize = Integer.ValueOf(getBatchSize_Accounts());
		
		// check to see if all records have been processed		
		Account[] AccountsLeftToProcess = [
			SELECT ID
			FROM Account
			WHERE DC_GG__BillingNeedsGeocodeUpdated__c = 'True' 
				  OR DC_GG__ShippingNeedsGeocodeUpdated__c = 'True'		
		];
		
		
		// Records are skipped whenever an exception is encounterd trying to update the account
		// record.  This could be due to an un-releated validation error.  So we want to try
		// and reprocess these records later - i.e. don't skip them forever.
		
		// if the records left to process won't fill up a batch size (i.e. maxSize) then
		// look for records to process
		if (AccountsLeftToProcess.size() < MaxSize) {
						
			// only delete a batch size (i.e. maxSize) of the oldest records
			// this is incase any new accounts come in - they will get processed
			// in the next batch but ahead of some of the newer skipped records 
			DC_GG__SkipRecord__c[] SkipRecordsToDelete = [
				SELECT Id, Name  FROM DC_GG__SkipRecord__c  
				ORDER BY CreatedDate
				LIMIT :MaxSize		
			];

			if (SkipRecordsToDelete.size() > 0) {
				if (Schema.Sobjecttype.DC_GG__SkipRecord__c.isDeletable()) {
					delete SkipRecordsToDelete;
				} // isDeletable
			} // if (SkipRecordsToDelete.size() > 0) {
		} // if (AccountsLeftToProcess.size() > 0) {
	
   } // finish

} // GeoCodeEngineBatch