## Why

无设计师、纯程序员主导的 AI 辅助研发团队，其前端 UI 工程方案（v3.0：BMAD UX 自动推导 + ui_contract YAML 契约 + 沙箱即生产 + 秒级静态门禁 + 组件注册表）目前仅存在于文档中。每开一个新仓库都要人工逐文件复制规则到 .qoder / .opencode，容易漏装、版本漂移、无法升级。需要把整套纪律打包为可分发、可幂等安装、可由大模型按提示词自行执行的方案包（onePress），首批落地 .qoder 与 .opencode 两个 harness。

## What Changes

**方案分发方式**
- From: v3.0 方案仅作为文档存在，人工逐文件复制到各环境，无版本概念
- To: onePress 模板包（qoder/ + opencode/ + openspec-schema/ + INSTALL_PROMPT.md），模板包为唯一事实源（SSOT）
- Reason: 消除人工搭建差异与版本漂移
- Impact: 非破坏性，纯新增资产

**安装与升级语义**
- From: 无安装状态跟踪，重复安装可能覆盖用户本地业务资产
- To: onePress.lock 清单 + 三档差异化策略（harness 核心全量覆盖 / 项目级资产存在即跳过 / 本地修改提示保护）
- Reason: 工具包升级不得破坏目标仓库业务资产
- Impact: 非破坏性

**环境支持面**
- From: 仅 Qoder 一套环境，命令与技能靠手动放置
- To: 首批支持 .qoder 与 .opencode 两套 harness，目录结构遵循各自官方规范（已核实 opencode.ai/docs：commands/ 为复数、skills/<name>/SKILL.md、agent/*.md）
- Reason: 覆盖团队实际使用的两个 AI 编码环境
- Impact: 非破坏性

**OpenSpec Schema 底座**
- From: 目标仓库不一定装有 openspec/schemas/superspec，AI 无法解析 ui_contract 契约
- To: onePress 安装时强制同步注入 openspec/schemas/superspec/，缺失视为安装失败
- Reason: v3.0 前端契约的解析底座是 superspec schema
- Impact: 非破坏性

## Capabilities

### New Capabilities
- `onepress-template-pack`: onePress 模板包目录结构与资产归属分层（harness 级 vs 项目级）规范
- `onepress-idempotent-install`: onePress.lock 清单、幂等安装与三档差异化升级策略
- `onepress-llm-installer`: INSTALL_PROMPT.md 标准安装提示词（任意大模型可依步骤自装）
- `onepress-harness-integration`: .qoder 技能挂载法与 .opencode 官方目录规范的双 harness 集成，含 superspec schema 同步安装

### Modified Capabilities
<!-- 无：本变更为纯新增，不修改既有 capability -->

## Impact

- 仓库根新增：`onepress/` 模板包目录、`onePress.lock` 清单文件
- 目标环境资产：`.qoder/skills/onepress-discipline/`；`.opencode/`（opencode.json + commands/ + agent/ + skills/）
- OpenSpec 资产：`openspec/schemas/superspec/` 注入目标仓库
- 运行时依赖：无新增（全部为 Markdown / JSON / YAML 静态资产，可选脚本不强制）
- 不触碰：`docs/ui-components.md`（项目级，仅首装初始化）、`openspec/changes/`（业务资产）
