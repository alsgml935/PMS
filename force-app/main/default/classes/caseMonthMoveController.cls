/**
 * @Class : caseMonthMoveController
 * @Author : IYeon, Jo
 * @Date : 2025-10-20
 * @Modified : 
 *  ---------------------------------------------
 *  NO | Date       | Modifier      | Description
 *  ---------------------------------------------
 *  1. | 2025-10-20 | IYeon, Jo     | 사례에 사례 이월 버튼 관련 최초작성 
 */
public with sharing class caseMonthMoveController {

    @AuraEnabled
    public static Map<String, Object> getCurrentCaseMonth(Id caseId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try{
            Case singleCase = [SELECT Id, Maintenance__c, Maintenance__r.Year__c, Maintenance__r.Month__c,AccountId  
                            FROM Case 
                            WHERE Id = :caseId 
                            LIMIT 1];

            if (singleCase == null || singleCase.Maintenance__c == null) {
                result.put('success', false);
                result.put('message', '해당 사례에 연결된 운영지원(월)이 없습니다.');
                return result;
            }

            result.put('success', true);
            result.put('year', String.valueOf(singleCase.Maintenance__r.Year__c));
            result.put('month', String.valueOf(singleCase.Maintenance__r.Month__c));
            result.put('caseAccountId', singleCase.AccountId);
            
            return result;

        } catch (Exception e) {
            result.put('success', false);
            result.put('message', '오류: ' + e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> checkMonthRecord(String year, String month, Id accountId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Id monthRecordId = findMonthRecord(year, month,accountId);
            
            if (monthRecordId != null) {
                result.put('exists', true);
                result.put('recordId', monthRecordId);
            } else {
                result.put('exists', false); 
                result.put('recordId', null);
            }
        
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('월 레코드 확인 중 오류: ' + e.getMessage());
        }
    }

    private static Id findMonthRecord(String year, String month, Id accountId) {

        List<Maintenance__c> monthRecords = [select id,Year__c,Month__c,Contract__r.Account__c from Maintenance__c where Year__c =:year and Month__c =:month and Contract__r.Account__c =:accountId];

        if (!monthRecords.isEmpty()) {

            return monthRecords[0].Id;
        }

        return null;
    }
    

    @AuraEnabled
    public static void updateCaseMonth(Id caseId, Id monthRecordId){
        
        Case caseData = new Case(
            Id = caseId,
            Maintenance__c = monthRecordId
        );
        update caseData;
        //이전  운영지원(월)의 소요시간은 트리거에서 계산 
    }
}