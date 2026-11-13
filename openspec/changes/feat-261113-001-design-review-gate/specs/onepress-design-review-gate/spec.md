# onepress-design-review-gate Delta

## ADDED Requirements

### Requirement: 编码前三级评审动作

`/opsx:review <change-name>` MUST 在 `/opsx:new` 之后、`/opsx:apply` 之前执行，并 MUST 按 L1 → L2 → L3 的顺序推进。评审过程 MUST NOT 修改目标仓库业务代码，只允许修订 `ui-spec.md`、`sandbox-preview.html`，并写入 `review.md` 与 `ui-spec.md` 的 `Review-Status` 行。

#### Scenario: 顺序执行且不触碰业务代码

- **GIVEN** 一个 `**UI Change**: yes` 且已生成 `ui-spec.md` 与 `sandbox-preview.html` 的变更
- **WHEN** 执行 `/opsx:review <change-name>`
- **THEN** 输出依次包含 L1、L2、L3 三个段落，且 `git status` 中不出现业务代码文件改动

#### Scenario: 纯后端变更跳过评审

- **GIVEN** 一个 `**UI Change**: no` 的变更
- **WHEN** 执行 `/opsx:review <change-name>`
- **THEN** 输出 `SKIP（无 UI 变更）`，不创建 `review.md`，流程以退出码 `0` 结束

---

### Requirement: L1 确定性沙箱预检

L1 MUST 使用 Playwright + `@axe-core/playwright` 对 `sandbox-preview.html` 遍历 `idle`/`loading`/`empty`/`error` × `light`/`dark` 共 8 个视图，并 MUST 断言：① `withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])` 零 violations（排除 `#sandbox-control-bar`）；② 交互控件渲染尺寸 ≥44×44px（行内文本链接豁免）；③ 375/768/1024/1280 视口零横向溢出；④ CSS 变量声明块之外零硬编码 Hex 与零 Emoji 功能图标。CLS MUST 以 `PerformanceObserver` 在状态切换时采样并记录，阈值 0.1。Playwright 或 axe 不可用时 MUST 记 `L1: SKIP（<原因>）`，MUST NOT 中断评审，MUST NOT 触发 `npm install`。

#### Scenario: axe 违规返回选择器

- **GIVEN** 沙箱在 Dark 模式下 `Border` 与背景对比度不足
- **WHEN** 执行 L1
- **THEN** `L1: FAIL`，`l1-report.json` 含违规规则 id 与 offending selector，且不进入 L2

#### Scenario: 工具缺失记 SKIP

- **GIVEN** 目标仓库未安装 Playwright
- **WHEN** 执行 L1
- **THEN** `review.md` 记录 `L1: SKIP（未检测到 Playwright）`，评审继续执行 L2

#### Scenario: 热区不足被拦截

- **GIVEN** 沙箱内某 `<button>` 渲染为 32×32px
- **WHEN** 执行 L1
- **THEN** `L1: FAIL` 并列出该元素标签、文本与宽高

#### Scenario: 变量块外硬编码色值被拦截

- **GIVEN** 沙箱在组件规则中直接写入 `#3b82f6`
- **WHEN** 执行 L1
- **THEN** `L1: FAIL` 并指出命中行号；`--primary: #3b82f6` 这类变量声明不判失败

---

### Requirement: L2 冷上下文盲审

L2 MUST 仅以 `docs/design-system/projectbaseline/MASTER.md`、变更的 `ui-spec.md`、变更的 `sandbox-preview.html` 与 `openspec/schemas/superspec/templates/review-rubric.md` 为输入，MUST NOT 携带生成阶段的对话历史。具备子代理能力的 harness MUST 派生零历史子代理；不具备时 MUST 走 FALLBACK：新会话 + 仅上传四件套 + 正文声明未引用生成历史。主判据 MUST 为 `P0 = 0 且 P1 = 0`，且单层列表 ≤8 项、单决策点并列选项 ≤4。每条 finding MUST 引用 `ui-spec.md` 章节或 DOM 选择器，无证据的 finding MUST NOT 计分或阻断。Critique 40 分制与 Audit 20 分制 MUST 以观察模式记录，MUST NOT 单独阻断。L1 与 L2 合计 MUST NOT 超过 3 轮，超限 MUST 输出 `ESCALATE` 交 L3。

#### Scenario: 子代理零历史

- **GIVEN** 支持子代理的 harness
- **WHEN** 执行 L2
- **THEN** 子代理输入只含四件套文件内容，不含 `/opsx:new` 会话记录

#### Scenario: 无子代理时走 FALLBACK

- **GIVEN** 一个不具备子代理能力的 harness
- **WHEN** 执行 L2
- **THEN** `review.md` 记录 `L2: FALLBACK`，且正文含"未引用生成历史"声明

#### Scenario: 无证据 finding 不计分

- **GIVEN** L2 输出一条未引用章节或选择器的 finding
- **WHEN** 汇总评审结果
- **THEN** 该条被标记 `no-evidence` 且不参与 P0/P1 统计

#### Scenario: 超限挂起

- **GIVEN** 第 3 轮 L1+L2 仍有 P1 级问题
- **WHEN** 汇总评审结果
- **THEN** `review.md` 结论为 `ESCALATE`，不写 `APPROVED`

---

### Requirement: L3 人类批注与契约锁定

