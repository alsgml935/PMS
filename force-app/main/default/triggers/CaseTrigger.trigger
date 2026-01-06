trigger CaseTrigger on Case (after update) {
    if(Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.handleMaintenanceChange(Trigger.new, Trigger.oldMap);
    }
}