/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2026-01-06      jh.jung           Created
 */

import {api, LightningElement} from 'lwc';

export default class PmsTeamViewGrid extends LightningElement {
  @api allocations = [];
  @api currentHalf;

  @api targetMemberId; // 추가: 모달에서 검색된 특정 멤버 ID
  @api hideTeamHeader = false; // 추가: 모달에서 팀 헤더를 숨기고 싶을 때

  get monthNums() {
    // return this.currentHalf === 'H1' ? [1, 2, 3, 4, 5, 6] : [7, 8, 9, 10, 11, 12];
    return this.currentHalf === 'H1' ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] : [1, 2, 3, 4, 5, 6];
  }

  get monthLabels() {
    return this.monthNums.map(m => `${m}월`);
  }

  get formattedData() {
    if (!this.allocations) return [];

    const teamMap = {};

    this.allocations.forEach(item => {

      // targetMemberId가 있을 경우 해당 멤버가 아니면 skip (필터링)
      if (this.targetMemberId && item.MemberId !== this.targetMemberId) {
        return;
      }

      // const month = new Date(item.TargetMonth).getMonth() + 1;
      const month = item.Month;
      if (!this.monthNums.includes(month)) return;

      // 1. 팀 그룹화
      if (!teamMap[item.TeamId]) {
        teamMap[item.TeamId] = {
          id: item.TeamId,
          name: item.TeamName,
          members: {},
          colContractTotals: {}, // 열 계약 합계
          colActualTotals: {},    // 열 실제 합계
          memberIds: new Set(), // 팀 인원수를 세기 위한 고유 ID Set
        };
      }

      // 2. 멤버 그룹화
      if (!teamMap[item.TeamId].members[item.MemberId]) {
        teamMap[item.TeamId].members[item.MemberId] = {
          id: item.MemberId,
          name: item.MemberName,
          role: item.JobDesc,
          projectList: [],
          projectNames: new Set(),
          monthly: {},
          rowContractTotal: 0, // 행 계약 합계
          rowActualTotal: 0    // 행 실제 합계
        };
      }

      const member = teamMap[item.TeamId].members[item.MemberId];
      const team = teamMap[item.TeamId];
      team.memberIds.add(item.MemberId); // 인원수 카운트용 추가

      // 왼쪽 프로젝트 리스트에는 '한 번이라도 투입이 있는' 프로젝트만 등록
      if (!member.projectNames.has(item.ProjectName)) {
        member.projectNames.add(item.ProjectName);
        member.projectList.push({ id: item.ProjectId, name: item.ProjectName });
      }

      // 3. 월별 데이터 초기화
      if (!member.monthly[month]) {
        member.monthly[month] = { projects: [], totalContract: 0, totalActual: 0 };
      }

      // 공수가 없으면 isMM = false
      member.monthly[month].projects.push({
        id: item.ProjectId,
        name: item.ProjectName,
        contract: item.ContractMM.toFixed(1),
        actual: item.ActualMM.toFixed(1),
        isMM: (item.ContractMM > 0 || item.ActualMM > 0)
      });

      // 데이터 누적 (Contract & Actual)
      member.monthly[month].totalContract += item.ContractMM;
      member.monthly[month].totalActual += item.ActualMM;

      member.rowContractTotal += item.ContractMM;
      member.rowActualTotal += item.ActualMM;

      if (!team.colContractTotals[month]) team.colContractTotals[month] = 0;
      if (!team.colActualTotals[month]) team.colActualTotals[month] = 0;

      team.colContractTotals[month] += item.ContractMM;
      team.colActualTotals[month] += item.ActualMM;
    });

    return Object.values(teamMap).map(team => {
      const memberCount = team.memberIds.size;
      const monthCount = this.monthNums.length; // 현재 화면에 표시되는 월의 개수 (6 또는 12)
      // Grand Total의 분모가 될 총 가용 자원 (인원수 * 개월수)
      const totalCapacity = memberCount * monthCount;

      // 팀 전체 총계 계산
      const totalC = Object.values(team.colContractTotals).reduce((a, b) => a + b, 0);
      const totalA = Object.values(team.colActualTotals).reduce((a, b) => a + b, 0);

      return {
        ...team,
        memberCount: memberCount,
        totalCapacity: totalCapacity,
        // 전체 총계용 데이터 추가
        grandTotal: {
          contract: totalC.toFixed(1),
          actual: totalA.toFixed(1),
          cUtil: totalCapacity > 0 ? Math.round((totalC / totalCapacity) * 100 * 10) / 10 : 0,
          aUtil: totalCapacity > 0 ? Math.round((totalA / totalCapacity) * 100 * 10) / 10 : 0,
          aUtilClass: (totalA / totalCapacity) > 1 ? 'slds-text-color_error' : ''
        },
        colTotalsData: this.monthNums.map(m => {
          const cTotal = team.colContractTotals[m] || 0;
          const aTotal = team.colActualTotals[m] || 0;
          return {
            month: m,
            contract: cTotal.toFixed(1),
            actual: aTotal.toFixed(1),
            cUtil: memberCount > 0 ? Math.round((cTotal / memberCount) * 100 * 10) / 10 : 0,
            aUtil: memberCount > 0 ? Math.round((aTotal / memberCount) * 100 * 10) / 10 : 0
          };
        }),

        memberList: Object.values(team.members).map(mem => ({
          ...mem,
          rowContractTotal: mem.rowContractTotal.toFixed(1),
          rowActualTotal: mem.rowActualTotal.toFixed(1),
          monthlyData: this.monthNums.map(m => {
            const data = mem.monthly[m] || {projects: [], totalActual: 0};
            return {
              month: m,
              projects: data.projects,
              // 셀 전체 배경색을 결정하는 클래스
              cellClass: `cell-mm-data ${this.getHeatmapClass(data.totalActual)}`
            };
          })
        }))
      }
    });
  }

  // 합계 수치에 따른 배경색 결정
  getHeatmapClass(actual) {
    if (actual === 0) return 'status-none';
    if (actual < 0.3) return 'status-low';      // 저가동 (하늘색)
    if (actual <= 0.7) return 'status-normal';  // 적정 (초록색)
    return 'status-over';                       // 과부하 (빨간색)
  }
}