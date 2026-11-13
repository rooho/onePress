# onepress-frontend-contract Delta

## MODIFIED Requirements

### Requirement: ui-spec.md 契约

UI 变更 MUST 在 `openspec/changes/<name>/ui-spec.md` 中按 `templates/ui-spec.md` 生成七个章节：组件层级拆解、Design Token 映射、四态状态机矩阵、响应式断点与排版、交互热点与微动效、行业反模式黑名单、沙箱预览。七章节 MUST NOT 缺失。文件 MUST 在标题下固定一行 `> Review-Status: PENDING`，作为 `/opsx:apply` 的前置契约锁（见 `onepress-design-review-gate`）。Design Token 映射 MUST 列出 16 个语义色彩通道（`Primary`、`On Primary`、`Secondary`、`On Secondary`、`Accent`、`On Accent`、`Background`、`Foreground`、`Card`、`Card Foreground`、`Muted`、`Muted Foreground`、`Border`、`Destructive`、`On Destructive`、`Ring`）的 Light 与 Dark 取值，MUST 将四个 `On *` 角色强制重命名为 Shadcn 标准变量 `--primary-foreground`、`--secondary-foreground`、`--accent-foreground`、`--destructive-foreground`，MUST NOT 使用 `--color-on-*` 原始命名。暗色侧 MUST 给出取值策略：`Background` `#0F172A`、`Card` `#111827`、`Muted Foreground` `#CBD5E1`、`Border` `#334155`，`Ring` MUST 在候选色中取与暗底对比度 ≥3:1 者（回退 `#60A5FA`）。Tailwind v4 项目 MUST 说明在 `:root` 与 `.dark` 定义变量，并在 `@theme inline` 中声明 `--color-primary: var(--primary)` 等映射。

#### Scenario: 七章节齐全

- **GIVEN** 一个 `**UI Change**: yes` 的变更
- **WHEN** 检查其 `ui-spec.md`
- **THEN** 七个二级标题全部存在，且第 2 节包含 16 个语义色彩通道行

#### Scenario: 六章节齐全

- **GIVEN** 一个 `**UI Change**: yes` 的变更
- **WHEN** 检查其 `ui-spec.md`
- **THEN** 第 1–6 节（组件层级 / Token / 四态 / 响应式 / 微动效 / 反模式）全部存在，不因新增第 7 节而缺失

#### Scenario: 字体与密度被量化

- **GIVEN** 一个 UI 变更的 `ui-spec.md`
- **WHEN** 检查第 2 节
- **THEN** 存在主副字体配对（含基准字号 16px、行高 1.5）与 `xs` 至 `3xl` 的间距变量表，且明确图标库与描边粗细

#### Scenario: 反模式黑名单非空

- **GIVEN** 一个 UI 变更的 `ui-spec.md`
- **WHEN** 检查第 6 节
- **THEN** 至少存在一条来自检索结果或人工确认的 `AVOID` 条目，供门禁 7 与 L2 盲审读取

#### Scenario: On 角色被重命名

- **GIVEN** `MASTER.md` 输出 `--color-on-primary`
- **WHEN** 写入 `ui-spec.md` 第 2.1 节
- **THEN** 目标变量名为 `--primary-foreground`，且契约中不出现 `--color-on-primary`

#### Scenario: 双主题与映射说明齐备

- **GIVEN** 一个 Tailwind v4 + Shadcn 项目
- **WHEN** 检查第 2.1 节
- **THEN** Light 与 Dark 两列均有取值，暗色策略与 `@theme inline` 映射说明均存在

#### Scenario: Review-Status 初始行存在

- **GIVEN** 一个新生成的 `ui-spec.md`
- **WHEN** 读取第 3 行
- **THEN** 内容为 `> Review-Status: PENDING`

#### Scenario: 纯后端变更不得创建该文件

- **GIVEN** 一个 `**UI Change**: no` 的变更
- **WHEN** 检查变更目录
- **THEN** 不存在 `ui-spec.md`，且 `/opsx:verify` 不因缺少该文件而失败

---

### Requirement: 设计智能检索与降级

