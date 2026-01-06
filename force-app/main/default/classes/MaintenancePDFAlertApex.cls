public without sharing class MaintenancePDFAlertApex {

    public class OutputWrapper {
        @InvocableVariable
        public List<String> recordIds;
        @InvocableVariable
        public List<String> fileTitles;        

        public OutputWrapper(List<String> ids) {
                this.recordIds = ids;
        }
      public OutputWrapper(List<String> ids, List<String> titles) {
              this.recordIds = ids;
              this.fileTitles = titles;
        }
    }

    @InvocableMethod(label='Get Maintenance Record IDs from PDF Files with (확인) Title')
    public static List<OutputWrapper> fetchMaintenanceRecords() {
        System.debug('Running as user: ' + UserInfo.getUserId());
     Set<Id> maintenanceIdSet = new Set<Id>();

    List<ContentDocument> matchDocuments = [
        SELECT Id, Title
        FROM ContentDocument
        WHERE  (Title LIKE '%서명완료_%' ) 
        AND FileType = 'PDF'
        //AND CreatedDate = LAST_N_MONTHS:2
    ]; 
        System.debug(matchDocuments);

    for (ContentDocument conDoc : matchDocuments) {
        Id eachDocId = conDoc.Id;
		System.debug(conDoc);
        try {
            ContentDocumentLink matchedLink = [
                SELECT Id, LinkedEntityId, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :eachDocId
                ORDER BY Visibility DESC
                LIMIT 1
            ];

            Id linkedId = matchedLink.LinkedEntityId;
            String sObjectType = linkedId.getSObjectType().getDescribe().getName();

            if (sObjectType == 'Maintenance__c') {
                maintenanceIdSet.add(linkedId);
            }
        } catch (Exception e) {
            continue;
        }
    }

    // Convert to List<String>
    List<String> idList = new List<String>();
    for (Id recordId : maintenanceIdSet) {
        idList.add(String.valueOf(recordId));
    }

    List<OutputWrapper> result = new List<OutputWrapper>();
    result.add(new OutputWrapper(idList));
        
      System.debug('Returning maintenanceIdSet: ' + maintenanceIdSet);
	System.debug('Returning idList: ' + idList);
	System.debug('Returning OutputWrapper: ' + result);      
    return result;
    }

}