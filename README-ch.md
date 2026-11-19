# onePress

> OpenSpec × Superpowers × Tailwind/shadcn 的桥接方案包——用一段提示词把**整套前端工程流程**装进任意仓库。

onePress 面向"没有专职设计师、由程序员主导"的团队，解决三个具体问题：

1. **设计靠猜**：让 AI 检索本地设计知识库，产出七章节 `ui-spec.md`（组件层级 / 16 通道 Token / 四态矩阵 / 响应式规则 / 微动效 / 行业反模式 / 沙箱预览），不再凭训练数据均值配色。
2. **交付靠感觉**：先出单文件 `sandbox-preview.html`（四态 + Light/Dark 切换），把色彩、字体、密度、动效锁死，再写生产组件。
3. **质量靠自觉**：八项 UI 门禁（Token 纯净度 + WCAG 对比度 + 反模式 + 热区 + 无障碍 + 纯逻辑状态测试 + 人工项）由 `scripts/onepress-gate.sh` 执行；plan 阶段由 `scripts/onepress-plan-lint.sh` 检查 plan + design + tasks 结构；执行阶段强制 TDD、根因调试与实时证据；验证阶段要求 `verification-evidence.md` 与冷上下文代码盲审，由 `scripts/onepress-evidence-lint.sh` 检查。

首批支持四个 AI 编码环境：`.qoder/`、`.opencode/`、`.trae/` 与 `.cursor/`。安装零运行时依赖，任意具备文件读写能力的模型都能执行。

---

## 前置要求

