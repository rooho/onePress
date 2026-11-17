# Apply Receipt

> Generated at the end of the apply phase to mark code-implementation
> complete and provide verify with the state it needs.
> Overwritten on each apply iteration; iteration counter grows.

**Change**: `<change-name>`
**Iteration**: `1`
**Applied at**: `YYYY-MM-DD HH:mm`
**Executor**: `subagent-driven-development` | `executing-plans` | `inline-2c`

---

## Workspace

- **Worktree**: `.worktrees/<change-name>/` (or `single-workspace`)
- **Branch**: `<branch-name>`

---

## Commits

- **Range**: `<from-sha>..<to-sha>` (or `none` if nothing committed yet)
- **Count**: `<n>`

---

## Tasks

- **Completed**: `X of Y` checkboxes in tasks.md flipped to `- [x]`
- **Remaining**: `<list ids of unfinished tasks, or "none">`

---

## TDD Evidence

> Paste real output only. No speculative wording.

| Task | RED (failing test + exit code) | GREEN (passing run) | REFACTOR (final run) |
|---|---|---|---|
| `<task id>` | `<test name; exit code>` | `<command; exit code>` | `<command; exit code>` |

**TDD exceptions** (docs/config-only tasks):

- `<task id>`: `TDD: N/A (<reason>)`

If a GREEN claim has no matching RED run, record here that the ghost code
was deleted and the task returned to RED.

---

## Root-Cause Log

| # | Trigger | Earliest cause / data source | Hypothesis | Experiment | Outcome |
|---|---|---|---|---|---|
| 1 | `<failing test or error>` | `<file:line>` | `I think X is the root cause because Y` | `<smallest change>` | `confirmed / disproved (reverted)` |

Write `None` when no unexpected failure occurred.

---

## Task Evidence

```text
$ <command for the last completed task>
...
exit code: <0>
```

```text
$ <test / build / lint command>
...
exit code: <0>
```

---

## Spec Drift

- `<requirement id>` → `<task id>` (or `None`)

---

## Next step

`<e.g., "Run the verify-report artifact" or "Re-run apply to address <issue>">`
