**UI Change**: no

## Why

V3.0 已建立"契约先行 + 沙箱即生产 + 八项门禁"的骨架，但设计推理内核仍有 5 个源码级陷阱会在编码期造成样式失效或规则静默绕过（Token 命名断层、MASTER 双源寻址、GSAP 栈冲突、中文查询 0 命中、冗余未清理）；同时 `ui-spec.md` 到 `/opsx:apply` 之间只有肉眼验收，缺少编码前评审环节。编码后再验的成本远高于事前拦截，因此按 `blueprint/BLUEPRINT-V3.1.md` 落入 5 个补丁 + `/opsx:review` 三级门禁，把可量化缺陷左移到沙箱阶段。

## What Changes

**Token 契约无损化（BLUEPRINT §四.1）**
- From: `templates/ui-spec.md` 2.1 仅列 16 通道与 Shadcn 别名，无重命名规则与暗色策略文字
- To: 2.1 增加 `On *` → `*-foreground` 强制重命名规则、`.dark` 取值策略（Background `#0F172A` / Card `#111827` / Muted Foreground `#CBD5E1` / Border `#334155` / Ring ≥3:1 回退 `#60A5FA`）与 Tailwind v4 `@theme inline` 映射说明；章节口径统一为 7 节
- Reason: 照搬 `--color-on-primary` 会导致 `<Button>` / `<Badge>` 文字色丢失
- Impact: non-breaking（模板内容增强，字段不改名）

**设计检索 SOP 修正（BLUEPRINT §一.1.2 陷阱二/三/四）**
- From: 三份 carrier 与 OpenCode 侧使用中文占位查询词；MASTER Banner 仍指向 `design-system/pages/*.md`；动效未约束 GSAP
- To: `<query>` 强制 2–5 个英文信号词（`dashboard`/`data_heavy`/`checkout`/`booking`/`mobile`/`luxury`），0 命中缩窄重试一次；本次生成 MASTER 后立即重写 Banner 指向 `openspec/changes/[change-name]/ui-spec.md` 并禁建 `pages/*.md`（已存在则只告警）；动效只取 150–250ms 时长/缓动/交错，除非 `package.json` 已声明 `gsap`
- Reason: 英文词边界正则对中文 0 命中会让 192 条推理规则静默失效；Banner 会架空单一契约源
- Impact: non-breaking；伴生技能与测试夹具清理降级为"可选增强层启用后的手工 runbook"，不自动 `rm -rf`

**编码前三级评审门禁（BLUEPRINT §三）**
- From: `ui-spec.md` → `/opsx:apply` 之间无标准动作
- To: 新增 `/opsx:review <change-name>`（四 harness 各一份 `opsx-review.md`）：L1 Playwright + `@axe-core/playwright` 遍历 4 态 × 2 主题，校验 WCAG 2.2 A/AA 零 violations、热区 ≥44×44（项目标准，行内文本链接豁免）、375/768/1024/1280 零横向溢出、变量声明块外零 Hex、零 Emoji；L2 冷上下文盲审按 `review-rubric.md` 出 P0–P3 + 认知负荷阈值，主判据 `P0 = 0 且 P1 = 0`，40/20 分制先观察不阻断；L3 人类 DOM 点选批注（`#sandbox-control-bar` + `data-set-state/theme` + `data-review-id` + Pin-to-AI）
- Reason: 人类肉眼无法判定 4.6:1 与 3.9:1，同会话自审存在顺从偏见
- Impact: 新增能力；`UI Change: no` 的变更完全跳过

**契约锁定与确定性门禁（BLUEPRINT §三.3 / §五）**
- From: 无评审签署；`onepress-gate.sh` 仅门禁 0/2a/2b/4/5/6/7
- To: `ui-spec.md` 第 3 行固定 `> Review-Status: PENDING|APPROVED`（仅人类可签 `APPROVED`），评审结论落 `review.md`；`onepress-gate.sh` 新增门禁 0.5（`--require-review` 时未签署即 FAIL）；`schema.yaml` 的 apply 块注入前置校验；新增 `templates/review-rubric.md`（schema 11→12 文件）
- Reason: 依赖 Agent 自觉的契约锁定不可靠，需确定性解析
- Impact: **breaking**（对未签署的旧变更，`--require-review` 下会被拦）；不影响 `UI Change: no` 流程

