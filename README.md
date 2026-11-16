# onePress

> An OpenSpec × Superpowers × Tailwind/shadcn bridge toolkit — install a **complete frontend workflow** into any repository with a single prompt.

onePress targets teams with **no dedicated designer**, where developers drive the work. It solves three concrete problems:

1. **Design by guesswork** → AI consults a local design knowledge base and writes a six-section `ui-spec.md` (component hierarchy / 16-channel tokens / four-state matrix / responsive rules / micro-motion / anti-patterns).
2. **Delivery by vibes** → a single-file `sandbox-preview.html` locks colour, type, density and motion — with four-state and Light/Dark toggles — before any production component is written.
3. **Quality by willpower** → eight gates (token purity + WCAG contrast + anti-patterns + touch targets + a11y + pure-logic state tests + human checks) executed by `scripts/onepress-gate.sh`.

First-class support for four harnesses: `.qoder/`, `.opencode/`, `.trae/` and `.cursor/`. Zero runtime dependencies — any model with file read/write access can install it.

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| Target repo | git initialized |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest` (**>= 2.0.0**; on 1.x use onePress v1.1.0 instead) |
| Design retrieval (optional) | `npm install -g ui-ux-pro-max-cli` + `uipro init --ai <harness> --offline`; skipped gracefully when absent |
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

The script does six things in one go: **detect harness → layered write → align OpenSpec config → write `onePress.lock` → self-check → report**. "Align config" means: create `openspec/config.yaml` (`schema: superspec`) when missing, rewrite only that line when the value is wrong (CRLF preserved), and run `openspec init --tools qoder|trae|cursor` automatically when the corresponding `.qoder/commands/`, `.trae/commands/` or `.cursor/commands/` is empty. Checks cover layout, verbatim content, all 12 schema files, `schema: superspec`, non-empty commands with reference lines, and lock/scope consistency; any failure aborts with a reason. Exit code `0` = success, `1` = failure. Nothing to verify by hand.

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
| `.opencode/` | `opencode.json`, `agent/ux-architect.md`, `commands/opsx-review.md`, `skills/superpowers-tdd/` | harness | OpenCode selected |
| `.qoder/skills/onepress-discipline/SKILL.md` | Ten iron rules (contract / triage / retrieval / sandbox / gates / token / states / a11y / anti-mistake / pre-code review) + TDD discipline | harness | Qoder selected |
| `.agents/skills/openspec-*/SKILL.md` (12) | OpenSpec 2.0 workflow skills; one reference line added after frontmatter, body untouched | harness | always (shared by all harnesses) |
| `.trae/skills/onepress-discipline/SKILL.md` | Ten iron rules + TDD discipline (Trae carrier) | harness | Trae selected |
| `.trae/commands/opsx-review.md` | onePress-managed review command (slash entry `/opsx:review`) | harness | Trae selected |
| `.cursor/skills/onepress-discipline/SKILL.md` | Ten iron rules + TDD discipline (Cursor carrier) | harness | Cursor selected |
| `.cursor/commands/opsx-review.md` | onePress-managed review command (slash entry `/opsx:review`) | harness | Cursor selected |
| `openspec/schemas/superspec/` | `schema.yaml` + 11 templates incl. `ui-spec.md` + `review-rubric.md` (12 files) | harness | always |
| `onePress.lock` | Version, install scope, protected assets | harness | always |
| `docs/ui-components.md` | Component registry template (four columns, empty tables on first install) | project | always |

> `docs/design-system/projectbaseline/MASTER.md` is generated **once** by the optional `ui-ux-pro-max` skill. onePress protects it on install/upgrade but never creates or rewrites it.

---

## 2. The full development workflow

From zero to archive in 5 steps. **All `/openspec-*` skills run at the target repo root** (the directory containing `openspec/`; OpenSpec 2.0 skills delivery).

| Step | Command | You provide | Output | Pass criteria |
|------|---------|-------------|--------|---------------|
| 1 Contract init | `/openspec-new-change <change>` | Feature description | `proposal.md`, `design.md`, `ui-spec.md` + `sandbox-preview.html` (UI only) | Six sections complete; sandbox opens in Light/Dark |
| 2 Complete artifacts | `/openspec-continue-change` ×N or `/openspec-ff-change` | — | `specs/`, `tasks.md`, `plan.md` | `openspec validate --strict` passes |
| 3 Implement | `/openspec-apply-change` | — | Code + `apply.md` | Sandbox parity (Light + Dark) |
| 4 Verify | `/openspec-verify-change` | — | `verify.md` | All eight gates green, no CRITICAL |
| 5 Archive | `/openspec-archive-change` | — | Main specs updated, `finalize.md`, archived dir | Components appended to registry |

### Step 1 — Contract init `/openspec-new-change`

```text
/openspec-new-change feat-261103-001-user-role-permission
```

What happens:

1. `/openspec-new-change` first decides `**UI Change**: yes|no` from three rules (routes/pages; table columns, form fields or state display; destructive interactions) and writes the verdict on the first line of `proposal.md`;
2. On `yes`, `ux-architect` reads `docs/design-system/projectbaseline/MASTER.md`, then runs a two-step retrieval (`--domain ux` first, then `--stack shadcn|html-tailwind`);
3. Reusable components are pulled from `docs/ui-components.md` (four columns, keyed by archetype);
4. A six-section `ui-spec.md` is written, followed by a single-file `sandbox-preview.html`.

`ui-spec.md` sections: component hierarchy / design tokens (16 colour channels + font pairing + `xs`–`3xl` density) / four-state matrix / responsive & anti-breakage / touch targets & micro-motion / industry anti-patterns.

**Human review point**: check `ui-spec.md` and the sandbox (Light + Dark) only — no production code exists yet.

**Optional accelerator**: `ui-ux-pro-max` supplies the local CSV knowledge base. If `python3` or the skill directory is missing, retrieval is recorded as `SKIP` and `ui-spec.md` is filled by hand — install and gates still work.

### Step 2 — Complete artifacts `/openspec-continue-change` / `/openspec-ff-change`

superspec defines 9 DAG artifacts; `/openspec-continue-change` produces **one per invocation**. UI changes additionally produce the conditional pair in the last row:

```text
brainstorm → proposal → design → specs → tasks → plan → apply → verify → finalize
```

| Artifact | Purpose |
|----------|---------|
| `brainstorm.md` | Options compared, decision recorded |
| `proposal.md` | Why, what, affected capabilities |
| `design.md` | Decisions (D1…Dn) + risks (UI contract lives in `ui-spec.md`) |
| `ui-spec.md` / `sandbox-preview.html` | **Conditional, not a DAG artifact**: six-section UI contract + single-file sandbox; only when `**UI Change**: yes` |
| `specs/<capability>/spec.md` | Delta spec: `### Requirement:` + `#### Scenario:` (GIVEN/WHEN/THEN) |
| `tasks.md` | Atomic checkable tasks |
| `plan.md` | 2–5 minute micro-steps |
| `apply.md` / `verify.md` / `finalize.md` | Implementation receipt / verification report / closeout receipt |

