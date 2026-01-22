/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2026-01-06      jh.jung           Created
 */

import { LightningElement, api, track } from 'lwc';

import AddMemberModal from 'c/pmsProjectViewAddMemberModal';

export default class PmsProjectViewGrid extends LightningElement {

  // @api allocations = [];
  _allocations = [];

  @api
  get allocations() {
    return this._allocations;
  }
  set allocations(value) {
    this._allocations = value ? [...value] : [];
  }
  @api currentHalf;
  @api isReadOnly;
  @api draftValues = {};
  @api currentYear;

  cellMap = new Map();
  memberMap = new Map();
  @track inputCache = new Map();

  get monthNums() { return this.currentHalf === 'H1' ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] : [1, 2, 3, 4, 5, 6]; }
  get monthLabels() { return this.monthNums.map(m => `${m}월`); }

  get formattedData() {
    const projectMap = {};
    this.cellMap.clear();
    this.memberMap.clear();
    console.log('allocations[0] ::: ' + JSON.stringify(this.allocations[0]))

    this.allocations.forEach(item => {
      const month = item.Month;
      if (!this.monthNums.includes(month)) return;

      // 1. 부모 키(PMKey) 추출: OppId_Stamp 형태
      const pmKey = item.CompositeKey.substring(0, item.CompositeKey.lastIndexOf('_'));

      if (!projectMap[item.ProjectId]) {
        projectMap[item.ProjectId] = {
          id: item.ProjectId,
          name: item.ProjectName,
          members: {},
          monthlyTotals: this.monthNums.map(m => ({ month: m, contractTotal: 0, actualTotal: 0 })),
        };
      }

      const proj = projectMap[item.ProjectId];

      if (!proj.members[pmKey]) {
        proj.members[pmKey] = {
          pmKey: pmKey, // tr의 key로 사용될 값 (이제 유니크함)
          pmId: item.ProjectMemberId,
          memberId: item.MemberId, // 실제 직원 ID는 별도 보관
          name: item.MemberName,
          role: item.Role,
          team: item.TeamName,
          grade: item.Grade,
          isDeleted: item.isDeleted,
          monthly: {},
        };
        // 멤버 객체가 생성될 때 Map에 등록
        this.memberMap.set(pmKey, proj.members[pmKey]);
      }

      const member = proj.members[pmKey];

      const dC = this.draftValues[`${item.CompositeKey}_contract`];
      const dA = this.draftValues[`${item.CompositeKey}_actual`];
      const contractVal = dC !== undefined ? dC : (item.ContractMM || 0);
      const actualVal = dA !== undefined ? dA : (item.ActualMM || 0);

      // 3. 화면에 표시될 최신 상태값을 변수에 담습니다.
      const currentCellData = {
        compositeKey: item.CompositeKey,
        contract: dC !== undefined ? dC : item.ContractMM,
        actual: dA !== undefined ? dA : item.ActualMM,
        isDirty: dC !== undefined || dA !== undefined,
        isSyncEnabled: item.ActualMM === item.ContractMM,
      };

      this.cellMap.set(item.CompositeKey, currentCellData);
      member.monthly[month] = currentCellData;


      const totalIdx = this.monthNums.indexOf(month);
      if (totalIdx !== -1) {
        proj.monthlyTotals[totalIdx].contractTotal =
          Math.round((proj.monthlyTotals[totalIdx].contractTotal + contractVal) * 100) / 100;
        proj.monthlyTotals[totalIdx].actualTotal =
          Math.round((proj.monthlyTotals[totalIdx].actualTotal + actualVal) * 100) / 100;
      }
    });

    return Object.values(projectMap).map(p => ({
      ...p,
      memberList: Object.values(p.members)
        .filter(m => m.memberId !== 'NONE')
        .map(m => ({
        ...m,
        isDeleted: m.isDeleted, // 부모가 준 플래그
        rowClass: m.isDeleted ? 'row-deleted' : '', // CSS에서 .row-deleted { opacity: 0.5; ... }
        nameWrapperClass: m.isDeleted ? 'name-strikethrough' : '', // 취소선 스타일
        cells: this.monthNums.map(n => {
          const cellData = m.monthly[n] || { contract: 0, actual: 0 };
          return {
            ...cellData,
            contract: this.inputCache.has(`${cellData.compositeKey}_contract`)
              ? this.inputCache.get(`${cellData.compositeKey}_contract`)
              : cellData.contract,
            actual: this.inputCache.has(`${cellData.compositeKey}_actual`)
              ? this.inputCache.get(`${cellData.compositeKey}_actual`)
              : cellData.actual,
            month: n,
            // (전체 그리드가 읽기전용이거나) OR (이 멤버가 삭제 대기 중일 때) true
            isReadOnly: this.isReadOnly || m.isDeleted
          };
        })
      })),
      // 소계 값 소수점 한자리 고정
      monthlyTotals: p.monthlyTotals.map(t => ({
        ...t,
        contractTotal: t.contractTotal.toFixed(1),
        actualTotal: t.actualTotal.toFixed(1)
      }))
    }));
  }

  handleDeleteMemberClick(event) {
    const { pmKey, projectId } = event.target.dataset;

    // 삭제 전 사용자 확인 (선택 사항)
    if (confirm('이 멤버를 프로젝트에서 제외하시겠습니까?\n(저장 버튼을 눌러야 최종 반영됩니다.)')) {
      this.dispatchDashboardAction('MEMBER_DELETE', {
        pmKey: pmKey,
        projectId: projectId
      });
    }
  }

  handleRestoreMemberClick(event) {
    const { pmKey, projectId } = event.target.dataset;
    this.dispatchDashboardAction('MEMBER_RESTORE', {
      pmKey: pmKey,
      projectId: projectId
    });
  }

  // 공통 액션 발송 함수
  dispatchDashboardAction(type, payload) {
    this.dispatchEvent(new CustomEvent('dashboardaction', {
      detail: { type, payload },
      bubbles: true,
      composed: true
    }));
  }

  async handleMemberClick(event) {
    const { pmId, pmKey, projectId, projectName } = event.currentTarget.dataset;

    const member = this.findMemberByKey(pmKey);
    if (!member) return;

    // 모달 오픈 (수정/교체 모드 전용 파라미터 전달)
    const result = await AddMemberModal.open({
      size: 'large',
      projectId: projectId,
      projectName: projectName,
      currentYear: this.currentYear,
      isSwapMode: true,
      oldPmKey: pmKey,
      pmName: member.name,
      // 이제 member 객체에서 안전하게 꺼내올 수 있습니다.
      oldRole: member.role,
      oldGrade: member.grade,
      oldEmployeeId: member.memberId
    });

    if (result && result.status === 'success') {
      // 부모(Dashboard)에게 'MEMBER_SWAP' 액션 전송
      this.dispatchDashboardAction('MEMBER_SWAP', {
        ...result.payload,
        oldPmKey: pmKey // 어떤 녀석을 바꿀지 알려줌
      });
    }
  }

  // 1. 셀 수정 시
  // handleInputChange(event) {
  //   const { key, type } = event.target.dataset;
  //   const value = parseFloat(event.target.value) || 0;
  //
  //   // 1. 기본 변경 사항 이벤트 발생
  //   this.dispatchDashboardAction('CELL_UPDATE', {
  //     draftKey: `${key}_${type}`,
  //     value: value
  //   });
  //
  //   // 2. 스마트 동기화 로직
  //   if (type === 'contract') {
  //     // 현재 화면 데이터(formattedData)에서 해당 셀의 동기화 가능 여부 확인
  //     const targetCell = this.findCellByKey(key);
  //
  //     // 동기화가 활성화된 상태라면 실제 공수(actual)도 같이 업데이트
  //     if (targetCell && targetCell.isSyncEnabled) {
  //       this.dispatchDashboardAction('CELL_UPDATE', {
  //         draftKey: `${key}_actual`,
  //         value: value
  //       });
  //     }
  //   } else if (type === 'actual') {
  //     // 실제 공수를 직접 수정하는 경우, 해당 셀의 isSyncEnabled를 수동으로 제어하기 위해
  //     // 필요한 경우 부모에게 알리거나 별도 플래그를 관리해야 합니다.
  //     // 현재 구조에서는 다시 로드되지 않는 한 isSyncEnabled는 formattedData 단계에서 계산됩니다.
  //   }
  // }

  handleKeyDown(event) {
    const allowKeys = [
      'Backend', 'Backspace', 'Delete', 'Tab', 'Escape', 'Enter',
      'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', '.'
    ];

    // 1. 방향키 위/아래 로직 (기존 유지)
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      let currentValue = parseFloat(event.target.value) || 0;
      const step = 0.1;

      if (event.key === 'ArrowUp') {
        // 현재 값이 1보다 크면 즉시 1로, 아니면 0.1 더하기 (최대 1)
        if (currentValue >= 1) {
          currentValue = 1;
        } else {
          currentValue = Math.min(1, (currentValue + step).toFixed(1));
        }
      } else if (event.key === 'ArrowDown') {
        // 현재 값이 1보다 크면 즉시 1로, 0보다 작으면 즉시 0으로, 아니면 0.1 빼기
        if (currentValue > 1) {
          currentValue = 1;
        } else if (currentValue <= 0) {
          currentValue = 0;
        } else {
          currentValue = Math.max(0, (currentValue - step).toFixed(1));
        }
      }
      event.target.value = currentValue;
      this.handleInputChange(event); // 변경사항 반영
      return;
    }

    // 2. 숫자 및 허용된 특수키 외에는 모두 차단
    // event.key가 숫자가 아니고, allowKeys 리스트에도 없으면 입력을 막음
    if (!/^[0-9]$/.test(event.key) && !allowKeys.includes(event.key)) {
      event.preventDefault();
    }

    // 3. 마침표(.)가 이미 있는데 또 찍으려고 하면 차단
    if (event.key === '.' && event.target.value.includes('.')) {
      event.preventDefault();
    }
  }

  handleInputChange(event) {
    const { key, type } = event.target.dataset;
    const cacheKey = `${key}_${type}`;
    let rawValue = event.target.value;

    // 1. 숫자와 마침표 이외의 문자 즉시 제거
    rawValue = rawValue.replace(/[^0-9.]/g, '');

    if (rawValue.length > 1 && rawValue.startsWith('0') && rawValue[1] !== '.') {
      rawValue = rawValue.substring(1); // 앞의 '0'을 제거하여 "1", "5"로 만듦
    }

    // 2. 소수점 중복 입력 방지
    const parts = rawValue.split('.');
    if (parts.length > 2) {
      rawValue = parts[0] + '.' + parts[1];
    }

    // 3. [추가] 소수점 첫째 자리까지만 허용 (둘째 자리 이상 입력 방지)
    // 소수점이 있다면, 소수점 뒤의 글자 수를 1개로 제한
    if (parts.length === 2 && parts[1].length > 1) {
      rawValue = parts[0] + '.' + parts[1].substring(0, 1);
    }

    // 4. [추가] 전체 길이를 3자리로 제한 (예: "0.5", "1.0" 등)
    // 단, "0." 처럼 입력 중인 상태는 허용해야 하므로 숫자 완성 시점을 고려
    if (rawValue.length > 3) {
      rawValue = rawValue.substring(0, 3);
    }

    // 화면의 Input 값을 정제된 값으로 강제 업데이트
    event.target.value = rawValue;

    // 1. 소수점 입력을 방해하지 않도록 캐시에 문자열로 저장
    this.inputCache.set(cacheKey, rawValue);
    this.inputCache = new Map(this.inputCache);

    // 2. 숫자 변환 및 부모 전송 (부모는 숫자로 관리)
    const numValue = parseFloat(rawValue) || 0;
    this.dispatchDashboardAction('CELL_UPDATE', { draftKey: cacheKey, value: numValue });

    // 3. 스마트 동기화 (화면 값만 복사)
    if (type === 'contract') {
      const targetCell = this.findCellByKey(key);
      if (targetCell && targetCell.isSyncEnabled) {
        this.inputCache.set(`${key}_actual`, rawValue);
        this.inputCache = new Map(this.inputCache);
        this.dispatchDashboardAction('CELL_UPDATE', { draftKey: `${key}_actual`, value: numValue });

        const actualInput = this.template.querySelector(`input[data-key="${key}"][data-type="actual"]`);
        if (actualInput) actualInput.value = rawValue;
      }
    }
  }

  // 2. 멤버 추가 모달 결과 수신 시
  async handleAddMemberClick(event) {
    const { projectId, projectName } = event.target.dataset;

    // 모달 오픈
    const result = await AddMemberModal.open({
      size: 'large',
      // 모달 내부로 전달할 데이터
      projectId: projectId,
      projectName: projectName,
      currentYear: this.currentYear
    });

    // 모달이 닫힌 후 (this.close(데이터) 호출 시) 처리 로직
    if (result && result.status === 'success') {
      this.dispatchDashboardAction('MEMBER_ADD', result.payload);
    }
  }

  // 현재 데이터 구조에서 특정 키에 해당하는 셀 정보를 찾는 헬퍼 함수
  findCellByKey(key) {
    return this.cellMap.get(key) || null;
  }

  /** 헬퍼 함수: pmKey로 멤버 객체 검색 */
  findMemberByKey(pmKey) {
    return this.memberMap.get(pmKey) || null;
  }

  // 포커스가 빠질 때만 잠금을 해제
  handleBlur(event) {
    const { key, type } = event.target.dataset;
    const cacheKey = `${key}_${type}`;
    let rawValue = event.target.value;

    // 포커스 아웃 시 빈 값이면 0으로 채움
    if (!rawValue || rawValue.trim() === '' || rawValue === '.') {
      this.dispatchDashboardAction('CELL_UPDATE', { draftKey: cacheKey, value: 0 });
    }

    // 캐시 삭제 및 리렌더링
    this.inputCache.delete(cacheKey);
    if (type === 'contract') this.inputCache.delete(`${key}_actual`);
    this.inputCache = new Map(this.inputCache);
  }
}