/**
 * @Author            : jh.jung
 * @Description     :
 * @Target            :
 * @Modification Log
 Ver      Date            Author           Modification
 ===================================================================================
 1.0      2026-01-20      jh.jung           Created
 */
import { LightningElement, api, track } from 'lwc';

export default class PmsBusinessUnitSummaryTable extends LightningElement {
  @api allocations = [];
  @api currentHalf;
  @api headerLabel = '';

  @track isExpanded = true;
  _processedData = null; // 계산된 데이터 캐시 변수

  // allocations 데이터가 부모로부터 새로 들어오면 캐시를 초기화합니다.
  @api
  get allocationsData() {
    return this.allocations;
  }

  // Setter: 부모로부터 데이터가 들어올 때 호출됨
  set allocationsData(value) {
    this.allocations = value;
    this._processedData = null; // 데이터가 바뀌면 캐시 초기화
  }

  get monthNums() {
    return this.currentHalf === 'H1' ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] : [1, 2, 3, 4, 5, 6];
  }

  get monthLabels() {
    return this.monthNums.map(m => `${m}월`);
  }

  get toggleIcon() {
    return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
  }

  // 토글 시 CSS 클래스만 변경 (성능 최적화 핵심)
  get tbodyClass() {
    return this.isExpanded ? 'animate-fade-in' : 'slds-hide';
  }

  handleToggle() {
    this.isExpanded = !this.isExpanded;
  }

  /** 전체 데이터를 가공하여 팀 리스트와 합계를 반환 */
  get processedData() {
    // 캐시된 데이터가 있으면 즉시 반환하여 연산 낭비 방지
    if (this._processedData) return this._processedData;
    if (!this.allocations || this.allocations.length === 0) return null;

    const teamMap = {};
    const totalRaw = { name: '본부 전체 합계', isTotal: true, memberIds: new Set(), colC: {}, colA: {} };

    this.allocations.forEach(item => {
      const month = item.Month;
      if (!this.monthNums.includes(month)) return;

      if (!teamMap[item.TeamId]) {
        teamMap[item.TeamId] = { id: item.TeamId, name: item.TeamName, memberIds: new Set(), colC: {}, colA: {} };
      }

      const team = teamMap[item.TeamId];
      team.memberIds.add(item.MemberId);
      team.colC[month] = (team.colC[month] || 0) + (item.ContractMM || 0);
      team.colA[month] = (team.colA[month] || 0) + (item.ActualMM || 0);

      totalRaw.memberIds.add(item.MemberId);
      totalRaw.colC[month] = (totalRaw.colC[month] || 0) + (item.ContractMM || 0);
      totalRaw.colA[month] = (totalRaw.colA[month] || 0) + (item.ActualMM || 0);
    });

    const formatRow = (data) => {
      const mCount = data.memberIds.size;
      const monthCount = this.monthNums.length;
      const tCapacity = mCount * monthCount;
      const grandC = Object.values(data.colC).reduce((a, b) => a + b, 0);
      const grandA = Object.values(data.colA).reduce((a, b) => a + b, 0);

      return {
        ...data,
        memberCount: mCount,
        totalCapacity: tCapacity,
        monthly: this.monthNums.map(m => {
          const c = data.colC[m] || 0;
          const a = data.colA[m] || 0;
          const cUtil = mCount > 0 ? Math.round((c / mCount) * 100 * 10) / 10 : 0;
          const aUtil = mCount > 0 ? Math.round((a / mCount) * 100 * 10) / 10 : 0;
          return {
            month: m,
            c: c.toFixed(1),
            a: a.toFixed(1),
            cUtil: cUtil,
            aUtil: aUtil,
            aUtilClass: aUtil > 100 ? 'slds-text-color_error slds-text-title_bold' : 'util-bold'
          };
        }),
        grandTotal: {
          c: grandC.toFixed(1),
          a: grandA.toFixed(1),
          cUtil: tCapacity > 0 ? Math.round((grandC / tCapacity) * 100 * 10) / 10 : 0,
          aUtil: tCapacity > 0 ? Math.round((grandA / tCapacity) * 100 * 10) / 10 : 0,
          aUtilClass: (grandA / tCapacity) > 1 ? 'slds-text-color_error' : ''
        }
      };
    };

    this._processedData = {
      teams: Object.values(teamMap).map(t => formatRow(t)),
      total: formatRow(totalRaw)
    };

    return this._processedData;
  }
}