@isTest
private class TransporterSelectorTest {

    @isTest
    static void testGetBestPrixTransporteurIdForZone() {
        // Création d’un compte (transporteur)
        Account transporteur = new Account(Name = 'Transporteur Test');
        insert transporteur;

        // Création de plusieurs Prix_Transporteur__c pour une même zone
        Prix_Transporteur__c prix1 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 15,
            Delai_jours__c = 3,
            Transporteur__c = transporteur.Id
        );
        insert prix1;

        Prix_Transporteur__c prix2 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 10,
            Delai_jours__c = 5,
            Transporteur__c = transporteur.Id
        );
        insert prix2;

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('France');
        Test.stopTest();

        System.assertEquals(prix2.Id, result, 'Le transporteur avec le tarif le plus bas doit être sélectionné');
    }
}