public class SOQLQueryFilterData {
		
		// this wrapper class will hold the field, operator and value for each critera
		// this wrapper class will be held in an array in the main class for iteration
		
		// used to share (mainly schema) data between controller and this inner class
		private VF_Maps ParentController; 		
		
		public Schema.SObjectField CurrentField {get; set;} 
		public Schema.DisplayType CurrentFieldType {get; set;}
		
		public string FieldName {get; 
			
			set{ 
				// whenever the field gets set, we want to limit the operator list
				// to prevent errors and/or invalid SOQL from being returned

				FieldName = value;
				
				if (ParentController.FieldsMap != null) {
					// Pull the current field from the map
					CurrentField = ParentController.FieldsMap.get(value);
								
					if (CurrentField != null) {								
						// Use a describe call to get the type back (an enum value is returned)
						CurrentFieldType = CurrentField.getDescribe().getType();
					} // CurrentField != null
					
					// Set the Operator List to valid options for the current type
					PopulateOperatorList();
				} // FieldsMap != null
			} // set method for Field Name
		} // Field Name
		
		// the field name is UTF8 encoded for use with the lookupwindow
		public string FieldNameUTF8 {
			get {
				return EncodingUtil.urlEncode(FieldName,'UTF-8');
			} // get
		} // FieldNameUTF8
		
		public string Operator {get; set;}
		 
		public string Value  {
			get {
				if (value == null) value='';
				return value;
			} 
			set;
		} // Value String 
		
		// vars for use when time fields are used in the GUI
		public string Hour {get; set;}
		public string Minute {get; set;}
		public string AMPM {get; set;}
		
		public List<SelectOption> HourList {get; set;}
		public List<SelectOption> MinuteList {get; set;}
		public List<SelectOption> AMPMList {get; set;}
		
		// var for displaying CustomLookupWindow on fields that can use it
		public boolean RenderLookupIcon {get;set;}
		// var for displaying date picker icon on date fields
		public boolean RenderDatePickerIcon {get;set;}
		
		// Future Development: var for displaying date/time picker on date/time fields
		public boolean RenderDateTimePickerIcon {get;set;}
				
		// InputValue is passed in so that BuildMultipleSOQLSOQLClause can use this method too
		private string BuildSingleSingleClause(string InputValue) {
				string ReturnValue = '';
								
				// escape quotes here to prevent SOQL injection while hiding them from the GUI
				string EscapedValue = string.escapeSingleQuotes(InputValue);
				
				// If a user added a row but didn't give us a value, don't try to build a string
				// Also, if a user left the field defaulted to --None-- then don't try to build a string
				if (FieldName != null && Operator != null && EscapedValue != null) {
				
					// This is a special operator that puts text before the field
					if (Operator == 'DOES NOT CONTAIN') {
						// be sure to wrap this operator in parentheses or you will have problems
						// when you have mutiple conditions
						ReturnValue += '( NOT ';
					} // DOES NOT CONTAIN
					
					ReturnValue += FieldName + ' ';
									
					// the like based operators need to be transformed into LIKE
					if (Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN' || Operator == 'STARTS WITH') {
						ReturnValue += 'LIKE ';
					} else {
						// all the other operators can be directly plugged in
						ReturnValue += Operator + ' ';
					} // check for operator being like based
									
					// now add in the value - adding quotes to those that require it
					if (
							CurrentFieldType == Schema.Displaytype.Email ||					
							CurrentFieldType == Schema.Displaytype.ID ||
							CurrentFieldType == Schema.Displaytype.MultiPickList ||
							CurrentFieldType == Schema.Displaytype.Phone ||
							CurrentFieldType == Schema.Displaytype.PickList ||
							CurrentFieldType == Schema.Displaytype.Reference ||
							CurrentFieldType == Schema.Displaytype.String ||
							CurrentFieldType == Schema.Displaytype.URL 
					   ) 
					{
						// the like based operators need to have the % added in
						if (Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN') {
							ReturnValue += '\'%' + EscapedValue + '%\' ';
						} else if (Operator == 'STARTS WITH') {
							ReturnValue += '\'' + EscapedValue + '%\' ';
						} else {
							// just add the quotes in
							ReturnValue += '\'' + EscapedValue + '\' ';											
						} // Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN'
					} else {												
						// for those that don't require a quote, just plug in the value
						ReturnValue += EscapedValue + ' ';
					} // check to see if quotes are required

					if (Operator == 'DOES NOT CONTAIN') {
						// be sure to wrap this operator in parentheses or you will have problems
						// when you have mutiple conditions
						ReturnValue += ')';
					} // DOES NOT CONTAIN
								
				} // check for null values
				
				return ReturnValue;
			
		} // BuildSingleSOQLSOQLClause
		
