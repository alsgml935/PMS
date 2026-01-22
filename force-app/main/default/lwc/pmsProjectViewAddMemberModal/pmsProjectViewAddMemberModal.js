/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2026-01-12      jh.jung           Created
 */

import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getMemberAllocations from '@salesforce/apex/PMS_ResourceManagementController.getMemberAllocations';
import getPicklistOptions from '@salesforce/apex/PMS_ResourceManagementController.getPicklistOptions';

export default class PmsProjectViewAddMemberModal extends LightningModal {
  @api projectId;    // 부모가 보낸 projectId를 받음
  @api projectName;  // 부모가 보낸 projectName을 받음
  @api currentYear;  // 부모가 보낸 currentYear를 받음

  // 교체(수정) 모드 전용 데이터
  @api isSwapMode = false;
  @api oldPmKey;
  @api pmName;        // 기존 멤버 이름
  @api oldRole;       // 기존 역할
  @api oldGrade;      // 기존 등급
  @api oldEmployeeId; // 기존 직원 ID

  @track selectedEmployeeId;
  @track memberAllocations = [];
  @track selectedRole = '';
  @track selectedGrade = '';
  @track roleOptions = [];
  @track gradeOptions = [];
  @track isLoading = false;

  connectedCallback() {
    console.log('modal connectedCallback')
    if (this.isSwapMode) {
      this.selectedRole = this.oldRole;
      this.selectedGrade = this.oldGrade;
      this.selectedEmployeeId = this.oldEmployeeId;

      this.loadData(this.selectedEmployeeId);
    }
  }

  @wire(getPicklistOptions, {
    objectName: 'ProjectMember__c',
    fieldName:  'Role__c'
  })
  wiredRoles({ error, data }) {
    if (data) {
      this.roleOptions = data;
      if (!this.isSwapMode && data.length > 0) this.selectedRole = data[0].value;
    }
  }

  @wire(getPicklistOptions, {
    objectName: 'ProjectMember__c',
    fieldName:  'Grade__c'
  })
  wiredGrades({ error, data }) {
    if (data) {
      this.gradeOptions = data;
      if (!this.isSwapMode && data.length > 0) this.selectedGrade = data[0].value;
    }
  }

  /** 모드에 따른 헤더 및 버튼 텍스트 설정 */
  get modalHeader() {
    return this.isSwapMode
      ? `멤버 교체 | 프로젝트: ${this.projectName} · 대체 인원: ${this.pmName}`
      : `신규 멤버 추가 | 프로젝트: ${this.projectName}`;
  }


  get actionLabel() {
    return this.isSwapMode ? '교체하기' : '추가하기';
  }

  get actionIcon() {
    return this.isSwapMode ? 'utility:replace' : 'utility:add';
  }

  /**
   * 현재 선택된 직원이 Placeholder(가배정) 인력인지 확인
   */
  get isPlaceholderSelected() {
    if (this.memberAllocations && this.memberAllocations.length > 0) {
      // Apex AllocationWrapper에서 넘겨주는 IsPlaceholder 필드 확인
      return this.memberAllocations[0].IsPlaceholder === true;
    }
    return false;
  }

  get placeholderWarningMessage() {
    if (this.memberAllocations.length > 0) {
      const grade = this.memberAllocations[0].MemberName; // '고급', '중급' 등이 들어있다고 가정
      return `현재 선택하신 항목은 [${grade}] 가배정 리소스입니다. 확정된 인력이 없을 때 임시 투입 계획용으로 사용하세요.`;
    }
    return '';
  }

  /**
   * 검색 결과에 표시할 필드 설정
   * - primaryField: 메인 텍스트 (직원 이름)
   * - additionalFields: 보조 텍스트 (소속, 직급)
   */
  get displayInfo() {
    return {
      primaryField: 'Name',
      additionalFields: ['Department__r.Name', 'JobLevel__c']
    };
  }

  /**
   * 검색 시 매칭할 필드 설정
   * - 이름 또는 부서명으로 검색 가능
   */
  get matchingInfo() {
    return {
      primaryField: { fieldPath: 'Name' },
      additionalFields: [
        { fieldPath: 'Department__r.Name' }
      ]
    };
  }

