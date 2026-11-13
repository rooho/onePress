## Design Summary

> 路径声明：`superpowers:brainstorming` 不在当前技能列表，本工件走 **SKILL FALLBACK（内联头脑风暴）**，输出重定向到本 change 的 `brainstorm.md`。
>
> 状态：**APPROVED — 6 项开放问题已于 2026-11-13 按推荐裁决（见文末）**。

### 目标

把 `blueprint/BLUEPRINT-V3.1.md` 的 5 个补丁 + 1 个新门禁（`/opsx:review` L1/L2/L3 + `Review-Status` 契约锁定）落到 onePress 模板包，且不破坏现有"多 harness 语义等价 + 幂等安装 + Protect Local"三条红线。

### 仓库现状（已核对，非转述）

| V3.1 要素 | 现状 | 差距 |
|---|---|---|
| 补丁 1：16 通道映射 | `openspec-schema/superspec/templates/ui-spec.md` 2.1 已是 16 通道 + Shadcn `--primary-foreground` 命名 + Light/Dark 双列 | 缺 `On *`→`*-foreground` 强制重命名规则文字、`.dark` 取值策略、Tailwind v4 `@theme inline` 说明 |
| 陷阱二：MASTER Banner | 三份 carrier 与 OpenCode 侧只要求"不存在则生成"，Banner 仍指向 `design-system/pages/*.md` | 缺生成后重写 + 禁建 `pages/*.md` |
| 陷阱三：GSAP | 全仓库 `gsap` grep 零命中 | 缺"仅取时长/缓动，除非 `package.json` 有 gsap"约束 |
| 陷阱四：英文查询 | 三份 carrier 铁律 7 仍是中文占位符；OpenCode 侧有 `--variance/--motion/--density` 但查询词同样中文 | 缺英文信号词 + 0 命中重试一次 |
| L1 预检 | `scripts/onepress-gate.sh` 仅门禁 0/2a/2b/4/5/6/7 + MANUAL 1/3/8 | 全缺（含 `--require-review`、门禁 0.5） |
| L3 批注器 | `ui-spec.md` 第 7 节只要求四态/主题按钮 | 缺 `#sandbox-control-bar`、`data-set-state/theme`、Pin-to-AI |
| `Review-Status` | 全仓库零命中；`ui-spec.md` 无元数据区 | 全缺 |
| `/opsx:review` 载体 | 四 harness 均无；`INSTALL_PROMPT.md` ② 写"不得新建命令文件" | 规则冲突，需同批修订 |

### 线上研究结论（2026-11 核对）

| # | 议题 | 证据 | 对 V3.1 的判定 |
|---|---|---|---|
| 1 | axe-core 自动化覆盖上限 | Deque 2021 研究：平均覆盖 **57%** 无障碍问题（<https://www.deque.com/blog/automated-testing-study-identifies-57-percent-of-digital-accessibility-issues/>；axe-core README 同口径） | **成立但需降级表述**：L1 只能当"必要条件"，不可替代 L2/L3/verify |
| 2 | 触控热区尺寸 | WCAG 2.2 **2.5.8（AA）= 24×24**，2.5.5（AAA）= 44×44（<https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html>） | **蓝图需改称**：44px 是"严于 AA 的项目标准"，不得写成 WCAG 2.2 AA 要求；行内文本链接豁免与 2.5.8 例外一致 |
| 3 | Shadcn Token 命名与双主题 | 官方：变量定义在 `:root` 与 `.dark`，再用 `@theme inline` 暴露给 Tailwind（<https://ui.shadcn.com/docs/theming>、<https://ui.shadcn.com/docs/tailwind-v4>） | **成立**；补丁 1 的 `@theme inline` 说明有官方依据 |
| 4 | 自审偏见 / 冷上下文盲审 | Huang et al. 2023：无外部反馈时 LLM 自我纠错能力有限甚至退化（<https://arxiv.org/abs/2310.01798>） | **方向成立**；但"独立子代理"≠"评审正确"，必须锚定评分标准与证据引用 |
| 5 | 评审循环上限 | Superpowers 的 reviewer 子代理不携带实现者会话；社区经验：reviewer 为 advisory，未收敛交人（<https://github.com/obra/superpowers/issues/229>） | **3 轮上限合理**（比 5 轮更克制），但必须"超限挂起交人"而非继续烧 Token |
| 6 | 0–4 分制来源 | NN/g 0–4 是**问题严重度**量表（0 = 非问题，4 = 灾难），不是质量得分（<https://www.nngroup.com/articles/how-to-rate-the-severity-of-usability-problems/>） | **蓝图表述不科学**：把 0–4 当"每项得分"再求和 40/20 属自定义量表，需显式锚点并改名 |
| 7 | AI Slop 规则库 | Impeccable 确有 24 命令 + 62 条本地规则 + critique/audit（<https://github.com/pbakaus/impeccable>） | **范式存在**，但 40/20 直接当硬门槛缺校准证据（蓝图风险 #3 自认） |
| 8 | DOM 点选批注 | Agentation：点选元素 → 结构化上下文交给 Agent（<https://github.com/benjitaylor/agentation>） | **方向成立**；选择器稳定性与 clipboard 权限需工程化处理 |
| 9 | 评审是否该做成 artifact | OpenSpec 官方 workflow 无审批闸，社区 issue 要求"review 节点"（<https://github.com/Fission-AI/OpenSpec/issues/773>、<https://openspec.dev/docs/schemas/spec-driven>） | **不宜改 DAG**：command + 文件标记与上游兼容，artifact 方案会被上游工作流演进甩开 |
| 10 | axe-core 是否支持 WCAG 2.2 tag | axe-core 覆盖 WCAG 2.0/2.1/2.2 A/AA/AAA；`@axe-core/playwright` 官方集成（<https://playwright.dev/docs/accessibility-testing>） | **成立**：`withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])` 可用 |

