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

## V3.2 执行铁律

- **TDD 铁律**：含逻辑修改的任务 MUST 先写失败测试并实际运行、取得 RED 输出，之后才允许写生产代码；声称 GREEN 但无 RED 运行记录时，MUST 删除该生产代码并退回 RED。纯文档/配置任务 MUST 在 `apply.md` 记录 `TDD: N/A (<reason>)`。
- **根因调试铁律**：出现非预期失败或连续两次修复无效时 MUST 停止打补丁，按「证据收集 → 数据流回溯 → 单一假设 → 最小实验」四阶段溯源；假设被证伪后 MUST 回退到原始错误状态再重新假设，诊断记录写入 `apply.md` 的 `Root-Cause Log`。
- **实时证据**：每个任务完成时 MUST 在 `apply.md` 粘贴真实命令输出与退出码；MUST NOT 使用「应该能通过」「看起来正确」等推测性措辞。

## V3.2 验证双锁

- **证据报告**：`/openspec-verify-change` 之前 MUST 存在 `verification-evidence.md`（`verify-report` 工件），含实测命令、退出码、通过数与 `Critical: 0` / `Important: 0`；`bash scripts/onepress-evidence-lint.sh --change <change-name>` MUST 退出 0。
- **冷上下文盲审**：`verify-report` MUST 在 `BASE_SHA..HEAD_SHA` 上执行一次只读代码盲审，输入仅 diff + `design.md` + `tasks.md` + `specs/**`；协议见 `openspec/schemas/superspec/templates/code-reviewer.md`；有子代理则派生零历史子代理，否则生成 `code-review-packet.md` 交人类新会话评审。`Critical`/`Important` > 0 MUST 回到 apply 修复。
- **反馈处置**：MUST NOT 表演性同意；逐条对照代码接受或以证据反驳；`Minor` 记录但不阻断。

## V3.2 任务与设计契约

- `tasks.md` 每条任务 MUST 为 2–5 分钟粒度，MUST 标注反引号文件路径与验证命令；逻辑任务 MUST 内嵌 `RED` / `GREEN` / `REFACTOR` 三个勾选；纯文档/配置任务 MUST 写 `TDD: N/A (<reason>)`。
- `design.md`（若产出）MUST 含 ADR（Context / Decision / Alternatives / Rationale / Consequences）、3–5 条 Non-Goals 与 Risks / Trade-offs；`specs/**` 每条需求 MUST 含 Given/When/Then 场景。

## 归档纪律

- `/openspec-archive-change` 时把本次新建或改造的可复用组件追加一行到 `docs/ui-components.md`，列固定为 `组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名`；只追加，不重排、不删历史。
- 归档前必须存在 `verify.md` 且结论非 `FAIL`；`MANUAL` 项未确认时不得归档。

## 门禁纪律

- `bash scripts/onepress-gate.sh` 实现门禁 2/4/5/6/7；门禁 0/1/3/8 由命令体与人工承担。
- 任何 `SKIP` 必须附原因；`MANUAL` 不得被默认为通过。

