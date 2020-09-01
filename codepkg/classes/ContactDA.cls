public with sharing class ContactDA implements ContactDAI {
    public List<Contact> getContactsByEmail(List<String> emails) {
        return [SELECT Id, 
                    AccountId,
                    AltName__c,
                    Email, 
                    FirstName, 
                    LastName, 
                    Name, 
                    OtherPhone,
                    Phone
                FROM Contact 
                WHERE Email IN :emails
        ];
    }
}