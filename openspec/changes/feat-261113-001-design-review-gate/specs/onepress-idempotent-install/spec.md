# onepress-idempotent-install Delta

## MODIFIED Requirements

### Requirement: 安装状态清单 onePress.lock

安装器 MUST 在每次安装或升级完成后写入 `onePress.lock`，至少包含 `version`、`installedAt`、`harnesses`（`qoder` / `opencode` / `trae` / `cursor` 四者的启用状态）、`protectedAssets`（受保护的项目级资产路径清单）与 `files`（本次受管文件清单）四个字段。`files` MUST 记录四份 onePress 托管 `opsx-review` 命令、`review-rubric.md` 与两份 tooling 脚本，供后续升级清理与回滚使用。

#### Scenario: 首次安装写入 lock

- **GIVEN** 目标仓库尚无 `onePress.lock`
- **WHEN** 完成一次安装
- **THEN** 仓库根出现 `onePress.lock`，且四个字段均有值，`harnesses` 含四个布尔键

#### Scenario: 托管命令被记录

- **GIVEN** 一次以 `qoder,trae` 为范围的安装
- **WHEN** 读取 `onePress.lock` 的 `files`
- **THEN** 包含 `.qoder/commands/opsx/review.md`、`.trae/commands/opsx-review.md`、`openspec/schemas/superspec/templates/review-rubric.md`、`scripts/onepress-gate.sh` 与 `scripts/sandbox-preflight.spec.ts`

#### Scenario: 升级更新 lock 版本

- **GIVEN** 目标仓库已有 `onePress.lock` 且 `version` 为 `1.0.7`
- **WHEN** 使用 `1.1.0` 版本模板包执行升级
- **THEN** `onePress.lock` 的 `version` 更新为 `1.1.0`，`installedAt` 刷新，旧版未删除的受管文件按 `files` 清理

---

### Requirement: harness 核心资产全量覆盖

harness 级与 tooling 级资产（`commands/`、`skills/`、`openspec/schemas/superspec/`、`scripts/onepress-gate.sh`、`scripts/sandbox-preflight.spec.ts`）MUST 在升级时按模板包版本全量覆盖，不得保留旧版本残留文件。升级清理范围 MUST 覆盖旧 lock `files` 中记录、但本次不再写入的 `opsx-review.md` 与 `review-rubric.md`。对用户自建的同名 tooling 文件 MUST 跳过覆盖并报告，MUST NOT 删除。

#### Scenario: 升级后无旧文件残留

- **GIVEN** 目标仓库已安装旧版 `onepress-discipline` 技能，其中包含旧版辅助文件
- **WHEN** 执行升级到新版模板包
- **THEN** 该技能目录内容与新版模板完全一致，旧版独有文件已被移除

#### Scenario: 新增 review 资产随升级落盘

- **GIVEN** 目标仓库已安装 1.0.7，`onePress.lock` 中无 review 相关文件
- **WHEN** 升级到 1.1.0
- **THEN** 四份 `opsx-review` 命令、`review-rubric.md` 与两份 tooling 脚本按本次 harness 范围写入，且 lock `files` 同步更新

#### Scenario: 用户自建 tooling 文件被保留

- **GIVEN** 目标仓库已存在用户自建的 `scripts/onepress-gate.sh` 且不在旧 lock `files` 中
- **WHEN** 执行安装或升级
- **THEN** 安装器输出跳过原因，该文件内容逐字节不变，安装其余文件继续

#### Scenario: 回滚可恢复到旧文件集合

- **GIVEN** 一次 1.0.7 → 1.1.0 升级已完成
- **WHEN** 按 `onePress.lock` 的 `files` 删除 1.1.0 新增文件并恢复 1.0.7 受管文件
- **THEN** 目标仓库不再包含任何 `opsx-review` 命令与 `review-rubric.md`，`/opsx:apply` 不再校验 `Review-Status`
