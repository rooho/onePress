---
description: onePress 契约初始化——为变更生成 proposal/design 与 design.md 底部 ui_contract YAML 契约
agent: ux-architect
---

为一个新变更（`$ARGUMENTS`）执行 onePress 契约初始化：

1. 检索 `docs/ui-components.md`（组件注册表）与 OpenSpec 核心 Schema，确定可复用组件与字段映射。
2. 生成 `proposal.md`（Why / What Changes / Capabilities / Impact，注明涉及的 harness 与资产归属层级）。
3. 生成 `design.md`，并在其底部生成 `ui_contract` YAML 块（5 选 1 archetype、schema_mapping、双轨 states_matrix、layout_tokens，严禁超过 40 行）。
4. 严禁跳过 UI 契约直接进入编码；契约缺失时中止并报告。
