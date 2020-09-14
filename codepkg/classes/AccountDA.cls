public with sharing class AccountDA implements AccountDAI {
    public List<Account> getAccountsByNames(List<String> accountNames) {
        List<Account> accounts = [SELECT Id, Name, Property_Owner_2__c, City_2__c FROM Account WHERE Name IN :accountNames]; 
        return accounts;
    }

    public List<Account> getAccountsByIds(Set<Id> accountIds) {
        return [SELECT Id, Name, Property_Owner_2__c, City_2__c FROM Account WHERE Id IN :accountIds];
    }

    public void insertAccounts(List<Account> accountsToInsert) {
        insert accountsToInsert;
    }
}