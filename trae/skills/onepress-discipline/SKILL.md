---
name: onepress-discipline
description: onePress 执行纪律（Trae 载体）——ui-spec 契约推导、Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆、编码前三级评审
---

# onePress 执行纪律（onepress-discipline）

> 本技能承载 Trae 侧全部 onePress 纪律：**契约先行（ui-spec.md）+ 需求分流 + 设计检索 + 高保真沙箱 + 八项门禁 + 编码前三级评审 + 四条实现铁律 + TDD 纪律**。OpenCode 侧由 `superpowers-tdd` 技能（实现铁律）与 `ux-architect` subagent（契约推导）分担，两侧语义等价的判定口径是"契约 + 铁律 + 检索 + 沙箱 + 门禁 + 评审 + TDD"七项齐全。

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

任何判定为 UI 变更的需求，MUST 先产出 `openspec/changes/<change>/ui-spec.md`（七章节全部必填，第 3 行为 `> Review-Status: PENDING`），再写代码。**严禁让程序员手动构思排版，也严禁凭空猜测配色与间距。**

| 章节 | 必填内容 |
|------|----------|
| 1 组件层级拆解 | 页面布局 Pattern（Bento Grid / Swiss Grid 12–16 列等）、Container 与 View 边界、复用组件（来自 `docs/ui-components.md`） |
| 2 Design Token 映射 | 16 个语义色彩通道的 Light 与 Dark 取值；`On *` 角色 MUST 重命名为 `--primary-foreground` / `--secondary-foreground` / `--accent-foreground` / `--destructive-foreground`；`.dark` 取值策略（Background `#0F172A`、Card `#111827`、Muted Foreground `#CBD5E1`、Border `#334155`、Ring ≥3:1）；Google Fonts 主副字体配对（正文 16px、行高 1.5）；`xs`–`3xl` 间距表；图标库与描边粗细 |
| 3 四态状态机矩阵 | 每个数据组件的 Idle / Loading / Empty / Error 表现；禁止 0ms 跳变；Loading 预留骨架（CLS < 0.1）；表单 Error 内联且带图标或文字 |
| 4 响应式与排版 | `sm` / `md` / `lg` / `xl` 断点规则；长 URL 与长标识符安全折行；Chip/Badge 支持换行或 `+n` 展开 |
| 5 交互热点与微动效 | 最小热区 ≥44×44px、间距 ≥8px；悬停 200–250ms、按压 150ms；禁仅 Hover；尊重 `prefers-reduced-motion`；非 gsap 项目禁止引入 GSAP |
| 6 行业反模式黑名单 | 来自检索结果的 `AVOID` 条目，作为一票否决项 |
| 7 沙箱预览 | `sandbox-preview.html` 的控制栏、双主题、Token 变量、Pin-to-AI 批注器与 `data-review-id` 要求 |

Tailwind v4 项目 MUST 在 `:root` / `.dark` 定义变量，并在 `@theme inline` 声明 `--color-primary: var(--primary)` 等映射。

**严禁**把 UI 契约写回 `design.md`：`ui-spec.md` 是唯一真源。

## 铁律 6：需求分流

`/opsx:new` MUST 先判定需求类型，把结论写入 `proposal.md` 的 `**UI Change**: yes|no` 行（内部字段名 `ui_change`）。命中任一条即 `yes`：① 新增或修改路由、页面；② 新增或修改表格列、表单字段、状态展示；③ 涉及删除/覆盖等破坏性操作的交互变更。

`no` 时 MUST NOT 生成 `ui-spec.md`、MUST NOT 生成 `sandbox-preview.html`、MUST NOT 触发设计检索，直接走标准后端 TDD。

## 铁律 7：设计检索与降级

UI 变更 MUST 先读 `docs/design-system/projectbaseline/MASTER.md`；不存在则一次性生成：

```bash
python3 .trae/skills/ui-ux-pro-max/scripts/search.py \
  "B2B SaaS analytics dashboard data_heavy modern clean" \
  --design-system --variance 4 --motion 3 --density 8 \
  --persist -p "ProjectBaseline" --output-dir "./docs"
```

生成后 MUST 立即把顶部 Banner 的 `design-system/pages/[page-name].md` 替换为 `openspec/changes/[change-name]/ui-spec.md (DO NOT create design-system/pages/*.md)`；`MASTER.md` 已存在时只告警、MUST NOT 改写。

随后按**双步**检索，每次 2–5 个**英文**领域词（优先 `dashboard` / `data_heavy` / `checkout` / `booking` / `mobile` / `luxury`），0 命中时缩窄关键词重试一次：

```bash
# 第一步：语义 UX（交互、无障碍、防破版）
python3 .trae/skills/ui-ux-pro-max/scripts/search.py "keyboard focus dialog accessible" --domain ux
# 第二步：技术栈实现（Shadcn / Tailwind）
python3 .trae/skills/ui-ux-pro-max/scripts/search.py "data table empty state shadcn" --stack shadcn
```

- `--json` 可选：脚本解析用 `--json`，人工阅读用默认表格。
- 动效：`--motion` 只取 150–250ms 时长、缓动与交错延迟；除非 `package.json` 已声明 `gsap`，否则 MUST NOT 引入 GSAP。
- 可选层清理（README 手工 runbook，非自动执行）：启用 `ui-ux-pro-max` 后可手工删除 6 个伴生技能目录与 `scripts/tests`、`validate_data.py`；MUST NOT 在安装或评审流程中自动 `rm -rf`。
- `python3` 或技能目录缺失时 MUST 输出 `SKIP: ui-ux-pro-max 不可用`，改为手工填写 `ui-spec.md`，**不得中断流程**。

