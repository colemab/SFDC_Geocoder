public with sharing class VF_Maps {

	// Parent wrapper class that lets the map display more than 1000 items
	transient public list<ParentMappingDataWrapper> AccountsToMap {get; set;}
	
	// The total number of items being displayed on the map from the SOQL query
	public integer TotalRows {get;set;}
	
	// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	// Vars for searching
	// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		// used in the map GUI to create the ObjectToFilter as needed
		public string ObjectTypeName {get; set;}
				
		// this will be used by the schema methods to find the fields to filter by
		public SObject ObjectToFilter {get;
			set {
				ObjectToFilter = value;
				
				// This is used communicate with lookup window
				this.CurrentObjectName = EncodingUtil.urlEncode(ObjectToFilter.getSObjectType().getDescribe().getName(), 'UTF-8');
				
				// now that we know what we are going to filter, we can provide a list of fields . . .
				PopulateFieldsList();
			} // end set
		} // ObjectToFilter
			
		// vars for describe / field list
		public Map<String, Schema.SObjectField> FieldsMap {get; set;}
		public List<SelectOption> FieldsSelectOptionList {get; set;}

		// vars for holding data from GUI
		public List<SOQLQueryFilterData> SOQLQueryFilterDataList {get; set;}
		
		// vars for advanced filter logic
		public boolean AdvancedFilterEnabled {get; set;} 
		public string AdvancedFilterCondition {get; set;}
		public string AdvancedFilterCondtionErrorMessage {get; set;}
		public boolean AdvancedFilterCondtionHasError {get; set;}
		
		// vars for custom lookup window - should be UTF-8 encoded to pass in the URL
		public string CurrentObjectName {get; set;}		
		
		// this is the sting that will be plugged into your SOQL where clause
		public string WhereConditionString {get;set;}
		
		// this is a list of the fields that exist in the where clause
		public List<String> FieldsList {get; set;}	
		
		// this is used to prevent trying to list the same field twice
		public Set<String> FieldsSet {
			get {
				FieldsSet = new Set<String>();
				FieldsSet.addAll(FieldsList);
				return FieldsSet;
			} 	
			set;
		}
		
		// this will translate the list into a comma delimited string
		public string FieldsListString {
			get {
				string returnValue = '';
				
				// build our comma+space delimited string
				for (string CurrentField: FieldsSet) {
					if (CurrentField != null) {
						returnValue += CurrentField + ', ';
					}
				} // loop thru FieldsList
				
				// trim any trailing delimiters
				returnValue = returnValue.removeEnd(', ');
				return ReturnValue;
			} // get
		} // FieldsListString
			
	// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		
	public VF_Maps () {
		
		// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		// Search testing

		FieldsSelectOptionList = new List<SelectOption>();
		SOQLQueryFilterDataList = new List<SOQLQueryFilterData>();

		AdvancedFilterEnabled = false;
		AdvancedFilterCondition = '';	
		AdvancedFilterCondtionErrorMessage = '';
		AdvancedFilterCondtionHasError = false;

		ObjectToFilter = new Account();
		ObjectTypeName = 'Account';
					
		// Make sure we have at least one option on the GUI . . . 		 		
		AddQueryFilterDataRow();
				
		// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
					
		system.debug('Calling Run Search . . . ');
		RunSearch();
				
	} // constructor VF_Maps
	 
	 // Collections (such as lists) are currently limited to 1k size in visual force
	 // to get around this limit we will use a list of lists via this wrapper class.
	 public class ParentMappingDataWrapper {	 	
	 	
	 	public list<MappingDataWrapper> ListofAccountsToMap {get; set;}
	 	
	 	public ParentMappingDataWrapper() {
	 		ListofAccountsToMap = new list<MappingDataWrapper>(); 
	 	} // constructor ParentMappingDataWrapper
	 	
	 } // class ParentMappingDataWrapper
	 
	 // This wrapper class allows the page to map to the generic variables 
	 // instead of tight binding to the actual fields returned by the SOQL search.  
	 public class MappingDataWrapper {
	 	
	 	public String Name {get;set;}
	 	public string Longitude {get;set;}
	 	public string Latitude {get;set;}
	 	public string Description {get;set;}	
	 	
	 	public MappingDataWrapper() {
	 		Name = '';
	 		Longitude = '';
	 		Latitude = '';
	 		Description = '';
	 	} // constructor MappingDataWrapper
	 	
	 } // class MappingDataWrapper
// ======================================================================================================

	// Create Sobject based on ObjectTypeName and store it in ObjectToFilter
	public void UpdateObjectToFilter() {
		ObjectToFilter = Schema.getGlobalDescribe().get(ObjectTypeName).newSObject() ;
	} // UpdateObjectToFilter


	public void ToggleAdvancedFilter() {
								
		AdvancedFilterEnabled = !AdvancedFilterEnabled;
				
		if (AdvancedFilterEnabled == false) {
			AdvancedFilterCondition = '';
			BuildQueryString();
		} // AdvancedFilterEnabled == false
						
	} // ToggleAdvancedFilter
	
	public void AddQueryFilterDataRow() {
		// this is a reference to the parent controller and is being passed in
		// to prevent from having to make describe calls to the schema again.
		SOQLQueryFilterData Row = new SOQLQueryFilterData(this);
		SOQLQueryFilterDataList.add(Row);
		
		BuildQueryString();				
	} // AddQueryFilterDataRow

	public void RemoveQueryFilterDataRow() {
		
		if (SOQLQueryFilterDataList.size() > 1) {
			// remove the last row
			SOQLQueryFilterDataList.remove(SOQLQueryFilterDataList.size()-1);
		} // SOQLQueryFilterDataList.size > 1
		
		BuildQueryString();
					
	} // RemoveQueryFilterDataRow
	
	private void PopulateFieldsList() {
		// This function will look at the SObject that was passed in
		// and create a selectoption list of those fields for the GUI
	
		FieldsSelectOptionList.clear();
				
		// Returns a map of all sObject names (keys) to sObject tokens (values) for the standard and custom objects defined in your organization.
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 

		// Get the Object Type from the Map dynamically by using the object type name		
		Schema.SObjectType CurrentType = gd.get(ObjectToFilter.getSObjectType().getDescribe().getName());

		// populate our map with names and labels		
		FieldsMap = CurrentType.getDescribe().fields.getMap();
	 	
	 	// Take that Map and populate a selectOption List with those that the user can access 	
		for(string CurrentKey : FieldsMap.keySet()) {
			
			// only show fields that the user can see
			if (FieldsMap.get(CurrentKey).getDescribe().isAccessible()) {			
			
				// only add fields that can be part of a WHERE clause
				if (FieldsMap.get(CurrentKey).getDescribe().isFilterable() == true) {
					String CurrentLabel = FieldsMap.get(CurrentKey).getDescribe().getLabel();														
					FieldsSelectOptionList.add(new SelectOption(CurrentKey,CurrentLabel));
				} // field is filterable
								
			} // field is accessible
						
		} // loop thru UpdateFieldsMap key set							
						
		// now sort the select list via label
		FieldsSelectOptionList = SortSelectOptions.selectOptionSortByLabel(FieldsSelectOptionList);
		
		// Add a none option to force the user to select a field
		// this is so the operator list can be filter by the field type
		// which will be set once the user makes a selection
		FieldsSelectOptionList.add(0,new SelectOption('','--None--'));
									
	} // PopulateFieldsList

	public void ValidateAdvancedFilterString() {
		
		// assume we will have an error . . .
		AdvancedFilterCondtionHasError = true;
				
		if (AdvancedFilterEnabled == true) {
			// if the user didn't specify any condition then use the default 
			if (AdvancedFilterCondition == '') {
				AdvancedFilterCondtionErrorMessage = 'Filter logic is required when enabled.';
				return;				
			} // AdvancedFilterCondition == ''
			
			// someone forgot to close a parentheses or forgot to open one
			if (AdvancedFilterCondition.countMatches('(') != AdvancedFilterCondition.countMatches(')')) {
				AdvancedFilterCondtionErrorMessage = 'All parentheses must be closed and opened.';
				return;
			} // check for ( and ) count being equal
			
			// tokenize the AdvancedFilterCondition via spaces
			list<string> AdvancedFilterConditionTokens = AdvancedFilterCondition.split(' ');
			
			boolean LastTokenWasNumeric = true;
			
			for (integer x=0; x<AdvancedFilterConditionTokens.size(); x++) {
				string CurrentToken = AdvancedFilterConditionTokens.get(x);
				
				// if the user doesn't put a space between parentheses,
				// we need to remove parentheses to get a truley numeric value
				string CurrentTokenNumeric = CurrentToken.remove('(');
				CurrentTokenNumeric = CurrentTokenNumeric.remove(')');
								
				if (CurrentTokenNumeric.isNumeric()) {

					// filter logic is made up of field numbers and union statements AND, OR
					// if two field numbers are back to back, the logic is invalid					
					if (LastTokenWasNumeric == true && x!=0) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;												
					} // LastTokenWasNumeric == true
					
					// the tokens will start at 1 but the clause will start a 0
					integer CurrentClause = integer.valueof(CurrentTokenNumeric)-1;
					integer MaxClause = SOQLQueryFilterDataList.size()-1;
										
					// the user tried to add a number but the array isn't that large					
					if (MaxClause < CurrentClause) {						
						AdvancedFilterCondtionErrorMessage = 'The filter logic references an undefined filter: ' + CurrentTokenNumeric;
						return;
					} // SOQLQueryFilterDataList.size > CurrentClause
					
					LastTokenWasNumeric = true;																
				} else {
					// filter logic is made up of field numbers and union statements AND, OR
					// if two union statements are back to back, the logic is invalid
					if (LastTokenWasNumeric == false) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;						
					} // LastTokenWasNumeric == false
					
					// Check for invalid placement of NOT 
					if (CurrentTokenNumeric.toUpperCase() == 'NOT' && x!=0) {
						AdvancedFilterCondtionErrorMessage = 'The NOT operator is only valid at the start filter logic.';
						return;													
					} // check for NOT but not in first clause
					
					// AND/OR/NOT are the only valid operators
					if (CurrentTokenNumeric.toUpperCase() != 'OR' && CurrentTokenNumeric.toUpperCase() != 'AND' && CurrentTokenNumeric.toUpperCase() != 'NOT') {
						AdvancedFilterCondtionErrorMessage = 'Check the spelling in your filter logic.';
						return;																			
					} // check for AND/OR/NOT 

					// the filter logic cannot end with an operator					
					if (x+1==AdvancedFilterConditionTokens.size()) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;												
					} // x==AdvancedFilterConditionTokens.size()
					
					LastTokenWasNumeric = false; 
				} // CurrentToken.isNumeric()
				
			} //CurrentToken: AdvancedFilterConditionTokens
						
		} // AdvancedFilterEnabled == true
		
		// clear any previous error messages on each run
		AdvancedFilterCondtionErrorMessage = '';		
		// this is used by the build string function to avoid building an invalid string
		AdvancedFilterCondtionHasError = false;
		
	} //ValidateAdvancedFilterString 
	
	public void PopulateFieldList() {
		
		FieldsList = new List<String>();
		
		for (SOQLQueryFilterData CurrentFilterData : SOQLQueryFilterDataList) {
			FieldsList.add(CurrentFilterData.FieldName);
		} // loop thru wrapper objects
		
	} // PopulateFieldList
	
	public void RunSearch() {
		
		AccountsToMap = new list<ParentMappingDataWrapper>();
		
		BuildQueryString();
		WhereConditionString = WhereConditionString;
		system.debug('WhereConditionString = ' + WhereConditionString);
		
		string SOQLQueryFieldsString = 'SELECT '; 
		string SOQLQueryFromString = 'FROM ' + ObjectTypeName + ' ';
		string SOQLQueryWhereString = 'WHERE ';
		
		if (ObjectTypeName == 'Account') { 
			SOQLQueryFieldsString += 'ID, Name, DC_GG__BillingGeoCodeData__Longitude__s, DC_GG__BillingGeoCodeData__Latitude__s, '; 
			SOQLQueryFieldsString += 'BillingStreet, BillingCity, BillingState, BillingPostalCode ';	
			SOQLQueryWhereString += 'DC_GG__BillingGeoCodeData__Longitude__s != null AND DC_GG__BillingGeoCodeData__Latitude__s !=null ';			 
			SOQLQueryWhereString += 'AND (DC_GG__BillingGeoCodeData__Longitude__s != 0 AND DC_GG__BillingGeoCodeData__Latitude__s !=0) ';
		} else {
			SOQLQueryFieldsString += 'ID, Account.ID, Account.Name, Account.DC_GG__BillingGeoCodeData__Longitude__s, Account.DC_GG__BillingGeoCodeData__Latitude__s, '; 
			SOQLQueryFieldsString += 'Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode ';				
			SOQLQueryWhereString += 'Account.DC_GG__BillingGeoCodeData__Longitude__s != null AND Account.DC_GG__BillingGeoCodeData__Latitude__s !=null ';
			SOQLQueryWhereString += 'AND (Account.DC_GG__BillingGeoCodeData__Longitude__s != 0 AND Account.DC_GG__BillingGeoCodeData__Latitude__s !=0) ';			
		} // ObjectTypeName == Account
		
		if (!String.isBlank(WhereConditionString)) {
			system.debug('SOQLQueryFilterDataList.size = ' + SOQLQueryFilterDataList.size());
			
			// if the query only has one condition, the parentheses would cause a QueryException to be thrown
			if(SOQLQueryFilterDataList.size() > 1) {
				SOQLQueryWhereString += ' AND (' + WhereConditionString + ')';	
			} else {
				SOQLQueryWhereString += ' AND ' + WhereConditionString;
			} // if(SOQLQueryFilterDataList.size() > 1) {
			
		} // if (!String.isBlank(WhereConditionString)) {

		// The where string gets escapesinglequotes called in the SOQLQueryFilterData class to prevent SOQL injection
		string SOQLQueryString = SOQLQueryFieldsString + SOQLQueryFromString + SOQLQueryWhereString;  
		string SOQLSizeQueryString = 'Select count()' + SOQLQueryFromString + SOQLQueryWhereString;
		
		system.debug('SOQLSizeQueryString = ' + SOQLSizeQueryString);
						
		TotalRows = database.countQuery(SOQLSizeQueryString);
		system.debug('TotalRows = ' + TotalRows);
		
		integer OffsetIncrement = 1000; // this is the current limit for visual force collections

		// query for all of the objects			
		List<sObject> CurrentAccounts = database.query(SOQLQueryString);			
		system.debug('Inital CurrentAccounts.size() = ' + CurrentAccounts.size());
		
		integer CurrentRecordCount = 0;

		// create a new parent wrapper to hold a list of the actual wrappers
		ParentMappingDataWrapper CurrentParentWrapper = new ParentMappingDataWrapper(); 
		
		
		// loop thru all of the records		
		for (sObject CurrentRecord: CurrentAccounts) {
		
			// Create a new wrapper for this record	
			MappingDataWrapper CurrentWrapper = new MappingDataWrapper();
			
			// populate the wrapper details
			if (ObjectTypeName == 'Account') {
				Account A = (Account)CurrentRecord;
				CurrentWrapper.Name = A.Name;
				CurrentWrapper.Longitude = string.valueOf(A.DC_GG__BillingGeoCodeData__Longitude__s);
				CurrentWrapper.Latitude = string.valueOf(A.DC_GG__BillingGeoCodeData__Latitude__s);
				//CurrentWrapper.Description = '<div id=\"content\"><h1 id=\"firstHeading\" class=\"firstHeading\"><a href=\"/' + A.id + '\" target=\"_blank\">' + A.Name + '</a></h1><div id=\"bodyContent\">' + A.BillingStreet + '<br/>' + A.BillingCity + ', ' +  A.BillingState + ' ' +  A.BillingPostalCode + '</div></div>';

				CurrentWrapper.Description = '<div id=\"content\"><h1 id=\"firstHeading\" class=\"firstHeading\"><a href=\"/' + A.id + '\" target=\"_blank\">' + A.Name + '</a></h1><div id=\"bodyContent\">';				
				if (A.BillingStreet!= null) CurrentWrapper.Description += A.BillingStreet + '<br/>';
				if (A.BillingCity!= null) CurrentWrapper.Description += A.BillingCity + ', ';
				if (A.BillingState!= null) CurrentWrapper.Description += A.BillingState + ' ';
				if (A.BillingPostalCode!= null) CurrentWrapper.Description += A.BillingPostalCode;
				CurrentWrapper.Description += '</div></div>';										
									
			} else {
				Opportunity A = (Opportunity)CurrentRecord;
				CurrentWrapper.Name = A.Account.Name;
				CurrentWrapper.Longitude = string.valueOf(A.Account.DC_GG__BillingGeoCodeData__Longitude__s);
				CurrentWrapper.Latitude = string.valueOf(A.Account.DC_GG__BillingGeoCodeData__Latitude__s);

				CurrentWrapper.Description = '<div id=\"content\"><h1 id=\"firstHeading\" class=\"firstHeading\"><a href=\"/' + A.id + '\" target=\"_blank\">' + A.Account.Name + '</a></h1><div id=\"bodyContent\">';				
				if (A.Account.BillingStreet!= null) CurrentWrapper.Description += A.Account.BillingStreet + '<br/>';
				if (A.Account.BillingCity!= null) CurrentWrapper.Description += A.Account.BillingCity + ', ';
				if (A.Account.BillingState!= null) CurrentWrapper.Description += A.Account.BillingState + ' ';
				if (A.Account.BillingPostalCode!= null) CurrentWrapper.Description += A.Account.BillingPostalCode;
				CurrentWrapper.Description += '</div></div>';										
			}
			
			
			// increment the counter and add the wrapper to the current parent
			CurrentRecordCount++;			
			CurrentParentWrapper.ListofAccountsToMap.add(CurrentWrapper);
			
			// when the limit is hit
			if (CurrentRecordCount == OffsetIncrement) {
				// add the parent wrapper to the list of lists
				AccountsToMap.add(CurrentParentWrapper);
				
				// create a new parent wrapper
				CurrentParentWrapper = new ParentMappingDataWrapper();
				
				// reset the counter					
				CurrentRecordCount = 0;
			}
		} // loop thru all records
										
		// add the last list to the wrapper
		AccountsToMap.add(CurrentParentWrapper);
		
	} // RunSearch
	
	public void BuildQueryString() {
			string SOQLWhereClause = ' ';
			
			// if no advanced query, everything is AND
			if (AdvancedFilterEnabled == false) {
				// loop thru our wrapper objects to build our WHERE clause
				for (SOQLQueryFilterData CurrentFilterData : SOQLQueryFilterDataList)
				{					
					
					if (CurrentFilterData.SOQLClause.length() > 0) {
						// Each wrapper class builds its own string, so we just assemble them here . . . 
						// Each wrapper escapes the value from the GUI to prevent SOQL injections . . . 
						SOQLWhereClause += CurrentFilterData.SOQLClause + ' AND ';						
					} // CurrentFilterData.SOQLClause != null
					
				} // loop thru SOQLQueryFilterDataList
				
				// remove any trailing and . . . 
				SOQLWhereClause = SOQLWhereClause.removeEnd(' AND ');
			} else {
								 
				// this call will set AdvancedFilterCondtionHasError 
				ValidateAdvancedFilterString();
				
				if (AdvancedFilterCondtionHasError == false) {
								
					// tokenize the AdvancedFilterCondition via spaces
					list<string> AdvancedFilterConditionTokens = AdvancedFilterCondition.split(' ');
					
					for (integer x=0; x<AdvancedFilterConditionTokens.size(); x++) {
						string CurrentToken = AdvancedFilterConditionTokens.get(x);
						
						// if the user doesn't put a space between parentheses,
						// we need to remove parentheses to get a truley numeric value
						string CurrentTokenNumeric = CurrentToken.remove('(');
						CurrentTokenNumeric = CurrentTokenNumeric.remove(')');
						
						if (CurrentTokenNumeric.isNumeric()) {
							// the tokens will start at 1 but the clause will start a 0
							integer CurrentClause = integer.valueof(CurrentTokenNumeric)-1;
							
							// Replace is used here so that any parentheses are kept
							CurrentToken = CurrentToken.replace(CurrentTokenNumeric,SOQLQueryFilterDataList.get(CurrentClause).SOQLClause); 
													
							AdvancedFilterConditionTokens.set(x,CurrentToken);
						} // CurrentToken.isNumeric()
					} //CurrentToken: AdvancedFilterConditionTokens
					
					// re-assemble our tokens
					SOQLWhereClause = string.join(AdvancedFilterConditionTokens, ' ');
				} // AdvancedFilterCondtionHasError == false
				 				
			} // if (AdvancedFilterEnabled == false) 						
							
			// since components can only pass data back via objects and not primitives
			// put the string in a wrapper class instance so the object can send data back
											
			if (SOQLWhereClause != null) { // avoid nullpointer exception during init
				WhereConditionString = SOQLWhereClause;
				PopulateFieldList();
			} // SOQLWhereClause != null
					
	} // BuildQueryString	 

	 	 
} // class VF_Maps