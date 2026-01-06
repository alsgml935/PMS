/**
 * 생성일자 : 2025-07-10
 * 설명       : ContentDocumentLink 관련 로직을 처리하는 클래스
 * 수정 로그:
 * Date         Author         Modification
 * 2025-07-10         Inho Kim         그룹 확인/Maintenance__c 연관 ContentDocumentLink 인 것을 확인하여 연관된 Maintenance__c 의 필드를 수정하도록 메서드 추가(handleAfterInsert_MaintenanceAlertFlag,isUserNotInMaintenanceGroup)
 **/
public without sharing class ContentDocumentLinkHandler {
  
    /**
     * 생성일자 : 2025-07-10
     * 설명    : ContentDocumentLink가 생성될 때 운영지원(Maintenance) 객체와 연관된 경우,  ContentVersion의 제목이 '서명완료_'로 시작하면 해당 Maintenance 레코드의  
     *  			SendSignedPDFAlertFlag__c 플래그를 true로 업데이트. 이 플래그 변화를 감지하여
     *  			Autolaunched Flow[[운영지원(월)] Update Triggered 고객사 서명본 PDF 업로드 시 알람/메일전송] 가 동작하여 메일/알림을 발송하게 됨.
     */
    public static void handleAfterInsert_MaintenanceAlertFlag(List<ContentDocumentLink> newLinks) {
        if (isUserNotInMaintenanceGroup()) return; // 현재 유저가 Maintenance 그룹이 아니면 메서드 스킵
        if (newLinks == null || newLinks.isEmpty()) return; // 전달된 링크가 없으면 메서드 스킵

        // Step 1: ContentDocumentId 수집 (Maintenance 객체 연관된 경우만)
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : newLinks) {
            if (link.ContentDocumentId != null && link.LinkedEntityId.getSObjectType().getDescribe().getName().contains('Maintenance__c')) {
                contentDocumentIds.add(link.ContentDocumentId);
            } else {
                return; // Maintenance 객체와 무관한 경우 전체 메서드 스킵
            }
        }

        // Step 2: ContentVersion의 최신 버전 매핑
        Map<Id, ContentVersion> docIdToVersionMap = new Map<Id, ContentVersion>();
        for (ContentVersion ver : [
            SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            ORDER BY VersionNumber DESC
        ]) {
            if (!docIdToVersionMap.containsKey(ver.ContentDocumentId)) {
                docIdToVersionMap.put(ver.ContentDocumentId, ver); // 최신 버전만 사용
            }
        }

        // Step 3: 제목이 '서명완료_'로 시작하는 경우 Maintenance 레코드 Id 수집
        Set<Id> maintenanceIdsToUpdate = new Set<Id>();
        for (ContentDocumentLink link : newLinks) {
            ContentVersion ver = docIdToVersionMap.get(link.ContentDocumentId);
            if (ver != null && ver.Title != null && ver.Title.startsWith('서명완료_')) {
                if (link.LinkedEntityId.getSObjectType().getDescribe().getName().contains('Maintenance__c')) {
                    maintenanceIdsToUpdate.add((Id)link.LinkedEntityId);
                }
            }
        }
        if (maintenanceIdsToUpdate.isEmpty()) return;

        // Step 4: SendSignedPDFAlertFlag__c 플래그 업데이트
        List<Maintenance__c> recordsToUpdate = new List<Maintenance__c>();
        for (Maintenance__c m : [
            SELECT Id, SendSignedPDFAlertFlag__c
            FROM Maintenance__c
            WHERE Id IN :maintenanceIdsToUpdate
        ]) {
            if (m.SendSignedPDFAlertFlag__c != true) {
                m.SendSignedPDFAlertFlag__c = true;
                recordsToUpdate.add(m);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }    
    
    /**
     * 생성일자 : 2025-07-10
     * 설명    : 현재 유저가 Maintenance 그룹 소속인지 확인
     * 반환값  : true = 그룹에 속하지 않음, false = 그룹에 속함 ( Setup > 공개 그룹 > 	MaintenanceGroup 의 멤버 확인 )
     */
    private static Boolean isUserNotInMaintenanceGroup() {
        Group groupMaintenance = [SELECT Id FROM Group WHERE DeveloperName ='MaintenanceGroup' LIMIT 1];
        if (groupMaintenance == null) return true; // 그룹이 없으면 "미소속" 처리
        List<GroupMember> members = [
            SELECT Id FROM GroupMember 
            WHERE GroupId = :groupMaintenance.Id AND UserOrGroupId = :UserInfo.getUserId() 
            LIMIT 1
        ];
        return members.isEmpty(); // true = 그룹 미소속
    }
}