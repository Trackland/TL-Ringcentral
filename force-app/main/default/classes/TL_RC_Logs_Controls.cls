global class TL_RC_Logs_Controls implements Schedulable {
    public static String JobName = 'Get RingCentral Logs';

    global static void init(Double Interval){
        try {
            TL_RC_Logs_Controls scheduledProcess = new TL_RC_Logs_Controls();
            String stringScheduleCronJob = getScheduleString(Integer.valueOf(Interval));
            System.schedule(JobName, stringScheduleCronJob, scheduledProcess);
        } catch (Exception e) {
            System.debug('Error in init get Logs: ' + e.getMessage());
        }
    }    

    private static String getScheduleString(Integer Interval){
        Datetime currentDatetime = Datetime.now().addSeconds(Interval);
        String seconds = String.valueOf(currentDatetime.second());
        String minutes = String.valueOf(currentDatetime.minute());
        String hours = String.valueOf(currentDatetime.hour());
        String month = String.valueOf(currentDatetime.month());
        String year = String.valueOf(currentDatetime.year());
        String dayOfMonth = String.valueOf(currentDatetime.day());
        String dayOfWeek = '?';

        return seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' ' + year;
    } 

    global void execute(SchedulableContext SC) {
        Id jobId = SC.getTriggerId();
        Date dateFrom = Date.today();
        Date dateTo = Date.today().addDays(1);

        try {
            TL_RC_Logs.QueueuGetLogs getLogs = new TL_RC_Logs.QueueuGetLogs('Production', dateFrom, dateTo, 1);
            if (!Test.isRunningTest()) System.enqueueJob(getLogs);
            System.abortJob(jobId);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.abortJob(jobId);
        }

        Integer IntervalInSeconds = 3600;
        TL_RC_Logs_Controls.init(IntervalInSeconds);
    }
}