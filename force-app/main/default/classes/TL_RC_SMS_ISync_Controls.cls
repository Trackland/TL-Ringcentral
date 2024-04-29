global class TL_RC_SMS_ISync_Controls implements Schedulable {
  static String JobName = 'Schedulable SMS Logs ISync';
  static String syncType = 'ISync';

  global static void init(Double Interval) {
    try {
      TL_RC_SMS_ISync_Controls scheduler = new TL_RC_SMS_ISync_Controls();
      String stringScheduleCronJob = getScheduleString(Integer.valueOf(Interval));
      System.schedule(JobName, stringScheduleCronJob, scheduler);
    } catch (Exception e) {
      System.debug('Error in init ISync: ' + e.getMessage());
    }
  }

  private static String getScheduleString(Integer Interval) {
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

  global void execute(SchedulableContext ctx) {
    Id jobId = ctx.getTriggerId();
    Date dateFrom = Date.today();
    Date dateTo = Date.today().addDays(1);
    String result;

    try {
      TL_RC_SMS_Sync.GetMessageStoreRecords messageStoreRecords = new TL_RC_SMS_Sync.GetMessageStoreRecords('Production', syncType, dateFrom, dateTo);
      if (!Test.isRunningTest())
        System.enqueueJob(messageStoreRecords);
      System.abortJob(jobId);
    } catch (Exception e) {
      System.debug('Scheduler failed: ' + e.getMessage());
      System.abortJob(jobId);
    }

    Integer IntervalInSeconds = 300;
    TL_RC_SMS_ISync_Controls.init(IntervalInSeconds);
  }
}
