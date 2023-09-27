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

  @future(callout=true)
  public static void sendSMS(String fromPhone, String toPhone, String message){
    HttpRequest req  = new HttpRequest();
    req.setEndpoint('https://platform.devtest.ringcentral.com/restapi/v1.0/account/~/extension/~/sms');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer '+getToken());
    req.setBody('{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}');
    HttpResponse res = sendRequest(req);
    System.debug(res.getBody());
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
}