import { LightningElement, api, wire } from 'lwc';
// importattion d'une variable booléen liée à la Custom Permission SF ==> Can_Send_Order
import hasPermission from '@salesforce/customPermission/Can_Send_Order';
import saveTransporterChoice from '@salesforce/apex/OrderService.saveTransporterChoice';
import getAllTransporters from '@salesforce/apex/TransporterSelector.getAllTransporters';



export default class ChooseTransporter extends LightningElement {
    @api recordId; // id de l'Order puisque l'on passe une commande
    selectedOption = null; // Stock l'option radio sélectionnée
    manualTransporterId = null; // Stock l'ID du transporteur manuel saisi
    hasPermission = hasPermission; // Stocke la valeur importée pour simplifier l'accès dans le template

    transporterList = []; // Stocke la liste des transporteurs récupérés depuis l'Apex

    options = [
        { label: 'Option la plus rapide', value: 'fastest' },
        { label: 'Option la moins chère', value: 'cheapest' }
    ]; // Choix à afficher dans le radio group

    @wire(getAllTransporters)
    wiredTransporters({ error, data }) {
        if (data) {
            this.transporterList = data.map(item => ({
                label: item.Transporteur__r.Name + ' (' + item.Tarif__c + ' €)', // a travailler : faire la relation entre prix transporteur(enfant) et account (parent)
                value: item.Id
            }));
        } else if (error) {
            console.error('Erreur récupération transporteurs', error);
        }
    }

    handleChange(event) {
        this.selectedOption = event.target.value;
        this.manualTransporterId = null;
    } // Stocke l'option radio dans selectedOption

    handleTransporterSelect(event) {
        this.manualTransporterId = event.detail.value;
        this.selectedOption = null;
    }

    handleSubmit() {
    if (!this.hasPermission) {
        alert("Vous n'avez pas la permission d'envoyer une commande.");
        return;
    }

    const optionToSend = this.selectedOption || this.manualTransporterId;

        if (!optionToSend) {
            alert("Veuillez choisir une option ou un transporteur.");
            return;
        }

    saveTransporterChoice({ orderId: this.recordId, option: this.selectedOption })
        .then(() => {
            alert('Commande envoyée avec succès !');
        })
        .catch(error => {
            console.error(error);
            alert('Erreur lors de l’envoi de la commande.');
        });
}

}