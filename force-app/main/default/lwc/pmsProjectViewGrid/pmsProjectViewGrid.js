/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2026-01-06      jh.jung           Created
 */

import { LightningElement, api } from 'lwc';

export default class PmsProjectViewGrid extends LightningElement {
  @api allocations = [];
  @api currentHalf;
  @api isReadOnly;
  @api draftValues = {};

  get monthNums() { return this.currentHalf === 'H1' ? [1, 2, 3, 4, 5, 6] : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]; }
  get monthLabels() { return this.monthNums.map(m => `${m}월`); }

  get formattedData() {
    const projectMap = {};
    this.allocations.forEach(item => {
      const month = new Date(item.TargetMonth).getMonth() + 1;
      if (!this.monthNums.includes(month)) return;

      if (!projectMap[item.ProjectId]) projectMap[item.ProjectId] = { id: item.ProjectId, name: item.ProjectName, members: {} };
      if (!projectMap[item.ProjectId].members[item.MemberId]) {
        projectMap[item.ProjectId].members[item.MemberId] = { id: item.MemberId, name: item.MemberName, role: item.Role, team: item.TeamName, monthly: {} };
      }

      const dC = this.draftValues[`${item.CompositeKey}_contract`];
      const dA = this.draftValues[`${item.CompositeKey}_actual`];

      projectMap[item.ProjectId].members[item.MemberId].monthly[month] = {
        compositeKey: item.CompositeKey,
        contract: dC !== undefined ? dC : item.ContractMM,
        actual: dA !== undefined ? dA : item.ActualMM,
        isDirty: dC !== undefined || dA !== undefined,
        isSyncEnabled: item.ActualMM === item.ContractMM,
      };
    });

    return Object.values(projectMap).map(p => ({
      ...p,
      memberList: Object.values(p.members).map(m => ({
        ...m,
        cells: this.monthNums.map(n => ({ ...m.monthly[n], month: n }))
      }))
    }));
  }

  handleInputChange(event) {
    const { key, type } = event.target.dataset;
    const value = parseFloat(event.target.value) || 0;

    // 1. 기본 변경 사항 이벤트 발생
    this.sendGridAction(`${key}_${type}`, value);

    // 2. 스마트 동기화 로직
    if (type === 'contract') {
      // 현재 화면 데이터(formattedData)에서 해당 셀의 동기화 가능 여부 확인
      const targetCell = this.findCellByKey(key);

      // 동기화가 활성화된 상태라면 실제 공수(actual)도 같이 업데이트
      if (targetCell && targetCell.isSyncEnabled) {
        this.sendGridAction(`${key}_actual`, value);
      }
    } else if (type === 'actual') {
      // 실제 공수를 직접 수정하는 경우, 해당 셀의 isSyncEnabled를 수동으로 제어하기 위해
      // 필요한 경우 부모에게 알리거나 별도 플래그를 관리해야 합니다.
      // 현재 구조에서는 다시 로드되지 않는 한 isSyncEnabled는 formattedData 단계에서 계산됩니다.
    }
  }

// 공통 이벤트 발송 로직
  sendGridAction(draftKey, value) {
    this.dispatchEvent(new CustomEvent('gridaction', {
      detail: { draftKey, value }
    }));
  }

// 현재 데이터 구조에서 특정 키에 해당하는 셀 정보를 찾는 헬퍼 함수
  findCellByKey(key) {
    for (const project of this.formattedData) {
      for (const member of project.memberList) {
        const cell = member.cells.find(c => c.compositeKey === key);
        if (cell) return cell;
      }
    }
    return null;
  }

  // handleInputChange(event) {
  //   this.dispatchEvent(new CustomEvent('gridaction', {
  //     detail: {
  //       draftKey: `${event.target.dataset.key}_${event.target.dataset.type}`,
  //       value: parseFloat(event.target.value) || 0
  //     }
  //   }));
  // }
}