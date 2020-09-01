@isTest
public with sharing class ContactDATest {
    public static ContactDAI contactAccessor = new ContactDA();
    @isTest
    public static void getContactsByEmail_givenEmailList_ReturnsContacts(){
        Contact contact1 = new Contact();
        contact1.email = 'testemail1@test.com';
        contact1.lastName = 'lastName';
        Contact contact2 = new Contact();
        contact2.email = 'testemail2@test.com';
        contact2.lastName = 'lastName';
        insert new List<Contact>{contact1, contact2};

        List<String> emails = new List<String>{'testemail1@test.com'};
        Test.startTest();
        List<Contact> queriedContacts = contactAccessor.getContactsByEmail(emails);
        Test.stopTest();

        System.assertEquals(1, queriedContacts.size());
        System.assertEquals(contact1.email, queriedContacts[0].email);
    }
}