		// the input string is passed in to allow the value to be different from
		// the value on the row / data wrapper instance (i.e. reformat dates in the background)		
		private string BuildMultipleSOQLSOQLClause(string InputValue) {
			string ReturnValue = '';
			
			List<string> ParsedValuesList = new List<string>();
			
			if (InputValue.containsAny('"')) {
				// since values could contain double quotes and commas, we need to parse twice
				// once for the double quote and again for the comma
				List<string> QuoteParsedValuesList = InputValue.split('"');
				
				for (string S:QuoteParsedValuesList) {
					
					if (S.startsWith(', ') || S.endsWith(', ')) {
						S = S.removeStart(', ');
						S = S.removeEnd(', ');
					}	
					
					// escape the string to prevent SOQL injection
					S =  string.escapeSingleQuotes(S);
										
					ParsedValuesList.add(S);
					
				} // for (string S:QuoteParsedValuesList)
			} else {
				// this is a normal comma delimited parse
				ParsedValuesList = InputValue.split(', ');
			} // if InputValue.containsAny('"')
									
			if (Operator == '=' || Operator == 'IN' || Operator == '!=' || Operator == 'NOT IN') {

				if (Operator == '=' || Operator == 'IN') {
					ReturnValue = FieldName + ' IN (';
				}else if (Operator == '!=' || Operator == 'NOT IN') {
					ReturnValue = FieldName + ' NOT IN (';
				} // Operator == 'equals' || Operator == 'in'
			
				// add delimiters for the SOQL query
				for (string CurrentValue: ParsedValuesList) {			
					ReturnValue += '\'' + CurrentValue + '\',';					
				} // for (string CurrentValue: ParsedValuesList) 
				
				// remove any trailing commas
				if (ReturnValue.endsWith(',')) ReturnValue = ReturnValue.removeEnd(',');
			
				// add closing Parenthesis
				ReturnValue += ')'; 
			
			} else { 	// for contains, does not contain, and starts with

				// default to OR for Contains and starts with
				string CurrentCondition = ' OR ';

				// change to AND as needed (currently only for does not contain)
				if (Operator == 'DOES NOT CONTAIN') {
					CurrentCondition = ' AND ';
				} // if (Operator == 'DOES NOT CONTAIN') {

				for (string CurrentValue: ParsedValuesList) {
					ReturnValue += BuildSingleSingleClause(CurrentValue) + CurrentCondition;					
				} // for (string CurrentValue: ParsedValuesList) {

				// remove any trailing condition
				if (ReturnValue.endsWith(CurrentCondition)) ReturnValue = ReturnValue.removeEnd(CurrentCondition);

				// surround with Parentheses just in case this is parter of a larger expression					
				ReturnValue = ' (' + ReturnValue + ' )'; 
				
			} // Operator == '=' || Operator == 'IN' || Operator == '!=' || Operator == 'NOT IN'
						
			return ReturnValue; 
		} // BuildMultipleSOQLSOQLClause
		
		
		// each instance of the wrapper class builds its SOQL here
		public string SOQLClause {
			get {
				
				string FormatedValue = value;
				
				if (!String.isEmpty(value)) {
					try {
						if (CurrentFieldType == Schema.Displaytype.Date) {
							date InputDate = date.parse(value);
							// change the format for the query to standard YYYY-MM-DD format
							FormatedValue = String.valueOf(InputDate);
						} else if (CurrentFieldType == Schema.Displaytype.DateTime) {
							
							string TempDateTime = value + ' ' + Hour + ':' + Minute + ' ' + AMPM;							
							system.debug('>>>> TempDateTime = ' + TempDateTime);
							
							datetime InputDateTime = datetime.parse(TempDateTime);
							
							// change the format to the standard YYYY-MM-DDTHH.mm.ss.000Z format
							FormatedValue = InputDateTime.formatGMT('yyyy-MM-dd') + 'T' + InputDateTime.formatGMT('HH:mm:ss.SSS') + 'Z';
							
						} // check for values that need to be reformatted
					} catch (exception e) {
						FormatedValue = value;
					} // try & catch					
				} // check for blank value
										
				// if the lookup icon was rendered AND the value contains a comma then process as mutiple values
				// when mutiple values are provided by the lookup window, they will be comma delimited
				// if an individual value contains a comma, it will be wrapped in double quotes
				if (RenderLookupIcon == true && value.containsAny(',')) {
					return BuildMultipleSOQLSOQLClause(FormatedValue);
				} else {						
					return BuildSingleSingleClause(FormatedValue);
				}
							
			} // get 
		} // SOQL Clause
		
		// This list is in the wrapper class so that we can adjust
		// the list as needed for each row (i.e. no greater than for a picklist)
		public List<SelectOption> OperatorList {get; set;}
				
		public SOQLQueryFilterData(VF_Maps ParentController) {
						
			this.ParentController = ParentController;
			
			OperatorList = new List<SelectOption>();
			
			HourList = new List<SelectOption>();
			MinuteList = new List<SelectOption>();
			AMPMList = new List<SelectOption>();
			
			RenderLookupIcon = false;
			RenderDatePickerIcon = false;
			RenderDateTimePickerIcon = false;
			
			// fill the list with the default values ....
			PopulateOperatorList();
			
		} // constructor
		
		private void UpdateRenderLookupIcon() {
			// for now, this only display's for picklist and Name Fields
			if (
				(CurrentFieldType == Schema.Displaytype.PickList) || 
					(CurrentFieldType == Schema.Displaytype.String) && (CurrentField.getDescribe().getName() == 'Name') 
				) 
			{
					
				RenderLookupIcon = true;
			} else {
				RenderLookupIcon = false;
			}
		} // UpdateRenderLookupIcon
		
