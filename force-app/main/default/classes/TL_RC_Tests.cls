@IsTest
public with sharing class TL_RC_Tests {

  public static RC_Credential__mdt cred;

  public static Call_Log__c createCallLog(
    String id,
    String sessionId,
    String uri,
    String action,
    String direction,
    Integer duration,
    String fromLocation,
    String fromName,
    String fromPhoneNumber,
    String result,
    String toName,
    String toPhoneNumber,
    String type,
    Datetime startTime
) {
    Call_Log__c log = new Call_Log__c(
        Log_Id__c = id,
        Session_Id__c = sessionId,
        Record_Url__c = uri,
        Action__c = action,
        Direction__c = direction,
        Duration__c = duration,
        From_Location__c = fromLocation,
        From_Name__c = fromName,
        From_Phone_Number__c = fromPhoneNumber,
        Result__c = result,
        To_Name__c = toName,
        To_Phone_Number__c = toPhoneNumber,
        Type__c = type,
        Start_Time__c = startTime
    );
    return log;
}

  @IsTest
  static void TestGetToken(){
    dataInit();
    Test.setMock(HttpCalloutMock.class, new GetTokenMock()); 
    Test.startTest();
    String name = null;
    RingCredential__mdt cred = TL_RingCentral_Request.getToken(name);
    Test.stopTest();  
    System.assert(cred.token__c == 'U0pDMTJQMDFQQVMwMHxBQUNQcl9wZUFST09rclZYaXJ3R0UtNUZwV2FHOU9xemJMLWY3MlpQdUpnLWMxR0x2V2hfbFhiSXFMVWlxUF9XTVZsVHVKTkY0ZExQU3l6THhZN3VaMy1UYXIxZGF2TFd3VUxIeGY0ZjVYNmZnWHJzZHRNMFpuVUFsVG9WamFlaDFqb01TcmY1dnlhcllra1JDSWhnOUlJRGZKY2lPazEyMzhVZGt5dUFaMzc4Q0ZmQjg2bDh2YWJqZ1g4RUEwR0l6YmI0SUhkaWFZd3xOT0FtbGd8WmVMWTNHREpaU2dDSTh2OFllOG0zd3xBUXxBQXxBQUFBQUZJdk5Vcw');
  }

  @IsTest
  static void TestSMS(){
    TL_RingCentral_SMS.variables testVariables = new TL_RingCentral_SMS.variables();
    testVariables.credName = null;
    testVariables.fromPhone = '+13214567788';
    testVariables.toPhone = '+123456789';
    testVariables.message = 'messageTest';
    dataInit();
    Test.setMock(HttpCalloutMock.class, new SendSMSMock()); 
    Test.startTest();
    TL_RingCentral_SMS.send(new List<TL_RingCentral_SMS.variables>{ testVariables });
    Test.stopTest();
  }

  @IsTest
  static void TestGetCallLogs() {
    TL_RingCentral_Logs.variables testVariables = new TL_RingCentral_Logs.variables();
    testVariables.credName = null;
    testVariables.type = 'call';
    dataInit();    
    String mockResponseBody = '{"navigation":{"firstPage":{"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}},"paging":{"perPage":100,"page":1},"records":[{"legs":[{"master":true,"legType":"RingOutWebToSubscriber","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z"}],"billing":{"costPurchased":0,"costIncluded":0},"lastModifiedTime":"2023-11-09T20:54:10.004Z","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z","sessionId":"18674467005","id":"AYtyfQ1ebnW5DUA","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfQ1ebnW5DUA?view=Detailed"}],"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}';
    Test.setMock(HttpCalloutMock.class, new GetLogsMock()); 
    testVariables.MockResponse = mockResponseBody;
    Test.startTest();
    TL_RingCentral_Logs.getLogs(new List<TL_RingCentral_Logs.variables>{ testVariables });
    Test.stopTest();   
  }

  @IsTest
  static void TestRunningJobs() {
        SMS_Job__c newJob = new SMS_Job__c();
        newJob.FromAccount__c = 'Tampa';
        newJob.FromPhone__c = '+13854296821';
        newJob.ToContact__c = 'Will Johnson';
        newJob.ToPhone__c = '+18043815513';
        newJob.Send_At__c = Datetime.now().addDays(-1);
        newJob.Message__c = 'Your appointment with Bull Oak Clinic is tomorrow! We cant wait to see you and help you on your journey to improved health. If you need to reschedule or have any questions, call us at ' + newJob.FromPhone__c + '. See you soon!';
        newJob.SMS_Sequence_Template__c = null;
        newJob.Status__c = 'Waiting';

        insert newJob;
        
        Test.startTest();
        TL_RingCentral_SMS.jobProcessing('Production');
        Test.stopTest();   

        SMS_Job__c[] jobsAfterProcessing = [SELECT Id, Status__c, RC_SMS_Id__c FROM SMS_Job__c WHERE Id = :newJob.Id];
        System.assertEquals('Complete', jobsAfterProcessing[0].Status__c);
        System.assertEquals('1234567890', jobsAfterProcessing[0].RC_SMS_Id__c);
  }

  @isTest
    static void TestRetrieveCallLogs() {
        List<Call_Log__c> callLogsToInsert = new List<Call_Log__c>();
        callLogsToInsert.add(createCallLog(
            'AYtyfnCj5tNDDUA',
            '18674468005',
            'https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfnCj5tNDDUA?view=Detailed',
            'RingOut Web',
            'Outbound',
            6,
            null,
            'Spencer Rose',
            '+13215236699',
            'Stopped',
            null,
            '+13214567788',
            'Voice',
            Datetime.newInstance(2023, 11, 9, 20, 53, 59)
        ));
        insert callLogsToInsert;
        
        Test.startTest();
        List<Call_Log__c> callLogs = TL_RingCentral_Logs.retrieveCallLogs();
        Test.stopTest();
        
        System.assertEquals(1, callLogs.size(), 'One call log expected');
  }

  @IsTest
    static void testSchedulableMethod() {
        Test.startTest();
        Datetime currentDateTime = Datetime.now();
        String jobCred = System.schedule('testSchedulerMethod', TestScheduledApexFromTestMethod.CRON_EXP, new TestScheduledApexFromTestMethod());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobCred];

        if (currentDateTime.hour() >= 3) {
          currentDateTime = currentDateTime.addDays(1);
        }

        Datetime scheduledDateTime = Datetime.newInstance(
          currentDateTime.year(),
          currentDateTime.month(),
          currentDateTime.day(),
          3,
          0,
          0
        );

        System.assertEquals(TestScheduledApexFromTestMethod.CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(scheduledDateTime.format('yyyy-MM-dd HH:mm:ss'), String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
  }

  @isTest
  static void testInit() {
        Test.startTest();
        TL_SchedulerSMSControls.init(5);
        Test.stopTest();

        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :'Schedulable SMS Jobs' LIMIT 1];
        System.assertNotEquals(0, cronTriggers.size(), 'No se creó el trabajo programado');
  }
  
  public class GetTokenMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"access_token":"U0pDMTJQMDFQQVMwMHxBQUNQcl9wZUFST09rclZYaXJ3R0UtNUZwV2FHOU9xemJMLWY3MlpQdUpnLWMxR0x2V2hfbFhiSXFMVWlxUF9XTVZsVHVKTkY0ZExQU3l6THhZN3VaMy1UYXIxZGF2TFd3VUxIeGY0ZjVYNmZnWHJzZHRNMFpuVUFsVG9WamFlaDFqb01TcmY1dnlhcllra1JDSWhnOUlJRGZKY2lPazEyMzhVZGt5dUFaMzc4Q0ZmQjg2bDh2YWJqZ1g4RUEwR0l6YmI0SUhkaWFZd3xOT0FtbGd8WmVMWTNHREpaU2dDSTh2OFllOG0zd3xBUXxBQXxBQUFBQUZJdk5Vcw","token_type":"bearer","expires_in":3600,"refresh_token":"U0pDMTJQMDFQQVMwMHxBQUJBQmhFX2xmcTFCS2pnRURvTTRiS1dzN0EyaGo4dFFmbkotTDE1Zkl3YWI1MENKS1BmeGJ3bVdrNm9oV0tFRF9HOXo5Z2NBTE5PdHhITnVMWUw2dEo5Ukt4UVotOVpLNGs2TFo0clJRS004aHd4Qm5NYmxDazM0amtwWmRPQlpJcGhpWkh1THNsUkdDbG10VEhtUExDQUNDdHRIeGpndmE1NzR0bEFUUzV3YjZjOHZaNi1GYktlVlBEa2V3RmktNndqRTEyTVlQd3xOT0FtbGd8aTZfWTJnSHFOS0ZvLWRvWmQ2anoxd3xBUXxBQXxBQUFBQVBReFV6Zw","refresh_token_expires_in":604800,"scope":"ReadContacts Contacts ReadAccounts SMS","owner_id":"813339005","endpoint_id":"9jmVM8WAQUuT6xVatEHX4Q"}');
      res.setStatusCode(200);
      return res;
    }
  }

  public class SendSMSMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"lastModifiedTime":"2023-11-09T20:43:42.080Z","conversation":{"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/conversation/2253133558236721312","id":"2253133558236721312"},"conversationId":2253133558236721400,"smsSendingAttemptsCount":1,"messageStatus":"Queued","subject":"Test SMS using a RingCentral Developer account - We have 20 API Calls","availability":"Alive","direction":"Outbound","attachments":[{"contentType":"text/plain","type":"Text","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/message-store/15091055005/content/15091055005","id":15091055005}],"priority":"Normal","readStatus":"Read","creationTime":"2023-11-09T20:43:41.000Z","type":"SMS","from":{"name":"Spencer Rose","phoneNumber":"+14705020091"},"to":[{"phoneNumber":"+15623221440"}],"id":15091055005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/message-store/15091055005"}');
      res.setStatusCode(200);
      return res;
    }
  }  

  public class GetLogsMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"navigation":{"firstPage":{"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}},"paging":{"perPage":100,"page":1},"records":[{"legs":[{"master":true,"legType":"RingOutWebToSubscriber","transport":"PSTN","partyId":"p-a1d14572f7ff2z18bb5dcf88az3915b50000-1","telephonySessionId":"s-a1d14572f7ff2z18bb5dcf88az3915b50000","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Stopped","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"&que","durationMs":5797,"duration":6,"startTime":"2023-11-09T20:53:59.607Z"}],"billing":{"costPurchased":0,"costIncluded":0},"lastModifiedTime":"2023-11-09T20:54:20.004Z","transport":"PSTN","partyId":"p-a1d14572f7ff2z18bb5dcf88az3915b50000-1","telephonySessionId":"s-a1d14572f7ff2z18bb5dcf88az3915b50000","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Stopped","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":5797,"duration":6,"startTime":"2023-11-09T20:53:59.607Z","sessionId":"18674468005","id":"AYtyfnCj5tNDDUA","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfnCj5tNDDUA?view=Detailed"},{"legs":[{"master":true,"legType":"RingOutWebToSubscriber","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z"}],"billing":{"costPurchased":0,"costIncluded":0},"lastModifiedTime":"2023-11-09T20:54:10.004Z","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z","sessionId":"18674467005","id":"AYtyfQ1ebnW5DUA","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfQ1ebnW5DUA?view=Detailed"}],"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}');
      res.setStatusCode(200);
      return res;
    }
  }    

  private static void dataInit(){
    cred = new RingCredential__mdt();
    cred.DeveloperName = 'Sandbox';
    cred.URL__c = 'https://platform.devtest.ringcentral.com/restapi';
    cred.version__c = 'v1.0';
    cred.ClientId__c = '90s09asfsd90dsf';
    cred.ClientSecret__c = '90s09asfsd90dsf';
    cred.JWT__c = 'osldkjiflasdl';
  }

}

