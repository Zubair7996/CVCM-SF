public class OpportunityResourceTriggerHandler {
    public static void handleOpportunityResource(List<Opportunity_Resource__c> oppResources) {
        if (oppResources == null || oppResources.isEmpty()) {
            System.debug('No Opportunity_Resource__c records found.');
            return;
        }

        // Prepare lists and maps
        List<Schedule__c> schedulesToInsert = new List<Schedule__c>();
        List<Schedule_Item__c> scheduleItemsToInsert = new List<Schedule_Item__c>();
        Map<String, Schedule__c> existingSchedules = new Map<String, Schedule__c>();
        Map<Id, String> opportunityNames = new Map<Id, String>();
        Set<Id> consultantIds = new Set<Id>();
        Id opportunityId = null;

        // Collect Consultant IDs and get the related Opportunity ID
        for (Opportunity_Resource__c oppResource : oppResources) {
            if (oppResource.Start_Date__c != null && oppResource.End_Date__c != null && oppResource.Consultant__c != null) {
                consultantIds.add(oppResource.Consultant__c);
                opportunityId = oppResource.Opportunity__c;
            
            }
        }

        if (opportunityId == null) {
            System.debug('Opportunity ID is null.');
            return;
        }

        // Query the related Opportunity once
        Opportunity relatedOpp = [
            SELECT Name
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        opportunityNames.put(opportunityId, relatedOpp.Name);

        // Define lists to handle schedules and their respective date ranges
        Map<Date, Set<Id>> dateRanges = new Map<Date, Set<Id>>();

        // Collect all date ranges for querying schedules
        for (Opportunity_Resource__c oppResource : oppResources) {
            if (oppResource.Start_Date__c != null && oppResource.End_Date__c != null && oppResource.Consultant__c != null) {
                Date startDate = oppResource.Start_Date__c;
                Date endDate = oppResource.End_Date__c;

                for (Date currentDate = startDate; currentDate <= endDate; currentDate = currentDate.addDays(1)) {
                    if (!dateRanges.containsKey(currentDate)) {
                        dateRanges.put(currentDate, new Set<Id>());
                    }
                    dateRanges.get(currentDate).add(oppResource.Consultant__c);
                }
            }
        }

        // Query existing Schedules for the specified Consultants and Date Ranges
        List<Schedule__c> schedules = [
            SELECT Id, Date__c, User__c, Name
            FROM Schedule__c
            WHERE User__c IN :consultantIds
            AND Date__c IN :dateRanges.keySet()
        ];

        for (Schedule__c schedule : schedules) {
            String key = schedule.User__c + '-' + String.valueOf(schedule.Date__c);
            existingSchedules.put(key, schedule);
        }

        // Define the start and end times
        Time startTime = Time.newInstance(9, 0, 0, 0);  // 09:00:00 AM
        Time endTime = Time.newInstance(17, 0, 0, 0);    // 05:00:00 PM

        // Process each Opportunity_Resource record to create Schedules
        for (Opportunity_Resource__c oppResource : oppResources) {
            if (oppResource.Start_Date__c != null && oppResource.End_Date__c != null && oppResource.Consultant__c != null) {
                Date startDate = oppResource.Start_Date__c;
                Date endDate = oppResource.End_Date__c;

                for (Date currentDate = startDate; currentDate <= endDate; currentDate = currentDate.addDays(1)) {

                    // Skip weekends
                    Integer dayOfWeek = calculateDayOfWeek(currentDate);
                    if (dayOfWeek == 6 || dayOfWeek == 7) { // 6 = Saturday, 7 = Sunday
                        continue; // Skip if it's Saturday or Sunday
                    }

                    String scheduleKey = oppResource.Consultant__c + '-' + String.valueOf(currentDate);

                    Schedule__c schedule;
                    if (existingSchedules.containsKey(scheduleKey)) {
                        schedule = existingSchedules.get(scheduleKey);
                    } else {
                        // Create a new Schedule record
                        schedule = new Schedule__c();
                        schedule.Date__c = currentDate;
                        schedule.User__c = oppResource.Consultant__c; // Use Consultant__c for User__c
                        schedule.Name = scheduleKey;  // Set the Schedule Name field to the key
                        schedulesToInsert.add(schedule);
                        existingSchedules.put(scheduleKey, schedule); // Add to map to avoid duplicates
                    }
                }
            }
        }

        // Insert new Schedules
        try {
            if (!schedulesToInsert.isEmpty()) {
                insert schedulesToInsert;
                System.debug('Schedules inserted successfully.');
            }
        } catch (DmlException e) {
            System.debug('Error inserting Schedules: ' + e.getMessage());
        }

        // Create Schedule_Items after schedules are inserted
        for (Opportunity_Resource__c oppResource : oppResources) {
            if (oppResource.Start_Date__c != null && oppResource.End_Date__c != null && oppResource.Consultant__c != null) {
                Date startDate = oppResource.Start_Date__c;
                Date endDate = oppResource.End_Date__c;

                for (Date currentDate = startDate; currentDate <= endDate; currentDate = currentDate.addDays(1)) {

                    // Skip weekends
                    Integer dayOfWeek = calculateDayOfWeek(currentDate);
                    if (dayOfWeek == 6 || dayOfWeek == 7) { // 6 = Saturday, 7 = Sunday
                        continue; // Skip if it's Saturday or Sunday
                    }

                    String scheduleKey = oppResource.Consultant__c + '-' + String.valueOf(currentDate);

                    if (existingSchedules.containsKey(scheduleKey)) {
                        Schedule__c schedule = existingSchedules.get(scheduleKey);

                        // Create a Schedule_Item record
                        Schedule_Item__c scheduleItem = new Schedule_Item__c();
                        scheduleItem.Schedule__c = schedule.Id;
                        scheduleItem.Schedule_Name__c = opportunityNames.get(opportunityId); // Set the name to the Opportunity's name

                        // Set start_time and end_time

                        scheduleItem.Start_Time__c = DateTime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0)); // 09:00 AM
                        scheduleItem.End_Time__c = DateTime.newInstance(currentDate, Time.newInstance(17, 0, 0, 0));   // 05:00 PM
                        scheduleItem.Date__c = currentDate;
                        
                        // Set the Schedule_Item_Type picklist value
                        scheduleItem.Schedule_Item_Type__c = 'Project'; // Set picklist field value

                        scheduleItemsToInsert.add(scheduleItem);
                    }
                }
            }
        }

        // Debug output for validation
        System.debug('Schedule Items to insert: ' + scheduleItemsToInsert);

        // Insert new Schedule Items
        try {
            if (!scheduleItemsToInsert.isEmpty()) {
                insert scheduleItemsToInsert;
                System.debug('Schedule Items inserted successfully.');
            }
        } catch (DmlException e) {
            System.debug('Error inserting Schedule Items: ' + e.getMessage());
        }
    }

    // Method to calculate the day of the week
    public static Integer calculateDayOfWeek(Date datetst) {
        DateTime dt = DateTime.newInstance(datetst, Time.newInstance(0, 0, 0, 0));
        // Use the format method to get the day of the week (1 = Monday, 7 = Sunday)
        String dayString = dt.format('u');
        return Integer.valueOf(dayString);
    }
}
