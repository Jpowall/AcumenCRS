public with sharing class LeadTriggerController {
    //TODO: on the lead insert, we must Make an Account, or if it matches an old account, retrieve the old account.
    //Then proceed with contact logic.
    private static CityDAI cityAccessor = new CityDA();
    private static AccountDAI accountAccessor = new AccountDA();
    private static ContactDAI contactAccessor = new ContactDA();
    public LeadTriggerController() {}
    public void beforeInsert(List<Lead> leads) {
        System.debug('in before insert');
        Map<String, City__c> nameToCity = getCityNamesToCity(leads);
        Map<String, Account> namesToAccounts = createAccountsFromLeads(leads, nameToCity);
        createContactsForNewAccounts(leads, namesToAccounts);
    }
    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        System.debug('in before update');
        // List<Lead> leadsForAccountConversion = new List<Lead>();
        // for(Integer i = 0; i < newLeads.size(); i++) {
        //     if(newLeads[i].Property_Address__c != oldLeads[i].Property_Address__c) {
        //         leadsForAccountConversion.add(newLeads[i]);
        //     }
        // }
        Map<String, City__c> nameToCity = getCityNamesToCity(newLeads);
        Map<String, Account> namesToAccounts = createAccountsFromLeads(newLeads, nameToCity);
        createContactsForNewAccounts(newLeads, namesToAccounts);
    }
    private void insertNonDuplicateContacts(Map<String, Contact> emailToContacts, Map<String, List<Id>> emailToAccountIds) {
        System.debug('in insertNonDUplicateContacts');
        System.debug('contacts: ' + emailToContacts);
        System.debug('account id: ' + emailToAccountIds);

        List<Contact> matchingEmailContacts = contactAccessor.getContactsByEmail(new List<String>(emailToContacts.keySet())); //get all contacts with matching emails.
        System.debug('matchingEmailContacts: ' + matchingEmailContacts);
        Map<String, Contact> tempMap = new Map<String, Contact>();
        System.debug('before for');
        if(matchingEmailContacts != null) {
            for(Contact currQueriedContact : matchingEmailContacts) {
                System.debug('in for loop');
                String currEmail = currQueriedContact.Email;
                Contact currNewContact = emailToContacts.get(currQueriedContact.Email);
                if(emailPhoneAndNameMatch(currNewContact, currQueriedContact)) {
                    //no updates in this scenario, but it prevents things in othe scenarios
                } 
                else if(emailAndPhoneMatch(currNewContact, currQueriedContact)) {
                    if(currQueriedContact.AltName__c == null) {
                        currQueriedContact.AltName__c = currNewContact.Name;
                    }
                } 
                else if(emailAndNameMatch(currNewContact, currQueriedContact)) {
                    if(currQueriedContact.OtherPhone == null) {
                        currQueriedContact.OtherPhone = currNewContact.Phone;
                    } 
                } 
                else if(emailsMatch(currNewContact, currQueriedContact)) {
                    if(currQueriedContact.AltName__c == null) {
                        currQueriedContact.AltName__c = currNewContact.Name;
                    }
                    if(currQueriedContact.OtherPhone == null) {
                        currQueriedContact.OtherPhone = currNewContact.Phone;
                    }
                }
                System.debug('after big if');
                emailToContacts.remove(currEmail);
                tempMap.put(currEmail, currQueriedContact);
            }
            System.debug('contact updates: ' + tempMap.values());
            update tempMap.values();
        }
        System.debug('new contacts: ' + emailToContacts.values());
        insert emailToContacts.values();

        if (tempMap != null) {
            emailToContacts.putAll(tempMap);
        }
        createAccountContactRelations(emailToContacts, emailToAccountIds);
    }

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

    private Boolean emailPhoneAndNameMatch(Contact newContact, Contact oldContact) {
        return (emailsMatch(newContact, oldContact) && namesMatch(newContact,oldContact) && phonesMatch(newContact, oldContact));
    }

    private Boolean emailAndPhoneMatch(Contact newContact, Contact oldContact){
        return (emailsMatch(newContact, oldContact) && phonesMatch(newContact, oldContact));
    }

    private Boolean emailAndNameMatch(Contact newContact, Contact oldContact){
        return (emailsMatch(newContact, oldContact) && namesMatch(newContact, oldContact));
    }

    private Boolean nameAndPhoneMatch(Contact newContact, Contact oldContact){
        return (phonesMatch(newContact, oldContact) && namesMatch(newContact, oldContact));
    }

    private Boolean emailsMatch(Contact newContact, Contact oldContact) {
        return (newContact.Email == oldContact.Email || newContact.Email == oldContact.Secondary_Email__c);
    }

    private Boolean namesMatch(Contact newContact, Contact oldContact) {
        return (newContact.Name == oldContact.Name || newContact.Name == oldContact.AltName__c);
    }

    private Boolean phonesMatch(Contact newContact, Contact oldContact) {
        return (newContact.Phone == oldContact.Phone || newContact.Phone == oldContact.OtherPhone);
    }

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

    private void createContactsForNewAccounts(List<Lead> leads, Map<String, Account> namesToAccounts) {
        System.debug('in create contacts for new accounts');
        System.debug('leads: ' + leads);
        System.debug('names to accounts: ' + namesToAccounts);
        Map<String, Contact> emailToContacts = new Map<String, Contact>(); //TODOD not two contacts, one contact with two account IDs
        Map<String, List<Id>> emailToAccountIds = new Map<String, List<Id>>();

        Set<String> accountNames = new Set<String>();

        for(Lead currLead : leads) {
            List<Id> currContactIds = new List<Id>();
            if(!emailToContacts.containsKey(currLead.Email) || !accountNames.contains(currLead.Property_Address__c)) { //no duplicate emails and contacts, but con be one or other since contacts can have more than one account and accounts can have many contacts.
                Contact currCon = new Contact();
                Account currAccount = namesToAccounts.get(currLead.Property_Address__c);
                System.debug('currAccount: ' + currAccount);
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
                    System.debug('email to account ids ' + emailToAccountIds);
                } else {
                    emailToAccountIds.get(currCon.Email).add(currCon.AccountId); //add account Id to list if already made list
                }
            }
        }
        System.debug('emailToContacts: ' + emailToContacts);
        System.debug('emailToAccountIds: ' + emailToAccountIds);
        insertNonDuplicateContacts(emailToContacts, emailToAccountIds);
    }

    private Map<String, Account> createAccountsFromLeads(List<Lead> leads, Map<String, City__c> nameToCity) {
        System.debug('create acounts from leads');
        System.debug('leads: ' + leads);
        Map<String, Account> accountNamesToAccount = new Map<String, Account>();
        for(Lead ld : leads) {
            if(!accountNamesToAccount.containsKey(ld.Property_Address__c)) { //only unique new addresses
                Account newAcc = new Account();
                if(nameToCity.get(ld.Property_City__c) != null) { //protect from null city
                    newAcc.City_2__c = nametoCity.get(ld.Property_City__c).Id;
                }
                newAcc.Name = ld.Property_Address__c;
                newAcc.State_2__c = ld.Property_State__c;
                newAcc.Zip_2__c = ld.PostalCode;
                newAcc.Phone = ld.Phone;
                newAcc.Year_Built_2__c = ld.Year_Built__c;
                accountNamesToAccount.put(newAcc.Name, newAcc);//add to map
            }
        }

        Map<String, Account> namesToAccountsToReturn = new Map<String, Account>();
        for(Account currAccount : accountAccessor.getAccountsByNames(new List<String>(accountNamesToAccount.keySet()))) {//query for duplicate names
            accountNamesToAccount.remove(currAccount.Name); //remove new accounts if they match old accounts
            namesToAccountsToReturn.put(currAccount.Name, currAccount); //add old account for contact updates
        }

        accountAccessor.insertAccounts(accountNamesToAccount.values());
        System.debug('new Accounts: ' + accountNamesToAccount.values());
        namesToAccountsToReturn.putAll(accountNamesToAccount);//add new Accounts for contact updates.
        return namesToAccountsToReturn;
    }
}