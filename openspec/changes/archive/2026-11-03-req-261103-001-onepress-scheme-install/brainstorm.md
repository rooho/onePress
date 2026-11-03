## Design Summary

onePress 是将 v3.0 极简前端工程方案（superspec 底座 + BMAD UX 自动推导 + ui_contract YAML 契约 + 沙箱即生产 + 秒级静态门禁 + 组件注册表）打包为可分发、可幂等安装的 harness 方案包，首批支持 `.qoder/` 与 `.opencode/` 两个 AI 编码环境，并提供一份让任意大模型按步骤自行完成安装的标准提示词（INSTALL_PROMPT.md）。

## Alternatives Considered

### Alternative A: 单提示词自安装（INSTALL_PROMPT.md 唯一载体）
- **Approach**: 不打包模板目录，只提供一份详尽的安装提示词，由 LLM 阅读后逐文件生成 `.qoder/`、`.opencode/`、`openspec/schemas/` 等全部资产。
- **Pros**: 资产体积最小，无需维护脚本；对任意 LLM 环境零依赖。
- **Cons**: LLM 每次生成的内容有随机性，模板正文无法保证逐字稳定；无法做版本比对与差异升级；长提示词执行到一半失败后难以续传。
- **Why not chosen**: 无法满足幂等安装与版本升级要求，harness 级资产的"全量覆盖"策略失去可校验基线。

### Alternative B: 模板包 + 安装脚本（版本化，脚本为唯一执行入口）
- **Approach**: `onepress/` 模板目录 + Node/Python 安装脚本，脚本校验 onePress.lock、执行覆盖/保护策略、复制渲染变量。
- **Pros**: 行为确定性强，版本比对、升级、回滚均可程序化；适合 CI 或批量仓库落地。
- **Cons**: 脚本需维护、需运行时依赖；纯脚本入口与"让大模型自动安装"的诉求割裂——用户还得先装运行时才能用。
- **Why not chosen**: 违背核心诉求"给大模型一段提示词即可自动安装"，且引入额外运行时依赖，增加维护面。

### Alternative C: 混合模式——模板包为唯一事实源，提示词与脚本均为前端（选定）
- **Approach**: `onepress/` 模板包是 SSOT（含 qoder/、opencode/、openspec-schema/ 三类 harness 资产 + INSTALL_PROMPT.md）。安装可由两种前端驱动：① 大模型读取 INSTALL_PROMPT.md 后手工落盘；② 未来可选的 install 脚本复用同一模板包。两者产出完全一致。
- **Pros**: 模板正文逐字稳定、可 diff；提示词与脚本共享事实源，不产生双份实现漂移；幂等与升级语义可被提示词明确描述（onePress.lock 清单）。
- **Cons**: 模板包需要维护版本与目录规范；提示词执行仍依赖 LLM 的遵守度。
- **Why not chosen（备选被否理由汇总）**: A 无法保证逐字稳定性，B 引入运行时割裂核心诉求，C 兼顾确定性与"提示词自动安装"的零门槛。

## Agreed Approach

采用 **Alternative C（混合模式）**。核心交付物与机制如下：

1. **模板包（SSOT）**：`onepress/` 目录包含：
   - `opencode/`：`opencode.json` + `agent/ux-architect.md` + `commands/opsx-new.md|opsx-apply.md|opsx-verify.md` + `skills/superpowers-tdd/`
   - `qoder/`：`skills/onepress-discipline/`（铁律封装）+ commands 头部强制引用说明
   - `openspec-schema/superspec/`：必须同步安装的 OpenSpec 核心 Schema 定义（V3.0 契约底座）
   - `INSTALL_PROMPT.md`：面向任意大模型的分步安装提示词（含幂等检查与升级语义）
2. **安装幂等与升级**：引入 `onePress.lock` 清单文件机制。安装前先检查目标环境与 lock 状态；harness 核心资产（command/skills/脚本）按版本全量覆盖；项目级资产（`docs/ui-components.md`、`openspec/changes/`）存在即跳过（Protect Local）；检测到本地未提交的工具链自定义修改时提示或跳过。
3. **资产归属分层**：
   - Harness 级（onePress 维护）：`ui_contract` 模板与 Schema 定义、Verify 门禁脚本 —— 随版本覆盖更新。
   - 项目级（目标仓库独有）：`docs/ui-components.md`（首次初始化空表，后续由 /opsx:archive 增量追加，严禁覆盖）、`openspec/changes/` 业务变更。
4. **安装范围**：目标仓库必须同步获得 `openspec/schemas/superspec/`，否则 AI 无法解析 proposal.md / design.md 及 `ui_contract` YAML 块。

## Key Decisions

1. **架构定位**：onePress 是 harness 级方案包（superspec 底座 + v3.0 前端纪律），不是新 Schema——schema 仍复用 superspec，前端契约以 design.md 底部 30~40 行 `ui_contract` YAML 块承载。
2. **.opencode/ 目录规范**：`opencode.json`（全局配置/Agent 角色/环境变量）+ `agent/ux-architect.md`（BMAD UX 架构师人设）+ `commands/opsx-{new,apply,verify}.md`（核心斜杠指令）+ `skills/superpowers-tdd/`（执行纪律）。注：命令目录官方规范为复数 `commands/`（已核实 opencode.ai/docs）。
3. **.qoder/ 注入方式**：采用"技能挂载法"——铁律封装为 `.qoder/skills/onepress-discipline/`，commands 头部强制引用，保证每次 `/opsx:apply`、`/opsx:new` 自动加载 Token 静态扫描与同构沙箱直出纪律；不改写 Qoder 现有 OpenSpec 命令主体。
4. **升级语义**：harness 核心覆盖 / 项目资产保护 / 本地修改提示，三档差异化。
5. **Schema 强制安装**：`openspec/schemas/superspec/` 随 onePress 初始化写入目标仓库，缺失时视为安装失败。

## Open Questions

1. **.opencode 能力面核实**：`.opencode/skills/` 与 `opencode.json` plugin 机制的当前版本格式需在 apply 前查证（已部分核实：skills 为 SKILL.md + frontmatter；commands 为 commands/ 目录 + frontmatter）。
2. **.qoder 命令策略**：是否新增独立 `onepress` 前缀命令，还是仅靠 skills 挂载改造现有 opsx 命令行为？（倾向后者，保持命令面不变。）
3. **onePress.lock 字段设计**：最少字段集（版本、安装时间、harness 清单哈希？）与缺失/损坏时的降级行为。
4. **INSTALL_PROMPT.md 的验收标准**：需要定义"安装成功"的可执行验收清单（两 harness 各 5 项检查），供 LLM 自检。
5. **测试矩阵**：全新仓库、已有 .qoder 仓库、带本地自定义修改仓库，三种场景的安装/升级回归方式。
