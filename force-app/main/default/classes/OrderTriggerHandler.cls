public with sharing class OrderTriggerHandler {
    public static void handleAfterUpdate(Map<Id, Order> oldMap, List<Order> newList) {
        List<Livraison__c> livraisons = new List<Livraison__c>();
        Set<Id> orderIds = new Set<Id>();

        // Collecter les commandes dont le statut passe à "Activated"
        for (Order ord : newList) {
            Order old = oldMap.get(ord.Id);
            if (ord.Status == 'Activated' && old.Status != ord.Status) {
                orderIds.add(ord.Id);
            }
        }

        if (orderIds.isEmpty()) return;

        // Récupérer les Orders avec leurs OrderItems et leur Account
        List<Order> ordersToCheck = [
            SELECT Id, AccountId, Transporter_Choice__c,
                   (SELECT Id FROM OrderItems),
                   Account.Type_de_Compte__c,
                   Account.BillingCountry
            FROM Order
            WHERE Id IN :orderIds
        ];

        for (Order ord : ordersToCheck) {
            Account acc = ord.Account;
            Integer nbProduits = ord.OrderItems.size();

            if (acc != null && String.isNotBlank(acc.Type_de_Compte__c)) {
                if (acc.Type_de_Compte__c == 'Professionnel' && nbProduits < 5) {
                    throw new AuraHandledException('Commande invalide : les clients professionnels doivent commander au moins 5 produits différents.');
                } else if (acc.Type_de_Compte__c == 'Particulier' && nbProduits < 3) {
                    throw new AuraHandledException('Commande invalide : les clients particuliers doivent commander au moins 3 produits différents.');
                }

                // Création de la livraison si la commande est valide
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
