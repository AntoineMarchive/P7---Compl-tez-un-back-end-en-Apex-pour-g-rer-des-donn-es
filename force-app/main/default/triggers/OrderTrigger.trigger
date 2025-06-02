trigger OrderTrigger on Order (after update) {
    List<Livraison__c> livraisons = new List<Livraison__c>();

    for (Order ord : Trigger.new) {
        Order old = Trigger.oldMap.get(ord.Id);
        if (ord.Transporter_Choice__c != old.Transporter_Choice__c) {
            livraisons.add(new Livraison__c(
                Order__c = ord.Id,
                Mode_de_Livraison__c = ord.Transporter_Choice__c
            ));
        }
    }

    if (!livraisons.isEmpty()) {
        insert livraisons;
    }
}

// ce trigger génère automatiquement une livraison après le choix du transporteur.