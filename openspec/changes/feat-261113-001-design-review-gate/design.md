## Context

onePress 是"提示词纪律 + 安装器"模板包，本身没有前端应用；本变更的产物是**纪律文本、命令体、schema 模板、门禁脚本与安装清单**。`proposal.md` 已确认 `**UI Change**: no`，因此不产出 `ui-spec.md` 与 `sandbox-preview.html`，设计重点在"四 harness 语义等价 + 幂等安装 + 可确定性校验"。

当前基线（已核对）：

- `openspec-schema/superspec/` 共 11 文件；`ui-spec.md` 2.1 已有 16 通道与 Shadcn 别名，但缺重命名规则、`.dark` 策略与 `@theme inline` 说明。
- `scripts/onepress-gate.sh` 实现门禁 0/2a/2b/4/5/6/7，门禁 1/3/8 输出 `MANUAL`；无 `--require-review`、无门禁 0.5。
- 四 harness 均无 `opsx-review` 命令；`INSTALL_PROMPT.md` ② 明确规定挂载阶段"不得新建命令文件"。
- 已实测：`openspec init` 重跑不会删除额外命令文件（`.dbg/init-probe/` 验证），但会重写 `openspec init` 生成的命令体。

Harness 官方文档引用：

- OpenCode：命令 <https://opencode.ai/docs/commands/>、技能 <https://opencode.ai/docs/skills/>、子代理 <https://opencode.ai/docs/agents/>
- Trae：技能 <https://docs.trae.ai/ide/skills>
- Qoder：技能 <https://docs.qoder.com/extensions/skills>
- Cursor：技能 <https://cursor.com/docs/skills>；`.cursor/commands/*.md` 无稳定官方命令页，沿用 onePress 既有已验收路径与安装器实现

## Goals / Non-Goals

**Goals:**

1. 五个补丁全部落到正确载体（模板 / carrier / OpenCode 拆分载体 / 脚本 / 安装清单），且 `UI Change: no` 的变更流程零变化。
2. 新增 `/opsx:review` 三级门禁，L1 可确定性执行、L2 有冷上下文与 FALLBACK、L3 有可用的 DOM 批注闭环。
3. `Review-Status` 成为可解析的契约锁，默认对 `UI Change: yes` 生效，不依赖 Agent 自觉。
4. 四 harness 的命令体、技能、schema 模板逐字节等价可验证；安装器升级/回滚幂等。
5. 不引入安装期运行时依赖：Node/Playwright/axe 缺失时 L1 记 `SKIP`，安装结论仍为成功。

**Non-Goals:**

1. 不把 review 做成 superspec 的新 artifact，不改 DAG。
2. 不自动安装 `ui-ux-pro-max` / Playwright / axe，不发起 `npm install` 或网络请求。
3. 不引入 GSAP 或替换 Shadcn/Tailwind 栈。
4. 不改写目标仓库业务代码、`openspec/changes/`、`docs/ui-components.md`、`docs/design-system/projectbaseline/MASTER.md`。
5. 不在本轮把 40/20 分制转为硬阻断（观察模式）。

## Decisions

### D1 门禁形态：命令 + 文件锁 + 脚本闸，不改 DAG

- 命令 `/opsx:review <change-name>` 承载 L1→L2→L3 流程；`review.md` 记录结果；`ui-spec.md` 的 `Review-Status` 作为唯一放行标记。
- 拒绝方案：新 artifact（会改变 DAG，纯后端流程被迫产出评审件；上游 OpenSpec 无审批闸且社区仍在提案阶段）。
- 拒绝方案：纯技能载体（无显式入口，无法承载 L1 脚本与评分表）。

### D2 资产清单与安装落点

