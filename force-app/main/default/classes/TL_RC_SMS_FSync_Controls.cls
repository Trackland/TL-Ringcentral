global class TL_RC_SMS_FSync_Controls implements Schedulable {
    static String JobName = 'Schedulable SMS Logs FSync';
    static String syncType = 'FSync';
    static String CRON_EXP = '0 0 3 * * ?';

    global void execute(SchedulableContext ctx) {    
        Date dateFrom = Date.today().addDays(-60);
        Date dateTo = Date.today().addDays(1);

        try {
            TL_RC_SMS_Sync.GetMessageStoreRecords messageStoreRecords = new TL_RC_SMS_Sync.GetMessageStoreRecords('Production', syncType, dateFrom, dateTo);
            if (!Test.isRunningTest()) System.enqueueJob(messageStoreRecords);
        } catch(Exception e) {
            System.debug('Scheduler failed: '+ e.getMessage());
        }
    }

    global static void init() {
        try {
            TL_RC_SMS_FSync_Controls scheduler = new TL_RC_SMS_FSync_Controls();
            System.schedule(JobName, CRON_EXP, scheduler);
        } catch (Exception e) {
            System.debug('Error in init FSync: ' + e.getMessage());
        }
    }
}