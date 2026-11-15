# Advisor Prompt Template

Use this template when consulting the advisor (see `SKILL.md` for when).

**Dispatch:** Agent tool, `subagent_type: advisor`. Do not pass `model` or `effort` — a value on the
call overrides the agent file. The agent file (`agents/advisor.md`) sets Opus at `max` effort and
read-only tools, and holds how the advisor works and its answer shape. This prompt carries only the
brief.

```
Agent tool (subagent_type: advisor):
  description: "Advise: [SHORT DECISION]"
  prompt: |
    **Decision:** [ONE QUESTION]

    **Options:**
    [2-4 OPTIONS, EACH WITH ITS TRADE-OFF — OR THE SINGLE CHOICE ABOUT TO BE MADE]

    **Leaning:** [OPTION] — confidence [high | medium | low]

    **Doubt:** [WHAT EXACTLY IS UNCLEAR; QUOTE THE HEDGE IF THERE IS ONE]

    **Evidence (read these):**
    [PATHS: spec / plan / discovery (with F-n ids) / ADRs / code files + symbols]

    **Constraints (cannot change):**
    [USER TECHNICAL NOTES, BINDING REQUIREMENTS, ADR GUARDS — or "none"]
```
