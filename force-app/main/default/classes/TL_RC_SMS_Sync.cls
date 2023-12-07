public with sharing class TL_RC_SMS_Sync {

    public class GetMessageStoreRecords implements Queueable, Database.AllowsCallouts {
        private String CredName;
        private String SyncType;
        private Date DateFrom;
        private Date DateTo;

        public GetMessageStoreRecords(String credName, String syncType, Date dateFrom, Date dateTo){
            this.CredName = credName;
            this.DateFrom = DateFrom;
            this.DateTo = dateTo;
            this.SyncType = syncType;
        }

        public void execute(QueueableContext context) {
            getSMSRecords(this.CredName, this.SyncType, this.DateFrom, this.DateTo);
        }
    }

    public static void getSMSRecords(String credName, String syncType, Date dFrom, Date dTo) {
        Integer batchSize = 150;
        List<Object> AllRecords = new List<Object>();
        List<RC_SMS_Record__c> smsRecords = new List<RC_SMS_Record__c>();
        List<RC_SMS_Record__c> smsRecordsToInsert = new List<RC_SMS_Record__c>();
        List<RC_SMS_Record__c> smsRecordsToUpdate = new List<RC_SMS_Record__c>();
        Map<String, RC_SMS_Record__c> ExistingRecordsByIdMap = new Map<String, RC_SMS_Record__c>();
        Map<String, List<RC_SMS_Record__c>> recordsByNumberMap = new Map<String, List<RC_SMS_Record__c>>();

        getRecordsFromServer(credName, dFrom, dTo, syncType, AllRecords);
        getExistingSMS(ExistingRecordsByIdMap, AllRecords);
        createAllRecords(ExistingRecordsByIdMap, AllRecords, smsRecordsToInsert, recordsByNumberMap);
        connectRecordsToContact(recordsByNumberMap, smsRecordsToUpdate);

        if (smsRecordsToInsert.size() > 0) processRecords(smsRecordsToInsert, batchSize, 'insert');
        if (smsRecordsToUpdate.size() > 0) processRecords(smsRecordsToUpdate, batchSize, 'update');
    }

    public static void processRecords(List<RC_SMS_Record__c> records, Integer batchSize, String operation) {
        if (records.size() > 0) {
            List<List<RC_SMS_Record__c>> recordBatches = new List<List<RC_SMS_Record__c>>();

            for (Integer i = 0; i < records.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, records.size());
                List<RC_SMS_Record__c> batch = new List<RC_SMS_Record__c>();

                for (Integer j = i; j < endIndex; j++) {
                    batch.add(records[j]);
                }

                recordBatches.add(batch);
            }

            for (List<RC_SMS_Record__c> batch : recordBatches) {
                if (operation == 'insert') {
                    insert batch;
                } else if (operation == 'update') {
                    update batch;
                }
            }
        }
    }

    public static void getRecordsFromServer(String credName, Date dFrom, Date dTo, String syncType, List<Object> AllRecords){
        if (syncType == 'ISync') {
            List<RC_SMS_Token__c> smsSyncToken = [SELECT Id, Name, Sync_Token__c FROM RC_SMS_Token__c LIMIT 1];
            syncType = 'ISync&syncToken=' + smsSyncToken[0].Sync_Token__c;
        }

        Map<String, Object> response = makeCall(credName, dFrom, dTo, syncType);
        List<Object> records = (List<Object>) response.get('records');      
    
        if (records != null && records.size() > 0) {
            AllRecords.addAll(records);
        }
    }

    public static Map<String, Object> makeCall(String credName, Date dFrom, Date dTo, String syncType){
        String endpoint = '/v1.0/account/~/extension/~/message-sync?syncType=' + syncType;
        Date dateFrom = dFrom != null ? dFrom : System.today();
        Date dateTo = dTo != null ? dTo : System.today().addDays(1);
        String dateInterval = '&dateFrom=' + isoFormatter(dateFrom) + '&dateTo=' + isoFormatter(dateTo);

        if (syncType == 'FSync') {
            endpoint = endpoint + '&messageType=SMS';
        }
    
        try{
          String responseBody = TL_RC_Request.send(endpoint + dateInterval, '', credName, 'GET');
          Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

          List<RC_SMS_Token__c> smsSyncTokens = [SELECT Id, Name, Sync_Token__c FROM RC_SMS_Token__c LIMIT 1];
          Map<String, Object> syncInfo = (Map<String, Object>) result.get('syncInfo');

          if (smsSyncTokens.size() == 0) {
            RC_SMS_Token__c smsSyncToken = new RC_SMS_Token__c(
                Sync_Token__c = (String) syncInfo.get('syncToken')
            );
            insert smsSyncToken;
          } else {
            smsSyncTokens[0].Sync_Token__c = (String) syncInfo.get('syncToken');
            update smsSyncTokens[0];
          }
          
          return result;
        } catch (Exception e) {
          throw new RingCentralException(e.getMessage());
        }
    }

    public static void getExistingSMS(Map<String, RC_SMS_Record__c> ExistingRecordsByIdMap, List<Object> records){
        Set<String> recordIds = new Set<String>();
  
        for (Object recordObj : records) {
          Map<String, Object> record = (Map<String, Object>) recordObj;
          recordIds.add(String.valueOf(record.get('id')));
        }
  
        RC_SMS_Record__c[] existingRecords = [SELECT Id, Contact__c, RC_SMS_Thread__c, SMS_Id__c, Direction__c, Read_Status__c, Record_Url__c, From_Location__c, From_Phone__c, From_Name__c, To_Name__c, To_Phone__c, Subject__c, Creation_Time__c FROM RC_SMS_Record__c WHERE SMS_Id__c IN :recordIds];

        for (RC_SMS_Record__c existingRecord : existingRecords) {
            ExistingRecordsByIdMap.put(existingRecord.SMS_Id__c, existingRecord);
        }
    } 

    public static void createAllRecords(Map<String, RC_SMS_Record__c> ExistingRecordsByIdMap, List<Object> records, List<RC_SMS_Record__c> RecordsToInsert, Map<String, List<RC_SMS_Record__c>> RecordsByNumberMap){
        List<String> conversationIdsAsString = new List<String>();

        for (Object recordObj : records) {            
            if (recordObj instanceof Map<String, Object>) {
                Map<String, Object> record = (Map<String, Object>) recordObj;
                Long conversationIdInt = (Long) record.get('conversationId');
                
                if (conversationIdInt != null) {
                    conversationIdsAsString.add(String.valueOf(conversationIdInt));
                }
            } else {
                System.debug('Unexpected type found: ' + recordObj);
            }
        }

        List<String> ExistingRecordsIds = new List<String>(ExistingRecordsByIdMap.keySet());
        List<RC_SMS_Thread__c> smsThreadsToAdd = new List<RC_SMS_Thread__c>();
        List<RC_SMS_Thread__c> smsThreads = [SELECT Id, Conversation_Id__c FROM RC_SMS_Thread__c WHERE Conversation_Id__c IN :conversationIdsAsString];
        
        for (Integer i = 0; i < records.size(); i++) {
          Object recordObj = records[i];

          Map<String, Object> record = (Map<String, Object>) recordObj;
          Map<String, Object> fromItem = (Map<String, Object>) record.get('from');    
          List<Object> toList= (List<Object>) record.get('to');
          List<Map<String, Object>> toItem = new List<Map<String, Object>>();

          for (Object element : toList) {
            if (element instanceof Map<String, Object>) {
                toItem.add((Map<String, Object>) element);
            }
          }

          Boolean exists = ExistingRecordsIds.contains(String.valueOf(record.get('id')));
          RC_SMS_Record__c smsRecord;

          if (!exists) { 
            if (toItem.size() == 1) {
                smsRecord = createMessageRecord(record, fromItem, toItem[0], smsThreads, smsThreadsToAdd);
                RecordsToInsert.add(smsRecord);
            } else {
                for (Map<String, Object> to : toItem) {
                    smsRecord = createMessageRecord(record, fromItem, to, smsThreads, smsThreadsToAdd);
                    RecordsToInsert.add(smsRecord);
                }
            }         
          } else {
            smsRecord = ExistingRecordsByIdMap.get(String.valueOf(record.get('id')));
          }
    
          String rawNbr = smsRecord.Direction__c == 'Inbound' ? (String) smsRecord.get('From_Phone__c') : (String) smsRecord.get('To_Phone__c');
          if(rawNbr == null) {
            continue;
          }
          String n = cleanNumber(rawNbr, true);  
          List<RC_SMS_Record__c> smsRecords = RecordsByNumberMap.get(n);
          if(smsRecords == null){
            smsRecords = new List<RC_SMS_Record__c>();
            RecordsByNumberMap.put(n, smsRecords);
          } 
          smsRecords.add(smsRecord);
        }

        if (!smsThreadsToAdd.isEmpty()) {
            addThreadToSmsRecord(smsThreadsToAdd, RecordsToInsert);
        }

    }

    public static void addThreadToSmsRecord(List<RC_SMS_Thread__c> threadsToAdd, List<RC_SMS_Record__c> RecordsToInsert) {
        if (threadsToAdd.isEmpty() || RecordsToInsert.isEmpty()) {
            return;
        }

        insert threadsToAdd;
    
        Map<String, Id> conversationIdToThreadId = new Map<String, Id>();
        for (RC_SMS_Thread__c thread : threadsToAdd) {
            conversationIdToThreadId.put(thread.Conversation_Id__c, thread.Id);
        }
    
        for (RC_SMS_Record__c record : RecordsToInsert) {
            String conversationId = record.Conversation_Id__c;
            if (conversationId != null && conversationIdToThreadId.containsKey(conversationId)) {
                record.RC_SMS_Thread__c = conversationIdToThreadId.get(conversationId);
            }
        }
    }

    public static void connectRecordsToContact(Map<String, List<RC_SMS_Record__c>> RecordsByNumberMap, List<RC_SMS_Record__c> RecordsToUpdate) {
        Map<String, String> idMapByPhone = new Map<String, String>();
        Set<String> numberSet = RecordsByNumberMap.keySet();
        List<String> numbers = new List<String>(numberSet);
        List<List<String>> chunks = new List<List<String>>();
        List<String> chunk = new List<String>();
        Integer chunkSize = 299;
        Integer l = 0;
    
        for (Integer i = 0; i < numbers.size(); i++) {
            if (l == 0) {
                chunk = new List<String>();
                chunks.add(chunk);
            }
            if (l == chunkSize) {
                l = 0;
            } else {
                l++;
            }
            chunk.add(numbers[i]);
        }
    
        for (List<String> chnk : chunks) {
            String search = !Test.isRunningTest() ? String.join(chnk, ' OR ') : '3214567788';
            if (search.length() < 5) {
                System.debug('No numbers were found to search for contacts.');
                continue;
            }
            List<List<SObject>> groups = [FIND :search IN PHONE FIELDS RETURNING Contact(Id, Phone, MobilePhone)];

            for (List<SObject> items : groups) {
                for (SObject item : items) {
                    Map<String, Object> values = item.getPopulatedFieldsAsMap();
                    String Id = null;
                    for (String fieldName : values.keySet()) {
                        if (fieldName == 'Id') {
                            Id = (String) values.get(fieldName);
                        } else {
                            idMapByPhone.put(cleanNumber((String) values.get(fieldName), false), Id);
                        }
                    }
                }
            }
        }
    
        for (String nbr : RecordsByNumberMap.keySet()) {
            Id Id = (Id) idMapByPhone.get(nbr);
            if (Id == null) continue;
    
            List<RC_SMS_Record__c> records = RecordsByNumberMap.get(nbr);
            for (RC_SMS_Record__c record : records) {
                if (record == null) continue;
                if (Id.getSObjectType() == Contact.SObjectType && (record.Contact__c == null || record.Contact__c != Id)) {
                    record.Contact__c = Id;
                    if (record.Id != null) RecordsToUpdate.add(record);
                }
            }
        }
    }

    public static RC_SMS_Record__c createMessageRecord(Map<String, Object> record, Map<String, Object> fromItem, Map<String, Object> toItem, List<RC_SMS_Thread__c> smsRelatedThreads, List<RC_SMS_Thread__c> threadsToAdd){
        Long conversationIdInt = (Long) record.get('conversationId');
        String conversationId = String.valueOf(conversationIdInt);
        RC_SMS_Thread__c relatedThread = findThreadById(smsRelatedThreads, conversationId);
        String relatedThreadId = relatedThread != null ? relatedThread.Id : null;
    
        if (relatedThread == null) {
            RC_SMS_Thread__c existingThread = findThreadById(threadsToAdd, conversationId);

            if (existingThread == null) {
                RC_SMS_Thread__c newThread = new RC_SMS_Thread__c (Conversation_Id__c = conversationId);
                threadsToAdd.add(newThread);
            }
        }
    
        RC_SMS_Record__c smsRecord = new RC_SMS_Record__c(
            SMS_Id__c = String.valueOf(record.get('id')),
            Status__c = (String) record.get('messageStatus'),
            Read_Status__c = (String) record.get('readStatus'),
            Record_Url__c = (String) record.get('uri'),
            Direction__c = (String) record.get('direction'),
            From_Location__c = (String) fromItem.get('location'),
            From_Phone__c = (String) fromItem.get('phoneNumber'),
            From_Name__c = (String) fromItem.get('name'),
            To_Name__c = (String) toItem.get('name'),
            To_Phone__c = (String) toItem.get('phoneNumber'),
            Subject__c = (String) record.get('subject'),
            Creation_Time__c = (Datetime) JSON.deserialize('"' + (String) record.get('creationTime') + '"', Datetime.class),
            Conversation_Id__c = conversationId,
            RC_SMS_Thread__c = relatedThread != null ? relatedThread.Id : null
        );
    
        return smsRecord;
    }

    public static RC_SMS_Thread__c findThreadById(List<RC_SMS_Thread__c> smsRelatedThreads, String targetConversationId) {
        RC_SMS_Thread__c foundThread = null;
        
        if (smsRelatedThreads.size() > 0) {
            for (RC_SMS_Thread__c thread : smsRelatedThreads) {
                if (thread.Conversation_Id__c == targetConversationId) {
                    foundThread = thread;
                    break;
                }
            }

            if (foundThread == null) {
                return null;
            }

            return foundThread;
        }  else {
            return null;
        }
    }

    public static string cleanNumber(String rawNbr, Boolean removeOne){
        String cleanNbr = rawNbr.replaceAll('\\D','');
        return removeOne == true ? cleanNbr.mid(1, 10) : cleanNbr;
    }
    
    public static String isoFormatter(Date dateObject) {
        return dateObject.year() + '-' + String.valueOf(dateObject.month()).leftPad(2, '0') + '-' + String.valueOf(dateObject.day()).leftPad(2, '0'); 
    }  

    public class RingCentralException extends Exception{}  
}