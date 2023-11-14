global class TL_Schedulable_Logs implements Schedulable {
    public static String CRON_EXP = '0 0 * * * ?';
    public static String CRED_NAME = '';

    public static void setCredentialName(String credName) {
        CRED_NAME = credName;
    }
       
    global void execute(SchedulableContext SC) {
        Date dateFrom = Date.today();
        Date dateTo = Date.today().addDays(-1);

        TL_CalloutHandler.performBringLogsCallout(CRED_NAME, dateFrom, dateTo);
    }
}