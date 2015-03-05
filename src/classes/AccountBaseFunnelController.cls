public with sharing class AccountBaseFunnelController {
    public influenceWrapper customAccountsInfluence { get;set; }
    
    //Funnel Bars
    public influenceWrapper totalAccountsInfluence { get;set; }
    public influenceWrapper activeAccountsInfluence { get;set; }
    public influenceWrapper accountsWithOppInfluence { get;set; }
    public influenceWrapper accountsWithClosedOppsInfluence { get;set; }

    //Search Filters
    public List<List<genericSelector>> accountTypeSelector { get;set; }
    public List<List<genericSelector>> opportunityStageSelector { get;set; }
    public String customFieldName { get;set; }
    public String customFieldValue { get;set; }
            
    //Metrics
    public Activity_Roll_Up__c latestRollUp { get;set; }
    public Activity_Roll_Up__c lastDayRollUp { get;set; }
    public Activity_Roll_Up__c lastQuarterRollUp { get;set; }
    public Activity_Roll_Up__c lastYearRollUp { get;set; }
    public Activity_Roll_Up__c realTimeRollUp { get;set; }
    
    public influenceChange dailyChange { get;set; }
    public influenceChange quarterlyChange { get;set; }
    public influenceChange yearlyChange { get;set; }
    
    public Decimal totalOpenOppAmount { get;set; }
    public Decimal totalClosedWonOppAmount { get;set; }
    
    //Classes
    public class genericSelector{
        public String Label { get;set; }
        public Boolean isSelected { get;set; }
        
        public genericSelector( String L ){
            Label = L;
            isSelected = False;
        }
        public genericSelector( String L , Boolean B){
            Label = L;
            isSelected = B;
        }
    }
    public class influenceChange{
        public Decimal salesOnlyChange{ get;set; }
        public Decimal alignedChange { get;set; }
        public Decimal marketingOnlyChange { get;set; }
        public Decimal salesOnlyChangeOO{ get;set; }
        public Decimal alignedChangeOO { get;set; }
        public Decimal marketingOnlyChangeOO { get;set; }
        public Decimal salesOnlyChangeCWO{ get;set; }
        public Decimal alignedChangeCWO { get;set; }
        public Decimal marketingOnlyChangeCWO { get;set; }
        
        public Decimal activeAccountChange { get;set; }
        public Decimal activeAccountOOChange { get;set; }
        public Decimal activeAccountCWOChange { get;set; }
        
        public Activity_Roll_Up__c oldRollUp { get;set; }
        public Activity_Roll_Up__c newRollUp { get;set; }
        
        public influenceChange( Activity_Roll_Up__c OldR, Activity_Roll_Up__c NR ){
            oldRollUp = OldR;
            newRollUp = NR;

            salesOnlyChange = ( NR.AA_Sales_Percentage__c  - OldR.AA_Sales_Percentage__c );
            marketingOnlyChange = ( NR.AA_Marketing_Percentage__c  - OldR.AA_Marketing_Percentage__c );
            alignedChange = ( NR.AA_Aligned_Percentage__c  - OldR.AA_Aligned_Percentage__c );  
            
            salesOnlyChangeOO = ( NR.OO_Sales_Percentage__c  - OldR.OO_Sales_Percentage__c );
            marketingOnlyChangeOO = ( NR.OO_Marketing_Percentage__c  - OldR.OO_Marketing_Percentage__c );
            alignedChangeOO = ( NR.OO_Aligned_Percentage__c  - OldR.OO_Aligned_Percentage__c ); 
             
            salesOnlyChangeCWO = ( NR.CWO_Sales_Percentage__c  - OldR.CWO_Sales_Percentage__c );
            marketingOnlyChangeCWO = ( NR.CWO_Marketing_Percentage__c  - OldR.CWO_Marketing_Percentage__c );
            alignedChangeCWO = ( NR.CWO_Aligned_Percentage__c  - OldR.CWO_Aligned_Percentage__c );  
            
            activeAccountChange = NR.active_Accounts__c - OldR.active_Accounts__c;
            activeAccountOOChange = NR.OO_Total_Accounts__c - OldR.OO_Total_Accounts__c;
            activeAccountCWOChange = NR.CWO_Total_Accounts__c - OldR.CWO_Total_Accounts__c;
        }
        
    }
    public class influenceWrapper{
        public Decimal salesAccounts { get;set; }
        public Decimal bothAccounts { get;set; }
        public Decimal marketingAccounts { get;set; }
        public Integer salesPercentage { get;set; }
        public Integer bothPercentage { get;set; }
        public Integer marketingPercentage { get;set; }
        public Decimal totalAccounts { get;set; }
        
        // Opportunity Amounts 
        public Decimal totalSalesOnlyOppAmount { get;set; }
        public Decimal totalAlignedOppAmount { get;set; }
        public Decimal totalMarketingOnlyOppAmount { get;set; }
        
         // Only used for top funnel which counts all accounts
        public Decimal allAccounts { get;set; }
        public Decimal noActivityAccounts { get;set; }
        public Integer noActivityAccountsPercentage { get;set; }
        
        public influenceWrapper( Decimal s, Decimal b, Decimal m ){
            salesAccounts = Integer.ValueOf( s );
            bothAccounts = Integer.ValueOf( b );
            marketingAccounts = Integer.ValueOf( m );
            totalAccounts = salesAccounts + bothAccounts + marketingAccounts;
            if( totalAccounts > 0 ){
                salesPercentage = Integer.ValueOf( ((salesAccounts / totalAccounts) * 100).setScale(0, RoundingMode.HALF_DOWN) );
                bothPercentage = Integer.ValueOf( (bothAccounts / totalAccounts  * 100).setScale(0, RoundingMode.HALF_UP) );
                marketingPercentage = Integer.ValueOf( ( marketingAccounts / totalAccounts * 100 ).setScale(0, RoundingMode.HALF_DOWN) );
            }
            if( salesPercentage + bothPercentage + marketingPercentage  > 100 ){
                marketingPercentage = marketingPercentage - 1;
            }
        }   
        public influenceWrapper( Decimal s, Decimal b, Decimal m, Decimal SOO, Decimal AOO, Decimal MOO ){
            salesAccounts = Integer.ValueOf( s );
            bothAccounts = Integer.ValueOf( b );
            marketingAccounts = Integer.ValueOf( m );
            totalSalesOnlyOppAmount = SOO;
            totalAlignedOppAmount = AOO;
            totalMarketingOnlyOppAmount = MOO;
            
            totalAccounts = salesAccounts + bothAccounts + marketingAccounts;
            if( totalAccounts > 0 ){
                salesPercentage = Integer.ValueOf( ((salesAccounts / totalAccounts) * 100).setScale(0, RoundingMode.HALF_DOWN) );
                bothPercentage = Integer.ValueOf( (bothAccounts / totalAccounts  * 100).setScale(0, RoundingMode.HALF_UP) );
                marketingPercentage = Integer.ValueOf( ( marketingAccounts / totalAccounts * 100 ).setScale(0, RoundingMode.HALF_DOWN) );
            }
            if( salesPercentage + bothPercentage + marketingPercentage  > 100 ){
                marketingPercentage = marketingPercentage - 1;
            }
        }   
        public influenceWrapper( Decimal s, Decimal b, Decimal m , Decimal everyAcc ){
            salesAccounts = Integer.ValueOf( s );
            bothAccounts = Integer.ValueOf( b );
            marketingAccounts = Integer.ValueOf( m );
            totalAccounts = salesAccounts + bothAccounts + marketingAccounts;
            allAccounts = everyAcc;
            if( totalAccounts > 0 ){
                salesPercentage = Integer.ValueOf( ((salesAccounts / allAccounts) * 100 ).setScale(0, RoundingMode.HALF_UP) );
                bothPercentage = Integer.ValueOf( (bothAccounts / allAccounts  * 100).setScale(0, RoundingMode.HALF_UP) );
                marketingPercentage = Integer.ValueOf( (marketingAccounts / allAccounts * 100 ).setScale(0, RoundingMode.HALF_UP) );
            }
            if( salesPercentage + bothPercentage + marketingPercentage  > 100 ){
                marketingPercentage = marketingPercentage - 1;
            }
            
            noActivityAccountsPercentage = 100 - (salesPercentage + bothPercentage + marketingPercentage );
            noActivityAccounts = allAccounts - totalAccounts;
        }  
        
    }
    public AccountBaseFunnelController(){
        initializeSelectors();
        buildReport();
        buildFunnel();
        buildMetrics();
    }
    public void initializeSelectors(){
        accountTypeSelector = new List<List<genericSelector>>();
        Schema.DescribeFieldResult fieldResult = Account.Type.getDescribe();
        List<Schema.PicklistEntry> accountTypes = fieldResult.getPicklistValues();
        
        Integer iter = 1;
        Integer row = 0;
        for( Schema.PicklistEntry accountPickListValue : accountTypes ) {
            if ( iter == 6 ){
                iter = 1;
                row++;
            }    
            if( iter == 1 ){
                accountTypeSelector.add(new List<genericSelector>{ new genericSelector( accountPickListValue.getLabel(), true ) } );
            }
            else{ 
                accountTypeSelector[row].add(new genericSelector( accountPickListValue.getLabel(), true));
            }
            iter++;
        } 
        
        
        opportunityStageSelector = new List<List<genericSelector>>();
        Schema.DescribeFieldResult fieldResult2 = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> stageTypes = fieldResult2.getPicklistValues();
        
        iter = 1;
        row = 0;
        for( Schema.PicklistEntry stagePickListValue : stageTypes ) {
            if ( iter == 6 ){
                iter = 1;
                row++;
            }    
            if( iter == 1 ){
                opportunityStageSelector.add(new List<genericSelector>{ new genericSelector( stagePickListValue.getLabel(), true ) } );
            }
            else{ 
                opportunityStageSelector[row].add(new genericSelector( stagePickListValue.getLabel(), true));
            }
            iter++;
        } 
    }
    public void buildReport(){
        String extraAccountSoql ='';
        Set<String> validAccountIds = new Set<String>(); //Stores a set of Valid Account Ids as per filter
        
        //Account Type Filter
        List<String> includedAccountTypes =  new List<String>();
        for( List<genericSelector> accountSelList : accountTypeSelector ){
            for( genericSelector accountSel : accountSelList ) {
                if( accountSel.isSelected ){
                    includedAccountTypes.add( accountSel.Label );
                }
            }
        }
        
        //Opportunity Stage filter
        Set<String> includedOpportunityStages =  new Set<String>();
        for( List<genericSelector> oppStageList : OpportunityStageSelector ){
            for( genericSelector oppStage : oppStageList ) {
                if( oppStage.isSelected ){
                    includedOpportunityStages.add( oppStage.Label );
                }
            }
        }
        
        for( Opportunity validOpp : [ SELECT AccountId FROM Opportunity WHERE StageName IN : includedOpportunityStages ] ){
            validAccountIds.add( validOpp.AccountId );
        }
        
        String customFilter;
        
        if( customFieldName != null && customFieldValue != null && customFieldName != '' && customFieldValue != '' ){
            customFilter = ' AND ' + customFieldName + ' = ' + customFieldValue;     
        }
        
        
        extraAccountSoql += ' AND Type IN : includedAccountTypes AND Id IN : validAccountIds ';
               
        if( customFilter != null )
            extraAccountSoql += customFilter;
        
        String salesAccountsSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c = 0 ' + extraAccountSoql;
        String bothAccountsSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c > 0 ' + extraAccountSoql;
        String marketingAccountsSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c = 0 AND Marketing_Activity_Score__c > 0 ' + extraAccountSoql;

        try{
            customAccountsInfluence = new influenceWrapper( database.countQuery( salesAccountsSoql ), database.countQuery( bothAccountsSoql ), database.countQuery( marketingAccountsSoql ) );
        } catch( exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'Error in Query, check Custom Field Filter.'));  
        }

        
    }
    public void buildFunnel(){
        Set<String> openOppAccounts = new Set<String>(); //Stores Accounts w/ Open Opps
        Set<String> closedWonOppAccounts = new Set<String>(); //Stores Accounts w/ Closed Won Opps
        
        //Get Day Range Configuration
        Integer dayRange = 120;
        for( Activity_Score_Setting__c activityScoreSetting : [ SELECT Type__c, Value__c FROM Activity_Score_Setting__c WHERE Type__c = 'DayRange' ] ){
            dayRange = Integer.ValueOf( activityScoreSetting.Value__c );
        }
        
        Date cutOffDate = System.Today() - dayRange;
        
        for( Opportunity validOpp : [ SELECT AccountId, isClosed, isWon, CloseDate FROM Opportunity WHERE ( isClosed = true AND isWon = true ) OR isClosed = false ] ){
            System.debug( ' Cut Off Date ' + cutOffDate );
            System.debug( ' Opp Close Date ' + validOpp.CloseDate );
            if( validOpp.isWon && validOpp.CloseDate >= cutOffDate  ){
                openOppAccounts.add( validOpp.AccountId );
                closedWonOppAccounts.add( validOpp.AccountId );
            }
            else{
                openOppAccounts.add( validOpp.AccountId );
            }    
        }
        
                
        String baseSalesSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c = 0 ';
        String baseBothSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 AND Marketing_Activity_Score__c > 0 ';
        String baseMarketingSoql = ' SELECT count() FROM Account WHERE Sales_Activity_Score__c = 0 AND Marketing_Activity_Score__c > 0 ';
        Decimal totalOpenOppSales, totalOpenOppAligned, totalOpenOppMarketing, totalClosedWonSales, totalClosedWonAligned, totalClosedWonMarketing = 0;
        try{
            totalOpenOppSales = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = False AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c = 0 ][0].get('amt');
            totalOpenOppAligned = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = False AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c > 0 ][0].get('amt');
            totalOpenOppMarketing = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = False AND Account.Sales_Activity_Score__c = 0 AND Account.Marketing_Activity_Score__c > 0 ][0].get('amt');
        } catch( exception e ){
            System.debug( e ) ;
        }
        try{
            totalClosedWonSales = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = True AND isWon = True AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c = 0 ][0].get('amt');
            totalClosedWonAligned = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = True AND isWon = True AND Account.Sales_Activity_Score__c > 0 AND Account.Marketing_Activity_Score__c > 0 ][0].get('amt');
            totalClosedWonMarketing = ( Decimal )[ SELECT SUM( Amount ) amt FROM Opportunity WHERE isClosed = True AND isWon = True AND Account.Sales_Activity_Score__c = 0 AND Account.Marketing_Activity_Score__c > 0 ][0].get('amt');
        } catch( exception e ){
            System.debug( e ) ;
        }
        
        totalAccountsInfluence = new influenceWrapper( database.countQuery( baseSalesSoql ), database.countQuery( baseBothSoql ), database.countQuery( baseMarketingSoql ) , [SELECT count() FROM Account]);
        activeAccountsInfluence = new influenceWrapper( database.countQuery( baseSalesSoql ), database.countQuery( baseBothSoql ), database.countQuery( baseMarketingSoql ) );
        accountsWithOppInfluence =  new influenceWrapper( database.countQuery( baseSalesSoql + ' AND Id IN : openOppAccounts '), database.countQuery( baseBothSoql  + ' AND Id IN : openOppAccounts ' ), database.countQuery( baseMarketingSoql  + ' AND Id IN : openOppAccounts ') , totalOpenOppSales, totalOpenOppAligned, totalOpenOppMarketing);
        accountsWithClosedOppsInfluence =  new influenceWrapper( database.countQuery( baseSalesSoql  + ' AND Id IN : closedWonOppAccounts '), database.countQuery( baseBothSoql+ ' AND Id IN : closedWonOppAccounts  ' ), database.countQuery( baseMarketingSoql+ ' AND Id IN : closedWonOppAccounts ' ) , totalClosedWonSales, totalClosedWonSales, totalClosedWonSales);
       
    }
    public void buildMetrics(){
        try{
            lastDayRollUp = [ SELECT id, Date__c, AA_Aligned_Accounts__c, Active_Accounts__c, Total_Accounts__c,
            AA_Accounts_With_Marketing_Touch__c, AA_Accounts_With_Sales_Touch__c, AA_Aligned_Percentage__c, AA_Marketing_Percentage__c, AA_Sales_Percentage__c, 
                            OO_Accounts_With_Marketing_Touch__c, OO_Accounts_With_Sales_Touch__c, OO_Aligned_Percentage__c, OO_Marketing_Percentage__c, OO_Sales_Percentage__c, OO_Total_Accounts__c,
                            CWO_Accounts_With_Marketing_Touch__c, CWO_Accounts_With_Sales_Touch__c, CWO_Aligned_Percentage__c, CWO_Marketing_Percentage__c, CWO_Sales_Percentage__c, CWO_Total_Accounts__c                        
                            FROM Activity_Roll_Up__c ORDER BY Date__c DESC limit 1 OFFSET 1];
         } catch( exception e ){
             System.debug( ' No Latest Roll Up. ' );
         }  
        try{
            latestRollUp = [ SELECT id, Date__c, AA_Aligned_Accounts__c, Active_Accounts__c, Total_Accounts__c,
            AA_Accounts_With_Marketing_Touch__c, AA_Accounts_With_Sales_Touch__c, AA_Aligned_Percentage__c, AA_Marketing_Percentage__c, AA_Sales_Percentage__c, 
                            OO_Accounts_With_Marketing_Touch__c, OO_Accounts_With_Sales_Touch__c, OO_Aligned_Percentage__c, OO_Marketing_Percentage__c, OO_Sales_Percentage__c, OO_Total_Accounts__c,
                            CWO_Accounts_With_Marketing_Touch__c, CWO_Accounts_With_Sales_Touch__c, CWO_Aligned_Percentage__c, CWO_Marketing_Percentage__c, CWO_Sales_Percentage__c, CWO_Total_Accounts__c                        
                            FROM Activity_Roll_Up__c ORDER BY Date__c DESC limit 1];
         } catch( exception e ){
             System.debug( ' No Latest Roll Up. ' );
         }   
         
         realTimeRollUp = new Activity_Roll_Up__c(  ); 
         realTimeRollUp.Total_Accounts__c = [ SELECT count() FROM Account ];
         realTimeRollUp.AA_Accounts_With_Marketing_Touch__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0];
         realTimeRollUp.AA_Accounts_With_Sales_Touch__c = [ SELECT count() FROM Account WHERE Sales_Activity_Score__c > 0 ];
         realTimeRollUp.AA_Aligned_Accounts__c = [ SELECT count() FROM Account WHERE Marketing_Activity_Score__c > 0 AND Sales_Activity_Score__c > 0];
         realTimeRollUp.Active_Accounts__c = [ SELECT count() FROM Account WHERE Activity_Score__c > 0 ];

            
            if( latestRollUp != null && lastDayRollUp!= null)
                dailyChange = new InfluenceChange( lastDayRollUp, latestRollUp );
         

    }
    public static Integer getTotalAccounts(){
        return( [ SELECT count() FROM Account ] );
    }
}