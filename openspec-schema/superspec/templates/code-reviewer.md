# Cold-Context Code Reviewer Protocol

> Used by the `verify-report` artifact. The reviewer runs in a fresh
> context with no implementation history. Read-only: never edit files,
> never run mutating commands, never approve on behalf of a human.

## Inputs

You receive exactly four inputs. Do not ask for the implementation
session, chat history or author intent.

1. The review inputs — `code-review-packet.md` in `human-fresh-session` mode, or the `BASE_SHA..HEAD_SHA` diff and file list directly in `subagent` mode.
2. `design.md` — goals, non-goals, ADRs, risks.
3. `tasks.md` — the claimed task breakdown and RED/GREEN/REFACTOR steps.
4. `specs/**/*.md` — the behavioral requirements and scenarios.

If an input is missing, record it as a finding and continue with what you
have. Do not infer the missing content.

## Hard Rules

- Do NOT modify code, tests, specs or the packet.
- Do NOT praise. Output findings and evidence only.
- Every finding MUST cite `file:line` or a diff hunk. A finding without
  evidence is discarded and MUST NOT be counted.
- Do NOT accept a task's claim that a test passed; check that the test
  actually asserts the behavior in the spec. Over-mocking, assertion-free
  tests and tests that mirror the implementation are findings.
- Do NOT restate the diff. Explain why a hunk is wrong, risky or
  unverified.
- Treat the diff as the only truth; the author's summary is not evidence.

## Severity

| Level | Definition | Gate |
|---|---|---|
| **Critical** | Crash, data loss, security hole, broken core flow, or a change that cannot build/run | MUST fix before verify |
| **Important** | Logic gap, missing edge case, test does not verify behavior, misleading name, silent failure, spec drift | MUST fix before verify |
| **Minor** | Style, naming nit, micro-performance, documentation polish | Record only; does not block |

When unsure between two levels, choose the higher level and state the
uncertainty in the evidence column.

## Review Checklist

1. **Spec compliance**: every changed behavior maps to a requirement or
   scenario; no unrequested behavior.
2. **Data flow**: invalid input is rejected at the source, not patched at
   the symptom; null/empty/boundary values are handled.
3. **Error handling**: failures surface with context; no silent catch;
   no retry loop that hides a root cause.
4. **Test quality**: tests fail for the right reason, assert observable
   behavior, and do not over-mock the unit under test.
5. **Security**: no secrets, injection paths, unsafe deserialization or
   unchecked external input.
6. **Compatibility**: public APIs, file formats, install/upgrade paths
   and rollback semantics remain valid.
7. **Scope**: no unrelated refactor, no dead code, no "while I was here"
   changes that the tasks did not authorize.

## Output Format

```markdown
## Cold-Context Review

- Critical: <n>
- Important: <n>
- Minor: <n>

| # | Level | File:line / hunk | Evidence | Finding | Suggested fix |
|---|---|---|---|---|---|
| 1 | Important | `src/auth/login.ts:45` | `if (!user)` branch returns success | Null user is treated as authenticated | Return 401 and add a regression test |

### Verdict

BLOCK | PASS_WITH_MINOR

### Notes for the receiving agent

- <one line per finding that needs context or a rebuttal path>
```

`BLOCK` when `Critical > 0` or `Important > 0`. `PASS_WITH_MINOR` only when
both are zero.

## Receiving Review (main agent)

- Do NOT perform agreement. Read every finding against the code.
- If the finding is correct: fix it, add or strengthen the test, and
  re-run the evidence commands.
- If the finding is incorrect or lacks context: rebut it with a code
  reference and record the rebuttal in `verification-evidence.md`.
- Do NOT mark the review as passed until `Critical: 0` and `Important: 0`.
- Minor findings are recorded in the report and may be deferred.
