global with sharing class TL_Schedulable_SMS implements Schedulable {
    global void execute(SchedulableContext ctx) {    
        Id jobId = ctx.getTriggerId();
        String result;

        try {
            TL_RingCentral_SMS.insertNewSequence();
            System.abortJob(jobId);
          }
          catch(Exception e) {
            System.debug('Scheduler failed: '+ e.getMessage());
            System.abortJob(jobId);
        }
        
        Integer IntervalInSeconds = 10;
        TL_SchedulerSMSControls.init(IntervalInSeconds);
    }
}