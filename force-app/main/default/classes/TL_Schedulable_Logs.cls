global class TL_Schedulable_Logs implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
       
    global void execute(SchedulableContext SC) {
        Date dateFrom = Date.today();
        Date dateTo = Date.today().addDays(1);

        try {
            TL_RingCentral_Logs.retrieveAllLogsAndInsert('BullOakProduction', dateFrom, dateTo, 1);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}