public with sharing class TL_RingCentral_Logs {

    @InvocableMethod(label='Get Call Logs' description='Get the ring central call logs')
    public static void getLogs(variables[] vars){
        String credName = vars[0].credName;
        String type = vars[0].type;
        if (type == 'call') {
            retrieveAllLogsAndInsert(credName, null, null, 0, 0);
        } else {
            System.debug('Invalid type');
        }    
    }

    public static void retrieveAllLogsAndInsert(String credName, Date dateFrom, Date dateTo, Integer page, Integer perPage) {
        String endpoint = '/v1.0/account/~/extension/~/call-log';
        String dateInterval = '';
        String paginated = '&page=' + page + '&perPage=' + perPage;
       
        if (dateFrom != null && dateTo != null) {
            dateInterval = '?dateFrom=' + isoFormatter(dateFrom) + '&dateTo=' + isoFormatter(dateTo);
        } else {
            dateInterval = '?dateFrom=' + isoFormatter(System.today()) + '&dateTo=' + isoFormatter(System.today().addDays(1));
        }

        String responseBody = TL_RingCentral_Request.send(endpoint + dateInterval + paginated, '', credName, 'GET');
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        List<Object> records = (List<Object>) jsonResponse.get('records');

        if (!records.isEmpty()) {
            for (Object recordObj : records) {
                Map<String, Object> record = (Map<String, Object>) recordObj;
                Map<String, Object> fromItem = (Map<String, Object>) record.get('from');
                Map<String, Object> toItem =  (Map<String, Object>)record.get('to');

                Call_Log__c[] existingRecord = [SELECT Id, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c FROM Call_Log__c WHERE Log_Id__c = : (String) record.get('id') LIMIT 1];

                if (existingRecord.isEmpty()) {
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
                 
                    insert callLog;
                }         
            }
        } else {
            System.debug('The records list is Empty.');
        }     
    }

    public static List<Call_Log__c> retrieveCallLogs() {
        List<Call_Log__c> callLogs = new List<Call_Log__c>();
        callLogs = [SELECT Id, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c, Start_Time__c, Log_Id__c FROM Call_Log__c];
    
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

    // public class retrieveLogsVariables{
    //     @InvocableVariable(label='CredName' description='Credential Name of Custome Metadata' required=true)
    //     public String credName;       
    //     @InvocableVariable(label='DateFrom' description='Start date' required=true)
    //     public Date dateFrom;       
    //     @InvocableVariable(label='DateTo' description='End date' required=true)
    //     public Date dateTo;    
    //     @InvocableVariable(label='Page' description='Page' required=false)
    //     public Integer page;     
    //     @InvocableVariable(label='PerPage' description='Per Page' required=false)
    //     public Integer perPage;     
    // }
    
    public class variables{
        @InvocableVariable(label='type' description='Type' required=true)
        public String type;
        @InvocableVariable(label='CredName' description='Credential Name of Custome Metadata' required=true)
        public String credName;        
    }
    
}