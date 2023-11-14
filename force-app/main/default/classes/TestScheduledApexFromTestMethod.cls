global class TestScheduledApexFromTestMethod implements Schedulable { 
       public static String CRON_EXP = '0 0 3 * * ?';
       
       global void execute(SchedulableContext ctx) {
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :ctx.getTriggerId()];

        Datetime currentDateTime = Datetime.now();
        if (currentDateTime.hour() >= 3) {
            currentDateTime = currentDateTime.addDays(1);
        }

        Datetime scheduledDateTime = Datetime.newInstance(
            currentDateTime.year(),
            currentDateTime.month(),
            currentDateTime.day(),
            3,
            0,
            0
        );

        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(
            scheduledDateTime.format('yyyy-MM-dd HH:mm:ss'),
            String.valueOf(ct.NextFireTime)
        );
    }
}