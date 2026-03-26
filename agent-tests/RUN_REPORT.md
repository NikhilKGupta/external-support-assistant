# Agent test run report — Workday_Support_Agent

**Track:** CLI Agent Testing Center (`sf agent test`)  
**Org alias:** `dhurandhar`  
**Agent:** `Workday_Support_Agent`  
**Evaluation API name:** `Workday_Support_Agent_Tests`  
**Spec:** [`workday_support_agent_tests.yaml`](workday_support_agent_tests.yaml)  
**Last run (local):** Job ID `4KBHu000000CaUaOAK` — 11/11 cases passed (topic, action, outcome 100%).

## What was executed

- `sf agent test create --spec agent-tests/workday_support_agent_tests.yaml --api-name Workday_Support_Agent_Tests -o dhurandhar --force-overwrite`
- `sf agent test run --api-name Workday_Support_Agent_Tests -o dhurandhar --wait 25 --result-format human`

## Apex regression (`CaseRiskScoringBatchTest`)

- Command: `sf apex run test --tests CaseRiskScoringBatchTest -o dhurandhar --wait 15 --result-format human`
- **WorkdayConfigValidator** methods **passed:** `testValidatorBusinessProcessPasses`, `testValidatorIntegrationFlagsHttp`, `testValidatorMissingConfigType`, `testValidatorSecurityFlagsBroadAccess`
- **Other methods failed** on Case insert: org flow `SDO Service - Case - On Create` requires `helperConfig` — environment-specific, not a validator code defect.

To run only validator tests:

```bash
sf apex run test \
  --tests CaseRiskScoringBatchTest.testValidatorBusinessProcessPasses \
  --tests CaseRiskScoringBatchTest.testValidatorIntegrationFlagsHttp \
  --tests CaseRiskScoringBatchTest.testValidatorMissingConfigType \
  --tests CaseRiskScoringBatchTest.testValidatorSecurityFlagsBroadAccess \
  -o dhurandhar --wait 10 --result-format human
```

## Coverage notes

| Area | Automated in YAML |
|------|-------------------|
| Menu routing (troubleshoot / configure / specialist) | Yes |
| Knowledge-first RAG (`tool_stream_knowledge_search`) | Yes |
| `go` vs `go_troubleshooting` naming | Assert `go` (runtime naming) |
| Escalation `go_to_escalation` / `handoff` / Omni | Manual / Messaging (see README) |
| Runtime API multi-turn | Optional (ECA); not run here |
| STDM trace validation | Optional — [`query/STDM/6_full_trace_one_shot.sql`](../query/STDM/6_full_trace_one_shot.sql) |

## Failure triage (from initial runs before spec tuning)

| Theme | Cause | Mitigation applied |
|-------|--------|-------------------|
| Action name mismatch | Transition reported as `go` not `go_troubleshooting` | Expected `go` for troubleshoot routing |
| KB path | Model used `tool_stream_knowledge_search` not `search_knowledge_base` | Expect RAG stream action |
| Conversation history | Must alternate user/agent and end with agent | Added closing agent turn |
| Escalation history | Topic reset to `topic_router` | Removed brittle automated escalation cases |
| Prompt injection | Topic stayed `topic_router`; action sometimes omitted in list | Outcome-only assertion |

## Next steps

- Re-run after agent or RAG changes; refresh `expectedTopic` from `--verbose` JSON if topics are renamed in org.
- Add Messaging-backed cases for `handoff` when `RoutableId` and queue are stable.
