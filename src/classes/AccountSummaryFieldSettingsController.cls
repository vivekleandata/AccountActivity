public with sharing class AccountSummaryFieldSettingsController {
    public List<fieldSelector> availableFields { get;set; }
    public List<fieldSelector> selectedFields { get;set; }
    public Reporting_Setting__c currentSetting { get;set; }
    public String displayFieldsValue { get;set; }
    public Map<String, Schema.SObjectType> GlobalDescribeMap {get;set;} //Global Describe
    
    public class fieldSelector implements Comparable{
        public String fieldLabel { get;set; }
        public String fieldName { get;set; }
        public Boolean isSelected { get;set; }
        
        public fieldSelector( String fL, String fN ){
            fieldLabel = fL;
            fieldName = fN;
            isSelected = false;
        }
        public fieldSelector( String fL, String fN, Boolean iS){
            fieldLabel = fL;
            fieldName = fN;
            isSelected = iS;
        }   
        
        // Compare opportunity stages based on the Priority 
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            fieldSelector comp = (fieldSelector)compareTo;
            
            if( fieldLabel > comp.fieldLabel ){
                return 1;
            }
            else if( fieldLabel < comp.fieldLabel ){
                return -1;
            }    
            else{
                return 0;
            }    
        } 
    }
    
    public AccountSummaryFieldSettingsController(){
        init();  
    }
    public void init(){
        GlobalDescribeMap = Schema.getGlobalDescribe();
        SObjectType accountType = GlobalDescribeMap.get('Account');
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        
        try{
            currentSetting = [ SELECT Id, Value__c FROM Reporting_Setting__c WHERE User__c = : userInfo.getUserId() AND Type__c = 'Account View' AND Category__c = 'Display Fields' ORDER BY CreatedDate DESC LIMIT 1 ];
        } catch( exception e){
            System.debug( 'No current settings' );
            currentSetting = new Reporting_Setting__c( Type__c = 'Account View', Category__c = 'Display Fields', Value__c = 'Name, Type', User__c = userInfo.getUserId() , Organization_Level__c = false );
        }
        
        selectedFields = new List<fieldSelector>();
        availableFields = new List<fieldSelector>();
        
        if( currentSetting.Value__c == null )
            currentSetting.Value__c = '';
            
        for( Schema.SObjectField objField : mfields.Values() ){
            //Only make a field available IF the user has access to see it
            if( objField.getDescribe().isAccessible() && objField.getDescribe().getType().Name() != 'Address' && objField.getDescribe().getType().Name() != 'Id'){
                if( currentSetting.Value__c.contains( objField.getDescribe().getName() ) ){
                    selectedFields.add( new fieldSelector( objField.getDescribe().getLabel(), objField.getDescribe().getName() ) );
                }
                else{
                    availableFields.add( new fieldSelector( objField.getDescribe().getLabel(), objField.getDescribe().getName() ) );
                }    
            }
        
        }
        
        availableFields.sort();
    }
    public void selectFields(){
        Integer j = 0;
        while (j < availableFields.size()){
          if( availableFields[j].isSelected ){
            selectedFields.add( new fieldSelector( availableFields[j].fieldLabel, availableFields[j].fieldName ) );
            availableFields.remove(j);
          }else{
            j++;
          }
        }
        availableFields.sort();
    }
    public void unselectFields(){
        Integer j = 0;
        while (j < selectedFields.size()){
          if( selectedFields[j].isSelected ){
            availableFields.add( new fieldSelector( selectedFields[j].fieldLabel, selectedFields[j].fieldName ) );
            selectedFields.remove(j);
          }else{
            j++;
          }
        }  
        availableFields.sort(); 
    }
    public void removeHighlights(){
       for( fieldSelector fS : selectedFields ){
           fS.isSelected = false;
       }
       for( fieldSelector fS : availableFields ){
           fS.isSelected = false;
       }
       
    }
    public void saveSettings(){
        String fieldNames = '';
        
        for( fieldSelector fS : selectedFields ){
            fieldNames+= fs.fieldName + ',';
        }
        
        if( fieldNames.length() > 0 )
            fieldNames = fieldNames.subString( 0, fieldNames.length() - 1 ) ;
            
        currentSetting.Value__c = fieldNames;
        
        upsert ( currentSetting );    
    }
}