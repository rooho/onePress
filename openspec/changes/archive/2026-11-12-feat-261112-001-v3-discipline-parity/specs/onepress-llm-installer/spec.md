## MODIFIED Requirements

### Requirement: 逐字写入约束

提示词 MUST 明确要求执行者将模板文件内容逐字写入目标路径，禁止改写、精简或重排内容；对无法逐字写入的情况 MUST 中止并报告。对由安装器内联生成的文件（`docs/ui-components.md`、`openspec/config.yaml`），提示词 MUST 内联与安装脚本完全一致的逐字模板正文，不得仅以"按模板初始化"等描述性语句替代。对随 schema 分发的模板（含 `templates/ui-spec.md`），提示词 MUST 要求直接复制模板包文件，不得由执行者重新生成或概括。

#### Scenario: 提示词包含逐字写入红线

- **GIVEN** `INSTALL_PROMPT.md` 的前置检查段落之后
- **WHEN** 检查提示词正文
- **THEN** 存在一条明确的"逐字写入、不得改写"约束条目

#### Scenario: 注册表模板逐字可比对

- **GIVEN** `INSTALL_PROMPT.md` 与 `install.sh`
- **WHEN** 分别提取两者定义的 `docs/ui-components.md` 初始化内容
- **THEN** 两份内容逐字节一致，含四个表头列名与 base/domain 两个分区

#### Scenario: ui-spec 模板随包分发且逐字一致

- **GIVEN** `openspec-schema/superspec/templates/ui-spec.md` 与安装后的副本
- **WHEN** 比对两者内容哈希
- **THEN** 哈希一致，且 `INSTALL_PROMPT.md` 的验收自检包含该项

#### Scenario: 描述性语句不被接受

- **GIVEN** `INSTALL_PROMPT.md` 中某处仅写"以注册表模板初始化（表头 + 使用说明）"而未给出模板正文
- **WHEN** 执行仅凭提示词的安装路径
- **THEN** 该处判定为违反逐字写入约束，验收自检失败
