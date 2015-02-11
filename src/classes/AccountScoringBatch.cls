public class AccountScoringBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Integer dayRange { get;set; }
    public List<String> includedCampaignMemberStatus { get;set; }
    public List<String> includedTaskTypes { get;set; }
    public List<String> includedEventTypes { get;set; }
    public List<String> includedTaskStatus { get;set; }
    
    public AccountScoringBatch(){
        //Get Day Range
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
            dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
        }
        
        if( dayRange == null )
            dayRange = 0;
        
        //Get Include Lists
        includedCampaignMemberStatus = new List<String>();
        includedTaskTypes = new List<String>();
        includedEventTypes = new List<String>();
        includedTaskStatus = new List<String>();            
          
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'CampaignMemberStatus' ] ){
            includedCampaignMemberStatus.add( activityScoreSetting.Value__c );
        }
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'TaskType' ] ){
            includedTaskTypes.add( activityScoreSetting.Value__c );
        }
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'CampaignMemberStatus' ] ){
            includedEventTypes.add( activityScoreSetting.Value__c );
        }
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'TaskStatus' ] ){
            includedTaskStatus.add( activityScoreSetting.Value__c );
        }
        System.debug( ' Account Scoring Day Range ' + dayRange);
        System.debug( ' Account Scoring Task Types ' + includedTaskTypes);
        System.debug( ' Account Scoring Campaign Member Status' + includedCampaignMemberStatus);
        System.debug( ' Account Scoring Task Status ' + includedTaskStatus);
        System.debug( ' Account Scoring Event Type ' + includedEventTypes);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){      
        return Database.getQueryLocator( [SELECT Id, Name, Activity_Score__c, Activity_Details__c, Last_Activated_Date__c, Last_Inactivated_Date__c, Marketing_Activity_Score__c, Sales_Activity_Score__c FROM Account ] );
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<String> accountIds = new List<String>();
        
        for( sObject acc : scope ){
            accountIds.add( acc.Id );
        }
        //Create set of Accounts with Campaign Member Activity
        List<CampaignMember> validCampaignMembers = [ SELECT id, CampaignId, ContactId, Contact.AccountId, Lead.LeanData__Reporting_Matched_Account__c, LeadId, FirstRespondedDate, HasResponded, Status FROM CampaignMember WHERE CreatedDate >= : System.Today() - dayRange AND  Status IN : includedCampaignMemberStatus AND ( Lead.LeanData__Reporting_Matched_Account__c IN : accountIds OR Contact.AccountId IN : accountIds ) ];
        Set<String> accountsWithValidCampaignMember = new Set<String>();
        
        System.debug( ' Valid Campaign Members ' + validCampaignMembers);
        
        for( CampaignMember validCampaignMember : validCampaignMembers ){
            if( validCampaignMember.ContactId != null ){
                accountsWithValidCampaignMember.add( validCampaignMember.Contact.AccountId );
            }
            else if( validCampaignMember.LeadId != null ){
                if( validCampaignMember.Lead.LeanData__Reporting_Matched_Account__c != null ){
                    accountsWithValidCampaignMember.add( validCampaignMember.Lead.LeanData__Reporting_Matched_Account__c );
                }
            }
        }
        
        //Create set of Accounts with Task Activity
        List<Task> validTasks = [ SELECT id, AccountId, ActivityDate, Priority, Status, Subject, Type FROM Task WHERE CreatedDate >= : System.Today() - dayRange AND Status IN : includedTaskStatus AND Type IN : includedTaskTypes AND AccountId IN : accountIds ];
        Set<String> accountsWithValidTasks = new Set<String>();
        
        System.debug( ' Valid Tasks' + validTasks);
        
        for( Task validTask : validTasks ){
            accountsWithValidTasks.add( validTask.AccountId );
        }
        
        //Create set of Accounts with Event Activity
        List<Event> validEvents = [ SELECT id, AccountId, ActivityDate, Subject, Type FROM Event WHERE CreatedDate >= : System.Today() - dayRange AND Type IN : includedEventTypes ];
        Set<String> accountsWithValidEvents = new Set<String>();
        
        System.debug( ' Valid Events' + validEvents);
        
        for( Event validEvent : validEvents ){
            accountsWithValidEvents.add( validEvent.AccountId );
        }
        
        List<Account> scopeAccounts = (List<Account>) scope;

        for( Account acc : scopeAccounts ){
            Boolean isActive = false;
            if( accountsWithValidCampaignMember.contains( acc.Id )){
                isActive = true;
                acc.Marketing_Activity_Score__c = 1;
            }
            else{
                acc.Marketing_Activity_Score__c = 0;
            }
            
            if( accountsWithValidTasks.contains( acc.Id ) || accountsWithValidEvents.contains( acc.Id ) ){
                if( accountsWithValidTasks.contains( acc.Id )){
                    isActive = true;
                    acc.Sales_Activity_Score__c = 1;
                }
                if( accountsWithValidEvents.contains( acc.Id )){
                    isActive = true;
                    acc.Sales_Activity_Score__c = 1;
                }
            }
            else{
                acc.Sales_Activity_Score__c = 0; 
            }
            if( isActive ){
                if( acc.Activity_Score__c == 0){
                    acc.Last_Activated_Date__c = System.Today();
                }
                acc.Activity_Score__c = 1;
            }
            else{
                if( acc.Activity_Score__c == 1){
                    acc.Last_Inactivated_Date__c = System.Today();
                }
                acc.Activity_Score__c = 0;
            }
            System.debug( ' Account Name ' + acc.Name + ' with Activity Score ' + acc.Activity_Score__c );
        }
        
        update( scopeAccounts );
    }
    
    public void finish(Database.BatchableContext BC){
    
    }

}