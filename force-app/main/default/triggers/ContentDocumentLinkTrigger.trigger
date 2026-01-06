/**
 * @description       : ContentDocumentLink 레코드가 생성될 때 처리 로직 실행 트리거
 * @author            : Inho Kim - 운영지원 서명완료 PDF 업로드 시 플래그 업데이트 트리거 추가
 * 생성일자           : 2025-07-10
 * 작업 로그         : ContentDocumentLinkHandler.handleAfterInsert_MaintenanceAlertFlag 호출
 */
trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentLinkHandler.handleAfterInsert_MaintenanceAlertFlag(Trigger.new);
    }
}