public with sharing class UserLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> searchUsers(String searchTerm) {
        // Search for active users matching the search term (on name)
        String searchQuery = '%' + searchTerm + '%';

        return [
            SELECT Id, Name 
            FROM User 
            WHERE IsActive = true AND (Name LIKE :searchQuery)
            LIMIT 10
        ];
    }
}
