---
description: "编码前三级设计评审门禁（L1 确定性预检 / L2 冷上下文盲审 / L3 人类批注）"
---

> onepress: 执行本命令时 MUST 先加载技能 `superpowers-tdd`（铁律 1–4：Token 纯净度 / 四态状态机 / 无障碍基线 / 防呆闭环）。

# /opsx:review `<change-name>`

编码前三级评审。只允许修订 `ui-spec.md`、`sandbox-preview.html`，并写入 `review.md` 与 `Review-Status`；**MUST NOT 修改业务代码**。

## 1. 输入与前置校验

1. 读 `openspec/changes/<change>/proposal.md` 的 `**UI Change**:` 行。为 `no` → 输出 `SKIP（无 UI 变更）` 并结束，退出码 0。
2. 校验 `ui-spec.md` 与 `sandbox-preview.html` 存在；缺失 → `FAIL`，提示先运行 `/opsx:new`。
3. 读评分表 `openspec/schemas/superspec/templates/review-rubric.md`（唯一来源，不得复制锚点）。
4. `Round` = 现有 `review.md` 的 `Round` + 1；无则 `1`。上限 3。

## 2. L1 确定性预检

1. 探测 `npx playwright --version` 与 `@axe-core/playwright`。任一缺失 → `L1: SKIP（<原因>）`，跳到 L2，**不得**执行 `npm install`。
2. 将 rubric 第 6 节脚本写入 `openspec/changes/<change>/.review/sandbox-preflight.spec.ts`。
3. 运行：

   ```bash
   SANDBOX_PATH=openspec/changes/<change>/sandbox-preview.html \
     npx playwright test openspec/changes/<change>/.review/sandbox-preflight.spec.ts
   ```

4. 报告写入 `.review/l1-report.json`。失败项按 offending selector 修订 `ui-spec.md` / 沙箱后重跑，本轮计入 `Round`。
5. 断言范围：WCAG 2.2 A/AA 零 violations、热区 ≥44×44（行内文本链接豁免）、375/768/1024/1280 零横向溢出、变量声明块外零 Hex、零 Emoji、CLS <0.1（代理指标）。

## 3. L2 冷上下文盲审

1. 输入四件套（只读）：`MASTER.md`、`ui-spec.md`、`sandbox-preview.html`、`review-rubric.md`。有子代理能力时派生零历史子代理；否则新会话 + 仅上传四件套 + 正文声明"未引用生成历史"（`L2: FALLBACK`）。
2. 按 rubric 第 1–4 节评估：P0–P3、认知负荷（单层列表 ≤8、单决策点 ≤4）、62 类 Slop 摘要。
3. **每条 finding 必须含证据列**（`ui-spec.md` 章节或 DOM 选择器）；无证据标记 `no-evidence`，不计分、不阻断。
4. 记录 `Critique <x>/40` 与 `Audit <y>/20`，标注 `observation`（本阶段不单独阻断）。
5. 主判据：`P0 = 0 且 P1 = 0`。存在 P0/P1 → 修订契约与沙箱后回到 L1（Round+1）；累计 3 轮仍未收敛 → 结论 `ESCALATE`。

## 4. L3 人类批注与契约锁定

1. 打开 `sandbox-preview.html`，提示 `Alt/⌘ + Click` 点选元素；批注器复制"选择器 + 类名 + HTML 片段 + 批注"。
2. 批注经 `/opsx:update <change-name> "<批注>"` 回写到 `ui-spec.md` 与沙箱，重跑 L1/L2。
3. **只有人类**可把 `ui-spec.md` 第 3 行改为 `> Review-Status: APPROVED`；Agent MUST NOT 自签，`review.md` 记录 approver 与日期。

## 5. 写 `review.md`

在变更目录写入（覆盖更新）：

```markdown
# Review — <change-name>

- Round: <n>/3
- L1: PASS | FAIL | SKIP (<reason>)
- L2: PASS | FAIL | SKIP | FALLBACK (<reason>)
- L3: APPROVED | PENDING (<approver>, <ISO date>)
- Critique: <x>/40 (observation)
- Audit: <y>/20 (observation)
- P0: <n>  P1: <n>  P2: <n>  P3: <n>

## Findings
| # | 级别 | 证据（ui-spec 章节 / 选择器） | 问题 | 建议 |

## 结论
<PASS | FAIL | ESCALATE>
```

## 6. 失败处置

- `P0` 存在 → 结论 `FAIL`，MUST 阻断进入 `/opsx:apply`。
- `P1` 存在 → 结论 `FAIL`，修订后重跑；3 轮未收敛 → `ESCALATE`。
- `L1: SKIP` 不阻断，但 MUST 在 `review.md` 写明原因与代理风险。
- 评审全程 MUST NOT 写业务代码、MUST NOT 执行 `npm install`、MUST NOT 发起网络请求。
- 结束后提示：`Review-Status: PENDING` 时必须由人类批准后 `/opsx:apply` 才会放行。
