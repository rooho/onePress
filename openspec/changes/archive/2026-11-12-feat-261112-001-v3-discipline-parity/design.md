## Context

现有 onePress 的四类资产只解决"工程确定性"：superspec 管 DAG 与工件格式、skills 管 Token/四态/无障碍/防呆、installer 管幂等分发。设计推理这一层完全空白——`ui_contract` 只有 `archetype`/`reuse_components`/`schema_mapping`/`states_matrix`/`layout_tokens`，没有任何行业调性、色彩明度关系、字体性格、密度刻度、动效时序的定义位置。

`BLUEPRINT-V3.0.md` 把这一层补上，但带来三个结构性冲突（契约载体 / 沙箱形态 / 外部依赖），且新文档内部还有一处自相矛盾（门禁 4 要 RTL，v3_0.md §一.3 禁 DOM 单测）。本变更在解决冲突的前提下落地 blueprint。

约束条件：

- 四个 harness 的资产必须继续语义等价（已归档需求）；
- `openspec init` 生成的命令主体不得改写（已归档需求）；
- 目标仓库的 `docs/ui-components.md` 与 `openspec/changes/` 不得覆盖（已归档需求）；
- `openspec validate --strict` 必须继续通过，包括纯后端变更；
- 安装器的"零运行时依赖"承诺不得被 `ui-ux-pro-max` 破坏。

## Goals / Non-Goals

**Goals:**

1. 用 `ui-spec.md`（6 章节）替代 `ui_contract`，成为唯一契约载体，并作为 `design` artifact 的条件产物；
2. `/opsx:new` 具备可审计的分流判定（`ui_change: yes|no`）；
3. 设计智能检索以"可选增强层"接入，缺失时全链路降级而不阻断；
4. 沙箱预览标准化为单文件 HTML，含四态与 Light/Dark 切换；
5. 八项门禁有明确的自动化边界与可执行脚本；
6. 注册表改为四列，旧表只警告；
7. 上述改动在四个 harness 上语义等价。

**Non-Goals:**

1. 不 vendor `ui-ux-pro-max` 的 CSV 知识库（体积与升级责任都不该由 onePress 背）；
2. 不实现行业反模式的自动识别（只能从 `ui-spec.md` 第 6 节读取禁用色/禁用模式再正则匹配）；
3. 不做视觉回归截图比对（门禁 8 是人工 + 沙箱对照）；
4. 不生成前端工程脚手架（Tailwind/Shadcn 初始化仍属目标仓库）；
5. 不恢复 RTL / DOM 快照测试（见 D5）；
6. 不改写 `openspec init` 生成的命令主体，只在 skill 与 pack 内命令体增补。

## Decisions

### D1：`ui-spec.md` 作为 `design` 的条件产物，不新增 DAG 节点

`templates/ui-spec.md` 随 superspec 一起注入（文件数 10 → 11）。`design` artifact 的 instruction 增加一段 UI CHANGE GATE：`ui_change: yes` 时必须额外产出 `ui-spec.md`；`no` 时禁止创建该文件。

- 替代方案：在 `schema.yaml` 新增 `ui-spec` artifact —— 被否决。superspec 的 DAG 是静态的，新增节点会让所有纯后端变更永久阻塞在"缺少 ui-spec.md"。
- 代价：`ui-spec.md` 的存在性无法由 `openspec` 自身校验，只能由门禁 0 与 skill 纪律保证。可接受，因为门禁 0 已经是显式检查项。

### D2：分流标准写成三条可穷举规则

① 新增/修改路由或页面；② 新增/修改表格列、表单字段、状态展示；③ 涉及删除/覆盖等破坏性操作的交互变更。命中任一即 `yes`。判定结果写入 `proposal.md` 的 `**UI Change**:` 行，供门禁 0 读取。

- 替代方案：让模型自由判断 —— 被否决。当前实现已经证明"无约束判断"会退化成一律产出契约。
- 代价：纯文案/纯样式微调可能被判为 `no`，漏掉检索。可接受，属于可人工覆盖的边界。

### D3：`ui-ux-pro-max` 为可选增强层，探测失败即 `SKIP`

安装器探测两个条件：`python3` 可执行、`.qoder/skills/ui-ux-pro-max/scripts/search.py`（或对应 harness 路径）存在。两者都满足才启用检索；否则在所有指令中输出 `SKIP: ui-ux-pro-max 不可用`，`ui-spec.md` 退化为"手工填写 6 章节"。

- 替代方案：安装时强制执行 `uipro init --ai <harness> --offline` —— 被否决。会引入 Node.js + Python3 双前置，破坏已归档的 `零运行时依赖执行` 需求，且 `uipro` 的 7 个伴生技能需要额外瘦身步骤。
- 代价：开箱体验从"自动检索"降为"模板填空"。README 需明确这一落差。

### D4：沙箱取代 State Bar，且沙箱只是视觉参照不是代码来源

`/opsx:new` 产出 `sandbox-preview.html`；`/opsx:apply` Stage 1 仍直接写生产级受控组件，**不从 HTML 翻译**。沙箱的作用是锁定 Token、字体、密度、动效参数，并作为门禁 8 的比对基准。

- 替代方案 A：保留 in-app State Bar 与沙箱并存 —— 被否决。两套验收口径会让"验收通过"失去唯一含义。
- 替代方案 B：从沙箱 HTML 转译成 React —— 被否决。正是 v3_0.md §一.2 要消除的"二次翻译损耗"。
- 代价：每个 UI 变更多一个 HTML 文件，且"零损耗转产"的强度下降（沙箱与实现是两份代码）。通过"沙箱只允许使用 `ui-spec.md` 第 2 节的 Token 变量"来抑制漂移。