UI 变更 MUST 按"先语义 UX、后技术栈"的双步策略调用本地检索：先以 `--domain ux` 查询交互与无障碍准则，再以 `--stack shadcn` 或 `--stack html-tailwind` 查询实现规范。每次查询 MUST 使用 2–5 个英文领域词，SHOULD 包含 `dashboard`、`data_heavy`、`checkout`、`booking`、`mobile`、`luxury` 等推理信号词；返回 0 结果时 MUST 缩窄关键词重试一次并记录。查询 MAY 附加 `--json` 以获取结构化字段。项目级基线 `docs/design-system/projectbaseline/MASTER.md` MUST 一次性生成；生成后 MUST 立即把顶部 Banner 中的 `design-system/pages/[page-name].md` 替换为 `openspec/changes/[change-name]/ui-spec.md`，并 MUST 显式禁止创建 `design-system/pages/*.md`；`MASTER.md` 已存在时 MUST 只输出告警，MUST NOT 改写。动效参数 MUST 只取时长（150–250ms）、缓动与交错延迟，并映射为 Tailwind 过渡类与 `prefers-reduced-motion` 降级；除非 `package.json` 已声明 `gsap`，否则 MUST NOT 引入 GSAP 代码或依赖。检索能力 MUST 视为可选增强层：`python3` 或技能目录缺失时 MUST 输出 `SKIP: ui-ux-pro-max 不可用` 并改为手工填写，MUST NOT 中断流程。

#### Scenario: 查询使用英文信号词

- **GIVEN** `ui-ux-pro-max` 可用
- **WHEN** 执行双步检索
- **THEN** 两次 `search.py` 调用的 `<query>` 均为 2–5 个英文词，且至少包含一个信号词

#### Scenario: 零命中重试一次

- **GIVEN** 首次查询返回 0 条结果
- **WHEN** 执行检索
- **THEN** 使用更窄的英文关键词重试一次，并在 `ui-spec.md` 记录重试关键词

#### Scenario: Banner 重写为单源路径

- **GIVEN** 本次首次生成 `MASTER.md`
- **WHEN** 生成完成
- **THEN** 顶部 Banner 指向 `openspec/changes/[change-name]/ui-spec.md`，且含 `DO NOT create design-system/pages/*.md`

#### Scenario: 既有基线不被改写

- **GIVEN** 目标仓库已存在 `MASTER.md`
- **WHEN** 执行 `/opsx:new`
- **THEN** 输出 Banner 核对告警，文件内容逐字节不变

#### Scenario: 无 gsap 时禁止引入

- **GIVEN** `package.json` 未声明 `gsap`
- **WHEN** 生成第 5 节微动效
- **THEN** 只出现 CSS/Tailwind 过渡参数，不出现 `import 'gsap'` 或 GSAP 代码骨架

#### Scenario: 检索能力缺失时降级

- **GIVEN** 目标环境没有 `python3`
- **WHEN** 执行 `/opsx:new` 且 `UI Change: yes`
- **THEN** 输出 `SKIP: ui-ux-pro-max 不可用`，`ui-spec.md` 仍被生成且七章节齐全，流程不中断

#### Scenario: 零运行时依赖承诺不受影响

- **GIVEN** 一个仅有 LLM 与文件系统能力的仓库
- **WHEN** 按 `INSTALL_PROMPT.md` 执行安装
- **THEN** 安装不要求预装 Python3 或 Node.js，`ui-ux-pro-max` 相关步骤全部记为可选

#### Scenario: 双步检索顺序被执行

- **GIVEN** `ui-ux-pro-max` 可用且变更为 UI 变更
- **WHEN** 执行 `/opsx:new`
- **THEN** 先出现 `--domain ux` 的检索调用，后出现 `--stack shadcn` 或 `--stack html-tailwind` 的检索调用

#### Scenario: 提示词安装路径同样保持可选

- **GIVEN** 执行者仅依据 `INSTALL_PROMPT.md` 安装，且目标环境没有 `python3`
- **WHEN** 安装完成并输出报告
- **THEN** 报告含一行 `ui-ux-pro-max：SKIP（未检测到 python3…）` 并附启用指引，安装结论仍为成功，且全程未执行 `npm install` 或 `uipro init`