| # | 模板源 | 目标路径 | 层级 | 说明 |
|---|---|---|---|---|
| 1 | `qoder/commands/opsx/review.md` | `.qoder/commands/opsx/review.md` | harness | 含 `onepress-discipline` 引用行 |
| 2 | `trae/commands/opsx-review.md` | `.trae/commands/opsx-review.md` | harness | 含引用行 |
| 3 | `cursor/commands/opsx-review.md` | `.cursor/commands/opsx-review.md` | harness | 含引用行 |
| 4 | `opencode/commands/opsx-review.md` | `.opencode/commands/opsx-review.md` | harness | 引用 `superpowers-tdd` |
| 5 | `openspec-schema/superspec/templates/review-rubric.md` | `openspec/schemas/superspec/templates/review-rubric.md` | harness | schema 11→12 |
| 6 | `openspec-schema/superspec/templates/ui-spec.md` | 同左（镜像） | harness | 2.1/第 7 节/章节口径 |
| 7 | `openspec-schema/superspec/schema.yaml` | 同左（镜像） | harness | apply 前置 `Review-Status`；design/verify 措辞更新 |
| 8 | `qoder|trae|cursor/skills/onepress-discipline/SKILL.md` | 对应 `.harness/skills/...` | harness | 铁律 7/8/9 增补 |
| 9 | `opencode/agent/ux-architect.md`、`opencode/commands/opsx-new.md`、`opencode/commands/opsx-apply.md` | 对应 `.opencode/...` | harness | 英文检索、Banner、动效约束 |
| 10 | `scripts/onepress-gate.sh` | `<target>/scripts/onepress-gate.sh` | tooling | 门禁 0.5 + `--require-review` |
| 11 | `scripts/sandbox-preflight.spec.ts` | `<target>/scripts/sandbox-preflight.spec.ts` | tooling | L1 参考实现，缺失 Playwright 即 `SKIP` |
| 12 | `install.sh` / `install.ps1` / `INSTALL_PROMPT.md` / `ASSETS.md` / `README*.md` / `scripts/verify-carriers.sh` | 不安装 | installer/docs | 清单、验收、文档同步 |

> **D2 的偏离说明**：`ASSETS.md` 现状把 `scripts/**` 全部标为"不安装"。本方案新增 **tooling 层**（仅 `onepress-gate.sh` 与 `sandbox-preflight.spec.ts`），否则门禁 0.5 在目标仓库无法确定性执行，蓝图风险 #5 的缓解措施落空。

### D3 命令体规范（四 harness 语义等价）

- Frontmatter：
  - Qoder：`name` / `description` / `category` / `tags`（对齐 `openspec init` 输出风格）
  - Trae、Cursor：`name` / `description`
  - OpenCode：仅 `description`（对齐 pack 内既有 `opencode/commands/*.md`）
- Qoder/Trae/Cursor 命令体在 frontmatter 后固定一行：
  `> onepress: 执行本命令时 MUST 先加载技能 \`onepress-discipline\`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。`
  安装器的 `mount_skill_reference` 检测到该行即跳过，保证幂等。
- 正文结构四份一致（六段）：① 输入与前置校验；② L1；③ L2；④ L3；⑤ 写 `review.md` 与 `Review-Status`；⑥ 失败处置与轮数上限。
- `verify-carriers.sh` 扩展：对四份命令体做"归一化 harness 名/路径后逐字节比对"，任一份漂移即 FAIL。

### D4 `Review-Status` 语法与解析

`ui-spec.md` 固定为：

```markdown
# UI Spec — `<change-name>`

> Review-Status: PENDING

> 由 `/opsx:new` 在 ...
```

规则：

- 仅接受 `PENDING` / `APPROVED` 两个值，正则 `^> Review-Status: (PENDING|APPROVED)$`。
- 初始由 `/opsx:new`（`UI Change: yes`）写入 `PENDING`；`/opsx:review` 只能写/保持 `PENDING`。
- 只有 L3 人类批准后，才允许改写为 `APPROVED`；Agent 自行改写视为违纪，门禁 0.5 与 verify 记录 FAIL。
- 旧变更（无该行）在默认强制下视为 `PENDING`；`--no-require-review` 可放行。

### D5 `review.md` 结构（评审通行证）

