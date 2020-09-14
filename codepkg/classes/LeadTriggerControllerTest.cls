@isTest
public with sharing class LeadTriggerControllerTest {
    public static LeadTriggerController ltc = new LeadTriggerController();
 
    private static void createData(){
        City__c clevelandCity = new City__c();
        clevelandCity.Name = 'Cleveland';
        insert clevelandCity;

        City__c parmaCity = new City__c();
        parmaCity.Name = 'Parma';
        insert parmaCity;
    }

    private static List<Contact> createMatchingOldAndNewContacts(Boolean isMatch){
        Contact newContact = new Contact();
            newContact.FirstName = 'aTest' ;
            newContact.LastName = 'Name';
            newContact.Email = 'testname@email.com';
            newContact.Phone = '1231231234';
        Contact oldContact = new Contact();
            if(isMatch) {
                oldContact.FirstName = 'aTest';
                oldContact.LastName = 'Name';
                oldContact.Email = 'testname@email.com';
                oldContact.Phone = '1231231234';
            }

            else {
                oldContact.FirstName = 'Not';
                oldContact.LastName = 'Matching';
                oldContact.Email = 'notAMatch@email.com';
                oldContact.Phone = '3213213210';
            }

        insert new List<Contact>{newContact, oldContact};

        List<Contact> contacts = [SELECT Id, AltName__c, FirstName, LastName, Name, Email, OtherPhone, Phone FROM Contact ORDER BY Email];
        return contacts;

    }

    @isTest
    public static void  nameAndPhoneMatch_givenNewContactAndOldContactWithMatchingFields_returnsTrue() {
        List<Contact> contactList = createMatchingOldAndNewContacts(true);
        Test.startTest();
            Boolean isMatch  = ltc.nameAndPhoneMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(true, isMatch);
    }

    @isTest
    public static void nameAndPhoneMatch_givenNewContactAndOldContactWithoutMatchingFields_returnsFalse() {
        List<Contact> contactList = createMatchingOldAndNewContacts(false);
        Test.startTest();
            Boolean isMatch  = ltc.nameAndPhoneMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(false, isMatch);
    }

    @isTest
    public static void  phonesMatch_givenNewContactAndOldContactWithMatchingFields_returnsTrue() {
        List<Contact> contactList = createMatchingOldAndNewContacts(true);
        Test.startTest();
            Boolean isMatch  = ltc.phonesMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(true, isMatch);
    }

    @isTest
    public static void phonesMatch_givenNewContactAndOldContactWithoutMatchingFields_returnsFalse() {
        List<Contact> contactList = createMatchingOldAndNewContacts(false);
        Test.startTest();
            Boolean isMatch  = ltc.phonesMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(false, isMatch);
    }

    @isTest
    public static void  namesMatch_givenNewContactAndOldContactWithMatchingFields_returnsTrue() {
        List<Contact> contactList = createMatchingOldAndNewContacts(true);
        Test.startTest();
            Boolean isMatch  = ltc.namesMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(true, isMatch);
    }

    @isTest
    public static void namesMatch_givenNewContactAndOldContactWithoutMatchingFields_returnsFalse() {
        List<Contact> contactList = createMatchingOldAndNewContacts(false);
        Test.startTest();
            Boolean isMatch  = ltc.namesMatch(contactList[0], contactList[1]);
        Test.stopTest();
        System.assertEquals(false, isMatch);
    }

    private static Map<String, City__c> createCities() {
        City__c cleveland = new City__c();
            cleveland.Name = 'Cleveland';
        City__c parma = new City__C();
            parma.Name = 'Parma';
        insert new List<City__c>{cleveland, parma};
        Map<String, City__c> cityMap = new Map<String, City__c>();
        for(City__c city : [SELECT Id, Name FROM City__c]) {
            cityMap.put(city.Name, city);
        }
        return cityMap;
    }

    private static List<Lead> createLeads() {
        Lead lead1 = new Lead();
            lead1.Company = 'NA';
            lead1.Email = 'testname@test.com';
            lead1.FirstName = 'Test';
            lead1.LastName = 'Name';
            lead1.Phone = '1231231234';
            lead1.PostalCode = '12345';
            lead1.Property_Address__c = '123 Cleveland St';
            lead1.Property_City__c = 'Cleveland';
            lead1.Property_State__c = 'Ohio';
            lead1.Year_Built__c = '1990';
        return new List<Lead>{lead1};
    }

    @isTest
    public static void getCityNamesToCity_givenCityStrings_returnsMatchingCities() {
        createCities();
        List<Lead> leads = createLeads();
        List<String> cityNames = new List<String>{'Cleveland', 'Parma'};
        
        Test.startTest();
            Map<String, City__c> cities = ltc.getCityNamesToCity(leads);
        Test.stopTest();

        System.assertEquals(1, cities.size());
        System.assertEquals('Cleveland', cities.get('Cleveland').Name);
    }


    @isTest
    public static void createAccountsFromLeads_givenNewLeads_shouldReturnUninsertedAccounts() {
        List<Lead> leads = createLeads();
        Map<String, City__c> cities = createCities();

        Test.startTest();
           ltc.createAccountsFromLeads(leads, cities);
        Test.stopTest();

        System.assertEquals(1, ltc.accountNameToAccountMap.size(), 'One Account should have been created.');
        System.assertEquals(leads[0].Property_Address__c, ltc.accountNameToAccountMap.values()[0].Name,
            'The created Accounts should have their Name match the Property_Address__c of the corresponding Lead.');
    }

    @isTest
    public static void setPropertyOwnerOnAccounts_givenMapsOfAddressesToAccountsAndContacts_shouldSetPropertyOwnerFieldOnAccountsToMatchingContactId() {
        Lead testLead = createLeads()[0];
        String address = testLead.Property_Address__c;
        ltc.accountNameToAccountMap = createAddressMap(testLead);
        Contact testContact = createMatchingOldAndNewContacts(false)[0];
        Map<String, Contact> emailToContact = new Map<String, Contact>();
        emailToContact.put(testContact.Email, testContact);
        Map<String, String> addressToContactEmail = new Map<String, String>();
        addressToContactEmail.put(address, testContact.Email);

        Test.startTest();
            ltc.setPropertyOwnerOnAccounts(emailToContact, addressToContactEmail);
        Test.stopTest();

        System.assertNotEquals(null, ltc.accountNameToAccountMap.get(address).Property_Owner_2__c, 'The Property Owner lookup field should be set for the accounts in the map.');
    }


    @isTest
    public static void insertUniqueAccounts_givenAccounts_shouldInsertsUniqueAccounts() {
        Lead testLead = createLeads()[0];
        ltc.accountNameToAccountMap = createAddressMap(testLead, false);

        Test.startTest();
            ltc.insertUniqueAccounts();
        Test.stopTest();

        List<Account> insertedAccounts = [SELECT Id, Name FROM Account];
        System.assert(insertedAccounts.size() > 0, 'Accounts should have been inserted.');
        System.assertNotEquals(null, ltc.accountNameToAccountMap.values()[0].Id, 'The returned Accounts should have an Id if they were successfully inserted.');
    }

    private static Map<String, Account> createAddressMap(Lead ld) {
        return createAddressMap(ld, true);
    }

    private static Map<String, Account> createAddressMap(Lead ld, Boolean insertAccount) {
        Account acc = new Account();
        acc.City_2__c = createCities().get(ld.Property_City__c).Id;
        acc.Phone = ld.Phone;
        acc.State_2__c = ld.Property_State__c;
        acc.Year_Built_2__c = ld.Year_Built__c;
        acc.Zip_2__c = ld.PostalCode;
        acc.Name = ld.Property_Address__c;
        if (insertAccount) {
            insert acc;
        }

        Map<String, Account> accountMap = new Map<String, Account>();
        accountMap.put(ld.Property_Address__c, acc);
        return accountMap;
    }

    @isTest
    public static void beforeInsert_givenLeadWithNewEmailandNewAddress_createsNewContactAndAccount() {
        Lead ld = new Lead(
            Email = 'testname@test.com',
            FirstName = 'Test',
            LastName = 'Name',
            Phone = '1231231234',
            PostalCode = '12345',
            Property_Address__c = '123 Cleveland St',
            Property_City__c = 'Cleveland',
            Property_State__c = 'Ohio',
            Year_Built__c = '1990'
        );

        Test.startTest();
            ltc.beforeInsert(new List<Lead>{ld});
        Test.stopTest();

        List<Contact> newContacts = [SELECT Id, Email FROM Contact];
        System.assertEquals(1, newContacts.size());
        System.assertEquals(ld.Email, newContacts[0].Email);
        
        List<Account> newAccounts = [SELECT Id, Name FROM Account];
        System.assertEquals(1, newContacts.size());
        System.assertEquals(ld.Property_Address__c, newAccounts[0].Name);

        List<AccountContactRelation> newACRs = [SELECT Id, ContactId, AccountId FROM AccountContactRelation];
        System.assertEquals(1, newACRs.size());
        System.assertEquals(newContacts[0].Id, newACRs[0].ContactId);
        System.assertEquals(newAccounts[0].Id, newACRs[0].AccountId);
    }

    @isTest
    public static void beforeInsert_givenLeadWithNewEmailandOldAddress_createsNewContactAndRelatesToOldAddress() {
        City__c clevelandCity = new City__c();
            clevelandCity.Name = 'Cleveland';
        insert clevelandCity;

        Account acc = new Account(
            City_2__c = clevelandCity.Id,
            Phone = '1231231234',
            State_2__c = 'Ohio',
            Year_Built_2__c = '1990',
            Zip_2__c = '12345',
            Name = '123 Cleveland St'
        );
        insert acc;
        
        Lead ld = new Lead(
            Email = 'testname@test.com',
            FirstName = 'Test',
            LastName = 'Name',
            Phone = '1231231234',
            PostalCode = '12345',
            Property_Address__c = '123 Cleveland St',
            Property_City__c = 'Cleveland',
            Property_State__c = 'Ohio',
            Year_Built__c = '1990'
        );

        Test.startTest();
            ltc.beforeInsert(new List<Lead>{ld});
        Test.stopTest();

        List<Contact> newContacts = [SELECT Id, Email FROM Contact];
        System.assertEquals(1, newContacts.size());
        System.assertEquals(ld.Email, newContacts[0].Email);
        
        List<Account> newAccounts = [SELECT Id, Name FROM Account];
        System.assertEquals(1, newContacts.size());
        System.assertEquals(ld.Property_Address__c, newAccounts[0].Name);

        List<AccountContactRelation> newACRs = [SELECT Id, ContactId, AccountId FROM AccountContactRelation];
        System.assertEquals(1, newACRs.size());
        System.assertEquals(newContacts[0].Id, newACRs[0].ContactId);
        System.assertEquals(newAccounts[0].Id, newACRs[0].AccountId);
    }

    @isTest
    public static void beforeInsert_givenLeadWithOldEmailandNewAddress_createsNewAccountAndRelatesToOldContact() {
        City__c clevelandCity = new City__c();
            clevelandCity.Name = 'Cleveland';
        insert clevelandCity;
        
        Account acc = new Account(
            City_2__c = clevelandCity.Id,
            Phone = '1231231234',
            State_2__c = 'Ohio',
            Year_Built_2__c = '1990',
            Zip_2__c = '12345',
            Name = '123 Cleveland St'
        );
        insert acc;

        Contact cont = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            Email = 'testname@test.com',
            Phone = '2345678901',
            AccountId = acc.Id
        );
        
        Lead ld = new Lead(
            Email = 'testname@test.com',
            FirstName = 'Test',
            LastName = 'Name',
            Phone = '1231231234',
            PostalCode = '12345',
            Property_Address__c = '123 New St',
            Property_City__c = 'Cleveland',
            Property_State__c = 'Ohio',
            Year_Built__c = '1990'
        );

        Test.startTest();
            ltc.beforeInsert(new List<Lead>{ld});
        Test.stopTest();

        List<Contact> newContacts = [SELECT Id, Email FROM Contact];
        System.assertEquals(1, newContacts.size());
        System.assertEquals(ld.Email, newContacts[0].Email);
        
        List<Account> newAccounts = [SELECT Id, Name FROM Account];
        System.assertEquals(2, newAccounts.size());
        System.assertEquals(ld.Property_Address__c, newAccounts[1].Name);

        List<AccountContactRelation> newACRs = [SELECT Id, ContactId, AccountId FROM AccountContactRelation];
        System.assertEquals(1, newACRs.size());
        System.assertEquals(newContacts[0].Id, newACRs[0].ContactId);
    }
}