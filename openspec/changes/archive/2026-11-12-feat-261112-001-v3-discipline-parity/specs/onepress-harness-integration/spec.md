## MODIFIED Requirements

### Requirement: 多 harness 语义等价

同一能力在 `.qoder/`、`.opencode/`、`.trae/` 与 `.cursor/` 中的纪律内容 MUST 语义等价（步骤、红线、验收项一致），仅允许载体格式差异（frontmatter 字段、目录名）。等价性 MUST 覆盖以下十项最小要点集合：① Token 纯净度三条禁令；② 四态状态机（含 `Submitting` 锁定）；③ 无障碍基线三条；④ 防呆与反馈闭环三条；⑤ 需求类型分流与 `**UI Change**:` 输出；⑥ `ui-spec.md` 六章节契约与 16 通道色彩要求；⑦ 设计智能检索的双步顺序与 `SKIP` 降级；⑧ 高保真沙箱（四态 + Light/Dark + Token 变量）；⑨ 沙箱即生产两阶段；⑩ 八项门禁与 `AUTO`/`MANUAL` 分级。

#### Scenario: 纪律要点一致

- **GIVEN** `.qoder/skills/onepress-discipline/SKILL.md`、`.trae/skills/onepress-discipline/SKILL.md`、`.cursor/skills/onepress-discipline/SKILL.md` 与 `.opencode/` 下的对应技能与命令
- **WHEN** 比对四者的纪律要点
- **THEN** 上述十项最小要点集合的命中数完全一致，缺任一项即判定语义不等价

#### Scenario: 新基线关键词在四个载体均可检索

- **GIVEN** 安装完成后的四个 harness 目录
- **WHEN** 在每个载体的技能或命令文件中检索 `ui_change`、`ui-spec.md`、`sandbox-preview`、`44×44`、`prefers-reduced-motion`
- **THEN** 五项关键词在四个载体中均可检索到，且语义指向同一套步骤

#### Scenario: OpenCode 侧不因拆分而缺失要点

- **GIVEN** OpenCode 的纪律被拆分为 `agent/ux-architect.md`、`skills/superpowers-tdd/SKILL.md` 与 `commands/opsx-*.md`
- **WHEN** 合并比对这组文件的要点集合
- **THEN** 与三份 carrier skill 的要点集合一致，拆分本身不构成差异理由

---

### Requirement: superspec schema 强制注入

安装器 MUST 将 `openspec/schemas/superspec/`（`schema.yaml` 与 `templates/` 下 10 个模板文件，含 `ui-spec.md`）注入目标仓库；任一文件缺失 MUST 判定安装失败并中止后续步骤。安装自检的文件数 MUST 由受管文件清单长度推导，MUST NOT 硬编码为固定数字。

#### Scenario: schema 文件齐全

- **GIVEN** 安装完成后的目标仓库
- **WHEN** 统计 `openspec/schemas/superspec/` 下的文件
- **THEN** 存在 `schema.yaml` 与 `templates/` 下 10 个模板文件（共 11 个），且包含 `ui-spec.md`

#### Scenario: 注入缺失即失败

- **GIVEN** 安装过程中 `templates/ui-spec.md` 未能写入
- **WHEN** 执行安装后校验
- **THEN** 安装结果判定为失败并输出缺失文件路径

#### Scenario: 计数随清单变化

- **GIVEN** 受管模板清单由 9 个增加到 10 个（新增 `ui-spec.md`）
- **WHEN** 执行安装自检
- **THEN** 期望文件数由清单长度推导得出（11 个），新增模板不导致自检误报

---

### Requirement: Trae 命令初始化与挂载

`.trae/` 集成 MUST 写入 `.trae/skills/onepress-discipline/SKILL.md`；当 `.trae/commands/` 为空或**命令集不完整**（缺少 `opsx-continue.md`、`opsx-propose.md`、`opsx-archive.md` 等 OpenSpec 标准命令）时 MUST 先清理旧版随包命令（`opsx-new.md` / `opsx-apply.md` / `opsx-verify.md`，存在未提交修改的除外）再执行 `openspec init --tools trae` 生成完整命令集，并在每个命令的 frontmatter 后挂载 `onepress-discipline` 技能引用。Trae MUST 与 Qoder 一样获得完整 `/opsx:*` 命令集，不得只提供三个命令。

#### Scenario: Trae 命令与 Qoder 对齐

- **GIVEN** 目标仓库存在 `.trae/` 且 `.trae/commands/` 为空
- **WHEN** 安装器以 `trae` harness 执行
- **THEN** `.trae/commands/` 下生成完整命令集（OpenSpec 1.13 实测为 12 个），且每个命令均含技能引用行

#### Scenario: 旧版 3 命令残留时自动修复

- **GIVEN** 目标仓库 `.trae/commands/` 仅有旧版随包直出的 `opsx-new.md`、`opsx-apply.md`、`opsx-verify.md`，且 `onePress.lock` 未记录这些文件
- **WHEN** 安装器以 `trae` harness 再次执行
- **THEN** 这 3 个旧文件被清理，`.trae/commands/` 下重新生成完整命令集（12 个）且均含技能引用行
