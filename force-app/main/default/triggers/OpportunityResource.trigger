trigger OpportunityResource on Opportunity_Resource__c (after insert, after update) {
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ){
        OpportunityResourceTriggerHandler.handleOpportunityResource(Trigger.new);
    }
}