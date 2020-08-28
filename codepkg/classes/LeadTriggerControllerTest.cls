@isTest
public with sharing class LeadTriggerControllerTest {
    public static LeadTriggerController ltc = new LeadTriggerController();

    @TestSetup
    static void setup(){
        City__c clevelandCity = new City__c();
        clevelandCity.Name = 'Cleveland';
        insert clevelandCity;

        City__c parmaCity = new City__C();
        parmaCity.Name = 'Parma';
        insert parmaCity;
    }

    @isTest
    public static void beforeInsert_givenListOfLeads_insertsNewAccounts() {
        List<Lead> leadList = new List<Lead>();
        Lead cleLead = new Lead();
        cleLead.Property_city__c = 'Cleveland';
        cleLead.Property_Address__c = '123 Cleveland Street';
        cleLead.Property_State__c = 'Ohio';
        cleLead.PostalCode = '12345';
        cleLead.Phone = '1234567890';
        cleLead.Year_Built__c = '1990';
        leadList.add(cleLead);

        Lead parmaLead = new Lead();
        parmaLead.Property_city__c = 'Parma';
        parmaLead.Property_Address__c = '123 Parma Street';
        parmaLead.Property_State__c = 'Ohio';
        parmaLead.PostalCode = '12345';
        parmaLead.Phone = '1234567891';
        parmaLead.Year_Built__c = '1991';
        leadList.add(cleLead);

        Test.startTest();
            ltc.beforeInsert(leadList);
            List<Account> newAccounts = [SELECT Id, Name FROM Account];
        Test.stopTest();
        System.assertEquals(2, newAccounts.size(), 'Incorrect number of Accounts created , expected 2, got ' + newAccounts.size());
        System.assertEquals('123 Cleveland Street', newAccounts[0].Name, 'Wrong Addresses');
    }

    public static void beforeUpdate_givenLeadsWithMatchingAdresses_doesNotInsertNewAccounts() {
        List<Lead> oldLeadList = new List<Lead>();
        Lead cleLead = new Lead();
        cleLead.Property_city__c = 'Cleveland';
        cleLead.Property_Address__c = '123 Cleveland Street';
        cleLead.Property_State__c = 'Ohio';
        cleLead.PostalCode = '12345';
        cleLead.Phone = '1234567890';
        cleLead.Year_Built__c = '1990';
        oldLeadList.add(cleLead);

        Lead parmaLead = new Lead();
        parmaLead.Property_city__c = 'Parma';
        parmaLead.Property_Address__c = '123 Parma Street';
        parmaLead.Property_State__c = 'Ohio';
        parmaLead.PostalCode = '12345';
        parmaLead.Phone = '1234567891';
        parmaLead.Year_Built__c = '1991';
        oldLeadList.add(cleLead);
        insert oldLeadList;

        List<Lead> newLeadList = [SELECT Id, Property_Address__c,Year_Built__c FROM Lead];
        for(Lead ld : newLeadList){
            ld.Year_Built__c = '1999';
        }
        List<Account> accounts = [SELECT Id, Name FROM Account];
        Integer numberOfAccountsBeforeUpdate = accounts.size();

        Test.startTest();
            ltc.beforeUpdate(newLeadList, oldLeadList);
        Test.stopTest();

        Integer numberOfAccountsAfterUpdate = [SELECT Id, Name FROM Account].size();
        System.assertEquals(numberOfAccountsBeforeUpdate, numberOfAccountsAfterUpdate, 'Test failed, Accounts added or removed');
    }

    public static void beforeUpdate_givenLeadsWithNewAdresses_insertsNewAccounts() {
        List<Lead> oldLeadList = new List<Lead>();
        Lead cleLead = new Lead();
        cleLead.Property_city__c = 'Cleveland';
        cleLead.Property_Address__c = '123 Cleveland Street';
        cleLead.Property_State__c = 'Ohio';
        cleLead.PostalCode = '12345';
        cleLead.Phone = '1234567890';
        cleLead.Year_Built__c = '1990';
        oldLeadList.add(cleLead);

        Lead parmaLead = new Lead();
        parmaLead.Property_city__c = 'Parma';
        parmaLead.Property_Address__c = '123 Parma Street';
        parmaLead.Property_State__c = 'Ohio';
        parmaLead.PostalCode = '12345';
        parmaLead.Phone = '1234567891';
        parmaLead.Year_Built__c = '1991';
        oldLeadList.add(cleLead);
        insert oldLeadList;

        List<Lead> newLeadList = [SELECT Id, Property_Address__c,Year_Built__c FROM Lead];
        for(Lead ld : newLeadList){
            ld.Property_Address__c = ld.Property_Address__c + ' new';
        }

        List<Account> accounts = [SELECT Id, Name FROM Account];
        Integer numberOfAccountsBeforeUpdate = accounts.size();
        
        Test.startTest();
            ltc.beforeUpdate(newLeadList, oldLeadList);
        Test.stopTest();

        Integer numberOfAccountsAfterUpdate = [SELECT Id, Name FROM Account].size();
        System.assertEquals(numberOfAccountsBeforeUpdate*2, numberOfAccountsAfterUpdate, 'Test failed, Accounts added or removed');
    }
}