---
name: onepress-discipline
description: onePress 执行纪律（Qoder 载体）——Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆
---

# onePress 执行纪律（onepress-discipline）

> 本技能与 OpenCode 载体 `superpowers-tdd` 语义等价（四条铁律 + TDD 纪律），仅载体格式不同。

## 铁律 1：Token 纯净度

- 零内联样式（禁止内联 style 属性）
- 零硬编码色值（`#hex` / `rgb()` / `hsl()` 禁止，SVG 内部除外）
- 零任意像素间距（`w-[317px]` / `p-[13px]` 禁止）

## 铁律 2：四态状态机

每个数据驱动组件必须实现四态：`Idle` / `Loading`（Skeleton 等高防 CLS）/ `Empty`（插图+引导文案+CTA）/ `Error`（Alert + 重试）。写入状态必须实现 `Submitting` 锁定（`disabled` + `Loader2`）。

## 铁律 3：无障碍基线

- 焦点环：继承 Radix/Shadcn 默认 `focus-visible:ring-2`，严禁无替代地移除焦点。
- 纯图标按钮必须显式 `aria-label`。
- 异步区域必须 `aria-live="polite"` 或 `role="status"`。

## 铁律 4：防呆与反馈闭环

- 一切异步提交动作必须锁定按钮防二次点击。
- 一切删除/覆盖动作必须经 `<AlertDialog variant="destructive">` 二次确认。
- 操作结果必须触发 `toast` 通知。

## TDD 纪律

- 仅对纯逻辑层（数据转换、Zod 校验、状态机函数）执行 TDD：先写失败测试，再写实现。
- DOM 渲染单测不做，四态验收靠浮动 State Bar 肉眼点检。
