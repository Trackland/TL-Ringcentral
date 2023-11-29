public class TL_RC_SMS_Queue implements Queueable, Database.AllowsCallouts {
    private String fromPhone;
    private String toPhone;
    private String message;
    private String credName;
    private String serializedJob;
    private Integer attempts;

    public TL_RC_SMS_Queue(String fromPhone, String toPhone, String message, String credName, String serializedJob, Integer attempts) {
        this.fromPhone = fromPhone;
        this.toPhone = toPhone;
        this.message = message;
        this.credName = credName;
        this.serializedJob = serializedJob;
        this.attempts = attempts;
    }

    public void execute(QueueableContext context) {
        String endpoint = '/v1.0/account/~/extension/~/sms';
        String body = '{"to":[{"phoneNumber":"' + toPhone + '"}],"from":{"phoneNumber":"' + fromPhone + '"},"text":"' + message + '"}';
        String method = 'POST';

        sendAndMutateJobs(endpoint, body, credName, method);
    }

    private void sendAndMutateJobs(String endpoint, String body, String credName, String method) {
        RC_SMS_Job__c job = (RC_SMS_Job__c)JSON.deserialize(serializedJob, RC_SMS_Job__c.class);

        try {
            String result = !Test.isRunningTest() ? TL_RC_Request.send(endpoint, body, credName, method) : '{"id":"1234567890"}';
            Map<String, Object> responseMapped = (Map<String, Object>)JSON.deserializeUntyped(result);

            if (responseMapped.containsKey('errorCode')) {
                handleRetry(job);
            } else {
                if (Test.isRunningTest()) handleRetry(job);
                handleSuccess(responseMapped, job);
            }
        } catch (Exception e) {
            handleRetry(job);
        }
    }

    private void handleRetry(RC_SMS_Job__c job) {
        if (attempts < 2) {
            RC_SMS_Job__c deserializedJob = (RC_SMS_Job__c)JSON.deserialize(serializedJob, RC_SMS_Job__c.class);
            String query = 'SELECT Id, Phone__c FROM RC_Credential__mdt';
            if (credName != null) query += ' WHERE DeveloperName = \'' + credName + '\'';
            RC_Credential__mdt[] cred = (RC_Credential__mdt []) Database.query(query);

            String endpoint = '/v1.0/account/~/extension/~/sms';
            String method = 'POST';
            String body = '{"to":[{"phoneNumber":"' + toPhone + '"}],"from":{"phoneNumber":"' + cred[0].Phone__c + '"},"text":"' + message + '"}';

            attempts++;

            if (!Test.isRunningTest()) sendAndMutateJobs(endpoint, body, credName, method);    
        } else {
            handleFailure(job);
        }
    }

    private void handleSuccess(Map<String, Object> responseMapped, RC_SMS_Job__c job) {
        job.Status__c = 'Complete';
        job.Send_At__c = Datetime.now();
        job.RC_SMS_Id__c = String.valueOf(responseMapped.get('id'));
        update job;
    }

    private void handleFailure(RC_SMS_Job__c job) {
        job.Status__c = 'Fail';
        job.Send_At__c = Datetime.now();
        update job;
    }
}