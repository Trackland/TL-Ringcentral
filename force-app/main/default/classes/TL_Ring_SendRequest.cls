public with sharing class TL_Ring_SendRequest {
  public static String getToken(){
    RingCredential__mdt cred;
    if(Test.isRunningTest()) cred = new RingCredential__mdt();
    else cred = [SELECT Id, ClientId__c, ClientSecret__c, JWT__c FROM RingCredential__mdt LIMIT 1];
    HttpRequest req  = new HttpRequest();
    String basicAuth = System.EncodingUtil.base64Encode(Blob.valueOf(cred.ClientId__c+':'+cred.ClientSecret__c));
    req.setEndpoint('https://platform.devtest.ringcentral.com/restapi/oauth/token');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setHeader('Authorization', 'Basic '+basicAuth);
    req.setBody('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion='+cred.JWT__c);
    HttpResponse res = sendRequest(req);
    Map<String, Object> resObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    return (String) resObj.get('access_token');
  }

  public static HttpResponse sendRequest(HttpRequest req){
    Http http = new Http();
    HttpResponse res;
    if(Test.isRunningTest()){
      res = new HttpResponse();
      res.setBody('{}');
    }
    else res = http.send(req);
    return res;
  }

  @future(callout=true)
  public static void sendSMS(String fromPhone, String toPhone, String message){
    HttpRequest req  = new HttpRequest();
    req.setEndpoint('https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/sms');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer '+ getToken());
    req.setBody('{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}');
    HttpResponse res = sendRequest(req);
  }

  public static void retrieveAllLogsAndInsert() {
    String endpoint = 'https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/call-log?view=Detailed';

    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Accept', 'application/json');
    request.setHeader('Authorization', 'Bearer '+ getToken());

    HttpResponse response = sendRequest(request);
          
    if (response.getStatusCode() == 200) {
        String responseBody = response.getBody();
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
    } else {
        String errorResponse = 'Error trying to make the request: ' + response.getStatusCode() + ' ' + response.getStatus();
        System.debug(errorResponse);
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