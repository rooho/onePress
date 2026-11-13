# V3.1 极简融合版：设计推理内核修复 + 三级编码前评审门禁

> **文档定位**：onePress 后续迭代纲领性文件（V3.1），是 `blueprint/BLUEPRINT-V3.0.md` 的修复与改良版。
>
> **基线**：`blueprint/BLUEPRINT-V3.0.md`（UI/UX Pro Max 融入 V3.0 极简融合版研发体系）。
>
> **来源**：Gemini 分享页《UI/UX Pro Max 融入 V3.0 极简融合版：深度架构评审与编码前设计评审门禁落地指南》（2026-11-13 全文转换）。
>
> **一句话结论**：V3.0 的架构方向正确（完成度 90%+），但存在 **5 个源码级工程陷阱**会在编码期造成样式失效或规则静默绕过；同时从 `ui-spec.md` 到 `/opsx:apply` 之间缺少**编码前评审环节**。V3.1 用「5 个补丁 + 三级门禁（`/opsx:review`）」闭合这两处缺口。

## 目录

- [零、V3.1 相对 V3.0 的变更清单](#零v31-相对-v30-的变更清单)
- [一、V3.0 架构体检：四个保留项与五个必须修复的陷阱](#一v30-架构体检四个保留项与五个必须修复的陷阱)
- [二、问题诊断：为什么"设计完直接写代码"必然漏检](#二问题诊断为什么设计完直接写代码必然漏检)
- [三、V3.1 三级编码前评审门禁（`/opsx:review`）](#三v31-三级编码前评审门禁opsxreview)
- [四、V3.1 补丁包](#四v31-补丁包)
- [五、落地到 onePress 的资产映射与依赖策略](#五落地到-onepress-的资产映射与依赖策略)
- [六、迁移顺序与验收](#六迁移顺序与验收)
- [七、风险与开放问题](#七风险与开放问题)

---

## 零、V3.1 相对 V3.0 的变更清单

| # | V3.0 现状 | V3.1 变更 | 修复的问题 |
|---|-----------|-----------|-----------|
| 1 | 假设 `colors.csv` 16 通道可"无损写入 Shadcn" | 增加 **16 通道 × 双模式映射表**，强制 `On *` → `*-foreground` 重命名，并同时产出 `:root` / `.dark` 两套值 | 陷阱一：变量命名断层 + 单模式输出 |
| 2 | SOP 第三步只生成 `MASTER.md` | 生成后**立即重写顶部 LOGIC Banner**，指向 `ui-spec.md` | 陷阱二：隐式双源寻址回归 |
| 3 | 直接使用 `--motion` 输出 | 只提取时长/缓动/交错参数；除非 `package.json` 有 `gsap`，否则禁止引入 GSAP | 陷阱三：动效栈冲突 |
| 4 | SOP 示例用中文查询词 | 强制 `<query>` 为 2–5 个**英文**领域词，含 `dashboard`/`data_heavy`/`checkout` 等信号词 | 陷阱四：推理规则静默失效 |
| 5 | 未用 `--json`、未清理测试夹具、未读 `pro-rules.md` | 补丁 2 清理 `scripts/tests` 与 `validate_data.py`；检索可加 `--json`；L2 盲审必读 `pro-rules.md` | 陷阱五：冗余与交付前核对缺失 |
| 6 | `ui-spec.md` → `/opsx:apply` 之间只有"肉眼验收" | 插入 **三级门禁 `/opsx:review`**：L1 确定性预检 / L2 冷上下文盲审 / L3 DOM 点选批注 + 契约锁定 | 缺少编码前评审环节 |

---

## 一、V3.0 架构体检：四个保留项与五个必须修复的陷阱

### 1.1 四个必须保留的架构决策

对照 `nextlevelbuilder/ui-ux-pro-max-skill` 主干源码与第三方静态审计，V3.0 的以下四个裁剪策略被底层实现印证，**V3.1 全部保留**：

1. **剥离 6 个伴生技能**：`uipro init` 默认写入 7 个目录 / 172 文件 / 约 4.8 MB，其中 `banner-design`、`brand`、`design`、`design-system`、`slides`、`ui-styling` 含外部图像 API 或 `npx` 调用。仅保留核心 `ui-ux-pro-max`（73 文件 / 约 3.6 MB），运行期退化为 Python 3 标准库对本地 CSV 的只读检索。
2. **确定性推理替代模型均值**：192 条行业推理规则、192 套调色板、74 组字体配对、119–120 条 UX 指南、79–80 种风格库，把"审美"转成可逐项核销的规则。
3. **单源契约**：砍掉 `--page` 持久化，`MASTER.md` 只做项目级基线，变更级决策唯一收敛到 `openspec/changes/<name>/ui-spec.md`。
4. **前后端分流 + 双步检索**：纯后端跳过；检索顺序固定"先 `--domain ux`、后 `--stack shadcn|html-tailwind`"。

### 1.2 五个必须修复的陷阱（基于源码级核查）

#### 陷阱一：Shadcn UI 变量命名断层与单模式输出局限

**现象**：`design_system.py` 的 `SEMANTIC_COLOR_ENTRIES` 中，主色/次色/强调色/危险色上的文本色采用 Material 风格 `On *` 命名：

| `design_system.py` 输出 | Shadcn UI 实际需要 |
|---|---|
| `--color-on-primary` | `--primary-foreground`（`--color-primary-foreground`） |
| `--color-on-secondary` | `--secondary-foreground` |
| `--color-on-accent` | `--accent-foreground` |
| `--color-on-destructive` | `--destructive-foreground` |

其余 3 项（`--color-foreground`、`--color-card-foreground`、`--color-muted-foreground`）命名一致。

**第二处差异**：`_resolve_color_mode()` 单次运行只输出**一种**模式（light 或 dark），不生成 `:root` + `.dark` 两套表；且 `_derive_dark_palette()` 不是明度反转，而是替换为固定暗色表面值（`Background #0F172A`、`Foreground #F8FAFC`、`Card #111827`、`Card Foreground #F8FAFC`、`Muted #1E293B`、`Muted Foreground #CBD5E1`、`Border #334155`；焦点环从 `Ring`/`Accent`/`Primary`/`#60A5FA` 中按 WCAG ≥3:1 筛选，默认回退 `#60A5FA`）。

**影响**：Agent 照搬变量名后，`<Button>` / `<Badge>` 因找不到 `text-primary-foreground` 出现文字色丢失或对比度失控；暗色模式无法在沙箱中切换验证。

**修复动作**：补丁 1（16 通道映射表）+ 补丁 4 第三步（强制双态输出）。

#### 陷阱二：MASTER.md 顶部硬编码 Logic Banner 引发隐式双源寻址

**现象**：`--persist` 生成 `MASTER.md` 时，脚本在第 1–5 行写入：

```text
> **LOGIC:** When building a specific page, first check design-system/pages/[page-name].md.
> If that file exists, its rules **override** this Master file.
```

**影响**：Agent 读到这段强势指令（大写 `LOGIC:` + 加粗 `override`）后会尝试检查甚至创建 `design-system/pages/*.md`，架空 `ui-spec.md`，正是 V3.0 第二章要消除的双源冲突。

**修复动作**：补丁 2 的头部重写脚本，把寻址目标替换为 `openspec/changes/[change-name]/ui-spec.md`，并显式禁止创建 `pages/*.md`。

#### 陷阱三：motion 旋钮默认挂载 GSAP 代码，与 Tailwind 极简栈冲突

**现象**：`--motion <1-10>` 映射为 `1-3 Subtle` / `4-7 Standard` / `8-10 Complex`，随后调用 `search(f"{query} {tier}", "gsap", 5)` 从 `motion.csv`（17 套 GSAP 预设）检索并挂载 **GSAP JavaScript 骨架代码**。

**影响**：未安装 `gsap` 的项目（Shadcn 惯例是 CSS Transitions / `tailwindcss-animate`）会被诱导写出无法编译的 import，违背 `SKILL.md` "Never Assume a Stack" 准则。

**修复动作**：只取时长（150–250ms）、缓动曲线、交错延迟参数，一律映射为 Tailwind 过渡类 + `prefers-reduced-motion` 降级；除非 `package.json` 已声明 `gsap`。

#### 陷阱四：reasoning_contract.py 英文词边界正则与中文查询失配

**现象**：`reasoning_contract.py` 是封闭的确定性规则求值器，`CONDITION_SIGNALS` 用预编译英文词边界正则 `re.compile(r"(?<!\w)" + re.escape(signal) + r"(?!\w)")` 匹配（输入经 `.casefold()`），据此激活 `if_booking` / `if_checkout` / `if_dashboard` / `if_data_heavy` / `if_luxury` / `if_mobile` 等分支；`core.py` 的 BM25 + 正则混合检索所索引的 17 个 CSV 也全是英文语料。

**影响**：传中文关键词（如 `"数据看板 紧凑"`、`"弹窗焦点管理"`）会 0 命中，192 条推理规则静默失效。

**修复动作**：SOP 强制 `search.py` 的 `<query>` 必须翻译为 2–5 个标准英文领域词，优先包含上述信号词；0 结果时缩窄关键词重试一次。

#### 陷阱五：未启用 `--json`、未清理测试冗余、漏读 `pro-rules.md`

**现象**：核心目录 73 个文件中含维护者专用的 `scripts/validate_data.py` 与 `scripts/tests/`（13 个测试与 Fixture 文件），运行期完全不需要；`search.py` 原生支持 `--json`；`uipro init` 还会生成 `references/pro-rules.md`（`SKILL.md` 第 6 步要求交付前核对图标纪律、交互反馈、明暗对比度、安全区、移动端无障碍）。

**影响**：多 14 个非运行期文件；用 ASCII 表格解析 Token 不稳；交付前核对缺一环。

**修复动作**：补丁 2 追加清理；需要脚本提取 Token 时用 `--json`；L2 盲审把 `pro-rules.md` 列为必读输入。

---

## 二、问题诊断：为什么"设计完直接写代码"必然漏检

V3.0 现行流程是：`/opsx:new` 产出 `ui-spec.md` + `sandbox-preview.html` → 人类肉眼验收 → `/opsx:apply` 写代码 → 最后才 `/opsx:verify`。这是"重事后验证、轻事前评审"，存在三大短板：

1. **人类肉眼对量化规范存在感知盲区**：无法判断某段次要文本是 4.6:1 还是 3.9:1，无法逐一测量 44×44px 热区，也容易忽略暗色下 `Border` 与背景融为一体。
2. **同会话自审顺从偏见（Self-Review Bias）**：刚生成契约的同一会话去检查自己，上下文里全是自己的推理历史，倾向于认为已满足要求。
3. **终端描述 UI 的摩擦极高**：看到某张卡片间距别扭，要用自然语言说清"是哪个 DOM 节点、改成什么"，往往多轮拉扯，浪费 Token 并引发上下文腐烂。

### 2026 主流"编码前评审"范式对比

| 范式 | 代表工具 | 机制与介入时机 | 强项 / 盲区 | 成本 | 与 V3.1 的契合度 |
|---|---|---|---|---|---|
| 1. 规范步进生成 + 双向无代码修正环 | OpenSpec Expanded Profile（`/opsx:continue` + `/opsx:update`） | 放弃 `/opsx:ff` 一步生成，按依赖图逐个产出；发现缺陷用 `/opsx:update` 在不碰业务代码的前提下双向同步 `design`/`specs`/`proposal` | 强项：天然维护契约一致性、支持反向冒泡；盲区：自身不做 UI/UX 与可访问性检测 | 极低（只改 Markdown） | **原生底座，100% 兼容** |
| 2. 独立上下文子代理盲审 + 浏览器视觉伴侣 | `obra/superpowers`（`spec-document-reviewer` + Visual Companion） | 派生零历史子代理对照规范审查，默认上限 5 轮；本地 `server.cjs` 渲染候选并回传点击事件 | 强项：消除自审偏见、强制 YAGNI；盲区：轮数不设限会陷入修补拉锯、耗 Token（Issue #2112） | 中 | **高**：可直接复用 |
| 3. 确定性 AI Slop 扫描 + 双子代理打分 | `pbakaus/impeccable`（`critique` + `audit` + 62 条规则）、`vercel-labs/web-design-guidelines` | 62 条无 LLM 规则扫 Slop；`critique` 派两个隔离子代理做尼尔森 10 项 0–4 分（40 分制）与技术审计（20 分制），按 P0–P3 出报告不改代码 | 强项：把"好看"量化成 40 分、专杀 Slop；盲区：全套 24 个命令与现有体系重叠 | 低–中 | **极佳评审内核**：只吸收评分表与 Slop 规则 |
| 4. 无障碍树 + 无头浏览器毫秒预检 | Playwright CLI/MCP + `@axe-core/playwright` | 直接加载页面，暴露结构化可访问性树，注入 axe-core 扫 WCAG 2.0/2.1/2.2 AA 与元素几何 | 强项：单页 **200–500ms**；axe-core 可捕获约 **57%** 无障碍缺陷；盲区：判断不了构图美感与文案语义 | 极低（本地执行，仅报错回传选择器） | **高**：把 DOM/A11y 检查左移到沙箱阶段 |
| 5. 真实 DOM 锚点批注 + 选择器级回传 | `ai-html-annotation`、`Agentation`、`Framesmith MCP` | `Ctrl/⌘ + Click` 在真实 DOM 打点，一键导出「CSS 选择器 + 元素 HTML + 批注」推给 Agent | 强项：消灭"用文字描述位置"的损耗；盲区：依赖人工点选 | 零额外 Token | **极简内嵌即可** |

---

## 三、V3.1 三级编码前评审门禁（`/opsx:review`）

**设计哲学**：能用机器毫秒级测准的绝不消耗 Token（L1）；能用独立子代理盲审拦截的绝不劳烦程序员肉眼（L2）；需要人类拍板的必须提供指哪打哪的 DOM 级反馈（L3）。

在 `/opsx:new` 与 `/opsx:apply` 之间插入标准动作：**`/opsx:review <change-name>`（Pre-Apply Gate）**。

### 3.1 L1：Playwright + axe-core 确定性预检（200–500ms，零 Token）

针对 `sandbox-preview.html` 自动遍历 **8 种组合**（Idle / Loading / Error / Empty × Light / Dark），完成四项硬性断言：

| # | 断言 | 判据 |
|---|---|---|
| 1 | WCAG 2.2 AA 扫描 | `AxeBuilder.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])` 零 violations |
| 2 | 触控热区几何 | 所有 `button/a/input/select/[role=button]` 渲染宽高 `≥44`（行内文本链接除外） |
| 3 | 多视口零横向溢出 + CLS | 375/768/1024/1280 下 `scrollWidth ≤ clientWidth`；`Loading` 与 `Idle` 主容器高度差在阈值内 |
| 4 | 反模式清零 | 无 Emoji 充当功能图标；样式表无硬编码 Hex（未走 CSS 变量） |

**失败处置**：非 0 violations 时，生成端 Agent 直接按返回的 `offending selectors` 原地修 `ui-spec.md` 与 `sandbox-preview.html`，无需人类介入；0 violations 才允许进 L2。

### 3.2 L2：独立上下文子代理盲审（Cold-Context Critique，上限 3 轮）

**输入四件套（只读，且严禁携带生成时的对话历史）**：

1. `docs/design-system/projectbaseline/MASTER.md`
2. `openspec/changes/<name>/ui-spec.md`
3. `openspec/changes/<name>/sandbox-preview.html` 源码（或 Playwright 导出的可访问性快照树）
4. `ui-ux-pro-max/references/pro-rules.md`

**三项评估**：

- **契约完整性**：5+1 章节无遗漏；无 `TODO` / `TBD` / "适当调整" 等模糊词；未触犯第 6 节行业反模式黑名单。
- **Critique 40 分制**：尼尔森 10 大可用性原则各 0–4 分（不适用记 `n/a` 后折算）；两项硬性认知负荷检查——**单层列表 ≤8 个未分组项**、**单一决策点 ≤4 个并列可见选项**；同时比对 62 类 AI Slop 特征（局促内边距、跳级标题、缺按压态等）。
- **Audit 20 分制**：A11y / 性能预留（CLS 与动效开销）/ 主题变量覆盖度 / 响应式排版 / 实现完整性，各 0–4 分；缺陷标 `P0 Blocking` / `P1 Major` / `P2 Minor` / `P3 Polish`。

**准入线（三项同时满足）**：

```text
P0 = 0 且 P1 = 0
Critique ≥ 28 / 40   （36–40 Excellent，20–27 Acceptable）
Audit    ≥ 14 / 20   （18–20 Excellent，10–13 Acceptable）
```

**有界自愈**：未达标时主控 Agent 自动修正并重跑 L1+L2，**最多 3 轮**（比 Superpowers 默认 5 轮更克制）；3 轮后仍有争议 ⇒ 挂起并携带差异摘要交 L3 人类裁决。

### 3.3 L3：人类真实 DOM 点选批注 + 契约锁定

1. 输出《编码前设计评审通行证》：L1 扫描结果 + L2 双量表得分 + P2/P3 建议项。
2. 打开 `sandbox-preview.html`，通过内嵌的 **Pin for AI** 脚本（约 30 行原生 JS，零依赖）：`Alt/⌘ + 左键` 点选元素 → 填写修改意图 → 自动复制「CSS 选择器 + 当前类名 + 元素 HTML 片段 + 批注」。
3. 在终端执行 `/opsx:update <change-name> "<粘贴的结构化批注>"`，Agent 双向同步 `ui-spec.md` 与 `sandbox-preview.html`，不碰业务代码。
4. 批准后在 `ui-spec.md` 头部写入 `Review-Status: APPROVED`。
5. **`/opsx:apply` 执行前必须校验该标记；未签署的契约严禁进入 React 编码阶段。**

### 3.4 与 `/opsx:verify` 八门禁的分工

| 阶段 | 门禁 | 检查对象 | 成本 |
|---|---|---|---|
| 编码前（V3.1 新增） | L1 确定性预检 | `sandbox-preview.html` | 200–500ms / 页，零 Token |
| 编码前 | L2 冷上下文盲审 | `MASTER.md` + `ui-spec.md` + 沙箱 + `pro-rules.md` | 一次独立短上下文，≤3 轮 |
| 编码前 | L3 人类批注 + 契约锁定 | `ui-spec.md` 的 `Review-Status` | 人工 |
| 编码后（V3.0 已有） | `/opsx:verify` 八门禁 | 真实组件代码 | 脚本 + 人工 |

**关系**：L1/L2/L3 **不替代** verify，只把"可量化缺陷"左移，verify 继续负责实现与沙箱的一致性、类型、Token 纯净度与状态机单测。

---

## 四、V3.1 补丁包

### 补丁 1：16 通道 × 双模式无损映射表（增补至 `ui-spec.md` 第二章）

| 序号 | `colors.csv` 角色名 | `MASTER.md` 原始变量名 | **Shadcn 标准变量名（强制目标）** | Tailwind 实用类 | `.dark` 取值策略 |
|---|---|---|---|---|---|
| 1 | `Primary` | `--color-primary` | **`--primary`** | `bg-primary` / `border-primary` | 保持品牌主色或提亮，确保与 `#0F172A` 对比达标 |
| 2 | `On Primary` ⚠️ | `--color-on-primary` ⚠️ | **`--primary-foreground`** | `text-primary-foreground` | 与 `--primary` ≥4.5:1 |
| 3 | `Secondary` | `--color-secondary` | **`--secondary`** | `bg-secondary` | 暗色次级表面（参考 `#1E293B`） |
| 4 | `On Secondary` ⚠️ | `--color-on-secondary` ⚠️ | **`--secondary-foreground`** | `text-secondary-foreground` | 与 `--secondary` ≥4.5:1 |
| 5 | `Accent/CTA` | `--color-accent` | **`--accent`** | `bg-accent` | 悬停/强调表面或高对比 CTA |
| 6 | `On Accent/CTA` ⚠️ | `--color-on-accent` ⚠️ | **`--accent-foreground`** | `text-accent-foreground` | 与 `--accent` ≥4.5:1 |
| 7 | `Background` | `--color-background` | **`--background`** | `bg-background` | 暗色主背景（基准 `#0F172A`） |
| 8 | `Foreground` | `--color-foreground` | **`--foreground`** | `text-foreground` | 暗色主文本（基准 `#F8FAFC`） |
| 9 | `Card` | `--color-card` | **`--card`** | `bg-card` | 暗色卡片表面（基准 `#111827`，与背景拉开明度差） |
| 10 | `Card Foreground` | `--color-card-foreground` | **`--card-foreground`** | `text-card-foreground` | 暗色卡片文本（基准 `#F8FAFC`） |
| 11 | `Muted` | `--color-muted` | **`--muted`** | `bg-muted` | 暗色弱化背景（基准 `#1E293B`） |
| 12 | `Muted Foreground` | `--color-muted-foreground` | **`--muted-foreground`** | `text-muted-foreground` | 暗色次要文本（基准 `#CBD5E1`，严禁灰字配灰底） |
| 13 | `Border` | `--color-border` | **`--border`**（同步 `--input`） | `border-border` | 暗色高可见边框（基准 `#334155`） |
| 14 | `Destructive` | `--color-destructive` | **`--destructive`** | `bg-destructive` | 危险/错误语义主色 |
| 15 | `On Destructive` ⚠️ | `--color-on-destructive` ⚠️ | **`--destructive-foreground`** | `text-destructive-foreground` | 与 `--destructive` ≥4.5:1 |
| 16 | `Ring` | `--color-ring` | **`--ring`** | `ring-ring` | 依次校验 `Ring`/`Accent`/`Primary`/`#60A5FA`，取与暗底 ≥3:1 者 |

> Tailwind v4：在 `:root` 与 `.dark` 定义 16 个变量后，于 `@theme inline` 中声明 `--color-primary: var(--primary); --color-primary-foreground: var(--primary-foreground);` 等映射，即可激活 Shadcn 组件类名。

### 补丁 2：SOP 清理与 `MASTER.md` 头部重写

```bash
# [SOP 第二步增强] 剔除 6 个伴生技能 + 核心技能内的测试夹具与维护脚本
rm -rf .qoder/skills/banner-design \
       .qoder/skills/brand \
       .qoder/skills/design \
       .qoder/skills/design-system \
       .qoder/skills/slides \
       .qoder/skills/ui-styling \
       .qoder/skills/ui-ux-pro-max/scripts/tests \
       .qoder/skills/ui-ux-pro-max/scripts/validate_data.py

# [SOP 第三步增强] 生成项目全局视觉基线 MASTER.md
python3 .qoder/skills/ui-ux-pro-max/scripts/search.py \
  "B2B SaaS analytics dashboard data_heavy modern clean" \
  --design-system \
  --variance 4 --motion 3 --density 8 \
  --persist -p "ProjectBaseline" \
  --output-dir "./docs"

# 将顶部指向 design-system/pages/[page-name].md 的指令改为 OpenSpec 单源契约路径
python3 -c '
p = "./docs/design-system/projectbaseline/MASTER.md"
with open(p, "r", encoding="utf-8") as f:
    content = f.read()
content = content.replace(
    "design-system/pages/[page-name].md",
    "openspec/changes/[change-name]/ui-spec.md (DO NOT create design-system/pages/*.md)"
)
with open(p, "w", encoding="utf-8") as f:
    f.write(content)
'
```

### 补丁 3：L1 预检脚本 + L3 点选批注器

#### 3.1 L1 预检脚本（Playwright + axe-core）

```ts
// scripts/sandbox-preflight.spec.ts
// 用法: SANDBOX_PATH="openspec/changes/my-feature/sandbox-preview.html" npx playwright test scripts/sandbox-preflight.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import path from 'path';

const sandboxPath = process.env.SANDBOX_PATH;
if (!sandboxPath) throw new Error('请指定 SANDBOX_PATH 环境变量');
const fileUrl = `file://${path.resolve(sandboxPath)}`;

const STATES = ['idle', 'loading', 'error', 'empty'];
const THEMES = ['light', 'dark'];

test.describe('V3.1 编码前沙箱原型确定性门禁 (L1 Pre-Flight)', () => {
  for (const theme of THEMES) {
    for (const state of STATES) {
      test(`[${theme.toUpperCase()} / ${state.toUpperCase()}] A11y 对比度、触控热区与防破版校验`, async ({ page }) => {
        await page.setViewportSize({ width: 1280, height: 800 });
        await page.goto(fileUrl);

        // 1. 切换沙箱顶栏主题与四态（约定控制栏按钮带 data-set-theme / data-set-state）
        const themeBtn = page.locator(`[data-set-theme="${theme}"]`);
        if (await themeBtn.count() > 0) await themeBtn.click();
        const stateBtn = page.locator(`[data-set-state="${state}"]`);
        if (await stateBtn.count() > 0) await stateBtn.click();

        // 2. Axe-core WCAG 2.2 AA 扫描
        const axeResults = await new AxeBuilder({ page })
          .exclude('#sandbox-control-bar')
          .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
          .analyze();
        expect(axeResults.violations, `WCAG 违规项: ${JSON.stringify(axeResults.violations, null, 2)}`).toEqual([]);

        // 3. 交互控件最小热区 >= 44x44px
        const undersizedTargets = await page
          .locator('main button, main [role="button"], main input, main select, main a[class*="btn"]')
          .evaluateAll((els) =>
            els
              .filter((el) => {
                const style = window.getComputedStyle(el);
                return style.display !== 'none' && style.visibility !== 'hidden';
              })
              .map((el) => {
                const rect = el.getBoundingClientRect();
                return {
                  tag: el.tagName,
                  text: (el.textContent || el.getAttribute('aria-label') || '').trim().slice(0, 24),
                  width: Math.round(rect.width),
                  height: Math.round(rect.height),
                };
              })
              .filter((item) => item.width < 44 || item.height < 44)
          );
        expect(undersizedTargets, `发现小于 44x44px 的交互热区`).toEqual([]);

        // 4. 375px 窄屏零横向滚动
        await page.setViewportSize({ width: 375, height: 812 });
        const hasHorizontalOverflow = await page.evaluate(() => {
          return document.documentElement.scrollWidth > document.documentElement.clientWidth;
        });
        expect(hasHorizontalOverflow, '375px 窄屏下出现横向滚动溢出').toBe(false);
      });
    }
  }
});
```

#### 3.2 L3 DOM Pin-to-AI 批注器（生成 `sandbox-preview.html` 时自动注入）

```html
<!-- V3.1 L3 DOM Pin-to-AI 轻量批注器（仅作用于沙箱预览，不进入生产代码） -->
<script>
document.addEventListener('click', (e) => {
  if (!(e.altKey || e.metaKey) || e.target.closest('#sandbox-control-bar')) return;
  e.preventDefault();
  e.stopPropagation();
  const el = e.target;
  const note = prompt('输入针对该元素的 UI/UX 修改意见（将自动连同选择器复制给 /opsx:update）：');
  if (!note) return;
  const getSelector = (node) => {
    const parts = [];
    while (node && node.nodeType === 1 && node.tagName !== 'BODY') {
      let sel = node.tagName.toLowerCase();
      if (node.id) { sel += '#' + node.id; parts.unshift(sel); break; }
      const cls = Array.from(node.classList).slice(0, 2).join('.');
      if (cls) sel += '.' + cls;
      parts.unshift(sel);
      node = node.parentElement;
    }
    return parts.join(' > ');
  };
  const payload = `/opsx:update [change-name] "【沙箱视觉批注】目标选择器: \`${getSelector(el)}\` | 当前类名: \`${el.className}\` | 元素片段: \`${el.outerHTML.slice(0, 140)}...\` | 修改要求: ${note}"`;
  navigator.clipboard.writeText(payload).then(() => {
    el.style.outline = '2px dashed #D93025';
    alert('已复制精准修改指令！请直接粘贴至 Qoder 终端执行。');
  });
}, true);
</script>
```

### 补丁 4：V3.1 完整契约规则（替换 V3.0 末尾的强制前置动作）

> 源文档中本章节标记为 "V3.0.1"，本文统一为 V3.1。以下规则正文可直接粘贴进项目文档。

```markdown
## 前端 UI 变更强制前置动作与编码前评审门禁（UI/UX Pro Max 赋能规则 V3.1）

当判定 `/opsx:new <change-name>` 包含前端 UI 变更时，严禁凭空猜测配色、排版与交互细节，且**严禁在未通过 `/opsx:review` 三级门禁前直接执行 `/opsx:apply` 编写业务代码**。必须严格按顺序执行以下五步闭环：

1. **第一步：读取全局视觉基线（单源对齐）**：首先读取 `docs/design-system/projectbaseline/MASTER.md`（若不存在，调用 `python3 .qoder/skills/ui-ux-pro-max/scripts/search.py "<英文产品类型与风格关键词>" --design-system --variance <1-10> --motion <1-10> --density <1-10> --persist -p "ProjectBaseline" --output-dir "./docs"` 生成，并将顶部 `design-system/pages/[page-name].md` 提示替换为 `openspec/changes/[change-name]/ui-spec.md`）。严禁使用 `--page` 参数在 `design-system/` 下生成单页覆盖文件，所有变更级设计决策唯一收敛于 `openspec/changes/<change-name>/ui-spec.md`。
2. **第二步：英文信号词双步确定性检索（Semantic UX First, Stack Second）**：每次调用 `search.py` 必须使用 2–5 个标准英文关键词（优先包含 `dashboard`、`data_heavy`、`checkout`、`booking`、`mobile`、`luxury` 等推理触发词；若返回 0 结果则缩窄关键词重试一次），并可附加 `--json` 获取结构化字段。先执行语义检索 `python3 .qoder/skills/ui-ux-pro-max/scripts/search.py "<English UX/A11y keywords>" --domain ux`，后执行技术栈检索 `--stack shadcn` 与 `--stack html-tailwind`。
3. **第三步：契约无损转换注入与高保真沙箱生成**：将 `MASTER.md` 的 16 个语义色彩角色写入 `ui-spec.md` 第二章时，必须将 `--color-on-primary`、`--color-on-secondary`、`--color-on-accent`、`--color-on-destructive` 转换为 Shadcn 标准命名 `--primary-foreground`、`--secondary-foreground`、`--accent-foreground`、`--destructive-foreground`，并同时列出 `:root`（Light）与 `.dark`（Dark，按相对亮度公式保障背景 `#0F172A`、卡片 `#111827`、次要文本 `#CBD5E1`、边框 `#334155` 及焦点环对比度 ≥3:1）双套变量表；读取 `--motion` 推荐的过渡时序（150–250ms）与缓动参数写入第五章（除非 `package.json` 已显式安装 `gsap`，否则严禁引入 GSAP 依赖，一律映射为 Tailwind CSS 过渡类与 `prefers-reduced-motion` 降级规则）；最后基于上述精确 Token 生成 `sandbox-preview.html`，顶部固定 `#sandbox-control-bar`（内置 `[data-set-state="idle|loading|error|empty"]` 四态切换按钮、`[data-set-theme="light|dark"]` 明暗切换按钮及 `Alt/⌘+Click` DOM 点选批注器）。
4. **第四步：执行编码前三级设计评审门禁（`/opsx:review <change-name>`）**：在进入 `/opsx:apply` 之前，依次执行 L1 确定性自动化预检（运行 Playwright + `@axe-core/playwright` 遍历 4 状态 × 2 主题共 8 种视图，确保 WCAG 2.2 AA 零违规、交互控件几何尺寸 ≥44×44px、375px 视口零横向滚动、零 Emoji 图标）、L2 独立子代理盲审（派生零历史记忆的 Reviewer 子代理核查 `MASTER.md`、`ui-spec.md`、`sandbox-preview.html` 与 `references/pro-rules.md`，确保单层列表项 ≤8 个、单决策点并列操作 ≤4 个、62 类 AI Slop 清零、行业 Anti-Patterns 一票否决，满足 P0 = 0、P1 = 0、Critique ≥28/40 且 Audit ≥14/20，自动修复循环上限 3 轮）以及 L3 人类视觉点选批注与契约锁定（通过 `/opsx:update` 同步修订并在 `ui-spec.md` 顶部写入 `Review-Status: APPROVED`）。
5. **第五步：解锁 `/opsx:apply` 与 `/opsx:verify`**：仅当校验到 `openspec/changes/<change-name>/ui-spec.md` 包含 `Review-Status: APPROVED` 时，才允许启动 `/opsx:apply` 执行 Superpowers CDD 三步编码循环（静态 UI 编写 → 状态断言测试 → 接口接入），并在编码完成后执行 `/opsx:verify` 8 项终验门禁与 `/opsx:archive` 归档。

```

---

## 五、落地到 onePress 的资产映射与依赖策略

> 本节为 V3.0 → V3.1 的工程落地口径，供后续 OpenSpec 变更直接引用。

| V3.1 要素 | 落点文件 | 说明 |
|---|---|---|
| 16 通道映射表（补丁 1） | `openspec-schema/superspec/templates/ui-spec.md` 第 2.1 节 + 镜像目录 | 表头从"通道 / Light / Dark / CSS 变量"升级为含 `On *` 强制重命名与 `.dark` 取值策略 |
| MASTER.md 头部重写（补丁 2） | `qoder|trae|cursor/skills/onepress-discipline/SKILL.md` 铁律 7；`opencode/agent/ux-architect.md` | 生成基线后立即替换 Logic Banner |
| 英文查询词纪律（陷阱四） | 同上铁律 7 + `opencode/commands/opsx-new.md` Step 2 | `search.py` 的 `<query>` 必须英文；0 命中重试一次 |
| 动效栈约束（陷阱三） | 铁律 8 + `opencode/commands/opsx-apply.md` | 除非 `package.json` 有 `gsap`，只取时长/缓动 |
| L1 预检 | 新增 `scripts/sandbox-preflight.spec.ts`（目标仓库侧，可选）+ `scripts/onepress-gate.sh` 增加 `--require-review` | Playwright 缺失时记 `SKIP`，不阻断 |
| L2 盲审 | 新增命令体 `opsx-review.md`（四 harness 各一份，**新增文件而非改写既有命令**）+ 复用 `ux-architect` 的只读输入约定 | 评分表与准入线写入命令体 |
| L3 批注器 | `ui-spec.md` 第 7 节"沙箱预览"增加 `#sandbox-control-bar` 与 Pin-to-AI 要求；`sandbox-preview.html` 生成时注入 | 纯内联 JS，零依赖 |
| `Review-Status` 闸 | `schema.yaml` 的 `apply` 块增加前置校验；`onepress-gate.sh` 增加门禁 0.5 | 未签署时 `FAIL`，仅在 `--require-review` 下生效 |
| 依赖策略 | `install.sh` / `install.ps1` 的探测段 | Playwright / axe-core 与 `ui-ux-pro-max` 同属**可选增强层**：缺失即 `SKIP`，不影响安装与基础门禁 |

**新增命令 vs 不改写原则**：`/opsx:review` 不在 OpenSpec 1.13 的 12 个原生命令内，落地方案是**新增** `opsx-review.md`（四 harness 各一份）。这属于"新增文件"，不违反既有需求中"不得改写既有命令主体"的约束；但需同步更新模板包白名单与安装清单。

---

## 六、迁移顺序与验收

| 阶段 | 内容 | 产物 | 验收 |
|---|---|---|---|
| P0 | 补丁 1 + 陷阱四/三的文本纪律 | `ui-spec.md` 模板第 2 节、三份 carrier skill 铁律 7/8 | `verify-carriers.sh` 21/21；模板双目录 `diff` 无差异 |
| P1 | 补丁 2（清理 + 头部重写） | 三份 skill + `ux-architect.md` 的 SOP 段 | 手工跑一次基线生成，确认 `MASTER.md` 顶部已指向 `ui-spec.md` |
| P2 | L1 预检脚本 + `--require-review` | `scripts/sandbox-preflight.spec.ts`、`onepress-gate.sh` | 用违规沙箱跑出非零退出；无 Playwright 时记 `SKIP` |
| P3 | L2/L3 命令体 + `Review-Status` 闸 | 四份 `opsx-review.md`、`schema.yaml` apply 前置校验 | 未签署时 `/opsx:apply` 被拦；签署后放行 |
| P4 | 安装器与文档 | `install.sh`/`install.ps1` 探测段、`INSTALL_PROMPT.md`、`ASSETS.md`、README | 四 harness 安装矩阵回归；`openspec validate --all` 通过 |

---

## 七、风险与开放问题

| # | 风险 | 缓解 |
|---|---|---|
| 1 | Playwright 预检引入 Node 依赖，与"零运行时依赖"承诺冲突 | 定为可选增强层，缺失记 `SKIP`；脚本不随包安装，仅在目标仓库按需引入 |
| 2 | L2 盲审可能陷入修补拉锯（Issue #2112） | 硬上限 3 轮，超限挂起交人类 |
| 3 | 40 分制 / 20 分制阈值可能过严导致大面积不达标 | 先在 1–2 个真实变更上校准，再写入硬门槛 |
| 4 | `/opsx:review` 需新增四份命令体，增加维护面 | 复用同一正文，仅替换载体路径；纳入 `verify-carriers.sh` 覆盖 |
| 5 | `Review-Status` 依赖 Agent 自觉写入 | `onepress-gate.sh` 增加门禁 0.5 做确定性校验，不依赖自觉 |
| 6 | 沙箱与实现仍是两份代码，门禁 8 只能人工比对 | 沙箱只允许引用 `ui-spec.md` 第 2 节变量；L1 与 verify 门禁 2 共用同一套正则 |

**待决问题**：

1. L2 的 Critique/Audit 评分表是否直接内联到命令体，还是抽成 `references/review-rubric.md` 单一来源？
2. `/opsx:review` 是否应作为 superspec 的新增 artifact（会改变 DAG，影响纯后端流程），还是维持"命令级动作 + 文件标记"？
3. L1 的 8 视图组合是否覆盖足够，还是需要加 `reduced-motion` 与 200% 缩放的组合？
