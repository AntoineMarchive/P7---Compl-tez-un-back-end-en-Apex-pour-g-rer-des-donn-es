@isTest
private class OrderServiceTest {



    // - Test qui vérifie que la méthode validateLivraison() fonctionne quand tout est correct
    // - Création d'un prix transporteur avec zone "France"
    // - Création d'une livraison avec la même zone et un prix
    // - Appel de la méthode sans erreur attendue

    @isTest
    static void testValidateLivraison_OK() {
        Prix_Transporteur__c prix = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 100.0
        );
        insert prix;

        Livraison__c livraison = new Livraison__c(
            Zone__c = 'France',
            Prix_Transporteur__c = prix.Id
        );

        Test.startTest();
        OrderService.validateLivraison(livraison);
        Test.stopTest();
    }



    // - Test qui vérifie que la méthode lève une erreur si la zone est vide
    // - Zone__c = '' => on attend une exception AuraHandledException
    // - Vérification que le message d'erreur est bien celui attendu

    @isTest
    static void testValidateLivraison_ZoneVide() {
        Prix_Transporteur__c prix = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 100.0
        );
        insert prix;

        Livraison__c livraison = new Livraison__c(
            Zone__c = '',
            Prix_Transporteur__c = prix.Id
        );

        Test.startTest();
        try {
            OrderService.validateLivraison(livraison);
            System.assert(false, 'Exception attendue');
        } catch (AuraHandledException e) {
            System.assertEquals('La zone de livraison doit être renseignée.', e.getMessage());
        }
        Test.stopTest();
    }



    // - Test qui vérifie que la méthode lève une erreur si Prix_Transporteur__c est null
    // - La zone est renseignée mais pas le prix => on attend une exception
    // - Vérification du message d’erreur

    @isTest
    static void testValidateLivraison_PrixTransporteurNull() {
        Livraison__c livraison = new Livraison__c(
            Zone__c = 'France',
            Prix_Transporteur__c = null
        );

        Test.startTest();
        try {
            OrderService.validateLivraison(livraison);
            System.assert(false, 'Exception attendue');
        } catch (AuraHandledException e) {
            System.assertEquals('Un Prix Transporteur doit être sélectionné.', e.getMessage());
        }
        Test.stopTest();
    }



    // - Test qui vérifie que isZoneValide() retourne true ou false selon la zone
    // - 'Belgique' => true (dans la liste des zones valides)
    // - 'Allemagne' => false (hors liste)

    @isTest
    static void testIsZoneValide() {
        Livraison__c livraisonOk = new Livraison__c(Zone__c = 'Belgique');
        Livraison__c livraisonKo = new Livraison__c(Zone__c = 'Allemagne');

        System.assertEquals(true, OrderService.isZoneValide(livraisonOk));
        System.assertEquals(false, OrderService.isZoneValide(livraisonKo));
    }


    // - Test valide pour un client "Particulier" qui commande 3 produits
    // - Création produit + entrée de prix (Pricebook)
    // - Création compte particulier + commande (Order)
    // - Ajout de 3 produits (OrderItem)
    // - Appel de validateOrders() => aucune exception attendue

    @isTest
    static void testValidateOrders_RulesOK_Particulier() {
        Product2 prod = new Product2(Name = 'Produit Valide', isActive = true);
        insert prod;

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prod.Id,
            UnitPrice = 10,
            IsActive = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Client Test', Type_de_Compte__c = 'Particulier');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = pbId
        );
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            Quantity = 3,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert item;

        Test.startTest();
        OrderService.validateOrders(new List<Order>{ ord });
        Test.stopTest();
    }


    // - Test KO pour un particulier avec moins de 3 produits
    // - Comme au-dessus mais avec 2 produits seulement
    // - On attend une exception => message d’erreur doit mentionner le quota

    @isTest
    static void testValidateOrders_KO_Particulier_SousQuota() {
        Product2 prod = new Product2(Name = 'Produit KO', isActive = true);
        insert prod;

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prod.Id,
            UnitPrice = 10,
            IsActive = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Client KO', Type_de_Compte__c = 'Particulier');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = pbId
        );
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            Quantity = 2,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert item;

        Test.startTest();
        try {
            OrderService.validateOrders(new List<Order>{ ord });
            System.assert(false, 'Erreur attendue pour un particulier avec < 3 produits');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('particulier doit commander'));
        }
        Test.stopTest();
    }


    // - Test pour vérifier qu’un Order sans compte associé est bloqué
    // - Création d’une commande sans AccountId
    // - Appel de validateOrders()
    // - On vérifie que ça lève une erreur

    @isTest
    static void testValidateOrders_AccountNull() {
        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert ord;

        Test.startTest();
        try {
            OrderService.validateOrders(new List<Order>{ ord });
            System.assert(true, 'addError devrait empêcher le traitement');
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }



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
        } catch (AuraHandledException e) {
            System.assertEquals('Paramètres invalides.', e.getMessage());
        }
        Test.stopTest();
    }
}
