# onePress

> An OpenSpec × Superpowers × Tailwind/shadcn bridge toolkit — install a **complete frontend workflow** into any repository with a single prompt.

onePress targets teams with **no dedicated designer**, where developers drive the work. It solves three concrete problems:

1. **UI by guesswork** → AI derives a `ui_contract` (page archetype / field widgets / state matrix / layout tokens) from the feature description.
2. **Delivery by vibes** → sandbox-as-production: ship a clickable UI scaffold first, verify it in 10 seconds with the floating State Bar, then wire the backend.
3. **Quality by willpower** → second-level static gates (tsc + token purity scan + pure-logic Hook TDD + four-state check) before archive.

First-class support for four harnesses: `.qoder/`, `.opencode/`, `.trae/` and `.cursor/`. Zero runtime dependencies — any model with file read/write access can install it.

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| Target repo | git initialized |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest` (Node 22.12+) |
| AI assistant | Qoder / OpenCode / Trae / Cursor / any agent with file and command access |

---

## 1. Install (one command)

Clone the pack, then run the matching script **at the target repo root**:

```powershell
# Windows (PowerShell 5.1+)
.\install.ps1
```
```bash
# macOS / Linux
./install.sh
```

Common options (equivalent on both sides):

```powershell
.\install.ps1 -Harness qoder     # Qoder only (default auto: detect .qoder/ / .opencode/ / .trae/ / .cursor/)
.\install.ps1 -Harness trae,cursor  # Trae + Cursor only
.\install.ps1 -Target D:\repo    # explicit target repo
.\install.ps1 -DryRun            # print the plan, write nothing
.\install.ps1 -Source D:\pack    # pack directory (default: the script's directory)
```
```bash
./install.sh --harness qoder --target ~/repo --dry-run --source ~/pack
```

The script does six things in one go: **detect harness → layered write → align OpenSpec config → write `onePress.lock` → self-check → report**. "Align config" means: create `openspec/config.yaml` (`schema: superspec`) when missing, rewrite only that line when the value is wrong (CRLF preserved), and run `openspec init --tools qoder|cursor` automatically when the corresponding `.qoder/commands/` or `.cursor/commands/` is empty; Trae commands ship with the pack, so no init is needed. Checks cover layout, verbatim content, all 10 schema files, `schema: superspec`, non-empty commands with reference lines, and lock/scope consistency; any failure aborts with a reason. Exit code `0` = success, `1` = failure. Nothing to verify by hand.

> Measured: `openspec init` does **not** overwrite an existing `config.yaml`, so the order "align config → init → mount" is safe. Use `-NoInit` / `--no-init` to disable the automatic init.

Downloaded the script only, no pack? It shallow-clones automatically:

```powershell
.\install.ps1 -Repo https://github.com/rooho/onePress.git -Ref main
```
```bash
./install.sh --repo https://github.com/rooho/onePress.git --ref main
```

> Prefer no script? Hand the full `INSTALL_PROMPT.md` to any file-capable agent; it runs the same five sections and produces byte-identical output.

### Install scope is detected automatically

The script detects which AI coding environment the target repo uses and **installs only that one** — no manual flag needed:

| Detection | What gets installed |
|-----------|---------------------|
| only `.qoder/` | Qoder assets only |
| only `.opencode/` | OpenCode assets only |
| only `.trae/` | Trae assets only |
| only `.cursor/` | Cursor assets only |
| several present | every detected harness |
| none present | asks which to use (Qoder / OpenCode / Trae / Cursor / all) — **never installs all by default**; pass `-Harness` / `--harness` for unattended runs |

The unselected harness gets no directory created and no files written. `onePress.lock`'s `harnesses` records the actual scope (`false` for the one not installed), and upgrades only overwrite the enabled harness.

### What gets installed

| Target path | Contents | Layer | Installed when |
|-------------|----------|-------|----------------|
| `.opencode/` | `opencode.json`, `agent/ux-architect.md`, `commands/opsx-{new,apply,verify}.md`, `skills/superpowers-tdd/` | harness | OpenCode selected |
| `.qoder/skills/onepress-discipline/SKILL.md` | Four iron rules + TDD discipline | harness | Qoder selected |
| `.qoder/commands/opsx/*.md` | One reference line added after frontmatter; body untouched | harness | Qoder selected |
| `.trae/skills/onepress-discipline/SKILL.md` | Four iron rules + TDD discipline (Trae carrier) | harness | Trae selected |
| `.trae/commands/opsx-{new,apply,verify}.md` | Trae slash commands (reference line included) | harness | Trae selected |
| `.cursor/skills/onepress-discipline/SKILL.md` | Four iron rules + TDD discipline (Cursor carrier) | harness | Cursor selected |
| `.cursor/commands/opsx-*.md` | One reference line added after frontmatter; body untouched | harness | Cursor selected |
| `openspec/schemas/superspec/` | `schema.yaml` + 9 templates (10 files) | harness | always |
| `onePress.lock` | Version, install scope, protected assets | harness | always |
| `docs/ui-components.md` | Component registry template (empty tables on first install) | project | always |

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

| Command | Qoder | OpenCode | Trae | Cursor | Purpose |
|---------|:-----:|:--------:|:----:|:------:|---------|
| `/opsx:new <name>` | ✅ | ✅ | ✅ | ✅ | Contract init (proposal + design + ui_contract) |
| `/opsx:continue` | ✅ | CLI | CLI | ✅ | Produce the next artifact |
| `/opsx:ff` | ✅ | CLI | CLI | ✅ | Produce all remaining artifacts |
| `/opsx:propose` | ✅ | CLI | CLI | ✅ | Full proposal in one step |
| `/opsx:explore` | ✅ | — | — | ✅ | Discussion only, no files |
| `/opsx:apply` | ✅ | ✅ | ✅ | ✅ | Two-stage implementation |
| `/opsx:verify` | ✅ | ✅ | ✅ | ✅ | Four gates |
| `/opsx:sync` | ✅ | CLI | CLI | ✅ | Sync delta specs only |
| `/opsx:archive` | ✅ | CLI | CLI | ✅ | Archive + registry append |
| `/opsx:bulk-archive` | ✅ | CLI | CLI | ✅ | Archive several changes |

- **Qoder / Cursor**: `openspec init --tools qoder|cursor` generates the 10 commands; onePress only adds the skill and a one-line reference (Cursor slash commands are `/opsx-apply`-style).
- **OpenCode / Trae**: only `new` / `apply` / `verify` ship with this pack; Trae commands live in `.trae/commands/` (`/opsx-new`-style). Use the CLI for the rest:

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

Upgrade = re-run the script (`.\install.ps1` / `./install.sh`) with the new pack; `onePress.lock`'s `version` decides "fresh install" vs "upgrade", and stale managed files from the older version are cleaned using the lock manifest. A missing or corrupt lock means fresh install — project-level assets stay protected.

Uninstall: remove everything except `protectedAssets` from `onePress.lock` (`.opencode/`, `.qoder/skills/onepress-discipline/`, `.trae/skills/onepress-discipline/`, `.trae/commands/opsx-*`, `.cursor/skills/onepress-discipline/`, `openspec/schemas/superspec/`), keeping `docs/ui-components.md` and `openspec/changes/`.

---

## 6. Template pack layout

```text
onePress/
├── README-ch.md            # Chinese README (default)
├── README.md               # English README (this file)
├── VERSION                 # Version (upgrade baseline)
├── ASSETS.md               # Asset manifest (layer + overwrite policy)
├── INSTALL_PROMPT.md       # AI install entry (five sections, script-equivalent fallback)
├── install.ps1             # Windows installer (detect/write/check/report in one command)
├── install.sh              # macOS / Linux installer
├── opencode/               # OpenCode harness assets (6 files)
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-{new,apply,verify}.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness assets (1 file)
│   └── skills/onepress-discipline/SKILL.md
├── trae/                   # Trae harness assets (4 files)
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx-{new,apply,verify}.md
├── cursor/                 # Cursor harness assets (1 file)
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

**Q: The agent cannot find `INSTALL_PROMPT.md` after cloning?**
A: Usually the sparse-checkout path does not match the real layout (cone mode silently checks out nothing, no error). Have it verify with `git ls-tree -r --name-only HEAD`, then fall back to `git sparse-checkout disable` (the pack is only KB-sized). This is already covered in the install block above, so it normally self-recovers.

**Q: `/opsx:continue` stops at the plan step saying `superpowers:writing-plans` is unavailable?**
A: Since 1.0.4 every Superpowers skill reference in superspec carries an inline fallback (brainstorm / plan / apply 2c / finalize), so a missing skill no longer halts the flow — the agent writes `plan.md` inline. On older versions (schema version ≤ 4) just upgrade and re-install; as a stopgap, have the agent split `tasks.md` into 2–5 minute micro-steps and write `plan.md` directly.

**Q: The target repo has no OpenSpec?**
A: Install still completes, but `/opsx:*` and `ui_contract` parsing require OpenSpec. Run `openspec init --tools qoder|cursor|opencode` first; for Trae, `openspec init --tools trae` adds the remaining OpenSpec skills.

**Q: OpenCode / Trae lacks `/opsx:continue` and `/opsx:archive`?**
A: Only three commands ship with the pack. Use `openspec status` / `openspec instructions` / `openspec archive` instead, or add your own `.opencode/commands/opsx-*.md` / `.trae/commands/opsx-*.md`.

**Q: Can I install only one harness?**
A: Yes — that is the default. The installer detects by directory: `.qoder/` only → Qoder only, `.trae/` only → Trae only, `.cursor/` only → Cursor only, several present → every detected harness, none → it asks first. You can also pass `--harness trae,cursor`. To add another harness later, re-run the install; only that harness is written and the existing one is untouched.

**Q: Should `.qoder/`, `.opencode/`, `.trae/`, `.cursor/` be committed?**
A: No — they are local environment config. Do commit `onePress.lock` and `docs/ui-components.md`.

**Q: How do I confirm the install?**
A: Check the exit code and the report — `0` plus the closing line `onePress v<version> 安装完成（harnesses: <scope>）` means success; skipped items and check results are already listed. To double-check yourself, three spots — `onePress.lock` exists with the matching `version`; every `.qoder/commands/`, `.cursor/commands/` and `.trae/commands/` file has one `onepress-discipline` reference line; `openspec/schemas/superspec/` has 10 files.

**Q: Will a re-install clobber my edits to tooling files?**
A: No. Tracked files with uncommitted changes are reported and skipped; existing skill reference lines are skipped, and command bodies are never rewritten.

**Q: Will my existing `.qoder/` / `.cursor/` be damaged?**
A: No. onePress only adds a skill file and inserts one reference line after the frontmatter; command bodies are untouched. Trae only adds the `onepress-discipline` skill and three `opsx-*.md` command files.

---

## License

MIT
