---
description: "onePress 用户入口：/op-explore 转发到 openspec-explore（只转发，不改写上游）"
---

# /op-explore [参数...]

用户入口。只做转发：调用 `openspec-explore` 并完整执行其原有流程，**MUST NOT 复制或改写上游步骤**。

## 目标

- 类型：`技能`
- 目标：`openspec-explore`

## 执行规则

1. 其余参数原样透传给目标。
2. 类型为「技能」时，用 Skill 工具加载该技能并按其流程完整执行。
3. 类型为「命令」时，执行对应斜杠命令；它不是技能，MUST NOT 当作技能名加载。
4. 未知或大小写/拼写不完全匹配的入口 MUST NOT 猜测意图，MUST NOT 落到任何默认工作流。
5. 上游流程的步骤、验收项与红线一律以目标为准，本文件不重复其内容。
