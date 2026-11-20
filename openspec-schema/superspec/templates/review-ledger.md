# Review Ledger — `<change-name>`

> Append-only。代码冷审与修复历史的唯一真源。
> `apply.md` 只保留当前迭代并指向本文件；`verification-evidence.md` 不承载已知非阻断台账。
> 只允许追加行，或更新既有行的 `Status` / `Fix-SHA` / `Action` / `Note`；MUST NOT 删除行，MUST NOT 修改既有行的 `ID` 与 `Fingerprint`。

**Change**: `<change-name>`
**last_reviewed_sha**: `<sha or "none">`
**review_round**: `0`

---

## Findings

| ID | Fingerprint | Level | File | Round | Status | Fix-SHA | Action | Note |
|---|---|---|---|---|---|---|---|---|
| `F-001` | `<path>::<defect-class>` | `Critical` | `<file:line>` | `1` | `open` | — | — | — |

---

## defect-class 受控词表

`Fingerprint` MUST 形如 `<file>::<defect-class>`，其中 `defect-class` MUST 取自：

```text
null-safety  boundary  unit-conversion  rounding  rule-conflict
silent-failure  doc-drift  test-quality  other-<slug>
```

使用 `other-<slug>` 时 MUST 在 `Note` 列写一句归类理由。同一问题整改后再次出现且指纹相同者，MUST 记为 `REGRESSION of <ID>`。

## Status 取值

| 值 | 含义 | 附加要求 |
|---|---|---|
| `open` | 未处理 | — |
| `fixed` | 已修复 | MUST 填 `Fix-SHA` |
| `accepted-risk` | 人类接受该风险 | `Note` 写结案人与日期 |
| `deferred` | 延后处理 | `Note` 写延后理由 |
| `debatable` | 无法给出可复现输入 | 归档前 MUST 由人类结案 |
| `no-repeat` | 已登记项的重复提出 | 不计入 `Critical` / `Important` |

## Action 取值

| 值 | 含义 |
|---|---|
| `root-cause` | 根因诊断记录（假设、实验、结论） |
| `rewrite` | 模块重写（同指纹第二次出现时由 `FORCE-REWRITE` 触发） |
| `scope-change` | 评审区间或轮次调整 |

## 停止规则

同一 `Fingerprint` 第二次出现时，MUST 将对应行 `Action` 置为 `rewrite` 并附 `FORCE-REWRITE` 标记，改为重写该模块并补齐 `## Boundary Matrix`；MUST NOT 继续输出局部补丁。同一 `File` 在 3 个及以上不同 `Round` 出现时，`scripts/onepress-verify.sh --churn` 会以非零码退出。

## 与 `.review/` 的分工

`.review/round-<n>.md` 只保存设计评审（`/openspec-review-change`）的失败轮次，可不入库；本文件是代码冷审与修复历史的唯一真源，MUST 随变更目录提交。