### 科学性判定（逐项）

| 机制 | 判定 | 理由 / 必要修正 |
|---|---|---|
| L1 确定性预检 | **成立** | 可复现、零 LLM 判断；但覆盖上限 ~57%，只能作必要条件 |
| 44×44 热区 | **成立，需改称呼** | 项目标准严于 WCAG 2.2 AA（24px）；防破版与触屏可用性收益明确 |
| CLS < 0.1 | **成立，需标注 proxy** | 0.1 是 Core Web Vitals "good" 阈值；沙箱无真实字体/图片加载，只能作代理指标 |
| Critique 40 / Audit 20 硬门槛 | **证据不足** | 属项目自定义量表；应先"观察模式"校准 1–2 个真实变更，再转阻断 |
| L2 冷上下文盲审 | **成立，需防偏置** | 有自纠错文献支撑；LLM-as-judge 存在宽松/位置偏置 → 每条结论必须引用 `ui-spec.md` 章节或选择器，否则不计分 |
| L3 DOM 批注 | **成立** | Agentation 验证过；需 `data-review-id` 稳定锚点 + clipboard 回退 |
| `Review-Status` 文件标记 | **成立** | 确定性解析优于"Agent 自觉"，与蓝图风险 #5 一致 |

### 本变更落地范围（建议）

| 阶段 | 内容 | 关键落点 |
|---|---|---|
| P0 | 补丁 1 + 陷阱三/四文本纪律 | `openspec-schema/superspec/templates/ui-spec.md` 2.1/5、三份 carrier 铁律 7/8、`opencode/agent/ux-architect.md`、`opencode/commands/opsx-new.md` |
| P1 | 补丁 2（清理 + Banner 重写） | 三份 carrier + `ux-architect.md` 的 SOP 段（清理降级为"可选层手工 runbook"） |
| P2 | L1 预检 + `--require-review` | 新增 `scripts/sandbox-preflight.spec.ts`（不随包装）、`onepress-gate.sh` 门禁 0.5 |
| P3 | L2/L3 + `Review-Status` | 四份 `opsx-review.md` + `templates/review-rubric.md`（11→12 文件）+ `schema.yaml` apply 前置校验 + `ui-spec.md` 第 7 节 |
| P4 | 安装器与文档 | `install.sh` / `install.ps1` 文件清单与验收、`INSTALL_PROMPT.md`、`ASSETS.md`、README 双语、`verify-carriers.sh`、`VERSION` 1.0.7 → 1.1.0 |

## Alternatives Considered

### Alternative A: 命令级三级门禁 + `Review-Status` + 确定性门禁 0.5

