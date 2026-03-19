public with sharing class CaseFieldPredictor {

    @InvocableMethod(
        label='Predict Case Fields'
        description='Predicts Priority and Product Area from conversation transcript for accurate routing to the correct NSC or Analyst'
    )
    public static List<PredictionResult> predictFields(List<PredictionRequest> requests) {
        List<PredictionResult> results = new List<PredictionResult>();
        for (PredictionRequest req : requests) {
            PredictionResult result = new PredictionResult();
            String combined = buildCombinedText(req);
            result.predictedPriority = predictPriority(combined);
            result.predictedProductArea = predictProductArea(combined, req.workdayModule);
            result.confidence = assessConfidence(combined);
            results.add(result);
        }
        return results;
    }

    private static String buildCombinedText(PredictionRequest req) {
        String text = '';
        if (String.isNotBlank(req.transcript)) {
            text += req.transcript.toLowerCase() + ' ';
        }
        if (String.isNotBlank(req.issueSummary)) {
            text += req.issueSummary.toLowerCase() + ' ';
        }
        if (String.isNotBlank(req.issueType)) {
            text += req.issueType.toLowerCase() + ' ';
        }
        return text;
    }

    private static String predictPriority(String text) {
        // Critical: system down, data loss, blocking production operations
        List<String> criticalKeywords = new List<String>{
            'down', 'outage', 'blocked', 'cannot access', 'cant access',
            'critical', 'emergency', 'data loss', 'production issue',
            'not processing', 'employees cant', 'payroll not', 'system unavailable',
            'complete failure', 'no one can', 'entire', 'all users affected'
        };
        for (String keyword : criticalKeywords) {
            if (text.contains(keyword)) {
                return 'Critical';
            }
        }
        // High: errors, broken functionality, significant impact
        List<String> highKeywords = new List<String>{
            'error', 'broken', 'failing', 'not working', 'failed',
            'unable to', 'incorrect', 'wrong data', 'missing data',
            'keeps crashing', 'keeps failing', 'urgent', 'impacting'
        };
        for (String keyword : highKeywords) {
            if (text.contains(keyword)) {
                return 'High';
            }
        }
        // Medium: guidance, how-to, configuration questions
        return 'Medium';
    }

    private static String predictProductArea(String text, String workdayModule) {
        // Module override takes priority
        if (String.isNotBlank(workdayModule)) {
            if (workdayModule == 'Integration') return 'Integration';
            if (workdayModule == 'Analytics') return 'Reporting';
        }
        // Keyword-based area prediction
        if (text.contains('integration') || text.contains(' api ') || text.contains('connector') ||
            text.contains('sync') || text.contains('eci ') || text.contains('web service')) {
            return 'Integration';
        }
        if (text.contains('security group') || text.contains('permission') || text.contains('access denied') ||
            text.contains('unauthorized') || text.contains('security policy')) {
            return 'Security';
        }
        if (text.contains('report') || text.contains('dashboard') || text.contains('analytics') ||
            text.contains('data export') || text.contains('pivot') || text.contains('prism')) {
            return 'Reporting';
        }
        if (text.contains('configure') || text.contains('configuration') || text.contains('business process') ||
            text.contains('workflow') || text.contains('setup') || text.contains('tenant') || text.contains('bp ')) {
            return 'Configuration';
        }
        if (text.contains('slow') || text.contains('timeout') || text.contains('performance') ||
            text.contains('load time') || text.contains('taking too long') || text.contains('hung')) {
            return 'Performance';
        }
        if (text.contains('import') || text.contains('migration') || text.contains('bulk') ||
            text.contains('data load') || text.contains('elt ') || text.contains('etl ')) {
            return 'Data Management';
        }
        if (text.contains('user') || text.contains('employee') || text.contains('worker profile') ||
            text.contains('hire') || text.contains('terminate') || text.contains('onboarding')) {
            return 'User Management';
        }
        return 'Other';
    }

    private static String assessConfidence(String text) {
        if (text.length() > 200) {
            return 'High';
        } else if (text.length() > 50) {
            return 'Medium';
        }
        return 'Low';
    }

    public class PredictionRequest {
        @InvocableVariable(
            required=false
            label='Transcript'
            description='Full conversation transcript from the Agentforce session'
        )
        public String transcript;

        @InvocableVariable(
            required=false
            label='Issue Summary'
            description='Concise summary of the customer issue captured during the session'
        )
        public String issueSummary;

        @InvocableVariable(
            required=false
            label='Issue Type'
            description='Issue type as categorised during the session'
        )
        public String issueType;

        @InvocableVariable(
            required=false
            label='Workday Module'
            description='Workday module affected (HCM, Financials, Payroll, etc.)'
        )
        public String workdayModule;
    }

    public class PredictionResult {
        @InvocableVariable(
            label='Predicted Priority'
            description='Auto-predicted case priority: Critical, High, or Medium'
        )
        public String predictedPriority;

        @InvocableVariable(
            label='Predicted Product Area'
            description='Auto-predicted product area for routing to the correct NSC or Analyst'
        )
        public String predictedProductArea;

        @InvocableVariable(
            label='Confidence'
            description='Confidence level of the predictions: High, Medium, or Low'
        )
        public String confidence;
    }
}