| 项 | 要求 |
|----|------|
| 目标仓库 | 已初始化 git |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest`（**>= 2.0.0**；1.x 环境请改用 onePress v1.1.0） |
| 设计检索（可选） | `npm install -g ui-ux-pro-max-cli` + `uipro init --ai <harness> --offline`；缺失时自动降级 |
| AI 助手 | Qoder / OpenCode / Trae / Cursor / 任意具备文件读写与命令执行能力的 Agent |

---

## 一、安装（一条命令）

把模板包 clone 下来，在**目标仓库根目录**执行对应脚本：

```powershell
# Windows（PowerShell 5.1+）
.\install.ps1
```
```bash
# macOS / Linux
./install.sh
```

常用参数（两侧等价）：

```powershell
.\install.ps1 -Harness qoder     # 只装 Qoder（默认 auto：按 .qoder/ .opencode/ .trae/ .cursor/ 探测）
.\install.ps1 -Harness trae,cursor  # 只装 Trae + Cursor
.\install.ps1 -Target D:\repo    # 指定目标仓库
.\install.ps1 -DryRun            # 只打印计划，不落盘
.\install.ps1 -Source D:\pack    # 指定模板包目录（默认脚本所在目录）
```
```bash
./install.sh --harness qoder --target ~/repo --dry-run --source ~/pack
```

脚本一键做完六件事：**探测 harness → 分层写入 → 对齐 OpenSpec 配置 → 写 `onePress.lock` → 自检 → 输出报告**。其中"对齐配置"包括：`openspec/config.yaml` 不存在时创建（`schema: superspec`）、已存在但值不对时只改那一行（CRLF 也保留），以及 `.qoder/`、`.trae/`、`.cursor/` 的 `commands/` 为空时自动 `openspec init --tools <qoder|trae|cursor>` 生成命令。自检覆盖布局、逐字一致、schema 15 文件齐全、`schema: superspec`、顶层 `rules`、review 托管命令与挂载、命令非空且已挂载、lock 与安装范围一致；失败即中止并给出原因，退出码 `0` 成功 / `1` 失败。你不需要手动核对任何东西。

> 实测：`openspec init` 在 `config.yaml` 已存在时**不会覆盖它**，所以"先对齐配置、再 init、再挂载"的顺序是安全的；`-NoInit` / `--no-init` 可关闭自动 init。

只下载了脚本、没有模板包？脚本会自动浅克隆：

```powershell
.\install.ps1 -Repo https://github.com/rooho/onePress.git -Ref main
```
```bash
./install.sh --repo https://github.com/rooho/onePress.git --ref main
```

> 不用脚本、想让 AI 自己装也可以：把 `INSTALL_PROMPT.md` 全文交给任意可读写文件的 Agent，它按同样五段执行，产出与本脚本逐字节一致。

### 安装范围会自动判定

脚本探测目标仓库用的是哪个 AI 编码环境，**只装选中的那个**，无需手工指定：

| 探测结果 | 安装内容 |
|----------|----------|
| 只有 `.qoder/` | 仅 Qoder 资产 |
| 只有 `.opencode/` | 仅 OpenCode 资产 |
| 只有 `.trae/` | 仅 Trae 资产 |
| 只有 `.cursor/` | 仅 Cursor 资产 |
| 多个目录存在 | 对应多套都装 |
| 一个都没有 | 交互询问你用哪个（Qoder / OpenCode / Trae / Cursor / 全部），**不默认全装**；无人值守场景请显式传 `-Harness` / `--harness` |

未选中的环境不会被创建目录、不会被写入文件；`onePress.lock` 的 `harnesses` 记录实际安装范围（未装的为 `false`），升级时也只覆盖已启用的那一套。

### 安装产物

| 目标仓库路径 | 内容 | 层级 | 安装条件 |
|--------------|------|------|----------|
| `.opencode/` | `opencode.json`、`agent/ux-architect.md`、`commands/opsx-review.md`、`skills/superpowers-tdd/` | harness | 仅选中 OpenCode |
| `.qoder/skills/onepress-discipline/SKILL.md` | 十三条铁律（契约 / 分流 / 检索 / 沙箱 / 门禁 / Token / 四态 / 无障碍 / 防呆 / 编码前评审 / TDD 与根因调试 / 验证双锁 / 任务与设计契约）+ TDD 纪律 | harness | 仅选中 Qoder |
| `.agents/skills/openspec-*/SKILL.md`（12 个） | OpenSpec 2.0 工作流技能；仅在 frontmatter 后**新增一行**技能引用，正文不改 | harness | 始终（四 harness 共享） |
| `.trae/skills/onepress-discipline/SKILL.md` | 十三条铁律 + TDD 纪律（Trae 载体） | harness | 仅选中 Trae |
| `.trae/commands/opsx-review.md` | onePress 托管评审命令（斜杠入口 `/opsx:review`） | harness | 仅选中 Trae |
| `.cursor/skills/onepress-discipline/SKILL.md` | 十三条铁律 + TDD 纪律（Cursor 载体） | harness | 仅选中 Cursor |
| `.cursor/commands/opsx-review.md` | onePress 托管评审命令（斜杠入口 `/opsx:review`） | harness | 仅选中 Cursor |
| `openspec/schemas/superspec/` | `schema.yaml` + 14 模板（共 15 文件，含 `ui-spec.md`、`review.md`、`review-rubric.md`、`verification.md` 与 `code-reviewer.md`） | harness | 始终 |
| `onePress.lock` | 版本、安装范围与受保护资产清单 | harness | 始终 |
| `docs/ui-components.md` | 组件注册表模板（四列，首次安装初始化为空表） | project | 始终 |

> `docs/design-system/projectbaseline/MASTER.md` 由可选的 `ui-ux-pro-max` 技能**一次性**生成；onePress 在安装/升级时只保护它，不创建也不改写。

---

## 二、完整开发流程

一条需求从零到归档，共 7 步。**所有 `/openspec-*` 技能都在目标仓库根目录执行**（即包含 `openspec/` 的那一层；OpenSpec 2.0 skills 交付形态）。

| 步骤 | 命令 | 你提供 | 产物 | 通过标准 |
|------|------|--------|------|----------|
| 1 新建变更 | `/openspec-new-change <change>` | 功能描述 | `proposal.md`（含 `**UI Change**` 判定） | proposal 落盘 |
| 2 补全规划 | `/openspec-continue-change` ×N 或 `/openspec-ff-change` | — | `brainstorm.md`、`design.md`（+ `ui-spec.md` / `sandbox-preview.html`）、`specs/`、`tasks.md`、`plan.md` | `openspec validate --strict` 与 plan-lint 通过；七章节齐全，沙箱 Light/Dark 可打开 |
| 3 设计评审 | `/opsx:review <change>` | 人工批注（L3） | `review.md`（非 UI 变更写 `Result: SKIP`） | `P0 = 0`、`P1 = 0`、`Review-Status: APPROVED`，review-lint 通过 |
| 4 实现 | `/openspec-apply-change` | — | 代码 + `apply.md` | `review.md` 存在且 Result 为 PASS/SKIP；TDD 证据（RED→GREEN→REFACTOR）；与沙箱 Light + Dark 对齐 |
| 5 收集证据 | `/openspec-continue-change`（verify-report）或 `openspec instructions verify-report --change <change>` | — | `verification-evidence.md`、`code-review-packet.md`（仅 human 模式） | 实测命令输出、`Critical: 0`、`Important: 0`、evidence-lint 通过 |
| 6 验证 | `/openspec-verify-change` | — | `verify.md` | 引用证据报告；八项 UI 门禁全绿，无 CRITICAL |
| 7 归档 | `/openspec-archive-change` | — | 主 specs 更新 + `finalize.md` + 归档目录 | 组件已增量写入注册表 |

### 步骤 1：新建变更 `/openspec-new-change`

```text
/openspec-new-change feat-261103-001-user-role-permission
```

做的事：

1. 创建变更目录与 `proposal.md` 骨架（为什么做、做什么、影响哪些 capability）；
2. 按三条规则判定 `**UI Change**: yes|no`（路由/页面；表格列、表单字段或状态展示；破坏性交互），并把结论写到 `proposal.md` 首行；
3. 此时**不生成** `ui-spec.md` 或沙箱；UI 契约在步骤 2 的 `design` 工件中产出。

### 步骤 2：补全规划工件 `/openspec-continue-change` / `/openspec-ff-change`

superspec 的 DAG 工件共 11 个，`/openspec-continue-change` **每次只产出一个**：

```text
brainstorm → proposal → design → specs → tasks → plan → review → apply → verify-report → verify → finalize
```

`ui-spec.md` / `sandbox-preview.html` 是 `design` 工件的**条件产物，非独立 DAG 工件**：仅 `**UI Change**: yes` 时产出；`review` 是 `plan` 之后的真实 DAG 工件，`apply` 依赖它。

| 工件 | 用途 |
|------|------|
| `brainstorm.md` | 备选方案对比与选型结论 |
| `proposal.md` | 为什么做、做什么、影响哪些 capability |
| `design.md` | 技术决策（D1…Dn）+ 风险（UI 契约在 `ui-spec.md`） |
| `ui-spec.md` / `sandbox-preview.html` | **条件产物，非 DAG 工件**：七章节契约 + 单文件沙箱；仅 `**UI Change**: yes` 时由 `design` 工件产出 |
| `specs/<capability>/spec.md` | delta 规范：`### Requirement:` + `#### Scenario:`（GIVEN/WHEN/THEN） |
| `tasks.md` | 可勾选的原子任务 |
| `plan.md` | 2–5 分钟微步骤 + Spec / Global Constraints / Review Focus / Evidence Map / File Structure / Files / Interfaces / Self-Review；生成后跑 plan-lint |
| `review.md` | 编码前评审回执：`Result: PASS`（P0=0、P1=0、人类批准）或 `Result: SKIP`（非 UI）；记录三个契约哈希 |
| `apply.md` / `verify.md` / `finalize.md` | 实现回执 / 验证报告 / 收尾回执 |

