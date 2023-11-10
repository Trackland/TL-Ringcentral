public with sharing class TL_RingCentral_SMS {

    public static void send(String fromPhone, String toPhone, String message, String credName){
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String result = TL_RingCentral_Request.send(endpoint, body, credName, method);
        // return result;
    }

    public static void send(String fromPhone, String toPhone, String message){
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String credName = null;
        String result = TL_RingCentral_Request.send(endpoint, body, credName, method);
        // return result;
    }

}