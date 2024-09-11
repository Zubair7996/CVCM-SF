import { LightningElement, api, wire, track } from 'lwc';
import searchUsers from '@salesforce/apex/UserLookupController.searchUsers';

export default class ConsultantLookup extends LightningElement {
    @api value; // Current consultant Id (if available)
    @api recordId; // Record ID for which the lookup is rendered
    @api fieldName; // Field name being edited
    
    @track searchTerm = '';
    @track users = [];
    @track isLoading = false;

    @wire(searchUsers, { searchTerm: '$searchTerm' })
    wiredUsers({ error, data }) {
        if (data) {
            this.users = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            this.users = [];
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleSelect(event) {
        const selectedEvent = new CustomEvent('lookupchange', {
            detail: {
                value: event.target.value,
                recordId: this.recordId,
                fieldName: this.fieldName
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    get hasResults() {
        return this.users.length > 0;
    }
}
