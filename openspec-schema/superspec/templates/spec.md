<!--
Delta spec template for a change.

This template demonstrates 4 delta section types — use as needed:
- ADDED / MODIFIED / REMOVED / RENAMED
File name and location: openspec/changes/<change-name>/specs/<capability>/spec.md
(`<capability>` matches the openspec/specs/<capability>/ directory name)

Hard formatting rules (validated by OpenSpec):
- Requirement sentences MUST contain `SHALL` or `MUST`
- Each Requirement MUST have at least one `#### Scenario:`
- Scenarios MUST use level-4 (`####`) — level-3 or bullet will silently fail
- V3.2: every scenario MUST use GIVEN / WHEN / THEN with an observable,
  testable outcome; cover at least one error path or boundary input per
  capability. A scenario is a test case, not an echo of the implementation.
-->

## ADDED Requirements

<!-- New behavior. List new Requirements this change adds to the capability. -->

### Requirement: <!-- requirement name -->
<!-- requirement text — 須含 SHALL 或 MUST -->

#### Scenario: <!-- scenario name -->
- **GIVEN** <!-- precondition -->
- **WHEN** <!-- condition -->
- **THEN** <!-- observable, testable outcome -->

---

## MODIFIED Requirements

<!--
Modify existing Requirements. **MUST use the exact normalized header from
openspec/specs/<capability>/spec.md** (case-sensitive match after trim),
otherwise the delta apply during archive will fail to find the matching requirement.

**MUST include the full modified content** (not just the diff), because OpenSpec
archive applies MODIFIED sections via full-text replacement.
-->

### Requirement: <!-- same header as in the existing spec -->
<!-- full modified requirement text — must contain SHALL or MUST -->

#### Scenario: <!-- scenario name (can be new or modified) -->
- **GIVEN** <!-- precondition -->
- **WHEN** <!-- condition -->
- **THEN** <!-- observable, testable outcome -->

---

## REMOVED Requirements

<!--
Remove existing Requirements. MUST include Reason and Migration notes so reviewers
understand why it was deprecated and how existing consumers should migrate.
-->

### Requirement: <!-- header to remove, must exactly match the existing spec -->

**Reason**: <!-- why it is being removed -->

**Migration**: <!-- how existing callers/dependents should adapt -->

---

## RENAMED Requirements

<!--
Rename a Requirement header. Fixed format: FROM / TO using code-fence headers.
If both name and content change, list the name change here in RENAMED **and**
write a full entry under MODIFIED using the **new** header.

Archive apply order: RENAMED -> REMOVED -> MODIFIED -> ADDED
-->

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`
