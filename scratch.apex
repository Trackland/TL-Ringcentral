Date dateFrom = Date.today();
Date dateTo = Date.today().addDays(1);

try {
    TL_RingCentral_Logs.retrieveAllLogsAndInsert('Production', dateFrom.addDays(-2), dateTo, 1);
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}


// TL_RingCentral_SMS.get();

// List<List<SObject>> groups = [FIND '7034012766 OR 8137352484 OR 7272724368' IN PHONE FIELDS RETURNING Contact(Id,Phone,MobilePhone), Lead(Id,Phone,MobilePhone), Account(Id, Phone)];
// Map<String, String> idPhoneMap = new Map<String, String>();
// for(List<SObject> items : groups){
//   for(SObject item : items){
//     Map<String, Object> values = item.getPopulatedFieldsAsMap();
//     System.debug(values);
//     String Id = null;
//     for(String fieldName: values.keySet()) {
//       if(fieldName == 'Id') Id = values[fieldName];
//       else idPhoneMap.put(Id, values[fieldName]);
//     }
//   }
// }


// List<SOBJECT> items = [SELECT Id FROM Call_Log__c];
// delete items;


