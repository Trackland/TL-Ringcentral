public with sharing class TL_RC_SMS {

    private static Integer attempts = 0;
  
    @future(callout=true)
    public static void send(String fromPhone, String toPhone, String message, String credName){
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"'+toPhone+'"}],"from":{"phoneNumber":"'+fromPhone+'"},"text":"'+message+'"}';
        String method = 'POST';
        String result = TL_RC_Request.send(endpoint, body, credName, method);
    }
    
    public static void jobProcessing(String credName) {
        List<RC_SMS_Job__c> rawJobs = [SELECT Id, AppointmentDate__c, TimeZone__c, ClinicAddress__c, FromAccount__c, FromPhone__c, Message__c, SMS_Sequence_Template__c, Send_At__c, Status__c, ToContact__c, ToPhone__c FROM RC_SMS_Job__c WHERE Status__c = 'Waiting' AND Send_At__c < :DateTime.now() ORDER BY Send_At__c ASC LIMIT 20];

        try {
                Double rateLimit = 40;
                Double ratePerUnitOfTime = 60;
                Double transactionInterval = ratePerUnitOfTime / rateLimit;

                for (RC_SMS_Job__c job : rawJobs) {
                    try {
                        Integer sleepTimeMillis = (Integer) (transactionInterval * 1000.0);
                        Datetime now = Datetime.now();
                        Datetime resumeTime = now.addSeconds(sleepTimeMillis / 1000);
                        String modifiedMessage = replaceVariables(job.Message__c, job);
                        String formattedPhoneNumber = '+1' + job.FromPhone__c.replaceAll('\\D', '');

                        if (!Test.isRunningTest()) {
                            TL_RC_SMS_Queue queueableJob = new TL_RC_SMS_Queue(formattedPhoneNumber, job.ToPhone__c, modifiedMessage, credName, JSON.serialize(job), attempts);
                            System.enqueueJob(queueableJob);
                        }          
                
                        while (Datetime.now() < resumeTime) {}
                    } catch (Exception e) {
                        System.debug(e.getMessage());
                    }
                    }
        } catch (Exception e) {
                System.debug(e.getMessage());
        }
    }

    private static String replaceVariables(String message, RC_SMS_Job__c job) {
        Pattern pattern = Pattern.compile('\\{\\{(\\w+__c)\\}\\}');
        Matcher matcher = pattern.matcher(message);
        String result = message;

        while (matcher.find()) {
            String variableName = matcher.group(1);
            String replacement = job.get(variableName) == null ? 'Empty' : String.valueOf(job.get(variableName));
            String dataType = [SELECT DataType FROM FieldDefinition WHERE EntityDefinitionId=:'RC_SMS_Job__c' AND QualifiedApiName=:variableName LIMIT 1].DataType;

            if (dataType == 'Date/Time') {
                Datetime keyInfo = (Datetime) job.get(variableName);
                String timeZoneStr = job.TimeZone__c != null ? job.TimeZone__c : 'GMT';
                TimeZone tz = TimeZone.getTimeZone(timeZoneStr);
                Integer offsetMillis = tz.getOffset(keyInfo);

                keyInfo = keyInfo.addSeconds(offsetMillis / 1000);
        
                Integer hour = keyInfo.hourGmt();
                String timeNotation = (hour > 12 ? 'PM' : 'AM');
                Integer twelveHourFormat = hour > 12 ? hour - 12 : hour;
                String formatted = String.valueOf(keyInfo.month()).leftPad(2, '0') + '/'
                                 + String.valueOf(keyInfo.day()).leftPad(2, '0') + '/'
                                 + keyInfo.year() + ' '
                                 + String.valueOf(twelveHourFormat).leftPad(2, '0') + ':'
                                 + String.valueOf(keyInfo.minute()).leftPad(2, '0') + ' ' + timeNotation;
                
                replacement = formatted;
            }

            if (variableName == 'FromPhone__c' || variableName == 'ToPhone__c') {
                String phoneNumber = (String) job.get(variableName);
                String phoneNumberDigits = phoneNumber.replaceAll('\\D', '');
                replacement = '+1' + phoneNumberDigits;
            }
    
            result = result.replace(matcher.group(), replacement);
        }
    
        return result;
    }
}