Generate everything at once: `/openspec-ff-change`. Proposal only: `/openspec-propose`. Discussion without writing files: `/openspec-explore`.

### Step 3 — Implement `/openspec-apply-change` (two stages)

| Stage | What | Output | Acceptance |
|-------|------|--------|------------|
| Stage 1 UI scaffold | Write the production view directly from `ui-spec.md` tokens (props-driven, four states) | Production component | Parity with `sandbox-preview.html` in Light + Dark |
| Stage 2 Schema wiring | Connect fields, error codes, permissions, submit logic | Real data flow | Structure and class lists unchanged |

There is no in-app State Bar: `sandbox-preview.html` is the single visual acceptance surface. **No DOM/RTL tests** — verify by eye, guard quality with the gate script.

### Step 4 — Verify `/openspec-verify-change`

Eight gates; any failure sends you back to the matching stage of `apply`:

| # | Gate | Mode |
|---|------|------|
| 0 | UI change ⇒ `ui-spec.md` + `sandbox-preview.html` present | AUTO |
| 1 | Four states match the matrix, CLS < 0.1 | MANUAL |
| 2 | Token purity (three regex scans) + WCAG contrast ≥4.5:1 (≥3:1 for large text/borders) | AUTO |
| 3 | Breakpoints: zero horizontal scroll, safe wrapping, `+n` disclosure | MANUAL |
| 4 | State-machine unit tests (pure logic only, RTL forbidden) | AUTO |
| 5 | A11y CRITICAL: focus ring, `aria-label`, `aria-describedby`, `aria-hidden` | AUTO |
| 6 | Touch targets ≥44×44px, `cursor-pointer`, 150–250ms, `motion-reduce:` | AUTO |
| 7 | Anti-patterns: zero Emoji icons, no blacklisted entries | AUTO |
| 8 | Sandbox parity: no visible drift vs `sandbox-preview.html` | MANUAL |

