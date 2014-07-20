@isTest (SeeAllData=true)
private class TestGeoCoder {
        
    static testmethod void BatchGeocodeAccounts() {
        
        system.debug('BatchGeocodeAccounts: Start');
        
        // create an account to geocode incase there isn't one in the system
        //Account MyAccount = CreateTestAccount();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new GoogleGeoCodeMock());         
            database.executebatch(new BatchGeocodeAccounts(), 1);
            
        Test.stopTest();
        
        //MyAccount = [Select ID, DC_GG__BillingNeedsGeocodeUpdated__c, DC_GG__ShippingNeedsGeocodeUpdated__c FROM Account WHERE ID = :MyAccount.ID];
        //system.assert(MyAccount.DC_GG__BillingNeedsGeocodeUpdated__c == 'False');
        //system.assert(MyAccount.DC_GG__ShippingNeedsGeocodeUpdated__c == 'False');
                            
    } // BatchGeocodeAccounts
    
    static testmethod void GeoCodeResult() {
    	
    	system.debug('GeoCodeResult: Start');
    	
        GeoCodeResult CurrentResult = new GeoCodeResult(); 
        system.assertEquals(CurrentResult.HasResults,false);
        
        CurrentResult.Latitude = 1;
        CurrentResult.Longitude = 1;        
        system.assertEquals(CurrentResult.HasResults,true);
        
        CurrentResult.Status = 'OK';
        system.assertEquals(CurrentResult.Status,'OK');
        
        datetime CurrentTimeStamp = system.now();
        CurrentResult.TimeStamp = CurrentTimeStamp;
        system.assertEquals(CurrentResult.TimeStamp,CurrentTimeStamp);
        
        string TestURL = 'www.google.com';
        CurrentResult.RequestURL = TestURL;
        system.assertEquals(CurrentResult.RequestURL,TestURL);
        
    } // GeoCodeResult
    
    static testmethod void VF_Maps() {
    	
    	system.debug('VF_Maps: Start');

		Account MyAccount = CreateTestAccount();
		// long / lat for the United Center (billing address)        
        MyAccount.DC_GG__BillingGeoCodeData__Latitude__s =  41.880716;
        MyAccount.DC_GG__BillingGeoCodeData__Longitude__s = -87.674604;
        
        // long / lat for Jordan Hare (shipping address)
        MyAccount.DC_GG__ShippingGeoCodeData__Latitude__s = 32.609455;
        MyAccount.DC_GG__ShippingGeoCodeData__Longitude__s = -85.490350;
        
        update MyAccount;
        
        test.startTest();
    	
    		VF_Maps MyController = new VF_Maps();
    	
    		MyController.UpdateObjectToFilter();
    		MyController.AddQueryFilterDataRow();
    		MyController.RemoveQueryFilterDataRow();
    		
    		MyController.ToggleAdvancedFilter();
    		MyController.ToggleAdvancedFilter();
    		
    		// A new filter option was automatically created, get it to change the settings
    		SOQLQueryFilterData FilterOption = MyController.SOQLQueryFilterDataList.get(0);
    		
    		integer TotalFields = MyController.FieldsSelectOptionList.size();
    		
			// start this at 1 instead of zero so we don't select --none-- which is first and is invalid 
			for (integer x=1; x<TotalFields; x++ ) {    		
				FilterOption.FieldName = MyController.FieldsSelectOptionList.get(x).getValue();			
				system.debug('Current Field: ' + FilterOption.FieldName);
	
				if (Schema.Displaytype.PickList == FilterOption.CurrentFieldType) {
					FilterOption.Value = 'A,B,C,D';
				} else if (Schema.Displaytype.Date == FilterOption.CurrentFieldType) {
					FilterOption.Value = '1/1/2013';
				} else {			
					FilterOption.Value = 'Test';
				}
							
				integer TotalOperators = FilterOption.OperatorList.size();
							
				for (integer y=0; y<TotalOperators; y++) {
	
					FilterOption.Operator = FilterOption.OperatorList.get(y).getValue();
					
					system.debug('Current Operator: ' + FilterOption.Operator);
									
					// get the condition string				
					system.debug('Condition is: ' + MyController.WhereConditionString);						
				} // loop thru Operators
			} // loop thru fields
			
			MyController.RunSearch();

			MyController.AdvancedFilterEnabled = true;

			// Filter logic is required when enabled.
			MyController.AdvancedFilterCondition  = '';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// All parentheses must be closed and opened.
			MyController.AdvancedFilterCondition  = '(';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// if two field numbers are back to back, the logic is invalid			
			MyController.AdvancedFilterCondition  = '1 2 3';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// The filter logic references an undefined filter			
			MyController.AdvancedFilterCondition  = '10000';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// if two union statements are back to back, the logic is invalid 
			MyController.AdvancedFilterCondition  = '1 AND AND';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// The NOT operator is only valid at the start filter logic
			MyController.AdvancedFilterCondition  = '1 NOT';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// unknown operator
			MyController.AdvancedFilterCondition  = 'BOB';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// the filter logic cannot end with an operator
			MyController.AdvancedFilterCondition  = '1 AND';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);
			
