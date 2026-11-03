## ADDED Requirements

### Requirement: 安装提示词固定五段结构

`INSTALL_PROMPT.md` MUST 按固定顺序包含五个段落：① 前置检查（目标仓库与 harness 现状探测）、② 分层安装（按 harness 级 / 项目级分别落盘）、③ 幂等与升级处理（读取与写入 `onePress.lock`）、④ 验收自检（逐项可执行检查）、⑤ 收尾（写 lock 并输出安装报告）。

#### Scenario: 五段结构齐全

- **GIVEN** 模板包中的 `INSTALL_PROMPT.md`
- **WHEN** 检查其标题结构
- **THEN** 五个段落按既定顺序全部存在

---

### Requirement: 逐字写入约束

提示词 MUST 明确要求执行者将模板文件内容逐字写入目标路径，禁止改写、精简或重排内容；对无法逐字写入的情况 MUST 中止并报告。

#### Scenario: 提示词包含逐字写入红线

- **GIVEN** `INSTALL_PROMPT.md` 的前置检查段落之后
- **WHEN** 检查提示词正文
- **THEN** 存在一条明确的"逐字写入、不得改写"约束条目

---

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
