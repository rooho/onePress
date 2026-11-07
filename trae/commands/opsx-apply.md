---
name: opsx-apply
description: onePress 沙箱即生产两阶段执行——UI 底座直出 + Schema 逻辑接线
---

> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。

按 onePress 纪律执行 `/opsx:apply`，两阶段推进：

## Stage 1：UI 底座直出 + 10 秒肉眼验收

1. 直接生成生产级受控组件 `[Feature]View.tsx`：100% Props 受控（数据、`status`、`isSubmitting`、回调全部经 Props 传入），100% 使用真实 Shadcn UI 组件与 Tailwind 标准 Token。
2. 注入仅开发环境可见的浮动 State Bar（`process.env.NODE_ENV === 'development'`），提供 5 个切换按钮：`[Idle/Success]` `[Loading]` `[Empty]` `[Error]` `[Submitting]`。
3. 开发者点击面板 10 秒完成多状态视觉验收，未通过则回到第 1 步修正。

## Stage 2：Schema 逻辑接线 + 纯逻辑 TDD

1. 编写自定义 Hook / Container 层，对复杂状态转换与 Zod 校验执行纯 TS 单元测试（`vitest run`，1 秒内完成）。
2. 将真实 OpenSpec API 返回值接入 `[Feature]View.tsx` 的 Props，UI 代码无需改动任何一行。
3. 移除或隐藏浮动 State Bar。

纪律（引用 superpowers-tdd 技能）：UI 代码零业务 API 依赖；先写失败测试再写实现。
