@isTest
private class AccountSelectorTest {



    // - Test pour vérifier que la méthode retourne bien un compte existant
    // - Création et insertion d’un compte avec plusieurs champs remplis
    // - Appel de la méthode getAccountById avec l’ID du compte inséré
    // - Vérification que :
    //    → l’ID retourné est bien le même que celui créé
    //    → la valeur de BillingCountry est correcte

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



    // - Test pour vérifier le comportement quand l’ID donné n’existe pas
    // - Appel de la méthode getAccountById avec un faux ID (non existant dans la base)
    // - On attend une exception
    // - Si aucune exception : le test échoue (System.assert(false))
    // - Si exception levée : test réussi (System.assert(true))

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
