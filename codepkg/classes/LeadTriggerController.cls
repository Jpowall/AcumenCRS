public with sharing class LeadTriggerController {
    private static CityDAI cityAccessor = new CityDA();
    private static AccountDAI accountAccessor = new AccountDA();
    private static ContactDAI contactAccessor = new ContactDA();


    @TestVisible private Map<String, Account> accountNameToAccountMap = new Map<String, Account>();
    @TestVisible private Map<String, Contact> emailToContacts = new Map<String, Contact>();
    @TestVisible private Map<String, String> accountNameToContactEmail = new Map<String, String>();
    @TestVisible private Map<String, Account> namesToAccountsWithIds = new Map<String, Account>();

    public LeadTriggerController() {}

    public void beforeInsert(List<Lead> leads) {
        Map<String, City__c> nameToCity = getCityNamesToCity(leads);
        createAccountsFromLeads(leads, nameToCity);
        Map<String, List<Account>> emailToAccounts = createContactsForNewAccounts(leads);
        insertNonDuplicateContacts(this.emailToContacts);
        setPropertyOwnerOnAccounts(emailToContacts, accountNameToContactEmail);
        insertUniqueAccounts();
        createAccountContactRelations(this.emailToContacts, emailToAccounts);
    }

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        createAccountsFromLeads(newLeads, getCityNamesToCity(newLeads));
        Map<String, List<Account>> emailToAccounts = createContactsForNewAccounts(newLeads);
        insertNonDuplicateContacts(this.emailToContacts);
        setPropertyOwnerOnAccounts(emailToContacts, accountNameToContactEmail);
        insertUniqueAccounts();
        createAccountContactRelations(this.emailToContacts, emailToAccounts);
    }

    @TestVisible
    private void createAccountsFromLeads(List<Lead> leads, Map<String, City__c> nameToCity) {
        Map<String, Account> accountNamesToAccount = new Map<String, Account>();
        for (Lead ld : leads) {
            if (!accountNamesToAccount.containsKey(ld.Property_Address__c)) {
                Account newAcc = new Account();
                if (nameToCity.get(ld.Property_City__c) != null) {
                    newAcc.City_2__c = nameToCity.get(ld.Property_City__c).Id;
                }
                newAcc.Name = ld.Property_Address__c;
                newAcc.State_2__c = ld.Property_State__c;
                newAcc.Zip_2__c = ld.PostalCode;
                newAcc.Phone = ld.Phone;
                newAcc.Year_Built_2__c = ld.Year_Built__c;
                accountNamesToAccount.put(newAcc.Name, newAcc);
            }
        }
        this.accountNameToAccountMap = accountNamesToAccount;

        List<Account> preexistingAccounts = accountAccessor.getAccountsByNames(new List<String>(this.accountNameToAccountMap.keySet()));

        for(Account currAccount : preexistingAccounts) {

            if(currAccount.City_2__c == this.accountNameToAccountMap.get(currAccount.Name).City_2__c
                    || this.accountNameToAccountMap.get(currAccount.Name).City_2__c == null) {
                this.accountNameToAccountMap.remove(currAccount.Name);
                this.namesToAccountsWithIds.put(currAccount.Name, currAccount);
            }
        }
    }

    @TestVisible
    private Map<String, List<Account>> createContactsForNewAccounts(List<Lead> leads) {
        Map<String, Contact> emailToContacts = new Map<String, Contact>(); 
        Map<String, List<Account>> emailToAccounts = new Map<String, List<Account>>();
        Map<String, String> accountNameToContactEmail = new Map<String, String>();
        Set<String> accountNames = new Set<String>();

        for(Lead currLead : leads) {
            List<Account> currentContactAccounts = new List<Account>();
            if(!emailToContacts.containsKey(currLead.Email) || !accountNames.contains(currLead.Property_Address__c)) {
                Contact currCon = new Contact();
                Account currAccount = this.namesToAccountsWithIds.get(currLead.Property_Address__c);
                if(currAccount == null) {
                    currAccount  = this.accountNameToAccountMap.get(currLead.Property_Address__c);
                }
                currCon.FirstName = currLead.FirstName;
                currCon.LastName = currLead.LastName;
                currCon.Email = currLead.Email;
                currCon.Phone = currLead.Phone;
                
                if(currAccount != null && currAccount.Id != null) {
                     currCon.AccountId = currAccount.Id;
                }

                accountNames.add(currLead.Property_Address__c);
                if(!accountNameToContactEmail.containsKey(currLead.Property_Address__c)) {
                    accountNameToContactEmail.put(currLead.Property_Address__c, currLead.Email);
                }

                if(!emailToContacts.containsKey(currLead.Email)) {
                    emailToContacts.put(currCon.Email, currCon);
                    currentContactAccounts.add(currAccount);
                    emailToAccounts.put(currCon.Email, currentContactAccounts);
                } else {
                    emailToAccounts.get(currLead.Email).add(currAccount);
                }
            }
        }
        this.emailToContacts = emailToContacts;
        this.accountNameToContactEmail = accountNameToContactEmail;
        return emailToAccounts;
    }

    @TestVisible
    private void insertNonDuplicateContacts(Map<String, Contact> emailToContacts) {
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
        this.emailToContacts = emailToContacts;
    }

    @TestVisible
    private void setPropertyOwnerOnAccounts(Map<String, Contact> emailToContacts, Map<String, String> accountNameToContactEmail) {
        for (String accountName : this.accountNameToAccountMap.keySet()) {
            Account currentAccount = this.accountNameToAccountMap.get(accountName);
            currentAccount.Property_Owner_2__c = emailToContacts.get(accountNameToContactEmail.get(currentAccount.Name)).Id;
        }
    }

    @TestVisible
    private void insertUniqueAccounts() {
        accountAccessor.insertAccounts(this.accountNameToAccountMap.values());
        this.namesToAccountsWithIds.putAll(this.accountNameToAccountMap);
        this.accountNameToAccountMap = namesToAccountsWithIds;
    }

    @TestVisible
    private void createAccountContactRelations(Map<String,Contact> emailToContact, Map<String, List<Account>> emailToAccounts) {
        List<Id> contactIds = new List<Id>();
        List<Id> accountIds = new List<Id>();

        List<Contact> contactsToUpdate = new List<Contact>();
        for(String email : emailToContact.keySet()) {
            Contact currContact = emailToContact.get(email);
            if(currContact.AccountId == null) {
                currContact.AccountId = emailToAccounts.get(email)[0].Id;
                contactsToUpdate.add(currContact);
            }
        }
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }

        for(String currEmail : emailToAccounts.keySet()) {
            contactIds.add(emailToContact.get(currEmail).Id);
            for(Account currAccount : emailToAccounts.get(currEmail)) {
                accountIds.add(currAccount.Id);
            }
        }

        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        List<AccountContactRelation> oldAccountContacts = [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :contactIds AND AccountId IN :accountIds];
        Boolean addNewACR = true;
        for(String currEmail : emailToAccounts.keySet()) {
            for(Account currAccount : emailToAccounts.get(currEmail)) {
                addNewACR = true;
                if(oldAccountContacts != null) {
                    for(AccountContactRelation currACR : oldAccountContacts) {
                        if(currACR.ContactId == emailToContact.get(currEmail).Id && currACR.AccountId == currAccount.Id) {
                            addNewAcr = false;
                        }
                    }
                }

                if(addNewACR) {
                    AccountContactRelation newACR = new AccountContactRelation();
                    newACR.ContactId = emailToContact.get(currEmail).Id;
                    newACR.AccountId = currAccount.Id;
                    acrList.add(newACR);
                }
            }
        }

        insert acrList;
    }

    @TestVisible
    private Map<String, City__c> getCityNamesToCity(List<Lead> leads){
        Map<String, City__c> nameToCity = new Map<String, City__c>();
        List<String> cityNames = new List<String>();
        for(Lead ld : leads) {
            cityNames.add(ld.Property_City__c);
        }

        List<City__c> accountCities = cityAccessor.getCitiesByNames(cityNames);
        for(City__c city : accountCities) {
            nameToCity.put(city.Name, city);
        }
        return nameToCity;
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
}