`review.md` 只在评审收敛时生成；失败轮次写入 `.review/round-<n>.md`。`ui-spec.md`、沙箱或 `plan.md` 任一变化都会使 `review.md` 失效，必须删除并复审。

想一次性补齐规划工件：`/openspec-ff-change`；只想先看完整提案：`/openspec-propose`；只想讨论不落文件：`/openspec-explore`。

### 步骤 3：设计评审 `/opsx:review`

```text
/opsx:review feat-261103-001-user-role-permission
```

- **L1 确定性预检**：沙箱四态 × 双主题，WCAG、热区、溢出、Hex/Emoji、CLS 代理指标；依赖缺失记 SKIP。
- **L2 冷上下文盲审**：输入 proposal / design / specs / tasks / plan / MASTER / ui-spec / 沙箱 / rubric；主判据 `P0 = 0 且 P1 = 0`，每条 finding 必须带证据。
- **L3 人类批注**：只有人类可把 `ui-spec.md` 第 3 行改为 `> Review-Status: APPROVED`；回写批注后必须重置为 PENDING 并复审。
- 收敛后写 `review.md` 并记录 `ui-spec-sha256` / `sandbox-sha256` / `plan-sha256`；`apply` 前必须通过 `scripts/onepress-review-lint.sh`。
- 非 UI 变更直接写 `Result: SKIP`，不产生 ui-spec/沙箱，也不进入 L1/L2/L3。


### 步骤 4：实现 `/openspec-apply-change`（两阶段）

| 阶段 | 做什么 | 产出 | 验收 |
|------|--------|------|------|
| Stage 1 UI 底座直出 | 按 `ui-spec.md` 的 Token 直接写生产级受控组件（四态齐全） | 生产组件 | 与 `sandbox-preview.html` 在 Light + Dark 下无显著偏差 |
| Stage 2 Schema 接线 | 接后端字段、错误码、权限与提交逻辑 | 真实数据流 | 组件结构与 class 集合不变 |