```markdown
# Review — <change-name>

- Round: <n>/3
- L1: PASS | FAIL | SKIP (<reason>)
- L2: PASS | FAIL | SKIP (<reason>)
- L3: APPROVED | PENDING (<approver>, <ISO date>)
- Critique: <x>/40 (observation)
- Audit: <y>/20 (observation)
- P0: <n>  P1: <n>  P2: <n>  P3: <n>

## Findings
| # | 级别 | 证据（ui-spec 章节 / 选择器） | 问题 | 建议 |

## 结论
<PASS | FAIL | ESCALATE>
```

- `review.md` 属变更工件，随 change 归档；不写入 `ui-spec.md`。
- L2 每条 finding 必须带证据列；无证据的 finding 不计分、不得作为阻断依据。
- 40/20 分制标注 `observation`：记录但不单独阻断，阈值校准后再启用（D7）。

### D6 L1 执行模型

- 运行位置：目标仓库根；测试文件写到 `openspec/changes/<change>/.review/sandbox-preflight.spec.ts`（变更工件，不污染业务代码），报告写 `.review/l1-report.json`。
- 依赖探测：`npx playwright --version` 与 `@axe-core/playwright` 可解析才执行；否则 `L1: SKIP`，原因写入 `review.md`，不阻断。
- 8 视图：`idle|loading|empty|error` × `light|dark`；每视图断言：
  1. `AxeBuilder.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])` 零 violations（排除 `#sandbox-control-bar`）；
  2. 交互控件（`button` / `[role=button]` / `input` / `select` / `a[class*=btn]`）渲染尺寸 ≥44×44；**行内文本链接豁免**；
  3. 视口 375/768/1024/1280 下 `scrollWidth ≤ clientWidth`；
  4. 样式表在 CSS 变量声明块之外零硬编码 Hex；零 Emoji 功能图标。
- CLS：状态切换前后用 `PerformanceObserver('layout-shift')` 采样，阈值 0.1；标注"沙箱代理指标"。
- 失败处置：非零即回写 `ui-spec.md` / `sandbox-preview.html` 并重跑（计入 3 轮上限）。

### D7 L2 执行模型与评分

- 输入四件套（只读）：`MASTER.md`、`ui-spec.md`、`sandbox-preview.html`、`openspec/schemas/superspec/templates/review-rubric.md`；`pro-rules.md` 若存在则追加，缺失不阻断。
- 隔离：有子代理能力的 harness（OpenCode/Qoder）派生零历史子代理；无子代理的（Trae/Cursor）走 FALLBACK：新会话 + 仅上传四件套 + 正文声明"未引用生成历史"。
- 主判据（阻断）：`P0 = 0 且 P1 = 0`，且单层列表 ≤8 项、单决策点并列选项 ≤4。
- 二级信号（观察）：Critique 40 / Audit 20 分制，按 `review-rubric.md` 锚点计分，本轮只记录不单独阻断。
- 轮数：L1+L2 合计 ≤3 轮；超限输出 `ESCALATE` 交 L3。

### D8 L3 与沙箱批注器

- `ui-spec.md` 第 7 节与 `sandbox-preview.html` 生成规则强制：`#sandbox-control-bar`、`[data-set-state="idle|loading|empty|error"]`、`[data-set-theme="light|dark"]`、`<main>` landmark。
- Pin-to-AI：`Alt/⌘ + Click` 点选，复制"选择器 + 类名 + HTML 片段 + 批注"；选择器优先 `[data-review-id]`，其次 id，再退化为 class 链；SVG 目标 `className` 需类型守卫；`navigator.clipboard` 失败时回退 `textarea + document.execCommand('copy')`。
- 批注 → `/opsx:update <change> "<批注>"` → 修订 `ui-spec.md` 与沙箱 → 重跑 L1/L2 → 人类确认后写 `APPROVED`。

### D9 评分表单一来源

