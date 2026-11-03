# onePress 安装提示词（INSTALL_PROMPT.md）

> 本文件是 onePress 的唯一安装入口。请把**本文件完整内容**交给任意具备文件读写能力的大模型（Qoder / OpenCode / 任意编码 Agent），它会按以下五段执行安装。**执行者只需通用文件读写能力，无需 Node.js、Python 或任何运行时。**

## ① 前置检查

1. 确认当前目录为目标仓库根（存在 `.git/` 或已初始化 git）。
2. 探测现状并记录：
   - `.qoder/` 是否存在；若存在，其 `commands/` 与 `skills/` 下有哪些文件。
   - `.opencode/` 是否存在；若存在，其 `commands/`、`agent/`、`skills/` 下有哪些文件。
   - `onePress.lock` 是否存在且可解析（JSON）；存在且版本小于本包 `VERSION` 则本次为**升级**，缺失/损坏则按**全新安装**处理。
   - `docs/ui-components.md` 是否已存在（决定 Protect Local 行为）。
3. 记录安装前的 `git status --porcelain`，识别哪些 harness 文件存在**未提交的本地修改**。

## ② 分层安装

**红线（违反任一条立即中止安装并报告）：**

1. 禁止覆盖项目级资产：`docs/ui-components.md`、`openspec/changes/` 及其下任何文件。
2. 禁止修改目标仓库的业务代码与既有业务文档（仅允许写入 `.qoder/`、`.opencode/`、`openspec/schemas/`、`onePress.lock`、`docs/ui-components.md`（首装初始化））。
3. 禁止删除用户本地文件（升级时仅允许删除将被全量覆盖的 harness 目录内的旧文件）。

**逐字写入约束：模板包内所有文件必须逐字写入目标路径，禁止改写、精简或重排内容；无法逐字写入时中止并报告。**

### Harness 级（全量覆盖）

| 模板源路径 | 目标路径 |
|-----------|---------|
| `opencode/opencode.json` | `.opencode/opencode.json` |
| `opencode/agent/ux-architect.md` | `.opencode/agent/ux-architect.md` |
| `opencode/commands/opsx-new.md` | `.opencode/commands/opsx-new.md` |
| `opencode/commands/opsx-apply.md` | `.opencode/commands/opsx-apply.md` |
| `opencode/commands/opsx-verify.md` | `.opencode/commands/opsx-verify.md` |
| `opencode/skills/superpowers-tdd/SKILL.md` | `.opencode/skills/superpowers-tdd/SKILL.md` |
| `qoder/skills/onepress-discipline/SKILL.md` | `.qoder/skills/onepress-discipline/SKILL.md` |
| `openspec-schema/superspec/**`（10 文件） | `openspec/schemas/superspec/`（schema.yaml + templates/ 9 文件） |

写入顺序：先创建目录，再逐文件写入。

### Qoder 命令技能挂载（仅 `.qoder/`）

对目标仓库 `.qoder/commands/` 下每个已存在的命令文件（含 `opsx/` 子目录），在 YAML frontmatter 之后插入一行（若该行已存在则跳过）：

```
> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。
```

约束：**仅允许新增这一行**，命令正文其余内容一字不得改动；命令文件不存在时跳过，**不得新建**命令文件。

### 文档条目（不安装）

- `ASSETS.md`、`README-ch.md`、`README.md` 属 `docs` 层，**不写入目标仓库**。

### 项目级（Protect Local）

- `docs/ui-components.md`：**已存在则跳过**（输出 `skipped (exists)`）；不存在则以注册表模板初始化（表头 + 使用说明，无业务内容）。
- `openspec/changes/`：**永不触碰**。

### 本地未提交修改保护

写入任一 harness 级文件前，若该文件在 `git status --porcelain` 中命中未提交修改，则**提示用户并跳过该文件**，继续安装其余文件；所有此类跳过项 MUST 在最终报告中列出。

## ③ 幂等与升级

### onePress.lock 结构（写入仓库根）

```json
{
  "version": "1.0.0",
  "installedAt": "2026-11-03T00:00:00Z",
  "harnesses": {
    "qoder": true,
    "opencode": true
  },
  "protectedAssets": [
    "docs/ui-components.md",
    "openspec/changes/"
  ]
}
```

### 三档升级策略

1. **Harness 核心全量覆盖**：升级时先删除目标 harness 目录中由 onePress 管理的旧文件（`commands/`、`skills/`、`opencode.json`、`openspec/schemas/superspec/`），再按第②段逐字写入，杜绝旧版本残留。
2. **项目级 Protect Local**：存在即跳过，仅首装初始化。
3. **本地修改保护**：未提交修改默认跳过并提示。

### lock 缺失 / 损坏降级

`onePress.lock` 缺失、无法解析或 `version` 非法时：按**全新安装**处理，但项目级资产仍执行 Protect Local；最终写入新 lock 并报告"lock 已重建"。

## ④ 验收自检

安装完成后逐项执行，任一失败即判定安装失败并输出失败项。

### .opencode 验收项（≥5）

- [ ] `.opencode/opencode.json` 存在且为合法 JSON
- [ ] `.opencode/commands/` 下存在 `opsx-new.md`、`opsx-apply.md`、`opsx-verify.md` 三个文件（复数目录 `commands/`）
- [ ] `.opencode/agent/ux-architect.md` frontmatter 含 `mode` 字段
- [ ] `.opencode/skills/superpowers-tdd/SKILL.md` frontmatter `name: superpowers-tdd` 与目录名一致，`description` 长度 1–1024 字符
- [ ] `.opencode/skills/superpowers-tdd/SKILL.md` 内容与模板包逐字一致

### .qoder 验收项（≥5）

- [ ] `.qoder/skills/onepress-discipline/SKILL.md` 存在
- [ ] 该 SKILL.md 包含四条铁律标题（Token 纯净度 / 四态状态机 / 无障碍基线 / 防呆与反馈闭环）
- [ ] 该 SKILL.md 内容与模板包逐字一致
- [ ] 既有 `.qoder/commands/` 下命令文件主体未被改写（仅允许 frontmatter 后新增一行技能引用）
- [ ] `.qoder/commands/` 下每个已存在的命令文件均含一行 `onepress-discipline` 技能引用
- [ ] 项目级资产未被覆盖：`docs/ui-components.md`（若安装前已存在）内容不变

### OpenSpec Schema 验收项

- [ ] `openspec/schemas/superspec/schema.yaml` 与 `templates/` 9 个模板文件齐全（共 10 文件）
- [ ] `openspec schemas` 可列出 `superspec (project)`

### 模板包结构验收项

- [ ] 模板包根条目均在白名单内：`VERSION`、`ASSETS.md`、`INSTALL_PROMPT.md`、`README-ch.md`、`README.md`、`opencode/`、`qoder/`、`openspec-schema/`；出现白名单外条目即判定失败并输出违规路径

## ⑤ 收尾

1. 按第③段结构写入 `onePress.lock`（`installedAt` 用当前 ISO 时间）。
2. 输出安装报告：安装类型（全新/升级/lock 重建）、逐文件写入结果、跳过项清单（本地修改 / 已存在）、验收自检结果。
3. 报告结束语：`onePress v<version> 安装完成`。
