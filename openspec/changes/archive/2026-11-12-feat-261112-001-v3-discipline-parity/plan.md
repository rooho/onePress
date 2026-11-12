# v3.0 Blueprint Parity Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task. If that skill is unavailable,
> follow apply mode 2c (inline task-by-task) instead — do not stop.

**Goal:** 按 `BLUEPRINT-V3.0.md` 把契约载体升级为 `ui-spec.md`、沙箱升级为单文件 HTML、门禁扩到 8 项，并在四个 harness 上语义等价落地。

**Architecture:** `ui-spec.md` 作为 `design` artifact 的条件产物（不新增 DAG 节点），沙箱是视觉参照而非代码来源，八门禁收敛为单一 POSIX 脚本 + 人工项显式标注，`ui-ux-pro-max` 作为可选增强层在缺失时全链路降级。

**Tech Stack:** Markdown（skill / command / template）、POSIX bash + awk、`openspec` CLI 1.13、既有 `install.sh` / `install.ps1`。

---

## Task 1: ui-spec 模板与 schema 门闸

- [ ] **Step 1:** 新建 `openspec-schema/superspec/templates/ui-spec.md`，按六章节写骨架；第 2 节放 16 行色彩通道表（含 Light/Dark 两列）与 `xs`–`3xl` 七行间距表
- [ ] **Step 2:** 第 3 节写四态矩阵表头 + 时序防抖四条；第 4 节写五档断点 + 三条防破版；第 5 节写热区/时序/`motion-reduce` 三条硬约束；第 6 节留一条 `AVOID` 占位
- [ ] **Step 3:** `cp` 到 `openspec/schemas/superspec/templates/`，`diff` 确认零差异
- [ ] **Step 4:** 在 `schema.yaml` 的 `design` instruction 末尾插入 `UI CHANGE GATE` 段（读 `**UI Change**:`，`yes` 时以 `templates/ui-spec.md` 生成 `ui-spec.md`）
- [ ] **Step 5:** 在 `schema.yaml` 的 `apply` instruction 的 Executor 段之前插入 `SANDBOX-AS-PRODUCTION` 段（Stage 1 直出、不从 HTML 转译、Stage 2 零改动）
- [ ] **Step 6:** 检查 `templates/design.md` 无 `ui_contract` 字样，若有则改为指向 `ui-spec.md`

## Task 2: 三份 carrier skill 增补铁律 6–10

- [ ] **Step 1:** 在 `qoder/skills/onepress-discipline/SKILL.md` 的「铁律 5」之后插入「铁律 6：需求分流」，10 行内
- [ ] **Step 2:** 插入「铁律 7：ui-spec 契约」，列出六章节名与 16 通道要求，14 行内
- [ ] **Step 3:** 插入「铁律 8：设计检索与降级」，给出两条 `search.py` 命令模板与 `SKIP` 文案，10 行内
- [ ] **Step 4:** 插入「铁律 9：高保真沙箱 + 两阶段」，写明沙箱五要素与 Stage 1/2 约束，14 行内
- [ ] **Step 5:** 插入「铁律 10：八项门禁」，编号列出 8 项 + `AUTO`/`MANUAL`，14 行内
- [ ] **Step 6:** 统计新增行数，确认 ≤ 60 行；超出则合并铁律 7 与 8
- [ ] **Step 7:** `cp` 到 `trae/` 与 `cursor/`，`sed` 替换载体名，两次 `diff --strip-trailing-cr` 确认仅载体名不同
- [ ] **Step 8:** 三份统一 UTF-8 无 BOM + LF

## Task 3: OpenCode 命令体与 ux-architect

- [ ] **Step 1:** 重写 `opencode/commands/opsx-new.md`：Step 0 判定 → Step 1 读 `MASTER.md` → Step 2 双步检索 → Step 3 写 `ui-spec.md` → Step 4 写 `sandbox-preview.html`
- [ ] **Step 2:** 在 Step 4 明确沙箱五要素（四态按钮、Light/Dark、16 变量、Google Fonts、`motion-reduce`）
- [ ] **Step 3:** 重写 `opencode/commands/opsx-apply.md`：删除 State Bar，改为 Stage 1 受控组件 + Stage 2 接线
- [ ] **Step 4:** 重写 `opencode/commands/opsx-verify.md`：门禁 0 + 八项门禁 + `AUTO`/`MANUAL` + CRITICAL 阻断
- [ ] **Step 5:** 重写 `opencode/agent/ux-architect.md`：输出改为 `ui-spec.md` 六章节，前置 `ui_change: yes`，内联检索命令
- [ ] **Step 6:** 在 `opencode/skills/superpowers-tdd/SKILL.md` 末尾追加归档追加注册表与门禁 4 的边界说明

