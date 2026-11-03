---
description: onePress 秒级静态门禁——tsc 类型 + Token 纯净度 + 纯逻辑 Hook TDD + 四态点检
---

执行 onePress 秒级静态门禁（4 项，任一失败打回 apply 对应阶段）：

## 门禁 1：TypeScript 契约对齐

运行 `tsc --noEmit`，确保 OpenSpec Schema 类型与 `View.tsx` Props 严丝合缝，零类型报错。

## 门禁 2：Design Token 纯净度正则扫描

对本次变更的 `.tsx/.vue` 文件执行以下正则，三项匹配数必须为 `0`：

1. 内联样式：`style=\{\{`
2. 硬编码颜色：`#[0-9a-fA-F]{3,8}|rgb\(|hsl\(`（SVG 内部除外）
3. 任意像素间距：`(p|m|w|h|gap)-\[\d+px\]`

## 门禁 3：纯逻辑层 TDD

仅对脱离 DOM 的纯 TypeScript 数据转换函数与 Zod 校验规则运行 `vitest run`，执行时间控制在 1 秒以内。

## 门禁 4：四态点检（人工 10 秒）

通过浮动 State Bar 确认 `Loading` / `Empty` / `Error` / `Submitting` 四态均正常渲染，无 `undefined` 或 `NaN` 裸露。
