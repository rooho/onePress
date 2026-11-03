# onepress-idempotent-install Specification

## Purpose
TBD - created by archiving change req-261103-001-onepress-scheme-install. Update Purpose after archive.

## Requirements

### Requirement: 安装状态清单 onePress.lock

安装器 MUST 在每次安装或升级完成后写入 `onePress.lock`，至少包含 `version`、`installedAt`、`harnesses`（`qoder` / `opencode` 的启用状态）与 `protectedAssets`（受保护的项目级资产路径清单）四个字段。

#### Scenario: 首次安装写入 lock

- **GIVEN** 目标仓库尚无 `onePress.lock`
- **WHEN** 完成一次安装
- **THEN** 仓库根出现 `onePress.lock`，且四个字段均有值

#### Scenario: 升级更新 lock 版本

- **GIVEN** 目标仓库已有 `onePress.lock` 且 `version` 为 `0.1.0`
- **WHEN** 使用 `0.2.0` 版本模板包执行升级
- **THEN** `onePress.lock` 的 `version` 更新为 `0.2.0`，`installedAt` 刷新

---

### Requirement: harness 核心资产全量覆盖

harness 级资产（`commands/`、`skills/`、门禁脚本、`openspec/schemas/superspec/`）MUST 在升级时按模板包版本全量覆盖，不得保留旧版本残留文件。

#### Scenario: 升级后无旧文件残留

- **GIVEN** 目标仓库已安装旧版 `onepress-discipline` 技能，其中包含旧版辅助文件
- **WHEN** 执行升级到新版模板包
- **THEN** 该技能目录内容与新版模板完全一致，旧版独有文件已被移除

---

### Requirement: 项目级资产存在即跳过

安装器对项目级资产（`docs/ui-components.md`、`openspec/changes/`）MUST 采用 Protect Local 策略：文件已存在时跳过写入，仅在不存在时初始化。

#### Scenario: 已存在的组件注册表被保留

- **GIVEN** 目标仓库存在含本地记录的 `docs/ui-components.md`
- **WHEN** 执行安装或升级
- **THEN** 安装日志标记该文件为 `skipped (exists)` 且内容未改变

#### Scenario: 不存在的组件注册表被初始化

- **GIVEN** 目标仓库不存在 `docs/ui-components.md`
- **WHEN** 执行安装
- **THEN** 该文件被创建为注册表模板（表头 + 使用说明，无业务内容）

---

### Requirement: 本地未提交修改保护

安装器在覆盖任一 harness 级文件前 MUST 检查该文件是否存在未提交的本地修改；存在时 MUST 提示用户并在未获确认时跳过该文件。

#### Scenario: 本地修改触发提示并跳过

- **GIVEN** `.qoder/skills/onepress-discipline/SKILL.md` 存在未提交的本地修改
- **WHEN** 执行升级
- **THEN** 安装器输出该文件被本地修改的提示，且默认跳过覆盖

---

### Requirement: lock 缺失或损坏的降级处理

当 `onePress.lock` 缺失、无法解析或版本字段非法时，安装器 MUST 按全新安装处理，同时 MUST 仍对项目级资产执行 Protect Local。

#### Scenario: 损坏 lock 不导致项目资产被覆盖

- **GIVEN** `onePress.lock` 内容为非法 JSON 且目标仓库存在 `docs/ui-components.md`
- **WHEN** 执行安装
- **THEN** 安装器报告 lock 损坏并按全新安装处理，且 `docs/ui-components.md` 内容保持不变
