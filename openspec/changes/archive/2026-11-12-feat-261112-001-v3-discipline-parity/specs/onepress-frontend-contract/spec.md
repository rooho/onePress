## Purpose

定义 v3.0 前端纪律在 onePress 中的可验证口径：需求类型分流、`ui-spec.md` 五+一章节契约、设计智能检索的可选降级、项目级设计基线、高保真沙箱、沙箱即生产两阶段、八项静态门禁、门禁脚本，以及组件注册表的结构与追加规则。

## ADDED Requirements

### Requirement: 需求类型分流

`/opsx:new` MUST 在生成任何工件之前先判定需求类型，并把结论写入 `proposal.md` 的 `**UI Change**: yes|no` 行。命中以下任一条 MUST 判定为 `yes`：① 新增或修改路由、页面；② 新增或修改表格列、表单字段、状态展示；③ 涉及删除/覆盖等破坏性操作的交互变更。三条均不命中 MUST 判定为 `no`，且 MUST NOT 生成 `ui-spec.md`、`sandbox-preview.html`，MUST NOT 触发任何设计检索。

#### Scenario: 纯后端变更不产出 UI 工件

- **GIVEN** 一个只修改后端接口、安装脚本或 Markdown 的变更
- **WHEN** 执行 `/opsx:new`
- **THEN** `proposal.md` 出现 `**UI Change**: no`，变更目录内不存在 `ui-spec.md` 与 `sandbox-preview.html`，流程进入标准 TDD 分支且不报错

#### Scenario: UI 变更强制产出契约与沙箱

- **GIVEN** 一个新增列表页面并含删除按钮的变更
- **WHEN** 执行 `/opsx:new`
- **THEN** `proposal.md` 出现 `**UI Change**: yes`，且变更目录内生成 `ui-spec.md` 与 `sandbox-preview.html`

#### Scenario: 判定结论可被 verify 读取

- **GIVEN** 任意已完成的 `/opsx:new`
- **WHEN** 执行 `/opsx:verify`
- **THEN** 门禁 0 能读取 `**UI Change**:` 行并据其判断是否需要 `ui-spec.md`

---

### Requirement: ui-spec.md 契约

UI 变更 MUST 在 `openspec/changes/<name>/ui-spec.md` 中按 `templates/ui-spec.md` 生成六个章节：组件层级拆解、Design Token 映射、四态状态机矩阵、响应式断点与排版、交互热点与微动效、行业反模式黑名单。六章节 MUST NOT 缺失；Design Token 映射 MUST 列出 16 个语义色彩通道（`Primary`、`On Primary`、`Secondary`、`On Secondary`、`Accent`、`On Accent`、`Background`、`Foreground`、`Card`、`Card Foreground`、`Muted`、`Muted Foreground`、`Border`、`Destructive`、`On Destructive`、`Ring`）的 Light 与 Dark 取值。

#### Scenario: 六章节齐全

- **GIVEN** 一个 `**UI Change**: yes` 的变更
- **WHEN** 检查其 `ui-spec.md`
- **THEN** 六个二级标题全部存在，且第 2 节包含 16 个语义色彩通道行

#### Scenario: 字体与密度被量化

- **GIVEN** 一个 UI 变更的 `ui-spec.md`
- **WHEN** 检查第 2 节
- **THEN** 存在主副字体配对（含基准字号 16px、行高 1.5）与 `xs` 至 `3xl` 的间距变量表，且明确图标库与描边粗细

#### Scenario: 反模式黑名单非空

- **GIVEN** 一个 UI 变更的 `ui-spec.md`
- **WHEN** 检查第 6 节
- **THEN** 至少存在一条来自检索结果或人工确认的 `AVOID` 条目，供门禁 7 读取

#### Scenario: 纯后端变更不得创建该文件

- **GIVEN** 一个 `**UI Change**: no` 的变更
- **WHEN** 检查变更目录
- **THEN** 不存在 `ui-spec.md`，且 `/opsx:verify` 不因缺少该文件而失败

---

### Requirement: 设计智能检索与降级

UI 变更 MUST 按"先语义 UX、后技术栈"的双步策略调用本地检索：先以 `--domain ux` 查询交互与无障碍准则，再以 `--stack shadcn` 或 `--stack html-tailwind` 查询实现规范。检索能力 MUST 视为可选增强层：当 `python3` 不可用或 `ui-ux-pro-max` 技能目录缺失时，执行者 MUST 输出 `SKIP: ui-ux-pro-max 不可用` 并改为手工填写 `ui-spec.md`，MUST NOT 中断 `/opsx:new` 或安装流程。

#### Scenario: 双步检索顺序被执行

- **GIVEN** `ui-ux-pro-max` 可用且变更为 UI 变更
- **WHEN** 执行 `/opsx:new`
- **THEN** 先出现 `--domain ux` 的检索调用，后出现 `--stack shadcn` 或 `--stack html-tailwind` 的检索调用

#### Scenario: 检索能力缺失时降级

