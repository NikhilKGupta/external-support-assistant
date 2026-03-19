/**
 * Schedule the CaseRiskScoringBatch to run every 4 hours.
 *
 * Run via:
 *   sf apex run -f scripts/schedule-risk-batch.apex -o TARGET_ORG
 *
 * To check the scheduled job:
 *   SELECT Id, CronExpression, State, NextFireTime
 *   FROM CronTrigger
 *   WHERE CronJobDetail.Name LIKE 'Workday Case Risk Scoring%'
 *
 * To cancel:
 *   System.abortJob('<JOB_ID>');
 */

// Remove any existing job with this name before scheduling
for (CronTrigger ct : [
    SELECT Id FROM CronTrigger
    WHERE CronJobDetail.Name = 'Workday Case Risk Scoring'
]) {
    System.abortJob(ct.Id);
}

// Schedule every 4 hours: 00:00, 04:00, 08:00, 12:00, 16:00, 20:00
String jobId = System.schedule(
    'Workday Case Risk Scoring',
    '0 0 0/4 * * ?',
    new CaseRiskScoringBatch()
);

System.debug('Workday Case Risk Scoring batch scheduled. Job ID: ' + jobId);
