public with sharing class OrderTriggerHandler {
    public static void handleAfterUpdate(Map<Id, Order> oldMap, List<Order> newList) {
        List<Livraison__c> livraisons = new List<Livraison__c>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        // Collecte des commandes dont le statut est passé à "Activated"
        for (Order ord : newList) {
            Order old = oldMap.get(ord.Id);
            if (ord.Status == 'Activated' && old.Status != ord.Status) {
                orderIds.add(ord.Id);
                if (ord.AccountId != null) {
                    accountIds.add(ord.AccountId);
                }
            }
        }

        if (orderIds.isEmpty()) return;

        // Récupération des comptes clients associés
        Map<Id, Account> accountsMap = new Map<Id, Account>(
            [SELECT Id, Type_de_Compte__c, BillingCountry FROM Account WHERE Id IN :accountIds]
        );

        // Récupération des quantités de produits par commande
        Map<Id, Integer> orderQuantities = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OrderId, SUM(Quantity) qty
            FROM OrderItem
            WHERE OrderId IN :orderIds
            GROUP BY OrderId
        ]) {
            orderQuantities.put((Id)ar.get('OrderId'), ((Decimal)ar.get('qty')).intValue());
        }

        // Vérification stricte des règles métiers
        for (Order ord : newList) {
            if (!orderIds.contains(ord.Id)) continue;

            Account acc = accountsMap.get(ord.AccountId);
            Integer qty = orderQuantities.containsKey(ord.Id) ? orderQuantities.get(ord.Id) : 0;

            if (acc != null && String.isNotBlank(acc.Type_de_Compte__c)) {
                if (acc.Type_de_Compte__c == 'Professionnel' && qty < 5) {
                    throw new AuraHandledException('Commande invalide : les clients professionnels doivent commander au moins 5 produits.');
                } else if (acc.Type_de_Compte__c == 'Particulier' && qty < 3) {
                    throw new AuraHandledException('Commande invalide : les clients particuliers doivent commander au moins 3 produits.');
                }

                // Si la commande est valide, on prépare la livraison
                Id prixTransporteurId = TransporterSelector.getBestPrixTransporteurIdForZone(acc.BillingCountry);
                livraisons.add(new Livraison__c(
                    Order__c = ord.Id,
                    Mode_de_Livraison__c = ord.Transporter_Choice__c,
                    Zone__c = acc.BillingCountry,
                    Prix_Transporteur__c = prixTransporteurId
                ));
            }
        }

        if (!livraisons.isEmpty()) {
            insert livraisons;
        }
    }
}
