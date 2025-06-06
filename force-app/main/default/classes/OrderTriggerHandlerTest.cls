@isTest
public class OrderTriggerHandlerTest {
    
    @isTest
    static void testLivraisonCreee_Professionnel_OK() {
        // Créer un compte professionnel avec le bon champ
        Account acc = new Account(Name = 'Client Pro', Type_de_Compte__c = 'Professionnel', BillingCountry = 'France');
        insert acc;

        // Créer un produit actif
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        // Récupérer l'ID du pricebook standard
        Id standardPB = Test.getStandardPricebookId();

        // Créer une entrée de pricebook active
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPB,
            UnitPrice = 10,
            IsActive = true
        );
        insert pbe;

        // Créer la commande à l’état "Draft"
        Order o = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Name = 'Commande Pro',
            Pricebook2Id = standardPB,
            Transporter_Choice__c = 'standard'
        );
        insert o;

        // Ajouter 5 produits (OK pour professionnel)
        OrderItem item = new OrderItem(
            OrderId = o.Id,
            Quantity = 5,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert item;

        // Activation de la commande pour déclencher le trigger
        o.Status = 'Activated';
        update o;

        // Vérifier qu’une livraison a bien été créée
        List<Livraison__c> livraisons = [SELECT Id FROM Livraison__c WHERE Order__c = :o.Id];
        System.assertEquals(1, livraisons.size(), 'Une livraison aurait dû être créée.');
    }
}
