trigger trigger_lead on Lead (before insert, before update) {
    System.debug('Lead Trigger');
    LeadTriggerController ltc = new LeadTriggerController();
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            ltc.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate) {
            ltc.beforeUpdate(Trigger.new, Trigger.old);
        }
    }
}