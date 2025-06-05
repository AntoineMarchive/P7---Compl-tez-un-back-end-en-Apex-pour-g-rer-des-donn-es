import { LightningElement, api } from 'lwc';
import hasPermission from '@salesforce/customPermission/Can_Send_Order';
import saveTransporterChoice from '@salesforce/apex/OrderService.saveTransporterChoice';
import getFilteredTransporters from '@salesforce/apex/TransporterSelector.getFilteredTransporters';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChooseTransporter extends LightningElement {
    @api recordId;

    selectedOption = null; // 'fastest' ou 'cheapest'
    manualTransporterId = null;
    transporterList = [];
    hasPermission = hasPermission;

    options = [
        { label: 'Option la plus rapide', value: 'fastest' },
        { label: 'Option la moins chère', value: 'cheapest' }
    ];

    // Getter pour afficher un message si aucun transporteur n’est dispo
    get isTransporterListEmpty() {
        return this.transporterList.length === 0;
    }

    handleChange(event) {
        this.selectedOption = event.target.value;
        this.manualTransporterId = null;

        getFilteredTransporters({ orderId: this.recordId, filterType: this.selectedOption })
            .then(data => {
                this.transporterList = data.map(item => ({
                    label: `${item.Transporteur__r.Name} (${item.Tarif__c} € / ${item.Delai_jours__c} j)`,
                    value: item.Id
                }));
            })
            .catch(error => {
                console.error('Erreur récupération transporteurs :', error);
                this.transporterList = [];
                this.showToast('Erreur', "Impossible de charger les transporteurs.", 'error');
            });
    }

    handleTransporterSelect(event) {
        this.manualTransporterId = event.detail.value;
    }

    handleSubmit() {
        if (!this.hasPermission) {
            this.showToast('Permission refusée', "Vous n'avez pas la permission d'envoyer une commande.", 'error');
            return;
        }

        const transporterId = this.manualTransporterId;
        if (!transporterId) {
            this.showToast('Sélection manquante', 'Veuillez sélectionner un transporteur.', 'warning');
            return;
        }

        saveTransporterChoice({ orderId: this.recordId, prixTransporteurId: this.manualTransporterId })

            .then(() => {
                this.showToast('Succès', 'Commande envoyée avec succès !', 'success');
            })
            .catch(error => {
                console.error(error);
                this.showToast('Erreur', error?.body?.message || 'Erreur lors de l’envoi de la commande.', 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}