L3 MUST 提供可执行的 DOM 点选批注闭环：`sandbox-preview.html` MUST 含 `#sandbox-control-bar`、`[data-set-state]`、`[data-set-theme]` 与 `<main>` landmark；关键可交互元素 MUST 带 `data-review-id`。批注器 MUST 在 `Alt/⌘ + Click` 时输出"选择器 + 类名 + HTML 片段 + 批注"，选择器 MUST 优先使用 `data-review-id`；`navigator.clipboard` 不可用时 MUST 回退 `document.execCommand('copy')`；SVG 目标 MUST 做 `className` 类型守卫。只有人类确认后，`ui-spec.md` 的 `Review-Status` 才允许写为 `APPROVED`，Agent MUST NOT 自行写入。

#### Scenario: 批注输出可被 update 消费

- **GIVEN** 用户在沙箱中 `Alt + Click` 一张卡片并填写"内边距过大"
- **WHEN** 批注器复制结果
- **THEN** 剪贴板内容含 `[data-review-id]` 选择器、类名、HTML 片段与原文批注，可直接粘贴给 `/opsx:update`

#### Scenario: 剪贴板失败时回退

- **GIVEN** 浏览器拒绝 `navigator.clipboard.writeText`
- **WHEN** 用户触发批注
- **THEN** 批注器改用隐藏 textarea + `execCommand('copy')`，并提示复制结果

#### Scenario: Agent 不得自签

- **GIVEN** L2 已通过但人类尚未确认
- **WHEN** 检查 `ui-spec.md`
- **THEN** `Review-Status` 仍为 `PENDING`，门禁 0.5 判定 `FAIL`

---

### Requirement: 评审通行证 review.md

`/opsx:review` MUST 在变更目录写入 `review.md`，至少包含 `Round`、`L1`、`L2`、`L3`、`Critique`、`Audit`、`P0`–`P3` 计数、`Findings` 表与结论。`Findings` 表 MUST 含"级别"与"证据（ui-spec 章节 / 选择器）"两列。`review.md` MUST 作为变更工件随归档保留，MUST NOT 写入 `ui-spec.md`。

#### Scenario: 通行证字段齐全

- **GIVEN** 一次完成的评审
- **WHEN** 检查 `review.md`
- **THEN** 七个头部字段与 `Findings` 表均存在，结论为 `PASS`/`FAIL`/`ESCALATE` 之一

#### Scenario: 分数标注观察模式

- **GIVEN** `review.md` 含 Critique 与 Audit 分值
- **WHEN** 汇总结论
- **THEN** 两项标注 `observation`，不单独导致 `FAIL`

---

### Requirement: 评分表单一来源

`openspec/schemas/superspec/templates/review-rubric.md` MUST 作为 L2 评分、认知负荷阈值、反模式清单与 L1 脚本附录的唯一来源。四份 `opsx-review` 命令体与三份 carrier skill MUST 只引用该路径，MUST NOT 复制评分锚点正文。

#### Scenario: 评分表随 schema 安装

- **GIVEN** 安装完成后的目标仓库
- **WHEN** 统计 `openspec/schemas/superspec/`
- **THEN** 共 12 个文件，且包含 `templates/review-rubric.md`

#### Scenario: 命令体不复制锚点

- **GIVEN** 四份 `opsx-review` 命令体
- **WHEN** 检索评分锚点表格特征
- **THEN** 命令体只出现 `review-rubric.md` 路径引用，不出现完整锚点表

---

### Requirement: 门禁 0.5 契约锁定校验

`scripts/onepress-gate.sh` MUST 新增门禁 0.5：当变更 `**UI Change**: yes` 且存在 `ui-spec.md` 时，`Review-Status` 不为 `APPROVED` MUST 判定 `FAIL`。`--require-review` MUST 显式表达同一语义供 CI 使用；`--no-require-review` MUST 将门禁 0.5 记为 `SKIP（legacy）`。`UI Change: no` 时 MUST 记 `SKIP`。门禁 0.5 的判定 MUST NOT 依赖 Python 或第三方包。

#### Scenario: 未签署被拦截

- **GIVEN** `ui-spec.md` 的 `Review-Status` 为 `PENDING`
- **WHEN** 执行 `bash scripts/onepress-gate.sh --change <dir>`
- **THEN** 门禁 0.5 输出 `FAIL`，脚本退出码非 `0`

#### Scenario: 已签署放行

- **GIVEN** `Review-Status` 为 `APPROVED`
- **WHEN** 执行门禁脚本
- **THEN** 门禁 0.5 输出 `PASS`，其余门禁照常执行

#### Scenario: 旧变更逃生阀

- **GIVEN** 一个 1.0.7 时期创建、无 `Review-Status` 行的变更
- **WHEN** 执行 `bash scripts/onepress-gate.sh --change <dir> --no-require-review`
- **THEN** 门禁 0.5 输出 `SKIP（legacy）`，不阻断

---

### Requirement: Review-Status 契约标记

`ui-spec.md` MUST 在标题下固定一行 `> Review-Status: PENDING|APPROVED`。初始值 MUST 为 `PENDING`；`/opsx:review` MUST NOT 写入 `APPROVED`；旧变更缺失该行时 MUST 视为 `PENDING`。解析正则 MUST 为 `^> Review-Status: (PENDING|APPROVED)$`。

#### Scenario: 初始值为 PENDING

- **GIVEN** `/opsx:new` 判定 `UI Change: yes`
- **WHEN** 生成 `ui-spec.md`
- **THEN** 第 3 行为 `> Review-Status: PENDING`

#### Scenario: 非法值被拒绝

- **GIVEN** `ui-spec.md` 写作 `> Review-Status: APPROVED_BY_AI`
- **WHEN** 执行门禁 0.5
- **THEN** 判定 `FAIL` 并提示合法取值
