# Workday Support Agent — automated tests

**Agent API name:** `Workday_Support_Agent` (see [`Workday_Support_Agent.agent`](../force-app/main/default/aiAuthoringBundles/Workday_Support_Agent/Workday_Support_Agent.agent))  
**Org alias (this workspace):** `dhurandhar`

Store real **Contact / Account / MessagingSession IDs** in your notes or local env — do not commit secrets or production IDs.

## Preflight (before `sf agent test`)

1. **Deploy and publish** the authoring bundle; confirm an **active** agent version in Setup (bundle [`Workday_Support_Agent.bundle-meta.xml`](../force-app/main/default/aiAuthoringBundles/Workday_Support_Agent/Workday_Support_Agent.bundle-meta.xml) may omit `<target>` — verify which version is live).
2. **Agent Testing Center:** `sf agent test list -o dhurandhar` — if the command errors, use `sf agent preview` or Runtime API multi-turn testing instead.
3. **Dependencies:** flows `Load_Workday_Customer_Context`, `Create_Workday_Support_Case`, `Route_Workday_To_Queue`; GenAI templates `Workday_KB_Search`, `Workday_Conversation_Summarizer`, `Workday_Config_Guide`; Apex `WorkdayConfigValidator`; RAG feature in the agent; permission set `Workday_Support_Agent_Access` on the Einstein agent user.
4. **Linked variables:** `ContactId`, `admin_account_id`, `RoutableId` — supply via your channel or add `contextVariables` to specific cases in the YAML (see Salesforce test-spec reference). Without portal context, context load and case flows may fail; adjust expectations or seed data.
5. **Omni:** full `utils.escalate` + `Route_Workday_To_Queue` is often validated **manually** on Messaging unless you have a stable queue and session ID. The YAML spec intentionally omits automated `go_to_escalation` / `handoff` cases until conversation history reliably pins `pre_escalation` in your org.

## Commands

```bash
# Create / refresh evaluation definition from spec
sf agent test create --spec agent-tests/workday_support_agent_tests.yaml \
  --api-name Workday_Support_Agent_Tests -o dhurandhar --force-overwrite

# Run (async + wait)
sf agent test run --api-name Workday_Support_Agent_Tests -o dhurandhar --wait 15 --verbose

# Results (use job id from run output when needed)
sf agent test results --job-id <JOB_ID> -o dhurandhar --result-format human
```

**Apex (WorkdayConfigValidator):**

```bash
sf apex run test --tests CaseRiskScoringBatchTest -o dhurandhar --wait 10 --result-format human
```

## Topic / action names

Agent Script uses **transition** actions on the first menu turn (`go_troubleshooting`, `go_configuration`, `go_escalation`). Business actions usually need **`conversationHistory`** in the YAML so the agent is already in the topic. If `expectedTopic` assertions fail, run once with `--verbose` and align names with `generatedData.topic` from results.

## Failure triage (quick buckets)

| Symptom | Check |
|--------|--------|
| Wrong topic | Utterance phrasing; platform topics (`Inappropriate_Content`, `Prompt_Injection`) stealing routing |
| Action not invoked | Missing `conversationHistory`; wrong Level-1 definition name |
| Action failed | Flow/Apex permissions, missing `ContactId`, invalid RAG config |
| Escalation | Omni queue, `RoutableId`, manual verification |

## Latest results

See [`RUN_REPORT.md`](RUN_REPORT.md) for pass/fail summary, Apex notes, and triage themes.

## Optional: traces (Data Cloud)

After runs, use [`query/STDM/6_full_trace_one_shot.sql`](../query/STDM/6_full_trace_one_shot.sql) with the session id from telemetry.

## Optional: Runtime API multi-turn

Use ECA / Connected App auth and multi-turn scripts (see Agentforce testing skill references). Do not commit client secrets.
