import { LightningElement, api } from 'lwc';

export default class ResourceTypePicklist extends LightningElement {
    @api value; // Current value of the picklist
    @api fieldName; // API name of the field being edited
    @api recordId; // Record ID for which the picklist is rendered
    @api options; // List of picklist options

    handleChange(event) {
        // Dispatch event to notify the parent component about the updated value
        const selectedEvent = new CustomEvent('picklistchange', {
            detail: {
                value: event.target.value,
                recordId: this.recordId,
                fieldName: this.fieldName
            }
        });
        this.dispatchEvent(selectedEvent);
    }
}
