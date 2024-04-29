@IsTest
public with sharing class TL_RC_Tests {
  public static RC_Credential__mdt cred;

  @IsTest
  static void TestGetToken() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new GetTokenMock());
    Test.startTest();
    String name = null;
    RC_Credential__mdt cred = TL_RC_Request.getToken(name);
    Test.stopTest();
    System.assert(
      cred.token__c ==
      'U0pDMTJQMDFQQVMwMHxBQUNQcl9wZUFST09rclZYaXJ3R0UtNUZwV2FHOU9xemJMLWY3MlpQdUpnLWMxR0x2V2hfbFhiSXFMVWlxUF9XTVZsVHVKTkY0ZExQU3l6THhZN3VaMy1UYXIxZGF2TFd3VUxIeGY0ZjVYNmZnWHJzZHRNMFpuVUFsVG9WamFlaDFqb01TcmY1dnlhcllra1JDSWhnOUlJRGZKY2lPazEyMzhVZGt5dUFaMzc4Q0ZmQjg2bDh2YWJqZ1g4RUEwR0l6YmI0SUhkaWFZd3xOT0FtbGd8WmVMWTNHREpaU2dDSTh2OFllOG0zd3xBUXxBQXxBQUFBQUZJdk5Vcw'
    );
  }

  @IsTest
  static void TestSMS() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new SendSMSMock());
    Test.startTest();
    TL_RC_SMS.send(null, null, null, null);
    Test.stopTest();
  }

  @IsTest
  static void TestGetCallLogs() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new GetLogsMock());
    Test.startTest();
    TL_RC_Logs.getLogs(null, null, null, null);
    Test.stopTest();
  }

  @IsTest
  static void TestRunningJobs() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new RunJobsMock());
    Test.startTest();
    TL_RC_SMS.jobProcessing(null);
    Test.stopTest();
  }

  @isTest
  static void testInit() {
    dataInit();
    Test.startTest();
    TL_RC_SMS_Controls.init(5);
    TL_RC_Logs_Controls.init(5);
    TL_RC_SMS_ISync_Controls.init(300);
    TL_RC_SMS_FSync_Controls.init();
    Test.stopTest();

    Set<String> targetCronJobNames = new Set<String>{ 'Schedulable SMS Jobs', 'Get RingCentral Logs', 'Schedulable SMS Logs FSync', 'Schedulable SMS Logs ISync' };
    List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name IN :targetCronJobNames LIMIT 4];
    System.assertNotEquals(0, cronTriggers.size(), 'The scheduled job was not created');
    System.assertEquals(4, cronTriggers.size());
  }

  @isTest
  static void testSMSSync() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new GetSMSMock());
    Test.startTest();
    TL_RC_SMS_Sync.getSMSRecords(null, 'FSync', null, null);
    Test.stopTest();
  }

  @isTest
  static void testQueueExecutionSuccess() {
    dataInit();
    Test.setMock(HttpCalloutMock.class, new RunJobsMock());

    RC_SMS_Job__c testJob = [SELECT Id, FromPhone__c, ToPhone__c, Message__c FROM RC_SMS_Job__c WHERE Status__c = 'Waiting' LIMIT 1];

    TL_RC_SMS_Queue queueInstance = new TL_RC_SMS_Queue(testJob.FromPhone__c, testJob.ToPhone__c, testJob.Message__c, cred.DeveloperName, JSON.serialize(testJob), 0);

    Test.startTest();
    queueInstance.execute(null);
    Test.stopTest();

    RC_SMS_Job__c updatedJob = [SELECT Id, Status__c FROM RC_SMS_Job__c WHERE Id = :testJob.Id LIMIT 1];
    System.assertEquals('Complete', updatedJob.Status__c);
  }

  public class GetSMSMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(
        '{"uri":"https://platform.ringcentral.com/restapi/v1.0/account/2968449036/extension/2972050036/message-sync?messageType=SMS&syncType=FSync&recordCount=1","records":[{"uri":"https://platform.ringcentral.com/restapi/v1.0/account/2968449036/extension/2972050036/message-store/2048985300036","id":2048985300036,"to":[{"phoneNumber":"+15406645445"}],"from":{"phoneNumber":"+13854296821","name":"Spencer Rose","location":"Salt Lake City, UT"},"type":"SMS","creationTime":"2023-12-04T20:24:02.000Z","readStatus":"Read","priority":"Normal","attachments":[{"id":2048985300036,"uri":"https://media.ringcentral.com/restapi/v1.0/account/2968449036/extension/2972050036/message-store/2048985300036/content/2048985300036","type":"Text","contentType":"text/plain"}],"direction":"Outbound","availability":"Alive","subject":"Your appointment with Bull Oak Clinic is tomorrow! We cant wait to see you and help you on your journey to improved health. If you need to reschedule or have any questions, call us at +18043815060. See you soon!","messageStatus":"Delivered","smsSendingAttemptsCount":1,"conversationId":7784370116995079010,"conversation":{"id":"7784370116995079010","uri":"https://platform.ringcentral.com/restapi/v1.0/conversation/7784370116995079010"},"lastModifiedTime":"2023-12-04T20:24:04.170Z"}],"syncInfo":{"syncType":"FSync","syncToken":"AQEAAAAQAwAAAYw2gIbQBgAAAAEFAAABjDaRY_YTAAgAAAAAsSXidAkBChEZAAABjDaRT89HoBA6","syncTime":"2023-12-04T20:42:27.190Z","olderRecordsExist":true}}'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  public class GetTokenMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(
        '{"access_token":"U0pDMTJQMDFQQVMwMHxBQUNQcl9wZUFST09rclZYaXJ3R0UtNUZwV2FHOU9xemJMLWY3MlpQdUpnLWMxR0x2V2hfbFhiSXFMVWlxUF9XTVZsVHVKTkY0ZExQU3l6THhZN3VaMy1UYXIxZGF2TFd3VUxIeGY0ZjVYNmZnWHJzZHRNMFpuVUFsVG9WamFlaDFqb01TcmY1dnlhcllra1JDSWhnOUlJRGZKY2lPazEyMzhVZGt5dUFaMzc4Q0ZmQjg2bDh2YWJqZ1g4RUEwR0l6YmI0SUhkaWFZd3xOT0FtbGd8WmVMWTNHREpaU2dDSTh2OFllOG0zd3xBUXxBQXxBQUFBQUZJdk5Vcw","token_type":"bearer","expires_in":3600,"refresh_token":"U0pDMTJQMDFQQVMwMHxBQUJBQmhFX2xmcTFCS2pnRURvTTRiS1dzN0EyaGo4dFFmbkotTDE1Zkl3YWI1MENKS1BmeGJ3bVdrNm9oV0tFRF9HOXo5Z2NBTE5PdHhITnVMWUw2dEo5Ukt4UVotOVpLNGs2TFo0clJRS004aHd4Qm5NYmxDazM0amtwWmRPQlpJcGhpWkh1THNsUkdDbG10VEhtUExDQUNDdHRIeGpndmE1NzR0bEFUUzV3YjZjOHZaNi1GYktlVlBEa2V3RmktNndqRTEyTVlQd3xOT0FtbGd8aTZfWTJnSHFOS0ZvLWRvWmQ2anoxd3xBUXxBQXxBQUFBQVBReFV6Zw","refresh_token_expires_in":604800,"scope":"ReadContacts Contacts ReadAccounts SMS","owner_id":"813339005","endpoint_id":"9jmVM8WAQUuT6xVatEHX4Q"}'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  public class SendSMSMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(
        '{"lastModifiedTime":"2023-11-09T20:43:42.080Z","conversation":{"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/conversation/2253133558236721312","id":"2253133558236721312"},"conversationId":2253133558236721400,"smsSendingAttemptsCount":1,"messageStatus":"Queued","subject":"Test SMS using a RingCentral Developer account - We have 20 API Calls","availability":"Alive","direction":"Outbound","attachments":[{"contentType":"text/plain","type":"Text","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/message-store/15091055005/content/15091055005","id":15091055005}],"priority":"Normal","readStatus":"Read","creationTime":"2023-11-09T20:43:41.000Z","type":"SMS","from":{"name":"Spencer Rose","phoneNumber":"+14705020091"},"to":[{"phoneNumber":"+15623221440"}],"id":15091055005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/message-store/15091055005"}'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  public class GetLogsMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(
        '{"navigation":{"firstPage":{"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}},"paging":{"perPage":100,"page":1},"records":[{"legs":[{"master":true,"legType":"RingOutWebToSubscriber","transport":"PSTN","partyId":"p-a1d14572f7ff2z18bb5dcf88az3915b50000-1","telephonySessionId":"s-a1d14572f7ff2z18bb5dcf88az3915b50000","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Stopped","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"&que","durationMs":5797,"duration":6,"startTime":"2023-11-09T20:53:59.607Z"}],"billing":{"costPurchased":0,"costIncluded":0},"lastModifiedTime":"2023-11-09T20:54:20.004Z","transport":"PSTN","partyId":"p-a1d14572f7ff2z18bb5dcf88az3915b50000-1","telephonySessionId":"s-a1d14572f7ff2z18bb5dcf88az3915b50000","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Stopped","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":5797,"duration":6,"startTime":"2023-11-09T20:53:59.607Z","sessionId":"18674468005","id":"AYtyfnCj5tNDDUA","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfnCj5tNDDUA?view=Detailed"},{"legs":[{"master":true,"legType":"RingOutWebToSubscriber","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z"}],"billing":{"costPurchased":0,"costIncluded":0},"lastModifiedTime":"2023-11-09T20:54:10.004Z","transport":"PSTN","partyId":"p-a1d1479174d62z18bb5dce6c9z39e1ff0000-1","telephonySessionId":"s-a1d1479174d62z18bb5dce6c9z39e1ff0000","reasonDescription":"An error occurred when making the call. Please try again.","reason":"Resource Error","extension":{"id":826906005,"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005"},"from":{"extensionId":"826906005","phoneNumber":"+13215236699","name":"Spencer Rose"},"to":{"location":"Merritt Island, FL","phoneNumber":"+13214567788"},"result":"Call Failed","action":"RingOut Web","direction":"Outbound","internalType":"LongDistance","type":"Voice","durationMs":835,"duration":1,"startTime":"2023-11-09T20:53:55.075Z","sessionId":"18674467005","id":"AYtyfQ1ebnW5DUA","uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfQ1ebnW5DUA?view=Detailed"}],"uri":"https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log?view=Detailed&showBlocked=true&withRecording=false&dateFrom=2023-11-08T20:49:00.000Z&page=1&perPage=100"}'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  public class RunJobsMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(
        '{"uri":"https://platform.ringcentral.com/restapi/v1.0/account/2968449036/extension/2972050036/message-store/2043603898037","id":2043603898037,"to":[{"phoneNumber":"+15623221440"}],"from":{"phoneNumber":"+18133339207","name":"Spencer Rose","location":"Tampa North, FL"},"type":"SMS","creationTime":"2023-11-28T20:01:42.000Z","readStatus":"Read","priority":"Normal","attachments":[{"id":2043603898037,"uri":"https://media.ringcentral.com/restapi/v1.0/account/2968449036/extension/2972050036/message-store/2043603898037/content/2043603898037","type":"Text","contentType":"text/plain"}],"direction":"Outbound","availability":"Alive","subject":"Thank you for scheduling your visit at Bull Oak Clinic! Your appointment is confirmed for 12/07/2023 10:00 AM. We look forward to assisting you with your health needs. If you have any questions, feel free to reply or call us at +18133339207. See you soon!","messageStatus":"Delivered","smsSendingAttemptsCount":1,"conversationId":4958098973575413451,"conversation":{"id":"4958098973575413451","uri":"https://platform.ringcentral.com/restapi/v1.0/conversation/4958098973575413451"},"lastModifiedTime":"2023-11-28T20:02:14.463Z"}'
      );
      res.setStatusCode(200);
      return res;
    }
  }

  private static void dataInit() {
    cred = new RC_Credential__mdt();
    cred.DeveloperName = 'Sandbox';
    cred.URL__c = 'https://platform.devtest.ringcentral.com/restapi';
    cred.version__c = 'v1.0';
    cred.ClientId__c = '90s09asfsd90dsf';
    cred.ClientSecret__c = '90s09asfsd90dsf';
    cred.JWT__c = 'osldkjiflasdl';

    RC_SMS_Job__c newJob = new RC_SMS_Job__c();
    newJob.FromPhone__c = '+13854296821';
    newJob.ToPhone__c = '+18043815513';
    newJob.Send_At__c = Datetime.now().addDays(-10);
    newJob.Message__c = 'Thank you for scheduling your visit at Bull Oak Clinic! Your appointment is confirmed for. We look forward to assisting you with your health needs. If you have any questions, feel free to reply or call us at {{FromPhone__c}}. See you soon!';
    newJob.SMS_Sequence_Template__c = null;
    newJob.Status__c = 'Waiting';
    insert newJob;

    List<RC_Call_Log__c> callLogsToInsert = new List<RC_Call_Log__c>();
    callLogsToInsert.add(
      new RC_Call_Log__c(
        Log_Id__c = 'AYtyfnCj5tNDDUA',
        Session_Id__c = '18674468005',
        Record_Url__c = 'https://platform.devtest.ringcentral.com/restapi/v1.0/account/826906005/extension/826906005/call-log/AYtyfnCj5tNDDUA?view=Detailed',
        Action__c = 'RingOut Web',
        Direction__c = 'Outbound',
        Duration__c = 6,
        From_Location__c = null,
        From_Name__c = 'Spencer Rose',
        From_Phone_Number__c = '+13215236699',
        Result__c = 'Stopped',
        To_Name__c = null,
        To_Phone_Number__c = '+13214567788',
        Type__c = 'Voice',
        Start_Time__c = Datetime.newInstance(2023, 11, 9, 20, 53, 59)
      )
    );

    insert callLogsToInsert;
  }
}
