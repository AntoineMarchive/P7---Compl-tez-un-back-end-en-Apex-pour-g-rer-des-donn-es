// Permet de trouver le meilleur trassporteur pour une zone donnée
public with sharing class TransporterSelector {

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

    @AuraEnabled(cacheable=true)
    public static List<Prix_Transporteur__c> getFilteredTransporters(Id orderId, String filterType) {
        if (orderId == null || String.isBlank(filterType)) {
            throw new AuraHandledException('Paramètres manquants.');
        }

        Order ord = [SELECT Id, AccountId FROM Order WHERE Id = :orderId LIMIT 1];
        Account acc = [SELECT BillingCountry FROM Account WHERE Id = :ord.AccountId LIMIT 1];
        String zone = acc.BillingCountry;

        List<Prix_Transporteur__c> candidats = [
            SELECT Id, Tarif__c, Delai_jours__c, Zone__c, Transporteur__r.Name
            FROM Prix_Transporteur__c
            WHERE Zone__c = :zone
        ];

        if (candidats.isEmpty()) {
            return new List<Prix_Transporteur__c>();
        }

        List<Prix_Transporteur__c> resultat = new List<Prix_Transporteur__c>();

        if (filterType == 'fastest') {
            Decimal minDelai;
            for (Prix_Transporteur__c p : candidats) {
                if (minDelai == null || p.Delai_jours__c < minDelai) {
                    minDelai = p.Delai_jours__c;
                }
            }
            for (Prix_Transporteur__c p : candidats) {
                if (p.Delai_jours__c == minDelai) {
                    resultat.add(p);
                }
            }
        } else if (filterType == 'cheapest') {
            Decimal minTarif;
            for (Prix_Transporteur__c p : candidats) {
                if (minTarif == null || p.Tarif__c < minTarif) {
                    minTarif = p.Tarif__c;
                }
            }
            for (Prix_Transporteur__c p : candidats) {
                if (p.Tarif__c == minTarif) {
                    resultat.add(p);
                }
            }
        }

        return resultat;
    }
}
