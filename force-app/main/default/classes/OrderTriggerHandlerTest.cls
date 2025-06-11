@isTest
private class OrderTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Création du produit de base
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        Id stdPbId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPbId,
            UnitPrice = 10,
            IsActive = true
        );
        insert pbe;

        // Prix transporteur
        insert new Prix_Transporteur__c(Zone__c = 'France', Tarif__c = 5.00);

        // Comptes clients
        insert new Account[] {
            new Account(Name = 'Pro OK', BillingCountry = 'France', Type_de_Compte__c = 'Professionnel'),
            new Account(Name = 'Pro KO', BillingCountry = 'France', Type_de_Compte__c = 'Professionnel'),
            new Account(Name = 'Particulier OK', BillingCountry = 'France', Type_de_Compte__c = 'Particulier'),
            new Account(Name = 'Particulier KO', BillingCountry = 'France', Type_de_Compte__c = 'Particulier')
        };
    }

    @isTest
    static void testCommandesValides_CreentLivraison() {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name LIKE '%OK%'];

        List<Order> orders = new List<Order>();
        for (Account acc : accounts) {
            orders.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = Test.getStandardPricebookId(),
                Name = 'Commande ' + acc.Name
            ));
        }
        insert orders;

        // Création de plusieurs OrderItems (produits différents)
        List<OrderItem> items = new List<OrderItem>();
        for (Order ord : orders) {
            Integer nbLignes = ord.Name.contains('Pro') ? 5 : 3; // 5 produits différents pour pro, 3 pour particulier
            for (Integer i = 0; i < nbLignes; i++) {
                items.add(new OrderItem(
                    OrderId = ord.Id,
                    PricebookEntryId = [SELECT Id FROM PricebookEntry LIMIT 1].Id,
                    Quantity = 1,
                    UnitPrice = 10
                ));
            }
        }
        insert items;

        for (Order ord : orders) {
            ord.Status = 'Activated';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        List<Livraison__c> livraisons = [SELECT Id FROM Livraison__c];
        System.assertEquals(2, livraisons.size(), 'Deux livraisons attendues pour les commandes valides.');
    }

    @isTest
    static void testCommandeProInvalide_RaiseException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Pro KO' LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < 3; i++) { // Seulement 3 produits → KO pour pro
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = [SELECT Id FROM PricebookEntry LIMIT 1].Id,
                Quantity = 1,
                UnitPrice = 10
            ));
        }
        insert items;

        ord.Status = 'Activated';

        Test.startTest();
        try {
            update ord;
            System.assert(false, 'Une exception aurait dû être levée.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('professionnels'), 'Message d’erreur incorrect.');
        }
        Test.stopTest();
    }

    @isTest
    static void testCommandeParticulierInvalide_RaiseException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Particulier KO' LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < 1; i++) { // 1 seul produit → KO pour particulier
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = [SELECT Id FROM PricebookEntry LIMIT 1].Id,
                Quantity = 1,
                UnitPrice = 10
            ));
        }
        insert items;

        ord.Status = 'Activated';

        Test.startTest();
        try {
            update ord;
            System.assert(false, 'Une exception aurait dû être levée.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('particuliers'), 'Message d’erreur incorrect.');
        }
        Test.stopTest();
    }
}
