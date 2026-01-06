@IsTest
private class PMS_ResourceManagementControllerTest {

    @IsTest
    static void testGetAllocations_TeamView() {
        Test.startTest();

        List<PMS_ResourceManagementController.AllocationWrapper> results =
            PMS_ResourceManagementController.getAllocations(
                'team',
                'T_SS',      // 솔루션사업팀
                null,
                '2025'
            );

        Test.stopTest();

        System.assertNotEquals(0, results.size(), '결과가 존재해야 합니다');

        // 팀 필터 검증
        for (PMS_ResourceManagementController.AllocationWrapper row : results) {
            System.assertEquals('T_SS', row.TeamId);
            System.assertNotEquals(null, row.TargetMonth);
        }
    }

    @IsTest
    static void testGetAllocations_ProjectView() {
        Test.startTest();

        List<String> projectIds = new List<String>{ 'P01', 'P03' };

        List<PMS_ResourceManagementController.AllocationWrapper> results =
            PMS_ResourceManagementController.getAllocations(
                'project',
                null,
                projectIds,
                '2025'
            );

        Test.stopTest();

        System.assertNotEquals(0, results.size(), '프로젝트 기준 결과가 있어야 합니다');

        for (PMS_ResourceManagementController.AllocationWrapper row : results) {
            System.assert(
                projectIds.contains(row.ProjectId),
                '선택한 프로젝트만 반환되어야 합니다'
            );
        }
    }

    @IsTest
    static void testGetAllocations_ProjectView_EmptyProjectIds() {
        Test.startTest();

        List<PMS_ResourceManagementController.AllocationWrapper> results =
            PMS_ResourceManagementController.getAllocations(
                'project',
                null,
                new List<String>(),
                '2025'
            );

        Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            '프로젝트 ID가 없으면 결과가 없어야 합니다'
        );
    }

    @IsTest
    static void testGetAllocations_BlankYear() {
        Test.startTest();

        List<PMS_ResourceManagementController.AllocationWrapper> results =
            PMS_ResourceManagementController.getAllocations(
                'team',
                'T_SF1',
                null,
                null
            );

        Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            'year가 없으면 빈 리스트를 반환해야 합니다'
        );
    }

    @IsTest
    static void testAllocationFieldValues() {
        Test.startTest();

        List<PMS_ResourceManagementController.AllocationWrapper> results =
            PMS_ResourceManagementController.getAllocations(
                'team',
                'T_AX',
                null,
                '2025'
            );

        Test.stopTest();

        PMS_ResourceManagementController.AllocationWrapper sample = results[0];

        System.assertNotEquals(null, sample.Id);
        System.assertNotEquals(null, sample.CompositeKey);
        System.assertNotEquals(null, sample.MemberId);
        System.assertNotEquals(null, sample.ProjectId);
        System.assertNotEquals(null, sample.TargetMonth);
        System.assert(sample.ContractMM >= 0);
        System.assert(sample.ActualMM >= 0);
    }
}
