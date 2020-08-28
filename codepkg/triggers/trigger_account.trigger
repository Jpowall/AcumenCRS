trigger trigger_account on Account (before insert) {
	AccountTriggerController atc = new AccountTriggerController();
	if(Trigger.isBefore && Trigger.isInsert) {
		atc.beforeInsert(Trigger.new);
	}
}