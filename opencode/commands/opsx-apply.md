---
description: onePress 沙箱即生产两阶段执行——UI 底座直出 + Schema 接线（无 in-app State Bar）
---

> 执行本命令 MUST 先加载技能 `superpowers-tdd`（铁律 1–4：Token 纯净度 / 四态状态机 / 无障碍基线 / 防呆与反馈闭环）。

先读 `openspec/changes/<change>/ui-spec.md`：

- **不存在**（`**UI Change**: no`）→ 跳过两阶段，直接按 `tasks.md` 执行标准 TDD 循环。
- **存在**（`**UI Change**: yes`）→ 按下列两阶段推进。

## Stage 1：UI 底座直出

1. 直接写生产级 `[Feature]View.tsx`：100% Props 受控（数据、`status`、`isSubmitting`、回调全部经 Props 传入），只使用真实 Shadcn 组件与 `ui-spec.md` 第 2 节的 Token。
2. 微动效按第 5 节执行：热区 ≥44×44px、悬停 200–250ms、按压 150ms、必须提供 `prefers-reduced-motion` 降级（`motion-reduce:`）。
3. 四态按第 3 节实现：`Loading` 预留等高骨架（CLS < 0.1）、`Empty` 带引导与 CTA、`Error` 内联展示且带图标或文字。
4. **禁止**从 `sandbox-preview.html` 转译代码——沙箱只是视觉参照。
5. **禁止**注入 in-app 浮动 State Bar，验收统一走沙箱对照。
6. 肉眼验收：对照 `sandbox-preview.html`，Light 与 Dark 各走一遍四态；不通过则回第 1 步。

## Stage 2：Schema 逻辑接线 + 纯逻辑 TDD

1. 写 Hook / Container 层，对状态迁移函数、数据转换与 Zod 校验执行纯 TS 单测（`vitest run`，1 秒内）。**不写** RTL 查询断言与 DOM 快照。
2. 把真实 API 返回值接入 `[Feature]View.tsx` 的 Props，组件结构与 class 集合**不得改动**。
3. 运行 `bash scripts/onepress-gate.sh --root . --ui-spec openspec/changes/<change>/ui-spec.md`，按输出修正直至无 `FAIL`。

## 回执

写 `openspec/changes/<change>/apply.md`，记录 worktree 路径、分支、commit 区间、`tasks.md` 完成度、所用执行模式（2a / 2b / 2c）与迭代号。
