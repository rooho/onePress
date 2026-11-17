## 1. <!-- Task Group Name -->

- [ ] 1.1 <!-- task description --> — files: `exact/path/to/file`, `exact/path/to/test` — verify: `exact command`
  - [ ] RED: <!-- failing test name + exact assertion / expected failure -->
  - [ ] GREEN: <!-- minimal implementation that makes the test pass -->
  - [ ] REFACTOR: <!-- cleanup with tests still green -->
- [ ] 1.2 <!-- docs/config task description --> — files: `exact/path/to/file` — verify: `exact command`
  - TDD: N/A (<!-- reason: pure docs / config, no logic branch -->)

## 2. <!-- Task Group Name -->

- [ ] 2.1 <!-- task description --> — files: `exact/path/to/file` — verify: `exact command`
  - [ ] RED: <!-- failing test -->
  - [ ] GREEN: <!-- minimal implementation -->
  - [ ] REFACTOR: <!-- cleanup -->

<!-- Rules:
- Each top-level checkbox is a 2-5 minute cognitive unit.
- Every task names its exact file paths in backticks and a verify command.
- Logic tasks nest RED / GREEN / REFACTOR checkboxes.
- Docs/config tasks write `TDD: N/A (<reason>)` instead of nesting RGB.
-->
