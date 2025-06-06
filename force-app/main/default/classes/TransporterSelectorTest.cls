@isTest
private class TransporterSelectorTest {


    //  Test qui vérifie que la méthode retourne le transporteur avec le prix le plus bas
    // - Création de deux Prix_Transporteur__c pour la zone 'France' (20€ et 10€)
    // - On attend que la méthode retourne celui à 10€

    @isTest
    static void testGetBestPrixTransporteurIdForZone_OK() {
        Prix_Transporteur__c p1 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 20.0
        );
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 10.0
        );
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('France');
        Test.stopTest();

        System.assertEquals(p2.Id, result);
    }


    // - Test quand la zone recherchée n’a pas de correspondance
    // - Un transporteur existe pour 'France'
    // - La méthode est appelée avec la zone 'Suisse' => aucun match attendu => résultat null

    @isTest
    static void testGetBestPrixTransporteurIdForZone_NoMatch() {
        insert new Prix_Transporteur__c(Zone__c = 'France', Tarif__c = 15.0);

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('Suisse');
        Test.stopTest();

        System.assertEquals(null, result);
    }


    // - Test si on appelle la méthode avec une zone vide
    // - La méthode doit retourner null (pas d'erreur mais pas de résultat)

    @isTest
    static void testGetBestPrixTransporteurIdForZone_BlankInput() {
        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('');
        Test.stopTest();

        System.assertEquals(null, result);
    }


    // - Test de la méthode qui retourne tous les transporteurs
    // - Création d’un transporteur
    // - On s’assure que la liste retournée par getAllTransporters() contient au moins 1 résultat

    @isTest
    static void testGetAllTransporters_OK() {
        insert new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 15.0
        );

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getAllTransporters();
        Test.stopTest();

        System.assert(result.size() > 0);
    }


    // - Test qui vérifie le tri par rapidité ('fastest')
    // - Création d’un compte et d’une commande (Order liée à un client)
    // - Création de 2 transporteurs avec des délais différents (3 jours et 1 jour)
    // - Appel de getFilteredTransporters avec option 'fastest'
    // - On vérifie que seul le transporteur le plus rapide est retourné (celui avec 1 jour)

    @isTest
    static void testGetFilteredTransporters_OK_fastest() {
        Account acc = new Account(Name='Client', BillingCountry='France');
        insert acc;

        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id
        );
        insert ord;

        Prix_Transporteur__c p1 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=20, Delai_jours__c=3);
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=30, Delai_jours__c=1);
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getFilteredTransporters(ord.Id, 'fastest');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(p2.Id, result[0].Id);
    }



    // - Test qui vérifie le tri par prix ('cheapest')
    // - Même logique que le test précédent, mais avec des tarifs différents (20€ et 10€)
    // - Option passée : 'cheapest'
    // - On vérifie que seul le transporteur le moins cher est retourné

    @isTest
    static void testGetFilteredTransporters_OK_cheapest() {
        Account acc = new Account(Name='Client', BillingCountry='France');
        insert acc;

        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id
        );
        insert ord;

        Prix_Transporteur__c p1 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=20, Delai_jours__c=2);
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=10, Delai_jours__c=3);
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getFilteredTransporters(ord.Id, 'cheapest');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(p2.Id, result[0].Id);
    }



    // - Test pour vérifier que la méthode lève une erreur si les paramètres sont invalides
    // - Paramètres : orderId null et option vide => AuraHandledException attendue
    // - On vérifie que le message d’erreur correspond à 'Paramètres manquants.'

    @isTest
    static void testGetFilteredTransporters_InvalidParams() {
        Test.startTest();
        try {
            TransporterSelector.getFilteredTransporters(null, '');
            System.assert(false, 'Exception attendue');
        } catch (AuraHandledException e) {
            System.assertEquals('Paramètres manquants.', e.getMessage());
        }
        Test.stopTest();
    }
}
