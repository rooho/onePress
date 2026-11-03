# onePress

> An OpenSpec × Superpowers × Tailwind/shadcn bridge toolkit — install a **complete frontend workflow** into any repository with a single prompt.

onePress targets teams with **no dedicated designer**, where developers drive the work. It solves three concrete problems:

1. **UI by guesswork** → AI derives a `ui_contract` (page archetype / field widgets / state matrix / layout tokens) from the feature description.
2. **Delivery by vibes** → sandbox-as-production: ship a clickable UI scaffold first, verify it in 10 seconds with the floating State Bar, then wire the backend.
3. **Quality by willpower** → second-level static gates (tsc + token purity scan + pure-logic Hook TDD + four-state check) before archive.

First-class support for two harnesses: `.qoder/` and `.opencode/`. Zero runtime dependencies — any model with file read/write access can install it.

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| Target repo | git initialized |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest` (Node 22.12+) |
| AI assistant | Qoder / OpenCode / any agent with file and command access |

---

## 1. Install (~30 seconds)

### 1.1 Fetch the template pack

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/rooho/onePress.git <temp-dir>
cd <temp-dir>
git sparse-checkout set onePress
```

**Verify before continuing** (sparse checkout silently checks out nothing when the path does not exist):

```powershell
Test-Path <temp-dir>\onePress\INSTALL_PROMPT.md     # Windows, must be True
```
```bash
ls <temp-dir>/onePress/INSTALL_PROMPT.md            # macOS / Linux
```

> If the file is missing, the checkout path does not match — stop and inspect the repository layout.

### 1.2 Hand it to the AI

Paste the **full contents** of `<temp-dir>/onePress/INSTALL_PROMPT.md` into the AI assistant inside the target repo. It runs five sections:

```
① Preflight → ② Layered install → ③ Idempotency & upgrade → ④ Acceptance checklist → ⑤ Finalize
```

### 1.3 What gets installed

| Target path | Contents | Layer |
|-------------|----------|-------|
| `.opencode/` | `opencode.json`, `agent/ux-architect.md`, `commands/opsx-{new,apply,verify}.md`, `skills/superpowers-tdd/` | harness |
| `.qoder/skills/onepress-discipline/SKILL.md` | Four iron rules + TDD discipline | harness |
| `.qoder/commands/opsx/*.md` | One reference line added after frontmatter; body untouched | harness |
| `openspec/schemas/superspec/` | `schema.yaml` + 9 templates (10 files) | harness |
| `onePress.lock` | Version and protected-asset manifest | harness |
| `docs/ui-components.md` | Component registry template (empty tables on first install) | project |

---

## 2. The full development workflow

From zero to archive in 5 steps. **All `/opsx:*` commands run at the target repo root** (the directory containing `openspec/`).

| Step | Command | You provide | Output | Pass criteria |
|------|---------|-------------|--------|---------------|
| 1 Contract init | `/opsx:new <change>` | Feature description | `proposal.md`, `design.md` (+ `ui_contract`) | Contract fields map to backend schema |
| 2 Complete artifacts | `/opsx:continue` ×N or `/opsx:ff` | — | `specs/`, `tasks.md`, `plan.md` | `openspec validate --strict` passes |
| 3 Implement | `/opsx:apply` | — | Code + `apply.md` | Stage 1 State Bar acceptance |
| 4 Verify | `/opsx:verify` | — | `verify.md` | All four gates green, no CRITICAL |
| 5 Archive | `/opsx:archive` | — | Main specs updated, `finalize.md`, archived dir | Components appended to registry |

### Step 1 — Contract init `/opsx:new`

```text
/opsx:new feat-261103-001-user-role-permission
```

What happens:

1. `ux-architect` (subagent on OpenCode, inlined skill on Qoder) searches `docs/ui-components.md`; reusable components must appear in `reuse_components`;
2. Backend fields map one-by-one to widgets and null-degradation rules;
3. The page scaffold picks exactly one of five archetypes: `Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`;
4. The contract is written at the bottom of `openspec/changes/<change>/design.md`.

Contract example:

```yaml
ui_contract:
  archetype: "Standard-CRUD-Table"
  reuse_components: ["DataTable", "RoleBadge"]
  schema_mapping:
    - field: "user.role"
      widget: "Select"
      rule: "required | default: member"
  states_matrix:
    query: { loading: "equal-height Skeleton", empty: "EmptyState + reset", error: "Alert + retry" }
    mutation: { submitting: "disabled + Loader2", destructive_guard: "AlertDialog confirmation" }
  layout_tokens:
    container: "max-w-7xl mx-auto p-6 space-y-6"
```

