# onepress-template-pack Delta

## MODIFIED Requirements

### Requirement: 模板包固定目录结构

onePress 模板包 MUST 采用固定顶层结构：7 个功能条目 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`trae/`、`cursor/`、`openspec-schema/`，1 个工具条目 `scripts/`，3 个文档条目 `ASSETS.md`、`README-ch.md`、`README.md`，1 个纲领条目 `blueprint/`，以及 1 个自托管条目 `openspec/`（本方案自身的规范工作区）。任何新增 harness 资产 MUST 归入对应子目录，不得散落在包根。模板包 MUST 在既有子目录内承载以下 V3.1 新增资产：`qoder/commands/opsx/review.md`、`trae/commands/opsx-review.md`、`cursor/commands/opsx-review.md`、`opencode/commands/opsx-review.md`、`openspec-schema/superspec/templates/review-rubric.md`、`scripts/sandbox-preflight.spec.ts`；顶层白名单 MUST NOT 因此扩张。

#### Scenario: 包结构完整性校验

- **GIVEN** 一个已构建的 onePress 模板包目录
- **WHEN** 执行结构校验（检查 7 个功能条目、1 个工具条目、3 个文档条目、1 个纲领条目与 1 个自托管条目是否存在）
- **THEN** 校验通过且列出 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`trae/`、`cursor/`、`openspec-schema/`、`scripts/`、`ASSETS.md`、`README-ch.md`、`README.md`、`blueprint/`、`openspec/`

#### Scenario: V3.1 新增资产位于既有子目录

- **GIVEN** 模板包内新增四份 `opsx-review` 命令、`review-rubric.md` 与 `sandbox-preflight.spec.ts`
- **WHEN** 检查其路径
- **THEN** 命令分别位于 `qoder/commands/opsx/`、`trae/commands/`、`cursor/commands/`、`opencode/commands/`，评分表位于 `openspec-schema/superspec/templates/`，L1 脚本位于 `scripts/`，包根无新增条目

#### Scenario: 散落资产被拒绝

- **GIVEN** 模板包根目录出现不在上述白名单内的额外条目
- **WHEN** 执行结构校验
- **THEN** 校验失败并指出违规路径

#### Scenario: 门禁与 L1 脚本归属 tooling 层

- **GIVEN** 模板包内存在 `scripts/onepress-gate.sh` 与 `scripts/sandbox-preflight.spec.ts`
- **WHEN** 检查 `ASSETS.md` 的归属标注
- **THEN** 两者标注为 `tooling` 层且覆盖策略为"安装到目标仓库 `scripts/`，受管文件全量覆盖，用户自建同名文件跳过"

#### Scenario: 门禁脚本归属工具条目

- **GIVEN** 模板包内新增 `scripts/onepress-gate.sh`
- **WHEN** 检查 `ASSETS.md` 的归属标注
- **THEN** 该脚本标注为 `tooling` 层且覆盖策略为“安装到目标仓库 `scripts/`”（V3.1 起由 installer 层上调，以支持门禁 0.5 在目标仓库确定性执行）

---

### Requirement: 资产归属分层标注

模板包内的每一项资产 MUST 在 `INSTALL_PROMPT.md` 的资产清单中标注归属层级（`harness`、`tooling` 或 `project`），归属信息 MUST 与安装时的覆盖策略一致。`tooling` 层 MUST 仅包含 `scripts/onepress-gate.sh` 与 `scripts/sandbox-preflight.spec.ts`，其余自测脚本仍 MUST 标注为 `installer` 且不安装。

#### Scenario: 归层级标注齐全

- **GIVEN** 模板包内存在 `qoder/skills/onepress-discipline/SKILL.md`、`scripts/onepress-gate.sh` 与 `docs/ui-components.md` 模板
- **WHEN** 读取 `INSTALL_PROMPT.md` 的资产清单
- **THEN** 前者标注为 `harness`，`onepress-gate.sh` 标注为 `tooling`，后者标注为 `project`

#### Scenario: 自测脚本仍不安装

- **GIVEN** `scripts/verify-carriers.sh`、`scripts/verify-gate.sh`、`scripts/verify-trae.sh`、`scripts/verify-cursor.sh`
- **WHEN** 检查资产清单与安装器清单
- **THEN** 四者标注为 `installer` 且不出现在 `install.sh` / `install.ps1` 的写入清单中

---

### Requirement: 模板内容逐字可复制

模板包内所有资产文件 MUST 为可直接落盘的最终内容，不得包含需要渲染的占位变量（如 `{{VAR}}`）或构建期指令。四份 `opsx-review` 命令体与 `review-rubric.md` MUST 由安装器直接复制，MUST NOT 由执行者按描述性语句重新生成。

#### Scenario: 无渲染占位符

- **GIVEN** 模板包内任意资产文件
- **WHEN** 扫描文件内容
- **THEN** 不出现 `{{` 或 `}}` 形式的渲染占位符

#### Scenario: 字节级一致性

- **GIVEN** 模板包内某资产文件与其在目标仓库中的安装副本
- **WHEN** 对比两者内容哈希
- **THEN** 哈希一致（未发生任何改写）

#### Scenario: 评分表逐字节一致

- **GIVEN** `openspec-schema/superspec/templates/review-rubric.md` 与安装后的副本
- **WHEN** 比对内容哈希
- **THEN** 哈希一致，且 `INSTALL_PROMPT.md` 的验收自检包含该项
