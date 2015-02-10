public with sharing class AccountScoreSettingsController {
    public ActivityScoreSettings__c activitySettings { get;set; }
    public List<genericSelector> CampaignMemberStatusList { get;set; }
    public List<genericSelector> ActivityTypeList { get; set; }
    public List<genericSelector> TaskTypeList { get; set; }
    public List<genericSelector> EventTypeList { get; set; }
    public List<genericSelector> TaskStatusList { get; set; }
    public List<genericSelector> EventStatusList { get; set; }
    public Time scheduledDateTime { get; set; }
    
    public Class genericSelector Implements Comparable{
        public String selectorLabel { get;set; }
        public Boolean isSelected { get;set; }
        
        public genericSelector( String t ){
            selectorLabel = t;
            isSelected = false;
        }
        public genericSelector( String t , Boolean isS){
            selectorLabel = t;
            isSelected = isS;
        }
        // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
            genericSelector compareToGS = (genericSelector)compareTo;
            return this.selectorLabel.compareTo( compareToGS.selectorLabel );
        }
    }
    
    public AccountScoreSettingsController(){
        activitySettings = ActivityScoreSettings__c.getOrgDefaults();
        CampaignMemberStatusList = new List<genericSelector>();
        
        //Select Campaign Member Statuses
        Set<String> campaignMemberStatusSet = new Set<String>();
        
        for( CampaignMemberStatus stat : [ SELECT Label From CampaignMemberStatus ]){
            campaignMemberStatusSet.add( stat.Label );
        }

        for( String statusLabel : campaignMemberStatusSet ){
            if( activitySettings.Included_Campaign_Member_Status__c == null ){
                CampaignMemberStatusList.add( new genericSelector ( statusLabel ));
            }
            else if( activitySettings.Included_Campaign_Member_Status__c.contains( statusLabel ) ){
                CampaignMemberStatusList.add( new genericSelector ( statusLabel , true ));
            }
            else{
                CampaignMemberStatusList.add( new genericSelector ( statusLabel ));
            }    
        }
        
        //Add up Event / Task Types
        TaskTypeList = new List<genericSelector>();
        EventTypeList = new List<genericSelector>();

        List<Schema.PicklistEntry> eventTypes = Event.Type.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> taskTypes = Task.Type.getDescribe().getPicklistValues();
        
        for( Schema.PickListEntry eventType : eventTypes ){
            if( activitySettings.Included_Event_Type__c == null ){
                EventTypeList.add( new GenericSelector( eventType.getLabel() ) );
            }
            else if( activitySettings.Included_Event_Type__c.contains( eventType.getLabel() ) ){
                EventTypeList.add( new GenericSelector( eventType.getLabel(), true ) );
            }
            else{
                EventTypeList.add( new GenericSelector( eventType.getLabel() ) );
            } 
        }
        
        for( Schema.PickListEntry taskType : taskTypes ){
            if( activitySettings.Included_Task_Type__c == null ){
                TaskTypeList.add( new GenericSelector( taskType.getLabel() ) );
            }
            else if( activitySettings.Included_Task_Type__c.contains( taskType.getLabel() ) ){
                TaskTypeList.add( new GenericSelector( taskType.getLabel() , true ) );
            }
            else{
                TaskTypeList.add( new GenericSelector( taskType.getLabel() ) );
            }        
        }
  
        EventTypeList.sort(); TaskTypeList.sort(); 
        
        //Add up Event / Task Statuses
        TaskStatusList = new List<genericSelector>();

        List<Schema.PicklistEntry> taskStatuses = Task.Status.getDescribe().getPicklistValues();
             
        for( Schema.PickListEntry taskStatus : taskStatuses ){
            if( activitySettings.Included_Task_Status__c == null ){
                TaskStatusList.add( new GenericSelector( taskStatus.getLabel() ) );
            }
            else if( activitySettings.Included_Task_Status__c.contains( taskStatus.getLabel() ) ){
                TaskStatusList.add( new GenericSelector( taskStatus.getLabel() , true ) );
            }
            else{
                TaskStatusList.add( new GenericSelector( taskStatus.getLabel() ) );
            }    
        }
  
        TaskStatusList.sort(); 
        
    }
    public void saveAccountScoringSettings(){
        String selectedCampaignMemberStatus = ':~!~,'; //A dummy value that won't pass just in case they have selected 0 statuses/types etc. ( Might not be best practice, will look into this )
        String selectedTaskType = ':~!~,';
        String selectedEventType = ':~!~,';
        String selectedTaskStatus =':~!~,';
        
        for( genericSelector CMS : CampaignMemberStatusList ){
            if( CMS.isSelected )
                selectedCampaignMemberStatus += CMS.selectorLabel + ',';
        }
        for( genericSelector TT : TaskTypeList ){
            if( TT.isSelected )
                selectedTaskType += TT.selectorLabel + ',';
        }
        for( genericSelector ET : EventTypeList ){
            if( ET.isSelected )
                selectedEventType += ET.selectorLabel + ',';
        }
        for( genericSelector TS : TaskStatusList ){
            if( TS.isSelected )
                selectedTaskStatus += TS.selectorLabel + ',';
        }
        
        if( selectedTaskType.endsWith( ',' ) )
            activitySettings.Included_Campaign_Member_Status__c = selectedCampaignMemberStatus.substring(0, selectedCampaignMemberStatus.length()-1);
            
        if( selectedTaskType.endsWith( ',' ) )        
            activitySettings.Included_Event_Type__c = selectedEventType.substring(0, selectedEventType.length()-1);
            
        if( selectedTaskType.endsWith( ',' ) )
            activitySettings.Included_Task_Status__c = selectedTaskStatus.substring(0, selectedTaskStatus.length()-1);
            
        if( selectedTaskType.endsWith( ',' ) )       
            activitySettings.Included_Task_Type__c = selectedTaskType.substring(0, selectedTaskType.length()-1);
                
        upsert( activitySettings );
    }
    public void runAccountScoring(){
        saveAccountScoringSettings();
        database.executeBatch(new AccountScoringBatch( ) );        
    }
    public void scheduleAccountScoring(){
        saveAccountScoringSettings();
        
        try{
            CronTrigger ct = [SELECT TimesTriggered, NextFireTime, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'Account Scoring' ];
            System.abortJob(ct.Id);
        } catch( exception e) {
            System.debug( 'No old scheduled job to delete');
        }
        AccountScoringScheduling SC = new AccountScoringScheduling(); 
        String sch = '0 00 00 * * ?'; 
        sch = '0 0 00 ? * MON-SUN' ;
        String jobID = system.schedule('Account Scoring', sch, SC );
    }

}