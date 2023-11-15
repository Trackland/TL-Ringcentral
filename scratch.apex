Date dateFrom = Date.today();
Date dateTo = Date.today().addDays(1);

try {
    TL_RingCentral_Logs.retrieveAllLogsAndInsert('Production', dateFrom, dateTo, 1);
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}