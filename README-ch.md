# onePress

> OpenSpec × Superpowers × Tailwind/shadcn 的桥接方案包——用一段提示词把**整套前端工程流程**装进任意仓库。

onePress 面向"没有专职设计师、由程序员主导"的团队，解决三个具体问题：

1. **UI 靠猜**：让 AI 按功能点自动推导 `ui_contract` 契约（页面骨架 / 字段控件 / 状态矩阵 / 布局 Token），不再临场发挥。
2. **交付靠感觉**：沙箱即生产——先出可点击的 UI 底座，用浮动 State Bar 十秒肉眼验收，再接后端。
3. **质量靠自觉**：秒级静态门禁（tsc + Token 纯净度扫描 + 纯逻辑 Hook TDD + 四态点检）卡在归档前。

首批支持两个 AI 编码环境：`.qoder/` 与 `.opencode/`。安装零运行时依赖，任意具备文件读写能力的模型都能执行。

---

## 前置要求

| 项 | 要求 |
|----|------|
| 目标仓库 | 已初始化 git |
| OpenSpec CLI | `npm install -g @fission-ai/openspec@latest`（Node 22.12+） |
| AI 助手 | Qoder / OpenCode / 任意具备文件读写与命令执行能力的 Agent |

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
.\install.ps1 -Harness qoder     # 只装 Qoder（默认 auto：按 .qoder/ .opencode/ 探测）
.\install.ps1 -Target D:\repo    # 指定目标仓库
.\install.ps1 -DryRun            # 只打印计划，不落盘
.\install.ps1 -Source D:\pack    # 指定模板包目录（默认脚本所在目录）
```
```bash
./install.sh --harness qoder --target ~/repo --dry-run --source ~/pack
```

脚本一键做完五件事：**探测 harness → 分层写入 → 写 `onePress.lock` → 自检 → 输出报告**。自检覆盖布局、逐字一致、schema 10 文件齐全、lock 与安装范围一致；失败即中止并给出原因，退出码 `0` 成功 / `1` 失败。你不需要手动核对任何东西。

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
| 两者都有 | 两套都装 |
| 两者都没有 | 交互询问你用哪个（Qoder / OpenCode / 两者），**不默认全装**；无人值守场景请显式传 `-Harness` / `--harness` |

未选中的环境不会被创建目录、不会被写入文件；`onePress.lock` 的 `harnesses` 记录实际安装范围（未装的为 `false`），升级时也只覆盖已启用的那一套。

### 安装产物

| 目标仓库路径 | 内容 | 层级 | 安装条件 |
|--------------|------|------|----------|
| `.opencode/` | `opencode.json`、`agent/ux-architect.md`、`commands/opsx-{new,apply,verify}.md`、`skills/superpowers-tdd/` | harness | 仅选中 OpenCode |
| `.qoder/skills/onepress-discipline/SKILL.md` | 四条铁律 + TDD 纪律 | harness | 仅选中 Qoder |
| `.qoder/commands/opsx/*.md` | 仅在 frontmatter 后**新增一行**技能引用，主体不改 | harness | 仅选中 Qoder |
| `openspec/schemas/superspec/` | `schema.yaml` + 9 模板（共 10 文件） | harness | 始终 |
| `onePress.lock` | 版本、安装范围与受保护资产清单 | harness | 始终 |
| `docs/ui-components.md` | 组件注册表模板（首次安装初始化为空表） | project | 始终 |

---

## 二、完整开发流程

一条需求从零到归档，共 5 步。**所有 `/opsx:*` 命令都在目标仓库根目录执行**（即包含 `openspec/` 的那一层）。

| 步骤 | 命令 | 你提供 | 产物 | 通过标准 |
|------|------|--------|------|----------|
| 1 契约初始化 | `/opsx:new <change>` | 功能描述 | `proposal.md`、`design.md`（含 `ui_contract`） | 契约字段与后端 Schema 逐项对齐 |
| 2 补全工件 | `/opsx:continue` ×N 或 `/opsx:ff` | — | `specs/`、`tasks.md`、`plan.md` | `openspec validate --strict` 通过 |
| 3 实现 | `/opsx:apply` | — | 代码 + `apply.md` | Stage 1 State Bar 验收通过 |
| 4 验证 | `/opsx:verify` | — | `verify.md` | 四道门禁全绿，无 CRITICAL |
| 5 归档 | `/opsx:archive` | — | 主 specs 更新 + `finalize.md` + 归档目录 | 组件已增量写入注册表 |

### 步骤 1：契约初始化 `/opsx:new`

```text
/opsx:new feat-261103-001-user-role-permission
```

做的事：

1. `ux-architect`（OpenCode 为 subagent，Qoder 为技能内联）检索 `docs/ui-components.md`，能复用的组件必须列入 `reuse_components`；
2. 后端字段逐字段映射到控件与空值降级策略；
3. 页面骨架从 5 种 archetype 里择一：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`；
4. 把契约写到 `openspec/changes/<change>/design.md` 底部。

产物示例（`design.md` 末尾的 `ui_contract`）：

```yaml
ui_contract:
  archetype: "Standard-CRUD-Table"
  reuse_components: ["DataTable", "RoleBadge"]
  schema_mapping:
    - field: "user.role"
      widget: "Select"
      rule: "required | default: member"
  states_matrix:
    query: { loading: "Skeleton 等高", empty: "EmptyState + 重置", error: "Alert + 重试" }
    mutation: { submitting: "disabled + Loader2", destructive_guard: "AlertDialog 二次确认" }
  layout_tokens:
    container: "max-w-7xl mx-auto p-6 space-y-6"
```

**人工复核点**：只核对契约本身（字段映射、状态矩阵、复用组件），此时还没有代码。

### 步骤 2：补全工件 `/opsx:continue` / `/opsx:ff`

superspec 的工件序列共 9 个，`/opsx:continue` **每次只产出一个**：

```text
brainstorm → proposal → design → specs → tasks → plan → apply → verify → finalize
```

| 工件 | 用途 |
|------|------|
| `brainstorm.md` | 备选方案对比与选型结论 |
| `proposal.md` | 为什么做、做什么、影响哪些 capability |
| `design.md` | 技术决策（D1…Dn）+ 风险 + 底部 `ui_contract` |
| `specs/<capability>/spec.md` | delta 规范：`### Requirement:` + `#### Scenario:`（GIVEN/WHEN/THEN） |
| `tasks.md` | 可勾选的原子任务 |
| `plan.md` | 2–5 分钟粒度的微步骤 |
| `apply.md` / `verify.md` / `finalize.md` | 实现回执 / 验证报告 / 收尾回执 |

想一次性补齐：`/opsx:ff`；只想先看完整提案：`/opsx:propose`；只想讨论不落文件：`/opsx:explore`。

### 步骤 3：实现 `/opsx:apply`（两阶段）

| 阶段 | 做什么 | 产出 | 验收 |
|------|--------|------|------|
| Stage 1 UI 底座直出 | 按 `ui_contract` 直接生成页面（mock 数据 + 四态） | 可点击页面 + 浮动 State Bar | 十个状态按钮逐个点，肉眼 10 秒确认 |
| Stage 2 Schema 接线 | 接后端字段、错误码、权限与提交逻辑 | 真实数据流 | 表单校验、破坏性操作二次确认生效 |

State Bar 一次只驱动一个状态（Idle / Loading / Empty / Error / Submitting），**不写 DOM 单测**——用眼睛验收，用类型与正则守质量。

### 步骤 4：验证 `/opsx:verify`

四道门禁，任一失败打回 `apply` 对应阶段：

| 门禁 | 内容 | 失败示例 |
|------|------|----------|
| 类型 | `tsc --noEmit` 零错误 | 属性名拼错 |
| Token 纯净度 | 静态扫描三类禁令 | 内联 style / `#3b82f6` / `w-[317px]` |
| 纯逻辑 TDD | Hook 与纯函数有测试且通过 | 分页计算无测试 |
| 四态点检 | query 与 mutation 状态齐全 | 缺 Empty 或 Error |

输出 `openspec/changes/<change>/verify.md`，结论三选一：`PASS` / `PASS WITH WARNINGS` / `FAIL`。有 CRITICAL 不允许归档。

### 步骤 5：归档 `/opsx:archive`

```text
/opsx:archive
```

1. 把 delta specs 同步进 `openspec/specs/<capability>/spec.md`（主规范）；
2. 本次新建/改造的组件**增量追加**到 `docs/ui-components.md`（只追加行，不重排、不删历史）；
3. 整个变更目录移入 `openspec/changes/archive/YYYY-MM-DD-<change>/`；
4. 写 `finalize.md` 收尾回执。

多个变更一起收：`/opsx:bulk-archive`。只想同步规范不归档：`/opsx:sync`。

---

## 三、命令参考

| 命令 | Qoder | OpenCode | 用途 |
|------|:----:|:--------:|------|
| `/opsx:new <name>` | ✅ | ✅ | 契约初始化（proposal + design + ui_contract） |
| `/opsx:continue` | ✅ | 用 CLI | 生成下一个工件 |
| `/opsx:ff` | ✅ | 用 CLI | 一次补齐全部工件 |
| `/opsx:propose` | ✅ | 用 CLI | 一步生成完整提案 |
| `/opsx:explore` | ✅ | — | 只讨论，不落文件 |
| `/opsx:apply` | ✅ | ✅ | 两阶段实现 |
| `/opsx:verify` | ✅ | ✅ | 四道门禁 |
| `/opsx:sync` | ✅ | 用 CLI | 仅同步 delta specs |
| `/opsx:archive` | ✅ | 用 CLI | 归档 + 注册表增量 |
| `/opsx:bulk-archive` | ✅ | 用 CLI | 批量归档 |

- **Qoder**：`openspec init --tools qoder` 已生成 10 个命令，onePress 只加技能与一行引用。
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

卸载：删除 `onePress.lock` 中 `protectedAssets` 之外的安装产物（`.opencode/`、`.qoder/skills/onepress-discipline/`、`openspec/schemas/superspec/`），保留 `docs/ui-components.md` 与 `openspec/changes/`。

---

## 六、模板包结构

```text
onePress/
├── README-ch.md            # 中文说明（默认）
├── README.md               # English README
├── VERSION                 # 版本号（升级判定基准）
├── ASSETS.md               # 资产清单（归属层级 + 覆盖策略）
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
├── openspec-schema/superspec/   # 分发给目标仓库的 schema（10 文件）
└── openspec/               # 本方案自身的规范工作区（不安装）
    ├── config.yaml         # schema: superspec
    ├── CHANGE_NAMING.md    # 变更命名规范
    ├── schemas/superspec/  # 与 openspec-schema/ 内容一致
    ├── specs/              # 4 份主规范（18 requirements）
    └── changes/archive/    # 已归档变更（完整证据链）
```

> 包内 `openspec/` 是**本方案自己的**规范与历史，不写入目标仓库；要安装到目标仓库的 schema 在 `openspec-schema/`。
> 因此在本仓库内跑 OpenSpec 命令要在 `onePress/` 目录下执行（那里有 `openspec/config.yaml`）。

---

## 七、FAQ

**Q：AI 说克隆下来找不到 `INSTALL_PROMPT.md`？**
A：多半是稀疏检出路径与实际布局不符（cone 模式对不存在的路径静默空检出、不报错）。让它先 `git ls-tree -r --name-only HEAD` 核对真实布局，再 `git sparse-checkout disable` 全量检出（包体仅 KB 级）。这条已写进上面的安装提示词，正常情况下它会自己兜住。

**Q：目标仓库没有 OpenSpec？**
A：安装能完成，但 `/opsx:*` 与 `ui_contract` 解析需要 OpenSpec。先 `openspec init --tools qoder`（或 `--tools opencode`）再安装。

**Q：OpenCode 下没有 `/opsx:continue`、`/opsx:archive`？**
A：本包只随附三个命令。其余用 `openspec status` / `openspec instructions` / `openspec archive` 等价操作，或自行补 `.opencode/commands/opsx-*.md`。

**Q：能不能只装 Qoder 或只装 OpenCode？**
A：能，且默认就是这样。安装器按目录探测判定：只有 `.qoder/` 只装 Qoder，只有 `.opencode/` 只装 OpenCode，两者都没有会先问你。也可以在提示词里直接写明"只装 Qoder"覆盖探测。事后想补装另一个环境，再跑一次安装即可，只会增量写那一套，已装的不受影响。

**Q：`.qoder/`、`.opencode/` 要不要入库？**
A：默认不入库（本地环境配置）。`onePress.lock` 与 `docs/ui-components.md` 建议入库。

**Q：怎么确认装好了？**
A：看脚本退出码与报告——`0` 且收尾语为 `onePress v<version> 安装完成（harnesses: <范围>）` 即成功，报告里已列出跳过项与自检结果。想自己复核只查三处——`onePress.lock` 存在且 `version` 匹配；`.qoder/commands/` 每个命令都有一行 `onepress-discipline` 引用；`openspec/schemas/superspec/` 有 10 个文件。

**Q：重装会不会把我改过的工具链文件冲掉？**
A：不会。已跟踪文件若有未提交修改，脚本会提示并跳过该文件；`.qoder/commands/` 里的技能引用已存在则跳过，命令正文永不改写。

**Q：已有 `.qoder/` 会被破坏吗？**
A：不会。只新增技能文件，并在既有命令 frontmatter 后插入一行引用，命令体零改动。

---

## License

MIT
