public with sharing class OrderService {

    // Méthode appelée depuis le composant LWC pour sauvegarder le choix du transporteur
    @AuraEnabled
public static void saveTransporterChoice(Id orderId, Id prixTransporteurId) {
    if (orderId == null || prixTransporteurId == null) {
        throw new OrderServiceException('Paramètres invalides.');
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
public class OrderServiceException extends Exception {}
}

