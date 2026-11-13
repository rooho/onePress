# onePress 安装提示词（INSTALL_PROMPT.md）

> 本文件是 onePress 的 AI 侧安装入口。**首选 `install.ps1` / `install.sh`（一条命令完成同样的五段）；在没有脚本执行能力时，才把本文件完整内容交给任意具备文件读写能力的大模型**，它会按以下五段执行安装。**执行者只需通用文件读写能力，无需 Node.js、Python 或任何运行时。**

## ⓿ 最快路径（MUST 优先尝试）

当前环境能执行命令时，**不要**逐文件手工复制，直接运行模板包自带的安装器：

```powershell
# Windows
<pack-root>\install.ps1 -Target <target-repo-root> -Harness <qoder|opencode|trae|cursor|both|all|逗号组合>
```
```bash
# macOS / Linux
<pack-root>/install.sh --target <target-repo-root> --harness <qoder|opencode|trae|cursor|both|all|逗号组合>
```

它会在数秒内完成 ①~⑤ 的全部工作（探测 / 写入 / config 对齐 / 命令初始化 / 挂载 / lock / 自检），退出码 `0` 即成功。把它的报告原样转述给用户即可，不要重复校验。

**只有**脚本无法执行（无 shell、无执行权限、环境禁止运行命令）时，才继续按下面 ①~⑤ 手工安装，且手工产出必须与脚本逐字节一致。

## ① 前置检查

1. 确认当前目录为目标仓库根（存在 `.git/` 或已初始化 git）。

2. **判定目标 harness（决定安装范围，必须先做，禁止跳过）**：

   | 探测结果 | 安装范围 `HARNESS_SET` |
   |----------|------------------------|
   | 仅 `.qoder/` 存在 | `{qoder}` |
   | 仅 `.opencode/` 存在 | `{opencode}` |
   | 仅 `.trae/` 存在 | `{trae}` |
   | 仅 `.cursor/` 存在 | `{cursor}` |
   | 多个目录存在 | 对应多个 harness 的集合 |
   | 一个都不存在 | **询问用户**"本仓库使用哪个 AI 编码环境？Qoder / OpenCode / Trae / Cursor / 全部"，按回答确定，**禁止默认全装** |

   - **自身环境佐证**：你在 Qoder 中运行 → 倾向 Qoder；在 OpenCode 中运行 → 倾向 OpenCode；在 Trae 中运行 → 倾向 Trae；在 Cursor 中运行 → 倾向 Cursor。佐证与目录探测冲突时，以用户确认为准。
   - 判定结论 MUST 在报告首行写明，后续 ②③④ 全部以 `HARNESS_SET` 为准。
   - **未选中的 harness：不得创建其目录、不得写入任何文件、不得挂载引用。**

3. 探测现状并记录：
   - `.qoder/` 是否存在；若存在，其 `commands/` 与 `skills/` 下有哪些文件。
   - `.opencode/` 是否存在；若存在，其 `commands/`、`agent/`、`skills/` 下有哪些文件。
   - `.trae/` 是否存在；若存在，其 `commands/` 与 `skills/` 下有哪些文件。
   - `.cursor/` 是否存在；若存在，其 `commands/` 与 `skills/` 下有哪些文件。
   - `onePress.lock` 是否存在且可解析（JSON）；存在且版本小于本包 `VERSION` 则本次为**升级**，缺失/损坏则按**全新安装**处理。
   - `docs/ui-components.md` 是否已存在（决定 Protect Local 行为）。
4. 记录安装前的 `git status --porcelain`，识别哪些 harness 文件存在**未提交的本地修改**。

## ② 分层安装

**红线（违反任一条立即中止安装并报告）：**

1. 禁止覆盖项目级资产：`docs/ui-components.md`、`openspec/changes/` 及其下任何文件。
2. 禁止修改目标仓库的业务代码与既有业务文档（仅允许写入 `HARNESS_SET` 内的 `.qoder/`、`.opencode/`、`.trae/`、`.cursor/`、`openspec/schemas/`、`onePress.lock`、`docs/ui-components.md`（首装初始化））。
3. 禁止删除用户本地文件（升级时仅允许删除将被全量覆盖的 harness 目录内的旧文件）。