不再注入 in-app State Bar：`sandbox-preview.html` 是唯一视觉验收面。**不写 DOM/RTL 单测**——用眼睛验收，用门禁脚本守质量。

### 步骤 5：收集证据（verify-report）

`verify` 之前必须完成 `verify-report` 工件并运行 `bash scripts/onepress-evidence-lint.sh --change openspec/changes/<change>`：它要求带退出码的实测输出、`Critical: 0`、`Important: 0`，以及 UI 变更的 `onepress-gate.sh` 证据。代码盲审必须使用 `templates/code-reviewer.md` 在冷上下文中执行（优先子代理，其次人类新会话）。

### 步骤 6：验证 `/openspec-verify-change`

八项门禁，任一失败打回 `apply` 对应阶段：

| # | 门禁 | 方式 |
|---|------|------|
| 0 | UI 变更必有 `ui-spec.md` + `sandbox-preview.html` | AUTO |
| 1 | 四态与矩阵一致，CLS < 0.1 | MANUAL |
| 2 | Token 纯净度（三条正则）+ WCAG 对比度 ≥4.5:1（大字与边界 ≥3:1） | AUTO |
| 3 | 断点零横向滚动、长串折行、`+n` 展开 | MANUAL |
| 4 | 状态机单测（仅纯逻辑，禁 RTL） | AUTO |
| 5 | A11y CRITICAL：焦点环、`aria-label`、`aria-describedby`、`aria-hidden` | AUTO |
| 6 | 热区 ≥44×44px、`cursor-pointer`、150–250ms、`motion-reduce:` | AUTO |
| 7 | 反模式：零 Emoji 图标、未命中黑名单 | AUTO |
| 8 | 与沙箱无显著视觉偏差 | MANUAL |

执行 `bash scripts/onepress-gate.sh --change openspec/changes/<change>` 自动跑门禁 0/0.5/2/4/5/6/7，其余输出 `MANUAL`。apply 前必须完成 `review` 工件：`review.md` 存在且 `Result` 为 `PASS`/`SKIP`，并通过 `scripts/onepress-review-lint.sh`；UI 变更还要求 `Review-Status: APPROVED`。

plan 阶段生成 `plan.md` 后运行 `bash scripts/onepress-plan-lint.sh --change openspec/changes/<change>`：FAIL 必须先修；WARN 可在 CI 中用 `--strict` 升级为失败。

输出 `openspec/changes/<change>/verify.md`，结论三选一：`PASS` / `PASS WITH WARNINGS` / `FAIL`。有 CRITICAL 不允许归档。

### 步骤 7：归档 `/openspec-archive-change`

```text
/openspec-archive-change
```

1. 把 delta specs 同步进 `openspec/specs/<capability>/spec.md`（主规范）；
2. 本次新建/改造的组件**增量追加**到 `docs/ui-components.md`（只追加行，不重排、不删历史）；
3. 整个变更目录移入 `openspec/changes/archive/YYYY-MM-DD-<change>/`；
4. 写 `finalize.md` 收尾回执。

> **OpenCode 与其它 harness 一致**：直接执行 `/openspec-archive-change`；归档后如需补记组件行：
> `bash scripts/onepress-registry-append.sh --root . --name <Name> --path <path> --archetype <Archetype> --props '<签名>'`
> 脚本幂等，只向指定分区追加，不改动历史行。

多个变更一起收：`/openspec-bulk-archive-change`。只想同步规范不归档：`/openspec-sync-specs`。

---

## 三、命令参考

| 命令 | Qoder | OpenCode | Trae | Cursor | 用途 |
|------|:----:|:--------:|:----:|:------:|------|
| `/openspec-new-change <name>` | ✅ | ✅ | ✅ | ✅ | 契约初始化（proposal + design + ui-spec + 沙箱） |
| `/openspec-continue-change` | ✅ | 用 CLI | ✅ | ✅ | 生成下一个工件 |
| `/openspec-ff-change` | ✅ | 用 CLI | ✅ | ✅ | 一次补齐全部工件 |
| `/openspec-propose` | ✅ | 用 CLI | ✅ | ✅ | 一步生成完整提案 |
| `/openspec-explore` | ✅ | — | ✅ | ✅ | 只讨论，不落文件 |
| `/openspec-apply-change` | ✅ | ✅ | ✅ | ✅ | 两阶段实现 |
| `/openspec-verify-change` | ✅ | ✅ | ✅ | ✅ | 八道门禁 |
| `/openspec-sync-specs` | ✅ | 用 CLI | ✅ | ✅ | 仅同步 delta specs |
| `/openspec-archive-change` | ✅ | ✅ | ✅ | ✅ | 归档 + 注册表增量 |
| `/openspec-bulk-archive-change` | ✅ | 用 CLI | ✅ | ✅ | 批量归档 |
| `/openspec-onboard` | ✅ | 用 CLI | ✅ | ✅ | 首次全流程引导（原生） |
| `/openspec-update-change` | ✅ | 用 CLI | ✅ | ✅ | 修订规划工件（原生，实验性） |

