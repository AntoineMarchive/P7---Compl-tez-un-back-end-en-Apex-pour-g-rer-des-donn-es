@isTest
private class AccountSelectorTest {

    @isTest
    static void testGetAccountById_OK() {
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Prospect',
            Industry = 'Technology',
            BillingCity = 'Paris',
            BillingCountry = 'France',
            Phone = '0123456789',
            Website = 'https://test.com'
        );
        insert acc;

        Test.startTest();
        Account result = AccountSelector.getAccountById(acc.Id);
        Test.stopTest();

        System.assertEquals(acc.Id, result.Id);
        System.assertEquals('France', result.BillingCountry);
    }

    @isTest
    static void testGetAccountById_InexistantId() {
        Test.startTest();
        Account result;
        try {
            result = AccountSelector.getAccountById('001000000000000AAA');
            System.assert(false, 'Exception attendue');
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}
