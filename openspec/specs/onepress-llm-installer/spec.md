# onepress-llm-installer Specification

## Purpose
定义 `INSTALL_PROMPT.md` 作为无脚本安装兜底的结构约束：五段式流程、逐字写入红线、每个 harness 的可执行验收清单，以及零运行时依赖承诺。

## Requirements

### Requirement: 安装提示词固定五段结构

`INSTALL_PROMPT.md` MUST 按固定顺序包含五个段落：① 前置检查（目标仓库与 harness 现状探测）、② 分层安装（按 harness 级 / 项目级分别落盘）、③ 幂等与升级处理（读取与写入 `onePress.lock`）、④ 验收自检（逐项可执行检查）、⑤ 收尾（写 lock 并输出安装报告）。

#### Scenario: 五段结构齐全

- **GIVEN** 模板包中的 `INSTALL_PROMPT.md`
- **WHEN** 检查其标题结构
- **THEN** 五个段落按既定顺序全部存在

---

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

### Requirement: 每个 harness 的可执行验收清单

提示词 MUST 为每个受支持 harness 提供不少于 5 项可执行验收检查，检查项 MUST 能通过读取文件或运行命令得出确定结论。

#### Scenario: .qoder 验收项数量达标

- **GIVEN** `INSTALL_PROMPT.md` 的验收自检段落
- **WHEN** 统计 `.qoder` 相关验收检查项
- **THEN** 数量不少于 5 项且每项均可执行

#### Scenario: .opencode 验收项数量达标

- **GIVEN** `INSTALL_PROMPT.md` 的验收自检段落
- **WHEN** 统计 `.opencode` 相关验收检查项
- **THEN** 数量不少于 5 项且每项均可执行

---

### Requirement: 安装红线声明

提示词 MUST 显式声明红线：禁止覆盖项目级资产、禁止修改目标仓库的业务代码与既有业务文档、禁止删除用户本地文件。

#### Scenario: 红线声明存在且可检索

- **GIVEN** `INSTALL_PROMPT.md`
- **WHEN** 检索红线关键词（项目级资产、业务代码、本地文件）
- **THEN** 三条红线均可检索到明确表述

---

### Requirement: 零运行时依赖执行

提示词 MUST 仅依赖执行者可用的通用文件读写能力即可完成安装，不得要求预先安装 Node.js、Python 或其他运行时。

#### Scenario: 无运行时前置要求

- **GIVEN** 一个仅有任意 LLM 与文件系统访问能力的全新仓库
- **WHEN** 按 `INSTALL_PROMPT.md` 执行安装
- **THEN** 安装可完成且过程中未调用任何包管理器或脚本运行时