---

### Requirement: 高保真沙箱预览

UI 变更 MUST 生成单文件 `openspec/changes/<name>/sandbox-preview.html`，仅使用 inline CSS 与 JS。该文件 MUST 包含：① `#sandbox-control-bar` 控制栏，内含 `[data-set-state="idle|loading|empty|error"]` 四态按钮与 `[data-set-theme="light|dark"]` 主题按钮；② `<main>` landmark 包裹页面主体；③ `ui-spec.md` 第 2 节的 16 个语义色彩变量与间距变量；④ 第 2 节选定的 Google Fonts `<link>`；⑤ `prefers-reduced-motion` 降级规则；⑥ L3 Pin-to-AI 批注脚本（`Alt/⌘ + Click`，复制选择器 + 类名 + HTML 片段 + 批注）。关键可交互元素 MUST 带 `data-review-id`。批注器 MUST 使用零依赖原生 JS，MUST NOT 进入生产代码。

#### Scenario: 控制栏契约齐备

- **GIVEN** 一个 UI 变更的 `sandbox-preview.html`
- **WHEN** 检查 DOM
- **THEN** 存在 `#sandbox-control-bar`、四个 `[data-set-state]` 按钮、两个 `[data-set-theme]` 按钮与 `<main>` landmark

#### Scenario: 双切换器齐备

- **GIVEN** 一个 UI 变更的 `sandbox-preview.html`
- **WHEN** 点击 `[data-set-state]` 与 `[data-set-theme]`
- **THEN** 页面状态（四态）与主题（Light/Dark）随之切换，且控件位于 `#sandbox-control-bar`

#### Scenario: 批注器可复制结构化指令

- **GIVEN** 用户 `Alt + Click` 一个带 `data-review-id` 的元素
- **WHEN** 填写批注并确认
- **THEN** 剪贴板内容包含选择器、类名、HTML 片段与批注原文

#### Scenario: Token 与字体来自契约

- **GIVEN** 一个 UI 变更的 `sandbox-preview.html`
- **WHEN** 比对其 CSS 变量与 `ui-spec.md` 第 2 节
- **THEN** 16 个色彩变量与间距变量取值一致，且 Google Fonts 与契约字体配对一致

#### Scenario: 沙箱不使用硬编码色值

- **GIVEN** `sandbox-preview.html`
- **WHEN** 执行 L1 的 Hex 规则
- **THEN** 变量声明块之外无硬编码十六进制色值

---

### Requirement: 八项 verify 门禁

`/opsx:verify` MUST 按编号 0–8 依次执行门禁：门禁 0（契约存在性，`UI Change: yes` 时必须有 `ui-spec.md` 与 `sandbox-preview.html`）；① 四态一致性与防抖（`Loading` 预留空间，CLS < 0.1）；② Design Token 100% 覆盖且 Light/Dark 正文对比度 ≥4.5:1、大号文本与控件边界 ≥3:1；③ `sm`/`md`/`lg`/`xl` 断点零横向滚动、长标识符安全折行、Chip/Badge 可换行或 `+n` 展开；④ 纯逻辑状态机单测通过；⑤ A11y CRITICAL（焦点环、`aria-label`、`aria-describedby`、装饰图标 `aria-hidden`）；⑥ 热区 ≥44×44px、间距 ≥8px、`cursor-pointer`、悬停 200–250ms、按压 150ms、尊重 `prefers-reduced-motion`；⑦ 反模式清零（零 Emoji 图标、未违反 `ui-spec.md` 第 6 节）；⑧ 实现与沙箱无显著视觉偏差。门禁 0.5（`Review-Status` 签署）属编码前评审阶段，由 `/opsx:review` 与门禁脚本执行，`/opsx:verify` MUST 复核其结论为 `APPROVED`。每项 MUST 记录 `PASS`/`FAIL`/`SKIP` 与 `AUTO`/`MANUAL`，`SKIP` MUST 附原因，CRITICAL 项 `FAIL` MUST 阻断归档。

