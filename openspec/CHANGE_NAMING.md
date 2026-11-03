# 变更命名规范（草案 v0.1）

> 状态：**DRAFT** — 第 12 节 3 个开放点待裁决后冻结为 v1.0，并写入 `openspec/config.yaml` 与 `/opsx:new` 生成逻辑。

## 1. 适用范围

`openspec/changes/` 下**所有变更目录名**；同一标识同时用于 commit message、看板与沟通口径。

## 2. 格式

```text
{type}-{YYMMDD}-{NNN}-{slug}

展示层（文档 / commit / 沟通）：  FEAT-261103-001-onepress-scheme-install
工具层（目录名，强制全小写）：    feat-261103-001-onepress-scheme-install
```

| 段 | 含义 | 示例 |
|----|------|------|
| `{type}` | 变更类型，见第 3 节 | `feat` |
| `{YYMMDD}` | 创建日期，6 位 | `261103` |
| `{NNN}` | 三位自增序号，001 起 | `001` |
| `{slug}` | ≤10 个单词的特性简述 | `onepress-scheme-install` |

**已核实的硬约束**（OpenSpec `validateChangeName` 源码）：

- 目录名必须**全小写**，大写会报 `Change name must be lowercase (use kebab-case)`；
- 只允许 `[a-z0-9-]`，禁止空格、下划线、连续连字符、首尾连字符；
- 整体长度 ≤ 200 字符（本规范自加可读性上限 60）。

> 因此 `FEAT-261103-001-...` 不能直接做目录名，只能作为展示名。这是规范允许"大写 TYPE"的唯一位置。

## 3. 类型枚举

| type（目录名） | 展示 | 适用场景 | 示例 slug |
|---------------|------|---------|-----------|
| `feat` | FEAT | 新功能、新能力、新增 harness 资产/命令/技能 | `onepress-scheme-install` |
| `fixbug` | FIXBUG | 缺陷修复：行为与预期不符 | `install-lock-corrupt-fallback` |
| `refactor` | REFACTOR | 不改变外部行为的结构调整 | `split-install-prompt-sections` |
| `perf` | PERF | 性能优化（构建时长、安装耗时） | `parallel-asset-copy` |
| `docs` | DOCS | 纯文档；不影响规范/契约时**不必**走 change 流程 | `readme-github-install-guide` |
| `chore` | CHORE | 构建、依赖、配置、目录清理 | `drop-legacy-diggerwasp-files` |
| `test` | TEST | 测试补强；不改变实现时可不走 change | `e2e-idempotent-reinstall` |
| `revert` | REVERT | 回滚已归档变更 | `revert-onepress-scheme-install` |

**规则**：一个 change 只允许一个类型，跨类型必须拆分（如"修 bug + 顺手加功能"→ 两个 change）。

## 4. 日期 `YYMMDD`

- 取 change **创建当天**本地日期，零填充 6 位；
- 必须是真实存在的日期（`261332` 非法）；
- 禁止未来日期；补记历史变更最多回溯 7 天，超出需在 proposal 里说明；
- 与 UTC 存在 ±1 日时区误差时以本地日期为准。

## 5. 序号 `NNN`

- 3 位零填充，`001`–`999`；
- **作用域（推荐 A，待裁决）**：
  - **A. 同日期全局自增（推荐）**：同一天内所有类型共享序列 → `feat-261103-001-…`、`fixbug-261103-002-…`
  - B. 同日期 + 同类型自增：各类型独立 → `feat-261103-001-…`、`fixbug-261103-001-…`
- 同日超过 999 → 拒绝创建，提示拆分或人工介入；
- **计算算法**：扫描 `openspec/changes/` 与 `openspec/changes/archive/`（归档目录带 `YYYY-MM-DD-` 前缀，需先剥离），取匹配 `-{YYMMDD}-(\d{3})-` 的最大序号 + 1；无匹配则从 `001` 开始。

## 6. `slug` 规则

- **1–10 个英文单词**，推荐 3–6；
- 字符集 `[a-z0-9]`，单词间单个 `-`；禁止下划线、空格、连续连字符、中文与拼音缩写混写；
- 描述**特性/主题**而非动作流水：`user-role-permission` ✅ / `fix-bug-1` ❌；
- 不与类型词重复（`feat-add-feature-…` ❌）；
- 不携带 issue key（issue key 写在 proposal 正文）；
- 整个目录名 ≤ 60 字符。

