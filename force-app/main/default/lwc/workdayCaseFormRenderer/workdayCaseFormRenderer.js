import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api } from 'lwc';

export default class WorkdayCaseFormRenderer extends NavigationMixin(LightningElement) {
    @api case_number = '';
    @api case_id = '';
    @api predicted_priority = '';
    @api predicted_product_area = '';

    get priorityBadgeClass() {
        // Dynamic variant based on priority
        if (this.predicted_priority === 'Critical') {
            return 'slds-badge_error';
        } else if (this.predicted_priority === 'High') {
            return 'slds-badge_warning';
        }
        return 'slds-badge_success';
    }

    handleViewCase() {
        if (!this.case_id) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.case_id,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }
}