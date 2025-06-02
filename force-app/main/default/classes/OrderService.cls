public with sharing class OrderService {

    // Méthode pour valider une livraison
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


    // Exemple de logique métier réutilisable
    public static Boolean isZoneValide(Livraison__c livraison) {
        List<String> zonesAutorisees = new List<String>{'France', 'Belgique', 'Luxembourg', 'Suisse'};
        return zonesAutorisees.contains(livraison.Zone__c);
    }

    public static void validateOrders(List<Order> orders) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();

        for (Order ord : orders) {
            if (ord.AccountId == null) {
                ord.addError('Un compte doit être associé à la commande.');
            } else {
                accountIds.add(ord.AccountId);
                orderIds.add(ord.Id);
            }
        }

        // Récupère les types de compte (particulier ou professionnel)
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Type_de_Compte__c FROM Account WHERE Id IN :accountIds]
        );

        // Récupère les quantités de lignes de commande par commande
        Map<Id, Decimal> orderQuantities = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT OrderId, SUM(Quantity) total
            FROM OrderItem
            WHERE OrderId IN :orderIds
            GROUP BY OrderId
        ]) {
            orderQuantities.put((Id)ar.get('OrderId'), (Decimal)ar.get('total'));
        }

        // Applique les regles selon le type de compte
        for (Order ord : orders) {
            Account acc = accountMap.get(ord.AccountId);
            Decimal totalProduits = orderQuantities.containsKey(ord.Id) ? orderQuantities.get(ord.Id) : 0;

            if (acc != null) {
                if (acc.Type_de_Compte__c == 'Particulier' && totalProduits < 3) {
                    ord.addError('Un client particulier doit commander au moins 3 produits.');
                }
                if (acc.Type_de_Compte__c == 'Professionnel' && totalProduits < 5) {
                    ord.addError('Un client professionnel doit commander au moins 5 produits.');
                }
            }
        }
    }
}
