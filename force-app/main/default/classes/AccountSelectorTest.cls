@isTest
public class AccountSelectorTest {

    @isTest
    static void testGetAccountById() {
        // Création d'un compte de test
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Particulier',
            BillingCountry = 'France'
        );
        insert acc;

        // Appel de la méthode à tester
        Account result = AccountSelector.getAccountById(acc.Id);

        // Vérifications
        System.assertNotEquals(null, result, 'Le compte retourné ne doit pas être null');
        System.assertEquals(acc.Name, result.Name, 'Le nom du compte doit correspondre');
        System.assertEquals(acc.Type, result.Type, 'Le type du compte doit correspondre');
        System.assertEquals(acc.BillingCountry, result.BillingCountry, 'Le pays de facturation doit correspondre');
    }
}
