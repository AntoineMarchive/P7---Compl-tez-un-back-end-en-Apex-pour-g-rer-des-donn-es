import { LightningElement, api, wire } from 'lwc';
// importattion d'une variable booléen liée à la Custom Permission SF ==> Can_Send_Order
import hasPermission from '@salesforce/customPermission/Can_Send_Order';
import saveTransporterChoice from '@salesforce/apex/OrderService.saveTransporterChoice';
import getAllTransporters from '@salesforce/apex/TransporterSelector.getAllTransporters';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';




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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant, // 'success' | 'error' | 'warning' | 'info'
            mode: 'dismissable'
     });
        this.dispatchEvent(event);
    }


    handleSubmit() {
    if (!this.hasPermission) {
        this.showToast('Permission refusée', "Vous n'avez pas la permission d'envoyer une commande.", 'error');
        return;
    }

    const optionToSend = this.selectedOption || this.manualTransporterId;

    if (!optionToSend) {
        this.showToast('Sélection manquante', 'Veuillez choisir une option ou un transporteur.', 'warning');
        return;
    }

    saveTransporterChoice({ orderId: this.recordId, option: optionToSend })
        .then(() => {
            this.showToast('Succès', 'Commande envoyée avec succès !', 'success');
        })
        .catch(error => {
            console.error(error);
            this.showToast('Erreur', error?.body?.message || "Erreur lors de l’envoi de la commande.", 'error');

        });
    }

}