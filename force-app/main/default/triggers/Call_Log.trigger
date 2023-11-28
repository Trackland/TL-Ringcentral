trigger Call_Log on Call_Log__c (after insert, after update) {
  TL_RingCentral_Logs.QueueConnectToContact(Trigger.new);
}