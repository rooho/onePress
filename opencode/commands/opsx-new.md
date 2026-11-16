---
description: onePress 契约初始化——需求分流、设计检索、ui-spec 六章节契约与高保真沙箱
agent: ux-architect
---

为一个新变更（`$ARGUMENTS`）执行 onePress 契约初始化，严格按以下顺序，不得跳步。

## Step 0：需求类型判定

命中任一条即判定为 UI 变更（`ui_change: yes`）：

1. 新增或修改路由、页面；
2. 新增或修改表格列、表单字段、状态展示；
3. 涉及删除/覆盖等破坏性操作的交互变更。

把结论写入 `openspec/changes/<change>/proposal.md` 首行：`**UI Change**: yes` 或 `**UI Change**: no`。

判定为 `no` 时：只产出 `proposal.md` 与 `design.md`，**不得**创建 `ui-spec.md`、**不得**创建 `sandbox-preview.html`、**不得**调用任何检索，直接结束。

## Step 1：读取全局设计基线

读 `docs/design-system/projectbaseline/MASTER.md`。不存在则一次性生成：

```bash
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "<产品类型与风格关键词>" \
  --design-system --variance 4 --motion 3 --density 8 \
  --persist -p "ProjectBaseline" --output-dir "./docs"
```

`python3` 或技能目录缺失时输出 `SKIP: ui-ux-pro-max 不可用`，继续执行（改为手工填写，不得中断）。

生成后 MUST 立即把顶部 Banner 的 `design-system/pages/[page-name].md` 替换为 `openspec/changes/[change-name]/ui-spec.md (DO NOT create design-system/pages/*.md)`；`MASTER.md` 已存在时只告警、不得改写。清理伴生技能与测试夹具属于可选层手工 runbook，不得自动 `rm -rf`。

## Step 2：双步检索（先语义 UX，后技术栈实现）

```bash
# 语义 UX：交互、无障碍、防破版、溢出
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "keyboard focus dialog accessible" --domain ux
# 技术栈：Shadcn 组件写法
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "data table empty state shadcn" --stack shadcn
# 技术栈：Tailwind 响应式与排版
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "responsive dashboard layout html" --stack html-tailwind
```

每次 2–5 个**英文**领域词（优先 `dashboard` / `data_heavy` / `checkout` / `booking` / `mobile` / `luxury`），禁止中文查询；0 命中时缩窄关键词重试一次并记录。`--json` 可选；动效只取 150–250ms 时长/缓动/交错，除非 `package.json` 已声明 `gsap` 否则不得引入 GSAP。

## Step 3：生成 proposal 与 design

- `proposal.md`：Why / What Changes / Capabilities / Impact（首行为 Step 0 的 `**UI Change**:`）。
- `design.md`：按 `templates/design.md` 写，**不得**在其中内联 UI 契约。

## Step 4：生成 ui-spec.md

先扫 `docs/ui-components.md`（四列：组件名称 / 路径 / 适用骨架 (Archetype) / 核心 Props 签名），可复用组件必须写入第 1 节。

再按 `openspec/schemas/superspec/templates/ui-spec.md` 生成 `openspec/changes/<change>/ui-spec.md`，七章节全部填写，第 3 行固定为 `> Review-Status: PENDING`：

1. 组件层级拆解（Pattern、Container/View 边界、复用组件）
2. Design Token 映射（16 个语义色彩通道的 Light/Dark 取值、Google Fonts 主副字体配对、`xs`–`3xl` 间距表、图标库与描边）
3. 四态状态机矩阵（含时序与防抖规则）
4. 响应式断点与排版（含防破版约束）
5. 交互热点与微动效（≥44×44px、200–250ms 悬停、150ms 按压、`prefers-reduced-motion`）
6. 行业反模式黑名单（检索 `AVOID` 条目，一票否决）
7. 沙箱预览（`#sandbox-control-bar`、`data-set-state/theme`、`<main>`、`data-review-id`、Pin-to-AI）

## Step 5：生成 sandbox-preview.html

生成 `openspec/changes/<change>/sandbox-preview.html`，单文件（inline CSS + JS），必须含：

1. `#sandbox-control-bar`：`[data-set-state="idle|loading|empty|error"]` 四态按钮与 `[data-set-theme="light|dark"]` 主题按钮；
2. `<main>` landmark，关键可交互元素带 `data-review-id`；
3. 第 2 节的 16 个色彩变量与间距变量（CSS 自定义属性）；
4. 第 2 节选定的 Google Fonts `<link>`；
5. `prefers-reduced-motion` 降级规则；
6. `Alt/⌘ + Click` Pin-to-AI 批注器（选择器优先 `data-review-id`，clipboard 失败回退 `execCommand('copy')`）。

沙箱只作为视觉参照与验收基准，MUST NOT 作为 Stage 1 的代码来源。
