global without sharing class PostInstallClass  implements InstallHandler {
	
	public class GeoCoderInstallException extends Exception {}
	
	static string JobName = 'DC:GeoCodeUpdater';
	
	global void onInstall(InstallContext context) {
		
		try {

			if(context.previousVersion() != null) {
				UnScheduleJob();
			} // if(context.previousVersion() != null)
		
			if(context.isUpgrade()) {
			
				if(context.previousVersion().major() ==1 
					&& context.previousVersion().minor() < 81)
				{				
					ClearDefaultRecords();
				} // if(context.previousVersion < 1.81) {
				
			} // if(context.isUpgrade()) {
			
			CreateActiveSettings();
		
			this.ScheduleJob();
			
		} catch (exception e) {

			EmailExceptionToAdmin OutGoingEmail = new EmailExceptionToAdmin('GeoCoder: PostInstallClass',e,'Previous Version: ' + context.previousVersion());						
		}
		
	} // onInstall
	
	private boolean HasActiveSettings() {
		
		List<DC_GG__GeoCodeSettings__c> DefaultSettings = [
							SELECT ID, NAME 
							FROM DC_GG__GeoCodeSettings__c 
							WHERE Name = 'Active'
							];
							
		return !DefaultSettings.IsEmpty();
		
	} // HasActiveSettings
	
	private void ClearDefaultRecords() {
		// this method will clear geocoding data for up to 10,000 records with default results
		// this is to fix a bug in preivous versions and let the records be automatically processed again.
		list <Account> RecordsToReset = [
			SELECT Id, Name, BillingGeoCodeData__Latitude__s, BillingGeoCodeData__Longitude__s
			FROM ACCOUNT
			WHERE
					(BillingGeoCodeData__Latitude__s = 39.390897 AND BillingGeoCodeData__Longitude__s = -99.066067)
				OR
					(BillingGeoCodeData__Latitude__s = 39.44325637817383 AND BillingGeoCodeData__Longitude__s = -98.95733642578125)
			LIMIT 10000		
		];
		
		for (Account A: RecordsToReset) {
			A.BillingGeoCodeData__Latitude__s = null;
			A.BillingGeoCodeData__Longitude__s = null;
		}
		
		update RecordsToReset;
		
	} // ClearDefaultRecords
	
	private void CreateActiveSettings() {
		
		if (HasActiveSettings() == false) {
			DC_GG__GeoCodeSettings__c DefaultSettings = new DC_GG__GeoCodeSettings__c();
			DefaultSettings.Name = 'Active';
			
			// Schema methods universally return false when called from post install scripts
			// even though the install script runs as a phantom 'god' user that can create the
			// data at will (at least when without sharing is set as it is here).
			// for those reasons this line is commented out:
			// if (Schema.Sobjecttype.DC_GG__GeoCodeSettings__c.isCreateable()) {
			
			// per Salesforce support, they hope to have this resolved in an upcoming release
				insert DefaultSettings;
			
		} // if (HasActiveSettings() == false)
		
	} // CreateActiveSettings
	
	private boolean HasLastRunRecord() {
		List<DC_GG__CronInfo__c> LastRun = [
							SELECT ID, NAME 
							FROM DC_GG__CronInfo__c 
							WHERE Name = 'LastRun'
							];
							
		return !LastRun.IsEmpty();		
	} // HasLastRunRecord
	
	private void ScheduleJob() {

		GoogleGeoCodeUpdaterSchedule g = new GoogleGeoCodeUpdaterSchedule();
		String sch = '0 0 * * * ?';
		ID CronID = system.schedule(JobName, sch, g);
		
		DC_GG__CronInfo__c CronSettings;
		
		if (HasLastRunRecord() == false) {
			if (Schema.Sobjecttype.DC_GG__CronInfo__c.isCreateable()) {
				CronSettings = new DC_GG__CronInfo__c();
				CronSettings.Name = 'LastRun';
				CronSettings.DC_GG__JobID__c = CronID;
				insert CronSettings;
			} else {
				throw new GeoCoderInstallException('Unable to CREATE custom cron settings.');				
			} // isCreatable
		} else {
			CronSettings = [
							SELECT ID, NAME 
							FROM DC_GG__CronInfo__c 
							WHERE Name = 'LastRun'
							LIMIT 1
							];
			
			CronSettings.DC_GG__JobID__c = CronID;
						
			if (Schema.Sobjecttype.DC_GG__CronInfo__c.isUpdateable()) {				
				update CronSettings;
				
			} else {
				throw new GeoCoderInstallException('Unable to UPDATE custom cron settings.');
			} // isCreateable && isUpdateable
							
		} // if (HasLastRunRecord == false) {
		 
	} // ScheduleJob
	
	private void UnScheduleJob() {
		DC_GG__CronInfo__c CronSettings = DC_GG__CronInfo__c.getInstance('LastRun');
		
		if (CronSettings != null) {
			
			ID CronID = CronSettings.DC_GG__JobID__c;
						
			if (Schema.Sobjecttype.DC_GG__CronInfo__c.isUpdateable()) {
				CronSettings.DC_GG__JobID__c = null;
				update CronSettings;
			} // DC_GG__CronInfo__c.isUpdateable
			
			if (CronID != null) {
				system.abortJob(CronID);
			} // if (CronID != null) {
			
		} // if (CronSettings != null) {
		
	} // UnScheduleJob
	
	static testMethod Void testInstallScript() {
		
		PostInstallClass postinstall = new PostInstallClass();
    	Test.testInstall(postinstall, null);
    	
    	Test.testInstall(postinstall, new Version(1,0), true);    	
	
	} // testInstallScript
	
} // PostInstallClass