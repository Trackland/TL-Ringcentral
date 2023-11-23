global with sharing class TL_SchedulerSMSControls {
    static String JobName = 'Schedulable SMS Jobs';

    global static void init(Double Interval){
        try {
            TL_Schedulable_SMS scheduler = new TL_Schedulable_SMS();
            String stringScheduleCronJob = getScheduleString(Integer.valueOf(Interval));
            System.schedule('Schedulable SMS Jobs', stringScheduleCronJob, scheduler);
        } catch (Exception e) {
            System.debug('Error in init: ' + e.getMessage());
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
}

