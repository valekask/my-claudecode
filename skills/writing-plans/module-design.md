# Module Design

Rules for building deep modules: complex logic hidden under a simple contract. `brainstorming`
designs to them, `writing-plans` lays out files by them, and the plan reviewer checks the plan
against them. Apply them to code you write; in code you touch, don't make it worse.

Each rule has a **Check** — a concrete signal that the rule is broken. A signal is a reason to
read the code and decide, not an automatic failure.

## Rules

1. **Explicit, minimal contract.** The contract shows what the feature does and hides how. Every
   input arrives through it — method parameters, `@Input`, or a snapshot of values taken at the
   call. Never read an input from a global, and never let the caller set public fields.
   - Check: a parameter replaced by an injected global; a public mutable field on a service that
     callers write before calling it.

2. **One owner per behaviour.** A feature's decisions, rules, state and the code that changes that
   state live in one owner — a ComponentStore or service. Its steps are private. A helper that
   decides what happens is a private method of the owner. Everyone else uses the owner only
   through its contract.
   - Check: the same behaviour decided in two places; a component or util making a decision the
     owner should make; a consumer that must know the owner's internal steps to use it.

3. **State is one named value.** A process or result is one union type keyed by a `status` or
   `kind` field, with the data each state needs. Refused, cancelled and failed come back to the
   caller as state or data, not only as notifications.
   - Check: flags derived from nullable fields (`isX = y !== null`); one field standing for
     several states; more than 4 changeable fields on one owner (ask whether one union replaces
     them); an outcome visible only as a side effect.

4. **Utils compute, never decide.** A util is a pure function for conversion, formatting or
   math. It never returns a mode, tier or flag for the caller to branch on, and never shows a
   message. A feature's own `.utils.ts` may be domain-specific; a shared utils library may not.
   New code starts in the feature that uses it and moves to a shared library only when a second
   consumer exists.
   - Check: a util returning a mode string or boolean policy; a util with side effects; a new
     shared util with one consumer.

5. **Few files per flow; split only for a complete job.** Count the files a reader must open to
   answer one user question ("what happens when I click Export?"). Fewer is easier to understand
   and change. Move a part into its own file only when it is a complete job with its own contract
   and moving it out makes the owner easier to understand.
   - Check: a file in the flow that only passes calls through; a split that leaves the owner's
     logic spread across files a reader has to combine.

6. **Test through the contract.** Test a feature by using its public contract and checking what
   its consumers see. Never widen the contract so a test can reach inside.
   - Check: an export used only by specs; a layer, injection token or wrapper whose only other
     user is a test.

## Flow map

A Flow map lists, for each main user question the change serves, the production files a reader
opens to follow it, in reading order, with one line on what each file does in that flow:

```markdown
**"What happens when I click Export?"** — 5 files (today: 12)
1. `export-menu.component.ts` — the click; calls `exportService.export(context)`
2. `graph-export.service.ts` — owner: job state, tier policy, cancel
3. ...
```

**What counts:** production `.ts` files and templates (`.html`) a reader opens to answer the
question. Not counted: specs, pure type/model files, barrel `index.ts` files and styles. Count the
same way for every option so the numbers compare.

Use it to **compare options**, never as a score. A count means something only next to another:
today's path (from the discovery file), an alternative approach, or a sibling feature that reads
well. Never meet a lower count by merging unrelated jobs into one file — rule 5 cuts both ways.
