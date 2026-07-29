---
name: herdr
description: Spawn and drive fresh Claude sessions in Herdr terminal tabs. Use when you need a new isolated session for a subtask — a fresh tab pointed at a working tree, running a slash command as its opening prompt — instead of opening one by hand, and to watch/read/close it afterwards. Pure terminal-session mechanics; the caller supplies all policy (which trees are off-limits, which command to run, where to record the spawn). Use for "open a session for X in its own tab", "run this in a new session", "spawn a subtask session", or as the launch primitive an orchestrator calls.
---

# Herdr

[Herdr](https://herdr.dev) is a tmux-like, **agent-aware** terminal workspace
manager. This skill is the mechanical primitive for **spawning a fresh Claude
session in its own tab** and driving it — so surfacing a subtask ("time to work
on X") and *starting* it are one step, not "now go open a tab by hand." **Fresh
tab = fresh session = clean context** per unit of work, which is exactly what
isolated subtask work wants.

This skill carries **no project knowledge**. It knows *how* to spawn and drive
sessions; *what* is off-limits, *which* command to run, and *where* to track the
spawn are decided by the caller (you, by hand, or an orchestrator that wraps
this skill) — see **Caller-supplied policy** below.

**Announce at start:** "I'm using the herdr skill."

## When this applies

- You're running **inside a Herdr pane** (`HERDR_ENV=1`). If it's unset, say so
  and stop — there's no server to talk to; fall back to asking the user to open a
  session by hand.
- Something needs a **fresh, isolated session**: a subtask of the work in flight,
  a parallel task, or a phase you want to run with clean context.

It is safe to call the Herdr **control subcommands** (`tab`, `pane`, `agent`,
`wait`) from inside a pane — that's their purpose. The "never run `herdr` inside
a Herdr pane" warning is only about launching the **bare TUI client** (`herdr`
with no subcommand) recursively. Don't do that.

## The spawn helper

`./herdr-spawn.sh` (next to this file) does the one reliable "fresh tab" recipe
and enforces any caller-supplied guardrails. Prefer it over hand-rolling the CLI.

```sh
<skill-dir>/herdr-spawn.sh \
  --cwd <working-tree> --label '<short label>' --prompt '<initial prompt>' \
  [--workspace <id>] [--focus] [--allow <path> ...]
```

- **`--cwd`** — where the session starts. Absolute or `~`-relative.
- **`--label`** — the tab label (shows in Herdr's tab bar). A readable
  `<verb> <subject>` like `implement FNA-16973` or `brainstorm login-flow`.
- **`--prompt`** — the initial prompt, **auto-submitted** into the fresh Claude.
  A slash command works: `'/prepare FNA-16973'`. (Verified: `claude "<prompt>"`
  starts with that prompt already submitted.) **Long prompts are safe:** a prompt
  that is long (>200 chars), multi-line, or contains a double-quote is auto-stashed
  to a temp brief file and launched via a short `Read <file> and follow it.`
  pointer — because `pane run` truncates a long typed line, which would leave an
  unclosed quote and silently fail to start claude. The `SPAWNED` line then
  includes `brief=<file>`. You can also hand-author a brief file yourself and pass
  a short pointer prompt when you want the brief to live somewhere durable.
  **Slash commands are the exception — they are sent inline, verbatim, and so
  cannot be rescued by stashing** (the session would receive the pointer text
  instead of the command). One longer than **400 chars is rejected** (exit 2)
  rather than truncated silently. Keep a slash prompt to the command plus paths —
  real ones are well under that — and put anything longer in a file the session
  reads. **A project skill isn't reachable from another cwd:** project skills load
  from the *cwd's* `.claude/skills/`, so to run one in a tab opened elsewhere, pass
  `'Follow <abs path>/SKILL.md for <subject>.'` instead of its slash name.
- **`--workspace`** — which Herdr *space* the tab is created in. **Defaults to the
  spawning session's own workspace (`$HERDR_WORKSPACE_ID`)** — "where it was
  requested" — so the tab lands in the caller's space, **not** whatever space
  you've manually focused at the moment of the call. (`--cwd` is the pane's
  directory; `--workspace` is a *separate* concept — omit it and Herdr drops the
  tab into the focused space, which races with manual switching.) Override only
  when you deliberately want another space.
- **`--focus`** brings the new tab forward; **the default is background**
  (`--no-focus`) — just create the session and start the work; open it when you
  need it. (No focus-stealing: right for autonomous batches and quiet hand-offs.)

On success it prints one line — **record it wherever your workflow tracks
sessions** (a caller's log, a worklog) so the session stays trackable:

```
SPAWNED tab=w1:t8 pane=w1:pB ws=w1 cwd=/Users/you/project :: claude "/prepare FNA-16973"
```

## Containment — spawns stay inside the current project (default-deny)

The helper **refuses to spawn a session outside the project you invoke it from**,
so a session can't wander into a sibling tree by accident. This needs no config:

- **Default allowed base** = the **git top-level** of the invoking directory
  (`$PWD` where the helper runs — i.e. the spawning session's cwd), or that
  directory itself if it isn't a git repo. A `--cwd` that isn't the base or a
  subtree of it is **REFUSED** (exit 3).
- **`--allow <path>`** (repeatable) — permit an **additional** base for a
  deliberate cross-tree spawn (e.g. spawning into a worktree that lives outside
  the project you're driving from). The default base still applies; `--allow`
  only widens it.

The helper resolves both `--cwd` and every base to real absolute paths before
matching, so containment can't be dodged via `~`, a relative path, or a symlink.

Examples of the guard:
- Invoked from `~/repoA`, `--cwd ~/repoB/sub` → **refused** (repoB isn't under
  repoA); add `--allow ~/repoB` to permit it.
- Invoked from `~/repoA/libs/x`, `--cwd ~/repoA/apps/y` → **allowed** (same repo:
  the base is repoA's git top-level, not the subdir).

## Driving spawned sessions (the CLI you'll use)

IDs are namespaced (`w1:t8`, `w1:pB`) and **not durable** — they compact when
tabs/panes close, so **re-read them from `agent list` when you need current
ones**, don't cache across closes.

| Need | Command |
|---|---|
| List live agents (pane/tab/cwd/status, JSON) | `herdr agent list` |
| Wait until a session settles | `herdr agent wait <pane> --timeout <ms>` |
| Wait until it's blocked on input | `herdr agent wait <pane> --until blocked --timeout <ms>` |
| Read what a session printed | `herdr pane read <pane> --source recent --lines <n>` |
| Bring a session forward | `herdr tab focus <tab>` / `herdr agent focus <pane>` |
| Send a follow-up prompt | `herdr agent prompt <pane> '<text>' [--wait --timeout <ms>]` |
| Send a command (text + Enter) | `herdr pane run <pane> '<cmd>'` |
| Tear a session down | `herdr tab close <tab>` |

**Waiting — read this before writing a watcher** (verified 2026-07-25; earlier
revisions of this file named a `herdr wait agent-status … --status …` that does
**not exist**, and an `herdr agent send` that does not exist either):

- The command is **`herdr agent wait <target> [--until <status>] [--timeout <ms>]`**,
  where `<status>` ∈ `idle | working | blocked | done | unknown`.
- **A session that has finished its turn reports `done`, not `idle`.** Pinning a
  watcher to `--until idle` **times out** against an agent that already answered —
  this was the original cause of the wrong guidance here.
- **So omit `--until`.** The default matches `idle`, `done`, *or* `blocked`, which is
  exactly what a watcher wants. Then check *which* state you settled into: `blocked`
  means **waiting on human input**, not finished — don't read its output as a final
  result.

`agent list` JSON, per agent: `pane_id`, `tab_id`, `workspace_id`, `agent`,
`agent_status` (`idle`/`working`/`blocked`/`done`/`unknown`), `cwd`, plus
`agent_session.value` (the session id) and `state_change_seq` (a monotonic counter
— useful to detect that a human typed into the pane since you last looked). Parse
with `python3`/`jq`. The env inside any pane exposes `HERDR_WORKSPACE_ID` /
`HERDR_TAB_ID` / `HERDR_PANE_ID` / `HERDR_SOCKET_PATH`.

**Why not `herdr agent start`?** It treats `-- <argv>` as the *whole* command and
**splits** the current/target tab (and ignores `--cwd`) instead of making a clean
fresh tab. The `tab create` + `pane run` recipe in the helper is the verified way
to get one clean pane per fresh session.

## Orchestration pattern — one orchestrator, many task sessions

The common shape: **one long-lived orchestrator** session (owns the plan, the
decisions, and the human) delegates jobs to **task sessions** — fresh sessions that
do one job and report back. Keep it lightweight:

- **Brief in (a file).** The orchestrator writes the task's instructions to a file
  (e.g. under a git-ignored `…/.temp/`), then spawns a session pointed at it
  (`--prompt 'Read <brief> and follow it.'`). A file brief avoids `pane run`'s
  long-line truncation and gives the task durable, complete instructions.
- **Result out (a terminal RESULT block).** Tell the task session to **end with a
  self-contained, marker-bracketed result block** so the orchestrator can read just
  that, not the whole scrollback:

  ```
  === RESULT ===
  <concise verdict + the findings the orchestrator needs to act>
  === END ===
  ```

  Reserve **files** for results a downstream step must *parse* (e.g. `smoke-test`'s
  verdict `.json`); for everything else the terminal block keeps file sprawl down.
- **Read it safely (wait, then confirm).** Spawn `--no-focus`; wait for the pane to
  **settle** (`herdr agent wait <pane> --timeout <ms>` — no `--until`; see "Waiting"
  above), **then** read the RESULT block (`herdr pane read <pane> --source recent`).
  If you settled into `blocked`, the worker is asking a question, not done. If the block isn't there
  yet, the session either hadn't started (a spurious early idle) or is still
  composing — **wait again and re-read.** Don't parse a half-written result.
- **Fire-and-complete.** A task session does its job, prints its result, and
  **stops** — it never waits for a follow-up. Follow-up work is a **new** task the
  orchestrator dispatches (or a follow-up prompt the orchestrator sends
  deliberately). This prevents a half-typed prompt lingering in an idle tab.
- **Lifecycle — keep open until done, then tear down.** Leave the tab open while the
  orchestrator might still use it (send follow-ups via `herdr pane run <pane> '…'`);
  **close it (`herdr tab close <tab>`) once its result is consumed and you're sure
  it's done** — otherwise task tabs accumulate. A persistent browser/auth session
  survives the tab close (it lives on disk), so a later task can reuse it.

Management's `run-queue` (orchestrator) + `smoke-test-mgmt` (fire-and-complete
worker writing a verdict `.json`) are the specialized, file-seam instance of this
pattern.

## Phase advances within one unit of work — reuse the tab, `/clear` between phases

A task's lifecycle often runs through several phases (e.g.
`prepare → brainstorming → writing-plans → subagent-driven-development → ship`). **Don't
spawn a fresh tab per phase** — that proliferates tabs. Instead keep one tab per
task for its whole lifecycle and use `/clear` as the phase boundary:

- **One tab per task.** A new tab (via the spawn helper) is only for a *different*
  task — i.e. true parallel work, fully isolated. Tabs are the **parallelism
  axis** (one per simultaneously-worked task); `/clear` is the **phase axis**
  within a tab.
- **`/clear` = the phase boundary.** Before kicking off the next phase, clear the
  session's context so the phase starts genuinely fresh — context-equivalent to a
  new tab, without the new tab. The next phase reads its input from the on-disk
  artifact, so nothing is lost:

  ```sh
  # capture the session id first — it changes on clear, which is your confirmation
  before=$(herdr agent list | jq -r '.result.agents[]|select(.pane_id=="<pane>")|.agent_session.value')
  herdr agent prompt <pane> '/clear'        # exits non-zero with agent_prompt_stalled — expected, see below
  after=$(herdr agent list | jq -r '.result.agents[]|select(.pane_id=="<pane>")|.agent_session.value')
  [ "$before" != "$after" ] || echo "WARNING: clear did not land"
  herdr agent prompt <pane> '/<next-skill> on <artifact-path>' --wait --timeout 600000
  ```

  **Two gotchas, both verified — an automated driver must handle them:**

  - **`/clear` reports a false failure.** It returns
    `agent_prompt_stalled: agent prompt produced no observed state change`. A
    client-side slash command never puts the agent into `working`, so there is no
    state change to observe — **the command did execute.** Whitelist this specific
    error for slash commands, or your driver will conclude every clear failed.
  - **A clear mints a new `agent_session.value`.** That id change is the only
    reliable *confirmation* the clear landed, so compare it rather than trusting the
    send. (Verified by planting a codeword before the clear and finding it gone
    after.)

  Driving `/clear` in from outside genuinely works, which is what makes this phase
  axis automatable instead of a manual step.

- **Always pass the artifact path explicitly** — the cleared session has no memory
  of which task/file it was on. e.g.
  `/brainstorming on <task-dir>/<task>-<slug>-proposal.md`.
- **Rename the tab to the new phase** (the old label goes stale):
  `herdr tab rename <tab> '<phase> <subject>'`.

Caveat: `/clear` wipes Claude's *context*, not the terminal scrollback — the prior
phase's output stays visible in the pane (cosmetic only; the on-disk artifact is
the durable record).

## Typical flows

**Spawn one subtask session (background, in the caller's own workspace — both are
the defaults):**
```sh
./herdr-spawn.sh --cwd ~/project \
  --label 'brainstorm login-flow' --prompt '/brainstorming on .claude/temp/login-flow/proposal.md'
```

**Spawn into a worktree outside the current project (bring it to the front):**
```sh
# invoked from ~/driver-project; target lives elsewhere → widen the base with --allow
./herdr-spawn.sh --cwd ~/other-repo/.worktrees/my-slug --focus \
  --label 'implement FNA-16973' --prompt '/executing-simple' \
  --allow ~/other-repo
```

**Spawn a fire-and-complete worker in the background and wait for it:**
```sh
./herdr-spawn.sh --cwd ~/project --no-focus \
  --label 'verify FNA-16973' --prompt '/smoke-test'
herdr agent wait <pane> --timeout 300000   # give slow work headroom; no --until (see "Waiting")
```

## Rules

- **`HERDR_ENV=1` or stop.** No server outside a pane.
- **Containment is default-deny** — spawns are confined to the current project;
  don't bypass the helper to dodge the check. Widen deliberately with `--allow`.
- **Record every spawn** (tab/pane id + what it's running) wherever the workflow
  tracks sessions, so they stay trackable; re-read ids from `agent list` (they're
  not durable).
- This skill **launches and drives** sessions; it does not push, commit, or touch
  external trackers. The spawned session follows its own prompt's/skill's rules.
- **One tab per task, not per phase** — advance phases within a task in the same
  tab via `/clear` (see above); spawn a new tab only for a *different* task. Never
  pile multiple tasks into one session (defeats the clean-context point).
