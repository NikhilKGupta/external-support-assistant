@IsTest
private class CaseRiskScoringBatchTest {

    // ── CaseFieldPredictor Tests ──────────────────────────────────────────────

    @IsTest
    static void testPredictPriorityCritical() {
        CaseFieldPredictor.PredictionRequest req = new CaseFieldPredictor.PredictionRequest();
        req.transcript    = 'The system is completely down and employees cant access payroll';
        req.issueSummary  = 'System outage blocking entire workforce';
        req.workdayModule = 'Payroll';

        Test.startTest();
        List<CaseFieldPredictor.PredictionResult> results =
            CaseFieldPredictor.predictFields(new List<CaseFieldPredictor.PredictionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Critical', results[0].predictedPriority, 'Outage keywords should predict Critical');
    }

    @IsTest
    static void testPredictPriorityHigh() {
        CaseFieldPredictor.PredictionRequest req = new CaseFieldPredictor.PredictionRequest();
        req.transcript    = 'Getting an error when trying to run the report';
        req.issueSummary  = 'Report failing with error code';
        req.workdayModule = 'Analytics';

        Test.startTest();
        List<CaseFieldPredictor.PredictionResult> results =
            CaseFieldPredictor.predictFields(new List<CaseFieldPredictor.PredictionRequest>{ req });
        Test.stopTest();

        System.assertEquals('High', results[0].predictedPriority, 'Error keywords should predict High');
        System.assertEquals('Reporting', results[0].predictedProductArea, 'Analytics module maps to Reporting');
    }

    @IsTest
    static void testPredictPriorityMedium() {
        CaseFieldPredictor.PredictionRequest req = new CaseFieldPredictor.PredictionRequest();
        req.transcript    = 'I need help setting up security groups for my HR team';
        req.issueSummary  = 'Configuration guidance needed for security groups';
        req.workdayModule = 'HCM';

        Test.startTest();
        List<CaseFieldPredictor.PredictionResult> results =
            CaseFieldPredictor.predictFields(new List<CaseFieldPredictor.PredictionRequest>{ req });
        Test.stopTest();

        System.assertEquals('Medium', results[0].predictedPriority, 'Guidance requests default to Medium');
        System.assertEquals('Security', results[0].predictedProductArea, 'Security group keywords map to Security');
    }

    @IsTest
    static void testPredictIntegrationArea() {
        CaseFieldPredictor.PredictionRequest req = new CaseFieldPredictor.PredictionRequest();
        req.transcript    = 'Our API connector is failing when syncing data to our ERP';
        req.workdayModule = 'Integration';

        Test.startTest();
        List<CaseFieldPredictor.PredictionResult> results =
            CaseFieldPredictor.predictFields(new List<CaseFieldPredictor.PredictionRequest>{ req });
        Test.stopTest();

        System.assertEquals('Integration', results[0].predictedProductArea, 'Integration module override applies');
    }

    @IsTest
    static void testPredictEmptyRequest() {
        CaseFieldPredictor.PredictionRequest req = new CaseFieldPredictor.PredictionRequest();

        Test.startTest();
        List<CaseFieldPredictor.PredictionResult> results =
            CaseFieldPredictor.predictFields(new List<CaseFieldPredictor.PredictionRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should handle empty request gracefully');
        System.assertEquals('Medium', results[0].predictedPriority, 'Default priority should be Medium');
        System.assertEquals('Other', results[0].predictedProductArea, 'Default area should be Other');
    }

    // ── WorkdayConfigValidator Tests ─────────────────────────────────────────

    @IsTest
    static void testValidatorSecurityFlagsBroadAccess() {
        WorkdayConfigValidator.ValidationRequest req = new WorkdayConfigValidator.ValidationRequest();
        req.configType = 'security';
        req.configData = 'Grant all users full access to all security groups';

        Test.startTest();
        List<WorkdayConfigValidator.ValidationResult> results =
            WorkdayConfigValidator.validateConfiguration(new List<WorkdayConfigValidator.ValidationRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isValid, 'Broad access should fail validation');
        System.assert(String.isNotBlank(results[0].recommendations), 'Recommendations should be populated');
    }

    @IsTest
    static void testValidatorIntegrationFlagsHttp() {
        WorkdayConfigValidator.ValidationRequest req = new WorkdayConfigValidator.ValidationRequest();
        req.configType = 'integration';
        req.configData = 'endpoint: http://workday.example.com/api (not https)';

        Test.startTest();
        List<WorkdayConfigValidator.ValidationResult> results =
            WorkdayConfigValidator.validateConfiguration(new List<WorkdayConfigValidator.ValidationRequest>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].isValid, 'HTTP endpoint should fail');
        System.assert(results[0].validationErrors.contains('HTTPS'), 'Error should mention HTTPS');
    }

    @IsTest
    static void testValidatorBusinessProcessPasses() {
        WorkdayConfigValidator.ValidationRequest req = new WorkdayConfigValidator.ValidationRequest();
        req.configType = 'business_process';
        req.configData = 'Standard approval workflow with defined steps';

        Test.startTest();
        List<WorkdayConfigValidator.ValidationResult> results =
            WorkdayConfigValidator.validateConfiguration(new List<WorkdayConfigValidator.ValidationRequest>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].isValid, 'Valid business process config should pass');
        System.assert(String.isNotBlank(results[0].recommendations), 'Best practice tips should still be provided');
    }

