public with sharing class WorkdayConfigValidator {

    @InvocableMethod(
        label='Validate Workday Configuration'
        description='Validates Workday configuration settings against best practices and returns errors and recommendations'
    )
    public static List<ValidationResult> validateConfiguration(List<ValidationRequest> requests) {
        List<ValidationResult> results = new List<ValidationResult>();
        for (ValidationRequest req : requests) {
            ValidationResult result = new ValidationResult();
            result.isValid = true;
            result.validationErrors = '';
            result.recommendations = '';
            if (String.isBlank(req.configType)) {
                result.isValid = false;
                result.validationErrors = 'configType is required';
                results.add(result);
                continue;
            }
            String configType = req.configType.toLowerCase();
            if (configType == 'security') {
                validateSecurityConfig(req, result);
            } else if (configType == 'business_process') {
                validateBusinessProcessConfig(req, result);
            } else if (configType == 'integration') {
                validateIntegrationConfig(req, result);
            } else {
                result.recommendations = 'Review Workday configuration best practices documentation for the ' + req.configType + ' configuration type.';
            }
            results.add(result);
        }
        return results;
    }

    private static void validateSecurityConfig(ValidationRequest req, ValidationResult result) {
        List<String> errors = new List<String>();
        if (String.isNotBlank(req.configData)) {
            String data = req.configData.toLowerCase();
            if (data.contains('all users') || data.contains('everyone')) {
                errors.add('Avoid granting broad access to all users — apply principle of least privilege.');
            }
            if (data.contains('super admin') || data.contains('full access')) {
                errors.add('Super admin / full access roles should be restricted to minimal users.');
            }
        }
        if (!errors.isEmpty()) {
            result.isValid = false;
            result.validationErrors = String.join(errors, ' | ');
        }
        result.recommendations = 'Best practices: Follow principle of least privilege. Regularly audit security group memberships. ' +
            'Use role-based access over direct assignments. Review intersecting security groups for unintended permissions. ' +
            'Document all security group changes with a business justification.';
    }

    private static void validateBusinessProcessConfig(ValidationRequest req, ValidationResult result) {
        result.recommendations = 'Best practices: Validate all business process step transitions have defined actions. ' +
            'Ensure approval chains have active approvers with backup delegates. ' +
            'Verify notification recipients are active workers. ' +
            'Test business process with a sandbox or test tenant before activating in production.';
    }

    private static void validateIntegrationConfig(ValidationRequest req, ValidationResult result) {
        List<String> errors = new List<String>();
        if (String.isNotBlank(req.configData)) {
            String data = req.configData.toLowerCase();
            if (data.contains('http:') && !data.contains('https:')) {
                errors.add('Use HTTPS endpoints only — HTTP is not secure for Workday integrations.');
            }
        }
        if (!errors.isEmpty()) {
            result.isValid = false;
            result.validationErrors = String.join(errors, ' | ');
        }
        result.recommendations = 'Best practices: Always use HTTPS endpoints. Store credentials in Workday Integration System User, not hardcoded. ' +
            'Configure retry logic for transient failures. ' +
            'Test integration with Workday sandbox before activating. ' +
            'Set up monitoring and alerting for integration failures.';
    }

    public class ValidationRequest {
        @InvocableVariable(
            required=true
            label='Config Type'
            description='Type of configuration to validate: security, business_process, or integration'
        )
        public String configType;

        @InvocableVariable(
            required=false
            label='Config Data'
            description='JSON or text representation of the configuration settings to validate'
        )
        public String configData;

        @InvocableVariable(
            required=false
            label='Workday Module'
            description='The Workday module being configured (e.g., HCM, Financials, Integration)'
        )
        public String workdayModule;
    }

    public class ValidationResult {
        @InvocableVariable(label='Is Valid' description='True if configuration passes all validation checks')
        public Boolean isValid;

        @InvocableVariable(label='Validation Errors' description='Pipe-delimited list of validation errors found')
        public String validationErrors;

        @InvocableVariable(label='Recommendations' description='Best practice recommendations for this configuration type')
        public String recommendations;
    }
}