## 铁律 8：高保真沙箱 + 沙箱即生产两阶段

**沙箱**：MUST 生成单文件 `openspec/changes/<change>/sandbox-preview.html`（inline CSS + JS），内含：

1. `#sandbox-control-bar`：`[data-set-state="idle|loading|empty|error"]` 四态按钮与 `[data-set-theme="light|dark"]` 主题按钮；
2. `<main>` landmark；关键可交互元素带 `data-review-id`；
3. `ui-spec.md` 第 2 节的 16 个色彩变量与间距变量；
4. 选定的 Google Fonts `<link>`；
5. `prefers-reduced-motion` 降级；
6. `Alt/⌘ + Click` Pin-to-AI 批注器（零依赖原生 JS；选择器优先 `data-review-id`；clipboard 失败回退 `execCommand('copy')`；SVG 目标做 `className` 类型守卫）。

**Stage 1（UI 底座直出）**：直接写生产级 `[Feature]View.tsx`，100% Props 受控（数据、`status`、`isSubmitting`、回调全经 Props）。MUST NOT 从沙箱 HTML 转译，MUST NOT 注入 in-app 浮动 State Bar。

**Stage 2（接线）**：只写 Hook / Container 接真实数据，`[Feature]View.tsx` 的结构与 class 集合 MUST NOT 改动。

## 铁律 9：八项门禁（0–8 + 0.5）

`/opsx:verify` MUST 逐项记录 `PASS` / `FAIL` / `SKIP` 与 `AUTO` / `MANUAL`：

| # | 门禁 | 方式 |
|---|------|------|
| 0 | UI 变更必有 `ui-spec.md` 与 `sandbox-preview.html` | AUTO |
| 0.5 | `Review-Status` 必须为 `APPROVED`（编码前由 `/opsx:review` 签署） | AUTO |
| 1 | 四态一致性与防抖（CLS < 0.1） | MANUAL |
| 2 | Token 100% 覆盖 + Light/Dark 对比度 ≥4.5:1（大字与边界 ≥3:1） | AUTO |
| 3 | 断点零横向滚动、长串折行、Chip/Badge 可展开 | MANUAL |
| 4 | 纯逻辑状态机单测通过（禁 RTL / DOM 快照） | AUTO |
| 5 | A11y CRITICAL：焦点环、`aria-label`、`aria-describedby`、装饰图标 `aria-hidden` | AUTO |
| 6 | 热区 ≥44×44px、`cursor-pointer`、150–250ms、`motion-reduce:` | AUTO |
| 7 | 反模式清零：零 Emoji 图标、未违反第 6 节黑名单 | AUTO |
| 8 | 实现与沙箱无显著视觉偏差 | MANUAL |

`SKIP` MUST 附原因；`MANUAL` 未确认时整体结论 MUST NOT 为 `PASS`；CRITICAL 项 `FAIL` MUST 阻断归档。

可执行脚本：`bash scripts/onepress-gate.sh`（门禁 0/0.5/2/4/5/6/7 自动，1/3/8 输出 `MANUAL`）。默认对 `UI Change: yes` 强制校验门禁 0.5；`--require-review` 供 CI 固定语义，`--no-require-review` 仅用于 1.1.0 之前的旧变更。

## 铁律 10：编码前三级评审（/opsx:review）

UI 变更 MUST 在 `/opsx:apply` 之前执行 `/opsx:review <change-name>`，按 L1 → L2 → L3 推进，并把结果写入 `review.md`：

- **L1 确定性预检**：Playwright + `@axe-core/playwright` 遍历 4 态 × 2 主题 8 视图；WCAG 2.2 A/AA 零 violations；热区 ≥44×44（项目标准，行内文本链接豁免）；375/768/1024/1280 零横向溢出；变量声明块外零 Hex、零 Emoji；CLS 以 `PerformanceObserver` 采样（代理指标）。依赖缺失记 `L1: SKIP`，不阻断。
- **L2 冷上下文盲审**：输入仅 `MASTER.md`、`ui-spec.md`、`sandbox-preview.html`、`review-rubric.md`；主判据 `P0 = 0 且 P1 = 0`，单层列表 ≤8、单决策点 ≤4；每条 finding MUST 引用章节或选择器，无证据不计分；Critique 40 / Audit 20 为观察模式；最多 3 轮，超限 `ESCALATE`。
- **L3 人类批注与锁定**：沙箱 `Alt/⌘ + Click` 输出"选择器 + 类名 + HTML 片段 + 批注"，经 `/opsx:update` 回写；只有人类可把 `ui-spec.md` 的 `Review-Status` 改为 `APPROVED`，Agent MUST NOT 自签。
- `review.md` MUST 含 `Round` / `L1` / `L2` / `L3` / `Critique` / `Audit` / `P0`–`P3` 与带证据列的 `Findings` 表；`Review-Status` 非 `APPROVED` 时 `/opsx:apply` MUST 停止。

## TDD 纪律

- 仅对纯逻辑层（数据转换、Zod 校验、状态机函数）执行 TDD：先写失败测试，再写实现。
- DOM 渲染单测不做，四态验收靠沙箱对照肉眼点检。
