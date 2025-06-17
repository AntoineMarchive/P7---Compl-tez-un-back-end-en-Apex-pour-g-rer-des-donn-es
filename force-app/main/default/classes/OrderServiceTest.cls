@isTest
private class OrderServiceTest {



    // - Test qui vérifie que la méthode validateLivraison() fonctionne quand tout est correct
    // - Création d'un prix transporteur avec zone "France"
    // - Création d'une livraison avec la même zone et un prix
    // - Appel de la méthode sans erreur attendue




    // - Test qui vérifie que isZoneValide() retourne true ou false selon la zone
    // - 'Belgique' => true (dans la liste des zones valides)
    // - 'Allemagne' => false (hors liste)

    // @isTest
    // static void testIsZoneValide() {
    //     Livraison__c livraisonOk = new Livraison__c(Zone__c = 'Belgique');
    //     Livraison__c livraisonKo = new Livraison__c(Zone__c = 'Allemagne');

    //     System.assertEquals(true, OrderService.isZoneValide(livraisonOk));
    //     System.assertEquals(false, OrderService.isZoneValide(livraisonKo));
    // }



    // - Test qui vérifie que saveTransporterChoice() crée bien une Livraison
    // - Création d’un compte et d’une commande
    // - Création d’un Prix_Transporteur__c
    // - Appel de saveTransporterChoice() avec les bons Ids
    // - On récupère la Livraison__c créée et on vérifie :
    //   - la zone, le transporteur, le mode de livraison

    @isTest
    static void testSaveTransporterChoice_OK() {
        Account acc = new Account(Name = 'Client', BillingCountry = 'France');
        insert acc;

        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = System.today(),
            AccountId = acc.Id
        );
        insert ord;

        Prix_Transporteur__c prix = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 20.0
        );
        insert prix;

        Test.startTest();
        OrderService.saveTransporterChoice(ord.Id, prix.Id);
        Test.stopTest();

        Livraison__c livraison = [SELECT Id, Zone__c, Prix_Transporteur__c, Mode_de_Livraison__c
                                  FROM Livraison__c WHERE Order__c = :ord.Id LIMIT 1];
        System.assertEquals('France', livraison.Zone__c);
        System.assertEquals(prix.Id, livraison.Prix_Transporteur__c);
        System.assertEquals('Choisi manuellement', livraison.Mode_de_Livraison__c);
    }



    // - Test pour vérifier que la méthode lève une erreur si les paramètres sont null
    // - Appel avec des null en entrée
    // - On attend une exception avec le message 'Paramètres invalides.'

    @isTest
    static void testSaveTransporterChoice_invalid() {
        Test.startTest();
        try {
            OrderService.saveTransporterChoice(null, null);
            System.assert(false, 'Une exception devait être levée');
        } catch (CustomException e) {
            System.assertEquals('Paramètres invalides.', e.getMessage());
        }
        Test.stopTest();
    }
}
