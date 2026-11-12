---
description: onePress 八项门禁——契约存在性 + 工程正确 + 体验正确（AUTO/MANUAL 分级）
---

先跑脚本拿到自动项结论，再补人工项。

```bash
bash scripts/onepress-gate.sh --root . --ui-spec openspec/changes/<change>/ui-spec.md
```

## 门禁 0：契约存在性（AUTO）

读 `proposal.md` 首行的 `**UI Change**:`。

- `yes` → `ui-spec.md` 与 `sandbox-preview.html` 必须同时存在，缺任一即 `FAIL`。
- `no` → 门禁 1–8 全部记 `SKIP（无 UI 变更）`，转入非 UI 校验。

## 门禁 1：四态一致性与防抖（MANUAL）

对照 `ui-spec.md` 第 3 节逐组件核对四态；`Loading` 必须预留等高空间（CLS < 0.1）；状态切换必须有 150–250ms 过渡，不得 0ms 跳变。

## 门禁 2：Design Token 100% 与对比度（AUTO）

三条正则匹配数必须为 0：内联 `style={{`、硬编码色值（`:root`/`.dark` 变量块与 `<svg>` 内部除外）、任意像素间距。Light/Dark 下 `Background/Foreground`、`Card/Card Foreground`、`Muted/Muted Foreground` 三对正文对比度 ≥4.5:1，大字与控件边界 ≥3:1。

## 门禁 3：断点与极端文本防破版（MANUAL）

`sm`/`md`/`lg`/`xl` 零横向滚动条；长 URL 与长标识符安全折行；Chip/Badge 可换行或提供键盘可访问的 `+n` 展开。

## 门禁 4：状态机单测（AUTO）

`vitest run` 通过，仅覆盖状态迁移函数、数据转换与 Zod 校验。**禁止** RTL 查询断言与 DOM 快照，违者记 `FAIL`。工具缺失记 `SKIP（vitest 不可用）`。

## 门禁 5：A11y CRITICAL（AUTO）

焦点环保留 `focus-visible:ring`；`<Button size="icon">` 必须有 `aria-label`；表单错误必须 `aria-describedby` 就近关联；装饰性图标必须 `aria-hidden`。

## 门禁 6：触控热区与微交互（AUTO）

可交互元素热区 ≥44×44px、相邻间距 ≥8px、带 `cursor-pointer`；过渡时长落在 150–250ms；存在 `motion-reduce:` 降级；不存在仅 `hover:` 才可达的关键功能。

## 门禁 7：反模式清零（AUTO）

零 Emoji 充当图标（统一同线宽 SVG）；未违反 `ui-spec.md` 第 6 节的任一 `AVOID` 条目。

## 门禁 8：沙箱高保真对齐（MANUAL）

实现与 `sandbox-preview.html` 在色彩情绪、字体层级、留白密度、微动效表现上无显著偏差。Light 与 Dark 各确认一次。

## 产出

写 `openspec/changes/<change>/verify.md`：

- 每项一行：`门禁 N | PASS|FAIL|SKIP | AUTO|MANUAL | 证据或原因`。
- `SKIP` 必须附原因；`MANUAL` 未确认时整体结论不得为 `PASS`。
- 结论取值：`PASS` / `PASS WITH WARNINGS` / `FAIL`。
- 任一 CRITICAL 项 `FAIL` → 结论 `FAIL` 且阻断归档；按失败项打回 apply 对应阶段（门禁 2/5/6 → Stage 1；门禁 4 → Stage 2）。
