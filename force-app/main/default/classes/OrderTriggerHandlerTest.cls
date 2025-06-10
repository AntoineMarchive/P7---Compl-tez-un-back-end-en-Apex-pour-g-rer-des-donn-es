@isTest
private class OrderTriggerHandlerTest {

    // Stockage d’éléments communs (réutilisables dans les tests)
    @testVisible
    private static Id pbeId;


    @isTest
    static void setupData() {
        // Création du produit
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        // Récupération de l’ID du pricebook standard
        Id stdPbId = Test.getStandardPricebookId();

        // Création d’un PricebookEntry actif
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPbId,
            UnitPrice = 10,
            IsActive = true
        );
        insert pbe;
        pbeId = pbe.Id;

        // Prix transporteur factice avec tarif pour la zone France
        Prix_Transporteur__c pt = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 5.00
        );
        insert pt;

        // Création des comptes test
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

        List<OrderItem> items = new List<OrderItem>();
        for (Order ord : orders) {
            Integer qty = ord.Name.contains('Pro') ? 5 : 3;
            items.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = OrderTriggerHandlerTest.pbeId,
                Quantity = qty,
                UnitPrice = 10
            ));
        }
        insert items;

        for (Order ord : orders) {
            ord.Status = 'Activated';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        List<Livraison__c> livraisons = [SELECT Id, Order__c FROM Livraison__c];
        System.assertEquals(2, livraisons.size(), 'Deux livraisons doivent être créées pour les commandes valides.');
    }

    @isTest
    static void testCommandeProInvalide_RaiseException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Pro KO' LIMIT 1];
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'Commande Pro KO'
        );
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = OrderTriggerHandlerTest.pbeId,
            Quantity = 2, // < 5 → invalide
            UnitPrice = 10
        );
        insert item;

        ord.Status = 'Activated';

        Test.startTest();
        try {
            update ord;
            System.assert(false, 'Une exception aurait dû être levée.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('professionnels'), 'Le message doit concerner les professionnels.');
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
            Pricebook2Id = Test.getStandardPricebookId(),
            Name = 'Commande Particulier KO'
        );
        insert ord;

        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = OrderTriggerHandlerTest.pbeId,
            Quantity = 1, // < 3 → invalide
            UnitPrice = 10
        );
        insert item;

        ord.Status = 'Activated';

        Test.startTest();
        try {
            update ord;
            System.assert(false, 'Une exception aurait dû être levée.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('particuliers'), 'Le message doit concerner les particuliers.');
        }
        Test.stopTest();
    }
}