**逐字写入约束：模板包内所有文件必须逐字写入目标路径，禁止改写、精简或重排内容；无法逐字写入时中止并报告。**

### Harness 级（全量覆盖）

**通用（与 IDE 无关，始终安装）**

| 模板源路径 | 目标路径 |
|-----------|---------|
| `openspec-schema/superspec/**`（11 文件） | `openspec/schemas/superspec/`（schema.yaml + templates/ 10 文件，含 `ui-spec.md`） |

**仅 OpenCode（`HARNESS_SET` 含 `opencode` 时）**

| 模板源路径 | 目标路径 |
|-----------|---------|
| `opencode/opencode.json` | `.opencode/opencode.json` |
| `opencode/agent/ux-architect.md` | `.opencode/agent/ux-architect.md` |
| `opencode/commands/opsx-new.md` | `.opencode/commands/opsx-new.md` |
| `opencode/commands/opsx-apply.md` | `.opencode/commands/opsx-apply.md` |
| `opencode/commands/opsx-verify.md` | `.opencode/commands/opsx-verify.md` |
| `opencode/skills/superpowers-tdd/SKILL.md` | `.opencode/skills/superpowers-tdd/SKILL.md` |

**仅 Qoder（`HARNESS_SET` 含 `qoder` 时）**

| 模板源路径 | 目标路径 |
|-----------|---------|
| `qoder/skills/onepress-discipline/SKILL.md` | `.qoder/skills/onepress-discipline/SKILL.md` |

**仅 Trae（`HARNESS_SET` 含 `trae` 时）**

| 模板源路径 | 目标路径 |
|-----------|---------|
| `trae/skills/onepress-discipline/SKILL.md` | `.trae/skills/onepress-discipline/SKILL.md` |

**仅 Cursor（`HARNESS_SET` 含 `cursor` 时）**

| 模板源路径 | 目标路径 |
|-----------|---------|
| `cursor/skills/onepress-discipline/SKILL.md` | `.cursor/skills/onepress-discipline/SKILL.md` |

写入顺序：先创建目录，再逐文件写入。未选中的 harness 目录**保持不存在或原样不动**。

### Qoder / Trae / Cursor 命令技能挂载（仅当 `HARNESS_SET` 含 `qoder`、`trae` 或 `cursor`）

对目标仓库 `.qoder/commands/`、`.trae/commands/` 或 `.cursor/commands/` 下每个已存在的命令文件（含子目录），在 YAML frontmatter 之后插入一行（若该行已存在则跳过）：

```
> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。
```

约束：**仅允许新增这一行**，命令正文其余内容一字不得改动；命令文件不存在时跳过，**不得新建**命令文件。

### OpenSpec 配置对齐（始终执行）

- 目标仓库存在 `openspec/config.yaml` 时，其顶层 `schema:` MUST 为 `superspec`（九工件序列 brainstorm→…→finalize 依赖它）。当前值不是 `superspec` 时，**只改这一行**，`context` / `rules` 等其余字段一字不动，并在报告中记一行 `config.yaml schema: <旧值> → superspec`。**改行时保留原换行风格**：CRLF 文件的该行末尾有 `\r`，不要一并删掉。
- `openspec/config.yaml` 不存在时**必须创建**，最小内容为 `schema: superspec` + `context.rules`（specs / design / tasks 三组；design 组要求 UI 变更在 `proposal.md` 首行给出 `**UI Change**: yes|no`，`yes` 时产出 `ui-spec.md` 与 `sandbox-preview.html`）。缺了它，本次安装提供不了九工件能力。
- **实测结论**：`openspec init` 在 `config.yaml` 已存在时**不会覆盖**（hash 不变），只有当文件缺失时才会新建为 `spec-driven`。因此正确顺序是：**先创建/对齐 config → 再 init → 再挂载技能引用**。