- **Approach**：新增四份 `opsx-review.md`（OpenCode 直投、Qoder/Trae/Cursor 由安装器直投并在 frontmatter 后挂技能引用）；`ui-spec.md` 增加固定 `Review-Status` 行；`onepress-gate.sh` 增加门禁 0.5 做确定性解析；`schema.yaml` 的 apply 块注入前置校验。
- **Pros**：
  - 不改 DAG，纯后端变更零干扰（`UI Change: no` 直接跳过）；
  - 与 OpenSpec 上游"无审批闸"的演进方向兼容，升级 init 不清除额外命令文件（已实测）；
  - 门禁可确定性执行，不依赖 Agent 自觉。
- **Cons**：
  - 模板包新增四份命令体，维护面 +4；
  - 需要同步改安装清单、lock 文件列表、四 harness 验收与 INSTALL_PROMPT 措辞。
- **Why not chosen**：—（本方案被选中）

### Alternative B: 把 review 做成 superspec 的新 artifact

- **Approach**：在 `specs/tasks` 与 `apply` 之间插入 `review` artifact，产出 `review.md`，`apply` 依赖 `review`。
- **Pros**：状态机内建，`openspec status` 天然可见；无法被跳过。
- **Cons**：改动 DAG，所有变更（含纯后端）都被迫产出评审件；与上游 schema 演进不兼容；`/opsx:apply` 的门槛变成"工件存在"而非"人已批准"。
- **Why not chosen**：违背 V3.0 已确立的"需求分流、纯后端零干扰"原则，且蓝图待决 2 的担忧成立。

### Alternative C: 纯技能载体（不新增命令文件）

- **Approach**：在四 harness 的 carrier skill 中新增铁律 10（三级门禁），由 `/opsx:apply` 前置自检触发，不新增 `opsx-review.md`。
- **Pros**：零安装清单改动；不受 `openspec init` 影响。
- **Cons**：无显式入口，用户难以主动触发；技能是提示级约束，无法承载 L1 脚本调用与评分表；四 harness 的触发语义不一致。
- **Why not chosen**：与"门禁必须可执行、可发现"的目标冲突；技能只保留摘要，命令体承载完整流程。

## Agreed Approach

采用 **Alternative A**，并把研究结论收敛为以下设计：

1. **L1（确定性）**：Playwright + `@axe-core/playwright` 遍历 4 态 × 2 主题 = 8 视图，断言四类：WCAG 2.2 A/AA 零 violations（排除 `#sandbox-control-bar`）、交互控件 ≥44×44（行内文本链接豁免）、375/768/1024/1280 零横向溢出、变量声明块外零硬编码 Hex + 零 Emoji；CLS 用 `PerformanceObserver` 在状态切换时采样，阈值 0.1，标注为沙箱代理指标。缺失 Playwright/axe 时记 `SKIP` 并在通行证写明，不阻断安装、不影响基础门禁。
2. **L2（冷上下文）**：新上下文子代理只读四件套；**主判据为 P0 = 0 且 P1 = 0 + 硬性认知负荷阈值（单层列表 ≤8、单决策点 ≤4）**，40/20 分制为二级信号（默认记录、可配置阈值）；每条 findings 必须引用 `ui-spec.md` 章节或选择器；自动修复 ≤3 轮，超限挂起交 L3。无 subagent 能力的 harness 走 FALLBACK：新会话 + 只读四件套 + 禁止引用生成历史。
3. **L3（人类）**：沙箱注入 `#sandbox-control-bar` + `data-set-state` / `data-set-theme` + Pin-to-AI（`Alt/⌘+Click`）；关键元素加 `data-review-id` 稳定锚点；clipboard 不可用时回退 `document.execCommand('copy')`；SVG 目标做 `className` 类型守卫。
4. **契约锁定**：`ui-spec.md` 标题下第 3 行固定 `> Review-Status: PENDING|APPROVED`，仅 L3 人类批准可置 `APPROVED`；`/opsx:apply` 前置校验 + 门禁 0.5 双保险。
5. **单一评分来源**：新增 `openspec-schema/superspec/templates/review-rubric.md`（随 schema 恒装，11→12 文件），命令体与技能只引用不复制。
6. **MASTER 基线**：仅"本次生成"时重写 Banner 指向 `openspec/changes/[change-name]/ui-spec.md` 并显式禁建 `pages/*.md`；已存在则只告警不改写（Protect Local）。
7. **查询与动效**：`search.py` 的 `<query>` 强制 2–5 个英文信号词（`dashboard` / `data_heavy` / `checkout` / `booking` / `mobile` / `luxury`），0 命中缩窄重试一次；动效只取 150–250ms 时长、缓动与交错，除非 `package.json` 已声明 `gsap`。
8. **安装器同步**：新增命令文件进 `ASSETS.md`、`install.sh` / `install.ps1` 文件清单与验收、lock `files`、`INSTALL_PROMPT.md` ②（"不得新建命令文件"改为"仅由安装器直投 onePress 托管命令"）、`verify-carriers.sh`、README 双语；`VERSION` 建议 1.1.0。

