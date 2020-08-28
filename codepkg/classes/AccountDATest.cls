@isTest
public with sharing class AccountDATest {
    public static AccountDAI accountDA = new AccountDA();
    
    @TestSetup
    static void setup(){
        
    }

    @isTest
    public static void insertAccounts_givenAccountList_insertsAccounts() {
        Account newAccount = new Account();
        newAccount.Name = '123 Cleveland Street';
        List<Account> accountsToInsert = new List<Account>{newAccount};

        Test.startTest();
            accountDA.insertAccounts(accountsToInsert);
        Test.stopTest();

        List<Account> insertedAccounts = [SELECT Id, Name FROM Account];
        System.assertEquals(1, insertedAccounts.size());
        System.assertEquals('123 Cleveland Street', insertedAccounts[0].Name);
    }

    @isTest
    public static void getAccountsByNames_givenNames_ReturnsAccounts() {
        Account newAccount = new Account();
        newAccount.Name = '123 Cleveland Street';
        insert newAccount;

        List<String> accountNames = new List<String>{'123 Cleveland Street'};

        Test.startTest();
            Account returnedAccount = accountDA.getAccountsByNames(accountNames)[0];
        Test.stopTest();

        System.assertEquals(returnedAccount, newAccount);
    }
}