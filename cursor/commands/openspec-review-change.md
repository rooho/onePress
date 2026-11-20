---
name: "openspec-review-change"
description: "编码前三级设计评审门禁（L1 确定性预检 / L2 冷上下文盲审 / L3 人类批注）"
---

> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。

# /openspec-review-change `<change-name>`

编码前三级评审，产出 DAG 工件 `review.md`。只允许修订 `ui-spec.md`、`sandbox-preview.html`，**MUST NOT 修改业务代码**。

## 1. 输入与前置校验

1. 读 `openspec/changes/<change>/proposal.md` 的 `**UI Change**:` 行。
   - `no` → 直接写 `review.md`：`Result: SKIP (UI Change: no)`、`P0: 0`、`P1: 0`、`Review-Status: N/A`，结束（退出码 0）；不创建 `ui-spec.md` 或沙箱。
   - `yes` → 继续。
2. 校验 `ui-spec.md` 与 `sandbox-preview.html` 存在；缺失 → `FAIL`，提示先完成 `design` 工件。
3. 读评分表 `openspec/schemas/superspec/templates/review-rubric.md`（唯一来源，不得复制锚点）。
4. `Round` = `.review/round-*.md` 数量 + 1；无则 `1`。上限 3。

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

1. 输入（只读）：`proposal.md`、`design.md`（若存在）、`specs/**/*.md`、`tasks.md`、`plan.md`、`ui-spec.md`、`sandbox-preview.html`、`MASTER.md`、`review-rubric.md`。有子代理能力时派生零历史子代理；否则新会话 + 仅上传这些输入 + 正文声明"未引用生成历史"（`L2: FALLBACK`）。
2. 按 rubric 第 1–4 节评估：P0–P3、62 类 Slop 摘要。
3. **每条 finding 必须含证据列**（`ui-spec.md` 章节或 DOM 选择器）；无证据标记 `no-evidence`，不计分、不阻断。
4. 记录 `Critique <x>/40` 与 `Audit <y>/20`，标注 `observation`（本阶段不单独阻断）。
5. 主判据：`P0 = 0 且 P1 = 0`。存在 P0/P1 → 修订契约与沙箱后回到 L1（Round+1）；累计 3 轮仍未收敛 → 结论 `ESCALATE`，不得写 `review.md`。

## 4. L3 人类批注与契约锁定

1. 打开 `sandbox-preview.html`，提示 `Alt/⌘ + Click` 点选元素；批注器复制"选择器 + 类名 + HTML 片段 + 批注"。
2. 批注经 `/openspec-update-change <change-name> "<批注>"` 回写到 `ui-spec.md` 与沙箱；回写后 MUST 把 `ui-spec.md` 第 3 行重置为 `> Review-Status: PENDING`，删除已有 `review.md`，再重跑 L1/L2。
3. **只有人类**可把 `ui-spec.md` 第 3 行改为 `> Review-Status: APPROVED`；Agent MUST NOT 自签，`review.md` 记录 approver 与日期。

## 5. 写评审记录

- 每轮写入 `openspec/changes/<change>/.review/round-<n>.md`，保留完整 Findings 与证据。
- 仅当 `P0 = 0`、`P1 = 0` 且人类 `Review-Status: APPROVED`（或 `UI Change: no`）时，才写 `openspec/changes/<change>/review.md`。
- `review.md` 使用 `openspec/schemas/superspec/templates/review.md`，必须包含 `Result` / `P0` / `P1` / `L1` / `L2` / `L3` / 三个 sha256 / `Approver` / `Reviewed-At`。
- FAIL 轮次 MUST NOT 生成 `review.md`；已有旧 `review.md` MUST 删除，避免 DAG 误放行。
- `review.md` 是 `review` 工件的产物；存在即表示 apply 解锁。

## 6. 版本绑定与失效

- 通过后计算 `sha256sum`（或 `shasum -a 256`）记录 `ui-spec-sha256`、`sandbox-sha256`、`plan-sha256`。
- 任一文件后续变化 → `review.md` 失效：删除 `review.md`、`Review-Status` 重置 PENDING、重跑本命令（只需增量复审变更章节）。
- `bash scripts/onepress-review-lint.sh --change openspec/changes/<change>` 会校验 Result/P0/P1/L3 与三个哈希；apply 前必须退出 0。

## 7. 失败处置

- `P0` 或 `P1` 存在 → 本轮 `FAIL`，只写 `.review/round-<n>.md`；修订后重跑，3 轮未收敛 → `ESCALATE`。
- `L1: SKIP` 不阻断，但 MUST 在轮次记录写明原因与代理风险。
- 评审全程 MUST NOT 写业务代码、MUST NOT 执行 `npm install`、MUST NOT 发起网络请求。
- 结束后提示：`review.md` 不存在或 `Result` 非 `PASS`/`SKIP` 时，`/openspec-apply-change` MUST NOT 启动。
