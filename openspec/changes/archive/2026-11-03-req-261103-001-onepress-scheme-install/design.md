## Context

onePress 是 v3.0 极简前端工程方案的可分发形态：把 superspec 底座、BMAD UX 自动推导（ui_contract YAML 契约）、沙箱即生产、秒级静态门禁与组件注册表打包为 harness 级方案包。本仓库为试点（dogfood）目标：`.qoder/` 已存在（OpenSpec init 产出的 commands/opsx 与 10 个 skills），`.opencode/` 不存在。安装必须不破坏现有 Qoder 命令面，不触碰项目级业务资产。

## Goals / Non-Goals

**Goals:**
- 模板包 onepress/ 成为唯一事实源（SSOT），可逐字复制、可 diff
- 幂等安装与三档升级：harness 核心覆盖 / 项目级资产存在即跳过 / 本地修改提示保护
- 一份 INSTALL_PROMPT.md 让任意大模型按步骤自行完成安装
- 首批支持 .qoder 与 .opencode 两套 harness（目录遵循各自官方规范）
- 强制同步注入 openspec/schemas/superspec/，缺失视为安装失败

**Non-Goals:**
- 不实现 CLI 安装脚本（可选后续前端）
- 不改写 Qoder 现有 opsx 命令主体，只做技能挂载引用
- 不提供可视化/UI
- 不迁移既有项目业务资产

## Decisions

- D1 模板包结构：`onepress/` 含 5 个功能条目（`VERSION` + `INSTALL_PROMPT.md` + `qoder/` + `opencode/` + `openspec-schema/`）与 3 个文档条目（`ASSETS.md`、`README-ch.md`、`README.md`，仅随仓库分发，不参与安装）
- D2 .opencode 采用已核实官方格式：`commands/*.md`（frontmatter description/agent/model，正文即 prompt，支持 $ARGUMENTS）；`skills/<name>/SKILL.md`（name 小写 kebab 且与目录名一致，description 1–1024 字符）；`agent/ux-architect.md`；`opencode.json`（$schema、agent permissions、command 映射）
- D3 .qoder 注入采用技能挂载法：铁律封装为 `skills/onepress-discipline/`，安装时对既有 `commands/` 文件在 frontmatter 后新增一行技能引用（仅加一行，不改主体）
- D4 onePress.lock 最小字段集：`version`、`installedAt`、`harnesses: {qoder, opencode}`、`protectedAssets: []`；lock 缺失/损坏时按全新安装处理，但项目级资产仍执行 Protect Local
- D5 三档升级策略：harness 核心（commands/skills/脚本）全量覆盖；项目级资产（docs/ui-components.md）存在即跳过；检测到本地未提交自定义修改时提示或跳过
- D6 Schema 注入：将 onepress/openspec-schema/superspec/ 复制到目标仓库 openspec/schemas/superspec/
- D7 INSTALL_PROMPT.md 结构：前置检查 → 分层安装 → 幂等与升级处理 → 双 harness 各 5 项验收自检 → 写 lock 收尾

## Risks / Trade-offs

- R1 LLM 执行提示词时产生随机性/遗漏 → 缓解：提示词要求逐字写入模板、安装后必须执行验收清单、lock 记录版本号
- R2 OpenCode 目录规范随版本演进 → 缓解：安装前以官方文档为准（本次已核实 opencode.ai/docs），lock 记录目标版本，升级时重新核对
- R3 与 Qoder 自带 opsx 命令/技能冲突 → 缓解：技能挂载法只加引用不改主体；onepress 资产命名带独立前缀
- R4 覆盖升级误伤用户自定义 harness 修改 → 缓解：git diff 未提交检测 + 提示，必要时跳过该项
- R5 LLM 误覆盖项目级资产 → 缓解：Protect Local（存在即跳过）+ 提示词红线声明

## Migration Plan

1. 试点安装：本仓库走"升级"分支（.qoder 已存在、.opencode 全新）
2. 新仓库安装：走"全新"分支，先初始化 openspec/ 再注入 harness 资产
3. 回滚：onePress.lock 记录安装文件清单，按清单手动删除即可回退

## Open Questions

- Qoder skills 的 frontmatter 规范是否与 OpenCode 一致（apply 前核实 Qoder 官方 skill 格式）
- INSTALL_PROMPT.md 的目标语言（中文/双语）与长度上限
- 后续是否提供 CLI 脚本前端（V2 候选）
