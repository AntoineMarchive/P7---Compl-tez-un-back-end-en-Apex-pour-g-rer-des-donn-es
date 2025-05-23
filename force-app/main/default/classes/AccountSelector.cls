// Déclaration d’une classe Apex nommée AccountSelector
// Le mot-clé `with sharing` garantit que les règles de partage Salesforce sont respectées
public with sharing class AccountSelector {

    // Déclaration d’une méthode statique publique qui renvoie un enregistrement de type Account
    // Elle prend en paramètre un Id appelé accountId
    public static Account getAccountById(Id accountId) {

        // Requête SOQL qui sélectionne certaines colonnes de l’objet standard Account
        // Elle filtre sur l’Id reçu en paramètre
        return [
            SELECT Id, Name, Type, Industry, BillingCity, BillingCountry, Phone, Website
            FROM Account
            WHERE Id = :accountId
        ];
    }
}
