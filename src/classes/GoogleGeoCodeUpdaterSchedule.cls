global class GoogleGeoCodeUpdaterSchedule implements Schedulable {
/*
Sample Scheduling code:

DC_GG.GoogleGeoCodeUpdaterSchedule p = new DC_GG.GoogleGeoCodeUpdaterSchedule();
String sch = '0 15 * * * ?';
system.schedule('GeoCoder Test', sch, p);

*/

	// Run the job every day at 1 am
  	public static String CRON_EXP = '0 0 1 * * ?';
 
  	global void execute(SchedulableContext ctx) { 
			DC_GG.BatchGeocodeAccounts BGA = new DC_GG.BatchGeocodeAccounts();
			database.executebatch(BGA, 1);  		  
  	} // execute
        
   	static testmethod void TestGoogleGeoCodeUpdaterSchedule() {
  		Test.startTest();
   
	       	// Schedule the test job 
	        String jobId = System.schedule('TestGoogleGeoCodeUpdaterSchedule',
	                GoogleGeoCodeUpdaterSchedule.CRON_EXP,
	                 new GoogleGeoCodeUpdaterSchedule());
	                  
	     	// Get the information from the CronTrigger API object 
	        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered,
	           NextFireTime
	           FROM CronTrigger WHERE id = :jobId];
	   
	     	// Verify the expressions are the same 
	        System.assertEquals(GoogleGeoCodeUpdaterSchedule.CRON_EXP,
	           ct.CronExpression);
	   
	     	// Verify the job has not run 
	        System.assertEquals(0, ct.TimesTriggered);
	         
     	Test.stopTest();   
   } // test method    
     
} // GoogleGeoCodeUpdaterSchedule