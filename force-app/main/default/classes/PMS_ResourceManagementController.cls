/**
* @Author            : jh.jung
* @Description 		 : 
* @Target            : 
* @Modification Log
  Ver      Date            Author           Modification
  ===================================================================================
  1.0      2026-01-06      jh.jung           Created
*/
public with sharing class PMS_ResourceManagementController {

    public class AllocationWrapper {
        @AuraEnabled public String  Id;
        @AuraEnabled public String  CompositeKey;
        @AuraEnabled public String  ProjectMemberId;
        @AuraEnabled public String  MemberId;
        @AuraEnabled public String  MemberName;
        @AuraEnabled public String  TeamId;
        @AuraEnabled public String  TeamName;
        @AuraEnabled public String  ProjectId;
        @AuraEnabled public String  ProjectName;
        @AuraEnabled public String  Role;
        @AuraEnabled public String  JobDesc; // 직급 + 직무
        @AuraEnabled public String  Grade;
        @AuraEnabled public Integer Year;
        @AuraEnabled public Integer Month;
        @AuraEnabled public Decimal ContractMM = 0.0;
        @AuraEnabled public Decimal ActualMM = 0.0;
        @AuraEnabled public Decimal WeightedActualMM = 0.0;
        @AuraEnabled public Decimal WeightedContractMM = 0.0;
        @AuraEnabled public Boolean IsPlaceholder;

        public AllocationWrapper() {}

        // 1. [정상 레코드]
        public AllocationWrapper(MonthlyEstimation__c me) {
            ProjectMember__c pm = me.ProjectMember__r;
            setMemberInfo(pm.Employee__r);
            setProjectInfo(pm.Opportunity__c, pm.Opportunity__r.Name, pm.Opportunity__r.Probability__c);
//            setTimeInfo(Integer.valueOf(me.Year__c), Integer.valueOf(me.Month__c));
//            this.Id = me.Id;
//            this.ProjectMemberId = me.ProjectMember__c;
//            this.CompositeKey = me.AllocationExternalKey__c;
//            this.Role = pm.Role__c;
//            this.ContractMM = (me.ContractMM__c != null) ? me.ContractMM__c : 0.0;
//            this.ActualMM = (me.ActualMM__c != null) ? me.ActualMM__c : 0.0;

            this.CompositeKey = me.AllocationExternalKey__c;
            this.ProjectMemberId = me.ProjectMember__c;
            this.Id = me.Id;
            this.Year = Integer.valueOf(me.Year__c);
            this.Month = Integer.valueOf(me.Month__c);
            this.Role = pm.Role__c;
            this.Grade = pm.Grade__c;
            this.ContractMM = (me.ContractMM__c != null) ? me.ContractMM__c : 0.0;
            this.ActualMM = (me.ActualMM__c != null) ? me.ActualMM__c : 0.0;
            this.WeightedActualMM = (me.Fm_WeightedActualMM__c != null) ? me.Fm_WeightedActualMM__c : 0.0;
            this.WeightedContractMM = (me.Fm_WeightedContractMM__c != null) ? me.Fm_WeightedContractMM__c : 0.0;
        }

        // 2. [가상 레코드 - 공수 없음]
        public AllocationWrapper(ProjectMember__c pm, Integer year, Integer month) {
            setMemberInfo(pm.Employee__r);
            setProjectInfo(pm.Opportunity__c, pm.Opportunity__r.Name, pm.Opportunity__r.Probability__c);
//            setTimeInfo(year, month);
//            this.Id = 'virtual_' + this.CompositeKey;
//            this.ProjectMemberId = pm.Id;
//            this.Role = pm.Role__c;

            String pmExtKey = pm.ProjectMemberExternalKey__c;
            String strMonth = String.valueOf(month).leftPad(2, '0');

            this.CompositeKey = pmExtKey + '_' + year + strMonth;
            this.Id = 'virtual_' + this.CompositeKey;
            this.ProjectMemberId = pm.Id;
            this.Year = year;
            this.Month = month;
            this.Role = pm.Role__c;
            this.Grade = pm.Grade__c;
        }

        // 3. [가상 레코드 - 멤버 없음]
        public AllocationWrapper(Opportunity opp, Integer year, Integer month) {
            setProjectInfo(opp.Id, opp.Name, opp.Probability__c);
            setMemberInfo(null); // (미배정) 처리
//            setTimeInfo(year, month);
//            this.Id = 'ignore_opp_' + this.CompositeKey;

            String strMonth = String.valueOf(month).leftPad(2, '0');

            this.CompositeKey = 'NONE_' + year + strMonth;
            this.Id = 'ignore_' + this.CompositeKey;
            this.Year = year;
            this.Month = month;
        }

        // 4. [가상 레코드 - 프로젝트 없음]
        public AllocationWrapper(Employee__c emp, Integer year, Integer month) {
            setMemberInfo(emp);
            setProjectInfo('NONE', '(미할당)', null);
//            setTimeInfo(year, month);
//            this.Id = 'ignore_emp_' + this.CompositeKey;

            String strMonth = String.valueOf(month).leftPad(2, '0');

            this.CompositeKey = 'NONE_' + year + strMonth;
            this.Id = 'ignore_' + this.CompositeKey;
            this.Year = year;
            this.Month = month;
        }

        // --- Private Mappers (데이터 가공 엔진) ---

        private void setMemberInfo(Employee__c emp) {
            if (emp == null) {
                this.MemberId = 'NONE';
                this.MemberName = '(미배정)';
                return;
            }
            this.MemberId = emp.Id;
            this.MemberName = emp.Name;
            this.TeamId = emp.Department__c;
            this.TeamName = emp.Department__r.Name;
            this.IsPlaceholder = emp.IsPlaceholder__c;

            // JobDesc 가공 로직 통합
            String level = String.isNotBlank(emp.JobLevel__c) ? emp.JobLevel__c : '';
            String role = String.isNotBlank(emp.JobRole__c) ? '(' + emp.JobRole__c + ')' : '';
            this.JobDesc = level + role;
        }

        private void setProjectInfo(String pId, String pName, String pStatus) {
            this.ProjectId = pId;
            this.ProjectName = String.isNotBlank(pStatus)
                ? '(' + pStatus + ') ' + pName
                : pName;
        }

//        private void setTimeInfo(Integer yr, Integer mm) {
////            this.TargetMonth = Date.newInstance(yr, mm, 1);
//            this.Year = yr;
//            this.Month = mm;
//            String strMonth = String.valueOf(mm).leftPad(2, '0');
//
//            // 키 생성 로직 통합
//            String pPart = (this.ProjectId == null) ? 'NONE' : this.ProjectId;
//            String mPart = (this.MemberId == null) ? 'NONE' : this.MemberId;
//
//            this.CompositeKey = pPart + mPart + yr + strMonth;
//        }
    }

    // ---------------------------------------------------------
    // 2. Public API 메서드
    // ---------------------------------------------------------

//    @AuraEnabled(Cacheable=true)
    @AuraEnabled
    public static List<AllocationWrapper> getAllocations(String viewMode, String teamId, List<String> projectIds, String year, String probability) {
        if (String.isBlank(year) || String.isBlank(probability)) return new List<AllocationWrapper>();

        // 대상 프로젝트 ID Set 준비
        Set<Id> oppIds = new Set<Id>();
        if (viewMode == 'project' && projectIds != null) {
            for(String pid : projectIds) oppIds.add((Id)pid);
//        } else if (viewMode == 'team' && String.isNotBlank(teamId)) {
        } else if (viewMode.contains('team') && String.isNotBlank(teamId)) {
            // 팀 뷰의 경우 해당 팀원이 속한 프로젝트들을 가져오기 위해 프로젝트 제한 없음(또는 별도 로직)
        }

        return processAllocations(viewMode, teamId, oppIds, year, probability);
    }

    @AuraEnabled(Cacheable=true)
    public static List<AllocationWrapper> getMemberAllocations(String memberId, String year) {
        if (String.isBlank(memberId) || String.isBlank(year)) return new List<AllocationWrapper>();
        // 모달 1인 조회는 'member' 모드로 처리
        return processAllocations('member', memberId, new Set<Id>(), year, null);
    }

    @AuraEnabled
    public static void saveAllChanges(
        List<Map<String, String>> membersToInsert,
        List<Id> deleteMemberIds,
        List<Map<String, Object>> mmList
    ) {
        
        System.debug('membersToInsert ::: ' + membersToInsert);
        System.debug('deleteMemberIds ::: ' + deleteMemberIds);
        System.debug('mmList ::: ' + mmList);
        Savepoint sp = Database.setSavepoint();
        try {
            // 1. 멤버 삭제 (Soft Delete)
            if (deleteMemberIds != null && !deleteMemberIds.isEmpty()) {
                List<ProjectMember__c> membersToDeactivate = new List<ProjectMember__c>();
                for (Id pmId : deleteMemberIds) {
                    membersToDeactivate.add(new ProjectMember__c(Id = pmId, IsActive__c = false));
                }
                update membersToDeactivate;
            }

            // ProjectMember의 ExternalKey를 키로, 실제 ID를 값으로 갖는 Map
            Map<String, Id> pmKeyToIdMap = new Map<String, Id>();

            // 2. 멤버 추가/수정 (ProjectMember__c)
            if (membersToInsert != null && !membersToInsert.isEmpty()) {
                List<ProjectMember__c> pmList = new List<ProjectMember__c>();
                for (Map<String, String> m : membersToInsert) {
                    // LWC에서 보낸 고유 PMKey (예: OppId_TimestampRAND1234)
                    String pmKey = m.get('PMKey');

                    pmList.add(new ProjectMember__c(
                        Opportunity__c = (Id)m.get('ProjectId'),
                        Employee__c = (Id)m.get('MemberId'),
                        Role__c = m.get('Role'),
                        Grade__c = m.get('Grade'),
                        ProjectMemberExternalKey__c = pmKey,
                        IsActive__c = true
                    ));
                }
                // 1단계 Upsert: 신규 멤버에게 ID가 할당됨
                System.debug(pmList);
                upsert pmList ProjectMemberExternalKey__c;

                // Upsert 후 생성된 DB ID를 Map에 즉시 저장 (자식 레코드 연결용)
                for (ProjectMember__c pm : pmList) {
                    pmKeyToIdMap.put(pm.ProjectMemberExternalKey__c, pm.Id);
                }
            }

            // 3. 공수 데이터 저장 (MonthlyEstimation__c)
            if (mmList != null && !mmList.isEmpty()) {
                // 기존 DB에 있는 부모 ID들도 맵에 보충 (수정 모드 대비)
                Set<String> pmKeysNeeded = new Set<String>();
                for (Map<String, Object> mm : mmList) {
                    String cKey = (String)mm.get('CompositeKey');
                    pmKeysNeeded.add(cKey.substringBeforeLast('_'));
                }

                // 이미 pmKeyToIdMap에 없는 키들만 DB에서 추가 조회
                pmKeysNeeded.removeAll(pmKeyToIdMap.keySet());
                if (!pmKeysNeeded.isEmpty()) {
                    for (ProjectMember__c pm : [
                        SELECT Id, ProjectMemberExternalKey__c FROM ProjectMember__c
                        WHERE ProjectMemberExternalKey__c IN :pmKeysNeeded
                    ]) {
                        pmKeyToIdMap.put(pm.ProjectMemberExternalKey__c, pm.Id);
                    }
                }

                List<MonthlyEstimation__c> meList = new List<MonthlyEstimation__c>();
                for (Map<String, Object> mm : mmList) {
                    String cKey = (String)mm.get('CompositeKey'); // 예: PMKey_YYYYMM

                    // 마지막 '_' 이전이 무조건 부모 키
                    String pmKey = cKey.substringBeforeLast('_');

                    Id parentId = pmKeyToIdMap.get(pmKey);
                    if (parentId == null) continue; // 부모가 없으면 skip

                    meList.add(new MonthlyEstimation__c(
                        ProjectMember__c = parentId,
                        AllocationExternalKey__c = cKey,
                        ContractMM__c = Decimal.valueOf(String.valueOf(mm.get('ContractMM'))),
                        ActualMM__c = Decimal.valueOf(String.valueOf(mm.get('ActualMM'))),
                        Year__c = String.valueOf(mm.get('Year')),
                        Month__c = String.valueOf(mm.get('Month')).leftPad(2, '0')
                    ));
                }
                // 2단계 Upsert: 자식 레코드 저장
                upsert meList AllocationExternalKey__c;
            }

        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ---------------------------------------------------------
    // 3. [핵심] 공통 처리 로직 (Private)
    // ---------------------------------------------------------
    private static List<AllocationWrapper> processAllocations(String mode, String filterId, Set<Id> oppIds, String year, String probability) {
        List<AllocationWrapper> results = new List<AllocationWrapper>();
        Integer yr = Integer.valueOf(year);


        System.debug('mode :::' + mode);
        System.debug('filterId :::' + filterId);
        System.debug('oppIds :::' + oppIds);
        System.debug('year :::' + year);
        System.debug('contains :::' + mode.contains('team'));

        // A-0. 멤버 뷰인 경우 해당 멤버 정보 미리 조회 (결과가 없을 때 사용하기 위함)
        Employee__c targetEmployee;
        if (mode == 'member') {
            targetEmployee = [
                SELECT
                    Id, Name, Department__c, JobRole__c, JobLevel__c, Fm_SortKey__c, IsPlaceholder__c,
                    Department__r.Name
                FROM Employee__c
                WHERE Id = :filterId
                AND IsActive__c = TRUE
                LIMIT 1
            ];
        }

        // A-1. 직원(Employee) 정보 조회 (팀 뷰인 경우 모든 팀원이 나와야 함)
        List<Employee__c> employeeList = [
            SELECT Id, Name, Department__c, JobRole__c, JobLevel__c, Fm_SortKey__c, IsPlaceholder__c,
                Department__r.Name
            FROM Employee__c
            WHERE (Department__c = :filterId OR Department__r.ParentDepartment__c = :filterId)
            AND IsActive__c = TRUE
            ORDER BY Department__r.Fm_SortKey__c, Fm_SortKey__c
        ];

        Map<Id, Employee__c> employeeMap = new Map<Id, Employee__c>(employeeList);
        Set<Id> employeeIds = employeeMap.keySet();

//        Map<Id, Employee__c> employeeMap = new Map<Id, Employee__c>();
//        if (mode.contains('team')) {
//            employeeMap = new Map<Id, Employee__c>([
//                SELECT
//                    Id, Name, Department__c, JobRole__c, JobLevel__c, Fm_SortKey__c, IsPlaceholder__c,
//                    Department__r.Name
//                FROM Employee__c
//                WHERE (Department__c = :filterId OR Department__r.ParentDepartment__c = :filterId)
//                AND IsActive__c = TRUE
//                ORDER BY Department__r.Fm_SortKey__c, Fm_SortKey__c
//            ]);
//        }
//        Set<Id> employeeIds = employeeMap.keySet();

        // A-2. 프로젝트 멤버 조회 (기준점)
        String pmQuery =
            ' SELECT Id, Employee__c, Opportunity__c, Role__c, Grade__c, Fm_SortKey__c, ProjectMemberExternalKey__c, ' +
            ' Employee__r.Name, Employee__r.Department__c, Employee__r.JobRole__c, Employee__r.JobLevel__c, Employee__r.Fm_SortKey__c, Employee__r.IsPlaceholder__c, ' +
            ' Employee__r.Department__r.Name, ' +
            ' Opportunity__r.Name, Opportunity__r.Probability__c ' +
            ' FROM ProjectMember__c ' +
            ' WHERE Employee__r.IsActive__c = true ' +
            ' AND IsActive__c = true ';
        // 해당 연도에 MonthlyEstimation 레코드가 존재하는 멤버만 조회
        if (mode.contains('team') || mode == 'member') {
            pmQuery += ' AND Id IN (SELECT ProjectMember__c FROM MonthlyEstimation__c WHERE Year__c = :year) ';
        }

        if (mode.contains('team')) pmQuery += ' AND Employee__c IN :employeeIds ';
        else if (mode == 'project') pmQuery += ' AND Opportunity__c IN :oppIds ';
        else if (mode == 'member') pmQuery += ' AND Employee__c = :filterId ';

        if (String.isNotBlank(probability)) {
            if (probability == 'WON') {
                // 1. 수주 완료된 건만 조회
                pmQuery += ' AND Opportunity__r.StageName = \'Closed Won\' ';
            }
            else if (probability == 'NONE') {
                // 2. 수주 전이면서 확도 값도 없는 건 (관리 누락)
                pmQuery += 'AND Opportunity__r.Probability__c = null AND Opportunity__r.StageName != \'Closed Won\' ';
            }
            else if (probability != 'ALL') {
                // 3. 상/중/하 선택 시: 수주 전인 건들 중에서만 해당 확도를 조회 (정합성 핵심)
                pmQuery += ' AND Opportunity__r.Probability__c = :probability AND Opportunity__r.StageName != \'Closed Won\' ';
            }
            // ALL인 경우 조건 없음 (전체 조회)
        }


        if (mode.contains('team')) pmQuery += ' ORDER BY Employee__r.Department__r.Fm_SortKey__c, Employee__r.Fm_SortKey__c, Employee__r.Name, Opportunity__r.Name ';
        else if (mode == 'project') pmQuery += ' ORDER BY Fm_SortKey__c, Employee__r.Name ';

        List<ProjectMember__c> pmList = Database.query(pmQuery);

        // 프로젝트가 할당된 직원 ID들을 추적
        Set<Id> assignedEmployeeIds = new Set<Id>();
        Set<Id> pmIds = new Set<Id>();
        for(ProjectMember__c pm : pmList) {
            pmIds.add(pm.Id);
            assignedEmployeeIds.add(pm.Employee__c);
        }

        // B. 실제 공수 데이터 조회 및 Map화 (기존과 동일)
        Map<String, MonthlyEstimation__c> meMap = new Map<String, MonthlyEstimation__c>();
        if(!pmIds.isEmpty()) {
            for (MonthlyEstimation__c me : [
                SELECT
                    Id, ContractMM__c, ActualMM__c, Month__c, Year__c, AllocationExternalKey__c, Fm_WeightedActualMM__c, Fm_WeightedContractMM__c,
                    ProjectMember__r.Employee__c, ProjectMember__r.Opportunity__c, ProjectMember__r.Role__c, ProjectMember__r.Grade__c, ProjectMember__r.Fm_SortKey__c,
                    ProjectMember__r.Opportunity__r.Name, ProjectMember__r.Opportunity__r.Probability__c,
                    ProjectMember__r.Employee__r.Name, ProjectMember__r.Employee__r.JobRole__c, ProjectMember__r.Employee__r.JobLevel__c, ProjectMember__r.Employee__r.Department__c, ProjectMember__r.Employee__r.Fm_SortKey__c, ProjectMember__r.Employee__r.IsPlaceholder__c,
                    ProjectMember__r.Employee__r.Department__r.Name

                FROM MonthlyEstimation__c
                WHERE ProjectMember__c IN :pmIds
                AND Year__c = :year
                AND ProjectMember__r.IsActive__c = TRUE
            ]) {
                meMap.put(me.ProjectMember__c + '_' + Integer.valueOf(me.Month__c), me);
            }
        }

        // C. Case 1 & 2 처리 (프로젝트 할당이 있는 행들)
        Set<Id> projectsWithMembers = new Set<Id>();
        for (ProjectMember__c pm : pmList) {
            projectsWithMembers.add(pm.Opportunity__c);
            for (Integer m = 1; m <= 12; m++) {
                MonthlyEstimation__c me = meMap.get(pm.Id + '_' + m);
                if(me != null) results.add(new AllocationWrapper(me));
                else           results.add(new AllocationWrapper(pm, yr, m));
            }
        }

        // D. Case 3 처리 (프로젝트는 있는데 멤버가 없는 경우 - 프로젝트 뷰 전용)
        if (mode == 'project') {
            List<Opportunity> oppList = [SELECT Id, Name, Probability__c FROM Opportunity WHERE Id IN :oppIds];
            for (Opportunity opp : oppList) {
                if (!projectsWithMembers.contains(opp.Id)) {
                    for (Integer m = 1; m <= 12; m++) {
                        results.add(new AllocationWrapper(opp, yr, m));
                    }
                }
            }
        }

        // E. Case 4: 팀 뷰에서 프로젝트 할당이 아예 없는 직원 처리
//        if (mode == 'team') {
        if (mode.contains('team')) {
//            for (Employee__c emp : employeeMap.values()) {
            for (Employee__c emp : employeeList) {
                if (!assignedEmployeeIds.contains(emp.Id)) {
                    // 이 직원은 프로젝트가 없으므로 '빈 프로젝트' 형태의 가상 행 생성
                    for (Integer m = 1; m <= 12; m++) {
                        results.add(new AllocationWrapper(emp, yr, m));
                    }
                }
            }
        }

        // F. Case 5: 멤버 뷰에서 프로젝트 할당이 아예 없는 경우 처리
        if (mode == 'member' && results.isEmpty() && targetEmployee != null) {
            // 이 멤버는 배정된 프로젝트가 하나도 없으므로, UI를 그리기 위해 '빈 프로젝트' 형태의 가상 행 생성
            for (Integer m = 1; m <= 12; m++) {
                results.add(new AllocationWrapper(targetEmployee, yr, m));
            }
        }

        return results;
    }

    // 콤보박스 옵션용 공통 Wrapper 클래스
    public class OptionWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getDepartmentOptions(Id parentDeptId, Boolean includeAll) {
        List<OptionWrapper> options = new List<OptionWrapper>();

        // 1. '전체' 옵션 추가 로직 (플래그가 true일 때만)
        if (includeAll == true && parentDeptId != null) {
            options.add(new OptionWrapper('전체', parentDeptId.toString()));
        }

        // 2. 하위 부서 조회
        for (Department__c d : [
            SELECT Id, Name
            FROM Department__c
            WHERE ParentDepartment__c = :parentDeptId
            ORDER BY Fm_SortKey__c
        ]) {
            options.add(new OptionWrapper(d.Name, d.Id));
        }

        return options;
    }

    /**
 * @description 필터 조건(연도, 확도)에 맞는 프로젝트(Opportunity) 목록을 조회하여 LWC 콤보박스용 옵션 리턴
 * @param year 조회 대상 연도 (문자열 숫자)
 * @param probability 수주확도 필터 값 (ALL, WON, NONE, 상, 중, 하 등)
 * @return List<OptionWrapper> 라벨과 ID가 포함된 프로젝트 옵션 리스트
 */
    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getProjectOptions(String year, String probability) {
        if (String.isBlank(year)) return new List<OptionWrapper>();

        List<OptionWrapper> options = new List<OptionWrapper>();
        Integer targetYear = Integer.valueOf(year);

        /**
         * [날짜 필터링 로직 설정]
         * 현재 기준: (조회연도 - 1년) ~ (조회연도) 사이 마감된 프로젝트 조회
         * 이유: 작년 말 수주되어 올해까지 공수가 이어지는 프로젝트를 포함하기 위함
         * 수정 필요 시: 특정 분기나 당해 연도만 보고 싶다면 아래 startDate의 year를 조정하세요.
         */
        Date startDate = Date.newInstance(targetYear - 1, 1, 1); // 조회 연도 1월 1일 기준
        Date endDate = Date.newInstance(targetYear, 12, 31);    // 조회 연도 12월 31일 기준

        // 1. 기본 SOQL 구성 (StageName은 UI 라벨 분기 및 필터 정합성에 필수)
        String query = 'SELECT Id, Name, Probability__c, CloseDate, StageName FROM Opportunity WHERE ';

        // 마감일(CloseDate) 기준 필터링
        query += ' (CloseDate >= :startDate AND CloseDate <= :endDate) ';

        /**
         * [수주확도 및 단계(Stage) 배타적 필터링 로직]
         * 수식 필드(Fm_WeightedActualMM__c)의 계산 로직과 일관성을 유지해야 함
         * 1. WON: 수주 성공(Closed Won) 상태인 프로젝트만
         * 2. NONE: 수주 전이면서 확도 값이 입력되지 않은 프로젝트 (관리 누락건)
         * 3. 일반(상/중/하): 수주 전 프로젝트 중 해당 확도를 가진 프로젝트 (이미 수주된 건은 제외)
         */
        if (String.isNotBlank(probability)) {
            if (probability == 'WON') {
                // StageName이 'Closed Won'인 확정 건 조회
                query += ' AND StageName = \'Closed Won\' ';
            }
            else if (probability == 'NONE') {
                // 확도 값이 null이고, 아직 수주 성공 전인 프로젝트
                query += ' AND Probability__c = null AND StageName != \'Closed Won\' ';
            }
            else if (probability != 'ALL') {
                // 특정 확도(상/중/하) 선택 시, 이미 수주 성공(Won)한 데이터는 중복 조회를 방지하기 위해 제외
                query += ' AND Probability__c = :probability AND StageName != \'Closed Won\' ';
            }
            // ALL(전체) 선택 시에는 추가 조건 없이 기간 내 모든 프로젝트 노출
        }

        // 마감일 순으로 정렬하여 최근 작업 중인 프로젝트가 상단에 오도록 처리
        query += ' ORDER BY CloseDate DESC LIMIT 200 ';

        try {
            List<Opportunity> oppList = Database.query(query);
            for (Opportunity opp : oppList) {
                // 마감 연도 추출 (UI 가독성용)
                String closeYear = opp.CloseDate != null ? String.valueOf(opp.CloseDate.year()) : '-';
                String probPart = '';

                /**
                 * [라벨링 로직]
                 * 사용자가 목록에서 수주 상태를 직관적으로 알 수 있도록 분기
                 * 수주 완료 시 '(완료)', 미완료 시 '(확도)' 표시
                 */
                if (opp.StageName == 'Closed Won') {
                    probPart = ' (완료)';
                } else {
                    probPart = String.isBlank(opp.Probability__c)
                        ? ''
                        : ' (' + opp.Probability__c + ')';
                }

                // 최종 라벨 예시: [2025] (완료) 만트럭 프로젝트 / [2025] (상) 포스코 시스템 구축
                String label = '[' + closeYear + ']' + probPart + ' ' + opp.Name;
                options.add(new OptionWrapper(label, opp.Id));
            }
        } catch (Exception e) {
            // 쿼리 오류나 비정상 데이터 접근 시 예외 처리
            throw new AuraHandledException('프로젝트 옵션 조회 중 오류 발생: ' + e.getMessage());
        }

        return options;
    }

    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getPicklistOptions(String objectName, String fieldName) {
        List<OptionWrapper> options = new List<OptionWrapper>();

        try {
            // 1. 문자열로부터 SObjectType과 Describe 정보 가져오기
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult sObjectDescribe = sObjectType.getDescribe();

            // 2. 필드 맵에서 해당 필드 정보 추출
            Schema.DescribeFieldResult fieldDescribe = sObjectDescribe.fields.getMap().get(fieldName).getDescribe();

            // 3. 픽리스트 값 루프
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.isActive()) { // 활성화된 값만 포함
                    options.add(new OptionWrapper(entry.getLabel(), entry.getValue()));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('픽리스트 정보를 불러오지 못했습니다: ' + e.getMessage());
        }

        return options;
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getInitMetadata() {
        Map<String, Object> res = new Map<String, Object>();

        // 1. 연도 옵션
        res.put('years', getPicklistOptions('MonthlyEstimation__c', 'Year__c'));
        // 2. 최상위 부서
        res.put('divisions', getDepartmentOptions(null, false));
        // 3. 확도 옵션
        List<OptionWrapper> probList = new List<OptionWrapper>();
        probList.add(new OptionWrapper('전체', 'ALL'));
        probList.add(new OptionWrapper('완료', 'WON'));

        // DB의 기존 픽리스트 값들(상, 중, 하) 추가
        probList.addAll(getPicklistOptions('Opportunity', 'Probability__c'));

        probList.add(new OptionWrapper('미지정', 'NONE'));

        res.put('probabilities', probList);

//        res.put('probabilities', getPicklistOptions('Opportunity', 'Probability__c'));

        return res;
    }
}