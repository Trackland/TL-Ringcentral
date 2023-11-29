global class TL_RC_Logs_Controls implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    public static String JobName = 'Get RingCentral Logs';
       
    global void execute(SchedulableContext SC) {
        Date dateFrom = Date.today();
        Date dateTo = Date.today().addDays(1);

        try {
            TL_RC_Logs.getLogs('Production', dateFrom, dateTo, 1);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    global static void init(Double Interval){
        TL_RC_Logs_Controls scheduledProcess = new TL_RC_Logs_Controls();
        System.schedule(JobName, CRON_EXP, scheduledProcess);
    }      
}