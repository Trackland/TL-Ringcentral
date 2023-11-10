public with sharing class TL_RingCentral_SMS {
  
    @InvocableMethod(label='Send Text Message' description='Send Text Message')
    public static void send(variables[] vars){
        for(variables var : vars){
            send(var.fromPhone, var.toPhone, var.message, var.credName);
        }
    }

    public static void send(String fromPhone, String toPhone, String message, String credName){
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String result = TL_RingCentral_Request.send(endpoint, body, credName, method);
    }

    public class variables{
        @InvocableVariable(label='FromPhone' description='From Phone Number' required=true)
        public String fromPhone;
        @InvocableVariable(label='ToPhone' description='To Phone Number' required=true)
        public String toPhone;        
        @InvocableVariable(label='message' description='Message' required=true)
        public String message;
        @InvocableVariable(label='CredName' description='Credential Name of Custome Metadata' required=true)
        public String credName;        
    }

}