# Planning Best Practices

This document captures critical checks and principles to apply when creating implementation plans for this project.

## Pre-Plan Delivery Checklist

Before finalizing any plan, validate the following:

### 1. Necessity Check for New Components

For each proposed new class/file/component, verify it doesn't duplicate existing functionality:

- **Search for existing implementations**: Before proposing a new Apex class, LWC, Flow, or other component, search the codebase for existing classes/actions with similar inputs/outputs
- **Evaluate reuse potential**: Check if existing infrastructure can be reused directly without modification
- **Validate wrapper value**: If proposing a wrapper or adapter class, confirm it adds actual logic beyond type conversion
- **Question every "new"**: Ask "Why can't we use what already exists?" for every proposed new component

**Anti-pattern**: Creating `PrepareCaseFormAction` as a wrapper around `CaseFieldPredictor` when both have identical signatures.

**Correct approach**: If an existing invocable method has the exact same signature (inputs/outputs) as what the plan requires, use it directly.

### 2. Self-Contradiction Scan

Read the plan end-to-end and flag any section where later text contradicts or undermines earlier recommendations:

- **Watch for constraint revelations**: If a constraint is discovered mid-plan (e.g., "Prompt Templates can't be called from Apex"), check if it invalidates earlier proposals
- **Validate combined operations**: If proposing a component to do "A+B" but later text says "actually only B is possible," re-evaluate whether the component is still needed
- **Flag undermining statements**: Look for phrases like "however," "actually," "but," "note that" — these often signal contradictions

**Example from this project**: Original plan proposed `PrepareCaseFormAction` to run "summarization and field prediction in a single call," then immediately noted summarization can't be in Apex and must be separate. This contradiction should have triggered deletion of the wrapper class from the plan.

### 3. Dependency Rationalization

When a constraint eliminates part of a component's purpose, re-evaluate whether the component is still needed at all:

- **Re-scope after constraints**: If a technical constraint reduces a component's scope, ask "Does this component still justify its existence?"
- **Avoid scope creep remnants**: Don't carry forward components whose original justification has been undermined
- **Challenge architectural momentum**: Just because a component was in the initial design doesn't mean it should survive constraint discovery

### 4. Interface Alignment Verification

Before proposing a wrapper or adapter, confirm that the source and target interfaces actually differ in a way that requires translation:

- **Compare signatures precisely**: List inputs and outputs side-by-side
- **Identify the delta**: What exactly is being transformed? If the answer is "nothing," no wrapper is needed
- **Check parameter names**: For Salesforce invocable methods, parameter names must match exactly for mapping to work. If names already match, no adapter is needed

### 5. Naming Convention Validation

For Salesforce Lightning Types, LWCs, and Agent Script actions:

- **Action parameters = Schema properties = LWC @api names**: These three layers must use identical names for the platform mapping to work
- **Check end-to-end**: Trace the name from the agent script action input/output → Lightning Type schema property → LWC `@api` property
- **Flag camelCase vs snake_case mismatches**: These are critical mapping failures in Salesforce

**Example**: `issue_summary` (action input) → `subject` (schema property) → `subject` (LWC) is BROKEN. All three must be `issue_summary`.

## Planning Philosophy

### Start with "What exists?"

- Before designing anything new, explore what's already built
- Default to reuse over rebuild
- Treat new components as last resort, not first choice

### Challenge every assumption

- If the plan assumes X, explicitly verify X is true
- Don't assume two things with the same purpose are different just because they have different names
- Re-read constraint statements carefully — they often invalidate earlier proposals

### Simplicity over clever architecture

- The simplest solution that meets requirements is usually the correct one
- Avoid premature abstraction
- Question whether "clean architecture" is adding value or just adding files

### Plan for junior developers

- Assume the implementer has minimal context
- Be precise about what changes and why
- Provide exact file paths, line numbers, and code snippets
- Explain not just "what" but "why" each change is necessary

## Lessons Learned

### `PrepareCaseFormAction` redundancy (March 2026)

**What happened**: Original plan proposed a new Apex class `PrepareCaseFormAction` to wrap `CaseFieldPredictor`, even though both classes had identical inputs and outputs. The wrapper added no logic — just type conversion.

**Root cause**: Plan designed top-down from desired architecture ("a single prepare action") without first checking if existing infrastructure (`CaseFieldPredictor`) already met the need. When a constraint (Prompt Templates can't be in Apex) forced summarization out of the wrapper, the plan wasn't revised to eliminate the now-redundant class.

**Prevention**: Apply checklist items #1 (necessity check) and #3 (dependency rationalization) before finalizing plans.

---

**Document version**: 1.0  
**Last updated**: March 2026  
**Apply to**: All implementation plans for Workday Support Agent and related components
