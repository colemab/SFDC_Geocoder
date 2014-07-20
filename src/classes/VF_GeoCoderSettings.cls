public with sharing class VF_GeoCoderSettings {

    public string BingMapsKey {get;set;}
    public string MapQuestKey {get;set;}
    public string GoogleKey {get;set;}
    
    public integer LogSize {get;set;}
    public integer AcctBatchSize {get;set;}

    DC_GG__GeoCodeSettings__c ActiveSettings {get; set;}
    
    public list <CronTrigger> CronJobs {get;set;} 
	public Id DelCronID {get;set;}
    
    public string JqueryDialogMessage {get;set;}
    
    public VF_GeoCoderSettings() {
    	JqueryDialogMessage = '';
        LoadActiveSettings();
        findCronJobs();
    } // constructor
    
    public void findCronJobs() {
		// Job type 7 = apex scheduled classes
		CronJobs  = 
				[
					SELECT Id, NextFireTime, PreviousFireTime, CronJobDetail.Id, CronJobDetail.Name, 
						   CronJobDetail.JobType
					FROM CronTrigger 
					WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE '%DC:GeoCodeUpdater%'
					ORDER BY NextFireTime
				];    	
    } // findCronJobs
    
    public void DelCronJob () {
    	
		JqueryDialogMessage = '';
    	
    	if (DelCronID != null) {
    		
    		system.debug('DelCronID = ' + DelCronID);    		
    		system.abortJob(DelCronID);
    		findCronJobs();
    		
    	} // if (DelCronID != null) {
    	
    } // DelCronJob
    
    public boolean ScheduleCronJob(integer MinutesAfterHour) {
    	boolean returnValue = false;

				// look for any existing jobs with in 10 minutes of this job
				integer MaxCheckValue = MinutesAfterHour + 9;
				integer MinCheckValue = MinutesAfterHour - 9;
				
				if (MinCheckValue <= 0 ) MinCheckValue += 60;
				if (MaxCheckValue <= 0 ) MaxCheckValue += 60;
				
				system.debug('MaxCheckValue: ' + MaxCheckValue);
				system.debug('MinCheckValue: ' + MinCheckValue);
				
				for (CronTrigger CurrentTrigger: CronJobs) {
					
					integer NextFireTimeMinute = CurrentTrigger.NextFireTime.minute();
					
					system.debug('CurrentTrigger Name: ' + CurrentTrigger.CronJobDetail.Name);
					system.debug('CurrentTrigger Minute: ' + NextFireTimeMinute);
					
					if ((NextFireTimeMinute >= MinCheckValue && NextFireTimeMinute <= MaxCheckValue) ||
						NextFireTimeMinute == MinutesAfterHour) {
						return false;
					} // check for conflick
										
				} // loop thru cron jobs
				
				if (MinutesAfterHour >= 60)  MinutesAfterHour -= 60;
				
				string TwoMinutesFromNow = String.ValueOf(MinutesAfterHour);
				
				system.debug('Trying to schedule: ' + TwoMinutesFromNow);
				
				GoogleGeoCodeUpdaterSchedule g = new GoogleGeoCodeUpdaterSchedule();
				String sch = '0 ' + TwoMinutesFromNow + ' * * * ?';
				string JobName = 'DC:GeoCodeUpdater - ' + TwoMinutesFromNow + ' after the hour';
				
				system.schedule(JobName, sch, g);
    			returnValue = true;
    			
    	return returnValue;
    	
    } // ScheduleCronJob
    
    public void AddCronJob () {
       	
       	JqueryDialogMessage = '';
       	findCronJobs();
       	
       	if (CronJobs.size() > 4) {
       		JqueryDialogMessage = 'You can only schedule 5 Jobs.';	
       	} else {
        	try {
				integer futurevalue = system.now().minute()+2;
				if (futurevalue >= 60)  futurevalue = futurevalue-60;
															
				while (ScheduleCronJob(futurevalue) == false) {
					futurevalue +=1;
					system.debug('futurevalue = ' + futurevalue);
				}				

				findCronJobs();
				
        	} catch (exception e) {
        		JqueryDialogMessage = e.getMessage();
        	}
       	} // if (CronJobs.size() > 5) {
    } // AddCronJob

    public void LoadActiveSettings() {
        ActiveSettings = DC_GG__GeoCodeSettings__c.getInstance('Active');
        
        if (ActiveSettings !=null) {
            
            AcctBatchSize = (integer) ActiveSettings.DC_GG__BatchSize__c;   
            LogSize = (integer) ActiveSettings.DC_GG__MaxLogSize__c;
            
            BingMapsKey = ActiveSettings.DC_GG__BingMapsKey__c;
            MapQuestKey = ActiveSettings.DC_GG__MapQuestKey__c;
            GoogleKey = ActiveSettings.DC_GG__GoogleKey__c;
            
        } else {
        	if (Schema.Sobjecttype.DC_GG__GeoCodeSettings__c.isCreateable()) {
        		ActiveSettings = new DC_GG__GeoCodeSettings__c();
        	} else {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                 'Insufficient permissions to create default settings.'));        		
        	} // isCreateable
        } // check for null 
                
    } // LoadActiveSettings

    public void Save() {

		JqueryDialogMessage = '';        

		if ((decimal) LogSize > 2000) {
			LogSize = 2000;
			JqueryDialogMessage = 'Max Log size was reduced to the maximum value of 2000.';
		}

        if (Schema.Sobjecttype.DC_GG__GeoCodeSettings__c.isUpdateable()) {

	        ActiveSettings.DC_GG__BatchSize__c = (decimal) AcctBatchSize;   
	        ActiveSettings.DC_GG__MaxLogSize__c = (decimal) LogSize;
	        
	        ActiveSettings.DC_GG__GoogleKey__c = GoogleKey;
	        ActiveSettings.DC_GG__BingMapsKey__c = BingMapsKey; 
	        ActiveSettings.DC_GG__MapQuestKey__c = MapQuestKey;
        	
        	update ActiveSettings;

	        // only show the confirmation if the update didn't error
	        if (ApexPages.hasMessages() == false) {
	        	JqueryDialogMessage += 'Save was successful!';
	        } // if (ApexPages.hasMessages() == false) {
        	
        } else {
        
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                 'Insufficient permissions to update settings.'));
                                         	        	
        } // .DC_GG__GeoCodeSettings__c.isUpdateable()
                                
    } // save

} // VF_GeoCoderSettings