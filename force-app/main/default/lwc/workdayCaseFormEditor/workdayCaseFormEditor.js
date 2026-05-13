import { LightningElement, api } from 'lwc';

export default class WorkdayCaseFormEditor extends LightningElement {
    @api admin_name = '';
    @api ai_summary = '';
    @api issue_summary = '';
    @api issue_type = '';
    @api workday_module = '';
    @api priuser_priority = '';
    @api user_product_area = '';

    get issueTypeOptions() {
        return [
            { label: 'Troubleshooting', value: 'Troubleshooting' },
            { label: 'Configuration', value: 'Configuration' },
            { label: 'Other', value: 'Other' }
        ];
    }

    get workdayModuleOptions() {
        return [
            { label: 'HCM', value: 'HCM' },
            { label: 'Financials', value: 'Financials' },
            { label: 'Payroll', value: 'Payroll' },
            { label: 'Time Tracking', value: 'Time Tracking' },
            { label: 'Integration', value: 'Integration' },
            { label: 'Analytics', value: 'Analytics' },
            { label: 'Security', value: 'Security' }
        ];
    }

    get priorityOptions() {
        return [
            { label: 'Critical', value: 'Critical' },
            { label: 'High', value: 'High' },
            { label: 'Medium', value: 'Medium' }
        ];
    }

    get productAreaOptions() {
        return [
            { label: 'Integration', value: 'Integration' },
            { label: 'Security', value: 'Security' },
            { label: 'Reporting', value: 'Reporting' },
            { label: 'Configuration', value: 'Configuration' },
            { label: 'Performance', value: 'Performance' },
            { label: 'Data Management', value: 'Data Management' },
            { label: 'User Management', value: 'User Management' },
            { label: 'Other', value: 'Other' }
        ];
    }

    handleSubjectChange(event) {
        this.subject = event.detail.value;
    }

    handleIssueTypeChange(event) {
        this.issueType = event.detail.value;
    }

    handleWorkdayModuleChange(event) {
        this.workdayModule = event.detail.value;
    }

    handlePriorityChange(event) {
        this.priority = event.detail.value;
    }

    handleProductAreaChange(event) {
        this.productArea = event.detail.value;
    }

    handleSubmit() {
        const subjectInput = this.template.querySelector('lightning-input[label="Subject"]');
        if (!subjectInput.reportValidity()) {
            return;
        }

        this.dispatchEvent(new CustomEvent('submit', {
            detail: {
                issue_summary: this.issue_summary,
                issue_type: this.issue_type,
                workday_module: this.workday_module,
                user_priority: this.user_priority,
                user_product_area: this.user_product_area,
                admin_name: this.admin_name,
                ai_summary: this.ai_summary
            }
        }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}