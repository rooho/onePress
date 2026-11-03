## ADDED Requirements

### Requirement: OpenCode 官方目录规范

`.opencode/` 资产 MUST 遵循 OpenCode 官方目录约定：配置为 `opencode.json`；命令为 `commands/<name>.md`（frontmatter 含 `description`，正文即 prompt，支持 `$ARGUMENTS`）；自定义 agent 为 `agent/<name>.md`（frontmatter 含 `mode`）；技能为 `skills/<name>/SKILL.md`（frontmatter 必含 `name` 与 `description`）。

#### Scenario: 技能目录与 frontmatter 合规

- **GIVEN** 安装后的 `.opencode/skills/superpowers-tdd/SKILL.md`
- **WHEN** 校验其目录名与 frontmatter
- **THEN** 目录名为小写 kebab-case，`name` 字段与该目录名完全一致，且 `description` 长度为 1–1024 字符

#### Scenario: 命令文件位于复数目录

- **GIVEN** 安装后的 `.opencode/` 目录树
- **WHEN** 定位命令文件
- **THEN** 命令文件位于 `.opencode/commands/` 而非单数 `command/`

---

### Requirement: Qoder 技能挂载法

`.qoder/` 集成 MUST 以新增技能 `.qoder/skills/onepress-discipline/SKILL.md` 的形式承载纪律，并通过命令文件头部引用该技能生效；MUST NOT 改写 Qoder 既有 `commands/opsx/` 下命令的主体内容。

#### Scenario: 既有 opsx 命令主体不被改写

- **GIVEN** 目标仓库已存在 `.qoder/commands/opsx/` 下的 OpenSpec 命令文件
- **WHEN** 执行 onePress 安装
- **THEN** 上述命令文件的既有主体内容保持不变

#### Scenario: 纪律技能可被引用

- **GIVEN** 安装完成后的 `.qoder/skills/onepress-discipline/`
- **WHEN** 检查该目录
- **THEN** 存在 `SKILL.md` 且其 frontmatter 含可被命令头部引用的技能名

#### Scenario: 安装后命令头部含技能引用

- **GIVEN** 目标仓库已存在 `.qoder/commands/opsx/apply.md`
- **WHEN** 执行 onePress 安装
- **THEN** 该文件 frontmatter 后新增一行 `onepress-discipline` 技能引用，且命令正文其余内容保持不变

---

### Requirement: superspec schema 强制注入

安装器 MUST 将 `openspec/schemas/superspec/`（`schema.yaml` 与 `templates/` 下 9 个模板文件）注入目标仓库；任一文件缺失 MUST 判定安装失败并中止后续步骤。

#### Scenario: schema 文件齐全

- **GIVEN** 安装完成后的目标仓库
- **WHEN** 统计 `openspec/schemas/superspec/` 下的文件
- **THEN** 存在 `schema.yaml` 与 `templates/` 下 9 个模板文件（共 10 个）

#### Scenario: 注入缺失即失败

- **GIVEN** 安装过程中 `templates/verify.md` 未能写入
- **WHEN** 执行安装后校验
- **THEN** 安装结果判定为失败并输出缺失文件路径

---

### Requirement: 双 harness 语义等价

同一能力在 `.qoder/` 与 `.opencode/` 中的纪律内容 MUST 语义等价（步骤、红线、验收项一致），仅允许载体格式差异（frontmatter 字段、目录名）。

#### Scenario: 纪律要点一致

- **GIVEN** `.qoder/skills/onepress-discipline/SKILL.md` 与 `.opencode/skills/` 下对应技能
- **WHEN** 比对二者的纪律要点（门禁项、红线条目）
- **THEN** 要点集合完全一致
