public with sharing class VF_GeoCoderSettings {

    public string BingMapsKey {get;set;}
    public string MapQuestKey {get;set;}
    
    public integer LogSize {get;set;}
    public integer AcctBatchSize {get;set;}

    DC_GG__GeoCodeSettings__c ActiveSettings {get; set;}
    
    public string JqueryDialogMessage {get;set;}
    
    public VF_GeoCoderSettings() {
    	JqueryDialogMessage = '';
        LoadActiveSettings();
    } // constructor

    public void LoadActiveSettings() {
        ActiveSettings = DC_GG__GeoCodeSettings__c.getInstance('Active');
        
        if (ActiveSettings !=null) {
            
            AcctBatchSize = (integer) ActiveSettings.DC_GG__BatchSize__c;   
            LogSize = (integer) ActiveSettings.DC_GG__MaxLogSize__c;
            
            BingMapsKey = ActiveSettings.DC_GG__BingMapsKey__c;
            MapQuestKey = ActiveSettings.DC_GG__MapQuestKey__c;
        } else {
        	if (Schema.Sobjecttype.DC_GG__GeoCodeSettings__c.isCreateable()) {
        		ActiveSettings = new DC_GG__GeoCodeSettings__c();
        	} else {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                 'Insufficient permissions to create default settings.'));        		
        	} // isCreateable
        } // check for null 
                
    } // LoadActiveSettings

    public void Save () {

		JqueryDialogMessage = '';        

        if (Schema.Sobjecttype.DC_GG__GeoCodeSettings__c.isUpdateable()) {

	        ActiveSettings.DC_GG__BatchSize__c = (decimal) AcctBatchSize;   
	        ActiveSettings.DC_GG__MaxLogSize__c = (decimal) LogSize;
	        
	        ActiveSettings.DC_GG__BingMapsKey__c = BingMapsKey; 
	        ActiveSettings.DC_GG__MapQuestKey__c = MapQuestKey;
        	        	
        	update ActiveSettings;

	        // only show the confirmation if the update didn't error
	        if (ApexPages.hasMessages() == false) {
	        	JqueryDialogMessage = '<br/><b>Save was successful!</b>';
	        } // if (ApexPages.hasMessages() == false) {
        	
        } else {
        
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                 'Insufficient permissions to update settings.'));
                                         	        	
        } // .DC_GG__GeoCodeSettings__c.isUpdateable()
                                
    } // save

} // VF_GeoCoderSettings