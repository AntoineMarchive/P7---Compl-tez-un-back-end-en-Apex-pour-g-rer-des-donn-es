// Permet de trouver le meilleur trassporteur pour une zone donnée
public with sharing class TransporterSelector {


    @AuraEnabled(cacheable=true)
public static List<Prix_Transporteur__c> getFilteredTransporters(Id orderId, String filterType) {
    if (orderId == null || String.isBlank(filterType)) {
        throw new TransporterSelectorException('Paramètres manquants.');
    }

    Order ord = [SELECT Id, AccountId FROM Order WHERE Id = :orderId LIMIT 1];
    Account acc = [SELECT BillingCountry, Type_de_Compte__c FROM Account WHERE Id = :ord.AccountId LIMIT 1];
    String zone = acc.BillingCountry;
    String typeCompte = acc.Type_de_Compte__c;

    if (filterType == 'fastest') {
        return [
            SELECT Id, Tarif__c, Delai_jours__c, Zone__c, Transporteur__r.Name
            FROM Prix_Transporteur__c
            WHERE Zone__c = :zone
            AND Transporteur__r.Type_de_Compte__c = :typeCompte
            ORDER BY Delai_jours__c ASC
            LIMIT 1
        ];
    } else if (filterType == 'cheapest') {
        return [
            SELECT Id, Tarif__c, Delai_jours__c, Zone__c, Transporteur__r.Name
            FROM Prix_Transporteur__c
            WHERE Zone__c = :zone
            AND Transporteur__r.Type_de_Compte__c = :typeCompte
            ORDER BY Tarif__c ASC
            LIMIT 1
        ];
    } else {
        return new List<Prix_Transporteur__c>();
    }
}


    public static Id getBestPrixTransporteurIdForZone(String zone) {
        // Vérification de la validité de l'entrée
        if (String.isBlank(zone)) {
            return null;
        }

        // Requête pour trouver les Prix Transporteurs associés à la zone, triés par tarif croissant
        List<Prix_Transporteur__c> candidats = [
            SELECT Id, Tarif__c
            FROM Prix_Transporteur__c
            WHERE Zone__c = :zone
            ORDER BY Tarif__c ASC
            LIMIT 1
        ];

        // Retourne l'Id du meilleur prix transporteur s'il existe
        if (!candidats.isEmpty()) {
            return candidats[0].Id;
        }

        // Aucun transporteur trouvé pour cette zone
        return null;
    }

    // Retourne tous les transporteurs
    @AuraEnabled(cacheable=true)
    public static List<Prix_Transporteur__c> getAllTransporters() {
        return [
            SELECT Id, Name, Tarif__c, Zone__c, Transporteur__r.Name 
            FROM Prix_Transporteur__c
            ORDER BY Name
        ];
    }

public class TransporterSelectorException extends Exception {}

}
