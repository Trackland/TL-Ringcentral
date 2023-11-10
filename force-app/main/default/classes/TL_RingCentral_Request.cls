public with sharing class TL_RingCentral_Request {

    public static string send(String endpoint, String body, String credName, String method){
        RingCredential__mdt cred = getToken(credName);
        HttpRequest req  = new HttpRequest();
        req.setEndpoint(cred.URL__c + endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer '+ cred.token__c);
        if (body != '') req.setBody(body);
        HttpResponse res = sendRequest(req);
        return res.getBody();
    }

    public static RingCredential__mdt getToken(String credName){
        RingCredential__mdt cred = Test.isRunningTest() ? TL_Ring_Tests.cred : getCredential(credName);
        HttpRequest req  = new HttpRequest();
        String basicAuth = System.EncodingUtil.base64Encode(Blob.valueOf(cred.ClientId__c+':'+cred.ClientSecret__c));
        req.setEndpoint(cred.URL__c+'/oauth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Basic '+basicAuth);
        req.setBody('grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion='+cred.JWT__c);
        HttpResponse res = sendRequest(req);
        Map<String, Object> resObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        cred.token__c = (string)resObj.get('access_token');
        System.debug(cred.token__c);
        if(cred.token__c == null && Test.isRunningTest()) {
            cred.token__c = 'testToken';
        } else if(cred.token__c == null) {
            throw new RingException('No RingCentral token found');
        }
        return cred;
    }
    
    public static RingCredential__mdt getCredential(String credName){
        String query = 'SELECT Id, ClientId__c, ClientSecret__c, JWT__c, version__c, URL__c FROM RingCredential__mdt';
        if(credName != null) query += ' WHERE DeveloperName = \''+credName+'\'';
        RingCredential__mdt[] creds = (RingCredential__mdt []) Database.query(query); 
        System.debug(creds);
        if(creds.size() == 0) throw new RingException('No RingCentral credentials found');
        return creds[0];
    }
    
    public static HttpResponse sendRequest(HttpRequest req){
        Http http = new Http();
        HttpResponse res;
        res = http.send(req);
        return res;
    }
    
    public class RingException extends Exception {}
}