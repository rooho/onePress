---
name: onepress-discipline
description: onePress 执行纪律（Cursor 载体）——ui_contract 契约推导、Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆
---

# onePress 执行纪律（onepress-discipline）

> 本技能承载 Cursor 侧全部 onePress 纪律：**契约先行（ui_contract）+ 四条实现铁律 + TDD 纪律**。OpenCode 侧由 `superpowers-tdd` 技能（实现铁律）与 `ux-architect` subagent（契约推导）分担，两侧语义等价的判定口径是"契约 + 铁律 + TDD"三项齐全。

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

## 铁律 5：契约先行（ui_contract）

任何涉及页面的需求，MUST 先在 `openspec/changes/<change>/design.md` 底部写出 `ui_contract` YAML 块（**严禁超过 40 行**），再写代码；契约未经人工确认不得进入 apply。**严禁让程序员手动构思排版。**

字段口径（与 OpenCode 侧 `ux-architect` 逐字同构）：

| 字段 | 必填 | 约束 |
|------|------|------|
| `archetype` | 是 | 5 选 1：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`，严禁自由发明顶层布局 |
| `reuse_components` | 是 | 先扫 `docs/ui-components.md`，可复用组件必须列入，严禁重复造组件 |
| `schema_mapping` | 是 | 后端字段逐字段映射 `field` / `type` / `widget` / `rule` / `fallback`（空值降级，严禁渲染 NaN/undefined） |
| `states_matrix.query` | 是 | `loading`（Skeleton 等高防 CLS）/ `empty`（EmptyState + 重置）/ `error`（Alert + 重试） |
| `states_matrix.mutation` | 是 | `submitting`（disabled + Loader2）/ `destructive_guard`（AlertDialog 二次确认） |
| `layout_tokens` | 是 | `container` / `card` / `mobile_rule`，只允许 Tailwind 标准 class 与 Shadcn CSS 变量 |

```yaml
ui_contract:
  archetype: "Standard-CRUD-Table"
  reuse_components:
    - "@/components/biz/data-table-toolbar"
  schema_mapping:
    - field: "user.role"
      type: "Enum(admin, member)"
      widget: "Select"
      rule: "required | default: member"
    - field: "account.balance"
      type: "Number"
      widget: "Badge(variant='outline')"
      fallback: "'--' (严禁渲染 NaN/undefined)"
  states_matrix:
    query:
      loading: "5行 <Skeleton className='h-10 w-full' />"
      empty: "<EmptyState /> + 重置筛选按钮"
      error: "<Alert variant='destructive' /> + 重试按钮"
    mutation:
      submitting: "主按钮 disabled + 前置 <Loader2 className='animate-spin' />"
      destructive_guard: "删除操作必须包裹 <AlertDialog variant='destructive' />"
  layout_tokens:
    container: "max-w-7xl mx-auto p-6 space-y-6"
    card: "p-6 space-y-4 rounded-lg border bg-card shadow-sm"
    mobile_rule: "<md 视口下 Grid 折叠为 grid-cols-1，表格包裹 overflow-x-auto"
```

**人工复核点**：契约产出后只核对「字段映射 / 状态矩阵 / 复用组件」三项，此时还没有代码。归档时把本次新建或改造的组件增量追加到 `docs/ui-components.md`。

## TDD 纪律

- 仅对纯逻辑层（数据转换、Zod 校验、状态机函数）执行 TDD：先写失败测试，再写实现。
- DOM 渲染单测不做，四态验收靠浮动 State Bar 肉眼点检。