- **Qoder / Trae / Cursor**：OpenSpec 2.0 将 12 个技能统一安装到 `.agents/skills/`，安装器在每个 `SKILL.md` 的 frontmatter 后挂载一行 `onepress-discipline` 引用；另直投 1 个托管 `/opsx:review` 命令。
- **OpenCode**：与其它 harness 共用 `.agents/skills/`，另随附 1 个托管 `commands/opsx-review.md`；不再直投 `new` / `apply` / `verify` 命令：

```bash
openspec status --change <name> --json          # 看进度与下一步
openspec instructions <artifact> --change <name> --json
openspec validate <name> --strict               # 规范校验
openspec archive <name> --yes                   # 归档并同步 specs
```

---

## 四、变更命名规范

```text
{type}-{YYMMDD}-{NNN}-{slug}

展示层（文档 / commit / 沟通）：FEAT-261103-001-user-role-permission
工具层（目录名，必须全小写）：  feat-261103-001-user-role-permission
```

- `type`：`feat` / `fixbug` / `refactor` / `perf` / `docs` / `chore` / `test` / `revert`，一个变更只允许一种；
- `YYMMDD`：创建当天日期；`NNN`：同日自增，从 `001` 起；
- `slug`：1–10 个英文单词，kebab-case，描述特性而非动作流水；
- OpenSpec 强制目录名全小写 kebab-case，大写只能出现在展示层；
- 归档时工具自动加 `YYYY-MM-DD-` 前缀。

完整细则：`studio/openspec/CHANGE_NAMING.md`。

---

## 五、资产分层与升级

| 层级 | 资产 | 升级行为 |
|------|------|----------|
| harness（onePress 维护） | `commands/`、`skills/`、`opencode.json`、`openspec/schemas/superspec/` | 全量覆盖（先删旧再写入） |
| project（目标仓库独有） | `docs/ui-components.md`、`openspec/changes/` | 存在即跳过（Protect Local），永不覆盖 |
| 本地修改 | 目标仓库中未提交的 harness 文件改动 | 检测到即提示并跳过 |

升级 = 用新版本模板包重跑一次脚本（`.\install.ps1` / `./install.sh`），`onePress.lock` 里的 `version` 决定"全新安装 / 升级"；旧版本遗留的受管文件会按 lock 清单清理。lock 缺失或损坏 → 按全新安装处理，但项目级资产仍受保护。

卸载：删除 `onePress.lock` 中 `protectedAssets` 之外的安装产物（`.opencode/`、`.qoder/skills/onepress-discipline/`、`.trae/skills/onepress-discipline/`、`.trae/commands/opsx-review.md`、`.cursor/skills/onepress-discipline/`、`openspec/schemas/superspec/`），保留 `docs/ui-components.md` 与 `openspec/changes/`；`.agents/skills/` 归 OpenSpec CLI 所有，卸载不删除（可执行 `openspec update` 去除引用行）。

---

## 六、模板包结构

