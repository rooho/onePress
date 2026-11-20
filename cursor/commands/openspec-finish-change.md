---
name: "openspec-finish-change"
description: "[internal] onePress 组合收尾命令：一次确认串行执行 verify-report → verify → finalize"
---

# /openspec-finish-change `<change-name>`

> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。

组合收尾入口：把 `verify-report`、`verify`、`finalize` 三个步骤串成**一次交互**。本命令只做编排，MUST NOT 复制或改写三个工件的规则；各步的验收标准以 `schema.yaml` 与 `templates/` 中的对应工件为准。

## 执行顺序

1. **verify-report**：按 `verification-evidence.md` 的规则采集证据（`bash scripts/onepress-verify.sh --change <change-dir>`）、运行 `onepress-evidence-lint.sh`、完成冷上下文评审并写回 `review-ledger.md`。
2. **证据短路**：若证据判定为 `Critical > 0` 或 `Important > 0`，立即停止并输出“回到 apply”，MUST NOT 进入第 3 步。
3. **verify**：执行 `verify.md` 的 5 项检查（结构校验 / 任务完成 / delta 同步 / 设计一致性 / 提交状态），给出 `PASS`、`PASS WITH WARNINGS` 或 `FAIL`。
4. **验证短路**：`FAIL` 时停止并输出回到 apply 的下一步；`PASS` 与 `PASS WITH WARNINGS` 继续。
5. **finalize**：按 `finalize.md` 执行 git 收尾；feature 分支 / worktree 等结构前置不满足时走 escape hatch，并在 `finalize.md` 记录所选模式。

## 交互约定

- 全流程只向用户请求**一次确认**：先展示三步计划，确认后连续执行，不再逐步询问。
- 任一步失败即停止，输出“已完成 / 卡在哪一步 / 下一步动作”，不自动回滚。
- 三个工件仍分别落盘：`verification-evidence.md`、`verify.md`、`finalize.md`；审计粒度不变。
- 单独执行 `verify-report`、`verify`、`finalize` 仍然有效；本命令等价于按序调用它们。
