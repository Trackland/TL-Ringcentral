@IsTest
public with sharing class TL_Ring_Tests {

  public static RingCredential__mdt cred;

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
    dataInit();
    Test.setMock(HttpCalloutMock.class, new SendSMSMock()); 
    Test.startTest();
    TL_RingCentral_SMS.send('23423', '23432', 'messageTest');
    Test.stopTest();
  }

  // @IsTest
  // static void getCallLogs() {
  //   Test.setMock(HttpCalloutMock.class, new GetLogsMock()); 
  //   Test.startTest();
  //   TL_Ring_SendRequest.retrieveAllLogsAndInsert();
  //   Test.stopTest();
  // }

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

