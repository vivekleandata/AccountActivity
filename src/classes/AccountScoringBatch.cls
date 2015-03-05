public class AccountScoringBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Integer dayRange { get;set; }
    public List<String> includedCampaignMemberStatus { get;set; }
    public List<String> includedTaskTypes { get;set; }
    public List<String> includedEventTypes { get;set; }
    public List<String> includedTaskStatus { get;set; }
    public String batchType { get;set; }
    public Set<String> stillValidUniqueIds { get;set; }
    
    public AccountScoringBatch( String bType ){
        batchType = bType;
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
        
        stillValidUniqueIds = new Set<String>();
        
        System.debug( ' Account Scoring Day Range ' + dayRange);
        System.debug( ' Account Scoring Task Types ' + includedTaskTypes);
        System.debug( ' Account Scoring Campaign Member Status' + includedCampaignMemberStatus);
        System.debug( ' Account Scoring Task Status ' + includedTaskStatus);
        System.debug( ' Account Scoring Event Type ' + includedEventTypes);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){      
        return Database.getQueryLocator( [SELECT Id, Name, Activity_Score__c, Last_Activated_Date__c, Last_Inactivated_Date__c, Marketing_Activity_Score__c, Sales_Activity_Score__c FROM Account ] );
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<String,List<Account_Touch__c>> accountTouchMap = new Map<String, List<Account_Touch__c>>();
        Set<String> accountIds = new Set<String>();
        Map<String,Lead> leadsMap = new Map<String,Lead>();
        Map<String,Opportunity> opportunitiesMap = new Map<String,Opportunity>();
        Map<String,String> AccountTouchIdMap = new Map<String,String>();
        
        for( sObject acc : scope ){
            accountIds.add( acc.Id );
            accountTouchMap.put( acc.Id , new List<Account_Touch__c>() );
        }

        //Existing Account Touch Rows
        for( Account_Touch__c accountTouch : [ SELECT id, Activity_Id_Account_Id__c FROM Account_Touch__c WHERE Account__c IN : accountIds ]){
            AccountTouchIdMap.put( accountTouch.Activity_Id_Account_Id__c, accountTouch.Id );
        }

        //Grab Leads matched to the scope Accounts
        Set<String> relatedLeadIds = new Set<String>();        
        for( Lead l : [ SELECT id, LeanData__Reporting_Matched_Account__c,Name FROM Lead WHERE LeanData__Reporting_Matched_Account__c IN : accountIds ] ){
            relatedLeadIds.add( l.id );
            leadsMap.put( l.id, l);
        }

        //Grab Opportunities from these Accounts
        Set<String> relatedOpportunityIds = new Set<String>();        
        for( Opportunity o : [ SELECT id, AccountId, Name FROM Opportunity WHERE AccountId IN : accountIds ] ){
            relatedOpportunityIds.add( o.id );
            opportunitiesMap.put( o.id, o);
        }


        //Create set of Accounts with Campaign Member Activity
        List<CampaignMember> validCampaignMembers = [ SELECT id, CreatedDate, CreatedById, Campaign.Name, Contact.OwnerId, Lead.OwnerId, CampaignId, ContactId, Contact.Name, Lead.Name, Contact.AccountId, Lead.LeanData__Reporting_Matched_Account__c, LeadId, FirstRespondedDate, HasResponded, Status FROM CampaignMember WHERE CreatedDate >= : System.Today() - dayRange AND  Status IN : includedCampaignMemberStatus AND ( Lead.LeanData__Reporting_Matched_Account__c IN : accountIds OR Contact.AccountId IN : accountIds ) ];
        
        System.debug( ' Valid Campaign Members ' + validCampaignMembers);
        
        for( CampaignMember validCampaignMember : validCampaignMembers ){
            System.debug( 'Campaign Member Id : ' + validCampaignMember.Id + ' CreatedDate : ' + validCampaignMember.CreatedDate + ' Valid Campaign Contact -> Account Id' + validCampaignMember.Contact.AccountId );
            Account_Touch__c newAccountTouch = new Account_Touch__c( Type__c ='Campaign Member', Activity_Name__c = validCampaignMember.Status, Date__c = Date.ValueOf( validCampaignMember.CreatedDate ), Campaign__c = validCampaignMember.CampaignId , Activity_id__c = validCampaignMember.Id);


            if( validCampaignMember.ContactId != null ){
                if( accountTouchMap.get( validCampaignMember.Contact.AccountId ) != null)
                    newAccountTouch.Account__c = validCampaignMember.Contact.AccountId;
                    newAccountTouch.Contact__c = validCampaignMember.ContactId;
                    if( String.ValueOf(validCampaignMember.Contact.OwnerId).substring(0,2) != '00G' && validCampaignMember.Contact.OwnerId.getsObjectType() == Schema.User.sObjectType ){
                        newAccountTouch.Owner__c = validCampaignMember.Contact.OwnerId;                
                    }
                    System.debug( ' Current Account Touch Map for this Account ' + accountTouchMap.get( validCampaignMember.Contact.AccountId ) );            
            }
            else if( validCampaignMember.LeadId != null ){
                if( validCampaignMember.Lead.LeanData__Reporting_Matched_Account__c != null ){
                    newAccountTouch.Account__c  = validCampaignMember.Lead.LeanData__Reporting_Matched_Account__c;
                    newAccountTouch.Lead__c = validCampaignMember.LeadId;
                    if( String.ValueOf(validCampaignMember.Lead.OwnerId).substring(0,2) != '00G' && validCampaignMember.Lead.OwnerId.getsObjectType() == Schema.User.sObjectType ){
                        newAccountTouch.Owner__c = validCampaignMember.Lead.OwnerId;
                    }
                }
            }

            String uniqueId =  validCampaignMember.id + '' + newAccountTouch.Account__c;
            newAccountTouch.Activity_Id_Account_Id__c = uniqueId;
            newAccountTouch.Id = accountTouchIdMap.get(uniqueId);

            if( accountTouchMap.get( newAccountTouch.Account__c ) != null ){
                accountTouchMap.get( newAccountTouch.Account__c ).add ( newAccountTouch );
            }
        }

        //Create set of Accounts with Task Activity
        List<Task> validTasks = [ SELECT id, WhoId, WhatId, AccountId, ActivityDate, Priority, Status, Subject, Type, OwnerId, CreatedDate FROM Task WHERE CreatedDate >= : System.Today() - dayRange AND Status IN : includedTaskStatus AND Type IN : includedTaskTypes AND ( AccountId IN : accountIds OR WhoId IN : relatedLeadIds OR WhatId IN : relatedOpportunityIds ) ];
        
        System.debug( ' Valid Tasks' + validTasks);
        
        for( Task validTask : validTasks ){
            //Create New Account Touch Object
            Account_Touch__c newAccountTouch = new Account_Touch__c( Type__c ='Task', Activity_Id__c = validTask.Id , activity_Name__c = validTask.Type );
                    
            if( validTask.ActivityDate != null ){
                newAccountTouch.Date__c = validTask.ActivityDate;
            }
            else{
                newAccountTouch.Date__c = Date.ValueOf( validTask.CreatedDate );
            }
            
            //The Task has to either have AccountId ( From being linked to Account, Contact or Opportunity ) or a WhoId ( Lead ) which is in our Related Leads Set
            //Grab the AccountId From the Appopriate Relation
            if( accountIds.contains( validTask.accountId ) ){
                newAccountTouch.Account__c = validTask.accountId;
            }
            else if( relatedLeadIds.contains( validTask.WhoId ) ){
                newAccountTouch.Account__c = leadsMap.get( validTask.WhoId ).LeanData__Reporting_Matched_Account__c ;
                newAccountTouch.Lead__c = validTask.WhoId;
            }

            //Set related Contact if valid
            if( validTask.WhoId != null ){
                if( validTask.WhoId.getsObjectType() == Schema.Contact.sObjectType ){
                    newAccountTouch.Contact__c = validTask.WhoId;
                }
            }
            //Set Opportunity Look Up if valid
            if( relatedOpportunityIds.contains( validTask.WhatId ) ){
                newAccountTouch.Opportunity__c = validTask.WhatId;
            }

            //Set Owner if not Queue
            if( String.ValueOf(validTask.OwnerId).substring(0,2) != '00G' && validTask.OwnerId.getsObjectType() == Schema.User.sObjectType ){
                newAccountTouch.Owner__c = validTask.OwnerId;
            }

            String uniqueId =  validTask.id + '' + newAccountTouch.Account__c;
            newAccountTouch.Activity_Id_Account_Id__c = uniqueId;
            newAccountTouch.Id = accountTouchIdMap.get(uniqueId);

            if( accountTouchMap.get( newAccountTouch.Account__c ) != null ){
                accountTouchMap.get( newAccountTouch.Account__c ).add ( newAccountTouch );
            }
        }
        
        
        //Create set of Accounts with Event Activity
        List<Event> validEvents = [ SELECT id, WhoId, WhatId , AccountId, ActivityDate, Subject, Type, OwnerId, CreatedDate FROM Event WHERE CreatedDate >= : System.Today() - dayRange AND Type IN : includedEventTypes AND ( AccountId IN : accountIds OR WhoId IN : relatedLeadIds OR WhatId IN : relatedOpportunityIds ) ];
        
        System.debug( ' Valid Events' + validEvents);
        
        for( Event validEvent : validEvents ){
            //Create New Account Touch Object
            Account_Touch__c newAccountTouch = new Account_Touch__c( Type__c ='Task', Activity_Id__c = validEvent.Id , activity_Name__c = validEvent.Type );
            
            if( validEvent.ActivityDate != null ){
                newAccountTouch.Date__c = validEvent.ActivityDate;
            }
            else{
                newAccountTouch.Date__c = Date.ValueOf( validEvent.CreatedDate );
            }
            
            //The Task has to either have AccountId ( From being linked to Account, Contact or Opportunity ) or a WhoId ( Lead ) which is in our Related Leads Set
            //Grab the AccountId From the Appopriate Relation
            if( accountIds.contains( validEvent.accountId ) ){
                newAccountTouch.Account__c = validEvent.accountId;
            }
            else if( relatedLeadIds.contains( validEvent.WhoId ) ){
                newAccountTouch.Account__c = leadsMap.get( validEvent.WhoId ).LeanData__Reporting_Matched_Account__c ;
                newAccountTouch.Lead__c = validEvent.WhoId;
            }

            //Set related Contact if valid
            if( validEvent.WhoId != null ){
                if( validEvent.WhoId.getsObjectType() == Schema.Contact.sObjectType ){
                    newAccountTouch.Contact__c = validEvent.WhoId;
                }
            }
            //Set Opportunity Look Up if valid
            if( relatedOpportunityIds.contains( validEvent.WhatId ) ){
                newAccountTouch.Opportunity__c = validEvent.WhatId;
            }

            //Set Owner if not Queue
            if( String.ValueOf( validEvent.OwnerId ).substring(0,2) != '00G' && validEvent.OwnerId.getsObjectType() == Schema.User.sObjectType ){
                newAccountTouch.Owner__c = validEvent.OwnerId;
            }

            String uniqueId =  validEvent.id + '' + newAccountTouch.Account__c;
            newAccountTouch.Activity_Id_Account_Id__c = uniqueId;
            newAccountTouch.Id = accountTouchIdMap.get(uniqueId);

            if( accountTouchMap.get( newAccountTouch.Account__c ) != null ){
                accountTouchMap.get( newAccountTouch.Account__c ).add ( newAccountTouch );
            }
        }
        
        List<Account> scopeAccounts = (List<Account>) scope;
        List<Account_Touch__c> accountTouchesToInsert = new List<Account_Touch__c>();
        
        for( Account acc : scopeAccounts ){
            accountTouchesToInsert.addAll( accountTouchMap.get( acc.Id) );
            Integer touchScore = 0;
            Integer marketingTouchScore = 0;
            Integer salesTouchScore = 0;
            Date mostRecentTouchDate = System.Today() - 10000;

            for( Account_Touch__c accountTouch : accountTouchMap.get( acc.Id) ){
                
                if( accountTouch.Type__c == 'Campaign Member'){
                    touchScore = 1;
                    marketingTouchScore = 1;
                }
                if( accountTouch.Type__c == 'Task' || accountTouch.Type__c == 'Event' ){
                    touchScore = 1;
                    salesTouchScore = 1;
                }
                if( accountTouch.Date__c > mostRecentTouchDate ){
                    mostRecentTouchDate = accountTouch.Date__c;
                }
            }

            if( acc.Activity_Score__c == 0 && touchScore > 0 )
                acc.Last_Activated_Date__c = System.Today();

            if( acc.Activity_Score__c > 0 && touchScore == 0 )
                acc.Last_Inactivated_Date__c = System.Today();

            acc.Activity_Score__c = touchScore;
            acc.Marketing_Activity_Score__c = marketingTouchScore;
            acc.Sales_Activity_Score__c = salesTouchScore;
            if( touchScore > 0 )
                acc.Most_Recent_Touch_Date__c = Date.ValueOf( mostRecentTouchDate );

            System.debug( ' Account Name ' + acc.Name + ' with Activity Score ' + acc.Activity_Score__c );
        }
        
        update( scopeAccounts );
        upsert accountTouchesToInsert;
        
        for( Account_Touch__c accountTouch : accountTouchesToInsert ){
                //Add the id for this account touch to still valid ids, so we can delete old irrelevant ones
                stillValidUniqueIds.add( accountTouch.Id );
        }        
    }
    
    public void finish(Database.BatchableContext BC){
        //Delete old irrelevant touches
        List<Account_Touch__c> invalidAccountTouches = [ SELECT id FROM Account_Touch__c WHERE id NOT IN : stillValidUniqueIds ];
        delete( invalidAccountTouches );
        
        if( batchType == 'One Time' ){ // Only send email on one time jobs
             //Send mail to User
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String userName = UserInfo.getUserName();
            User activeUser = [Select Email From User where Username = : userName limit 1];
            String[] toAddresses = new String[] { activeUser.Email }; 
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('LeanData');
            String emailBody = 'Hi, <br/><br/> Active Account One Time Run has been completed. <br/> Thanks, <br/> LeanData';
            mail.setHtmlBody( emailBody ); 
            mail.setSubject('Active Account One Time Run Completed.');
            if( !Test.isRunningTest() ){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
        //else{ //Only do metrics on Scheduled Jobs
            Activity_Roll_Up__c newRollUp = new Activity_Roll_Up__c( Date__c = (System.Today()-1) );
            newRollUp.Total_Accounts__c = [ SELECT count() FROM Account ];
            newRollUp.AA_Accounts_With_Marketing_Touch__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0];
            newRollUp.AA_Accounts_With_Sales_Touch__c = [ SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 ];
            newRollUp.AA_Aligned_Accounts__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND Sales_Activity_Score__c > 0];
            newRollUp.Active_Accounts__c = [ SELECT count() FROM Account WHERE Activity_Score__c > 0 ];
            
             //Get Day Range Configuration
            Integer dayRange = 120;
            for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
                dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
            }
            
            Date cutOffDate = System.Today() - dayRange;
        
            Set<String> accountsWithOpenOpps = new Set<String>();
            Set<String> accountsWithClosedWonOpps = new Set<String>();
            
            for( Opportunity o : [ SELECT AccountId , isWon, isClosed, CloseDate FROM Opportunity WHERE (( isClosed = true AND isWon = true ) OR isClosed = false) AND ( Account.Sales_Activity_Score__c > 0 OR Account.Marketing_Activity_Score__c > 0 ) ] ){
                if( o.isClosed && o.CloseDate > cutOffDate ){
                    accountsWithClosedWonOpps.add( o.AccountId );        
                }
                else{
                    accountsWithOpenOpps.add( o.AccountId );
                }
            }
            
            newRollUp.OO_Accounts_With_Marketing_Touch__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND id IN : accountsWithOpenOpps ];
            newRollUp.OO_Accounts_With_Sales_Touch__c = [ SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND id IN : accountsWithOpenOpps ];
            newRollUp.OO_Aligned_Accounts__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND Sales_Activity_Score__c > 0 AND id IN : accountsWithOpenOpps ];
            
            newRollUp.CWO_Accounts_With_Marketing_Touch__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND id IN : accountsWithClosedWonOpps] ;
            newRollUp.CWO_Accounts_With_Sales_Touch__c = [ SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND id IN : accountsWithClosedWonOpps ];
            newRollUp.CWO_Aligned_Accounts__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND Sales_Activity_Score__c > 0 AND id IN : accountsWithClosedWonOpps];
            
            
            
            delete( [ SELECT id FROM  Activity_Roll_Up__c WHERE Date__c = : (Date.Today()-1) ] );
            insert( newRollUp );
        //}
    }

}