  /**
   * 필터 조건: 활성 직원만 표시
   */
  get filterInfo() {
    return {
      criteria: [
        {
          fieldPath: 'IsActive__c',
          operator: 'eq',
          value: true
        }
      ]
    };
  }

  // 피커에서 직원 선택 시 호출
  // async handleEmployeeChange(event) {
  //   this.selectedEmployeeId = event.detail.recordId;
  //
  //   if (this.selectedEmployeeId) {
  //     this.isLoading = true;
  //     try {
  //       // 특정 직원의 전체 데이터를 Apex에서 조회
  //       this.memberAllocations = await getMemberAllocations({
  //         memberId: this.selectedEmployeeId,
  //         year: this.currentYear
  //       });
  //     } catch (error) {
  //       console.error('멤버 데이터 조회 실패', error);
  //     } finally {
  //       this.isLoading = false;
  //     }
  //   }
  // }

  // 1. 순수하게 로직만 담은 함수
  async loadData(employeeId) {
    if (!employeeId) return;
    this.isLoading = true;
    try {
      this.memberAllocations = await getMemberAllocations({
        memberId: employeeId,
        year: this.currentYear
      });
    } catch (error) {
      console.error(error);
    } finally {
      this.isLoading = false;
    }
  }

// 2. 이벤트 핸들러는 이벤트를 받아서 함수에 전달만 함
  handleEmployeeChange(event) {
    this.selectedEmployeeId = event.detail.recordId;
    this.loadData(this.selectedEmployeeId); // 함수 호출
  }

  handleRoleChange(event)   { this.selectedRole = event.detail.value; }
  handleGradeChange(event)  { this.selectedGrade = event.detail.value; }

  get isAddDisabled() {
    return !this.selectedEmployeeId;
  }

  /** [수정] 실행 버튼 클릭 시 (Add와 Swap 통합 처리) */
  handleAction() {
    const firstEntry = this.memberAllocations.length > 0 ? this.memberAllocations[0] : {};

    // 부모에게 전달할 공통 데이터
    const payload = {
      employeeId: this.selectedEmployeeId,
      employeeName: firstEntry.MemberName,
      projectId: this.projectId,
      projectName: this.projectName,
      teamId: firstEntry.TeamId,
      teamName: firstEntry.TeamName,
      role: this.selectedRole,
      grade: this.selectedGrade,
      jobDesc: firstEntry.JobDesc,
      isPlaceholder: firstEntry.IsPlaceholder,
    };

    // Swap 모드라면 어떤 멤버를 교체할지 oldPmKey를 포함해서 보냄
    if (this.isSwapMode) {
      payload.oldPmKey = this.oldPmKey;
    }

    this.close({
      status: 'success',
      type: this.isSwapMode ? 'SWAP' : 'ADD', // 부모가 액션 타입을 알 수 있게 전달
      payload: payload
    });
  }

  // // 추가 버튼 클릭 시 (부모에게 ID 전달하며 닫기)
  // handleAdd() {
  //   // 부모가 가상 DTO를 만드는 데 필요한 모든 재료를 패키징해서 전달
  //   // memberAllocations[0]에서 팀 정보나 직급 정보를 파싱해서 보낼 수도 있습니다.
  //   const firstEntry = this.memberAllocations.length > 0 ? this.memberAllocations[0] : {};
  //
  //   this.close({
  //     status: 'success',
  //     payload: {
  //       employeeId: this.selectedEmployeeId,
  //       employeeName: firstEntry.MemberName,
  //       projectId: this.projectId,
  //       projectName: this.projectName,
  //       // 팀 뷰 그리드에서 사용하던 팀명/직급 정보를 그대로 전달
  //       teamId: firstEntry.TeamId,
  //       teamName: firstEntry.TeamName,
  //       role: this.selectedRole,
  //       jobDesc: firstEntry.JobDesc,
  //       isPlaceholder: firstEntry.IsPlaceholder,
  //     }
  //   });
  // }

  // 취소 버튼
  handleCancel() {
    this.close({ status: 'cancel' });
  }
}