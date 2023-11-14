public with sharing class TL_CalloutHandler {
    public static void performBringLogsCallout(String credName, Date dateFrom, Date dateTo) {
        TL_RingCentral_Logs.retrieveAllLogsAndInsert(credName, dateFrom, dateTo, 1);
    }
}