public with sharing class CityDA implements CityDAI {
    public List<City__c> getCitiesByNames(List<String> cityNames) {
        List<City__c> cities = [SELECT Id, Name, County__c FROM City__c WHERE Name IN :cityNames];
        return cities;
    }
}