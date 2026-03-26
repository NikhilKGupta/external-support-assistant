SELECT "KQ_AiAgentInteractionId__c",
	   "KQ_AiAgentSessionId__c",
	   "KQ_AiAgentSessionParticipantId__c",
	   "KQ_Id__c",
	   "KQ_ParentMessageId__c",
	   "ssot__AiAgentInteractionId__c",
	   "ssot__AiAgentInteractionMessageType__c",
	   "ssot__AiAgentInteractionMsgContentType__c",
	   "ssot__AiAgentSessionId__c",
	   "ssot__AiAgentSessionParticipantId__c",
	   "ssot__ContentText__c",
	   "ssot__DataSourceId__c",
	   "ssot__DataSourceObjectId__c",
	   "ssot__ExternalSourceId__c",
	   "ssot__Id__c",
	   "ssot__IndividualId__c",
	   "ssot__InternalOrganizationId__c",
	   "ssot__MessageSentTimestamp__c",
	   "ssot__ParentMessageId__c",
	   "ssot__SessionOwnerId__c",
	   "ssot__SessionOwnerObject__c" 
FROM "ssot__AiAgentInteractionMessage__dlm"
WHERE "ssot__AiAgentSessionId__c" = 'ffbf2564-06ba-48dc-88bc-5c89f2832067'
ORDER BY "ssot__MessageSentTimestamp__c"