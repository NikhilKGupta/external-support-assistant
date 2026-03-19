/**
 * CaseRiskScoringBatch
 *
 * Scheduled batch that scores open Workday support cases for escalation risk.
 * Analyzes last 30 days of activity, customer sentiment, and account health.
 * Proactively alerts managers and generates Next Best Action recommendations
 * for cases that exceed the high-risk threshold (>= 70).
 *
 * To schedule every 4 hours:
 *   System.schedule('Case Risk Scoring', '0 0 0/4 * * ?', new CaseRiskScoringBatch());
 */
public with sharing class CaseRiskScoringBatch implements Database.Batchable<SObject>, Schedulable {

    @TestVisible private static final Integer HIGH_RISK_THRESHOLD = 70;
    @TestVisible private static final Integer LOOKBACK_DAYS = 30;
    private static final Integer BATCH_SIZE = 50;

    // Scoring weights — must total 100
    private static final Integer WEIGHT_ACTIVITY  = 25;
    private static final Integer WEIGHT_AGE       = 25;
    private static final Integer WEIGHT_TOUCHES   = 20;
    private static final Integer WEIGHT_SENTIMENT = 15;
    private static final Integer WEIGHT_ACCOUNT   = 15;

    // ── Schedulable ───────────────────────────────────────────────────────────

    /** @description Schedulable entry point — fires the batch. */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CaseRiskScoringBatch(), BATCH_SIZE);
    }

    // ── Batchable ─────────────────────────────────────────────────────────────

    /** @description Returns the query scope: open Workday cases within the lookback window. */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime lookbackDate = DateTime.now().addDays(-LOOKBACK_DAYS);
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, AccountId, OwnerId,
                   CreatedDate, LastModifiedDate, Status, Priority,
                   Subject, Description,
                   Workday_Module__c, Product_Area__c,
                   Account.Name, Account.Type,
                   (SELECT Id, CommentBody, CreatedDate
                    FROM CaseComments
                    ORDER BY CreatedDate DESC
                    LIMIT 5),
                   (SELECT Id, Subject, CreatedDate
                    FROM ActivityHistories
                    ORDER BY CreatedDate DESC
                    LIMIT 5)
            FROM Case
            WHERE Status NOT IN ('Closed', 'Resolved')
            AND Workday_Module__c != null
            AND CreatedDate >= :lookbackDate
        ]);
    }

    /** @description Scores each case, updates risk fields, and alerts on high-risk cases. */
    public void execute(Database.BatchableContext bc, List<Case> cases) {
        // Collect all records before any DML — bulk pattern
        List<Case>      casesToUpdate = new List<Case>();
        List<Task>      alertTasks    = new List<Task>();
        List<FeedItem>  chatterPosts  = new List<FeedItem>();

        // Build owner→manager map for User-type owners (avoid polymorphic cross-object SOQL)
        Set<Id> userOwnerIds = new Set<Id>();
        for (Case c : cases) {
            if (c.OwnerId != null && String.valueOf(c.OwnerId).startsWith('005')) {
                userOwnerIds.add(c.OwnerId);
            }
        }
        Map<Id, Id> ownerManagerMap = new Map<Id, Id>();
        if (!userOwnerIds.isEmpty()) {
            for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :userOwnerIds]) {
                if (u.ManagerId != null) {
                    ownerManagerMap.put(u.Id, u.ManagerId);
                }
            }
        }

        for (Case c : cases) {
            Decimal riskScore = calculateRiskScore(c);
            String  nba       = generateNextBestAction(c, riskScore);

            casesToUpdate.add(buildCaseUpdate(c.Id, riskScore, nba));

            if (riskScore >= HIGH_RISK_THRESHOLD) {
                Id managerId = ownerManagerMap.get(c.OwnerId);
                if (managerId != null) {
                    alertTasks.add(buildAlertTask(c, riskScore, nba, managerId));
                }
                chatterPosts.add(buildChatterPost(c, riskScore, nba));
            }
        }

        // Single DML operations after full collection
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
        if (!alertTasks.isEmpty()) {
            insert alertTasks;
        }
        if (!chatterPosts.isEmpty()) {
            insert chatterPosts;
        }
    }

    /** @description Batch finish hook — reserved for summary notifications. */
    public void finish(Database.BatchableContext bc) {
        // Reserved: send summary to support managers
    }

    // ── Risk Scoring ──────────────────────────────────────────────────────────

    @TestVisible
    private Decimal calculateRiskScore(Case c) {
        Decimal score = 0;
        score += scoreDaysSinceActivity(c);
        score += scoreCaseAge(c);
        score += scoreTouchCount(c);
        score += scoreSentiment(c);
        score += scoreAccountTier(c);
        return Math.min(score, 100);
    }

    private Decimal scoreDaysSinceActivity(Case c) {
        Integer days = getDaysSinceLastActivity(c);
        if (days >= 5) { return WEIGHT_ACTIVITY; }
        if (days >= 3) { return Math.round(WEIGHT_ACTIVITY * 0.6); }
        if (days >= 1) { return Math.round(WEIGHT_ACTIVITY * 0.2); }
        return 0;
    }

    private Decimal scoreCaseAge(Case c) {
        Integer age = c.CreatedDate.date().daysBetween(Date.today());
        if (age >= 7) { return WEIGHT_AGE; }
        if (age >= 5) { return Math.round(WEIGHT_AGE * 0.8); }
        if (age >= 3) { return Math.round(WEIGHT_AGE * 0.4); }
        if (age >= 1) { return Math.round(WEIGHT_AGE * 0.2); }
        return 0;
    }

    private Decimal scoreTouchCount(Case c) {
        Integer comments = (c.CaseComments != null) ? c.CaseComments.size() : 0;
        if (comments >= 5) { return WEIGHT_TOUCHES; }
        if (comments >= 3) { return Math.round(WEIGHT_TOUCHES * 0.6); }
        if (comments >= 1) { return Math.round(WEIGHT_TOUCHES * 0.25); }
        return 0;
    }

    private Decimal scoreSentiment(Case c) {
        if (c.CaseComments == null || c.CaseComments.isEmpty()) { return 0; }
        List<String> negativeKeywords = new List<String>{
            'frustrated', 'unacceptable', 'disappointed',
            'still broken', 'still not working', 'no progress',
            'escalate to management', 'losing patience', 'fed up',
            'contract', 'legal', 'cancel'
        };
        String recentText = '';
        Integer commentLimit = Math.min(c.CaseComments.size(), 3);
        for (Integer i = 0; i < commentLimit; i++) {
            if (c.CaseComments[i].CommentBody != null) {
                recentText += c.CaseComments[i].CommentBody.toLowerCase() + ' ';
            }
        }
        for (String kw : negativeKeywords) {
            if (recentText.contains(kw)) { return WEIGHT_SENTIMENT; }
        }
        return 0;
    }

    private Decimal scoreAccountTier(Case c) {
        if (c.Account == null) { return 0; }
        String accountType = c.Account.Type != null ? c.Account.Type : '';
        if (accountType == 'Enterprise' || accountType == 'Premier') { return WEIGHT_ACCOUNT; }
        if (accountType == 'Business') { return Math.round(WEIGHT_ACCOUNT * 0.5); }
        return Math.round(WEIGHT_ACCOUNT * 0.2);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Integer getDaysSinceLastActivity(Case c) {
        DateTime lastActivity = c.LastModifiedDate;
        if (c.ActivityHistories != null && !c.ActivityHistories.isEmpty()) {
            DateTime latestTask = c.ActivityHistories[0].CreatedDate;
            if (latestTask > lastActivity) {
                lastActivity = latestTask;
            }
        }
        return lastActivity.date().daysBetween(Date.today());
    }

    @TestVisible
    private String generateNextBestAction(Case c, Decimal riskScore) {
        Integer age = c.CreatedDate.date().daysBetween(Date.today());
        if (riskScore >= 80) {
            return 'IMMEDIATE: Contact customer within 2 hours. Engage engineering lead. '
                 + 'Escalate to senior support manager if no resolution path. Provide written status update today.';
        }
        if (riskScore >= 70) {
            return (age >= 5)
                ? 'Schedule 30-min sync call today. Review with technical lead. Provide resolution timeline by EOD.'
                : 'Send proactive status update. Identify blockers. Assign additional resources if needed.';
        }
        if (riskScore >= 40) {
            return 'Send proactive update within 24 hours. Review priority alignment. Explore workaround options.';
        }
        return 'Continue standard support process. Follow up by next business day. Monitor for sentiment changes.';
    }

    private Case buildCaseUpdate(Id caseId, Decimal riskScore, String nba) {
        return new Case(
            Id                      = caseId,
            Risk_Score__c           = riskScore,
            Last_Risk_Assessment__c = DateTime.now(),
            Next_Best_Action__c     = nba
        );
    }

    private Task buildAlertTask(Case c, Decimal riskScore, String nba, Id managerId) {
        String accountName = (c.Account != null) ? c.Account.Name : 'Unknown Account';
        String module      = String.isNotBlank(c.Workday_Module__c) ? c.Workday_Module__c : 'Not specified';
        return new Task(
            Subject      = 'Escalation Risk Alert: Case ' + c.CaseNumber,
            Description  = 'Case ' + c.CaseNumber + ' (' + accountName + ') '
                         + 'has Risk Score ' + riskScore.setScale(0) + '/100. '
                         + 'Module: ' + module + '. '
                         + 'Age: ' + c.CreatedDate.date().daysBetween(Date.today()) + ' days.\n\n'
                         + 'Next Best Action:\n' + nba,
            WhatId       = c.Id,
            OwnerId      = managerId,
            ActivityDate = Date.today(),
            Priority     = 'High',
            Status       = 'Not Started'
        );
    }

    private FeedItem buildChatterPost(Case c, Decimal riskScore, String nba) {
        String accountName = (c.Account != null) ? c.Account.Name : 'Unknown';
        String module      = String.isNotBlank(c.Workday_Module__c) ? c.Workday_Module__c : 'Not specified';
        return new FeedItem(
            ParentId = c.Id,
            Body     = 'HIGH ESCALATION RISK DETECTED\n\n'
                     + 'Risk Score: ' + riskScore.setScale(0) + '/100\n'
                     + 'Account: ' + accountName + '\n'
                     + 'Module: ' + module + '\n\n'
                     + 'Next Best Action:\n' + nba + '\n\n'
                     + 'Assessed by automated risk scoring. Please review and act.',
            Type     = 'TextPost'
        );
    }
}
