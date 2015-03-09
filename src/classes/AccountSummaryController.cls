public class AccountSummaryController {
    public Map<String, Schema.SObjectType> GlobalDescribeMap {get;set;} //Global Describe
    public List<wrapDummyAndField> fieldsWrapper {get;set;} //Wrap fields
    public List<wrapDummyAndField> searchWrapper {get;set;} //Wrap search context
    public Boolean isSelectAll { get;set; }
    public Integer numberOfInactiveOwners  { get;set; }
    
    public ApexPages.StandardSetController con { get;set; }   
    public List<WrapObjAndChild> objectList{ get;set; }
    
    public String objectSoql { get;set ; }
    public String specialQueryMode { get;set; }
    public String specialQuery { get;set; }
    public String specialQueryText { get;set; }
    public Boolean disableSpecialQueryMode { get;set; }
    public List<String> validAccountIds { get;set; }
    public Integer dayRange { get;set; }
    
    public static Integer offSetAmount = 300;

    //Wrap Object, Related List, and Selected
    public class WrapObjAndChild{
        public sObject Obj {get;set;}  
        public List<String> RelatedList {get;set;}  
        public boolean selected { get;set; }
 
        public WrapObjAndChild(sObject O , List<String> R) {
            Obj = O ;
            RelatedList = R ;
            selected = false;
       
        }
        public WrapObjAndChild(sObject O ) {
            Obj = O ;
            RelatedList = null ;
            selected = false;
       
        }
    }
    //Wrap a search String object with a field
    public class wrapDummyAndField{
        public String fieldApiName { get;set; }
        public String fieldLabel { get;set; }
        public String fieldType { get;set; }
        public Boolean isSortable { get;set; }
        public String stringValue { get;set; }
        
        //Used if the field Type is Date
        public Date startDate { get;set; }
        public Date endDate { get;set; }

        //Picklist Options of field is picklist
        public List<selectOption> options { get;set; }

        public wrapDummyAndField( String A, String B, String C , Boolean S) {
            fieldApiName = A;
            fieldLabel = B;
            stringValue = '';
            fieldType = C;
            isSortable = S;
            if( C == 'BOOLEAN'){
                options = new List<selectOption>();
                options.add(new selectOption( 'null', '-'));
                options.add(new selectOption('True', 'True')); 
                options.add(new selectOption('False', 'False')); 
            }
        }
        public wrapDummyAndField( String A, String B, String C, List<Schema.PicklistEntry> D, Boolean S) {
            fieldApiName = A;
            fieldLabel = B;
            stringValue = '';
            fieldType = C;
            isSortable = S;
            options = new List<selectOption>();
            options.add(new selectOption( 'null', '-'));
            for( Schema.PicklistEntry ple : D ){
                options.add(new selectOption( ple.getValue(), ple.getLabel() )); 
            }
        }
    }

    //Create selectOptions for True False picklists
    public List<selectOption> getEnabledSelectOptions() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options
        options.add(new selectOption('null', 'All')); 
        options.add(new selectOption('True', 'True')); 
        options.add(new selectOption('False', 'False')); 
        return options; //return the picklist options
    }

    //Constructor
    public AccountSummaryController(){
        init();
        GlobalDescribeMap = Schema.getGlobalDescribe();

    }

    //Init function
    public void init(){
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
            dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
        }    
        disableSpecialQueryMode = false;
            
        setFields();   
        runFullSearch();  
    } 

    //Sets the fields from custom settings
    public void setFields() {
         Set<String> includeFields = new Set<String>();
         Reporting_Setting__c reportingSetting;
         
         //Look for Org Settings first
         try{
             reportingSetting = [ SELECT Value__c FROM Reporting_Setting__c WHERE Organization_Level__c = true AND Type__c = 'Account View' AND Category__c = 'Display Fields' ];
         } catch( exception e){
             System.debug( ' No Personal Settings' );
         }
         //Override to User Level if possible
         try{
             reportingSetting = [ SELECT Value__c FROM Reporting_Setting__c WHERE User__c = : UserInfo.getUserId() AND Type__c = 'Account View' AND Category__c = 'Display Fields' ];
         } catch( exception e){
             System.debug( ' No Personal Settings' );
         }
         
         //Default just to Name
         if( reportingSetting == null ){
             reportingSetting = new Reporting_Setting__c ( Value__c = 'Name' );
         }
         
         List<String> tempfieldNames = new List<String>();
         
         if( reportingSetting.Value__c != null )
             tempfieldNames = reportingSetting.Value__c.split(',');
         else{
             tempFieldNames.add( 'Name' );
         }
         
         
         Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.Account.fields.getMap();
         
         
         searchWrapper = new List<wrapDummyAndField>();
         fieldsWrapper = new List<wrapDummyAndField>();
         
         for( String fName : tempfieldNames ){
             Schema.DescribeFieldResult describeResult= schemaFieldMap.get( fName).getDescribe();
            //Only add filterable fields to search wrapper
            if( describeResult.isFilterable() ){
                if(  schemaFieldMap.get( fName).getDescribe().getType().Name() == 'PICKLIST' ){
                    searchWrapper.add(new wrapDummyAndField( fName, describeResult.getLabel(), schemaFieldMap.get( fName).getDescribe().getType().Name() , describeResult.getPicklistValues(), schemaFieldMap.get( fName).getDescribe().isSortable() ));  
                }   
                else{
                    searchWrapper.add(new wrapDummyAndField( fName, describeResult.getLabel(), schemaFieldMap.get( fName).getDescribe().getType().Name() , describeResult.isSortable()));  
                }   
            }
            if(  describeResult.getType().Name() == 'PICKLIST' ){
                fieldsWrapper.add(new wrapDummyAndField( fName, describeResult.getLabel(), schemaFieldMap.get( fName).getDescribe().getType().Name() , describeResult.getPicklistValues(), schemaFieldMap.get( fName).getDescribe().isSortable() ));  
            }   
            else{
                fieldsWrapper.add(new wrapDummyAndField( fName, describeResult.getLabel(), schemaFieldMap.get( fName).getDescribe().getType().Name() , describeResult.isSortable()));  
            }
         }   
         
         tempFieldNames.add( 'Owner.isActive' );
         fieldsWrapper.add(new wrapDummyAndField( 'Owner.isActive', 'Has Active Owner', 'BOOLEAN' , true));  
         searchWrapper.add(new wrapDummyAndField( 'Owner.isActive', 'Has Active Owner', 'BOOLEAN', true));                      
    }  

    //Goes through the search steps
    public void runFullSearch(){
            setBaseSoql();
            setFilterSoql();
            setSpecialSoql();
            setSpecialSoqlMode();
            setObjectList();
    }
    //Sets the base soql statement
    public void setBaseSoql(){
        objectSoql = 'SELECT id';
        
        for( wrapDummyAndField w : fieldsWrapper ){
            objectSoql += ', ' + w.fieldApiName;
            if( w.fieldType == 'Reference' && w.fieldApiName.substring(w.fieldApiName.length() - 3, w.fieldApiName.length()) == '__c' ){
                objectSoql += ','+w.fieldApiName.substring(0,W.fieldApiName.length()-1)+'r.name';
            }
        }

        objectSoql+= ' FROM Account ';     
    }

    //Adds filter to the soql statement based on search box
    public void setFilterSoql(){
        //ADD WHERE STATEMENTS TO objectSoql
        objectSoql+=' WHERE id != null ';
        String nextText = 'AND ';

        for(wrapDummyAndField F : searchWrapper) {
            if( F.stringValue != null && f.stringValue != ''){
                if(F.fieldType == 'Reference' && f.fieldApiName.substring(f.fieldApiName.length() - 3, f.fieldApiName.length()) == '__c' ) 
                    objectSoql+= nextText + F.fieldApiName.substring(0,F.fieldApiName.length()-1) + 'r.name LIKE \'%' + String.escapeSingleQuotes(F.stringValue) + '%\' ';
                else if( F.fieldType == 'Boolean' ){
                    if( F.stringValue == 'true' || F.stringValue == 'True' || F.stringValue == 'false' || F.stringValue == 'False' ){
                        objectSoql+= nextText + F.fieldApiName + ' = ' + String.escapeSingleQuotes(F.stringValue) + ' ';
                    }
                    else{
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Enabled Field Filter value must be True or False'));
                    }    
                }
                else if( F.fieldType == 'Picklist' ){
                    if( f.stringValue != 'null' )
                        objectSoql+= nextText + F.fieldApiName + ' = \'' + F.stringValue + '\' ';
                }
                else
                     objectSoql+= nextText + F.fieldApiName + ' LIKE \'%' + String.escapeSingleQuotes(F.stringValue) + '%\' ';
            }
        }
    }  
    public void setSpecialSoql(){

    }
    public void setSpecialSoqlMode(){
        String qMode = ApexPages.currentPage().getParameters().get('specialQueryMode');
        validAccountIds = new List<String>();
                
        Date cutOffDate = System.Today() - dayRange;  
        
        if( qMode != null && !disableSpecialQueryMode){
            qMode = String.EscapeSingleQuotes( qMode );
            
            if( qMode == 'IA' ){
                objectSoql += ' AND Sales_Activity_Score__c = 0 AND Marketing_Activity_Score__c = 0 '; 
                specialQueryText = ' Showing all Inactive Accounts ';
            }
            else if( qMode == 'SA' ){
                objectSoql += ' AND Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c = 0 '; 
                specialQueryText = ' Showing all Sales Active Accounts ';
            }
            else if ( qMode == 'MA' ){
                objectSoql += ' AND Marketing_Activity_Score__c > 0 AND Sales_Activity_Score__c = 0 '; 
                specialQueryText = ' Showing all Marketing Active Accounts ';
            }
            else if( qMode == 'AA' ){
                objectSoql += ' AND Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c > 0'; 
                specialQueryText = ' Showing all Aligned Accounts ';
            }
            else if( qMode == 'SAOO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Sales Active Accounts with Open Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE isClosed = false AND Account.Sales_Activity_Score__c = 0 AND Account.Marketing_Activity_Score__c = 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            else if( qMode == 'MAOO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Marketing Active Accounts with Open Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE isClosed = false AND Account.Sales_Activity_Score__c = 0 AND Account.Marketing_Activity_Score__c > 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            else if( qMode == 'AAOO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Aligned Accounts with Open Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE isClosed = false AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c > 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            else if( qMode == 'SACWO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Sales Active Accounts with Closed Won Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE CloseDate > : cutOffDate AND isClosed = true and isWon = true AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c = 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            else if( qMode == 'MACWO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Sales Active Accounts with Closed Won Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE CloseDate > : cutOffDate AND isClosed = true and isWon = true AND Account.Sales_Activity_Score__c = 0 AND Account.Marketing_Activity_Score__c > 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            else if( qMode == 'AACWO' ){
                objectSoql += ' AND Id IN : validAccountIds '; 
                specialQueryText = ' Showing all Aligned Accounts with Closed Won Opportunities';
                
                for( Opportunity o : [ SELECT AccountId FROM Opportunity WHERE CloseDate > : cutOffDate AND isClosed = true and isWon = true AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c > 0 ] )
                    validAccountIds.add( o.AccountId );
            }
            
        }      
    }
    //Runs the query and creates the object list
    public void setObjectList(){
        try{
            con = new ApexPages.StandardSetController(Database.query(objectSoql + ' order by ' + sortField + ' ' + sortDir + ' LIMIT 5000' ));
            // sets the number of records in each page set
            con.setPageSize(offSetAmount);
        } catch(exception e){           
            System.debug('Problem with SOQL : ' + e + ' SOQL : ' + objectSoql);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Soql Problem : '+e+objectSoql));      
        }   
        objectList = new List<WrapObjAndChild>();
        numberOfInactiveOwners = 0;
        if( con != null ){
            for (Account obj : (List<Account>)con.getRecords()){
                objectList.add(new WrapObjAndChild(obj));
                if( obj.Owner.isActive == false )
                    numberOfInactiveOwners++;
            }    
        }
    }   

    //turns off and resets all filtering
    public void TurnOffFilter(){
        for(wrapDummyAndField DF : searchWrapper )
            DF.stringValue = '';
        runFullSearch();
    }
    // Sets the sort direction
    public String sortDir {
        get  { if (sortDir == null) {  sortDir = 'desc'; } return sortDir;  }
        set;
    }
    
    // Sets the sort field
    public String sortField {
        get  { if (sortField == null) {sortField = 'CreatedDate'; } return sortField;  }
        set;
    }    
    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
        // run the query again
        runFullSearch();
    }  
    //Select all in the object list
    public void selectAll(){
        for(WrapObjAndChild Item:ObjectList){
            if(isSelectAll==true)
                Item.selected = true;
            else if(isSelectAll==false)
                Item.selected = false;  
        }
    }   
    public void resetSpecialQueryMode(){
        specialQueryMode = '';
        specialQueryText = '';
        disableSpecialQueryMode = true;
        runFullSearch();
    }

    //----------------------------------------Standard Set Controller Clases/Methods ---------------------------------------------------
    // instantiate the StandardSetController from a query locator

    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }

    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }

    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

     public void first() {
         con.first();
         objectList = new List<WrapObjAndChild>();
            for (sObject obj : (List<sObject>)con.getRecords())
                objectList.add(new WrapObjAndChild(obj));
     }

     public void last() {
         con.last();
         objectList = new List<WrapObjAndChild>();
            for (sObject obj : (List<sObject>)con.getRecords())
                objectList.add(new WrapObjAndChild(obj));
     }

     public void previous() {
         con.previous();
         objectList = new List<WrapObjAndChild>();
            for (sObject obj : (List<sObject>)con.getRecords())
                objectList.add(new WrapObjAndChild(obj));
     }

     public void next() {
         con.next();
         objectList = new List<WrapObjAndChild>();
            for (sObject obj : (List<sObject>)con.getRecords())
                objectList.add(new WrapObjAndChild(obj));
     }

}