		private void UpdateRenderDatePickerIcon() {
			// Only display this for date fields
			if (CurrentFieldType == Schema.Displaytype.Date) 				
			{					
				RenderDatePickerIcon = true;
			} else {
				RenderDatePickerIcon = false;
			} // check for date field
			
		} // UpdateRenderDatePickerIcon

		// Future Development: Toggle javascript / icon for date / time picker
		private void UpdateRenderDateTimePickerIcon() {
			// Only display this for date/time fields
			if (CurrentFieldType == Schema.Displaytype.DateTime) 				
			{					
				// Display both the date and date/time picker
				RenderDateTimePickerIcon = RenderDatePickerIcon = true;
				PopulateTimesLists();
			} else {
				// hide just the datetime picker - date picker takes care of itself!
				RenderDateTimePickerIcon = false;
			} // check for date/time field
						
		} // UpdateRenderDateTimePickerIcon
		
		private void PopulateTimesLists() {

			PopulateHoursList();
			PopulateMinutesList();
			PopulateAMPMList();

		} // PopulateTimesLists
		
		private void PopulateHoursList() {
			
			HourList.clear();
			
			for (integer x = 1; x <= 12; x++) {				
			
				HourList.add(new SelectOption(String.ValueOf(x), String.ValueOf(x)));
			
			} // loop to 12
												
		} // PopulateHoursList
		
		private void PopulateMinutesList() {
			
			MinuteList.clear();
			
			for (integer x = 0; x < 60; x++) {	
				
				// zero pad any single digits to be 2 digits
				string CurrentMinute = String.ValueOf(x);
				if (CurrentMinute.length() == 1) CurrentMinute = '0' + CurrentMinute;
				
				MinuteList.add(new SelectOption(CurrentMinute, CurrentMinute));
				
			} // loop to 59
			
		} // PopulateMinutesList
		
		private void PopulateAMPMList() {
			
			AMPMList.clear();
			
			AMPMList.add(new SelectOption('AM', 'AM'));
			
			AMPMList.add(new SelectOption('PM', 'PM'));
			
		} // PopulateAMPMList
				
		private void PopulateOperatorList() {
			
			// reset the list each time to prevent duplicates			
			OperatorList.Clear();
						
			// add our universal comparsion operators
			OperatorList.add(new SelectOption('=','equals'));
			OperatorList.add(new SelectOption('!=','not equal to'));
			OperatorList.add(new SelectOption('IN','in'));
			OperatorList.add(new SelectOption('NOT IN','not in'));
			
			// Now add our Double, Date, Date/Tme Operators						
			if (
					CurrentFieldType == Schema.Displaytype.Currency ||
					CurrentFieldType == Schema.Displaytype.Date ||
					CurrentFieldType == Schema.Displaytype.DateTime ||					
					CurrentFieldType == Schema.Displaytype.Double ||
					CurrentFieldType == Schema.Displaytype.Integer ||
					CurrentFieldType == Schema.Displaytype.Percent 
			   ) 
			{
				OperatorList.add(new SelectOption('<','less than'));
				OperatorList.add(new SelectOption('>','greater than'));		
				OperatorList.add(new SelectOption('<=','less or equal'));
				OperatorList.add(new SelectOption('>=','greater or equal'));
			} // Add Double, Date, Date/time Operators
			
			// Now add LIKE Operator for strings that support it
			if (
					CurrentFieldType == Schema.Displaytype.Email ||					
					CurrentFieldType == Schema.Displaytype.Phone ||
					CurrentFieldType == Schema.Displaytype.PickList ||
					CurrentFieldType == Schema.Displaytype.String ||
					CurrentFieldType == Schema.Displaytype.URL 
			   ) 
			{
				
				OperatorList.add(new SelectOption('CONTAINS','contains'));
				OperatorList.add(new SelectOption('DOES NOT CONTAIN','does not contain'));
				OperatorList.add(new SelectOption('STARTS WITH','starts with'));
				
			} // Add LIKE Operator
			
			/* TO BE IMPLEMENTED LATER:  
				Please note this will require modification of SOQLClause's getter method to implement
							
				//Now add EXCLUDES and INCLDUES for MultiPickLists
				if (CurrentFieldType == Schema.Displaytype.MultiPickList) 
				{
					// Note that EXCLUDES and INCLUDES require a comma delimited list wrapped in Parentheses (much like in / not in)
					OperatorList.add(new SelectOption('EXCLUDES','excludes'));
					OperatorList.add(new SelectOption('INCLUDES','includes'));				
				} // Add EXCLUDES & INCLUDES Operators
			
			*/
			
			// display the lookup icon as needed
			UpdateRenderLookupIcon();
			
			// attach the date picker as needed
			UpdateRenderDatePickerIcon();		
			
			// attach the date/time picker as needed
			UpdateRenderDateTimePickerIcon();
				
		} // PopulateOperatorList
		
	} // class SOQLQueryFilterData