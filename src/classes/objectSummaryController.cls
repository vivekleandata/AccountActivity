public class objectSummaryController {
    public Map<String, Schema.SObjectType> GlobalDescribeMap {get;set;} //Global Describe
    public String objType{get;set;} //Object API Name
    public String objLabel {get;set;} //Object's Type Label
    public Boolean verifiedSettings { get;set; } //Don't run page if valid settings not passed
    public String nameSpacePrefix { get;set; }
    public Boolean isCustom { get;set; }
    
    public List<wrapDummyAndField> searchDummy {get;set;} //List of dummy fields to use for filtering
    public List<Schema.FieldSetMember> displayFields {get;set;} //The fields from the 'displayFields' field set
    public List<Schema.FieldSetMember> searchFields {get;set;} //The fields from the 'searchFields' field set 
    //public List<WrapObjAndChild> objList {get;set;} //Holds all the objects in the summary
    public ApexPages.StandardSetController con { get;set; }   
    public List<WrapObjAndChild> objectList{ get;set; }
    
    public String objectSoql { get;set ; }
    public String specialQueryMode { get;set; }
    public String specialQuery { get;set; }
    public String specialQueryText { get;set; }
    public Boolean disableSpecialQueryMode { get;set; }
    public List<String> validAccountIds { get;set; }
    public Integer dayRange { get;set; }
    
    public Boolean isSelectAll {get; set;} //Checkbox in the front to select all objects
    public Integer pageNumber2 { get;set; }
    public static Integer offSetAmount = 15;
    
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
    //Wrap a dummy object with a field
    public class wrapDummyAndField{
        public Schema.FieldSetMember field {get;set;}  
        public String stringValue { get;set; }
 
        public wrapDummyAndField( Schema.FieldSetMember A ) {
            field = A;
            stringValue = '';
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
    public objectSummaryController(){
        init();
        GlobalDescribeMap = Schema.getGlobalDescribe();
        nameSpacePrefix = '';
        isCustom = false;
        verifiedSettings = true;
        pageNumber2 = 1;
        disableSpecialQueryMode = false;
        if( ApexPages.currentPage().getParameters().get('isCustom') != null ) 
            isCustom = true;
        //if(LD.isManaged() )
        if( isCustom )
            nameSpacePrefix = 'LeanData__';
            
        setObjectType();
        setFields();   
        runFullSearch();

    }
    //Init function
    public void init(){
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
            dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
        }      
    } 
    //Sets the object type
    public void setObjectType(){
        try{
            objType = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('objt'));             
            objLabel = GlobalDescribeMap.get(nameSpacePrefix + objType).getDescribe().getLabel();    
        } catch ( exception e ){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Object Type not found'));
             verifiedSettings = false;
        }
    }
    //Sets the fields from the fieldset
    public void setFields() {
         if( !verifiedSettings )
            return;
         Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(nameSpacePrefix+objType);
         Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
         
         try{
             Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(nameSpacePrefix + 'displayFields');          
             displayFields = fieldSetObj.getFields();
         } catch(exception e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'This Object does not have displayFields field set'));
             verifiedSettings = false;
         }
         
         try{
             Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(nameSpacePrefix + 'searchFields');          
             searchFields = fieldSetObj.getFields();
         } catch(exception e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'This Object does not have searchFields field set'));
             verifiedSettings = false;
         }
         
         searchDummy = new List<wrapDummyAndField>();
         if( searchFields != null ){
             for(Schema.FieldSetMember F : searchFields)
                 searchDummy.add(new wrapDummyAndField( F ));
         }        
                
    }
    //Goes through the search steps
    public void runFullSearch(){
        if( verifiedSettings ){
            pageNumber2 = 1;
            setBaseSoql();
            setFilterSoql();
            setSpecialSoql();
            setSpecialSoqlMode();
            setObjectList();
        }
    }
    //Sets the base soql statement
    public void setBaseSoql(){
        objectSoql = 'SELECT id,CreatedDate';
        
        for(Schema.FieldSetMember f : displayFields) {
            objectSoql += ', '+f.getFieldPath() ;
            if(f.gettype().name() =='reference' && f.fieldPath.substring(f.fieldPath.length() - 3, f.fieldPath.length()) == '__c')
                objectSoql += ','+f.getFieldPath().substring(0,F.fieldpath.length()-1)+'r.name';
        }
        
        objectSoql+= ' FROM ' + objType +' ';
     
    }
    //Adds filter to the soql statement based on search box
    public void setFilterSoql(){
        //ADD WHERE STATEMENTS TO objectSoql
        objectSoql+=' WHERE id != null ';
        String nextText = 'AND ';
        for(wrapDummyAndField F : searchDummy) {
            if(F.stringValue!=null && F.stringValue!=''){                        
                if(F.field.getType().name() == 'reference' && f.field.fieldPath.substring(f.field.fieldPath.length() - 3, f.field.fieldPath.length()) == '__c' ) 
                    objectSoql+= nextText + F.field.fieldpath.substring(0,F.field.fieldpath.length()-1) + 'r.name LIKE \'%' + String.escapeSingleQuotes(F.stringValue) + '%\' ';
                else if(F.field.getType() == Schema.DisplayType.Boolean ){
                    if( F.stringValue == 'true' || F.stringValue == 'True' || F.stringValue == 'false' || F.stringValue == 'False' ){
                        objectSoql+= nextText + F.field.fieldpath + ' = ' + String.escapeSingleQuotes(F.stringValue) + ' ';
                    }
                    else{
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Enabled Field Filter value must be True or False'));
                    }    
                }
                else
                     objectSoql+= nextText + F.field.fieldpath + ' LIKE \'%' + String.escapeSingleQuotes(F.stringValue) + '%\' ';
                
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
            System.debug('Problem with SOQL');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Soql Problem : '+e+objectSoql));      
        }   
        objectList = new List<WrapObjAndChild>();
        for (sObject obj : (List<sObject>)con.getRecords())
            objectList.add(new WrapObjAndChild(obj));

        /*
        List<sObject> Objs = new List<sObject>();
        try{
            Objs = database.query(objectSoql + ' order by ' + sortField + ' ' + sortDir+ ' LIMIT '+ offSetAmount + ' OFFSET ' + ( pageNumber2 - 1 )*offSetAmount );    
        }catch(exception e){
            System.debug('Problem with SOQL');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Soql Problem : '+e+objectSoql));      
        }
                
        ObjList = new List<WrapObjAndChild>();
        
        try{
            for(Sobject O:Objs){               
              ObjList.add((new WrapObjAndChild( O)) );                 
            }               
        }catch(exception e){
             ObjList = new List<WrapObjAndChild>();
             System.debug('No objects queried');
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'No Objects Found'+Objs));      
        }    
        */
    }   
    //turns off and resets all filtering
    public void TurnOffFilter(){
        for(wrapDummyAndField DF : searchDummy)
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
    /*
    //Go to next page
    public void nextPage(){
        pageNumber2++;
        setObjectList();
    }
    
    public void previousPage(){
        pageNumber2--;
        setObjectList();
    } 
    */
    
    
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