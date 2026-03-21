SELECT "KQ_AiAgentSessionId__c",
	   "KQ_Id__c",
	   "KQ_PrevInteractionId__c",
	   "ssot__AiAgentInteractionType__c",
	   "ssot__AiAgentSessionId__c",
	   "ssot__AttributeText__c",
	   "ssot__DataSourceId__c",
	   "ssot__DataSourceObjectId__c",
	   "ssot__EndTimestamp__c",
	   "ssot__ExternalSourceId__c",
	   "ssot__Id__c",
	   "ssot__IndividualId__c",
	   "ssot__InternalOrganizationId__c",
	   "ssot__PrevInteractionId__c",
	   "ssot__SessionOwnerId__c",
	   "ssot__SessionOwnerObject__c",
	   "ssot__StartTimestamp__c",
	   "ssot__TelemetryTraceId__c",
	   "ssot__TelemetryTraceSpanId__c",
	   "ssot__TopicApiName__c" 
FROM "ssot__AiAgentInteraction__dlm" 
where ssot__AiAgentSessionId__c = '019d1161-b33c-78db-a9cb-20f180c9fcc2'
ORDER BY "ssot__StartTimestamp__c"