#### Scenario: 对比度不足被拦截

- **GIVEN** Light 模式下正文前景与背景的对比度为 3.8:1
- **WHEN** 执行门禁 2
- **THEN** 判定为 `FAIL`，`verify.md` 记录实际比值与所测颜色对

#### Scenario: 未签署契约阻断 verify

- **GIVEN** `ui-spec.md` 的 `Review-Status` 为 `PENDING`
- **WHEN** 执行 `/opsx:verify`
- **THEN** 门禁 0.5 记为 `FAIL`，整体结论 MUST NOT 为 `PASS`

#### Scenario: Emoji 图标触发反模式

- **GIVEN** 组件中使用 Emoji 作为按钮图标
- **WHEN** 执行门禁 7
- **THEN** 判定为 `FAIL` 并列出命中文件与行号

#### Scenario: 人工门禁不得默认通过

- **GIVEN** 门禁 8（沙箱对齐）尚未由人工确认
- **WHEN** 生成 `verify.md`
- **THEN** 该项记为 `MANUAL / 未确认`，整体结论 MUST NOT 为 `PASS`

#### Scenario: 纯后端变更跳过八门禁

- **GIVEN** 一个 `**UI Change**: no` 的变更
- **WHEN** 执行 `/opsx:verify`
- **THEN** 门禁 0–8 全部记为 `SKIP（无 UI 变更）`，结论按非 UI 校验项给出

---

### Requirement: 门禁脚本与自动化分级

模板包 MUST 提供 `scripts/onepress-gate.sh`，在任意目标仓库根目录可运行，自动实现门禁 0、0.5、2、4、5、6、7，并对门禁 1、3、8 输出 `MANUAL` 提示。门禁 0.5 MUST 在变更 `UI Change: yes` 且存在 `ui-spec.md` 时校验 `Review-Status`，不为 `APPROVED` 即 `FAIL`；`--require-review` MUST 显式表达同一语义供 CI 使用，`--no-require-review` MUST 记为 `SKIP（legacy）`，`UI Change: no` MUST 记为 `SKIP`。退出码约定：存在 `FAIL` 时为非 `0`，全部 `PASS` 或 `SKIP` 时为 `0`。脚本 MUST NOT 要求 Python3 或第三方包；对比度计算 MUST 在脚本内以 `awk` 完成；L1 预检脚本缺失或 Playwright 不可用时 MUST 记 `SKIP`，MUST NOT 阻断。

#### Scenario: 违规代码导致非零退出

- **GIVEN** 目标仓库某个 `.tsx` 文件含 `style={{ color: '#3b82f6' }}` 与 `w-[317px]`
- **WHEN** 执行门禁脚本
- **THEN** 脚本以非 `0` 退出，并逐条列出命中的文件与行号

#### Scenario: 未签署契约被门禁 0.5 拦截

- **GIVEN** `ui-spec.md` 的 `Review-Status` 为 `PENDING`
- **WHEN** 执行 `bash scripts/onepress-gate.sh --change <dir>`
- **THEN** 门禁 0.5 输出 `FAIL`，脚本退出码非 `0`

#### Scenario: 工具缺失记为 SKIP

- **GIVEN** 目标仓库没有 `node_modules`
- **WHEN** 执行门禁脚本
- **THEN** 门禁 4 与 L1 记为 `SKIP（vitest/Playwright 不可用）`，门禁 2/5/6/7 仍正常执行，脚本不崩溃

#### Scenario: 对比度由 awk 计算

- **GIVEN** 组件 CSS 中 `--background: #ffffff` 与 `--foreground: #777777`
- **WHEN** 执行门禁 2
- **THEN** 脚本计算出对比度约 4.48:1 并判定 `FAIL`（低于 4.5:1），全程未调用 Python

#### Scenario: 人工项被显式标注

- **GIVEN** 任意一次门禁脚本执行
- **WHEN** 查看输出
- **THEN** 门禁 1、3、8 以 `MANUAL` 前缀输出，不出现 `PASS` 字样
