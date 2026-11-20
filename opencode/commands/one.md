---
description: "onePress 用户层单入口：/one <子命令> 转发到规范全名（12 个官方技能 + 1 个 onePress 命令）"
---

# /one `<子命令>` [参数...]

用户层单入口。只做转发：调用对应规范全名并完整执行其原有流程，**MUST NOT 复制或改写上游步骤**。

## 转发表

| 子命令 | 目标 | 类型 |
|---|---|---|
| `propose` | `openspec-propose` | 技能 |
| `explore` | `openspec-explore` | 技能 |
| `new` | `openspec-new-change` | 技能 |
| `continue` | `openspec-continue-change` | 技能 |
| `ff` | `openspec-ff-change` | 技能 |
| `update` | `openspec-update-change` | 技能 |
| `apply` | `openspec-apply-change` | 技能 |
| `verify` | `openspec-verify-change` | 技能 |
| `sync` | `openspec-sync-specs` | 技能 |
| `archive` | `openspec-archive-change` | 技能 |
| `bulk-archive` | `openspec-bulk-archive-change` | 技能 |
| `onboard` | `openspec-onboard` | 技能 |
| `review` | `/openspec-review-change` | onePress 命令 |

## 执行规则

1. 取第一个参数作为子命令，其余参数原样透传给目标。
2. `类型` 为「技能」时，用 Skill 工具加载该技能并按其流程完整执行。
3. `类型` 为「onePress 命令」时，执行对应斜杠命令；它不是技能，MUST NOT 当作技能名加载。
4. 子命令缺失、未知或大小写/拼写不完全匹配时，输出完整转发表并以非零结果结束；MUST NOT 猜测意图、MUST NOT 落到任何默认工作流。
5. 上游流程的步骤、验收项与红线一律以目标技能/命令为准，本文件不重复其内容。
