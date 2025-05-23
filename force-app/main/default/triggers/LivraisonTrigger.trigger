trigger LivraisonTrigger on Livraison__c (before insert, before update) {
    for (Livraison__c liv : Trigger.new) {
        if (liv.Zone__c != null && liv.Prix_Transporteur__c == null) {
            liv.Prix_Transporteur__c = TransporterSelector.getBestPrixTransporteurIdForZone(liv.Zone__c);
        }
    }
}
