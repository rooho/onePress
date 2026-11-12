# UI Spec — `<change-name>`

> 由 `/opsx:new` 在 `**UI Change**: yes` 时生成，六章节全部必填。
> 所有取值必须来自 `docs/design-system/projectbaseline/MASTER.md` 或 `search.py` 检索结果，
> 严禁凭空猜测配色、字体与间距。`**UI Change**: no` 时 MUST NOT 创建本文件。

## 1. 组件层级拆解

**页面布局模式（Pattern）**: `<Bento Grid | Swiss Grid 12–16 列 | ...>`

**页面级容器（Container）**

| 组件 | 文件路径 | 职责 | 持有状态 |
|------|----------|------|----------|
| `<Feature>Container` | `src/features/<feature>/container.tsx` | 数据获取与状态编排 | `status` / `data` / `error` |

**纯渲染组件（View）**

| 组件 | 文件路径 | 职责 | Props 摘要 |
|------|----------|------|-----------|
| `<Feature>View` | `src/features/<feature>/view.tsx` | 纯展示，100% Props 受控 | `data` / `status` / `isSubmitting` / 回调 |

**复用组件（来自 `docs/ui-components.md`）**

| 组件名称 | 路径 | 适用骨架 |
|----------|------|----------|
| `<ComponentName>` | `@/components/biz/<file>` | `<Archetype>` |

## 2. Design Token 映射

### 2.1 语义色彩（16 通道）

| 通道 | Light | Dark | CSS 变量 |
|------|-------|------|----------|
| Primary |  |  | `--primary` |
| On Primary |  |  | `--primary-foreground` |
| Secondary |  |  | `--secondary` |
| On Secondary |  |  | `--secondary-foreground` |
| Accent |  |  | `--accent` |
| On Accent |  |  | `--accent-foreground` |
| Background |  |  | `--background` |
| Foreground |  |  | `--foreground` |
| Card |  |  | `--card` |
| Card Foreground |  |  | `--card-foreground` |
| Muted |  |  | `--muted` |
| Muted Foreground |  |  | `--muted-foreground` |
| Border |  |  | `--border` |
| Destructive |  |  | `--destructive` |
| On Destructive |  |  | `--destructive-foreground` |
| Ring |  |  | `--ring` |

**对比度基线**：`Background/Foreground`、`Card/Card Foreground`、`Muted/Muted Foreground` 三对在 Light 与 Dark 下正文对比度 MUST ≥ 4.5:1，大号文本与控件边界 MUST ≥ 3:1。

### 2.2 字体配对

| 用途 | 字体 | 字重 | 字号 / 行高 | 加载方式 |
|------|------|------|-------------|----------|
| 标题 | `<Heading Font>` | `<600>` | `<24px / 1.3>` | Google Fonts `<link>` |
| 正文 | `<Body Font>` | `<400>` | `16px / 1.5` | Google Fonts `<link>` |

### 2.3 间距密度（`--density <1–10>`）

| Token | 值 | 典型用途 |
|-------|----|----------|
| `xs` |  | 图标与文字间距 |
| `sm` |  | 表单项内部 |
| `md` |  | 卡片内边距 |
| `lg` |  | 区块间距 |
| `xl` |  | 页面分段 |
| `2xl` |  | 大区块分隔 |
| `3xl` |  | 页面级留白 |

### 2.4 图标

- 图标库：`@phosphor-icons/react`（备选 Heroicons / Lucide）
- 描边粗细：`<1.5px 或 2px>`，全站统一
- 严禁使用 Emoji 充当图标

## 3. 四态状态机矩阵

| 组件 | Idle | Loading | Empty | Error |
|------|------|---------|-------|-------|
| `<Feature>View` |  |  |  |  |

**时序与防抖规则**

1. 禁止 0ms 瞬时跳变，状态过渡 MUST 150–250ms。
2. `Loading` MUST 预留等高骨架空间，CLS < 0.1。
3. 表单 `Error` MUST 紧邻输入框内联展示，且带图标或文字，不得仅靠颜色传达。
4. 退出动画 MUST 快于进入动画。

## 4. 响应式断点与排版

| 断点 | 布局规则 |
|------|----------|
| `< sm` |  |
| `sm` |  |
| `md` |  |
| `lg` |  |
| `xl` |  |

**防破版约束**

1. 长 URL / 长标识符 MUST 安全折行（`break-words` / `overflow-wrap: anywhere`），零横向滚动条。
2. 表格 MUST 包裹 `overflow-x-auto`，容器 MUST 设 `min-w-0`。
3. Chip/Badge 组 MUST 自动换行，或提供键盘可访问的 `+n` 展开披露。

## 5. 交互热点与微动效

**动效等级（`--motion <1–10>`）**: `<Subtle | Standard | Complex>`

| 交互 | 触发 | 热区 | 时序 | 缓动 |
|------|------|------|------|------|
| `<主操作>` |  | `≥44×44px` | `150ms` | `ease-out` |
| `<悬停>` | hover |  | `200–250ms` | `ease-out` |

**硬约束**

1. 最小热区 ≥ 44×44px，相邻热区间距 ≥ 8px。
2. 所有可交互元素 MUST 带 `cursor-pointer`，且具备 hover / pressed / disabled 三态。
3. 严禁仅依赖 Hover 暴露功能（键盘与触屏必须可达）。
4. MUST 提供 `prefers-reduced-motion` 降级（Tailwind `motion-reduce:`）。

## 6. 行业反模式黑名单（一票否决）

> 直接摘录 `search.py --design-system` 输出的 `AVOID (Anti-patterns)`，作为编码与门禁 7 的判定依据。

- `<AVOID 条目，例如：禁用紫粉渐变>`
- `<AVOID 条目，例如：禁止灰底灰字>`

## 7. 沙箱预览

- 文件：`openspec/changes/<change>/sandbox-preview.html`（单文件，inline CSS + JS）
- MUST 内置：`Idle` / `Loading` / `Empty` / `Error` 四态切换按钮
- MUST 内置：`Light` / `Dark` 主题切换开关
- MUST 声明：第 2.1 节的 16 个色彩变量与第 2.3 节的间距变量
- MUST 引入：第 2.2 节选定的 Google Fonts `<link>`
- MUST 提供：`prefers-reduced-motion` 降级规则
- 验收标准：实现与沙箱在色彩情绪、字体层级、留白密度、微交互表现上无显著偏差（门禁 8）
