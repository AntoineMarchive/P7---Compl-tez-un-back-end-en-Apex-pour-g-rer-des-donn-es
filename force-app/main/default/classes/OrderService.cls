public with sharing class OrderService {

    // Méthode pour valider une livraison
    public static void validateLivraison(Livraison__c livraison) {
        if (String.isBlank(livraison.Zone__c)) {
            throw new AuraHandledException('La zone de livraison doit être renseignée.');
        }

        if (livraison.Prix_Transporteur__c == null) {
            throw new AuraHandledException('Un Prix Transporteur doit être sélectionné.');
        }
    }

    // Exemple de logique métier réutilisable
    public static Boolean isZoneValide(Livraison__c livraison) {
        List<String> zonesAutorisees = new List<String>{'France', 'Belgique', 'Luxembourg', 'Suisse'};
        return zonesAutorisees.contains(livraison.Zone__c);
    }

    // Validation d’une liste de commandes selon les règles métier
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

        // Récupère les types de compte
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Type_de_Compte__c FROM Account WHERE Id IN :accountIds]
        );

        // Récupère les quantités de lignes de commande
        Map<Id, Decimal> orderQuantities = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT OrderId, SUM(Quantity) total
            FROM OrderItem
            WHERE OrderId IN :orderIds
            GROUP BY OrderId
        ]) {
            orderQuantities.put((Id)ar.get('OrderId'), (Decimal)ar.get('total'));
        }

        // Applique les règles selon le type de compte
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

    // Méthode appelée depuis le composant LWC pour sauvegarder le choix du transporteur
    @AuraEnabled
public static void saveTransporterChoice(Id orderId, Id prixTransporteurId) {
    if (orderId == null || prixTransporteurId == null) {
        throw new AuraHandledException('Paramètres invalides.');
    }

    Order ord = [SELECT Id, AccountId FROM Order WHERE Id = :orderId LIMIT 1];
    Account acc = [SELECT BillingCountry FROM Account WHERE Id = :ord.AccountId LIMIT 1];

    Livraison__c livraison = new Livraison__c(
        Order__c = orderId,
        Prix_Transporteur__c = prixTransporteurId,
        Zone__c = acc.BillingCountry,
        Mode_de_Livraison__c = 'Choisi manuellement'
    );

    insert livraison;
}

}
