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

## Step 2：双步检索（先语义 UX，后技术栈实现）

```bash
# 语义 UX：交互、无障碍、防破版、溢出
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "<交互或无障碍关键词>" --domain ux
# 技术栈：Shadcn 组件写法
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "<组件关键词>" --stack shadcn
# 技术栈：Tailwind 响应式与排版
python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "<响应式或排版关键词>" --stack html-tailwind
```

每次聚焦 1 个主导意图、2–5 个关键词，禁止一次塞入整段需求描述。

## Step 3：生成 proposal 与 design

- `proposal.md`：Why / What Changes / Capabilities / Impact（首行为 Step 0 的 `**UI Change**:`）。
- `design.md`：按 `templates/design.md` 写，**不得**在其中内联 UI 契约。

## Step 4：生成 ui-spec.md

先扫 `docs/ui-components.md`（四列：组件名称 / 路径 / 适用骨架 (Archetype) / 核心 Props 签名），可复用组件必须写入第 1 节。

再按 `openspec/schemas/superspec/templates/ui-spec.md` 生成 `openspec/changes/<change>/ui-spec.md`，六章节全部填写：

1. 组件层级拆解（Pattern、Container/View 边界、复用组件）
2. Design Token 映射（16 个语义色彩通道的 Light/Dark 取值、Google Fonts 主副字体配对、`xs`–`3xl` 间距表、图标库与描边）
3. 四态状态机矩阵（含时序与防抖规则）
4. 响应式断点与排版（含防破版约束）
5. 交互热点与微动效（≥44×44px、200–250ms 悬停、150ms 按压、`prefers-reduced-motion`）
6. 行业反模式黑名单（检索 `AVOID` 条目，一票否决）

## Step 5：生成 sandbox-preview.html

生成 `openspec/changes/<change>/sandbox-preview.html`，单文件（inline CSS + JS），必须含：

1. `Idle` / `Loading` / `Empty` / `Error` 四态切换按钮；
2. `Light` / `Dark` 主题切换开关；
3. 第 2 节的 16 个色彩变量与间距变量（CSS 自定义属性）；
4. 第 2 节选定的 Google Fonts `<link>`；
5. `prefers-reduced-motion` 降级规则。

沙箱只作为视觉参照与验收基准，MUST NOT 作为 Stage 1 的代码来源。
