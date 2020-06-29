@isTest
public class TestPropertyTrigger {
	static testmethod void TestAdd() {
    	// Add test logic
    	Test.startTest();
        Property__c newProp = new Property__c();
        //Datetime myDateTime = DateTime.parse('1-20-2015 9:00:00 AM');
		
        newProp.Name='';
       // newInq.Date__c	=myDateTime;
       	
		insert newProp;
    	//Contact con = [Select id,Contact_Type__C, Status__C from Contact where email='bruce.williams@thundertech.com'];
        //System.assert(con.Contact_Type__c);
        Test.stopTest();
    }
}