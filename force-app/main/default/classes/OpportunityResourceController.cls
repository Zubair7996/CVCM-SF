public with sharing class OpportunityResourceController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Resource__c> getOpportunityResources(Id opportunityId) {
        return [
            SELECT Id, Resource_Type__c, Charge_Out_Day_Rate__c, Cost_Per_Day__c, Start_Date__c, End_Date__c, Consultant__r.Name
            FROM Opportunity_Resource__c
            WHERE Opportunity__c = :opportunityId
        ];
    }
}
