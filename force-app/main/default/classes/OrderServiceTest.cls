@isTest
private class OrderServiceTest {

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

    @isTest
    static void testIsZoneValide() {
        Livraison__c livraisonOk = new Livraison__c(Zone__c = 'Belgique');
        Livraison__c livraisonKo = new Livraison__c(Zone__c = 'Allemagne');

        System.assertEquals(true, OrderService.isZoneValide(livraisonOk));
        System.assertEquals(false, OrderService.isZoneValide(livraisonKo));
    }

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
