public with sharing class TL_RingCentral_SMS {

    private static Integer attempts = 0;
  
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
    
    public static void jobProcessing(String credName) {
        Integer batchSize = 40;
        List<List<SMS_Job__c>> jobBatches = new List<List<SMS_Job__c>>();
        List<SMS_Job__c> rawJobs = [SELECT Id, AppointmentDate__c, FromAccount__c, FromPhone__c, Message__c, SMS_Sequence_Template__c, Send_At__c, Status__c, ToContact__c, ToPhone__c FROM SMS_Job__c WHERE Status__c = 'Waiting' AND Send_At__c < :DateTime.now() ORDER BY Send_At__c ASC];

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
                            String formattedPhoneNumber = '+1' + job.FromPhone__c.replaceAll('\\D', '');

                            TL_SMSQueable queueableJob = new TL_SMSQueable(formattedPhoneNumber, job.ToPhone__c, modifiedMessage, credName, JSON.serialize(job), attempts);
                            System.enqueueJob(queueableJob);
                    
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
            String replacement = job.get(variableName) == null ? 'Empty' : String.valueOf(job.get(variableName));
            String dataType = [SELECT DataType FROM FieldDefinition WHERE EntityDefinitionId=:'SMS_Job__c' AND QualifiedApiName=:variableName LIMIT 1].DataType;

            if (dataType == 'Date/Time') {
                Datetime keyInfo = (Datetime) job.get(variableName);
                String timeNotation = (keyInfo.hourGmt() > 12 ? 'PM' : 'AM');
                Integer twelveHourFormat = keyInfo.hourGmt() > 12 ? keyInfo.hourGmt() - 12 : keyInfo.hourGmt();
                String formatted = String.valueOf(keyInfo.month()).leftPad(2, '0') + '/' + String.valueOf(keyInfo.day()).leftPad(2, '0') + '/' + keyInfo.year() + ' ' + String.valueOf(twelveHourFormat).leftPad(2, '0') + ':' + String.valueOf(keyInfo.minute()).leftPad(2, '0') + ' ' + timeNotation;
               
                replacement = formatted;
            }

            if (variableName == 'FromPhone__c') {
                String phoneNumber = (String) job.get(variableName);
                String phoneNumberDigits = phoneNumber.replaceAll('\\D', '');
                replacement = '+1' + phoneNumberDigits;
            }
    
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