## Key Decisions

| # | 决策 | 依据 |
|---|---|---|
| D1 | 门禁形态 = 命令 + `Review-Status` + 脚本门禁 0.5，不改 DAG | 上游无审批闸（OpenSpec 文档）；社区 issue #773 仅提案；纯后端零干扰 |
| D2 | 44×44 定位为"项目标准（严于 WCAG 2.2 AA 的 24px）" | W3C 2.5.8 / 2.5.5 原文；避免把项目标准误标为 WCAG 要求 |
| D3 | L1 只作必要条件，不替代 L2/L3/verify | Deque 57% 覆盖率上限 |
| D4 | L2 主判据用 P0/P1 计数 + 认知负荷硬阈值，分数为二级信号 | NN/g 0–4 是严重度而非质量分；分数阈值缺校准证据 |
| D5 | 每条 L2 finding 必须引用章节/选择器，否则不计分 | 抑制 LLM-as-judge 的宽松与位置偏置 |
| D6 | L2 自动修复 ≤3 轮，超限挂起交人 | Superpowers advisory 经验；防 Issue #2112 式拉锯 |
| D7 | L2 必须有 FALLBACK（新会话只读四件套） | Trae/Cursor 无 subagent 等价物；与 schema 既有 FALLBACK 风格一致 |
| D8 | L3 用 `data-review-id` 稳定锚点 + clipboard 回退 | Agentation 模式验证；class 选择器在改写后易失配 |
| D9 | 评分表单一来源 = `templates/review-rubric.md`（第 12 个 schema 文件） | 四份命令体去重；可选层 `ui-ux-pro-max` 缺失时仍可用 |
| D10 | `Review-Status` 仅人类可签 `APPROVED`，Agent 只能写 `PENDING` | 防自审自批；门禁 0.5 确定性校验 |
| D11 | MASTER Banner 只在"本次生成"重写，已存在只告警 | Protect Local 红线；`docs/design-system/**` 非安装器管辖 |
| D12 | 0 命中重试一次 + `--json` 可选，不强制 | `--json` 利于脚本解析，但 ASCII 表格对 LLM 更稳；两者并存 |
| D13 | 伴生技能与测试夹具清理降级为"可选增强层启用后的手工 runbook" | onePress 安装器不安装 `ui-ux-pro-max`；自动 `rm -rf` 违反防呆铁律 |
| D14 | 本变更同时修章节口径（7 节）与门禁编号（0–8 显式编号，新增 0.5） | 现状"六章节"与 9 行门禁表已自相矛盾 |

## Open Questions

无遗留。6 项已于 2026-11-13 按推荐裁决：

1. **40/20 阈值** → **观察模式**：首个真实变更记录不阻断，校准 1–2 个变更后再转硬门槛。
2. **`Review-Status` 强制范围** → **默认强制**（仅 `UI Change: yes`）；`--require-review` 保留为 CI 显式开关。
3. **评审通行证载体** → **`review.md`**（change 目录内独立文件），不写进 `ui-spec.md`。
4. **`review-rubric.md`** → **接受 11→12 文件**，同步修订 `INSTALL_PROMPT.md` ④ 与 `ASSETS.md`。
5. **44px** → **保留**，标注为"严于 WCAG 2.2 AA（24px）的项目标准"。
6. **L1 视图矩阵** → **8 视图为基线**，`--full` 追加 `reduced-motion` 与 200% 缩放。