### 命令初始化（仅当 `HARNESS_SET` 含 `qoder`、`trae` 或 `cursor`，且对应 `commands/` 为空或不完整）

- **不完整的判定（Trae / Cursor）**：`commands/` 中存在 `.md` 文件，但缺少 OpenSpec 标准命令（如 `opsx-continue.md`、`opsx-propose.md`、`opsx-archive.md`）；只有 `opsx-new.md` / `opsx-apply.md` / `opsx-verify.md` 三个文件即属此类（旧版 onePress 随包直出的命令）。
- 判定为不完整时：先删除旧版随包命令 `commands/opsx-new.md`、`opsx-apply.md`、`opsx-verify.md`（存在未提交修改的跳过并记录），再执行 `openspec init --tools qoder|trae|cursor --no-animation` 生成完整命令集（当前 OpenSpec 1.13 为 12 个），**然后才做技能引用挂载**。漏掉这一步的结果是"技能已落盘但永不加载"，`/opsx:*` 全部不可用。
- `.qoder/commands/` 的命令位于 `commands/opsx/` 子目录，不适用上述扁平文件名判定；其非空即视为完整。
- `openspec` 命令不可用时：在报告中明确写"技能存在但无挂载点，需先安装 OpenSpec CLI 并 init"，不得当作安装成功。
- 已有完整命令集时**不重复 init**。

### 文档与自托管条目（不安装）

- `install.ps1`、`install.sh` 属 installer 层，是首选安装入口（一条命令完成探测 / 写入 / 自检 / 报告）；本文件是它的等价 AI 兜底，两者产出必须逐字节一致。
- `ASSETS.md`、`README-ch.md`、`README.md` 属 `docs` 层，**不写入目标仓库**。
- `openspec/` 属自托管层（本方案自身的 config、规范、变更归档），**不写入目标仓库**；要注入目标仓库的 schema 取自 `openspec-schema/`。

### 项目级（Protect Local）

- `docs/ui-components.md`：**已存在则跳过**（输出 `skipped (exists)`）；不存在则以下列逐字模板初始化。若已存在但表头不含「适用骨架」，输出一条迁移 `WARN` 并附目标表头，**不得改写文件**。

````markdown
# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/opsx:archive` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/opsx:new` 起草 `ui-spec.md` 前 MUST 先检索本表，可复用的组件写入第 1 节复用表，不得重复造轮子。
2. 新增组件必须补齐：组件名称、路径、适用骨架 (Archetype)、核心 Props 签名。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. `适用骨架` 列取值：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`；通用组件填 `通用`。
5. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|

## 业务组件（domain）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|
````
- `docs/design-system/projectbaseline/MASTER.md`：**已存在则跳过**（输出 `skipped (exists)`）；本文件由 `ui-ux-pro-max` 在项目初始化时一次性生成，安装器 MUST NOT 创建或改写它。
- `openspec/changes/`：**永不触碰**。

### 本地未提交修改保护

写入任一 harness 级文件前，若该文件在 `git status --porcelain` 中命中未提交修改，则**提示用户并跳过该文件**，继续安装其余文件；所有此类跳过项 MUST 在最终报告中列出。

### 可选增强层探测（不安装，只探测）

设计检索能力 `ui-ux-pro-max` 属于**可选增强层**。本次安装 MUST NOT 尝试安装它，MUST NOT 调用 `npm install` / `uipro init`，MUST NOT 发起任何网络请求。

1. 判定条件（两者同时满足才视为可用）：
   - `python3` 可执行（以 `command -v python3` 判定）；
   - `HARNESS_SET` 中任一 harness 存在 `.<harness>/skills/ui-ux-pro-max/scripts/search.py`。
2. 在报告第⑤段输出**且仅输出一行**结论：
   - 可用：`ui-ux-pro-max：enabled（python3 与技能目录均就绪）`
   - 不可用：`ui-ux-pro-max：SKIP（<未检测到 python3 | 未检测到技能目录>；检索步骤降级为手工填写 ui-spec.md）`
3. `SKIP` MUST NOT 视为安装失败，MUST NOT 重试、MUST NOT 因此向用户索要额外权限。
4. 输出 `SKIP` 时，紧随其后给出启用指引（按 `HARNESS_SET` 逐个 harness 展开，**只打印，不落盘**）：

```text
启用设计检索（可选，需 Node.js + Python3）：
  npm install -g ui-ux-pro-max-cli
  uipro init --ai <harness> --offline    # 只保留 .<harness>/skills/ui-ux-pro-max 目录，其余 6 个伴生技能可删
