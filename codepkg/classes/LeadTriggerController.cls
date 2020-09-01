public with sharing class LeadTriggerController {
    private static CityDAI cityAccessor = new CityDA();
    private static AccountDAI accountAccessor = new AccountDA();
    private static ContactDAI contactAccessor = new ContactDA();
    public LeadTriggerController() {}

    public void beforeInsert(List<Lead> leads) {
        Map<String, City__c> nameToCity = getCityNamesToCity(leads);
        Map<String, Account> namesToAccounts = createAccountsFromLeads(leads, nameToCity);
        createContactsForNewAccounts(leads, namesToAccounts);
    }

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        Map<String, Account> namesToAccounts = createAccountsFromLeads(newLeads, getCityNamesToCity(newLeads));
        createContactsForNewAccounts(newLeads, namesToAccounts);
    }

    @TestVisible
    private void insertNonDuplicateContacts(Map<String, Contact> emailToContacts, Map<String, List<Id>> emailToAccountIds) {
        List<Contact> matchingEmailContacts = contactAccessor.getContactsByEmail(new List<String>(emailToContacts.keySet()));
        Map<String, Contact> tempMap = new Map<String, Contact>();
        if(matchingEmailContacts != null) {
            for(Contact currQueriedContact : matchingEmailContacts) {
                String currEmail = currQueriedContact.Email;
                if(emailToContacts != null && emailToContacts.get(currQueriedContact.Email) != null) {

                    Contact currNewContact = emailToContacts.get(currQueriedContact.Email);
                    if(!nameAndPhoneMatch(currNewContact, currQueriedContact)) {
                        if(phonesMatch(currNewContact, currQueriedContact)) {
                            if(currQueriedContact.AltName__c == null) {
                                currQueriedContact.AltName__c = currNewContact.Name;
                            }
                        } 
                        else if(namesMatch(currNewContact, currQueriedContact)) {
                            if(currQueriedContact.OtherPhone == null) {
                                currQueriedContact.OtherPhone = currNewContact.Phone;
                            } 
                        } 
                        else {
                            if(currQueriedContact.AltName__c == null) {
                                currQueriedContact.AltName__c = currNewContact.Name;
                            }
                            if(currQueriedContact.OtherPhone == null) {
                                currQueriedContact.OtherPhone = currNewContact.Phone;
                            }
                        }
                    }
                    emailToContacts.remove(currEmail);
                    tempMap.put(currEmail, currQueriedContact);
                }
                update tempMap.values();
            }
        }
        insert emailToContacts.values();

        if (tempMap != null) {
            emailToContacts.putAll(tempMap);
        }
        createAccountContactRelations(emailToContacts, emailToAccountIds);
    }

    @TestVisible
    private void createAccountContactRelations(Map<String,Contact> emailToContact, Map<String, List<Id>> emailToAccountIds) {
        List<Id> contactIds = new List<Id>();
        List<Id> accountIds = new List<Id>();

        for(String currEmail : emailToAccountIds.keySet()) {
            contactIds.add(emailToContact.get(currEmail).Id);
            for(Id accountId : emailToAccountIds.get(currEmail)) {
                accountIds.add(accountId);
            }
        }

        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        List<AccountContactRelation> oldAccountContacts = [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :contactIds AND AccountId IN :accountIds];
        Boolean addNewACR = true;
        for(String currEmail : emailToAccountIds.keySet()) {
            for(Id accountId : emailToAccountIds.get(currEmail)) {
                addNewACR = true;
                if(oldAccountContacts != null) {
                    for(AccountContactRelation currACR : oldAccountContacts) {
                        if(currACR.ContactId == emailToContact.get(currEmail).Id && currACR.AccountId == accountId) {
                            addNewAcr = false;
                        }
                    }
                }

                if(addNewACR) {
                    AccountContactRelation newACR = new AccountContactRelation();
                    newACR.ContactId = emailToContact.get(currEmail).Id;
                    newACR.AccountId = accountId;
                    acrList.add(newACR);
                }
            }
        }

        insert acrList;
    }

    @TestVisible
    private Boolean phonesMatch(Contact newContact, Contact oldContact) {
        return (newContact.Phone == oldContact.Phone || newContact.Phone == oldContact.OtherPhone);
    }

    @TestVisible
    private Boolean namesMatch(Contact newContact, Contact oldContact) {
        return (newContact.Name == oldContact.Name || newContact.Name == oldContact.AltName__c);
    }

    @TestVisible
    private Boolean nameAndPhoneMatch(Contact newContact, Contact oldContact){
        return (phonesMatch(newContact, oldContact) && namesMatch(newContact, oldContact));
    }

    @TestVisible
    private Map<String, City__c> getCityNamesToCity(List<Lead> leads){
        Map<String, City__c> nametoCity = new Map<String, City__c>();
        List<String> cityNames = new List<String>();
        for(Lead ld : leads) {
            cityNames.add(ld.Property_City__c);
        }

        List<City__c> accountCities = cityAccessor.getCitiesByNames(cityNames);
        for(City__c city : accountCities) {
            nametoCity.put(city.Name, city);
        }
        return nameToCity;
    }

    @TestVisible
    private void createContactsForNewAccounts(List<Lead> leads, Map<String, Account> namesToAccounts) {
        Map<String, Contact> emailToContacts = new Map<String, Contact>(); 
        Map<String, List<Id>> emailToAccountIds = new Map<String, List<Id>>();

        Set<String> accountNames = new Set<String>();

        for(Lead currLead : leads) {
            List<Id> currContactIds = new List<Id>();
            if(!emailToContacts.containsKey(currLead.Email) || !accountNames.contains(currLead.Property_Address__c)) { //no duplicate emails and contacts, but con be one or other since contacts can have more than one account and accounts can have many contacts.
                Contact currCon = new Contact();
                Account currAccount = namesToAccounts.get(currLead.Property_Address__c);
                currCon.FirstName = currLead.FirstName;
                CurrCon.LastName = currLead.LastName;
                currCon.Email = currLead.Email;
                currCon.Phone = currLead.Phone;
                
                if(currAccount != null) {
                    currCon.AccountId = currAccount.Id;
                }

                accountNames.add(currLead.Property_Address__c);
                
                if(!emailToContacts.containsKey(currLead.Email)) {
                    emailToContacts.put(currCon.Email, currCon);
                    currContactIds.add(currAccount.Id);
                    emailToAccountIds.put(currCon.Email, currContactIds);
                } else {
                    emailToAccountIds.get(currLead.Email).add(currCon.AccountId); //add account Id to list if already made list
                }
            }
        }
        insertNonDuplicateContacts(emailToContacts, emailToAccountIds);
    }

    @TestVisible
    private Map<String, Account> createAccountsFromLeads(List<Lead> leads, Map<String, City__c> nameToCity) {
        Map<String, Account> accountNamesToAccount = new Map<String, Account>();
        for(Lead ld : leads) {
            if(!accountNamesToAccount.containsKey(ld.Property_Address__c)) { 
                Account newAcc = new Account();
                if(nameToCity.get(ld.Property_City__c) != null) {
                    newAcc.City_2__c = nametoCity.get(ld.Property_City__c).Id;
                }
                newAcc.Name = ld.Property_Address__c;
                newAcc.State_2__c = ld.Property_State__c;
                newAcc.Zip_2__c = ld.PostalCode;
                newAcc.Phone = ld.Phone;
                newAcc.Year_Built_2__c = ld.Year_Built__c;
                accountNamesToAccount.put(newAcc.Name, newAcc);
            }
        }

        Map<String, Account> namesToAccountsToReturn = new Map<String, Account>();
        for(Account currAccount : accountAccessor.getAccountsByNames(new List<String>(accountNamesToAccount.keySet()))) {
            if(currAccount.City_2__c  == accountNamesToAccount.get(currAccount.Name).City_2__c || accountNamesToAccount.get(currAccount.Name).City_2__c == null) {
                accountNamesToAccount.remove(currAccount.Name);
                namesToAccountsToReturn.put(currAccount.Name, currAccount);
            }
        }

        accountAccessor.insertAccounts(accountNamesToAccount.values());
        namesToAccountsToReturn.putAll(accountNamesToAccount);
        return namesToAccountsToReturn;
    }
}