@isTest
private class OrderServiceTest {

    @isTest
    static void testValidateOrders() {
        // Créer un compte particulier
        Account accParticulier = new Account(Name = 'Client Particulier', Type_de_Compte__c = 'Particulier');
        insert accParticulier;

        // Créer une commande avec ce compte
        Order ord = new Order(Name = 'Commande Test', Status = 'Draft', EffectiveDate = Date.today(), AccountId = accParticulier.Id);
        insert ord;

        // Créer un OrderItem avec moins de 3 produits
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pb.Id, UnitPrice = 10, IsActive = true);
        insert pbe;

        OrderItem item = new OrderItem(OrderId = ord.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 10);
        insert item;

        Test.startTest();
        try {
            OrderService.validateOrders(new List<Order>{ord});
            System.assert(false, 'Une exception aurait dû être levée pour un client particulier avec moins de 3 produits.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('particulier'));
        }
        Test.stopTest();
    }
}
