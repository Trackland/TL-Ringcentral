public with sharing class TL_RC_Logs {

  private static Integer PerPage = 1000;

  public class QueueuGetLogs implements Queueable {
    private String CredName;
    private Date DateFrom;
    private Date DateTo;
    private Integer PageNumber;

    public QueueuGetLogs(String credName, Date dateFrom, Date dateTo, Integer pageNumber){
      this.CredName = credName;
      this.DateFrom = DateFrom;
      this.DateTo = dateTo;
      this.PageNumber = pageNumber;
    }
    
    public void execute(QueueableContext context) {
      getLogs(this.CredName, this.DateFrom, this.DateTo, this.PageNumber);
    }
  } 

  public static void getLogs(String credName, Date dFrom, Date dTo, Integer pgNbr){
    List<RC_Call_Log__c> callLogsToInsert = new List<RC_Call_Log__c>();
    Integer firstCallout = 0;
    Integer page = pgNbr;
    Boolean completionFlag = false;
    Integer batchSize = 150;
    List<Object> AllRecords = new List<Object>();
    Map<String, RC_Call_Log__c> ExistingLogsByIdMap = new Map<String, RC_Call_Log__c>();
    List<RC_Call_Log__c> LogsToInsert = new List<RC_Call_Log__c>();
    List<RC_Call_Log__c> LogsToUpdate = new List<RC_Call_Log__c>();
    List<RC_Call_Log__c> AllLogs = new List<RC_Call_Log__c>();
    Map<String, RC_Call_Log__c> LogsByNumberMap = new Map<String, RC_Call_Log__c>();
  
    recursiveCallGetLogs(credName, dFrom, dTo, page, AllRecords);
    getExistingLogs(ExistingLogsByIdMap, AllRecords);
    createAllCallLogs(ExistingLogsByIdMap, AllRecords, LogsToInsert, LogsByNumberMap);
    connectLogToContactOrLead(LogsByNumberMap, LogsToUpdate);
    insertLogsByBatches(callLogsToInsert, batchSize, completionFlag);    
    
    if(LogsToInsert.size() > 0) insert LogsToInsert;
    if(LogsToUpdate.size() > 0) update LogsToUpdate;

    QueueuCreateLogHistories queueuCreateLogHistories = new QueueuCreateLogHistories(LogsByNumberMap, AllRecords);
    System.enqueueJob(queueuCreateLogHistories);    
  }

  public static void recursiveCallGetLogs(String credName, Date dFrom, Date dTo, Integer page, List<Object> AllRecords){
    Map<String, Object> response = makeCall(credName, dFrom, dTo, page);
    List<Object> records = (List<Object>) response.get('records');      
    if(records != null && records.size() > 0) AllRecords.addAll(records);
    Map<String, Object> pageingInfo = (Map<String, Object>)response.get('paging');
    if(pageingInfo == null) return;
    Integer pgEnd = (Integer)pageingInfo.get('pageEnd');

    if(pgEnd <= page) {
      return;
    } else if(pgEnd == null) {
      return;      
    } else if(AllRecords.size() >= 10000) {
      return;
    } else {
      page++;
      recursiveCallGetLogs(credName, dFrom, dTo, page, AllRecords);
    }    
  }

  public static Map<String, Object> makeCall(String credName, Date dFrom, Date dTo, Integer page){
    String endpoint = '/v1.0/account/~/call-log';
    String paginated = '&page=' + page + '&perPage=' + PerPage;
    Date dateFrom = dFrom != null ? dFrom : System.today();
    Date dateTo = dTo != null ? dTo : System.today().addDays(1);
    String dateInterval = '?dateFrom=' + isoFormatter(dateFrom) + '&dateTo=' + isoFormatter(dateTo);

    try{
      String responseBody = TL_RC_Request.send(endpoint + dateInterval + paginated, '', credName, 'GET');
      Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
      return result;
    } catch (Exception e) {
      throw new RingCentralException(e.getMessage());
    }
  }

  public static void getExistingLogs(Map<String, RC_Call_Log__c> ExistingLogsByIdMap, List<Object> records){
      Set<String> logIds = new Set<String>();

      for (Object recordObj : records) {
        Map<String, Object> record = (Map<String, Object>) recordObj;
        logIds.add((String) record.get('id'));
      }

      RC_Call_Log__c[] existingRecords = [SELECT Id, Lead__c, Contact__c, Log_Id__c, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c FROM RC_Call_Log__c WHERE Log_Id__c IN :logIds];
      
      for (RC_Call_Log__c existingRecord : existingRecords) {
        ExistingLogsByIdMap.put(existingRecord.Log_Id__c, existingRecord);
      }
  } 

  public static void createAllCallLogs(Map<String, RC_Call_Log__c> ExistingLogsByIdMap, List<Object> records, List<RC_Call_Log__c> LogsToInsert, Map<String, RC_Call_Log__c> LogsByNumberMap){
    List<String> ExistingLogIds = new List<String>(ExistingLogsByIdMap.keySet());

    for (Integer i = 0; i < records.size(); i++) {
      Object recordObj = records[i];
      Map<String, Object> record = (Map<String, Object>) recordObj;
      Map<String, Object> fromItem = (Map<String, Object>) record.get('from');
      Map<String, Object> toItem =  (Map<String, Object>)record.get('to');

      Boolean exists = ExistingLogIds.contains((String) record.get('id'));
      RC_Call_Log__c log;
      if (!exists) {
        log = createCallLog(record, fromItem, toItem);
        LogsToInsert.add(log);
      } else {
        log = ExistingLogsByIdMap.get((String) record.get('id'));
      }

      String rawNbr = log.Direction__c == 'Inbound' ? (String)log.get('From_Phone_Number__c') : (String)log.get('To_Phone_Number__c');
      if(rawNbr == null) {
        System.debug(log);
        continue;
      }
      String n = cleanNumber(rawNbr, true);        
      LogsByNumberMap.put(n, log);
    }
  }

  public static RC_Call_Log__c createCallLog(Map<String, Object> record, Map<String, Object> fromItem, Map<String, Object> toItem){
    RC_Call_Log__c callLog = new RC_Call_Log__c(
      Log_Id__c = (String) record.get('id'),
      Session_Id__c = (String) record.get('sessionId'),
      Record_Url__c = (String) record.get('uri'),
      Action__c = (String) record.get('action'),
      Direction__c = (String) record.get('direction'),
      Duration__c = (Integer) record.get('duration'),
      From_Location__c = (String) fromItem.get('location'),
      From_Name__c = (String) fromItem.get('name'),
      From_Phone_Number__c = (String) fromItem.get('phoneNumber'),
      Result__c = (String) record.get('result'),
      To_Name__c = (String) toItem.get('name'),
      To_Phone_Number__c = (String) toItem.get('phoneNumber'),
      Type__c = (String) record.get('type'),
      Start_Time__c = (Datetime) JSON.deserialize('"' + (String) record.get('startTime') + '"', Datetime.class)
    );

    return callLog;
  }

  public static void insertLogsByBatches(List<RC_Call_Log__c> callLogsToInsert, Integer batchSize, Boolean completionFlag) {
    // if (!callLogsToInsert.isEmpty()) {
    //   List<List<RC_Call_Log__c>> callLogBatches = new List<List<RC_Call_Log__c>>();

    //   for (Integer i = 0; i < callLogsToInsert.size(); i += batchSize) {
    //     Integer endIndex = Math.min(i + batchSize, callLogsToInsert.size());
    //     List<RC_Call_Log__c> batch = new List<RC_Call_Log__c>();
        
    //     for (Integer j = i; j < endIndex; j++) {
    //         batch.add(callLogsToInsert[j]);
    //     }
        
    //     callLogBatches.add(batch);
    //   }

    //   for (List<RC_Call_Log__c> batch : callLogBatches) {
    //     try {
    //         if (!Test.isRunningTest()) insert batch;
    //     } catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }
    //   }
    // }   
  }  

  public static String isoFormatter(Date dateObject) {
    return dateObject.year() + '-' + String.valueOf(dateObject.month()).leftPad(2, '0') + '-' + String.valueOf(dateObject.day()).leftPad(2, '0'); 
  }  

  public static void connectLogToContactOrLead(Map<String, RC_Call_Log__c> LogsByNumberMap, List<RC_Call_Log__c> LogsToUpdate){
    Map<String, String> idMapByPhone = new Map<String, String>();
    Set<String> numberSet = LogsByNumberMap.keySet();
    List<String> numbers = new List<String>(numberSet);
    List<List<String>> chunks = new List<List<String>>();
    List<String> chunk = new List<String>();
    Integer chunkSize = 299;
    Integer l = 0;
    for(Integer i = 0; i < numbers.size(); i++){
      if(l == 0){
        chunk = new List<String>();
        chunks.add(chunk);
      }
      if(l == chunkSize) {
        l = 0;
      } else {
        l++;
      }
      chunk.add(numbers[i]);
    }
    
    for(List<String> chnk : chunks){
      String search = !Test.isRunningTest() ? String.join(chnk, ' OR ') : '3214567788';  
      if(search.length() < 5) {
        System.debug('No numbers were found to search for contacts.');
        continue;
      }
      List<List<SObject>> groups = [FIND :search IN PHONE FIELDS RETURNING Contact(Id,Phone,MobilePhone), Lead(Id,Phone,MobilePhone), Account(Id, Phone)];
    
      for(List<SObject> items : groups){
        for(SObject item : items){
          Map<String, Object> values = item.getPopulatedFieldsAsMap();
          String Id = null;
          for(String fieldName: values.keySet()) {
            if(fieldName == 'Id') Id = (String)values.get(fieldName);
            else idMapByPhone.put(cleanNumber((String)values.get(fieldName), false), Id);
          }
        }
      }    
    }

    for(String nbr : LogsByNumberMap.keySet()){
      Id Id = (Id)idMapByPhone.get(nbr);
      if(Id == null) continue;

      RC_Call_Log__c log = LogsByNumberMap.get(nbr);
      if(log == null) continue;
      
      if(Id.getSObjectType() == Contact.SObjectType && (log.Contact__c == null || log.Contact__c != Id)) {
        log.Contact__c = Id;
        if(log.Id != null) LogsToUpdate.add(log);
      } else if (Id.getSObjectType() == Lead.SObjectType && (log.Lead__c != null || log.Lead__c != Id)) {
        log.Lead__c = Id;
        if(log.Id != null) LogsToUpdate.add(log);
      }
    }      
  } 
  
  public static string cleanNumber(String rawNbr, Boolean removeOne){
    String cleanNbr = rawNbr.replaceAll('\\D','');
    return removeOne == true ? cleanNbr.mid(1, 10) : cleanNbr;
  }

  public class variables{
    @InvocableVariable(label='type' description='Type' required=true)
    public String type;
    @InvocableVariable(label='CredName' description='Credential Name of Custome Metadata' required=true)
    public String credName;        
    @InvocableVariable(label='MockResponse' description='Response body' required=true)
    public String MockResponse;       
  }
  
  public class QueueuCreateLogHistories implements Queueable {
    Map<String, RC_Call_Log__c> LogsByNumberMap;
    List<Object> AllLogs;

    public QueueuCreateLogHistories(Map<String, RC_Call_Log__c> logsByNumberMap, List<Object> allLogs){
      this.LogsByNumberMap = logsByNumberMap;
      this.AllLogs = allLogs;
    }
    
    public void execute(QueueableContext context) {
      createLogHistories(this.LogsByNumberMap, this.AllLogs);
    }
  } 

  public static void createLogHistories(Map<String, RC_Call_Log__c> logsByNumberMap, List<Object> allLogs){
    List<RC_Number_History__c> toInsert = new List<RC_Number_History__c>();
    List<RC_Number_History__c> toUpdate = new List<RC_Number_History__c>();
    List<Id> toUpdateIds = new List<Id>();
    List<RC_Number_History__c> AllHistories = new List<RC_Number_History__c>();
    Map<String, RC_Number_History__c> historiesByNumberMap = new Map<String, RC_Number_History__c>();
    List<String> logIds = new List<String>();
    List<RC_Call_Log__c> AllRCLogs = new List<RC_Call_Log__c>();
    List<String> AllRCLogNumbers = new List<String>();
    
    for(Object log : allLogs){
      Map<String, Object> record = (Map<String, Object>) log;
      logIds.add((String) record.get('id'));
    }
    RC_Call_Log__c[] logsFromThePrevProcess = [SELECT Id, Lead__c, Contact__c, Log_Id__c, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c FROM RC_Call_Log__c WHERE Log_Id__c IN :logIds];    
    for(RC_Call_Log__c log : logsFromThePrevProcess){
      if(log.From_Phone_Number__c == null) continue;
      AllRCLogNumbers.add(log.From_Phone_Number__c);
    }
    RC_Call_Log__c[] allLogsByNumber = [SELECT Id, Lead__c, Contact__c, Log_Id__c, Session_Id__c, Record_Url__c, Action__c, Direction__c, Duration__c, From_Location__c, From_Name__c, From_Phone_Number__c, Result__c, To_Name__c, To_Phone_Number__c, Type__c FROM RC_Call_Log__c WHERE From_Phone_Number__c IN :AllRCLogNumbers];    
    List<String> numbers = new List<String>();
    for(RC_Call_Log__c log : allLogsByNumber){
      String nbr = log.Direction__c == 'Inbound' ? (String)log.get('From_Phone_Number__c') : (String)log.get('To_Phone_Number__c');
      if(nbr == null) continue;
      numbers.add(nbr);
    }
    
    List<RC_Number_History__c> existingHistories = [SELECT Id, Lead__c, Call_Count__c, Contact__c, Earliest_Call__c, Phone__c, Recent_Call__c, Out_Bound_Count__c, In_Bound_Count__c FROM RC_Number_History__c WHERE Phone__c IN :numbers];
    Map<String, RC_Number_History__c> existingHistoriesByNumberMap = new Map<String, RC_Number_History__c>();
    for(RC_Number_History__c history : existingHistories){
      history.Call_Count__c = 0;
      history.Out_Bound_Count__c = 0;
      history.In_Bound_Count__c = 0;
      existingHistoriesByNumberMap.put(cleanNumber(history.Phone__c, false), history);
    }

    for(RC_Call_Log__c log : allLogsByNumber){

      String nbr = log.Direction__c == 'Inbound' ? (String)log.get('From_Phone_Number__c') : (String)log.get('To_Phone_Number__c');
      if(nbr == null) continue;
      RC_Number_History__c history = historiesByNumberMap.get(nbr);
      RC_Number_History__c existing = existingHistoriesByNumberMap.get(cleanNumber(nbr, false));
      if(existing != null) history = existing;
      
      if(history == null) {
        history = new RC_Number_History__c(
          Phone__c = nbr,
          Call_Count__c =  1,
          Out_Bound_Count__c = log.Direction__c == 'Outbound' ? 1 : +0,
          In_Bound_Count__c = log.Direction__c == 'Inbound' ? 1 : +0,
          Earliest_Call__c = log.Id,
          Recent_Call__c = log.Id        );
          System.debug(history);
        toInsert.add(history);
      } else if(history.Id == null){
        history.Call_Count__c++;
        history.Out_Bound_Count__c = log.Direction__c == 'Outbound' ? history.Out_Bound_Count__c+1 : history.Out_Bound_Count__c;
        history.In_Bound_Count__c = log.Direction__c == 'Inbound' ? history.In_Bound_Count__c+1 : history.In_Bound_Count__c;      
        if(history.Earliest_Call__c == null) history.Earliest_Call__c = log.Id;
        history.Recent_Call__c = log.Id;
      } else {
        history.Call_Count__c++;
        history.Out_Bound_Count__c = log.Direction__c == 'Outbound' ? history.Out_Bound_Count__c+1 : history.Out_Bound_Count__c;
        history.In_Bound_Count__c = log.Direction__c == 'Inbound' ? history.In_Bound_Count__c+1 : history.In_Bound_Count__c;
        if(history.Earliest_Call__c == null) history.Earliest_Call__c = log.Id;
        history.Recent_Call__c = log.Id;
        if(!toUpdateIds.contains(history.Id)){
          toUpdateIds.add(history.Id);
          toUpdate.add(history);  
        }
      }
      
      historiesByNumberMap.put(nbr, history);

      if(log.Contact__c != null && (history.Contact__c == null || history.Contact__c != log.Contact__c)) history.Contact__c = log.Contact__c;
      if(log.Lead__c != null && (history.Lead__c == null || history.Lead__c != log.Lead__c)) history.Lead__c = log.Lead__c;
    }
    
    AllHistories.addAll(toInsert);
    AllHistories.addAll(toUpdate);
    addServiceAppointments(AllHistories);

    System.debug('To Insert: '+toInsert.size());
    if(toInsert.size() > 0) insert toInsert;

    System.debug('To Update: '+toUpdate.size());
    if(toUpdate.size() > 0) update toUpdate;
  }

  public static void addServiceAppointments(List<RC_Number_History__c> AllHistories){
    Set<Id> contactIds = new Set<Id>();
    Set<Id> leadIds = new Set<Id>();
    for(RC_Number_History__c history : AllHistories){
      if(history.Contact__c != null) contactIds.add(history.Contact__c);
      if(history.Lead__c != null) leadIds.add(history.Lead__c);
    }

    ServiceAppointment[] appts = [SELECT Id, ContactId FROM ServiceAppointment WHERE ContactId IN :contactIds Order By Status];

    Map<Id, ServiceAppointment> apptsByContactIdMap = new Map<Id, ServiceAppointment>();
    for(ServiceAppointment appt : appts){
      if(apptsByContactIdMap.containsKey(appt.ContactId)) continue;
      apptsByContactIdMap.put(appt.ContactId, appt);
    }

    for(RC_Number_History__c history : AllHistories){
      if(history.Contact__c == null) continue;
      ServiceAppointment appt = apptsByContactIdMap.get(history.Contact__c);
      if(appt == null) continue;
      history.Service_Appointment__c = appt.Id;
    }
  }

  public class RingCentralException extends Exception{}  
}