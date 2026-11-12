## Design Summary

`BLUEPRINT-V3.0.md` 把 v3.0 的基线整体抬高了：它诊断出现行体系的病灶不是"契约不完备"，而是"**工程契约完备、设计推理缺失**"——只有 Tailwind/Shadcn 的语法约束，没有行业审美基线、色彩情绪配比、排印层级、空间密度与微交互时序，于是模型退化为"AI 视觉廉价感"。

解法是把 `nextlevelbuilder/ui-ux-pro-max-skill` 作为**设计智能内核**嵌入现有闭环：`/opsx:new` 阶段检索本地 CSV 知识库，把结果写进 `ui-spec.md` 并生成高保真 `sandbox-preview.html`；`/opsx:apply` 遇到复杂交互时先查语义 UX、再查技术栈；`/opsx:verify` 从 4 项门禁扩到 8 项。

这与 onePress 现存实现有三处正面冲突，已裁决：

| 冲突点 | 旧基线（v3_0.md / 现有实现） | 新基线（BLUEPRINT-V3.0.md） | 裁决 |
|---|---|---|---|
| 契约载体 | `design.md` 底部 40 行 `ui_contract` | 独立 `ui-spec.md`（5+1 章节） | 改用 `ui-spec.md`，`ui_contract` 下线 |
| 沙箱 | 明确砍掉 HTML 沙箱，改 in-app State Bar | 恢复 `sandbox-preview.html`，加 Light/Dark | HTML 沙箱取代 State Bar |
| 外部依赖 | 承诺零运行时依赖 | 需要 Python3 + `ui-ux-pro-max` CSV 知识库 | 定为可选增强层，缺失即降级 |

## Alternatives Considered

### Alternative A: `ui-spec.md` 作权威载体（Agreed）

- **Approach**: 新增 `templates/ui-spec.md`（6 章节），`/opsx:new` 在 `ui_change: yes` 时生成；`ui_contract` 从 `design.md` 移除，契约信息由 `ui-spec.md` 唯一承载。
- **Pros**: 与 BLUEPRINT §四.1 逐条对齐；6 个章节能容纳 16 通道色彩、字体配对、密度表、防破版、微动效、反模式这类体量，YAML 单块装不下；沙箱与门禁都直接引用它。
- **Cons**: 破坏 v3_0.md §一.2 的"不做独立 ui-spec"减法原则；变更目录多一个文件。
- **Why not chosen**: —（本方案即被采纳）

### Alternative B: 把 5+1 章节压回 `design.md` 的 `ui_contract`

- **Approach**: 保留 40 行 YAML 契约，把新增强内容塞进 `schema_mapping` 与新增字段。
- **Pros**: 文件数不变，延续减法原则；解析方仍是 design.md。
- **Cons**: 16 个色彩通道 + 7 档间距 + 6 章节天然超过 40 行；YAML 里写"长 URL 安全折行""≥44×44 热区"这类规则会变成大段字符串，可读性与可校验性都差。
- **Why not chosen**: 与 BLUEPRINT §四.1 要求的章节结构不兼容，且必然突破行数上限。

### Alternative C: 双轨并存

- **Approach**: `ui-spec.md` 写全量，`design.md` 保留一份机器可读的 `ui_contract` 摘要。
- **Pros**: 下游解析可以只读 YAML；向后兼容。
- **Cons**: 同一信息两份载体，`/opsx:apply` 与 `/opsx:verify` 无法判断哪份为准，正是 BLUEPRINT §三.2 点名的"双源真相"风险。
- **Why not chosen**: 用一个可预期的漂移问题换取不存在的兼容性收益。

## Agreed Approach

采纳 Alternative A。核心判断：**契约的体量已经超过单个 YAML 块能承载的上限**——BLUEPRINT 要注入的是 16 通道色彩表、7 档间距表、字体配对、防破版规则、微动效时序、行业反模式，这些是"设计规范文档"而不是"渲染参数"。把它们塞回 40 行 YAML 只会得到一个不可读的键值堆。因此承认载体升级，同时用 `ui_change: yes|no` 保证纯后端变更零干扰。

## Key Decisions

1. **D1 契约载体**：`ui-spec.md` 为唯一权威，`design.md` 不再要求 `ui_contract`；`ui-spec.md` 作为 `design` artifact 的条件产物，不新增 DAG 节点（避免纯后端变更被强制）。
2. **D2 分流判定**：三条标准（路由/页面、表格列/表单字段/状态展示、破坏性交互）命中任一即 `ui_change: yes`，结果写入 `proposal.md` 首行，可审计。
3. **D3 依赖模型**：`ui-ux-pro-max` 为可选增强层。安装器探测 `python3` 与技能目录，缺失时检索步骤记 `SKIP`；门禁脚本把"检索产物缺失"记为 `SKIP` 而非 `FAIL`。零运行时依赖承诺保持不变。
4. **D4 沙箱取代 State Bar**：`sandbox-preview.html` 是唯一视觉验收载体，必须含四态按钮 + Light/Dark 切换 + 16 变量 + Google Fonts。不再注入 in-app State Bar，避免两套验收口径。
5. **D5 八门禁的自动化边界**：门禁 2/5/6/7 可实现为静态正则与对比度计算；门禁 1/3/8 为启发式 + 人工；门禁 4 明确限定为**纯逻辑状态机测试**，不含 RTL 渲染测试——BLUEPRINT 门禁 4 的 "RTL" 措辞与 v3_0.md §一.3 的减法原则冲突，此处取减法原则。
6. **D6 注册表四列**：对齐 BLUEPRINT 引用的原文表结构，旧表只 `WARN` 不改写。
7. **D7 本变更自身 `ui_change: no`**：只改 Markdown 与 shell，无路由/表单/交互，用于自举验证分流规则。

## Open Questions

1. BLUEPRINT §四.3 门禁 4 写"Vitest / RTL 组件状态机单元测试全绿"，与 v3_0.md §一.3 "不写脆弱的前端 DOM 渲染单测"直接冲突。本方案按 D5 取纯逻辑测试；若确认要恢复 RTL，需要同步修改门禁脚本与 skill 铁律。
2. `docs/design-system/<slug>/MASTER.md` 的 slug 由谁决定：固定 `projectbaseline` 还是由安装器按仓库名生成？当前按 BLUEPRINT §五 的示例固定为 `projectbaseline`。
3. `ui-ux-pro-max` 的 6 个伴生技能目录是否需要在安装器里显式清理，还是仅在文档中提示？当前按"安装器只检测、不删除"实现。
