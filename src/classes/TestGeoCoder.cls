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