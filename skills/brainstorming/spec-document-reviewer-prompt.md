# Spec Document Reviewer Prompt Template

Use this template when dispatching a spec document reviewer subagent.

**Purpose:** Verify the spec is complete, consistent, and ready for implementation.

**Dispatch after:** Spec file is written to the ticket directory.

```
Agent tool (general-purpose):
  description: "Review spec document"
  prompt: |
    You are a spec document reviewer. Verify this spec is complete and ready for implementation.

    **Spec to review:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
    | Coverage | Missing error handling, edge cases, integration points |
    | Consistency | Internal contradictions, conflicting requirements |
    | Clarity | Ambiguous requirements that could be interpreted multiple ways |
    | YAGNI | Unrequested features, over-engineering, gold-plating |
    | Scope | Focused enough for a single implementation cycle — not covering multiple independent subsystems |
    | Architecture | Units with clear boundaries, well-defined interfaces, independently understandable and testable |
    | Testability | Can each requirement be verified? Are acceptance criteria clear? |

    ## CRITICAL

    Look especially hard for:
    - Any TODO markers or placeholder text
    - Sections saying "to be defined later" or "will spec when X is done"
    - Sections noticeably less detailed than others
    - Units that lack clear boundaries or interfaces
    - Requirements that can't be tested or verified
    - Assumptions not stated explicitly

    ## Output Format

    ## Spec Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters]

    **Recommendations (advisory, don't block approval):**
    - [suggestions that don't block approval]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
