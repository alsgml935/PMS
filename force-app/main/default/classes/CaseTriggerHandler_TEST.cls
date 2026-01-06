/**
 * @Class : CaseTriggerHandler_TEST
 * @Author : IYeon, Jo
 * @Date : 2025-10-24
 * @Modified : 
 *  ---------------------------------------------
 *  NO | Date       | Modifier      | Description
 *  ---------------------------------------------
 *  1. | 2025-10-24 | IYeon, Jo     | CaseTriggerHandler에 대한 테스트코드 작성
 */
@isTest
private class CaseTriggerHandler_TEST {
    static Account acc;
    static Contract__c contract;
    static Contact con;
    static Opportunity opt;
    static RecordType rec;
    static BusinessHours bh;
    static Case testcase;
    static Maintenance__c maintenance1;
    static Maintenance__c maintenance2;
    
    static{
        acc = new Account(Name = 'test', Industry = '제조');
        insert acc;
        
        con = new Contact(
            AccountId = acc.Id, Email = 'test@test.com', LastName = 'test'
            , RelatedBusinessTeam__c = '세일즈포스사업팀', Title = '책임'
        );
        insert con;
        
        opt = new Opportunity(  
            AccountId = acc.Id, Amount = 43200000, Name = 'Test Opportunity'  
            , StageName = 'Prospecting', CloseDate = Date.newInstance(2023, 1, 2)  
        );
        insert opt;
        
        contract = new Contract__c(
            Account__c = acc.Id, AccountRep__c = con.Id
            , ContractExpiredDate__c = Date.newInstance(2024, 1, 1)  
            , ContractStartDate__c = Date.newInstance(2023, 1, 2)  
            , Opportunity__c = opt.Id
        );
        insert contract;
        
        rec = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Maintenance' LIMIT 1];  
        bh = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        
        maintenance1 = new Maintenance__c(Contract__c = contract.Id, UsageTime_Monthly__c = 10);
        insert maintenance1;
        
        maintenance2 = new Maintenance__c(Contract__c = contract.Id, UsageTime_Monthly__c = 20);
        insert maintenance2;
        
        testcase = new Case(
            AccountId = acc.Id, BusinessHoursId = bh.Id, ContactId = con.Id
            , Contract__c = contract.Id, Maintenance__c = maintenance1.Id
            , RecordTypeId = rec.Id, UsageTime__c = 3
        );
        insert testcase;
    }
    
    static testMethod void testMaintenanceChange(){
        Decimal originalTime = [SELECT UsageTime_Monthly__c FROM Maintenance__c WHERE Id = :maintenance1.Id].UsageTime_Monthly__c;
        
        Test.startTest();
        testcase.Maintenance__c = maintenance2.Id;
        update testcase;
        Test.stopTest();
        
        Decimal afterTime = [SELECT UsageTime_Monthly__c FROM Maintenance__c WHERE Id = :maintenance1.Id].UsageTime_Monthly__c;
        System.assertEquals(originalTime - 3, afterTime);
    }
}