**Human review point**: check the contract only (field mapping, state matrix, reused components) — no code exists yet.

### Step 2 — Complete artifacts `/opsx:continue` / `/opsx:ff`

superspec defines 9 artifacts; `/opsx:continue` produces **one per invocation**:

```text
brainstorm → proposal → design → specs → tasks → plan → apply → verify → finalize
```

| Artifact | Purpose |
|----------|---------|
| `brainstorm.md` | Options compared, decision recorded |
| `proposal.md` | Why, what, affected capabilities |
| `design.md` | Decisions (D1…Dn) + risks + `ui_contract` at the bottom |
| `specs/<capability>/spec.md` | Delta spec: `### Requirement:` + `#### Scenario:` (GIVEN/WHEN/THEN) |
| `tasks.md` | Atomic checkable tasks |
| `plan.md` | 2–5 minute micro-steps |
| `apply.md` / `verify.md` / `finalize.md` | Implementation receipt / verification report / closeout receipt |

Generate everything at once: `/opsx:ff`. Proposal only: `/opsx:propose`. Discussion without writing files: `/opsx:explore`.

### Step 3 — Implement `/opsx:apply` (two stages)

| Stage | What | Output | Acceptance |
|-------|------|--------|------------|
| Stage 1 UI scaffold | Render pages from `ui_contract` (mock data + four states) | Clickable page + floating State Bar | Click every state button, confirm by eye in 10 seconds |
| Stage 2 Schema wiring | Connect fields, error codes, permissions, submit logic | Real data flow | Validation and destructive-action confirmation work |

The State Bar drives one state at a time (Idle / Loading / Empty / Error / Submitting). **No DOM unit tests** — verify by eye, guard quality with types and regex gates.

### Step 4 — Verify `/opsx:verify`

Four gates; any failure sends you back to the matching stage of `apply`:

| Gate | Content | Failure example |
|------|---------|-----------------|
| Types | `tsc --noEmit` with zero errors | Misspelled prop |
| Token purity | Static scan of three prohibitions | inline style / `#3b82f6` / `w-[317px]` |
| Pure-logic TDD | Hooks and pure functions tested and passing | Pagination math untested |
| Four-state check | query and mutation states complete | Missing Empty or Error |

Writes `openspec/changes/<change>/verify.md` with one of: `PASS` / `PASS WITH WARNINGS` / `FAIL`. CRITICAL issues block archiving.

### Step 5 — Archive `/opsx:archive`

```text
/opsx:archive
```

1. Delta specs sync into `openspec/specs/<capability>/spec.md` (main specs);
2. Components created or changed are **appended** to `docs/ui-components.md` (append rows only — never reorder or delete history);
3. The change directory moves to `openspec/changes/archive/YYYY-MM-DD-<change>/`;
4. `finalize.md` records the closeout.

Batch: `/opsx:bulk-archive`. Sync specs only: `/opsx:sync`.

---

## 3. Command reference

| Command | Qoder | OpenCode | Purpose |
|---------|:-----:|:--------:|---------|
| `/opsx:new <name>` | ✅ | ✅ | Contract init (proposal + design + ui_contract) |
| `/opsx:continue` | ✅ | CLI | Produce the next artifact |
| `/opsx:ff` | ✅ | CLI | Produce all remaining artifacts |
| `/opsx:propose` | ✅ | CLI | Full proposal in one step |
| `/opsx:explore` | ✅ | — | Discussion only, no files |
| `/opsx:apply` | ✅ | ✅ | Two-stage implementation |
| `/opsx:verify` | ✅ | ✅ | Four gates |
| `/opsx:sync` | ✅ | CLI | Sync delta specs only |
| `/opsx:archive` | ✅ | CLI | Archive + registry append |
| `/opsx:bulk-archive` | ✅ | CLI | Archive several changes |

- **Qoder**: `openspec init --tools qoder` generates the 10 commands; onePress only adds the skill and a one-line reference.
- **OpenCode**: only `new` / `apply` / `verify` ship with this pack; use the CLI for the rest:

