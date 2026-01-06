public without sharing class CommunityController {

    /**
     * @description 유지보수 홈 화면 진입 시 대쉬보드에 출력될 유지보수 항목 Return
     */
    @AuraEnabled
    public static Map<String, Object> getInit() {
        try {
            System.debug('hi');

            return new Map<String, Object> {
                'mtCase' => getCaseList()
            };

        } catch(Exception e) {
            System.debug('Error : '       + e.getMessage());
            System.debug('Line Number : ' + e.getLineNumber());

            throw new AuraHandledException(e.getMessage());
        } 

    }


    /**
     * @description 현재 유저의 유지보수 List 반환.
     */
    public static List<MTCaseWrapper> getCaseList() {
        List<MTCaseWrapper> results = new List<MTCaseWrapper>();

        User currentUser = [SELECT Id, Name, Profile.Name, AccountId, Account.Name
                            FROM User
                            WHERE Id = :UserInfo.getUserId()];

        List<Case> mTCases = [SELECT Id
                                     , Subject
                                     , MaintenanceContract__c
                                     , MaintenanceContract__r.Name
                                     , LastMH__c	
                                     , InChargeOfDecision__c
                                     , InChargeOfDecision__r.Name
                                     , toLabel(Case_Status__c)
                                     , SuggestHeadOffice__c
                                     , AccountId
                                     , Account.Name 
                                     , CreatedById
                              FROM Case
                              WHERE AccountId = :currentUser.AccountId
                              OR CreatedById = :currentUser.Id
                              ORDER BY CreatedDate DESC];
        System.debug(mTCases);


        if (!mTCases.isEmpty()) {
            for (Case c : mTCases) {
                results.add(new MTCaseWrapper(c));
            }
        }

        return results;
                       
    }


    // 유지보수 사례 Wrapper
    public class MTCaseWrapper {
        @AuraEnabled public Id caseId           {get; set;}
        @AuraEnabled public String name         {get; set;}
        @AuraEnabled public Id contractId       {get; set;}
        @AuraEnabled public String contractName {get; set;}
        @AuraEnabled public Decimal manday      {get; set;}
        @AuraEnabled public String assignTo     {get; set;}
        @AuraEnabled public String status       {get; set;}
        @AuraEnabled public Decimal suggest       {get; set;}
        @AuraEnabled public String account      {get; set;}

        public MTCaseWrapper() {}        
        public MTCaseWrapper(Case mCase) {
            this.caseId       = mCase.Id;
            this.name         = mCase.Subject;
            this.contractId   = mCase.MaintenanceContract__c;
            this.contractName = mCase.MaintenanceContract__r.Name;
            this.manday       = mCase.LastMH__c;
            this.assignTo     = mCase.InChargeOfDecision__r.Name;
            this.status       = mCase.Case_Status__c;
            this.suggest       = mCase.SuggestHeadOffice__c;
            this.account      = mCase.Account.Name;
        }

    }


}