Run `bash scripts/onepress-gate.sh --change openspec/changes/<change>` to execute gates 0/0.5/2/4/5/6/7 automatically; the rest are printed as `MANUAL`. Run `/opsx:review <change>` before apply — `Review-Status: APPROVED` is required.

Writes `openspec/changes/<change>/verify.md` with one of: `PASS` / `PASS WITH WARNINGS` / `FAIL`. CRITICAL issues block archiving.

### Step 5 — Archive `/openspec-archive-change`

```text
/openspec-archive-change
```

1. Delta specs sync into `openspec/specs/<capability>/spec.md` (main specs);
2. Components created or changed are **appended** to `docs/ui-components.md` (append rows only — never reorder or delete history);
3. The change directory moves to `openspec/changes/archive/YYYY-MM-DD-<change>/`;
4. `finalize.md` records the closeout.

> **OpenCode behaves like every other harness**: run `/openspec-archive-change` directly; append the component row afterwards if needed:
> `bash scripts/onepress-registry-append.sh --root . --name <Name> --path <path> --archetype <Archetype> --props '<signature>'`
> The script is idempotent and only appends to the chosen section.

Batch: `/openspec-bulk-archive-change`. Sync specs only: `/openspec-sync-specs`.

---

## 3. Command reference

| Command | Qoder | OpenCode | Trae | Cursor | Purpose |
|---------|:-----:|:--------:|:----:|:------:|---------|
| `/openspec-new-change <name>` | ✅ | ✅ | ✅ | ✅ | Contract init (proposal + design + ui-spec + sandbox) |
| `/openspec-continue-change` | ✅ | CLI | ✅ | ✅ | Produce the next artifact |
| `/openspec-ff-change` | ✅ | CLI | ✅ | ✅ | Produce all remaining artifacts |
| `/openspec-propose` | ✅ | CLI | ✅ | ✅ | Full proposal in one step |
| `/openspec-explore` | ✅ | — | ✅ | ✅ | Discussion only, no files |
| `/openspec-apply-change` | ✅ | ✅ | ✅ | ✅ | Two-stage implementation |
| `/openspec-verify-change` | ✅ | ✅ | ✅ | ✅ | Eight gates |
| `/openspec-sync-specs` | ✅ | CLI | ✅ | ✅ | Sync delta specs only |
| `/openspec-archive-change` | ✅ | ✅ | ✅ | ✅ | Archive + registry append |
| `/openspec-bulk-archive-change` | ✅ | CLI | ✅ | ✅ | Archive several changes |
| `/openspec-onboard` | ✅ | CLI | ✅ | ✅ | Guided first-run walkthrough (native) |
| `/openspec-update-change` | ✅ | CLI | ✅ | ✅ | Revise planning artifacts (native, experimental) |

- **Qoder / Trae / Cursor**: OpenSpec 2.0 installs all 12 skills into `.agents/skills/`; the installer mounts one `onepress-discipline` reference line after each `SKILL.md` frontmatter and ships one managed `/opsx:review` command.
- **OpenCode**: shares the same `.agents/skills/` and ships one managed `commands/opsx-review.md`; `new` / `apply` / `verify` commands are no longer shipped:

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

Full details: `studio/openspec/CHANGE_NAMING.md`.

---

## 5. Asset layering and upgrades

| Layer | Assets | Upgrade behavior |
|-------|--------|------------------|
| harness (maintained by onePress) | `commands/`, `skills/`, `opencode.json`, `openspec/schemas/superspec/` | Full overwrite (delete then write) |
| project (owned by target repo) | `docs/ui-components.md`, `openspec/changes/` | Skip if exists (Protect Local), never overwritten |
| local modifications | Uncommitted harness edits in the target repo | Prompt and skip |

Upgrade = re-run the script (`.\install.ps1` / `./install.sh`) with the new pack; `onePress.lock`'s `version` decides "fresh install" vs "upgrade", and stale managed files from the older version are cleaned using the lock manifest. A missing or corrupt lock means fresh install — project-level assets stay protected.

Uninstall: remove everything except `protectedAssets` from `onePress.lock` (`.opencode/`, `.qoder/skills/onepress-discipline/`, `.trae/skills/onepress-discipline/`, `.trae/commands/opsx-review.md`, `.cursor/skills/onepress-discipline/`, `openspec/schemas/superspec/`), keeping `docs/ui-components.md` and `openspec/changes/`; `.agents/skills/` belongs to the OpenSpec CLI and is left in place (run `openspec update` to drop the reference lines).

