global with sharing class TL_RC_SMS_Controls implements Schedulable {
  static String JobName = 'Schedulable SMS Jobs';

  global static void init(Double Interval) {
    try {
      TL_RC_SMS_Controls scheduler = new TL_RC_SMS_Controls();
      String stringScheduleCronJob = getScheduleString(Integer.valueOf(Interval));
      System.schedule('Schedulable SMS Jobs', stringScheduleCronJob, scheduler);
    } catch (Exception e) {
      System.debug('Error in init: ' + e.getMessage());
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
    String result;

    try {
      TL_RC_SMS.jobProcessing('Production');
      System.abortJob(jobId);
    } catch (Exception e) {
      System.debug('Scheduler failed: ' + e.getMessage());
      System.abortJob(jobId);
    }

    Integer IntervalInSeconds = 120;
    TL_RC_SMS_Controls.init(IntervalInSeconds);
  }
}