- **GIVEN** 目标环境没有 `python3`
- **WHEN** 执行 `/opsx:new` 且 `UI Change: yes`
- **THEN** 输出 `SKIP: ui-ux-pro-max 不可用`，`ui-spec.md` 仍被生成且六章节齐全（内容为手工填写），流程不中断

#### Scenario: 提示词安装路径同样保持可选

- **GIVEN** 执行者仅依据 `INSTALL_PROMPT.md` 安装，且目标环境没有 `python3`
- **WHEN** 安装完成并输出报告
- **THEN** 报告含一行 `ui-ux-pro-max：SKIP（未检测到 python3…）` 并附启用指引，安装结论仍为成功，且全程未执行 `npm install` 或 `uipro init`

#### Scenario: 零运行时依赖承诺不受影响

- **GIVEN** 一个仅有 LLM 与文件系统能力的仓库
- **WHEN** 按 `INSTALL_PROMPT.md` 执行安装
- **THEN** 安装不要求预装 Python3 或 Node.js，`ui-ux-pro-max` 相关步骤全部记为可选

---

### Requirement: 项目级设计基线

项目初始化阶段 MUST 支持一次性生成 `docs/design-system/projectbaseline/MASTER.md`，内容包含推荐布局模式、16 通道色彩 Hex 与 CSS 变量对照、字体配对、间距像素表与行业反模式清单。`MASTER.md` 与 `docs/ui-components.md` MUST 同为项目级资产，安装与升级 MUST NOT 覆盖既有 `MASTER.md`。

#### Scenario: 基线文件结构完整

- **GIVEN** 已生成 `docs/design-system/projectbaseline/MASTER.md`
- **WHEN** 检查其内容
- **THEN** 存在布局模式、16 通道色彩、字体配对、间距表与反模式清单五个部分

#### Scenario: 既有基线不被覆盖

- **GIVEN** 目标仓库已存在 `docs/design-system/projectbaseline/MASTER.md`
- **WHEN** 执行安装或升级
- **THEN** 该文件内容逐字节保持不变，安装报告标注 `skipped (exists)`

---

### Requirement: 高保真沙箱预览

UI 变更 MUST 生成单文件 `openspec/changes/<name>/sandbox-preview.html`，仅使用 inline CSS 与 JS。该文件 MUST 包含：① `Idle`/`Loading`/`Empty`/`Error` 四态切换按钮；② `Light`/`Dark` 主题切换开关；③ `ui-spec.md` 第 2 节定义的 16 个语义色彩变量与间距变量；④ 第 2 节选定的 Google Fonts `<link>`；⑤ 通过 `prefers-reduced-motion` 的降级规则。

#### Scenario: 双切换器齐备

- **GIVEN** 一个 UI 变更的 `sandbox-preview.html`
- **WHEN** 检查页面控件
- **THEN** 同时存在四态切换按钮与 Light/Dark 切换开关，且点击后页面状态或主题随之变化

#### Scenario: Token 与字体来自契约

- **GIVEN** 一个 UI 变更的 `sandbox-preview.html`
- **WHEN** 比对其 CSS 变量与 `ui-spec.md` 第 2 节
- **THEN** 16 个色彩变量与间距变量取值一致，且 `<head>` 中的 Google Fonts 与契约字体配对一致

#### Scenario: 沙箱不使用硬编码色值

- **GIVEN** `sandbox-preview.html`
- **WHEN** 执行门禁 2 的三条 Token 正则（排除变量定义块）
- **THEN** 变量定义块之外无硬编码十六进制色值与任意像素间距

---

### Requirement: 沙箱即生产两阶段执行

`/opsx:apply` 在 UI 分支 MUST 分两阶段执行。Stage 1 MUST 直接编写生产级 Props 受控组件（数据、`status`、`isSubmitting` 与回调全部经 Props 传入），MUST 使用 `ui-spec.md` 第 2 节的 Token 与第 5 节的微交互参数，MUST NOT 从沙箱 HTML 转译。Stage 2 MUST 只接线真实数据与 Hook，MUST NOT 改动 Stage 1 的 UI 结构与样式。两阶段 MUST NOT 要求注入 in-app 浮动 State Bar。

#### Scenario: Stage 1 产出生产级受控组件

- **GIVEN** 一个含 `ui-spec.md` 的变更进入 `/opsx:apply`
- **WHEN** Stage 1 完成
- **THEN** 产出组件为纯 Props 受控，样式全部来自 `ui-spec.md` 定义的 Token，且代码中不存在浮动 State Bar

#### Scenario: Stage 2 零改动接线

- **GIVEN** Stage 1 已通过沙箱比对验收
- **WHEN** 执行 Stage 2
- **THEN** 真实数据经 Hook / Container 注入 Props，组件结构与 class 集合无任何改动

#### Scenario: 无 UI 变更跳过两阶段

- **GIVEN** 一个 `**UI Change**: no` 的变更进入 `/opsx:apply`
- **WHEN** 执行 apply
- **THEN** 不创建视图组件、不生成沙箱、不注入任何浮动工具，直接按 `tasks.md` 执行标准 TDD

---

### Requirement: 八项 verify 门禁

