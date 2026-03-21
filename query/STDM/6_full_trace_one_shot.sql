WITH
  -- Parameterize your session ID here
  params AS (
    SELECT '019d1161-b33c-78db-a9cb-20f180c9fcc2' AS session_id
  ),

  -- Turns + messages per turn
  interactionsWithMessages AS (
    SELECT
      I."ssot__Id__c"                                  AS interaction_id,
      I."ssot__AiAgentSessionId__c"                    AS session_id,
      I."ssot__AiAgentInteractionType__c"              AS interaction_type,
      I."ssot__TopicApiName__c"                        AS topic,
      I."ssot__TelemetryTraceId__c"                    AS telemetry_trace_id,
      I."ssot__TelemetryTraceSpanId__c"                AS telemetry_span_id,
      I."ssot__StartTimestamp__c"                      AS interaction_start,
      I."ssot__EndTimestamp__c"                        AS interaction_end,
      M."ssot__AiAgentInteractionMessageType__c"       AS message_type,
      M."ssot__AiAgentInteractionMsgContentType__c"    AS message_content_type,
      M."ssot__ContentText__c"                         AS message_text,
      M."ssot__MessageSentTimestamp__c"                AS message_time,
      M."ssot__AiAgentSessionParticipantId__c"         AS participant_id
    FROM "ssot__AiAgentInteraction__dlm" I
    JOIN "ssot__AiAgentInteractionMessage__dlm" M
      ON I."ssot__Id__c" = M."ssot__AiAgentInteractionId__c"
    WHERE I."ssot__AiAgentSessionId__c" = (SELECT session_id FROM params)
  ),

  -- Steps (actions, LLM calls) per turn
  interactionSteps AS (
    SELECT
      I."ssot__Id__c"                               AS interaction_id,
      S."ssot__Id__c"                               AS step_id,
      S."ssot__PrevStepId__c"                       AS prev_step_id,
      S."ssot__Name__c"                             AS step_name,
      S."ssot__AiAgentInteractionStepType__c"       AS step_type,
      S."ssot__StartTimestamp__c"                   AS step_start,
      S."ssot__EndTimestamp__c"                     AS step_end,
      S."ssot__InputValueText__c"                   AS step_input,
      S."ssot__OutputValueText__c"                  AS step_output,
      S."ssot__PreStepVariableText__c"              AS pre_step_variables,
      S."ssot__PostStepVariableText__c"             AS post_step_variables,
      S."ssot__ErrorMessageText__c"                 AS error_message,
      S."ssot__GenAiGatewayRequestId__c"            AS llm_request_id,
      S."ssot__GenAiGatewayResponseId__c"           AS llm_response_id,
      S."ssot__GenerationId__c"                     AS generation_id,
      S."ssot__TelemetryTraceSpanId__c"             AS telemetry_span_id
    FROM "ssot__AiAgentInteraction__dlm" I
    JOIN "ssot__AiAgentInteractionStep__dlm" S
      ON I."ssot__Id__c" = S."ssot__AiAgentInteractionId__c"
    WHERE I."ssot__AiAgentSessionId__c" = (SELECT session_id FROM params)
  )

-- Combine messages and steps into a unified timeline
SELECT
  'MESSAGE'                AS record_type,
  session_id,
  interaction_id,
  interaction_type,
  topic,
  telemetry_trace_id,
  telemetry_span_id,
  participant_id,
  NULL                     AS step_id,
  NULL                     AS prev_step_id,
  message_type             AS detail_type,
  message_content_type,
  message_text             AS content,
  NULL                     AS pre_step_variables,
  NULL                     AS post_step_variables,
  NULL                     AS error_message,
  NULL                     AS llm_request_id,
  NULL                     AS llm_response_id,
  NULL                     AS generation_id,
  message_time             AS event_time
FROM interactionsWithMessages

UNION ALL

SELECT
  'STEP'                                                              AS record_type,
  (SELECT session_id FROM params)                                    AS session_id,
  interaction_id,
  NULL                                                                AS interaction_type,
  NULL                                                                AS topic,
  NULL                                                                AS telemetry_trace_id,
  telemetry_span_id,
  NULL                                                                AS participant_id,
  step_id,
  prev_step_id,
  step_type                                                           AS detail_type,
  NULL                                                                AS message_content_type,
  CONCAT(step_name, ' | IN: ', step_input, ' | OUT: ', step_output) AS content,
  pre_step_variables,
  post_step_variables,
  error_message,
  llm_request_id,
  llm_response_id,
  generation_id,
  step_start                                                          AS event_time
FROM interactionSteps

ORDER BY event_time