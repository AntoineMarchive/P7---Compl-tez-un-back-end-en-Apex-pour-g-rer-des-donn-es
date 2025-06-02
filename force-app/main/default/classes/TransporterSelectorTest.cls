@isTest
private class TransporterSelectorTest {

    @isTest
    static void testGetBestPrixTransporteurIdForZone_OK() {
        // Cas : deux transporteurs pour la même zone, on attend le moins cher
        Prix_Transporteur__c p1 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 20.0
        );
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 10.0
        );
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('France');
        Test.stopTest();

        System.assertEquals(p2.Id, result, 'Le transporteur le moins cher doit être retourné');
    }

    @isTest
    static void testGetBestPrixTransporteurIdForZone_NoMatch() {
        // Cas : aucun transporteur pour la zone "Suisse"
        insert new Prix_Transporteur__c(Zone__c = 'France', Tarif__c = 15.0);

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('Suisse');
        Test.stopTest();

        System.assertEquals(null, result, 'Aucun transporteur ne doit être retourné');
    }

    @isTest
    static void testGetBestPrixTransporteurIdForZone_BlankInput() {
        // Cas : zone vide
        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('');
        Test.stopTest();

        System.assertEquals(null, result, 'Zone vide doit retourner null');
    }
}
