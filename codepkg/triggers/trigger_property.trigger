trigger trigger_property on Property__c (after insert) {
    for(Property__c prop: Trigger.new){
        Inquiry__c newInq = new Inquiry__c();
        //Datetime myDateTime = DateTime.parse('1-20-2015 9:00:00 AM');
        
        newInq.Property__c= prop.Id;
        newInq.Date__c = prop.CreatedDate;
        //newInq.Contact__c = prop.Owner__c;
        //newInq.CreatedById = prop.CreatedById;
        newInq.Note__c = 'Initial Inquiry';
        // newInq.Date__c   =myDateTime;
        
        insert newInq;
        
    }

       
  
        
        
  
}