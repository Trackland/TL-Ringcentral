@IsTest
public with sharing class TL_Ring_Tests {

  @IsTest
  static void sendrequestTest(){
    TL_Ring_SendRequest.sendSMS('23423', '23432', 'messageTest');
  }

  @IsTest
  static void getCallLogs() {
    TL_Ring_SendRequest.retrieveAllLogsAndInsert();
  }

}