```bash
openspec status --change <name> --json          # progress and next step
openspec instructions <artifact> --change <name> --json
openspec validate <name> --strict               # spec validation
openspec archive <name> --yes                   # archive and sync specs
```

---

## 4. Change naming convention

```text
{type}-{YYMMDD}-{NNN}-{slug}

Display layer (docs / commits / chat):  FEAT-261103-001-user-role-permission
Tool layer (directory name, lowercase): feat-261103-001-user-role-permission
```

- `type`: `feat` / `fixbug` / `refactor` / `perf` / `docs` / `chore` / `test` / `revert` — exactly one per change;
- `YYMMDD`: creation date; `NNN`: same-day counter starting at `001`;
- `slug`: 1–10 English words, kebab-case, describing the feature rather than a task list;
- OpenSpec forces lowercase kebab-case for directory names; uppercase is display-only;
- Archive prepends `YYYY-MM-DD-` automatically.

Full details: `onePress/openspec/CHANGE_NAMING.md`.

---

## 5. Asset layering and upgrades

| Layer | Assets | Upgrade behavior |
|-------|--------|------------------|
| harness (maintained by onePress) | `commands/`, `skills/`, `opencode.json`, `openspec/schemas/superspec/` | Full overwrite (delete then write) |
| project (owned by target repo) | `docs/ui-components.md`, `openspec/changes/` | Skip if exists (Protect Local), never overwritten |
| local modifications | Uncommitted harness edits in the target repo | Prompt and skip |

Upgrade = re-run the same install flow with the new version; `onePress.lock`'s `version` decides "fresh install" vs "upgrade". A missing or corrupt lock means fresh install — project-level assets stay protected.

Uninstall: remove everything except `protectedAssets` from `onePress.lock` (`.opencode/`, `.qoder/skills/onepress-discipline/`, `openspec/schemas/superspec/`), keeping `docs/ui-components.md` and `openspec/changes/`.

---

## 6. Template pack layout

```text
onePress/
├── README-ch.md            # Chinese README (default)
├── README.md               # English README (this file)
├── VERSION                 # Version (upgrade baseline)
├── ASSETS.md               # Asset manifest (layer + overwrite policy)
├── INSTALL_PROMPT.md       # Install prompt (single entry, five sections)
├── opencode/               # OpenCode harness assets (6 files)
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-{new,apply,verify}.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness assets (1 file)
│   └── skills/onepress-discipline/SKILL.md
├── openspec-schema/superspec/   # Schema installed into target repos (10 files)
└── openspec/               # This toolkit's own spec workspace (not installed)
    ├── config.yaml         # schema: superspec
    ├── CHANGE_NAMING.md    # Change naming convention
    ├── schemas/superspec/  # Identical to openspec-schema/
    ├── specs/              # 4 main specs (18 requirements)
    └── changes/archive/    # Archived changes (full evidence chain)
```

> `openspec/` inside the pack is **this toolkit's own** spec workspace and history; it is never written into target repos. The schema to install lives in `openspec-schema/`.
> Run OpenSpec commands inside `onePress/` (where `openspec/config.yaml` lives).

---

## 7. FAQ

**Q: `onePress/INSTALL_PROMPT.md` is missing after checkout?**
A: `git sparse-checkout set` silently checks out nothing when the path does not exist. Verify with `git ls-tree -r --name-only HEAD | head`, or use `git sparse-checkout disable` for a full checkout.

**Q: The target repo has no OpenSpec?**
A: Install still completes, but `/opsx:*` and `ui_contract` parsing require OpenSpec. Run `openspec init --tools qoder` (or `--tools opencode`) first.

**Q: OpenCode lacks `/opsx:continue` and `/opsx:archive`?**
A: Only three commands ship with the pack. Use `openspec status` / `openspec instructions` / `openspec archive` instead, or add your own `.opencode/commands/opsx-*.md`.

**Q: Should `.qoder/` and `.opencode/` be committed?**
A: No — they are local environment config. Do commit `onePress.lock` and `docs/ui-components.md`.

**Q: How do I confirm the install?**
A: Three checks — `onePress.lock` exists with the matching `version`; every `.qoder/commands/` file has one `onepress-discipline` reference line; `openspec/schemas/superspec/` has 10 files. Section ④ of the install prompt runs these automatically.

**Q: Will my existing `.qoder/` be damaged?**
A: No. onePress only adds a skill file and inserts one reference line after the frontmatter; command bodies are untouched.

---

## License

MIT