## 7. 校验

**结构正则**：

```regex
^(feat|fixbug|refactor|perf|docs|chore|test|revert)-[0-9]{6}-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+){0,9}$
```

**语义检查**（正则无法覆盖，需人工或脚本）：

| 检查项 | 判定 |
|--------|------|
| 日期真实且不晚于今天 | 拒绝 |
| 同日序号是否已被占用 | 拒绝并提示下一个可用号 |
| slug 单词数 ≤10 | 由正则 `{0,9}` 保证 |
| 目录名长度 ≤60 | 拒绝 |
| 类型唯一 | 拒绝混合类型 |

**一行自检**（PowerShell，仓库根执行）：

```powershell
Get-ChildItem openspec\changes -Directory | Where-Object Name -ne 'archive' |
  Where-Object { $_.Name -cnotmatch '^(feat|fixbug|refactor|perf|docs|chore|test|revert)-[0-9]{6}-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+){0,9}$' } |
  ForEach-Object { "FAIL: $($_.Name)" }
```

## 8. 正反例

| 判定 | 名称 | 原因 |
|------|------|------|
| ✅ | `feat-261103-001-onepress-scheme-install` | 标准格式 |
| ✅ | `fixbug-261103-002-install-lock-corrupt-fallback` | 同日全局序号 002 |
| ✅ | `refactor-261104-001-split-install-prompt` | 隔日重置为 001 |
| ❌ | `FEAT-261103-001-onepress-scheme-install` | 大写，工具拒绝 |
| ❌ | `req-261103-001-onepress-scheme-install` | 旧前缀 `req`，不在枚举内 |
| ❌ | `feat-20261103-001-onepress` | 日期必须 6 位 |
| ❌ | `feat-261103-1-onepress` | 序号必须 3 位 |
| ❌ | `feat-261103-001-onepress_scheme_install` | 下划线 |
| ❌ | `feat-261103-001-implement-the-new-installation-scheme-for-onepress-template-deployment-pack-now` | slug 11 词，超 10 |
| ❌ | `feat-261103-001-fix-bug-and-add-feature` | 多主题混合 |

## 9. 生命周期

1. **创建时生成并锁定**：由 `/opsx:new` 自动推导，人工只做复核；
2. 变更生效后**不得重命名**（重命名视同新建 change，工件历史割裂）；
3. **archive 时由工具加日期前缀** `YYYY-MM-DD-{原名}`，原名主体保持不变；
4. 名称一旦进入 `archive/`，永久只读。

## 10. 落点与工具

| 落点 | 动作 |
|------|------|
| `openspec/config.yaml` | `context.rules` 新增 `naming:` 段，AI 起草 change 前必读 |
| `.qoder/commands/opsx/new.md` | 新增"命名生成"步骤：读规范 → 取日期 → 扫描序号 → 组 slug → 自检正则 |
| `onePress/opencode/commands/opsx-new.md` | 同步同一生成步骤（harness 级资产，随版本全量覆盖） |
| `onePress/INSTALL_PROMPT.md` | 验收自检追加"变更命名正则校验"1 项 |
| 门禁（可选） | 仓库脚本 + verify 阶段调用，失败即阻断归档 |

**`/opsx:new` 命名生成四步**：

```text
1) type   ← 用户意图判定（新能力=feat / 行为不符=fixbug / 结构=refactor …），歧义时反问一次
2) date   ← 当天本地日期 YYMMDD
3) seq    ← 扫 changes/ + archive/ 同日最大序号 +1，零填充三位
4) slug   ← 从需求描述提炼 ≤10 个英文单词，kebab-case，去停用词
→ 输出展示名与目录名两个版本，人工确认后 create
```

## 11. 存量迁移

| 现存 | 迁移后 | 说明 |
|------|--------|------|
| `req-261103-001-onepress-scheme-install` | `feat-261103-001-onepress-scheme-install` | `git mv` 改名，工件内容零改动 |
| `archive/` 下历史变更 | 不迁移 | 历史只读，保留原貌 |

## 12. 待裁决（冻结前需你确认）

1. **序号作用域**：A 同日期全局自增（推荐） / B 同日期 + 同类型自增
2. **类型枚举范围**：8 类全量 / 精简为 `feat` `fixbug` `refactor` `chore` 4 类
3. **存量迁移**：`req-261103-001-…` 是否立即改为 `feat-261103-001-…`（当前 change 尚未归档，改名成本低）
