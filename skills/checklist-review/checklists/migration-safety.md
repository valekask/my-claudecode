# Migration Safety Checklist

Covers schema/data migrations (database) **and** persisted client-state schema changes
(localStorage, IndexedDB, cached/hydrated state). Apply the relevant items to whichever
form of persisted data the change touches.

---

## Backward Compatibility

- [ ] **MG-1**: "Is the migration backward-compatible with currently deployed code (expand before contract)?"
  → Check: New columns/fields are additive; the old code keeps working against the new schema during rollout. Destructive changes (drop/rename) are split into expand → migrate → contract phases.
  → FAIL: A column/field is dropped or renamed in the same step the code starts depending on it, breaking the previous version during deploy/rollback.

- [ ] **MG-2**: "Are new non-nullable columns/fields given a default or backfilled before the NOT NULL constraint?"
  → Check: Adding a required column on a populated table sets a default or backfills existing rows before enforcing NOT NULL.
  → FAIL: A NOT NULL column is added with no default to a table that already has rows — the migration fails or leaves invalid rows.

- [ ] **MG-3**: "For persisted client state, is there a version + upgrade path for old shapes?"
  → Check: localStorage/IndexedDB/hydrated-state reads tolerate data written by a previous app version (version key + migration, or defensive parsing).
  → FAIL: New code reads persisted state assuming the new shape; a returning user with the old shape gets a crash, blank state, or silent data loss.

## Reversibility & Recovery

- [ ] **MG-4**: "Is the migration reversible (down migration) or is irreversibility justified?"
  → Check: A down/rollback path exists, or the migration is explicitly documented as one-way with reasoning.
  → FAIL: A destructive migration has no rollback and no justification — a bad deploy can't be backed out.

- [ ] **MG-5**: "Does rollback avoid data loss?"
  → Check: Rolling back the migration (or deploying the previous app version) doesn't discard data written in the meantime.
  → FAIL: The down migration drops a column that the new code populated, losing user data on rollback.

- [ ] **MG-6**: "Is the migration idempotent / safe to re-run?"
  → Check: Re-running (after a partial failure or duplicate trigger) doesn't error or double-apply (`IF NOT EXISTS`, guards, upserts).
  → FAIL: Re-running the migration throws (column already exists) or duplicates data.

## Execution Safety

- [ ] **MG-7**: "Is the migration safe on production data volume (locks, long transactions)?"
  → Check: Operations on large tables (index creation, column rewrites, type changes) use non-blocking variants or batching; long transactions won't hold locks that stall the app.
  → FAIL: A blocking ALTER / index build on a large table locks it for the duration, causing downtime under production volume.

- [ ] **MG-8**: "Are large data backfills batched rather than single-statement?"
  → Check: Backfilling many rows is chunked to avoid huge transactions, replication lag, and memory blowups.
  → FAIL: A single `UPDATE`/loop rewrites millions of rows in one transaction.

- [ ] **MG-9**: "Are foreign keys, cascades, and constraints validated against existing data?"
  → Check: Adding a constraint (FK, UNIQUE, CHECK) accounts for existing rows that may violate it; cascade rules won't unexpectedly delete data.
  → FAIL: A constraint is added that existing rows violate (migration fails), or a new `ON DELETE CASCADE` can wipe related records.

## Correctness & Coordination

- [ ] **MG-10**: "Is the data transformation in the migration correct and tested?"
  → Check: Value mapping / type conversion / splitting-merging columns preserves meaning; tested against representative (incl. edge-case) data.
  → FAIL: The transformation drops precision, mishandles null/empty/legacy values, or corrupts a subset of rows.

- [ ] **MG-11**: "Is enum / type narrowing safe for existing values?"
  → Check: Removing an enum value or narrowing a type accounts for rows/state still holding the old value.
  → FAIL: An enum value is removed while existing rows still use it, breaking reads or constraints.

- [ ] **MG-12**: "Does code that depends on the migration ship in the correct order?"
  → Check: Migration and the code that requires it are sequenced so neither half runs against an incompatible counterpart (migrate-then-deploy, or feature-flagged).
  → FAIL: New code is deployed expecting a column that the migration hasn't created yet (or vice versa), causing runtime errors during the window.

---

Total items: 12