- `templates/review-rubric.md` 是唯一评分与清单来源，包含：P0–P3 定义、Critique 10 项锚点（4/3/2/1/0 各档描述）、Audit 5 维锚点、认知负荷阈值、62 类 AI Slop 摘要、L1 断言清单与 preflight 脚本附录。
- 四份命令体与三份 skill 只引用路径，不复制锚点正文，避免四份漂移。

### D10 门禁 0.5 与开关

- `onepress-gate.sh`：
  - 默认对 `UI Change: yes` 且存在 `ui-spec.md` 的变更执行门禁 0.5：`Review-Status` 非 `APPROVED` → `FAIL`。
  - `--require-review`：CI 显式声明，等价于默认行为（便于流水线固定语义）。
  - `--no-require-review`：旧变更逃生阀，输出 `SKIP (legacy)`。
  - `UI Change: no` → 门禁 0.5 `SKIP`。
- `schema.yaml` 的 `apply` 块新增一句前置：未签署 `APPROVED` 时停止并提示运行 `/opsx:review`；与脚本互为双保险。

### D11 安装器改造与幂等语义

- `install.sh` / `install.ps1`：
  - 新增 `QODER_COMMAND_FILES` / `TRAE_COMMAND_FILES` / `CURSOR_COMMAND_FILES` / `TOOLING_FILES` 列表；`OPENCODE_FILES` 增加 `opencode/commands/opsx-review.md`。
  - `SCHEMA_FILES` 增加 `templates/review-rubric.md`（11→12）。
  - `will_write` / `remove_stale_files` / `write_lock` 自动覆盖新列表；lock 的 `files` 记录新增托管命令与 tooling。
  - 验收新增：四份 review 命令存在且逐字节等于模板；qoder/trae/cursor 命令含技能引用行；rubric 逐字节一致；schema 文件数为 12。
- 幂等语义（沿用现有实现，不新增语义）：
  - 全量覆盖：命中 `MODIFIED`（已跟踪未提交修改）→ 跳过并报告；命中 `UNTRACKED && !MANAGED`（用户自建）→ 跳过并报告；其余覆盖。
  - Protect Local：`docs/ui-components.md`、`docs/design-system/**`、`openspec/changes/**` 永不写。
  - 升级：按旧 lock 的 `files` 清理 stale（新文件不在旧 lock，无需清理）；`openspec init` 生成的 12 个原生命令体不删，只补挂载行。
  - 回滚：删除 4 份 `opsx-review.md` + `review-rubric.md` + 2 份 tooling；恢复 1.0.7 的 skill/schema/`VERSION`；lock 重建（缺失即降级为全新安装语义）。
- 保护红线更新（`INSTALL_PROMPT.md` ②）：
  - 允许写入新增：`scripts/onepress-gate.sh`、`scripts/sandbox-preflight.spec.ts`（tooling 层）；
  - "不得新建命令文件"改为"不得新建本清单之外的命令文件；onePress 托管的 `opsx-review.md` 由安装器直投"。

### D12 MASTER.md Banner 重写

- 仅在"本次生成"后执行替换：`design-system/pages/[page-name].md` → `openspec/changes/[change-name]/ui-spec.md (DO NOT create design-system/pages/*.md)`。
- 已存在 `MASTER.md`：只输出 `WARN: 基线已存在但 Banner 可能指向 pages/*.md，请手工核对`，不写文件（Protect Local）。
- 三份 carrier 与 `ux-architect.md` 使用同一段文字（归一化 harness 名/路径后一致）。

### D13 检索与动效纪律

- `search.py` 查询强制 2–5 个英文词，优先包含 `dashboard` / `data_heavy` / `checkout` / `booking` / `mobile` / `luxury`；0 结果缩窄关键词重试一次并记录。
- `--json` 可选：脚本解析用 `--json`，LLM 阅读用默认表格；两者并存不强制。
- 动效：只取 `--motion` 的时长（150–250ms）、缓动、交错参数，映射为 Tailwind 过渡类 + `motion-reduce:`；`package.json` 无 `gsap` 时禁止引入 GSAP 代码或 import。

### D14 版本与文档

