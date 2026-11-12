**UI Change**: no

## Why

现行 onePress 只保证"工程确定性"——状态完备、Token 语法正确、类型不报错，却没有提供任何**设计推理**依据：行业审美基线、16 通道色彩语义、字体配对、空间密度、微交互时序全部缺位，模型只能退化为训练数据均值，产出"AI 视觉廉价感"。BLUEPRINT-V3.0.md 给出的解法是引入 `ui-ux-pro-max` 作为设计智能内核，并把契约载体从 40 行 `ui_contract` 升级为 5+1 章节的 `ui-spec.md`、把门禁从 4 项扩到 8 项。

## What Changes

**契约载体升级（BLUEPRINT §四.1）**
- From: `design.md` 底部 40 行 `ui_contract` YAML，五个字段
- To: 独立 `openspec/changes/<name>/ui-spec.md`，六章节（组件拆解 / Token 映射 / 四态矩阵 / 响应式排版 / 微动效 / 反模式黑名单），由 `templates/ui-spec.md` 承载
- Reason: 16 通道色彩 + 7 档间距 + 反模式清单的体量无法压进 40 行 YAML，硬塞会得到不可读也不可校验的键值堆
- Impact: **breaking**（相对 v3_0.md 基线）；`ui_contract` 下线，`/opsx:apply`、`/opsx:verify`、注册表检索全部改读 `ui-spec.md`

**需求分流（BLUEPRINT §三.1）**
- From: `/opsx:new` 对所有变更无条件要求契约
- To: 先判定 `ui_change: yes|no` 并写入 `proposal.md`；`no` 时不生成 `ui-spec.md`、不生成沙箱、不触发检索
- Reason: 保证纯后端 TDD 零干扰
- Impact: non-breaking

**设计智能检索（BLUEPRINT §五）**
- From: 无
- To: `ui_change: yes` 时按"先语义 UX、后技术栈"双步检索；一次性生成项目级基线 `docs/design-system/projectbaseline/MASTER.md`
- Reason: 用本地 CSV 知识库替代模型猜测
- Impact: 新增**可选**能力；`python3` 或技能目录缺失时检索记 `SKIP`，不影响安装与门禁

**高保真沙箱（BLUEPRINT §四.2）**
- From: in-app 浮动 State Bar（仅 dev 可见）
- To: `openspec/changes/<name>/sandbox-preview.html` 单文件，含四态切换 + Light/Dark 切换 + 16 语义变量 + Google Fonts
- Reason: 暗色模式与卡片表面分离度必须在编码前验收，in-app 工具看不到
- Impact: **breaking**；移除 State Bar 注入要求，两套验收口径收敛为一套

**八项门禁（BLUEPRINT §四.3）**
- From: 4 项（tsc / Token 正则 / 纯逻辑 TDD / 四态点检）
- To: 8 项（+ 对比度 ≥4.5:1、断点防破版、A11y CRITICAL、热区 ≥44px 与微动效时序、反模式清零、沙箱对齐）
- Reason: 前 4 项只覆盖工程正确，后 4 项覆盖体验正确
- Impact: `scripts/onepress-gate.sh` 需新增 4 组检查；门禁 4 明确限定为纯逻辑状态机测试，不含 RTL

**组件注册表结构（BLUEPRINT 引用表）**
- From: 6 列（组件名 / 文件路径 / 用途 / 关键 Props / 状态覆盖 / 首次引入）
- To: 4 列（组件名称 / 路径 / 适用骨架 (Archetype) / 核心 Props 签名），保留 base/domain 分区
- Reason: "适用骨架"是 `ui-spec.md` 第 1 节的复用检索键，缺列会导致复用失效
- Impact: 模板变更；旧表只输出迁移 `WARN`，不改写

## Capabilities

### New Capabilities

- `onepress-frontend-contract`: v3.0 前端纪律本体——需求分流、`ui-spec.md` 五+一契约、设计智能检索与基线、高保真沙箱、沙箱即生产两阶段、八项门禁、门禁脚本、组件注册表

### Modified Capabilities

- `onepress-harness-integration`: `多 harness 语义等价` 扩为十项最小要点；`superspec schema 强制注入` 由 10 文件改为 11 文件
- `onepress-llm-installer`: `逐字写入约束` 覆盖 `ui-spec.md` 与注册表的内联逐字模板
- `onepress-template-pack`: `模板包固定目录结构` 补齐 `trae/`、`cursor/`、`scripts/` 与 `BLUEPRINT-V3.0.md`

## Impact

- 新增：`openspec-schema/superspec/templates/ui-spec.md`、`scripts/onepress-gate.sh`、`scripts/verify-gate.sh`
- harness 级：`qoder/`、`trae/`、`cursor/` 三份 `SKILL.md`；`opencode/agent/ux-architect.md` 与 `commands/opsx-{new,apply,verify}.md`；`superspec/schema.yaml` 的 design / apply 指令
- installer 层：`install.sh`、`install.ps1`（11 文件计数、注册表四列、旧表 `WARN`、`ui-ux-pro-max` 探测）、`INSTALL_PROMPT.md`
- 文档：`ASSETS.md`、`README.md`、`README-ch.md`
- 不触碰：`openspec/changes/`（业务资产）、目标仓库既有 `docs/ui-components.md`
