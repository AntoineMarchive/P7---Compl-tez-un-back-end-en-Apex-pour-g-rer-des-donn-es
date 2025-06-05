@isTest
private class TransporterSelectorTest {

    @isTest
    static void testGetBestPrixTransporteurIdForZone_OK() {
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

        System.assertEquals(p2.Id, result);
    }

    @isTest
    static void testGetBestPrixTransporteurIdForZone_NoMatch() {
        insert new Prix_Transporteur__c(Zone__c = 'France', Tarif__c = 15.0);

        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('Suisse');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testGetBestPrixTransporteurIdForZone_BlankInput() {
        Test.startTest();
        Id result = TransporterSelector.getBestPrixTransporteurIdForZone('');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testGetAllTransporters_OK() {
        insert new Prix_Transporteur__c(
            Zone__c = 'France',
            Tarif__c = 15.0
        );

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getAllTransporters();
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetFilteredTransporters_OK_fastest() {
        Account acc = new Account(Name='Client', BillingCountry='France');
        insert acc;

        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id
        );
        insert ord;

        Prix_Transporteur__c p1 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=20, Delai_jours__c=3);
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=30, Delai_jours__c=1);
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getFilteredTransporters(ord.Id, 'fastest');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(p2.Id, result[0].Id);
    }

    @isTest
    static void testGetFilteredTransporters_OK_cheapest() {
        Account acc = new Account(Name='Client', BillingCountry='France');
        insert acc;

        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id
        );
        insert ord;

        Prix_Transporteur__c p1 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=20, Delai_jours__c=2);
        Prix_Transporteur__c p2 = new Prix_Transporteur__c(Zone__c='France', Tarif__c=10, Delai_jours__c=3);
        insert new List<Prix_Transporteur__c>{ p1, p2 };

        Test.startTest();
        List<Prix_Transporteur__c> result = TransporterSelector.getFilteredTransporters(ord.Id, 'cheapest');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(p2.Id, result[0].Id);
    }

    @isTest
    static void testGetFilteredTransporters_InvalidParams() {
        Test.startTest();
        try {
            TransporterSelector.getFilteredTransporters(null, '');
            System.assert(false, 'Exception attendue');
        } catch (AuraHandledException e) {
            System.assertEquals('Paramètres manquants.', e.getMessage());
        }
        Test.stopTest();
    }
}
