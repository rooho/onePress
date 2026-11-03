# Verification Report

**Change**: `req-261103-001-onepress-scheme-install`
**Verified at**: `2026-11-03`
**Iteration**: `1`
**Verifier**: `Qoder agent（/opsx:verify 手工核查循环）`

---

## 1. Structural Validation (`openspec validate --all`)

- [x] All items `"valid": true`

**Result**:

```text
openspec validate --all   → Totals: 1 passed, 0 failed (1 items)
openspec validate req-261103-001-onepress-scheme-install --strict → Change '...' is valid
```

| Item | Type | Issues |
|---|---|---|
| — | — | — |

---

## 2. Task Completion (`tasks.md`)

- [x] All `- [ ]` have been changed to `- [x]`

**Incomplete tasks**: 无（`openspec instructions apply --json` → `progress: 28/28, remaining: 0`）

| Task | Reason incomplete | Blocks archive? |
|---|---|---|
| — | — | — |

---

## 3. Delta Spec Sync State

| Capability | Sync status | Notes |
|---|---|---|
| onepress-template-pack | ✗ pending sync | 4 Requirements（R1 本轮已修订为 8 条目白名单） |
| onepress-idempotent-install | ✗ pending sync | 5 Requirements |
| onepress-llm-installer | ✗ pending sync | 5 Requirements |
| onepress-harness-integration | ✗ pending sync | 4 Requirements（R2 本轮新增 1 个场景） |

`openspec/specs/` 下尚无对应 capability 目录，全部待同步属正常——由 `/opsx:archive` 执行同步。

---

## 4. Design / Specs Coherence Spot Check

| Sample item | design description | specs counterpart | Gap |
|---|---|---|---|
| D1 模板包结构 | 5 功能条目 + 3 文档条目（文档不安装） | onepress-template-pack R1（本轮同步为 8 条目白名单） | 无 |
| D2 .opencode 官方格式 | `commands/` 复数、`skills/<name>/SKILL.md`、`agent/` + `mode` | onepress-harness-integration R1 | 无 |
| D3 Qoder 技能挂载 | 安装时对既有 commands frontmatter 后新增一行引用 | onepress-harness-integration R2 + 新场景「安装后命令头部含技能引用」 | 无（INSTALL_PROMPT ② 已补该步骤） |
| D4 onePress.lock 最小字段 | version / installedAt / harnesses / protectedAssets | onepress-idempotent-install R1 | 无 |
| D5 三档升级 | 全量覆盖 / Protect Local / 本地修改保护 | onepress-idempotent-install R2–R4 | 无 |
| D6 Schema 注入 | 复制 superspec 10 文件，缺失即失败 | onepress-harness-integration R3 | 无 |
| D7 INSTALL_PROMPT 五段 + 双 harness 验收 | 五段结构、每 harness ≥5 项 | onepress-llm-installer R1 / R3 | 无（`.qoder` 验收项由 5 增至 6） |

**Drift warnings**（非阻塞）:

- `tasks.md` 任务 1.1 描述 `VERSION` 内容为 `0.1.0`，实际发布版为 `1.0.0`（历史记录，不影响验收结论）。
- 模板包 README 明确以 `onepress/` 为唯一目录名，而产品名与 `onePress.lock` 用驼峰；该口径已在 README 与 ASSETS.md 固定，但 GitHub 仓库名 `rooho/onePress` 与目录名大小写不同，属预期设计。

---

## 5. Implementation Signal

- [ ] No unstaged files in the worktree
- [ ] All related commits have been pushed

**Commit range**: `325c253..（暂无提交）`

说明：实现产物为 `.worktree/v1.0.0/onepress/`（分支 `v1.0.0`，22 文件），当前为未跟踪状态（`?? onepress/`）。worktree 内该路径**不在** `.gitignore` 忽略范围内，可直接 `git add onepress/` 提交。

---

## Iteration 1 修复记录（本轮 verify 中处理）

| # | 级别 | 问题 | 处理 |
|---|---|---|---|
| 1 | CRITICAL | Qoder「命令头部技能引用」未纳入安装流程，新仓库安装后技能不生效 | INSTALL_PROMPT ② 新增「Qoder 命令技能挂载」步骤（仅加一行、禁止新建命令文件、禁止改主体）；④ 验收项改为「仅允许 frontmatter 后新增一行引用」，并新增「每个命令文件均含引用」检查 |
| 2 | WARNING | 包根 8 条目与 spec R1 / design D1 的 5 条目冲突 | spec R1 与 design D1 改为「5 功能条目 + 3 文档条目（不安装）」；④ 新增「模板包结构验收项」白名单校验 |
| 3 | WARNING | 包内 3 处字面 `{{`（`style={{`）会触发 R3 扫描失败 | `opencode/agent/ux-architect.md`、`opencode/skills/superpowers-tdd/SKILL.md`、`qoder/skills/onepress-discipline/SKILL.md` 改为「禁止内联 style 属性」；复测包内 `{{` 计数 = 0 |
| 4 | WARNING | 外层 `onepress/`（VERSION 0.1.0、小写命名）与 worktree（1.0.0、驼峰）两份实现分叉 | 删除外层 20 文件副本，worktree `v1.0.0` 成为唯一实现源 |
| 5 | SUGGESTION | lock 示例 `"version": "0.1.0"` 与 VERSION 不一致 | 示例改为 `1.0.0` |
| 6 | SUGGESTION | docs 条目未出现在 INSTALL_PROMPT 资产清单 | ② 新增「文档条目（不安装）」，覆盖 ASSETS.md / README-ch.md / README.md |

---

## Overall Decision

- [ ] ✅ PASS — ready to proceed via /opsx:continue to the finalize artifact, then /opsx:archive
- [x] ⚠️ PASS WITH WARNINGS — 无阻塞项；两项非阻塞提示见第 4、5 节
- [ ] ❌ FAIL

**Next step**:

1. 在 `.worktree/v1.0.0` 提交 `onepress/`（当前未跟踪），建议 `feat(onepress): ...`
2. `/opsx:continue` 生成 finalize 工件（第 9/9），再 `/opsx:archive`——archive 会把 4 份 delta spec 同步进 `openspec/specs/`

### Verification Dimensions

| Dimension | Status |
|---|---|
| Completeness | 28/28 tasks；18/18 Requirements 全部落地，4 份 delta spec 可解析 |
| Correctness | 18/18 reqs 已实现（含本轮修复的 Qoder 挂载项）；场景覆盖：e2e-report 6 项 + 本轮新增的「包结构校验」「命令头部含引用」均有可执行检查项 |
| Coherence | D1–D7 全部对齐，无遗留偏离 |