### D5：门禁 4 限定为纯逻辑状态机测试，拒绝 RTL

BLUEPRINT §四.3 门禁 4 写"Vitest / RTL 组件状态机单元测试全绿"，但 v3_0.md §一.3 的第一条减法原则就是"不写脆弱的前端 DOM 渲染单测"。两者不能同时成立。本方案取减法原则：门禁 4 只覆盖脱离 DOM 的状态迁移函数、reducer、Zod 校验，**禁止**引入 RTL 查询断言与快照。

- 理由：RTL 的状态机断言本质上在测"渲染结构"，对样式与布局改动极其敏感，维护成本正是 v3_0.md 点名要砍掉的部分。
- 风险：BLUEPRINT 作者可能确实想要 RTL。已在 brainstorm 的 Open Questions 中标注，作为可翻转决策。

### D6：八门禁的自动化分级

| 门禁 | 内容 | 实现方式 |
|---|---|---|
| 1 | 四态一致性与防抖 | 启发式（组件文件含四态分支 + `ui-spec.md` 有四态矩阵）+ 人工 |
| 2 | Token 100% 与对比度 ≥4.5:1 | **自动**：三条正则 + `:root` / `.dark` 变量对比度计算 |
| 3 | 断点与极端文本防破版 | 启发式（表格容器 `overflow-x-auto`、长串 `break-words`/`min-w-0`）+ 人工 |
| 4 | 状态机单测 | **自动**：`vitest run`，缺失 `SKIP` |
| 5 | 无障碍 CRITICAL | **自动**：焦点环、`aria-label`、`aria-describedby`、`aria-hidden` 正则 |
| 6 | 热区与微交互 | **自动**：`duration-*` 是否落在 150–250ms、`cursor-pointer`、`motion-reduce:` |
| 7 | 反模式清零 | **自动**：Emoji 字符扫描 + `ui-spec.md` 第 6 节禁用项匹配 |
| 8 | 沙箱高保真对齐 | 人工 |

对比度计算用 `awk` 实现（sRGB → 相对亮度 → 对比度比值），不引入 Python 依赖。

- 替代方案：全自动 —— 被否决。门禁 1/3/8 涉及视觉与布局，静态分析无法给出可信结论，强行自动化会制造假阳性。
- 代价：`verify.md` 必须区分 `AUTO` 与 `MANUAL` 两类结论，人工项不得被默认记为通过。

### D7：注册表四列 + 旧表只警告

表头固定为 `组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名`，保留 base/domain 分区。安装器读取既有表头，不含"适用骨架"则输出 `WARN` 并打印目标表头，不写文件。

- 理由：Protect Local 是已归档需求的硬约束，模板一致性只能让位。

### D8：本变更 `ui_change: no`

本变更只改 Markdown、shell 与模板，无路由、无表单、无状态展示、无破坏性交互。按 D2 判定为 `no`，因此本变更不产出 `ui-spec.md` 与 `sandbox-preview.html`。这是对分流规则的自举验证。

## Risks / Trade-offs

- [契约载体切换导致存量变更失效] → 已归档变更的 `ui_contract` 留在 archive 中不改；新变更一律走 `ui-spec.md`；`docs/ui-components.md` 的检索键改为"适用骨架"。
- [三份 carrier skill 手工同步漂移] → `tasks.md` 固定"改一份 → 同步两份 → `diff --strip-trailing-cr`"三步，安装自检增加 `ui_change`、`ui-spec.md`、`sandbox-preview`、`44×44`、`prefers-reduced-motion` 五个关键词。
- [沙箱与实现漂移] → 沙箱只允许引用 `ui-spec.md` 第 2 节变量；门禁 2 对两者使用同一套正则。
- [对比度 awk 实现的边界] → 只校验 `Background/Foreground`、`Card/Card Foreground`、`Muted/Muted Foreground` 三对，其余通道只检查是否存在，避免过度拦截。
- [门禁 4 的 RTL 争议] → 决策记录在案，翻转时只需改 `scripts/onepress-gate.sh` 的门禁 4 与三份 skill 的一条铁律。
- [11 文件计数变更导致旧安装自检失败] → 安装器按 `SCHEMA_FILES` 列表逐个 `cmp`，计数检查改为"与 `SCHEMA_FILES` 长度一致"而非硬编码 10。

## Migration Plan

1. 先加 `templates/ui-spec.md` 与 schema 的 UI CHANGE GATE，再改命令体（保证载体先于指令存在）；
2. 三份 carrier skill 按 D1–D7 增补铁律 6–9，`diff` 校验后同步编码；
3. 新增 `scripts/onepress-gate.sh` 与 `scripts/verify-gate.sh`，先跑用例再接文档；
4. 安装器改造：`SCHEMA_FILES` 加 `templates/ui-spec.md`、计数逻辑参数化、注册表四列、旧表 `WARN`、`ui-ux-pro-max` 探测；
5. `INSTALL_PROMPT.md` 内联全部逐字模板并更新验收项；
6. 文档：`ASSETS.md` 新增三条、`README` 更新流程表与门禁表；
7. 回滚：`git revert` 单个 commit；已安装仓库重装即可回到 10 文件旧版。

## Open Questions

1. 门禁 4 是否恢复 RTL（D5 的反向选项）—— 需要产品侧确认。
2. `ui-ux-pro-max` 的 6 个伴生技能：安装器是否代跑清理？当前只检测不删除。
3. `MASTER.md` 的 slug：固定 `projectbaseline` 还是按仓库名生成？当前固定。
