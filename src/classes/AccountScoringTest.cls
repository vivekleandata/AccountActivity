@isTest           ( SeeAllData = True )                  
private class AccountScoringTest {
    static testmethod void testAccountScoreSettingsController(){
        AccountScoreSettingsController con = new AccountScoreSettingsController();
        con.saveAccountScoringSettings();
        
        Account a = new Account( Name='Test Acc' );
        insert( a );
        Campaign c = new Campaign( Name='Test C' );
        insert( c );
        CampaignMemberStatus CM = new CampaignMemberStatus( Label='Test', CampaignId = c.Id, SortOrder=0 );
        insert( CM );
        Test.startTest();
            con.runAccountScoring();
            con.scheduleAccountScoring();
        Test.stopTest();
    }
}