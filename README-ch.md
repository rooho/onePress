# onePress

> OpenSpec × Superpowers × Tailwind/shadcn 的桥接方案包——用一段提示词把**整套前端工程流程**装进任意仓库。

onePress 面向"没有专职设计师、由程序员主导"的团队，解决三个具体问题：

1. **设计靠猜**：让 AI 检索本地设计知识库，产出六章节 `ui-spec.md`（组件层级 / 16 通道 Token / 四态矩阵 / 响应式规则 / 微动效 / 行业反模式），不再凭训练数据均值配色。
2. **交付靠感觉**：先出单文件 `sandbox-preview.html`（四态 + Light/Dark 切换），把色彩、字体、密度、动效锁死，再写生产组件。
3. **质量靠自觉**：八项门禁（Token 纯净度 + WCAG 对比度 + 反模式 + 热区 + 无障碍 + 纯逻辑状态测试 + 人工项）由 `scripts/onepress-gate.sh` 执行。

首批支持四个 AI 编码环境：`.qoder/`、`.opencode/`、`.trae/` 与 `.cursor/`。安装零运行时依赖，任意具备文件读写能力的模型都能执行。

---

## 前置要求

| 项 | 要求 |
|----|------|
| 目标仓库 | 已初始化 git |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest`（Node 22.12+） |
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

脚本一键做完六件事：**探测 harness → 分层写入 → 对齐 OpenSpec 配置 → 写 `onePress.lock` → 自检 → 输出报告**。其中"对齐配置"包括：`openspec/config.yaml` 不存在时创建（`schema: superspec`）、已存在但值不对时只改那一行（CRLF 也保留），以及 `.qoder/`、`.trae/`、`.cursor/` 的 `commands/` 为空时自动 `openspec init --tools <qoder|trae|cursor>` 生成命令。自检覆盖布局、逐字一致、schema 11 文件齐全、`schema: superspec`、命令非空且已挂载、lock 与安装范围一致；失败即中止并给出原因，退出码 `0` 成功 / `1` 失败。你不需要手动核对任何东西。

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
| `.opencode/` | `opencode.json`、`agent/ux-architect.md`、`commands/opsx-{new,apply,verify}.md`、`skills/superpowers-tdd/` | harness | 仅选中 OpenCode |
| `.qoder/skills/onepress-discipline/SKILL.md` | 四条铁律 + TDD 纪律 | harness | 仅选中 Qoder |
| `.qoder/commands/opsx/*.md` | 仅在 frontmatter 后**新增一行**技能引用，主体不改 | harness | 仅选中 Qoder |
| `.trae/skills/onepress-discipline/SKILL.md` | 四条铁律 + TDD 纪律（Trae 载体） | harness | 仅选中 Trae |
| `.trae/commands/opsx-*.md` | 仅在 frontmatter 后**新增一行**技能引用，主体不改 | harness | 仅选中 Trae |
| `.cursor/skills/onepress-discipline/SKILL.md` | 四条铁律 + TDD 纪律（Cursor 载体） | harness | 仅选中 Cursor |
| `.cursor/commands/opsx-*.md` | 仅在 frontmatter 后**新增一行**技能引用，主体不改 | harness | 仅选中 Cursor |
| `openspec/schemas/superspec/` | `schema.yaml` + 10 模板（共 11 文件，含 `ui-spec.md`） | harness | 始终 |
| `onePress.lock` | 版本、安装范围与受保护资产清单 | harness | 始终 |
| `docs/ui-components.md` | 组件注册表模板（首次安装初始化为空表） | project | 始终 |

---

## 二、完整开发流程

一条需求从零到归档，共 5 步。**所有 `/opsx:*` 命令都在目标仓库根目录执行**（即包含 `openspec/` 的那一层）。

| 步骤 | 命令 | 你提供 | 产物 | 通过标准 |
|------|------|--------|------|----------|
| 1 契约初始化 | `/opsx:new <change>` | 功能描述 | `proposal.md`、`design.md`、`ui-spec.md` + `sandbox-preview.html`（仅 UI 变更） | 六章节齐全，沙箱 Light/Dark 可打开 |
| 2 补全工件 | `/opsx:continue` ×N 或 `/opsx:ff` | — | `specs/`、`tasks.md`、`plan.md` | `openspec validate --strict` 通过 |
| 3 实现 | `/opsx:apply` | — | 代码 + `apply.md` | 与沙箱 Light + Dark 对齐 |
| 4 验证 | `/opsx:verify` | — | `verify.md` | 八门禁全绿，无 CRITICAL |
| 5 归档 | `/opsx:archive` | — | 主 specs 更新 + `finalize.md` + 归档目录 | 组件已增量写入注册表 |

### 步骤 1：契约初始化 `/opsx:new`

```text
/opsx:new feat-261103-001-user-role-permission
```

做的事：

1. `/opsx:new` 先按三条规则判定 `**UI Change**: yes|no`（路由/页面；表格列、表单字段或状态展示；破坏性交互），并把结论写到 `proposal.md` 首行；
2. `yes` 时 `ux-architect` 读取 `docs/design-system/projectbaseline/MASTER.md`，再执行双步检索（先 `--domain ux`，后 `--stack shadcn|html-tailwind`）；
3. 从 `docs/ui-components.md`（四列，按"适用骨架"检索）拉取可复用组件；
4. 生成六章节 `ui-spec.md`，随后生成单文件 `sandbox-preview.html`。

`ui-spec.md` 六章节：组件层级拆解 / Design Token 映射（16 通道 + 字体配对 + `xs`–`3xl` 密度）/ 四态状态机矩阵 / 响应式与排版 / 交互热点与微动效 / 行业反模式黑名单。

**人工复核点**：只核对 `ui-spec.md` 与沙箱（Light + Dark 各一遍），此时还没有生产代码。

**可选加速器**：`ui-ux-pro-max` 提供本地 CSV 知识库。`python3` 或技能目录缺失时，检索记为 `SKIP`，`ui-spec.md` 改为手工填写——安装与门禁照常工作。

### 步骤 2：补全工件 `/opsx:continue` / `/opsx:ff`

superspec 的工件序列共 9 个，`/opsx:continue` **每次只产出一个**：

```text
brainstorm → proposal → design → specs → tasks → plan → apply → verify → finalize
```

| 工件 | 用途 |
|------|------|
| `brainstorm.md` | 备选方案对比与选型结论 |
| `proposal.md` | 为什么做、做什么、影响哪些 capability |
| `design.md` | 技术决策（D1…Dn）+ 风险（UI 契约在 `ui-spec.md`） |
| `specs/<capability>/spec.md` | delta 规范：`### Requirement:` + `#### Scenario:`（GIVEN/WHEN/THEN） |
| `tasks.md` | 可勾选的原子任务 |
| `plan.md` | 2–5 分钟粒度的微步骤 |
| `apply.md` / `verify.md` / `finalize.md` | 实现回执 / 验证报告 / 收尾回执 |

想一次性补齐：`/opsx:ff`；只想先看完整提案：`/opsx:propose`；只想讨论不落文件：`/opsx:explore`。

### 步骤 3：实现 `/opsx:apply`（两阶段）

| 阶段 | 做什么 | 产出 | 验收 |
|------|--------|------|------|
| Stage 1 UI 底座直出 | 按 `ui-spec.md` 的 Token 直接写生产级受控组件（四态齐全） | 生产组件 | 与 `sandbox-preview.html` 在 Light + Dark 下无显著偏差 |
| Stage 2 Schema 接线 | 接后端字段、错误码、权限与提交逻辑 | 真实数据流 | 组件结构与 class 集合不变 |

不再注入 in-app State Bar：`sandbox-preview.html` 是唯一视觉验收面。**不写 DOM/RTL 单测**——用眼睛验收，用门禁脚本守质量。

### 步骤 4：验证 `/opsx:verify`

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

执行 `bash scripts/onepress-gate.sh --change openspec/changes/<change>` 自动跑门禁 2/4/5/6/7，其余输出 `MANUAL`。

输出 `openspec/changes/<change>/verify.md`，结论三选一：`PASS` / `PASS WITH WARNINGS` / `FAIL`。有 CRITICAL 不允许归档。

### 步骤 5：归档 `/opsx:archive`

```text
/opsx:archive
```

1. 把 delta specs 同步进 `openspec/specs/<capability>/spec.md`（主规范）；
2. 本次新建/改造的组件**增量追加**到 `docs/ui-components.md`（只追加行，不重排、不删历史）；
3. 整个变更目录移入 `openspec/changes/archive/YYYY-MM-DD-<change>/`；
4. 写 `finalize.md` 收尾回执。

> **OpenCode 没有 `/opsx:archive`**：执行 `openspec archive <name> --yes` 后，用脚本补记组件行：
> `bash scripts/onepress-registry-append.sh --root . --name <Name> --path <path> --archetype <Archetype> --props '<签名>'`
> 脚本幂等，只向指定分区追加，不改动历史行。

多个变更一起收：`/opsx:bulk-archive`。只想同步规范不归档：`/opsx:sync`。

---

## 三、命令参考

| 命令 | Qoder | OpenCode | Trae | Cursor | 用途 |
|------|:----:|:--------:|:----:|:------:|------|
| `/opsx:new <name>` | ✅ | ✅ | ✅ | ✅ | 契约初始化（proposal + design + ui-spec + 沙箱） |
| `/opsx:continue` | ✅ | 用 CLI | ✅ | ✅ | 生成下一个工件 |
| `/opsx:ff` | ✅ | 用 CLI | ✅ | ✅ | 一次补齐全部工件 |
| `/opsx:propose` | ✅ | 用 CLI | ✅ | ✅ | 一步生成完整提案 |
| `/opsx:explore` | ✅ | — | ✅ | ✅ | 只讨论，不落文件 |
| `/opsx:apply` | ✅ | ✅ | ✅ | ✅ | 两阶段实现 |
| `/opsx:verify` | ✅ | ✅ | ✅ | ✅ | 八道门禁 |
| `/opsx:sync` | ✅ | 用 CLI | ✅ | ✅ | 仅同步 delta specs |
| `/opsx:archive` | ✅ | 用 CLI | ✅ | ✅ | 归档 + 注册表增量 |
| `/opsx:bulk-archive` | ✅ | 用 CLI | ✅ | ✅ | 批量归档 |
| `/opsx:onboard` | ✅ | 用 CLI | ✅ | ✅ | 首次全流程引导（原生） |
| `/opsx:update` | ✅ | 用 CLI | ✅ | ✅ | 修订规划工件（原生，实验性） |

- **Qoder / Trae / Cursor**：`openspec init --tools qoder|trae|cursor` 已生成 12 个命令，onePress 只加技能与一行引用（Trae / Cursor 的斜杠命令名为 `/opsx-apply` 形式）。
- **OpenCode**：本包只随附 `new` / `apply` / `verify` 三个命令；其余用 CLI 等价替代：

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

完整细则：`onePress/openspec/CHANGE_NAMING.md`。

---

## 五、资产分层与升级

| 层级 | 资产 | 升级行为 |
|------|------|----------|
| harness（onePress 维护） | `commands/`、`skills/`、`opencode.json`、`openspec/schemas/superspec/` | 全量覆盖（先删旧再写入） |
| project（目标仓库独有） | `docs/ui-components.md`、`openspec/changes/` | 存在即跳过（Protect Local），永不覆盖 |
| 本地修改 | 目标仓库中未提交的 harness 文件改动 | 检测到即提示并跳过 |

升级 = 用新版本模板包重跑一次脚本（`.\install.ps1` / `./install.sh`），`onePress.lock` 里的 `version` 决定"全新安装 / 升级"；旧版本遗留的受管文件会按 lock 清单清理。lock 缺失或损坏 → 按全新安装处理，但项目级资产仍受保护。

卸载：删除 `onePress.lock` 中 `protectedAssets` 之外的安装产物（`.opencode/`、`.qoder/skills/onepress-discipline/`、`.trae/skills/onepress-discipline/`、`.trae/commands/opsx-*`、`.cursor/skills/onepress-discipline/`、`openspec/schemas/superspec/`），保留 `docs/ui-components.md` 与 `openspec/changes/`。

---

## 六、模板包结构

```text
onePress/
├── README-ch.md            # 中文说明（默认）
├── README.md               # English README
├── VERSION                 # 版本号（升级判定基准）
├── ASSETS.md               # 资产清单（归属层级 + 覆盖策略）
├── BLUEPRINT-V3.0.md       # V3.0 纲领（后续迭代基准，不安装）
├── INSTALL_PROMPT.md       # AI 安装入口（五段结构，脚本的等价兜底）
├── install.ps1             # Windows 安装器（探测/写入/自检/报告一条命令）
├── install.sh              # macOS / Linux 安装器
├── opencode/               # OpenCode harness 资产（6 文件）
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-{new,apply,verify}.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness 资产（1 文件）
│   └── skills/onepress-discipline/SKILL.md
├── trae/                   # Trae harness 资产（1 文件）
│   └── skills/onepress-discipline/SKILL.md
├── cursor/                 # Cursor harness 资产（1 文件）
│   └── skills/onepress-discipline/SKILL.md
├── openspec-schema/superspec/   # 分发给目标仓库的 schema（11 文件，含 templates/ui-spec.md）
└── openspec/               # 本方案自身的规范工作区（不安装）
    ├── config.yaml         # schema: superspec
    ├── CHANGE_NAMING.md    # 变更命名规范
    ├── schemas/superspec/  # 与 openspec-schema/ 内容一致
    ├── specs/              # 主规范（份数与需求数随归档增长）
    └── changes/archive/    # 已归档变更（完整证据链）
```

> 包内 `openspec/` 是**本方案自己的**规范与历史，不写入目标仓库；要安装到目标仓库的 schema 在 `openspec-schema/`。
> 因此在本仓库内跑 OpenSpec 命令要在 `onePress/` 目录下执行（那里有 `openspec/config.yaml`）。

---

## 七、FAQ

**Q：AI 说克隆下来找不到 `INSTALL_PROMPT.md`？**
A：多半是稀疏检出路径与实际布局不符（cone 模式对不存在的路径静默空检出、不报错）。让它先 `git ls-tree -r --name-only HEAD` 核对真实布局，再 `git sparse-checkout disable` 全量检出（包体仅 KB 级）。这条已写进上面的安装提示词，正常情况下它会自己兜住。

**Q：没装 Superpowers 插件，`/opsx:continue` 卡在 plan 步骤报 `superpowers:writing-plans` 不可用？**
A：1.0.4 起 superspec 的 Superpowers 技能引用全部带内联兜底（brainstorm / plan / apply 2c / finalize 四处），技能缺失时 AI 会按兜底步骤自行产出 `plan.md`，不会中断。旧版本（schema version ≤ 4）升级重装即可；临时也可让 AI 直接按 `tasks.md` 拆 2–5 分钟微步骤写入 `plan.md`。

**Q：目标仓库没有 OpenSpec？**
A：安装能完成，但 `/opsx:*` 与 `ui-spec.md` / `sandbox-preview.html` 的产出需要 OpenSpec。先 `openspec init --tools qoder|trae|cursor|opencode` 再安装。

**Q：OpenCode 下没有 `/opsx:continue`、`/opsx:archive`？**
A：本包只随附三个命令。其余用 `openspec status` / `openspec instructions` / `openspec archive` 等价操作，或自行补 `.opencode/commands/opsx-*.md`。

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
