public with sharing class TL_RingCentral_SMS {
  
    @InvocableMethod(label='Send Text Message' description='Send Text Message')
    public static void send(variables[] vars){
        for(variables var : vars){
            System.debug('fromPhone: ' + var.fromPhone);
            System.debug('toPhone: ' + var.toPhone);
            send(var.fromPhone, var.toPhone, var.message, var.credName);
        }
    }

    @future(callout=true)
    public static void send(String fromPhone, String toPhone, String message, String credName){
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String result = TL_RingCentral_Request.send(endpoint, body, credName, method);
    }

    @future(callout=true)
    public static void sendAndMutateJobs(String fromPhone, String toPhone, String message, String credName, String serializedJob){
        SMS_Job__c job = (SMS_Job__c)JSON.deserialize(serializedJob, SMS_Job__c.class);
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String result = !Test.isRunningTest() ? TL_RingCentral_Request.send(endpoint, body, credName, method) : '{"id":"1234567890"}' ;
        Map<String, Object> responseMapped = (Map<String, Object>)JSON.deserializeUntyped(result);

        if (responseMapped.containsKey('errorCode')) {
            job.Status__c = 'Fail';   
            job.Send_At__c = Datetime.now();        
            update job;
        } else {
            job.Status__c = 'Complete';
            job.Send_At__c = Datetime.now();       
            job.RC_SMS_Id__c = String.valueOf(responseMapped.get('id'));
            update job;
        }

    }
    
    public static void jobProcessing(String credName) {
        Integer batchSize = 40;
        List<List<SMS_Job__c>> jobBatches = new List<List<SMS_Job__c>>();
        List<SMS_Job__c> rawJobs = [SELECT Id, FromAccount__c, FromPhone__c, Message__c, SMS_Sequence_Template__c, Send_At__c, Status__c, ToContact__c, ToPhone__c FROM SMS_Job__c WHERE Status__c = 'Waiting' AND Send_At__c < :DateTime.now() ORDER BY Send_At__c ASC];

        for (Integer i = 0; i < rawJobs.size(); i += batchSize) {
            Integer endIndex = Math.min(i + batchSize, rawJobs.size());
            List<SMS_Job__c> batch = new List<SMS_Job__c>();
            
            for (Integer j = i; j < endIndex; j++) {
                batch.add(rawJobs[j]);
            }
            
            jobBatches.add(batch);
        }

        for (List<SMS_Job__c> batch : jobBatches) {
            try {
                    Double rateLimit = 40;
                    Double ratePerUnitOfTime = 60;
                    Double transactionInterval = ratePerUnitOfTime / rateLimit;
                    List<SMS_Job__c> jobsToUpdate = new List<SMS_Job__c>();

                    for (SMS_Job__c job : batch) {
                        try {
                            Integer sleepTimeMillis = (Integer) (transactionInterval * 1000.0);
                            Datetime now = Datetime.now();
                            Datetime resumeTime = now.addSeconds(sleepTimeMillis / 1000);
                            String modifiedMessage = replaceVariables(job.Message__c, job);
                            
                            TL_RingCentral_SMS.sendAndMutateJobs(job.FromPhone__c, job.ToPhone__c, modifiedMessage, credName, JSON.serialize(job));
                    
                            while (Datetime.now() < resumeTime) {}
                        } catch (Exception e) {
                            System.debug(e.getMessage());
                        }
                    }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
    }

    private static String replaceVariables(String message, SMS_Job__c job) {
        Pattern pattern = Pattern.compile('\\{\\{(\\w+__c)\\}\\}');
        Matcher matcher = pattern.matcher(message);
        String result = message;
    
        while (matcher.find()) {
            String variableName = matcher.group(1);
            String replacement = String.valueOf(job.get(variableName));
    
            result = result.replace(matcher.group(), replacement);
        }
    
        return result;
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