    @IsTest
    static void testValidatorMissingConfigType() {
        WorkdayConfigValidator.ValidationRequest req = new WorkdayConfigValidator.ValidationRequest();
        req.configType = '';

        Test.startTest();
        List<WorkdayConfigValidator.ValidationResult> results =
            WorkdayConfigValidator.validateConfiguration(new List<WorkdayConfigValidator.ValidationRequest>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].isValid, 'Missing configType should fail');
        System.assert(results[0].validationErrors.contains('configType'), 'Error should name the missing field');
    }

    // ── CaseRiskScoringBatch Tests ────────────────────────────────────────────

    @IsTest
    static void testBatchScoresOpenCase() {
        Account acct = new Account(Name = 'Acme Corp', Type = 'Enterprise');
        insert acct;
        Case openCase = new Case(
            Subject           = 'Payroll integration failing',
            Status            = 'Open',
            Priority          = 'High',
            AccountId         = acct.Id,
            Workday_Module__c = 'Payroll'
        );
        insert openCase;

        Test.startTest();
        Database.executeBatch(new CaseRiskScoringBatch(), 50);
        Test.stopTest();

        Case updated = [SELECT Risk_Score__c, Last_Risk_Assessment__c, Next_Best_Action__c
                        FROM Case WHERE Id = :openCase.Id];
        System.assertNotEquals(null, updated.Risk_Score__c, 'Risk score must be set after batch');
        System.assertNotEquals(null, updated.Last_Risk_Assessment__c, 'Assessment timestamp must be set');
        System.assertNotEquals(null, updated.Next_Best_Action__c, 'Next best action must be populated');
    }

    @IsTest
    static void testBatchSkipsClosedCases() {
        Account acct = new Account(Name = 'Beta Corp', Type = 'Business');
        insert acct;
        Case closedCase = new Case(
            Subject           = 'Closed configuration question',
            Status            = 'Closed',
            AccountId         = acct.Id,
            Workday_Module__c = 'HCM'
        );
        insert closedCase;

        Test.startTest();
        Database.executeBatch(new CaseRiskScoringBatch(), 50);
        Test.stopTest();

        Case result = [SELECT Risk_Score__c FROM Case WHERE Id = :closedCase.Id];
        System.assertEquals(null, result.Risk_Score__c, 'Closed cases should not be scored');
    }

    @IsTest
    static void testGenerateNextBestActionCritical() {
        Account acct = new Account(Name = 'Test Co', Type = 'Enterprise');
        insert acct;
        Case c = new Case(
            Subject           = 'Critical issue',
            Status            = 'Open',
            AccountId         = acct.Id,
            Workday_Module__c = 'HCM'
        );
        insert c;
        c = [SELECT Id, CaseNumber, CreatedDate, AccountId,
                    Account.Name, Account.Type, Workday_Module__c
             FROM Case WHERE Id = :c.Id];

        CaseRiskScoringBatch batch = new CaseRiskScoringBatch();

        Test.startTest();
        String nba = batch.generateNextBestAction(c, 85);
        Test.stopTest();

        System.assert(nba.contains('IMMEDIATE'), 'Score 85 should produce immediate action guidance');
    }

    @IsTest
    static void testGenerateNextBestActionMedium() {
        Account acct = new Account(Name = 'Medium Co', Type = 'Customer');
        insert acct;
        Case c = new Case(
            Subject           = 'Config question',
            Status            = 'Open',
            AccountId         = acct.Id,
            Workday_Module__c = 'Analytics'
        );
        insert c;
        c = [SELECT Id, CaseNumber, CreatedDate, AccountId,
                    Account.Name, Account.Type, Workday_Module__c
             FROM Case WHERE Id = :c.Id];

        CaseRiskScoringBatch batch = new CaseRiskScoringBatch();

        Test.startTest();
        String nba = batch.generateNextBestAction(c, 30);
        Test.stopTest();

        System.assert(nba.contains('standard support'), 'Score 30 should produce standard process guidance');
    }

    @IsTest
    static void testCalculateRiskScoreHighRisk() {
        Account acct = new Account(Name = 'Enterprise Co', Type = 'Enterprise');
        insert acct;
        Case c = new Case(
            Subject           = 'Critical outage',
            Status            = 'Open',
            Priority          = 'Critical',
            AccountId         = acct.Id,
            Workday_Module__c = 'Payroll'
        );
        insert c;
        c = [SELECT Id, CaseNumber, CreatedDate, LastModifiedDate, OwnerId,
                    AccountId, Account.Name, Account.Type,
                    Status, Priority, Subject, Description,
                    Workday_Module__c, Product_Area__c,
                    (SELECT Id, CommentBody, CreatedDate FROM CaseComments LIMIT 5),
                    (SELECT Id, Subject, CreatedDate FROM ActivityHistories LIMIT 5)
             FROM Case WHERE Id = :c.Id];

        CaseRiskScoringBatch batch = new CaseRiskScoringBatch();

        Test.startTest();
        Decimal score = batch.calculateRiskScore(c);
        Test.stopTest();

        System.assertNotEquals(null, score, 'Score should be computed');
        System.assert(score >= 0 && score <= 100, 'Score must be in 0-100 range');
    }

    @IsTest
    static void testSchedulableExecutes() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Case Risk Scoring',
            '0 0 0 * * ?',
            new CaseRiskScoringBatch()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 0 * * ?', ct.CronExpression, 'Cron expression should match');
    }
}
