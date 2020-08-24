trigger trigger_lead on Lead (before insert) {
    LeadTriggerController ltc = new LeadTriggerController();
    if(Trigger.isBefore && Trigger.isInsert) {
        ltc.beforeInsert(Trigger.new);
    }
}