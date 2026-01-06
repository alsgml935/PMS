/**
 * @Class : caseMonthMoveController_TEST
 * @Author : IYeon, Jo
 * @Date : 2025-10-23
 * @Modified : 
 *  ---------------------------------------------
 *  NO | Date       | Modifier      | Description
 *  ---------------------------------------------
 *  1. | 2025-10-23 | IYeon, Jo     | caseMonthMoveController에 대한 테스트코드 작성
 */
@isTest
private class caseMonthMoveController_TEST {
    static Account acc;
    static Contract__c contract;
    static Contact con;
    static Opportunity opt;  
    static RecordType rec;
    static BusinessHours bh;
    static Case testcase;
    static Maintenance__c beforemain;
    static Maintenance__c aftermain;
    
    static{
        acc = new Account (
            Name = 'test'
            , Industry = '제조'
        );
        insert acc;
        
        con = new Contact(
            AccountId = acc.Id
            , DoNotCall = false
            , Email = 'test@test.com'
            , LastName = 'test'
            , OwnerId = System.UserInfo.getUserId()
            , RelatedBusinessTeam__c = '세일즈포스사업팀'
            , Title = '책임'
        );
        insert con;
        
        opt = new Opportunity(  
            AccountId = acc.Id
            , Amount = 43200000
            , Name = 'Test Opportunity'  
            , StageName = 'Prospecting' 
            , CloseDate = Date.newInstance(2023, 1, 2)  
        );
        insert opt;
        
        contract = new Contract__c(
            Account__c = acc.Id
            , AccountRep__c = con.Id
            , ContractExpiredDate__c = Date.newInstance(2024, 1, 1)  
            , ContractStartDate__c = Date.newInstance(2023, 1, 2)  
            , Description__c = 'test'
            , Opportunity__c = opt.Id
        );
        insert contract;
        
        rec = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Maintenance' LIMIT 1];  
        bh = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        
        beforemain = new Maintenance__c(
            Contract__c = contract.Id
            , UsageTime_Monthly__c = 3 
        );
        insert beforemain;
        
        aftermain = new Maintenance__c(
            Contract__c = contract.Id
            , UsageTime_Monthly__c = 1  
        );
        insert aftermain;
        
        testcase = new Case(
            AccountId = acc.Id
            , BusinessHoursId = bh.Id
            , Case_Status__c = 'Case 신청'
            , ContactId = con.Id
            , Contract__c = contract.Id
            , Description = 'test'
            , Description__c = 'test'
            , Maintenance__c = beforemain.Id
            , RecordTypeId = rec.Id
            , UsageTime__c = 2  
        );
        insert testcase;
    }
    
    static testMethod void testUpdateCaseMonth(){
        Test.startTest();
        caseMonthMoveController.updateCaseMonth(testcase.Id, aftermain.Id);
        Test.stopTest();
        
        Case updatedCase = [SELECT Maintenance__c FROM Case WHERE Id = :testcase.Id];
        System.assertEquals(aftermain.Id, updatedCase.Maintenance__c);
    }
    
    static testMethod void testGetCurrentCaseMonth(){
        Test.startTest();
        Map<String, Object> result = caseMonthMoveController.getCurrentCaseMonth(testcase.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'));
        System.assertEquals(acc.Id, result.get('caseAccountId'));
    }
    
    static testMethod void testCheckMonthRecordExists(){
        Maintenance__c main = [SELECT Year__c, Month__c FROM Maintenance__c WHERE Id = :aftermain.Id];
        
        Test.startTest();
        Map<String, Object> result = caseMonthMoveController.checkMonthRecord(main.Year__c, main.Month__c, acc.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('exists'));
        System.assertNotEquals(null, result.get('recordId'));
    }
    
    static testMethod void testCheckMonthRecordNotExists(){
        Test.startTest();
        Map<String, Object> result = caseMonthMoveController.checkMonthRecord('9999', '99', acc.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.get('exists'));
        System.assertEquals(null, result.get('recordId'));
    }
    
    static testMethod void testGetCurrentCaseMonthNoMaintenance(){
        Case caseWithoutMaintenance = new Case(
            AccountId = acc.Id
            , BusinessHoursId = bh.Id
            , Case_Status__c = 'Case 신청'
            , ContactId = con.Id
            , Contract__c = contract.Id
            , RecordTypeId = rec.Id
        );
        insert caseWithoutMaintenance;
        
        Test.startTest();
        Map<String, Object> result = caseMonthMoveController.getCurrentCaseMonth(caseWithoutMaintenance.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.get('success'));
    }
}