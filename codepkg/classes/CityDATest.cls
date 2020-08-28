@isTest
public with sharing class CityDATest {
    public static CityDAI cityAccessor = new CityDA();
    
    @TestSetup
    static void setup(){
        City__c cleveland = new City__c();
        cleveland.Name = 'Cleveland';
        insert cleveland;
    }

    @isTest
    public static void getCitiesByNames_givenCityNames_returnsCities() {
        List<String> names = new List<String>{'Cleveland'};
        Test.startTest();
            City__c queriedCity = cityAccessor.getCitiesByNames(names)[0];
        Test.stopTest();

        System.assertEquals('Cleveland', queriedCity.Name);
    }
}