`/opsx:verify` MUST 依次执行八项门禁：① 四态一致性与防抖（`Loading` 预留空间，CLS < 0.1）；② Design Token 100% 覆盖且 Light/Dark 正文对比度 ≥4.5:1、大号文本与控件边界 ≥3:1；③ `sm`/`md`/`lg`/`xl` 断点零横向滚动、长标识符安全折行、Chip/Badge 可换行或 `+n` 展开；④ 纯逻辑状态机单测通过；⑤ A11y CRITICAL（焦点环、`aria-label`、`aria-describedby`、装饰图标 `aria-hidden`）；⑥ 热区 ≥44×44px、间距 ≥8px、`cursor-pointer`、悬停 200–250ms、按压 150ms、尊重 `prefers-reduced-motion`；⑦ 反模式清零（零 Emoji 图标、未违反 `ui-spec.md` 第 6 节）；⑧ 实现与沙箱无显著视觉偏差。每项 MUST 记录 `PASS`/`FAIL`/`SKIP` 与 `AUTO`/`MANUAL`，`SKIP` MUST 附原因，CRITICAL 项 `FAIL` MUST 阻断归档。

#### Scenario: 对比度不足被拦截

- **GIVEN** Light 模式下正文前景与背景的对比度为 3.8:1
- **WHEN** 执行门禁 2
- **THEN** 判定为 `FAIL`，`verify.md` 记录实际比值与所测颜色对

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
- **THEN** 八项门禁全部记为 `SKIP（无 UI 变更）`，结论按非 UI 校验项给出

---

### Requirement: 门禁脚本与自动化分级

模板包 MUST 提供 `scripts/onepress-gate.sh`，在任意目标仓库根目录可运行，自动实现门禁 2、4、5、6、7，并对门禁 1、3、8 输出 `MANUAL` 提示。退出码约定：存在 `FAIL` 时为非 `0`，全部 `PASS` 或 `SKIP` 时为 `0`。脚本 MUST NOT 要求 Python3 或第三方包；对比度计算 MUST 在脚本内以 `awk` 完成。

#### Scenario: 违规代码导致非零退出

- **GIVEN** 目标仓库某个 `.tsx` 文件含 `style={{ color: '#3b82f6' }}` 与 `w-[317px]`
- **WHEN** 执行门禁脚本
- **THEN** 脚本以非 `0` 退出，并逐条列出命中的文件与行号

#### Scenario: 工具缺失记为 SKIP

- **GIVEN** 目标仓库没有 `node_modules`
- **WHEN** 执行门禁脚本
- **THEN** 门禁 4 记为 `SKIP（vitest 不可用）`，门禁 2/5/6/7 仍正常执行，脚本不崩溃

#### Scenario: 对比度由 awk 计算

- **GIVEN** 组件 CSS 中 `--background: #ffffff` 与 `--foreground: #777777`
- **WHEN** 执行门禁 2
- **THEN** 脚本计算出对比度约 4.48:1 并判定 `FAIL`（低于 4.5:1），全程未调用 Python

#### Scenario: 人工项被显式标注

- **GIVEN** 任意一次门禁脚本执行
- **WHEN** 查看输出
- **THEN** 门禁 1、3、8 以 `MANUAL` 前缀输出，不出现 `PASS` 字样

---

### Requirement: 组件注册表结构与追加

安装器首次初始化 `docs/ui-components.md` 时 MUST 使用四列表头：`组件名称`、`路径`、`适用骨架 (Archetype)`、`核心 Props 签名`，并按 `base` 与 `domain` 两个分区组织。`/opsx:archive` MUST 将本次新建或改造的可复用组件追加为表格行，MUST NOT 重排或删除历史行。安装器遇到列结构不一致的既有注册表时 MUST 输出迁移 `WARN` 并给出目标表头，MUST NOT 改写文件。

#### Scenario: 首装表头四列

- **GIVEN** 目标仓库不存在 `docs/ui-components.md`
- **WHEN** 执行 onePress 安装
- **THEN** 初始化文件包含两个分区，每个分区表头为 `组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名`

#### Scenario: 归档只追加不重排

- **GIVEN** 注册表 `domain` 分区已有 3 行历史记录
- **WHEN** 归档一个新增 1 个业务组件的变更
- **THEN** 该组件作为第 4 行追加，既有 3 行内容与顺序保持不变

#### Scenario: 无归档命令时用脚本追加

- **GIVEN** 目标仓库已安装 onePress，且当前 harness 不提供 `/opsx:archive`（如 OpenCode）
- **WHEN** 执行 `bash scripts/onepress-registry-append.sh --root . --name <Name> --path <path> --archetype <Archetype>`
- **THEN** 该组件作为新行追加到 `--section` 指定分区（默认 `domain`），重复执行不产生第二行，且其它分区逐字节不变

#### Scenario: 旧表结构只警告不改写

- **GIVEN** 目标仓库已存在六列旧表
- **WHEN** 执行安装或升级
- **THEN** 输出一条迁移 `WARN` 并附目标四列表头，文件内容逐字节保持不变
