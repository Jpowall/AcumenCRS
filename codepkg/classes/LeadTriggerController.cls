public with sharing class LeadTriggerController {
    private CityDAI cityAccessor;
        
    public LeadTriggerController() {
        cityAccessor = new CityDA();
    }

    public void beforeInsert(List<Lead> leads) {
        List<Account> newAccs = new List<Account>();
        List<String> cityNames = new List<String>();
        for(Lead ld : leads){
            cityNames.add(ld.Property_City__c);
        }

        List<City__c> accountCities = cityAccessor.getCitiesByNames(cityNames);

        Map<String, City__c> nametoCity = new Map<String, City__c>();
        for(City__c city : accountCities) {
            nametoCity.put(city.Name, city);
        }

        for(Lead ld : leads){
            Account newAcc = new Account();
            newAcc.City_2__c = nametoCity.get(ld.Property_City__c).Id;
            newAcc.Name = ld.Property_Address__c;
            newAcc.State_2__c = ld.Property_State__c;
            newAcc.Zip_2__c = ld.PostalCode;
            newAcc.Phone = ld.Phone;
            newAcc.Year_Built_2__c = ld.Year_Built__c;
            newAccs.add(newAcc);
        }
        insert newAccs;
    }
}