---

## 6. Template pack layout

```text
onePress/                    # release pack root (generated from studio/pack/)
├── README-ch.md            # Chinese README (default)
├── README.md               # English README (this file)
├── VERSION                 # Version (upgrade baseline)
├── ASSETS.md               # Asset manifest (layer + overwrite policy)
├── INSTALL_PROMPT.md       # AI install entry (five sections, script-equivalent fallback)
├── install.ps1             # Windows installer (detect/write/check/report in one command)
├── install.sh              # macOS / Linux installer
├── opencode/               # OpenCode harness assets (4 files)
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-review.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness assets (2 files)
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx/review.md
├── trae/                   # Trae harness assets (2 files)
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx-review.md
├── cursor/                 # Cursor harness assets (2 files)
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx-review.md
├── scripts/                # Pack-side scripts
│   ├── onepress-gate.sh    # Gates 0/0.5/2/4/5/6/7 AUTO + MANUAL 1/3/8 (installed)
│   ├── sandbox-preflight.spec.ts  # L1 pre-flight (installed, optional deps)
│   └── onepress-registry-append.sh  # Append a component row (shipped, run manually)
└── openspec-schema/superspec/   # Schema installed into target repos (12 files, incl. templates/ui-spec.md + review-rubric.md)
```

> `blueprint/` (iteration blueprints) and `openspec/` (this toolkit's own spec workspace) live in the **studio repo**, never in this release pack. The release pack is generated from `studio/pack/`.

---

## 7. FAQ

**Q: The agent cannot find `INSTALL_PROMPT.md` after cloning?**
A: Usually the sparse-checkout path does not match the real layout (cone mode silently checks out nothing, no error). Have it verify with `git ls-tree -r --name-only HEAD`, then fall back to `git sparse-checkout disable` (the pack is only KB-sized). This is already covered in the install block above, so it normally self-recovers.

**Q: `/openspec-continue-change` stops at the plan step saying `superpowers:writing-plans` is unavailable?**
A: Since 1.0.4 every Superpowers skill reference in superspec carries an inline fallback (brainstorm / plan / apply 2c / finalize), so a missing skill no longer halts the flow — the agent writes `plan.md` inline. On older versions (schema version ≤ 4) just upgrade and re-install; as a stopgap, have the agent split `tasks.md` into 2–5 minute micro-steps and write `plan.md` directly.

**Q: The target repo has no OpenSpec?**
A: Install still completes, but `/openspec-*` skills and `ui-spec.md`/`sandbox-preview.html` generation require OpenSpec. Run `openspec init --tools qoder|trae|cursor|opencode` first.

**Q: Where are the workflow skills on OpenCode?**
A: OpenSpec 2.0 installs them into `.agents/skills/openspec-*`, shared by all four harnesses; this pack only adds `commands/opsx-review.md`. If they are missing, run `openspec init --tools opencode` or `openspec update`.

**Q: Can I install only one harness?**
A: Yes — that is the default. The installer detects by directory: `.qoder/` only → Qoder only, `.trae/` only → Trae only, `.cursor/` only → Cursor only, several present → every detected harness, none → it asks first. You can also pass `--harness trae,cursor`. To add another harness later, re-run the install; only that harness is written and the existing one is untouched.

**Q: Should `.qoder/`, `.opencode/`, `.trae/`, `.cursor/` be committed?**
A: No — they are local environment config. Do commit `onePress.lock` and `docs/ui-components.md`.

**Q: How do I confirm the install?**
A: Check the exit code and the report — `0` plus the closing line `onePress v<version> 安装完成（harnesses: <scope>）` means success; skipped items and check results are already listed. To double-check yourself, three spots — `onePress.lock` exists with the matching `version`; every `.qoder/commands/`, `.trae/commands/` and `.cursor/commands/` file has one `onepress-discipline` reference line; `openspec/schemas/superspec/` has 12 files (incl. `templates/ui-spec.md` and `templates/review-rubric.md`).

**Q: Will a re-install clobber my edits to tooling files?**
A: No. Tracked files with uncommitted changes are reported and skipped; existing skill reference lines are skipped, and command bodies are never rewritten.

**Q: Will my existing `.qoder/` / `.trae/` / `.cursor/` be damaged?**
A: No. onePress only adds a skill file and inserts one reference line after the frontmatter; command bodies are untouched.

---

## License

MIT
