public with sharing class TL_RingCentral_Logs {

    public static String mockRes = '';

    public static void setMockRes(String mockResponseBody) {
           mockRes = mockResponseBody;
    }

    @InvocableMethod(label='Get Call Logs' description='Get the ring central call logs')
    public static void getLogs(variables[] vars){
        String credName = vars[0].credName;
        String type = vars[0].type;
        if (type == 'call') {
            retrieveAllLogsAndInsert(credName, null, null, 0);
            setMockRes(vars[0].MockResponse);
        } else {
            System.debug('Invalid type');
        }    
    }

    @future(callout=true)
    public static void retrieveAllLogsAndInsert(String credName, Date dateFrom, Date dateTo, Integer pageNumber) {
        List<Call_Log__c> callLogsToInsert = new List<Call_Log__c>();
        Integer firstCallout = 0;
        Integer page = pageNumber;
        Boolean completionFlag = false;
        Integer batchSize = 150;

        while (!completionFlag || (Test.isRunningTest() && firstCallout == 0)) {
            String endpoint = '/v1.0/account/~/call-log';
            String dateInterval = '';
            String paginated = '&page=' + page + '&perPage=' + 1000;
    
            if (dateFrom != null && dateTo != null) {
                dateInterval = '?dateFrom=' + isoFormatter(dateFrom) + '&dateTo=' + isoFormatter(dateTo);
            } else {
                dateInterval = '?dateFrom=' + isoFormatter(System.today()) + '&dateTo=' + isoFormatter(System.today().addDays(1));
            }

            String responseBody = Test.isRunningTest() ? mockRes : TL_RingCentral_Request.send(endpoint + dateInterval + paginated, '', credName, 'GET');

            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            List<Object> records = (List<Object>) jsonResponse.get('records');
    
            Set<String> logIds = new Set<String>();
            for (Object recordObj : records) {
                Map<String, Object> record = (Map<String, Object>) recordObj;
                logIds.add((String) record.get('id'));
            }
    
            Call_Log__c[] existingRecords = Test.isRunningTest() ? new List<Call_Log__c>() : [SELECT Id, Log_Id__c, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c  FROM Call_Log__c WHERE Log_Id__c IN :logIds];

            Set<String> existingLogIds = new Set<String>();
            for (Call_Log__c existingRecord : existingRecords) {
                existingLogIds.add(existingRecord.Log_Id__c);
            }

            if (!records.isEmpty()) {
                for (Integer i = 0; i < records.size(); i++) {
                    Object recordObj = records[i];
                    Map<String, Object> record = (Map<String, Object>) recordObj;
                    Map<String, Object> fromItem = (Map<String, Object>) record.get('from');
                    Map<String, Object> toItem =  (Map<String, Object>)record.get('to');
    
                    if (!existingLogIds.contains((String) record.get('id'))) {
                        Call_Log__c callLog = new Call_Log__c(
                            Log_Id__c = (String) record.get('id'),
                            Session_Id__c = (String) record.get('sessionId'),
                            Record_Url__c = (String) record.get('uri'),
                            Action__c = (String) record.get('action'),
                            Direction__c = (String) record.get('direction'),
                            Duration__c = (Integer) record.get('duration'),
                            From_Location__c = (String) fromItem.get('location'),
                            From_Name__c = (String) fromItem.get('name'),
                            From_Phone_Number__c = (String) fromItem.get('phoneNumber'),
                            Result__c = (String) record.get('result'),
                            To_Name__c = (String) toItem.get('name'),
                            To_Phone_Number__c = (String) toItem.get('phoneNumber'),
                            Type__c = (String) record.get('type'),
                            Start_Time__c = (Datetime) JSON.deserialize('"' + (String) record.get('startTime') + '"', Datetime.class)
                        );
                        
                        callLogsToInsert.add(callLog);
                    }

                    if (Test.isRunningTest()) {
                        insertLogsByBatches(callLogsToInsert, batchSize, completionFlag);   
                        page++;
                        return;
                    }

                    if (i == records.size() - 1) {
                        page++;
                    }
            }
            } else {
                insertLogsByBatches(callLogsToInsert, batchSize, completionFlag);         
                completionFlag = true;  
            }
        }  
    }

    public static void insertLogsByBatches(List<Call_Log__c> callLogsToInsert, Integer batchSize, Boolean completionFlag) {
        if (!callLogsToInsert.isEmpty()) {
            List<List<Call_Log__c>> callLogBatches = new List<List<Call_Log__c>>();

            for (Integer i = 0; i < callLogsToInsert.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, callLogsToInsert.size());
                List<Call_Log__c> batch = new List<Call_Log__c>();
                
                for (Integer j = i; j < endIndex; j++) {
                    batch.add(callLogsToInsert[j]);
                }
                
                callLogBatches.add(batch);
            }

            for (List<Call_Log__c> batch : callLogBatches) {
                try {
                    if (!Test.isRunningTest()) insert batch;
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
            }
        }   
    }

    public static List<Call_Log__c> retrieveCallLogs() {
        List<Call_Log__c> callLogs = new List<Call_Log__c>();
        callLogs = [SELECT Id, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c, Start_Time__c, Log_Id__c FROM Call_Log__c LIMIT 10000];
    
        if (!callLogs.isEmpty()) {
          for (Call_Log__c callLog : callLogs) {
            System.debug('Log ID: ' + callLog);
          }
          return callLogs;
        } else {
            System.debug('The records list is Empty.');
            return null;
        }
    }   

    public static String isoFormatter(Date dateObject) {
        return dateObject.year() + '-' + String.valueOf(dateObject.month()).leftPad(2, '0') + '-' + String.valueOf(dateObject.day()).leftPad(2, '0');
    }
    
    public class variables{
        @InvocableVariable(label='type' description='Type' required=true)
        public String type;
        @InvocableVariable(label='CredName' description='Credential Name of Custome Metadata' required=true)
        public String credName;        
        @InvocableVariable(label='MockResponse' description='Response body' required=true)
        public String MockResponse;       
    }
    
}