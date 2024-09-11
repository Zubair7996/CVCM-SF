import { LightningElement, api, wire } from 'lwc';
import getOpportunityResources from '@salesforce/apex/OpportunityResourceController.getOpportunityResources';

export default class OpportunityResourceTable extends LightningElement {
    @api recordId; // Opportunity Id

    opportunityResources = [];
    error;

    // Fetch data from Apex using wire service
    @wire(getOpportunityResources, { opportunityId: '$recordId' })
    wiredResources({ data, error }) {
        if (data) {
            // Map through data and extract Consultant Name safely
            this.opportunityResources = data.map(resource => ({
                ...resource,
                consultantName: resource.Consultant__r ? resource.Consultant__r.Name : 'No Consultant'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.opportunityResources = [];
        }
    }
    get hasResources() {
        return this.opportunityResources.length > 0;
    }

    // Define table columns, including consultantName field
    get columns() {
        return [
            { label: 'Resource Type', fieldName: 'Resource_Type__c' },
            { label: 'Charge Out Day Rate', fieldName: 'Charge_Out_Day_Rate__c', type: 'currency' },
            { label: 'Cost Per Day', fieldName: 'Cost_Per_Day__c', type: 'currency' },
            { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
            { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
            { label: 'Consultant', fieldName: 'consultantName' } // Use derived field for Consultant Name
        ];
    }
}