## Task 4: 门禁脚本

- [ ] **Step 1:** 新建 `scripts/onepress-gate.sh`：shebang、`set -uo pipefail`、`pass/fail/skip/manual` 四个输出函数、参数解析
- [ ] **Step 2:** 实现文件收集：`--files` 优先，否则 `git diff --name-only`，再否则 `find`；过滤 `node_modules`
- [ ] **Step 3:** 实现门禁 2a：三条 `grep -nE`，颜色规则排除 `:root`/`.dark` 变量定义块与 `<svg>` 区间
- [ ] **Step 4:** 实现门禁 2b：用 awk 从 CSS 抽取 `--background/--foreground`、`--card/--card-foreground`、`--muted/--muted-foreground` 六组 hex，计算相对亮度与对比度比值
- [ ] **Step 5:** 实现门禁 4：`npx --no-install vitest run`，无 `package.json` 或 `npx` 缺失时 `SKIP`
- [ ] **Step 6:** 实现门禁 5：`focus-visible:ring` 存在性、`size="icon"` 附近 `aria-label`、表单 `aria-describedby`、装饰图标 `aria-hidden`
- [ ] **Step 7:** 实现门禁 6：`cursor-pointer`、`duration-(150|2xx)`、`motion-reduce:`、`size-11`/`min-h-11` 近似判定
- [ ] **Step 8:** 实现门禁 7：扫描 Emoji 码点区间 + 读 `--ui-spec` 第 6 节 `AVOID` 条目做关键字匹配
- [ ] **Step 9:** 门禁 1/3/8 固定输出 `MANUAL`，汇总后按"存在 FAIL 则退出 1"给出退出码

## Task 5: 门禁用例

- [ ] **Step 1:** 新建 `scripts/verify-gate.sh`，用 `mktemp -d` 造仓库
- [ ] **Step 2:** 用例 A：写入含 `style={{`、`#3b82f6`、`w-[317px]` 的 `.tsx`，断言退出码非 0 且三处行号出现
- [ ] **Step 3:** 用例 B：改为合规文件，断言退出码 0 且门禁 4 为 `SKIP`
- [ ] **Step 4:** 用例 C：空目录，断言退出码 0 且门禁 1/3/8 输出 `MANUAL`
- [ ] **Step 5:** 用例 D：写入对比度 3.8:1 的 CSS 变量对，断言门禁 2 判 `FAIL`

## Task 6: 安装器改造

- [ ] **Step 1:** `install.sh` 的 `SCHEMA_FILES` 加入 `templates/ui-spec.md`，把 `= "10"` 改为与清单长度比较
- [ ] **Step 2:** `install.ps1` 同步
- [ ] **Step 3:** `init_ui_components` 的 here-doc 改为四列表头，base/domain 两分区
- [ ] **Step 4:** 已存在时读首行表头，不含"适用骨架"则 `warn` 输出目标表头，直接 return
- [ ] **Step 5:** 新增 `probe_uiux()`：`command -v python3` + 检查各 harness 的 `skills/ui-ux-pro-max/scripts/search.py`，结果写报告
- [ ] **Step 6:** `accept_skill_harness` 关键词集追加五项，`install.ps1` 同步

## Task 7: 安装提示词与文档

- [ ] **Step 1:** `INSTALL_PROMPT.md` 内联四列注册表模板（与 install.sh 逐字节一致）
- [ ] **Step 2:** `INSTALL_PROMPT.md` 内联 `ui-spec.md` 六章节模板正文
- [ ] **Step 3:** 验收自检加"11 文件含 ui-spec.md"、"ui-spec 模板哈希一致"、"ui-ux-pro-max 探测结论"
- [ ] **Step 4:** `ASSETS.md` 增加三条资产行并标注层级
- [ ] **Step 5:** `README` / `README-ch` 更新 Step 1/2/4、命令矩阵、`ui-ux-pro-max` 可选说明

## Task 8: 终验

- [ ] **Step 1:** `openspec validate feat-261112-001-v3-discipline-parity --strict`
- [ ] **Step 2:** `bash scripts/verify-gate.sh`
- [ ] **Step 3:** `bash scripts/verify-trae.sh` / `bash scripts/verify-cursor.sh`
- [ ] **Step 4:** `diff -r openspec/schemas/superspec openspec-schema/superspec`
- [ ] **Step 5:** 复核本变更无 `ui-spec.md` 与 `sandbox-preview.html`
