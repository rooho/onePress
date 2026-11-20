---
description: "onePress 用户入口：/op-finish 转发到 /openspec-finish-change（只转发，不改写上游）"
---

# /op-finish [参数...]

用户入口。只做转发：调用 `/openspec-finish-change` 并完整执行其原有流程，**MUST NOT 复制或改写上游步骤**。

## 目标

- 类型：`命令`
- 目标：`/openspec-finish-change`（组合收尾：verify-report → verify → finalize）

## 执行规则

1. 其余参数原样透传给目标。
2. 类型为「技能」时，用 Skill 工具加载该技能并按其流程完整执行。
3. 类型为「命令」时，执行对应斜杠命令；它不是技能，MUST NOT 当作技能名加载。
4. 未知或大小写/拼写不完全匹配的入口 MUST NOT 猜测意图，MUST NOT 落到任何默认工作流。
5. 上游流程的步骤、验收项与红线一律以目标为准，本文件不重复其内容。
6. 组合收尾只在开始时确认一次；证据 `Critical/Important > 0` 或 verify `FAIL` 时短路回到 apply。
