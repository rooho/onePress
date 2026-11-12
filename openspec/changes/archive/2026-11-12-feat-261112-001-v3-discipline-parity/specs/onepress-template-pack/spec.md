## MODIFIED Requirements

### Requirement: 模板包固定目录结构

onePress 模板包 MUST 采用固定顶层结构：7 个功能条目 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`trae/`、`cursor/`、`openspec-schema/`，1 个工具条目 `scripts/`，4 个文档条目 `ASSETS.md`、`README-ch.md`、`README.md`、`BLUEPRINT-V3.0.md`，以及 1 个自托管条目 `openspec/`（本方案自身的规范工作区）。工具条目、文档条目与自托管条目 MUST NOT 被安装到目标仓库。任何新增 harness 资产 MUST 归入对应子目录，不得散落在包根。

#### Scenario: 包结构完整性校验

- **GIVEN** 一个已构建的 onePress 模板包目录
- **WHEN** 执行结构校验（检查 7 个功能条目、1 个工具条目、4 个文档条目与 1 个自托管条目是否存在）
- **THEN** 校验通过且列出 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`trae/`、`cursor/`、`openspec-schema/`、`scripts/`、`ASSETS.md`、`README-ch.md`、`README.md`、`BLUEPRINT-V3.0.md`、`openspec/`

#### Scenario: 散落资产被拒绝

- **GIVEN** 模板包根目录出现不在上述白名单内的额外条目
- **WHEN** 执行结构校验
- **THEN** 校验失败并指出违规路径

#### Scenario: 门禁脚本归属工具条目

- **GIVEN** 模板包内新增 `scripts/onepress-gate.sh`
- **WHEN** 检查 `ASSETS.md` 的归属标注
- **THEN** 该脚本标注为 `installer` 层且覆盖策略为"不安装"，与 `scripts/` 属工具条目的定义一致
