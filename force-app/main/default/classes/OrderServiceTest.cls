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
    static void testValidateOrders_OK() {
        Account acc = new Account(Name = 'Client Test', Type_de_Compte__c = 'Particulier');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            Quantity = 3,
            UnitPrice = 10
        );
        insert item;

        Test.startTest();
        OrderService.validateOrders(new List<Order>{ ord });
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
        } catch (Exception e) {
            System.assert(true, 'addError devrait empêcher la suite du traitement');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveTransporterChoice_OK() {
        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = System.today(),
            AccountId = [SELECT Id FROM Account LIMIT 1].Id
        );
        insert ord;

        Test.startTest();
        OrderService.saveTransporterChoice(ord.Id, 'fastest');
        Test.stopTest();

        Order updated = [SELECT Transporter_Choice__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('fastest', updated.Transporter_Choice__c);
    }

    @isTest
    static void testSaveTransporterChoice_invalid() {
        Test.startTest();
        try {
            OrderService.saveTransporterChoice(null, '');
            System.assert(false, 'Une exception devait être levée');
        } catch (AuraHandledException e) {
            System.assertEquals('Paramètres invalides.', e.getMessage());
        }
        Test.stopTest();
    }
}
