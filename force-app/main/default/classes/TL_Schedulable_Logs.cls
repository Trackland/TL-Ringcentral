global class TL_Schedulable_Logs implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    public static String JobName = 'Get RingCentral Logs';
       
    global void execute(SchedulableContext SC) {
        Date dateFrom = Date.today();
        Date dateTo = Date.today().addDays(1);

        try {
            TL_RingCentral_Logs.retrieveAllLogsAndInsert('Production', dateFrom, dateTo, 1);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    global static void init(Double Interval){
        TL_Schedulable_Logs scheduledProcess = new TL_Schedulable_Logs();
        System.schedule(JobName, CRON_EXP, scheduledProcess);
    }      
}