```text
onePress/                    # 发布包根目录（由 studio/pack/ 生成）
├── README-ch.md            # 中文说明（默认）
├── README.md               # English README
├── VERSION                 # 版本号（升级判定基准）
├── ASSETS.md               # 资产清单（归属层级 + 覆盖策略）
├── INSTALL_PROMPT.md       # AI 安装入口（五段结构，脚本的等价兜底）
├── install.ps1             # Windows 安装器（探测/写入/自检/报告一条命令）
├── install.sh              # macOS / Linux 安装器
├── opencode/               # OpenCode harness 资产（4 文件）
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-review.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness 资产（2 文件）
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx/review.md
├── trae/                   # Trae harness 资产（2 文件）
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx-review.md
├── cursor/                 # Cursor harness 资产（2 文件）
│   ├── skills/onepress-discipline/SKILL.md
│   └── commands/opsx-review.md
├── scripts/                # 发布包侧脚本
│   ├── onepress-gate.sh    # 门禁 0/0.5/2/4/5/6/7 AUTO + MANUAL 1/3/8（安装）
│   ├── onepress-plan-lint.sh  # plan + design + tasks 结构门禁（安装）
│   ├── onepress-evidence-lint.sh  # verification-evidence 证据门禁（安装）
│   ├── onepress-review-lint.sh  # review.md 回执与契约哈希校验（安装）
│   ├── sandbox-preflight.spec.ts  # L1 预检（安装，依赖可选）
│   └── onepress-registry-append.sh  # 按分区追加组件行（随包分发，手工运行）
└── openspec-schema/superspec/   # 分发给目标仓库的 schema（15 文件，含 templates/ui-spec.md、review.md、review-rubric.md、verification.md 与 code-reviewer.md）
```

> `blueprint/`（迭代纲领）与 `openspec/`（本方案自己的规范工作区）位于**开发仓**，永不进入发布包；发布包由 `studio/pack/` 生成。

---

## 七、FAQ

**Q：AI 说克隆下来找不到 `INSTALL_PROMPT.md`？**
A：多半是稀疏检出路径与实际布局不符（cone 模式对不存在的路径静默空检出、不报错）。让它先 `git ls-tree -r --name-only HEAD` 核对真实布局，再 `git sparse-checkout disable` 全量检出（包体仅 KB 级）。这条已写进上面的安装提示词，正常情况下它会自己兜住。

**Q：没装 Superpowers 插件，`/openspec-continue-change` 卡在 plan 步骤报 `superpowers:writing-plans` 不可用？**
A：1.0.4 起 superspec 的 Superpowers 技能引用全部带内联兜底（brainstorm / plan / apply 2c / finalize 四处），技能缺失时 AI 会按兜底步骤自行产出 `plan.md`（含 Spec / Global Constraints / Review Focus / Evidence Map / File Structure / Files / Interfaces / Self-Review），不会中断。旧版本（schema version ≤ 5）升级重装即可；生成后运行 `bash scripts/onepress-plan-lint.sh --change <change>` 自检。

**Q：目标仓库没有 OpenSpec？**
A：安装能完成，但 `/openspec-*` 技能与 `ui-spec.md` / `sandbox-preview.html` 的产出需要 OpenSpec。先 `openspec init --tools qoder|trae|cursor|opencode` 再安装。

**Q：OpenCode 下工作流技能在哪里？**
A：OpenSpec 2.0 统一安装到 `.agents/skills/openspec-*`，四 harness 共享；本包仅额外随附 `commands/opsx-review.md`。若技能缺失，执行 `openspec init --tools opencode` 或 `openspec update` 补齐。

**Q：能不能只装某一个平台？**
A：能，且默认就是这样。安装器按目录探测判定：只有 `.qoder/` 只装 Qoder，只有 `.trae/` 只装 Trae，只有 `.cursor/` 只装 Cursor，多个目录存在则对应多套都装，一个都没有会先问你。也可以用 `--harness trae,cursor` 显式指定。事后想补装另一个环境，再跑一次安装即可，只会增量写那一套，已装的不受影响。

**Q：`.qoder/`、`.opencode/`、`.trae/`、`.cursor/` 要不要入库？**
A：默认不入库（本地环境配置）。`onePress.lock` 与 `docs/ui-components.md` 建议入库。

**Q：怎么确认装好了？**
A：看脚本退出码与报告——`0` 且收尾语为 `onePress v<version> 安装完成（harnesses: <范围>）` 即成功，报告里已列出跳过项与自检结果。想自己复核只查三处——`onePress.lock` 存在且 `version` 匹配；`.qoder/commands/`、`.trae/commands/`、`.cursor/commands/` 每个命令都有一行 `onepress-discipline` 引用；`openspec/schemas/superspec/` 有 10 个文件。

**Q：重装会不会把我改过的工具链文件冲掉？**
A：不会。已跟踪文件若有未提交修改，脚本会提示并跳过该文件；`.qoder/commands/`、`.trae/commands/`、`.cursor/commands/` 里的技能引用已存在则跳过，命令正文永不改写。

**Q：已有 `.qoder/` / `.trae/` / `.cursor/` 会被破坏吗？**
A：不会。只新增技能文件，并在既有命令 frontmatter 后插入一行引用，命令体零改动。

---

## License

MIT
