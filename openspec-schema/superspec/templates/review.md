# Review — `<change-name>`

> This file is the `review` DAG artifact. It is written only when the
> review converges (`Result: PASS`) or when the change is non-UI
> (`Result: SKIP`). Failed rounds live in `.review/round-<n>.md`.

- **Result**: `PASS` | `SKIP (UI Change: no)`
- **UI Change**: `yes` | `no`
- **Round**: `<n>` / 3
- **L1**: `PASS` | `FAIL` | `SKIP (<reason>)`
- **L2**: `PASS` | `FAIL` | `SKIP` | `FALLBACK (<reason>)`
- **L3**: `APPROVED (<approver>, <ISO date>)` | `N/A (non-UI)`
- **P0**: `0`  **P1**: `0`  **P2**: `<n>`  **P3**: `<n>`
- **Critique**: `<x>/40 (observation)`
- **Audit**: `<y>/20 (observation)`
- **ui-spec-sha256**: `<64 hex chars>`
- **sandbox-sha256**: `<64 hex chars>`
- **plan-sha256**: `<64 hex chars>`
- **Review-Status**: `APPROVED` | `N/A (non-UI)`
- **Reviewed-At**: `<ISO timestamp>`

## Findings

| # | 级别 | 证据（ui-spec 章节 / DOM 选择器） | 问题 | 建议 |
|---|------|-----------------------------------|------|------|
| 1 | `P0`–`P3` |  |  |  |

## 结论

`PASS`：P0 = 0、P1 = 0，人类已批准，三个哈希与当前文件一致。

`SKIP`：非 UI 变更，未生成 `ui-spec.md` 与沙箱，无需评审。

## 失效规则

`ui-spec.md`、`sandbox-preview.html` 或 `plan.md` 任一文件发生变化时，本文件失效：
删除 `review.md`，把 `ui-spec.md` 第 3 行重置为 `> Review-Status: PENDING`，
并重新运行 `review` 工件。复审只需覆盖变更章节。