**安装器与文档同步（BLUEPRINT §五/§六 P4）**
- From: `INSTALL_PROMPT.md` ② 写"命令文件不存在时跳过，不得新建"；schema 验收为 11 文件；`ASSETS.md` 无 review 资产
- To: 四份 `opsx-review.md` 纳入模板包与安装清单（OpenCode 直投；Qoder/Trae/Cursor 安装器直投并挂技能引用），`INSTALL_PROMPT.md` 改为"仅由安装器直投 onePress 托管命令"、验收改 12 文件；`ASSETS.md`、`install.sh`/`install.ps1` 清单与验收、`verify-carriers.sh`、README 双语同步；`VERSION` 1.0.7 → 1.1.0
- Reason: 已实测 `openspec init` 重跑不删除额外命令文件，直投可行；不同步会导致四 harness 等价验收漏检
- Impact: 升级新增 5 个 harness 级文件；回滚需删除新增命令与 rubric 并恢复旧版 skill

## Capabilities

### New Capabilities

- `onepress-design-review-gate`: 编码前三级评审门禁（L1 确定性预检 / L2 冷上下文盲审 / L3 人类 DOM 批注）、`review.md` 通行证、`Review-Status` 契约锁定、`review-rubric.md` 单一评分来源与门禁 0.5 的确定性校验。

### Modified Capabilities

- `onepress-frontend-contract`: "ui-spec.md 契约"（Token 重命名规则、`.dark` 策略、7 节口径）、"设计智能检索与降级"（英文信号词、0 命中重试、MASTER Banner 重写、清理降级为 runbook）、"高保真沙箱预览"（control bar / Pin-to-AI / `data-review-id`）、"八项 verify 门禁"与"门禁脚本与自动化分级"（编号 0–8 + 新增 0.5、`--require-review`）
- `onepress-harness-integration`: "多 harness 语义等价"（最小要点集合新增 review 命令与 rubric）、"Qoder 技能挂载法"/"Trae 命令初始化与挂载"/"Cursor 技能挂载法"（onePress 托管命令直投）、"superspec schema 强制注入"（apply 前置 `Review-Status`、12 文件）
- `onepress-template-pack`: "模板包固定目录结构"（新增四份 `opsx-review.md`、`templates/review-rubric.md`、`scripts/sandbox-preflight.spec.ts`）、"资产归属分层标注"、"模板内容逐字可复制"
- `onepress-llm-installer`: "安装提示词固定五段结构"（托管命令直投与 `--require-review` 验收）、"每个 harness 的可执行验收清单"（review 命令、rubric、12 文件）、"零运行时依赖执行"（Playwright/axe 缺失记 `SKIP` 不阻断安装）
- `onepress-idempotent-install`: "harness 核心资产全量覆盖"（新增命令文件的覆盖/清理范围）、"安装状态清单 onePress.lock"（`files` 记录新增托管命令）

## Impact

- **涉及 harness**：`.qoder/`、`.opencode/`、`.trae/`、`.cursor/` 四者全量；资产归属均为 **harness 级**（命令体、carrier skill、schema 模板、rubric）。
- **资产归属层级**：`scripts/onepress-gate.sh`、`scripts/verify-carriers.sh`、`install.sh`/`install.ps1`、`INSTALL_PROMPT.md`、`ASSETS.md`、README 属 installer / docs 层，不写入目标仓库；`docs/design-system/**` 与 `docs/ui-components.md` 属项目级，安装器不改写。
- **安装场景**：
  - 全新安装：新增 5 个 harness 级文件（4 命令 + 1 rubric），验收由 11 文件改 12 文件；
  - 升级（1.0.7 → 1.1.0）：按 lock 的 `files` 清理旧版托管文件后全量覆盖，新文件追加；`Review-Status` 只对 `UI Change: yes` 生效；
  - 回滚：删除四份 `opsx-review.md` 与 `review-rubric.md`，恢复旧 skill/schema 与 `VERSION`，lock 重建。
- **依赖**：L1 需 Node + Playwright + `@axe-core/playwright`，属**可选增强层**，缺失记 `SKIP`，不触发 `npm install`、不发起网络请求、不影响安装结论。
- **设计文档引用**：`blueprint/BLUEPRINT-V3.1.md` §零（变更清单）、§一.1.2（5 陷阱）、§三（三级门禁）、§四（补丁 1–4）、§五（资产映射）、§六（迁移顺序）、§七（风险）。
- **不受影响**：目标仓库业务代码、`openspec/changes/`、`docs/ui-components.md`；纯后端变更（`UI Change: no`）流程与门禁 1–8 行为不变。
