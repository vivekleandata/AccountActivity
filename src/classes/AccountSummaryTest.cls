@isTest ( SeeAllData = True )                  
private class AccountSummaryTest {
    static testmethod void testAccountSummaryController(){

        PageReference pageRef = new pageReference( '/apex/AccountSummary?objt=Account' );
        Test.setCurrentPage(pageRef);
      
        AccountSummaryController con = new AccountSummaryController();
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('objt', 'Account');
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AA');
        con = new AccountSummaryController();
        con.getEnabledSelectOptions();
        con.selectAll();
        con.toggleSort();
        con.resetSpecialQueryMode();
        con.TurnOffFilter();
        
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MA');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SA');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AAOO');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MAOO');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SAOO');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SACWO');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AACWO');
        con = new AccountSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MACSWO');
        con = new AccountSummaryController();
    }
}