			// test a clean build of advanced query string
			MyController.AdvancedFilterEnabled = true;
			MyController.AdvancedFilterCondtionHasError = false;
			MyController.AdvancedFilterCondition  = '1 AND 1';
			MyController.BuildQueryString();
			system.debug('AdvancedFilterCondtionErrorMessage = ' + MyController.AdvancedFilterCondtionErrorMessage);
			system.assert(MyController.AdvancedFilterCondtionHasError == false);
    		
    		system.debug(MyController.FieldsListString);
    		
    	test.stopTest();
    	
    } // VF_Maps
    
	static testMethod Void TestCustomLookupWindowController() {
		
		Account MyAccount = new Account();
		MyAccount.Name = 'Acme, Inc.';
		MyAccount.BillingState = 'AL';
		insert MyAccount;
		
		PageReference CurrentPage = Page.CustomLookupWindow;
		Test.setCurrentPageReference(CurrentPage);
		
		ApexPages.currentPage().getParameters().put('object', 'Account');
		ApexPages.currentPage().getParameters().put('field', 'type');		
		CustomLookupWindowController MyController = new CustomLookupWindowController();
		system.assert(MyController.RenderTextSearch == false);
		system.assert(MyController.RenderListSearch == true);
		
		// this will select or deselect all options
		MyController.SetCurrentSelectedListWrapperSelected();
		// this will build a comma delimited list of all selected options
		MyController.BuildSelectedString();
		
		ApexPages.currentPage().getParameters().put('input', 'test');
		system.assert(MyController.getInputDOMName() == 'test');
		
		ApexPages.currentPage().getParameters().put('object', 'Account');
		ApexPages.currentPage().getParameters().put('field', 'name');
		MyController = new CustomLookupWindowController();
		system.assert(MyController.RenderTextSearch == true);
		system.assert(MyController.RenderListSearch == false);
		
		MyController.TextSearchInput = 'a';
		MyController.TextSearch();
				
	} // TestCustomLookupWindowController	
        
    static testmethod void SortSelectOptions() {
    	
    	list<selectOption> SelectOptionsList = new list<selectOption>();
    	
    	for (integer X=1; x<10; x++) {
    		SelectOption CurrentOption = new SelectOption(String.valueOf(X), String.valueOf(X));
    		SelectOptionsList.add(CurrentOption);
    	} // for (int X=1; x<10; x++)
    	
    	SortSelectOptions.selectOptionSortByLabel(SelectOptionsList);
    	SortSelectOptions.selectOptionSortByValue(SelectOptionsList);
    	
    } // SortSelectOptions
    
    static testmethod void VF_GeoCoderSettings() {

		system.debug('VF_GeoCoderSettings: Start');
		
        VF_GeoCoderSettings MyController = new VF_GeoCoderSettings();
        
        integer Size = 10;
        string Key = 'APIKEY';
        
        MyController.AcctBatchSize = Size;
        MyController.LogSize = Size;
        
        MyController.BingMapsKey = Key;
        MyController.MapQuestKey = Key;
        
        MyController.Save();
        
        MyController.LoadActiveSettings();
        
        system.assertEquals(MyController.BingMapsKey, Key);
        system.assertEquals(MyController.MapQuestKey, Key);
        
        system.assertEquals(MyController.AcctBatchSize, Size);
        system.assertEquals(MyController.LogSize, Size);
        
        MyController.AddCronJob();
        MyController.DelCronID = MyController.CronJobs.get(0).Id;
        MyController.DelCronJob();
        
        MyController.LogSize = 5000;
        MyController.Save();
        system.assertEquals(MyController.LogSize, 2000);
        
    } // VF_GeoCoderSettings
    
    public static Account CreateTestAccount() {
    	
    	system.debug('CreateTestAccount: Start');
    	
        Account MyAccount = new Account();
        MyAccount.Name = 'Test Account 1';
        
        // United Center - Go Blackhawks!
        MyAccount.BillingStreet = '1901 W. Madison St.';
        MyAccount.BillingCity = 'Chicago';
        MyAccount.BillingState = 'IL';
        MyAccount.BillingPostalCode = '60612';
        MyAccount.BillingCountry = 'US';
        
        // Jordan-Hare Stadium - War Eagle!
        MyAccount.ShippingStreet = '251 South Donahue Drive';
        MyAccount.ShippingCity = 'Auburn';
        MyAccount.ShippingState = 'AL';
        MyAccount.ShippingPostalCode = '35244';
        MyAccount.ShippingCountry = 'US';
        
        insert MyAccount;
        
        /// dummy phone number
        MyAccount.Phone = '205-555-1515';
        upsert MyAccount;
        
        // requery the account so the formula fields will be updated
        
        MyAccount = [
                        SELECT ID, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                               ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                               DC_GG__BillingNeedsGeocodeUpdated__c, DC_GG__ShippingNeedsGeocodeUpdated__c
                        FROM Account
                        WHERE ID = :MyAccount.ID
                    ];
                    
        system.assert(MyAccount.DC_GG__BillingNeedsGeocodeUpdated__c == 'True');
        system.assert(MyAccount.DC_GG__ShippingNeedsGeocodeUpdated__c == 'True');
        
        return MyAccount;
    } // CreateTestAccount
    
    static testmethod void GeoCodeEngineGoogle() {
        
        system.debug('GeoCodeEngineGoogle: Start');
        
        Account MyAccount = CreateTestAccount();        
        
        test.startTest();

            GeoCodeEngine GCE = new GeoCodeEngine();
            system.assert(GeoCodeEngine.SystemHasCalloutsRemaining() == true);

            Test.setMock(HttpCalloutMock.class, new GoogleGeoCodeMock());                               
            GeoCodeEngine.GeoCodeAccount(MyAccount);
            
        test.stopTest();
        
    } // GeoCodeEngineGoogle

    static testmethod void GeoCodeEngineBing() {
        
        system.debug('GeoCodeEngineBing: Start');
        
        Account MyAccount = CreateTestAccount();
        
        test.startTest();

            GeoCodeEngine GCE = new GeoCodeEngine();
            system.assert(GeoCodeEngine.SystemHasCalloutsRemaining() == true);

            Test.setMock(HttpCalloutMock.class, new BingGeoCodeMock());                             
            GeoCodeEngine.GeoCodeAccount(MyAccount);
                        
        test.stopTest();
        
    } // GeoCodeEngineBing

    static testmethod void GeoCodeEngineMapQuest() {
        
        system.debug('GeoCodeEngineMapQuest: Start');
        
        Account MyAccount = CreateTestAccount();
                
        test.startTest();

            GeoCodeEngine GCE = new GeoCodeEngine();
            system.assert(GeoCodeEngine.SystemHasCalloutsRemaining() == true);
            
            Test.setMock(HttpCalloutMock.class, new MapQuestGeoCodeMock());                             
            GeoCodeEngine.GeoCodeAccount(MyAccount);
            
        test.stopTest();
        
    } // GeoCodeEngineMapQuest


} // TestGeoCoder