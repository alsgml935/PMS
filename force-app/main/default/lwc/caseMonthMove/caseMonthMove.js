import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getCurrentCaseMonth from '@salesforce/apex/caseMonthMoveController.getCurrentCaseMonth';
import checkMonthRecord from '@salesforce/apex/caseMonthMoveController.checkMonthRecord';
import updateCaseMonth from '@salesforce/apex/caseMonthMoveController.updateCaseMonth';

export default class caseMonthMove extends LightningElement {
    @track isSaveDisabled = true;
    _recordId; 
    
    currentYear = null;      // 사례의 현재 연도
    currentMonth = null;     // 사례의 현재 월
    selectedMonth = null;
    selectedYear = null;
    selectedMonthRecordId = null;
    isLoading = false;
    accountId = null;           //사례의 accountId

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        
        // recordId가 설정되면 바로 현재 월 정보 로드
        if (value) {
            this.isSaveDisabled = true;
            this.loadCurrentMonth();
        }
    }

    @track months = [
        { label: '1월', value: '01', cssClass: 'month-box' },
        { label: '2월', value: '02', cssClass: 'month-box' },
        { label: '3월', value: '03', cssClass: 'month-box' },
        { label: '4월', value: '04', cssClass: 'month-box' },
        { label: '5월', value: '05', cssClass: 'month-box' },
        { label: '6월', value: '06', cssClass: 'month-box' },
        { label: '7월', value: '07', cssClass: 'month-box' },
        { label: '8월', value: '08', cssClass: 'month-box' },
        { label: '9월', value: '09', cssClass: 'month-box' },
        { label: '10월', value: '10', cssClass: 'month-box' },
        { label: '11월', value: '11', cssClass: 'month-box' },
        { label: '12월', value: '12', cssClass: 'month-box' }
    ];


    async loadCurrentMonth() {
        this.isLoading = true;
        
        try {
            const result = await getCurrentCaseMonth({ 
                caseId: this.recordId 
            });
            
            if (result.success) {
                this.currentYear = parseInt(result.year, 10);
                this.currentMonth = parseInt(result.month, 10);
                this.accountId = result.caseAccountId;

                this.updateMonthClasses();
            } else {
                this.showToast('알림', result.message, 'warning');
                this.isSaveDisabled = true;
            }
            
        } catch (error) {
            this.showToast('오류', '시스템 오류가 발생했습니다.', 'error');
            this.isSaveDisabled = true;
            console.error('Error loading current month:', error);
        } finally {
            this.isLoading = false;
        }
    }

    updateMonthClasses() {
        this.months = this.months.map(m => {
            const monthNum = parseInt(m.value, 10);
            let cssClass = 'month-box';
            
            // 선택된 월이 없고 현재 월에 current 클래스 추가
            if (!this.selectedMonth && this.currentMonth && monthNum === this.currentMonth) {
                cssClass += ' current';
            }
            // 월 선택 시 
            else if (this.selectedMonth && m.value === this.selectedMonth) {
                cssClass += ' selected';
            }
            
            return { ...m, cssClass };
        });
    }

   //월 클릭
    async handleMonthClick(event) {
        if (!this.currentYear || !this.currentMonth) {
            return;
        }
        
        const clickedMonth = event.currentTarget.dataset.month;
        const targetYear = this.getTargetYear(clickedMonth);
        
        console.log('targetYear:', targetYear, typeof targetYear);
        
        this.isLoading = true;
        try {

            const result = await checkMonthRecord({ 
                year: String(targetYear),  // 2024 → "2024"
                month: String(parseInt(clickedMonth, 10)),  // "08" → "8"
                accountId: this.accountId
            });
            
            console.log('⭐ result:', result);
            
            if (!result.exists) {
                this.showToast(
                    '알림', 
                    `${targetYear}년 ${parseInt(clickedMonth)}월에 해당하는 운영지원(월) 레코드가 존재하지 않습니다.`, 
                    'warning'
                );
                return;
            }

           if(this.currentYear === targetYear && 
                parseInt(this.currentMonth, 10) === parseInt(clickedMonth, 10)){

                    this.selectedMonth = null;
                    this.selectedYear = null;
                    this.selectedMonthRecordId = null;
                    this.isSaveDisabled = true;

                    this.updateMonthClasses();

                    this.showToast(
                        '알림', 
                        `기존의 운영지원(월)과 같은 월을 선택하셨습니다.`, 
                        'warning'
                    );
                    return;
            }
            
            // 검증 통과
            this.selectedMonth = clickedMonth;
            this.selectedYear = targetYear;
            this.selectedMonthRecordId = result.recordId;

            this.isSaveDisabled = false;

            this.updateMonthClasses();
        } catch (error) {
            this.showToast('오류', '월 확인 중 오류가 발생했습니다.', 'error');
            console.error('Error checking month:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // 대상 연도 계산
    getTargetYear(selectedMonth) {
        const selectedMonthNum = parseInt(selectedMonth, 10);
        const currentYear = parseInt(this.currentYear, 10); 
        const currentMonth = parseInt(this.currentMonth, 10);
        
        if (selectedMonthNum < currentMonth) {
            return currentYear + 1; 
        } else {
            return currentYear;
        }
    }

    //취소버튼
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    //저장버튼
    async handleSave() {
        if (!this.selectedMonth || !this.selectedMonthRecordId) {
            this.showToast('알림', '월을 선택해주세요.', 'warning');
            return;
        }

        this.isLoading = true;

        try {
            await updateCaseMonth({ 
                caseId: this.recordId, 
                monthRecordId: this.selectedMonthRecordId 
            });

            this.showToast('성공', '월 이동이 완료되었습니다.', 'success');
            
            // Quick Action 닫기
            this.dispatchEvent(new CloseActionScreenEvent());

            setTimeout(() => {
                location.reload();
            }, 500);

        } catch (error) {
            this.showToast(
                '오류', 
                error.body?.message || '월 이동 중 오류가 발생했습니다.', 
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ 
            title, 
            message, 
            variant 
        }));
    }
}