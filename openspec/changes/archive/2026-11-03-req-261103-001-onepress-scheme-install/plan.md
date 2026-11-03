# onePress 方案包安装器 Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Goal:** 产出可分发、可幂等安装、可由大模型按提示词自装的 onePress 模板包（首批支持 .qoder 与 .opencode）。

**Architecture:** `onepress/` 为唯一事实源（SSOT），含 `qoder/`、`opencode/`、`openspec-schema/` 三类 harness 资产与 `INSTALL_PROMPT.md`；安装行为由提示词五段结构驱动，onePress.lock 承载幂等与升级语义。目标仓库注入 superspec schema 使 `ui_contract` 可解析。

**Tech Stack:** 纯 Markdown / JSON / YAML 静态资产；验证用 PowerShell 脚本与 OpenSpec CLI（`openspec validate`）；无强制运行时依赖。

---

## Task 1: 模板包骨架与事实源（tasks 1.1–1.4）

- [ ] **Step 1.1:** 创建 `onepress/` 目录并写入 `onepress/VERSION`（内容 `0.1.0`）
- [ ] **Step 1.2:** 复制 superspec 10 文件到 `onepress/openspec-schema/superspec/`：`copy openspec\schemas\superspec\schema.yaml onepress\openspec-schema\superspec\`，再 `copy openspec\schemas\superspec\templates\* onepress\openspec-schema\superspec\templates\`
- [ ] **Step 1.3:** 验证 10 文件齐全：`(Get-ChildItem onepress\openspec-schema\superspec -Recurse -File).Count` 输出 `10`
- [ ] **Step 1.4:** 编写 `onepress/ASSETS.md` 资产清单（表格：路径 / 归属 harness|project / 覆盖策略）
- [ ] **Step 1.5:** 结构校验：`Get-ChildItem onepress` 顶层仅含 `VERSION`、`ASSETS.md`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`openspec-schema/`

> Commit point: `chore(onepress): scaffold template pack skeleton with superspec schema`

## Task 2: OpenCode harness 资产（tasks 2.1–2.6）

- [ ] **Step 2.1:** 编写 `onepress/opencode/opencode.json`（`$schema` 指向 opencode 官方 config schema、`agent.ux-architect` 声明、`permission.skill` 规则）
- [ ] **Step 2.2:** 校验 JSON：`Get-Content onepress\opencode\opencode.json -Raw | ConvertFrom-Json` 无报错
- [ ] **Step 2.3:** 编写 `onepress/opencode/agent/ux-architect.md`（frontmatter：`description` + `mode: subagent`；正文：BMAD UX 推导 + `ui_contract` YAML 生成要求）
- [ ] **Step 2.4:** 编写 `onepress/opencode/commands/opsx-new.md`（frontmatter `description`；正文含 `$ARGUMENTS` 占位与 ui_contract 7 模块要求）
- [ ] **Step 2.5:** 编写 `onepress/opencode/commands/opsx-apply.md`（沙箱即生产两阶段：UI 底座直出 → Schema 接线）
- [ ] **Step 2.6:** 编写 `onepress/opencode/commands/opsx-verify.md`（秒级门禁：`tsc --noEmit` + Token 正则三禁令 + Hook TDD + 四态点检）
- [ ] **Step 2.7:** 编写 `onepress/opencode/skills/superpowers-tdd/SKILL.md`（frontmatter `name: superpowers-tdd` 与目录名一致、`description` 100–1024 字符）

> Commit point: `feat(onepress): add opencode harness assets`

## Task 3: Qoder harness 资产（tasks 3.1–3.3）

- [ ] **Step 3.1:** 编写 `onepress/qoder/skills/onepress-discipline/SKILL.md`（四态状态机约定、Token 纯净度三禁令、3 条无障碍铁律、破坏性操作 AlertDialog 防呆、四态点检流程）
- [ ] **Step 3.2:** 在本仓库 `.qoder/commands/opsx/opsx-apply.md` 与 `opsx-verify.md` 头部插入 `onepress-discipline` 技能引用（仅头部一行，命令主体不动）
- [ ] **Step 3.3:** `git diff -- .qoder/commands/` 复核仅头部新增引用行、无主体改动
- [ ] **Step 3.4:** 语义等价比对：`onepress-discipline/SKILL.md` 与 `superpowers-tdd/SKILL.md` 的门禁项、红线条目逐条对照一致

> Commit point: `feat(onepress): add qoder discipline skill and command mounting`

## Task 4: 安装提示词（tasks 4.1–4.6）

- [ ] **Step 4.1:** 创建 `onepress/INSTALL_PROMPT.md` 五段骨架：`## ① 前置检查` / `## ② 分层安装` / `## ③ 幂等与升级` / `## ④ 验收自检` / `## ⑤ 收尾`
- [ ] **Step 4.2:** 填写第①段（探测 `.qoder/`、`.opencode/`、`onePress.lock` 现状的分支逻辑）
- [ ] **Step 4.3:** 填写第②段（harness 级逐字落盘 / 项目级 Protect Local，含逐字写入约束与三条红线）
- [ ] **Step 4.4:** 填写第③段（读写 `onePress.lock`、三档策略、lock 损坏降级）
- [ ] **Step 4.5:** 填写第④段（`.qoder` 与 `.opencode` 各 ≥5 项可执行验收检查）
- [ ] **Step 4.6:** 填写第⑤段（写 lock、输出安装报告）
- [ ] **Step 4.7:** 结构校验：五段标题按序存在且无渲染占位符 `{{ }}`（正则 `\{\{` 匹配数为 0）

> Commit point: `feat(onepress): add INSTALL_PROMPT.md five-section installer`

## Task 5: 幂等安装语义落地（tasks 5.1–5.4）

- [ ] **Step 5.1:** 在 INSTALL_PROMPT.md 第③段给出 `onePress.lock` JSON 示例（`version` / `installedAt` / `harnesses` / `protectedAssets`）
- [ ] **Step 5.2:** 校验示例可解析：将该示例写入临时文件后 `ConvertFrom-Json` 无报错
- [ ] **Step 5.3:** 固化全量覆盖规则（升级时删除目标 harness 目录旧文件后再写入，杜绝残留）
- [ ] **Step 5.4:** 固化 Protect Local 与本地未提交修改检测（`git status --porcelain` 命中则提示并默认跳过）

> Commit point: `feat(onepress): solidify idempotent install and upgrade semantics`

## Task 6: 安装演练与回归验证（tasks 6.1–6.5）

- [ ] **Step 6.1:** 全新仓库演练：在 `$env:TEMP\onepress-e2e-new` 按 INSTALL_PROMPT.md 执行安装，双 harness 验收项全过
- [ ] **Step 6.2:** 升级演练：本仓库（已有 `.qoder`）执行升级分支，`git diff` 确认既有 opsx 命令主体未改写、本地修改提示生效
- [ ] **Step 6.3:** schema 完整性：演练仓库 `openspec schemas` 可列出 `superspec (project)` 且 `openspec validate` 通过
- [ ] **Step 6.4:** 注册表两态：全新仓库 `docs/ui-components.md` 被初始化；本仓库已存在则输出 `skipped (exists)` 且内容不变
- [ ] **Step 6.5:** lock 降级：手工写入非法 JSON 的 `onePress.lock` 后重跑安装，确认按全新安装处理且项目资产未被覆盖
- [ ] **Step 6.6:** 清理演练目录 `$env:TEMP\onepress-e2e-new`，归档演练记录到本变更目录 `e2e-report.md`

> Commit point: `test(onepress): e2e install and upgrade regression passed`
