/**
 * @Class : CaseTriggerHandler
 * @Author : IYeon, Jo
 * @Date : 2025-10-23
 * @Modified : 
 *  ---------------------------------------------
 *  NO | Date       | Modifier      | Description
 *  ---------------------------------------------
 *  1. | 2025-10-23 | IYeon, Jo     | handleMaintenanceChange 생성 -> 운영지원(월) 바뀔때 소요시간 계산
 */
public with sharing class CaseTriggerHandler {
    public CaseTriggerHandler() {

    }

    public static void handleMaintenanceChange(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        for(Case newCase : newCases){
            Case oldCase = oldCaseMap.get(newCase.Id);

            if(oldCase.Maintenance__c != newCase.Maintenance__c && oldCase.Maintenance__c != null){
                Maintenance__c beforeMaintenance = [select id,UsageTime_Monthly__c from Maintenance__c where id =:oldCase.Maintenance__c];
                
                Double caseTime = oldCase.UsageTime__c != null ? oldCase.UsageTime__c : 0;  
                Double maintenaceTime = beforeMaintenance.UsageTime_Monthly__c != null ? beforeMaintenance.UsageTime_Monthly__c : 0; 

                beforeMaintenance.UsageTime_Monthly__c = maintenaceTime - caseTime;
                update beforeMaintenance;
            }
        }
    }
}