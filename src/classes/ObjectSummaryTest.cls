@isTest ( SeeAllData = True )                  
private class ObjectSummaryTest {
    static testmethod void testObjectSummaryController(){
       /* ObjectSummaryController con = new ObjectSummaryController();
        con.objType = 'Account';
        con.verifiedSettings = true;
        con.setObjectType();
        con.setFields();
        con.runFullSearch();
        con.nextPage();
        con.previousPage();
        con.getEnabledSelectOptions();
        con.selectAll();
        con.toggleSort();
        con.resetSpecialQueryMode();
        //con.TurnOffFilter();
        */
        PageReference pageRef = new pageReference( '/apex/ObjectSummary?objt=Account' );
        Test.setCurrentPage(pageRef);
      
        ObjectSummaryController con = new ObjectSummaryController();
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('objt', 'Account');
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AA');
        con = new ObjectSummaryController();
        con.getEnabledSelectOptions();
        con.selectAll();
        con.toggleSort();
        con.resetSpecialQueryMode();
        con.TurnOffFilter();
        
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MA');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SA');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AAOO');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MAOO');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SAOO');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'SACWO');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'AACWO');
        con = new ObjectSummaryController();
        ApexPages.currentPage().getParameters().put('specialQueryMode', 'MACSWO');
        con = new ObjectSummaryController();
    }
}