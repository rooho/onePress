---
name: superpowers-tdd
description: onePress 执行纪律（OpenCode 载体）——纯逻辑 Hook TDD、Token 纯净度、四态状态机、无障碍与破坏性操作防呆
---

# onePress 执行纪律（superpowers-tdd）

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

- 仅对纯逻辑层（数据转换、Zod 校验、状态机迁移函数）执行 TDD：先写失败测试，再写实现。
- DOM 渲染单测不做，四态验收靠 `sandbox-preview.html` 对照肉眼点检（Light 与 Dark 各一遍）。
- **禁止**引入 RTL 查询断言与 DOM 快照，违者门禁 4 判 `FAIL`。

## 归档纪律

- `/opsx:archive` 时把本次新建或改造的可复用组件追加一行到 `docs/ui-components.md`，列固定为 `组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名`；只追加，不重排、不删历史。
- 归档前必须存在 `verify.md` 且结论非 `FAIL`；`MANUAL` 项未确认时不得归档。

## 门禁纪律

- `bash scripts/onepress-gate.sh` 实现门禁 2/4/5/6/7；门禁 0/1/3/8 由命令体与人工承担。
- 任何 `SKIP` 必须附原因；`MANUAL` 不得被默认为通过。

