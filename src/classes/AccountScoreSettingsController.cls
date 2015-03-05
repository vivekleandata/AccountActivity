public with sharing class AccountScoreSettingsController {
    public List<genericSelector> CampaignMemberStatusList { get;set; }
    public List<genericSelector> ActivityTypeList { get; set; }
    public List<genericSelector> TaskTypeList { get; set; }
    public List<genericSelector> EventTypeList { get; set; }
    public List<genericSelector> TaskStatusList { get; set; }
    public List<genericSelector> EventStatusList { get; set; }
    public Time scheduledDateTime { get; set; }
    public Integer dayRange { get;set; }
    
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
        CampaignMemberStatusList = new List<genericSelector>();
        
        //Set Day Range
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
            if( activityScoreSetting.Value__c != null )
                dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
        }
        
        if( dayRange == null )
            dayRange = 90;
        
        //Select Campaign Member Statuses
        Set<String> campaignMemberStatusSet = new Set<String>();
        Set<String> selectedCampaignMemberStatus = new Set<String>();
        
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'CampaignMemberStatus' ] ){
            selectedCampaignMemberStatus.add( activityScoreSetting.Value__c );
        }
        
        for( CampaignMemberStatus stat : [ SELECT Label From CampaignMemberStatus ]){
            campaignMemberStatusSet.add( stat.Label );
        }

        for( String statusLabel : campaignMemberStatusSet ){
            if( selectedCampaignMemberStatus.contains( statusLabel ) ){
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
        
        //Get Current Settings
        Set<String> selectedEventTypes = new Set<String>();
        
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'EventType' ] ){
            selectedEventTypes.add( activityScoreSetting.Value__c );
        }
        
        Set<String> selectedTaskTypes = new Set<String>();
        
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'TaskType' ] ){
            selectedTaskTypes.add( activityScoreSetting.Value__c );
        }
        
        for( Schema.PickListEntry eventType : eventTypes ){
            if( selectedEventTypes.contains( eventType.getLabel() ) ){
                EventTypeList.add( new GenericSelector( eventType.getLabel(), true ) );
            }
            else{
                EventTypeList.add( new GenericSelector( eventType.getLabel() ) );
            } 
        }
        
        for( Schema.PickListEntry taskType : taskTypes ){
            if( selectedTaskTypes.contains( taskType.getLabel() ) ){
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
        
        Set<String> selectedTaskStatus = new Set<String>();
        
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'TaskStatus' ] ){
            selectedTaskStatus.add( activityScoreSetting.Value__c );
        }
             
        for( Schema.PickListEntry taskStatus : taskStatuses ){
            if( selectedTaskStatus.contains( taskStatus.getLabel() ) ){
                TaskStatusList.add( new GenericSelector( taskStatus.getLabel() , true ) );
            }
            else{
                TaskStatusList.add( new GenericSelector( taskStatus.getLabel() ) );
            }    
        }
  
        TaskStatusList.sort(); 
        
    }
    public void saveAccountScoringSettings(){
        List<Activity_Score_Setting__c> oldSettings = [ SELECT id FROM Activity_Score_Setting__c ];
        delete ( oldSettings );
        
        List<Activity_Score_Setting__c> newSettings = new List<Activity_Score_Setting__c>();
        Integer i = 0;
        
        for( genericSelector CMS : CampaignMemberStatusList ){
            if( CMS.isSelected ){
                newSettings.add( new Activity_Score_Setting__c( Type__c ='CampaignMemberStatus', Value__c = CMS.selectorLabel , Name = 'Setting' + i));
                i++;
            }
        }
        for( genericSelector TT : TaskTypeList ){
            if( TT.isSelected ){
                newSettings.add( new Activity_Score_Setting__c( Type__c ='TaskType', Value__c = TT.selectorLabel, Name = 'Setting' + i));
                i++;
            }
        }
        for( genericSelector ET : EventTypeList ){
            if( ET.isSelected ){
                newSettings.add( new Activity_Score_Setting__c( Type__c ='EventType', Value__c = ET.selectorLabel, Name = 'Setting' + i ));
                i++;
            }
        }
        for( genericSelector TS : TaskStatusList ){
            if( TS.isSelected ){
                newSettings.add( new Activity_Score_Setting__c( Type__c ='TaskStatus', Value__c = TS.selectorLabel, Name = 'Setting' + i ));
                i++;
            }
        }
        
        if( dayRange == null )
            dayRange = 90;
            
        newSettings.add( new Activity_Score_Setting__c( Type__c ='DayRange', Value__c = String.ValueOf( dayRange ) , Name='DayRange' ));

        insert( newSettings );
    }
    public void runAccountScoring(){
        saveAccountScoringSettings();
        database.executeBatch(new AccountScoringBatch( 'One Time') );        
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
        String sch = '0 0 00 ? * MON-SUN' ;
        String jobID = system.schedule('Account Scoring', sch, SC );
    }

}