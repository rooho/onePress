# onepress-llm-installer Delta

## MODIFIED Requirements

### Requirement: 安装提示词固定五段结构

`INSTALL_PROMPT.md` MUST 按固定顺序包含五个段落：① 前置检查（目标仓库与 harness 现状探测）、② 分层安装（按 harness 级 / tooling 级 / 项目级分别落盘；harness 级 MUST 包含四份 onePress 托管 `opsx-review` 命令，tooling 级 MUST 包含 `scripts/onepress-gate.sh` 与 `scripts/sandbox-preflight.spec.ts`）、③ 幂等与升级处理（读取与写入 `onePress.lock`，升级清理范围 MUST 覆盖 `opsx-review.md` 与 `review-rubric.md`）、④ 验收自检（逐项可执行检查）、⑤ 收尾（写 lock 并输出安装报告）。

#### Scenario: 五段结构齐全

- **GIVEN** 模板包中的 `INSTALL_PROMPT.md`
- **WHEN** 检查其标题结构
- **THEN** 五个段落按既定顺序全部存在

#### Scenario: 托管命令出现在分层安装段

- **GIVEN** `INSTALL_PROMPT.md` 的第②段
- **WHEN** 检索命令文件清单
- **THEN** 四份 `opsx-review` 命令与两份 tooling 脚本均被列出，且各自标注目标路径

---

### Requirement: 逐字写入约束

提示词 MUST 明确要求执行者将模板文件内容逐字写入目标路径，禁止改写、精简或重排内容；对无法逐字写入的情况 MUST 中止并报告。对由安装器内联生成的文件（`docs/ui-components.md`、`openspec/config.yaml`），提示词 MUST 内联与安装脚本完全一致的逐字模板正文，不得仅以"按模板初始化"等描述性语句替代。对随 schema 分发的模板（含 `templates/ui-spec.md` 与 `templates/review-rubric.md`）及四份 `opsx-review` 命令，提示词 MUST 要求直接复制模板包文件，不得由执行者重新生成或概括。

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

#### Scenario: ui-spec 与 rubric 模板随包分发且逐字一致

- **GIVEN** `openspec-schema/superspec/templates/ui-spec.md`、`templates/review-rubric.md` 与安装后的副本
- **WHEN** 比对内容哈希
- **THEN** 两份哈希均一致，且 `INSTALL_PROMPT.md` 的验收自检包含这两项

#### Scenario: 描述性语句不被接受

- **GIVEN** `INSTALL_PROMPT.md` 中某处仅写"以注册表模板初始化（表头 + 使用说明）"而未给出模板正文
- **WHEN** 执行仅凭提示词的安装路径
- **THEN** 该处判定为违反逐字写入约束，验收自检失败

---

### Requirement: 每个 harness 的可执行验收清单

提示词 MUST 为每个受支持 harness 提供不少于 5 项可执行验收检查，检查项 MUST 能通过读取文件或运行命令得出确定结论。对 Qoder/Trae/Cursor，清单 MUST 包含 `opsx-review` 命令存在且含技能引用行；对 OpenCode，清单 MUST 包含 `commands/opsx-review.md` 存在且逐字节一致；四者 MUST 共同包含 `review-rubric.md` 与 schema 12 文件校验。

#### Scenario: .qoder 验收项数量达标

- **GIVEN** `INSTALL_PROMPT.md` 的验收自检段落
- **WHEN** 统计 `.qoder` 相关验收检查项
- **THEN** 数量不少于 5 项，且包含 `opsx-review` 命令与技能引用行检查

#### Scenario: .opencode 验收项数量达标

- **GIVEN** `INSTALL_PROMPT.md` 的验收自检段落
- **WHEN** 统计 `.opencode` 相关验收检查项
- **THEN** 数量不少于 5 项，且包含 `opsx-review` 命令逐字节一致检查

#### Scenario: schema 12 文件与 rubric 被验收

- **GIVEN** `INSTALL_PROMPT.md` 的 OpenSpec Schema 验收段
- **WHEN** 检查验收项
- **THEN** 存在 `schema.yaml + templates/ 11 文件（共 12）` 与 `review-rubric.md` 逐字节一致两项

---

### Requirement: 零运行时依赖执行

提示词 MUST 仅依赖执行者可用的通用文件读写能力即可完成安装，不得要求预先安装 Node.js、Python 或其他运行时。L1 预检（Playwright + axe）与 `ui-ux-pro-max` 检索 MUST 属可选增强层：缺失时 MUST 记 `SKIP` 并继续安装，MUST NOT 触发 `npm install`、`uipro init` 或任何网络请求。

#### Scenario: 无运行时前置要求

- **GIVEN** 一个仅有任意 LLM 与文件系统访问能力的全新仓库
- **WHEN** 按 `INSTALL_PROMPT.md` 执行安装
- **THEN** 安装可完成且过程中未调用任何包管理器或脚本运行时

#### Scenario: L1 依赖缺失仍安装成功

- **GIVEN** 目标环境没有 Node.js 与 Playwright
- **WHEN** 按 `INSTALL_PROMPT.md` 执行安装
- **THEN** 报告记录 L1 为可选增强层且安装结论为成功，`opsx-review` 命令与 rubric 仍被写入

#### Scenario: 可选层缺失不重试不索权

- **GIVEN** `ui-ux-pro-max` 技能目录不存在
- **WHEN** 安装完成
- **THEN** 报告含一行 `SKIP` 与启用指引，未发起网络请求，未向用户索要额外权限
