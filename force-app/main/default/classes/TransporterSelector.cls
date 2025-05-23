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

        // Retourner l'Id du meilleur prix transporteur s'il existe
        if (!candidats.isEmpty()) {
            return candidats[0].Id;
        }

        // Aucun transporteur trouvé pour cette zone
        return null;
    }
}