- `VERSION`：`1.0.7` → `1.1.0`（新增能力，向后兼容；`--require-review` 默认化对本变更之外为 opt-out 可退）。
- `README.md` / `README-ch.md`：目录结构、命令数（12 原生 + 1 onePress 托管）、schema 12 文件、门禁 0–8 + 0.5。
- `INSTALL_PROMPT.md`：① 探测段不变；② 表格新增 4 命令 + rubric + 2 tooling；③ 升级删除范围补充 review 命令；④ 验收项按 D11 更新；⑤ 报告条目不变。

## Risks / Trade-offs

| 风险 | 缓解 |
|---|---|
| Playwright/axe 缺失导致 L1 无法执行 | 可选增强层；`SKIP` + 原因写 `review.md`；不阻断安装与 L2/L3 |
| L1 只覆盖约 57% 无障碍问题 | 明示"必要条件"，L2/L3/verify 继续兜底 |
| 40/20 分数噪音导致误拦 | 观察模式；主判据用 P0/P1 计数 |
| L2 子代理编造 finding | 证据列强制；无证据不计分；超 3 轮 `ESCALATE` |
| Agent 自签 `APPROVED` | 命令/schema 明文禁止；门禁 0.5 + verify 检查；`review.md` 记 approver |
| 四份命令体漂移 | `verify-carriers.sh` 归一化逐字节比对 |
| `openspec init` 重跑覆盖/清理 | 已实测额外命令文件保留；生成命令体被重写但挂载行可重跑安装器恢复 |
| tooling 层扩大安装面 | 仅 2 个文件；用户自建同名文件一律跳过；回滚清单明确 |
| 12 文件口径遗漏 | `INSTALL_PROMPT.md` ④、`ASSETS.md`、README、install 验收同步修改，纳入 tasks 验收 |
| 沙箱与生产仍是两份代码 | 沙箱只引用 `ui-spec.md` 2.1/2.3 变量；L1 与 verify 门禁 2 共用同一 Hex 规则；门禁 8 保持人工 |
| 旧变更在默认强制下被拦 | `--no-require-review` 逃生阀；`--require-review` 供 CI 固定语义 |

## Migration Plan

| 阶段 | 步骤 | 可验证产物 |
|---|---|---|
| P0 | 改 `ui-spec.md` 2.1/第 7 节/章节口径 + 三份 skill 铁律 7/8 + `ux-architect.md`/`opsx-new.md` 检索段 | 模板双目录 `diff` 无差异；`verify-carriers.sh` 通过 |
| P1 | MASTER Banner 重写规则 + 清理降级 runbook + 动效约束 | 三份 skill 归一化等价；grep `gsap` 命中约束条款 |
| P2 | `sandbox-preflight.spec.ts` + 门禁 0.5 + `--require-review`/`--no-require-review` + tooling 安装清单 | 违规沙箱跑出非零；无 Playwright 记 `SKIP`；未签署 ui-spec 被门禁 0.5 拦 |
| P3 | 四份 `opsx-review.md` + `review-rubric.md` + `Review-Status` + `schema.yaml` apply 前置 | 四份命令归一化一致；未签署时 apply 指令停止；签署后放行 |
| P4 | 安装器/INSTALL_PROMPT/ASSETS/README/VERSION 同步 | 四 harness 安装矩阵回归；`openspec validate --all` 通过；lock `files` 含新增资产 |
| 回滚 | 删除 4 命令 + rubric + 2 tooling；恢复 1.0.7 skill/schema/VERSION；lock 重建 | 目标仓库回到 1.0.7 文件集合；`/opsx:apply` 不再校验 `Review-Status` |

## Open Questions

1. **40/20 阈值校准**：观察模式下需要积累 1–2 个真实变更的分布后再定硬门槛；本轮不设数值门槛，只在 `review-rubric.md` 写锚点与观察口径。
2. **`pro-rules.md` 路径**：随 `ui-ux-pro-max` 安装位置变化，`review-rubric.md` 只写"若存在则读取"，不硬编码绝对路径。
