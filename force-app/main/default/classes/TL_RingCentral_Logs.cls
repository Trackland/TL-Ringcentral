public with sharing class TL_RingCentral_Logs {

    @future(callout=true)
    public static void retrieveAllLogsAndInsert() {
        String endpoint = '/v1.0/account/~/extension/~/call-log';
        String responseBody = TL_RingCentral_Request.send(endpoint, '', 'BullOakProduction', 'GET');
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        List<Object> records = (List<Object>) jsonResponse.get('records');

        if (!records.isEmpty()) {
            for (Object recordObj : records) {
                Call_Log__c callLog = new Call_Log__c();
                Map<String, Object> record = (Map<String, Object>) recordObj;
                Map<String, Object> fromItem = (Map<String, Object>) record.get('from');
                Map<String, Object> toItem =  (Map<String, Object>)record.get('to');

                Call_Log__c[] existingRecord = [SELECT Id, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c FROM Call_Log__c WHERE Log_Id__c = : (String) record.get('id') LIMIT 1];

                if (existingRecord.isEmpty()) {
                  callLog.Log_Id__c = (String) record.get('id');
                  callLog.Session_Id__c = (String) record.get('sessionId');
                  callLog.Record_Url__c = (String) record.get('uri');
                  callLog.Action__c = (String) record.get('action');
                  callLog.Direction__c = (String) record.get('direction');
                  callLog.Duration__c = (Integer) record.get('duration');
                  callLog.From_Location__c = (String) fromItem.get('location');
                  callLog.From_Name__c = (String) fromItem.get('name');
                  callLog.From_Phone_Number__c = (String) fromItem.get('phoneNumber');
                  callLog.Result__c = (String) record.get('result');
                  callLog.To_Name__c = (String) toItem.get('name');
                  callLog.To_Phone_Number__c = (String) toItem.get('phoneNumber');
                  callLog.Type__c = (String) record.get('type');
                  callLog.Start_Time__c = (Datetime) JSON.deserialize('"' + (String) record.get('startTime') + '"', Datetime.class);
  
                  insert callLog;
                }         
            }
        } else {
            System.debug('The records list is Empty.');
        }     
    }

    public static void retrieveCallLogs() {
        List<Call_Log__c> callLogs = new List<Call_Log__c>();
        callLogs = [SELECT Id, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c, Start_Time__c, Log_Id__c FROM Call_Log__c];
    
        if (!callLogs.isEmpty()) {
          for (Call_Log__c callLog : callLogs) {
            System.debug('Log ID: ' + callLog);
          }
        } else {
            System.debug('The records list is Empty.');
        }
    }    
}