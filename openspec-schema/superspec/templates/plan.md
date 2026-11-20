# [Feature Name] Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task. If that skill is unavailable,
> follow apply mode 2c (inline task-by-task) instead — do not stop.
>
> **Execution:** OpenSpec apply phase. Do not pause for a
> subagent-driven/native choice; the apply artifact owns execution.
>
> Run `bash scripts/onepress-plan-lint.sh --change <change-dir>` after
> writing this plan and fix every FAIL. The lint also checks sibling
> `design.md` (ADR / Non-Goals / Risks) and `tasks.md` (exact file paths
> + RED-GREEN-REFACTOR).

**Goal:** <!-- One sentence -->

**Architecture:** <!-- 2-3 sentences -->

**Tech Stack:** <!-- Key technologies -->

**Spec:** `openspec/changes/<change>/specs/**/spec.md` <!-- plus design.md if present -->

---

## Global Constraints

<!-- Copy exact values from the spec/design: version floors, dependency
limits, naming/copy rules, platform requirements. One line each. -->

## Review Focus

<!-- Five input classes or failure modes the spec implies but no task's
tests exercise, most likely first. Each line names the input/condition
and the expected behavior; add the test to the owning task. Write
"None found" only after checking. -->

## Evidence Map

<!-- Every claim the change will make, and the command that proves it.
These commands become the verify-report evidence rows. -->

| Task | Command that proves it | Expected pass signal |
|---|---|---|
| `Task 1` | `exact command` | `<n/n pass, exit 0>` |

## File Structure

<!-- Map every file before defining tasks: path -> single responsibility.
Follow existing project patterns; do not restructure unrelated files. -->

- `exact/path/to/file` — <!-- responsibility -->

<!-- Boundary Matrix: add a `## Boundary Matrix` section when this change parses,
normalises, extracts, classifies, converts units or rounds values. Group rows by
category (extraction / unit / rounding / range / name / date); each category needs
at least three rows and one counter-example; at least 20 rows in total. Row shape:
| category | input | expected | positive or counter-example |
-->

<!-- Subsystems: add `**Subsystems:** a、b` when `## File Structure` exceeds 30
entries or `tasks.md` exceeds 40 items. List at least two subsystem names,
otherwise plan-lint fails. `-->` is not part of the declaration. -->

---

## Task 1: <!-- Component Name -->

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing` (line range if known)
- Test: `exact/path/to/test`

**Interfaces:**
- Consumes: <!-- exact signatures from earlier tasks; "None" if first -->
- Produces: <!-- exact names, parameters, return types -->

- [ ] **Step 1: Write the failing test**

```text
<!-- test name + assertions, with exact values from the spec -->
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `<!-- exact command -->`
Expected: FAIL with `<!-- exact failure -->`

- [ ] **Step 3: Implement the minimal code**

<!-- exact signature, file, and values the spec pins; body only when the
algorithm is not determined by the test/signature -->

- [ ] **Step 4: Run the test and verify it passes**

Run: `<!-- exact command -->`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add <!-- files -->
git commit -m "<!-- message -->"
```

---

## Self-Review

- [ ] Spec coverage: every requirement maps to a task; gaps fixed.
- [ ] Step scan: every step lets the implementer write exactly one reasonable thing; no placeholder steps.
- [ ] Type consistency: names/signatures in later tasks match earlier definitions.
- [ ] Review Focus: every listed failure mode has a test in its owning task.
- [ ] Evidence map: every task names the command that will prove it in verify-report.
- [ ] Proportion: the plan is not longer than the code it describes; code blocks are not transcripts.

**Totals:** <!-- N tasks, M commits -->
