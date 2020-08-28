public with sharing class AccountDA implements AccountDAI {
    public List<Account> getAccountsByNames(List<String> accountNames) {
        List<Account> accounts = [SELECT id, 
                                    Name 
                                FROM Account 
                                WHERE Name IN :accountNames
        ]; 
        return accounts;
    }

    public void insertAccounts(List<Account> accountsToInsert) {
        insert accountsToInsert;
    }
}