```

## ③ 幂等与升级

### onePress.lock 结构（写入仓库根）

```json
{
  "version": "1.0.0",
  "installedAt": "2026-11-03T00:00:00Z",
  "harnesses": {
    "qoder": true,
    "opencode": false,
    "trae": false,
    "cursor": false
  },
  "protectedAssets": [
    "docs/ui-components.md",
    "openspec/changes/"
  ]
}
```

`harnesses` 按**实际安装范围**填写：本次装哪个写 `true`，未装写 `false`（上例为仅 Qoder 环境）。

### 安装范围与增量

- 本次 `HARNESS_SET` 之外的 harness，其 `harnesses` 值保持原状（首次为 `false`），**不得因为对方目录存在就顺手安装**。
- 若某 harness 在 lock 中为 `false`、而本次探测到它确有目录且用户确认要装，则视为**该 harness 的首次安装**：只写它的文件并把它置 `true`，不动另一个已装的 harness。
- 升级时**仅全量覆盖 lock 中为 `true` 的 harness**；为 `false` 的 harness 目录不读、不写、不删。

### 三档升级策略

1. **Harness 核心全量覆盖（仅限已启用的 harness）**：升级时先删除**该 harness** 目录中由 onePress 管理的旧文件，再按第②段逐字写入，杜绝旧版本残留；未启用的 harness 目录不读不写。删除范围：
   - OpenCode：`commands/`、`skills/`、`opencode.json`
   - Trae：`skills/onepress-discipline/`、lock 中记录的命令文件，以及旧版随包直出的 `commands/opsx-new.md`、`opsx-apply.md`、`opsx-verify.md`（**lock 未记录也要删**，否则会阻塞 `openspec init` 而只剩 3 个命令）
   - Cursor：`skills/onepress-discipline/`
   - 通用：`openspec/schemas/superspec/`
2. **项目级 Protect Local**：存在即跳过，仅首装初始化。
3. **本地修改保护**：未提交修改默认跳过并提示。

### lock 缺失 / 损坏降级

`onePress.lock` 缺失、无法解析或 `version` 非法时：按**全新安装**处理，但项目级资产仍执行 Protect Local；最终写入新 lock 并报告"lock 已重建"。

## ④ 验收自检

安装完成后逐项执行，任一失败即判定安装失败并输出失败项。
**只验收 `HARNESS_SET` 内的 harness**；未安装的 harness 整组记为 `skipped (not installed)`，不计入失败。

### .opencode 验收项（仅当 `HARNESS_SET` 含 `opencode`）

- [ ] `.opencode/opencode.json` 存在且为合法 JSON
- [ ] `.opencode/commands/` 下存在 `opsx-new.md`、`opsx-apply.md`、`opsx-verify.md` 三个文件（复数目录 `commands/`）
- [ ] `.opencode/agent/ux-architect.md` frontmatter 含 `mode` 字段
- [ ] `.opencode/skills/superpowers-tdd/SKILL.md` frontmatter `name: superpowers-tdd` 与目录名一致，`description` 长度 1–1024 字符
- [ ] `.opencode/skills/superpowers-tdd/SKILL.md` 内容与模板包逐字一致

### .qoder / .cursor 验收项（仅当 `HARNESS_SET` 含 `qoder` 或 `cursor`）

- [ ] 对应目录（`.qoder/` 或 `.cursor/`）下 `skills/onepress-discipline/SKILL.md` 存在
- [ ] 该 SKILL.md 包含九条铁律标题（ui-spec 契约先行 / 需求分流 / 设计检索与降级 / 高保真沙箱与两阶段 / 八项门禁 / Token 纯净度 / 四态状态机 / 无障碍基线 / 防呆与反馈闭环）
- [ ] 该 SKILL.md 包含 `ui-spec.md`、`sandbox-preview`、`ui_change`、`44×44`、`prefers-reduced-motion` 五个关键词
- [ ] 该 SKILL.md 内容与模板包逐字一致
- [ ] 既有 `commands/` 下命令文件主体未被改写（仅允许 frontmatter 后新增一行技能引用）
- [ ] `commands/` **非空**，且其中每个命令文件均含一行 `onepress-discipline` 技能引用（为空即判定失败：技能存在但无挂载点）
- [ ] 项目级资产未被覆盖：`docs/ui-components.md`（若安装前已存在）内容不变

### .trae 验收项（仅当 `HARNESS_SET` 含 `trae`）

- [ ] `.trae/skills/onepress-discipline/SKILL.md` 存在，包含九条铁律与 `ui-spec.md` / `sandbox-preview` / `ui_change` / `44×44` / `prefers-reduced-motion` 关键词，且与模板包逐字一致
- [ ] `.trae/commands/` **非空**（完整命令集通常 12 个），且其中每个命令文件均含一行 `onepress-discipline` 技能引用（为空即判定失败：技能存在但无挂载点）
- [ ] 既有 `commands/` 下命令文件主体未被改写（仅允许 frontmatter 后新增一行技能引用）
- [ ] 项目级资产未被覆盖：`docs/ui-components.md`（若安装前已存在）内容不变

### OpenSpec Schema 验收项

- [ ] `openspec/schemas/superspec/schema.yaml` 与 `templates/` 10 个模板文件齐全（共 11 文件，含 `ui-spec.md`）
- [ ] `openspec schemas` 可列出 `superspec (project)`
- [ ] `openspec/config.yaml` 存在且顶层 `schema:` 为 `superspec`（缺失或值不符即判定失败）
- [ ] `openspec/schemas/superspec/schema.yaml` 中每一处 `superpowers:<skill>` 引用都配有 `FALLBACK` 兜底说明（brainstorm / plan / apply / finalize 四处齐全），缺一处即判定失败——否则目标仓库没装 Superpowers 插件时，`/opsx:continue` 会停在 plan 步骤

### 可选增强层验收项

- [ ] 报告含**且仅含一行** `ui-ux-pro-max：enabled` 或 `ui-ux-pro-max：SKIP（<原因>）`
- [ ] `SKIP` 时附有启用指引，且安装结论仍为成功（不计入失败项）
- [ ] 本次安装未执行任何 `npm install` / `uipro init` / 网络请求
- [ ] `docs/design-system/projectbaseline/MASTER.md` 若已存在，内容逐字节不变

### 安装范围验收项

- [ ] `onePress.lock` 的 `harnesses` 与本次 `HARNESS_SET` 完全一致（未安装的 harness 为 `false`）
- [ ] 未安装的 harness：其目录不存在，或原有文件内容未被本次安装改动

### 模板包结构验收项

- [ ] 模板包根条目均在白名单内：`VERSION`、`ASSETS.md`、`INSTALL_PROMPT.md`、`install.ps1`、`install.sh`、`README-ch.md`、`README.md`、`blueprint/`、`opencode/`、`qoder/`、`trae/`、`cursor/`、`openspec-schema/`、`scripts/`、`openspec/`；出现白名单外条目即判定失败并输出违规路径

## ⑤ 收尾

1. 按第③段结构写入 `onePress.lock`（`installedAt` 用当前 ISO 时间；`harnesses` 按实际安装范围填写）。
2. 输出安装报告，**首行写明安装范围**（`HARNESS_SET`，例如 `harnesses: qoder`），随后给出：安装类型（全新/升级/单 harness 增量/lock 重建）、逐文件写入结果、跳过项清单（本地修改 / 已存在 / 未安装 harness）、验收自检结果。
3. 报告结束语：`onePress v<version> 安装完成（harnesses: <范围>）`。
