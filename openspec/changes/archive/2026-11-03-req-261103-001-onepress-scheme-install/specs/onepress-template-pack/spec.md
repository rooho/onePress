## ADDED Requirements

### Requirement: 模板包固定目录结构

onePress 模板包 MUST 采用固定顶层结构：5 个功能条目 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`openspec-schema/`，以及 3 个文档条目 `ASSETS.md`、`README-ch.md`、`README.md`（文档条目 MUST NOT 被安装到目标仓库）。任何新增 harness 资产 MUST 归入对应子目录，不得散落在包根。

#### Scenario: 包结构完整性校验

- **GIVEN** 一个已构建的 onePress 模板包目录
- **WHEN** 执行结构校验（检查 5 个功能条目与 3 个文档条目是否存在）
- **THEN** 校验通过且列出 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`openspec-schema/`、`ASSETS.md`、`README-ch.md`、`README.md`

#### Scenario: 散落资产被拒绝

- **GIVEN** 模板包根目录出现不在上述白名单内的额外条目
- **WHEN** 执行结构校验
- **THEN** 校验失败并指出违规路径

---

### Requirement: 资产归属分层标注

模板包内的每一项资产 MUST 在 `INSTALL_PROMPT.md` 的资产清单中标注归属层级（`harness` 或 `project`），归属信息 MUST 与安装时的覆盖策略一致。

#### Scenario: 归层级标注齐全

- **GIVEN** 模板包内存在 `qoder/skills/onepress-discipline/SKILL.md` 与 `docs/ui-components.md` 模板
- **WHEN** 读取 `INSTALL_PROMPT.md` 的资产清单
- **THEN** 前者标注为 `harness`，后者标注为 `project`

---

### Requirement: 模板内容逐字可复制

模板包内所有资产文件 MUST 为可直接落盘的最终内容，不得包含需要渲染的占位变量（如 `{{VAR}}`）或构建期指令。

#### Scenario: 无渲染占位符

- **GIVEN** 模板包内任意资产文件
- **WHEN** 扫描文件内容
- **THEN** 不出现 `{{` 或 `}}` 形式的渲染占位符

#### Scenario: 字节级一致性

- **GIVEN** 模板包内某资产文件与其在目标仓库中的安装副本
- **WHEN** 对比两者内容哈希
- **THEN** 哈希一致（未发生任何改写）

---

### Requirement: 项目级资产不得作为覆盖目标

模板包 MUST NOT 将 `docs/ui-components.md` 与 `openspec/changes/` 声明为可覆盖资产；二者仅允许在目标仓库中不存在时初始化。

#### Scenario: 项目级资产存在时不覆盖

- **GIVEN** 目标仓库已存在 `docs/ui-components.md` 且内容含本地组件记录
- **WHEN** 执行 onePress 安装或升级
- **THEN** 该文件内容保持不变
