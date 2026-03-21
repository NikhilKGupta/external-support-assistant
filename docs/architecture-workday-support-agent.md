# Workday Support Agent — architecture

Agent definition: `force-app/main/default/aiAuthoringBundles/Workday_Support_Agent/Workday_Support_Agent.agent`  
Type: **AgentforceServiceAgent** · Entry: **`start_agent topic_router`**

## Runtime context

- **Channels**: community portal session supplies linked variables (`ContactId`, `admin_account_id`, `RoutableId` for Omni).
- **Knowledge**: RAG via `streamKnowledgeSearch` + `rag_feature_config_id` (`ARFPC_…`); optional KB search prompt `Workday_KB_Search`.
- **Handoff**: Omni-Channel flow `Route_Workday_To_Queue` after `utils.escalate`.

## System view

```mermaid
flowchart TB
  subgraph User
    U[Community admin]
  end
  subgraph Salesforce["Salesforce / Agentforce"]
    A[Workday_Support_Agent]
    F1[Flow: Load_Workday_Customer_Context]
    F2[Flow: Create_Workday_Support_Case]
    F3[Flow: Route_Workday_To_Queue]
    G1[GenAI: Workday_KB_Search]
    G2[GenAI: Workday_Conversation_Summarizer]
    G3[GenAI: Workday_Config_Guide]
    AP[Apex: WorkdayConfigValidator]
    RAG[streamKnowledgeSearch + RAG feature config]
  end
  subgraph Omni["Omni-Channel"]
    Q[Human specialist queue]
  end

  U --> A
  A --> F1
  A --> RAG
  A --> G1
  A --> G2
  A --> G3
  A --> AP
  A --> F2
  A --> F3
  F3 --> Q
```

## Topic flow (FSM)

```mermaid
flowchart TD
  START([Session start]) --> TR[topic_router]
  TR -->|Troubleshoot| TRO[troubleshooting]
  TR -->|Configure| CFG[configuration_assistance]
  TR -->|Specialist| PRE[pre_escalation]
  TRO -->|Specialist| PRE
  TRO -->|Main menu| TR
  CFG -->|Errors / troubleshoot| TRO
  CFG -->|Main menu| TR
  PRE --> ESC[escalation]
  ESC -->|utils.escalate| OMNI[Omni handoff]
```

**ASCII (same story)**

```
                    ┌─────────────────┐
                    │  topic_router   │
                    └────────┬────────┘
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
   troubleshooting   configuration      pre_escalation
           │           _assistance              │
           │                 │                  │
           └────────►(menu)──┴──►troubleshooting │
           │                 │                  │
           └─────────────────┴──────────────────┤
                                                ▼
                                         escalation → Omni
```

## Capabilities by topic

| Topic | User-facing intent | Main integrations |
|--------|-------------------|-------------------|
| `topic_router` | Load admin context, choose path | Flow `Load_Workday_Customer_Context` |
| `troubleshooting` | KB-first (if verified), diagnose, case | `streamKnowledgeSearch`, GenAI `Workday_KB_Search`, summarizer + Flow case create |
| `configuration_assistance` | KB-first, guides, validation | `streamKnowledgeSearch`, GenAI `Workday_Config_Guide`, Apex `WorkdayConfigValidator` |
| `pre_escalation` | Summary + case if missing | GenAI `Workday_Conversation_Summarizer`, Flow `Create_Workday_Support_Case` |
| `escalation` | Transfer | `utils.escalate` → `Route_Workday_To_Queue` |

## Session variables (logical groups)

- **Identity**: `ContactId`, `admin_account_id`, `admin_name`, `support_tier`, `identity_verified`, `RoutableId`
- **Issue**: `issue_type`, `workday_module`, `issue_summary`, KB flags (`knowledge_first_enabled`, thresholds)
- **Case / handoff**: `case_created`, `case_number`, `predicted_priority`, `predicted_product_area`, `ai_summary`, `ai_transcript`, `escalation_initiated`
