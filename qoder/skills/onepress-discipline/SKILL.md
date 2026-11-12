---
name: onepress-discipline
description: onePress 执行纪律（Qoder 载体）——ui-spec 契约推导、Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆
---

# onePress 执行纪律（onepress-discipline）

> 本技能承载 Qoder 侧全部 onePress 纪律：**契约先行（ui-spec.md）+ 需求分流 + 设计检索 + 高保真沙箱 + 八项门禁 + 四条实现铁律 + TDD 纪律**。OpenCode 侧由 `superpowers-tdd` 技能（实现铁律）与 `ux-architect` subagent（契约推导）分担，两侧语义等价的判定口径是"契约 + 铁律 + 检索 + 沙箱 + 门禁 + TDD"六项齐全。

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

## 铁律 5：契约先行（ui-spec.md）

任何判定为 UI 变更的需求，MUST 先产出 `openspec/changes/<change>/ui-spec.md`（六章节全部必填），再写代码。**严禁让程序员手动构思排版，也严禁凭空猜测配色与间距。**

| 章节 | 必填内容 |
|------|----------|
| 1 组件层级拆解 | 页面布局 Pattern（Bento Grid / Swiss Grid 12–16 列等）、Container 与 View 边界、复用组件（来自 `docs/ui-components.md`） |
| 2 Design Token 映射 | 16 个语义色彩通道（Primary / On Primary / Secondary / On Secondary / Accent / On Accent / Background / Foreground / Card / Card Foreground / Muted / Muted Foreground / Border / Destructive / On Destructive / Ring）的 Light 与 Dark 取值；Google Fonts 主副字体配对（正文 16px、行高 1.5）；`xs`–`3xl` 间距表；图标库与描边粗细 |
| 3 四态状态机矩阵 | 每个数据组件的 Idle / Loading / Empty / Error 表现；禁止 0ms 跳变；Loading 预留骨架（CLS < 0.1）；表单 Error 内联且带图标或文字 |
| 4 响应式与排版 | `sm` / `md` / `lg` / `xl` 断点规则；长 URL 与长标识符安全折行；Chip/Badge 支持换行或 `+n` 展开 |
| 5 交互热点与微动效 | 最小热区 ≥44×44px、间距 ≥8px；悬停 200–250ms、按压 150ms；禁仅 Hover；尊重 `prefers-reduced-motion` |
| 6 行业反模式黑名单 | 来自检索结果的 `AVOID` 条目，作为一票否决项 |

**严禁**把 UI 契约写回 `design.md`：`ui-spec.md` 是唯一真源。

## 铁律 6：需求分流

`/opsx:new` MUST 先判定需求类型，把结论写入 `proposal.md` 的 `**UI Change**: yes|no` 行（内部字段名 `ui_change`）。命中任一条即 `yes`：① 新增或修改路由、页面；② 新增或修改表格列、表单字段、状态展示；③ 涉及删除/覆盖等破坏性操作的交互变更。

`no` 时 MUST NOT 生成 `ui-spec.md`、MUST NOT 生成 `sandbox-preview.html`、MUST NOT 触发设计检索，直接走标准后端 TDD。

## 铁律 7：设计检索与降级

UI 变更 MUST 先读 `docs/design-system/projectbaseline/MASTER.md`；不存在则一次性生成（`--design-system --persist -p "ProjectBaseline" --output-dir "./docs"`）。

随后按**双步**检索，每次聚焦 1 个主导意图、2–5 个关键词：

```bash
# 第一步：语义 UX（交互、无障碍、防破版）
python3 .qoder/skills/ui-ux-pro-max/scripts/search.py "<交互或无障碍关键词>" --domain ux
# 第二步：技术栈实现（Shadcn / Tailwind）
python3 .qoder/skills/ui-ux-pro-max/scripts/search.py "<组件关键词>" --stack shadcn
```

`python3` 或技能目录缺失时 MUST 输出 `SKIP: ui-ux-pro-max 不可用`，改为手工填写 `ui-spec.md`，**不得中断流程**。

## 铁律 8：高保真沙箱 + 沙箱即生产两阶段

**沙箱**：MUST 生成单文件 `openspec/changes/<change>/sandbox-preview.html`（inline CSS + JS），内含 ① Idle/Loading/Empty/Error 四态切换按钮；② Light/Dark 切换开关；③ `ui-spec.md` 第 2 节的 16 个色彩变量与间距变量；④ 选定的 Google Fonts `<link>`；⑤ `prefers-reduced-motion` 降级。

**Stage 1（UI 底座直出）**：直接写生产级 `[Feature]View.tsx`，100% Props 受控（数据、`status`、`isSubmitting`、回调全经 Props）。MUST NOT 从沙箱 HTML 转译，MUST NOT 注入 in-app 浮动 State Bar。

**Stage 2（接线）**：只写 Hook / Container 接真实数据，`[Feature]View.tsx` 的结构与 class 集合 MUST NOT 改动。

## 铁律 9：八项门禁

`/opsx:verify` MUST 逐项记录 `PASS` / `FAIL` / `SKIP` 与 `AUTO` / `MANUAL`：

| # | 门禁 | 方式 |
|---|------|------|
| 0 | UI 变更必有 `ui-spec.md` 与 `sandbox-preview.html` | AUTO |
| 1 | 四态一致性与防抖（CLS < 0.1） | MANUAL |
| 2 | Token 100% 覆盖 + Light/Dark 对比度 ≥4.5:1（大字与边界 ≥3:1） | AUTO |
| 3 | 断点零横向滚动、长串折行、Chip/Badge 可展开 | MANUAL |
| 4 | 纯逻辑状态机单测通过（禁 RTL / DOM 快照） | AUTO |
| 5 | A11y CRITICAL：焦点环、`aria-label`、`aria-describedby`、装饰图标 `aria-hidden` | AUTO |
| 6 | 热区 ≥44×44px、`cursor-pointer`、150–250ms、`motion-reduce:` | AUTO |
| 7 | 反模式清零：零 Emoji 图标、未违反第 6 节黑名单 | AUTO |
| 8 | 实现与沙箱无显著视觉偏差 | MANUAL |

`SKIP` MUST 附原因；`MANUAL` 未确认时整体结论 MUST NOT 为 `PASS`；CRITICAL 项 `FAIL` MUST 阻断归档。

可执行脚本：`bash scripts/onepress-gate.sh`（实现门禁 2/4/5/6/7，其余输出 `MANUAL`）。

## TDD 纪律

- 仅对纯逻辑层（数据转换、Zod 校验、状态机函数）执行 TDD：先写失败测试，再写实现。
- DOM 渲染单测不做，四态验收靠浮动 State Bar 肉眼点检。
