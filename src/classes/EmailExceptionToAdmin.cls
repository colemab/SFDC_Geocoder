public without sharing class EmailExceptionToAdmin {

	/*
		02/27/12 TC - This class will be used to email developers / admins 
		whenever an unhandled exception is encountered.
		
		Please note that this class is WITHOUT SHARING because the public site user
		is often the one that calls this class and that set of users does not have
		access to the user table.  So if this class were with sharing, it would fail.
		
		Due to this configuration, this class should be very limited in what it does.
		
		For example, be sure to use ONLY bind variables in SOQL calls.
	*/

	public EmailExceptionToAdmin(string SourceLocation, Exception e, string ExtraInformation) {
		
		string ToEmailAddress;
		
		ToEmailAddress = GetPrimaryContactEmailAddress();
		
		if (ToEmailAddress != null) {
			
				// Make sure this transaction won't fail due to lack of daily capacity
				Messaging.reserveSingleEmailCapacity(1);
				
				// generate our new object
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
				
				// build the Array string required to set the to address
				String[] toAddresses = new String[] {ToEmailAddress};
				system.debug('ToEmailAddress = ' + ToEmailAddress);
				
				// Set our to address
				email.setToAddresses(toAddresses);

				// hide the salesforce name in the display
				email.setSenderDisplayName('CMS - SalesForce.com');
				
				// set the subject on the email
				email.setSubject('DEVELOPER ALERT: Unhandled Exception');

				
				// set the body of the email
				email.setHTMLBody('An unhandled Exception has been encountered from: ' + SourceLocation + '<br/>' +
								  'Exception Type Name: ' + e.getTypeName() + '<br/>' +
								  'Exception Message: ' + e.getMessage() + '<br/>' +
								  'Exception Cause: ' + e.getCause() + '<br/>' +
								  'Exception LineNumber: ' + e.getLineNumber() + '<br/>' +
								  'Extra Information: ' + ExtraInformation
				);
				
				// send our email by creating an array of emails and calling the send email method.
				Messaging.SingleEmailMessage[] EmailsToSend = new Messaging.SingleEmailMessage[] { email };
				
				Messaging.sendEmail(EmailsToSend);			
			
		} // check for null address
		
	} // constructor Method

	static public string GetPrimaryContactEmailAddress() {
		
		String PrimaryContactEmailAddress = '';
		
		// 1. Determine the Primary Contact Name
		Organization SFDC_OrgInfo = [SELECT PRIMARYCONTACT FROM ORGANIZATION LIMIT 1];
		
		// 2. Find the primary contact email in user table
		User PrimaryContactUser = [SELECT email FROM User WHERE NAME = :SFDC_OrgInfo.PRIMARYCONTACT LIMIT 1];
		
		PrimaryContactEmailAddress = PrimaryContactUser.Email; 
		
		system.debug('PrimaryContactEmailAddress = ' + PrimaryContactEmailAddress);
		
		return PrimaryContactEmailAddress;
		
	} // GetPrimaryContactEmailAddress
	
	static testMethod void TestEmailExceptionToAdmin() {
		
		// Lead has required fields and inserting without them will result in an exception
		Lead MyBadLead;
		
		try {
			insert MyBadLead;
		} catch (exception e) {
			EmailExceptionToAdmin OutGoingEmail = new EmailExceptionToAdmin('TestEmailExceptionToAdmin',e,'Test Method!');
		} // try & catch
		
	} // test EmailExceptionToAdmin
	
} // end class