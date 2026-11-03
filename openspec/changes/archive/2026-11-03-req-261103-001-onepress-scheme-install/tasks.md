## 1. 模板包骨架与事实源（onepress-template-pack）

- [x] 1.1 创建 `onepress/` 顶层目录并写入 `VERSION` 文件（内容 `0.1.0`）
- [x] 1.2 创建 `onepress/openspec-schema/superspec/`，复制 `schema.yaml` 与 `templates/` 下 9 个模板文件（共 10 文件）
- [x] 1.3 编写 `onepress/` 资产清单初稿（逐项标注归属 `harness` 或 `project`）
- [x] 1.4 校验模板包顶层结构：仅含 `VERSION`、`INSTALL_PROMPT.md`、`qoder/`、`opencode/`、`openspec-schema/` 五条目

## 2. OpenCode harness 资产（onepress-harness-integration）

- [x] 2.1 编写 `onepress/opencode/opencode.json`（`$schema`、agent 声明、`permission.skill` 规则）
- [x] 2.2 编写 `onepress/opencode/agent/ux-architect.md`（BMAD UX 架构师人设，frontmatter 含 `mode`）
- [x] 2.3 编写 `onepress/opencode/commands/opsx-new.md`（契约初始化 + `ui_contract` YAML 要求，支持 `$ARGUMENTS`）
- [x] 2.4 编写 `onepress/opencode/commands/opsx-apply.md`（沙箱即生产两阶段执行：UI 底座直出 → Schema 接线）
- [x] 2.5 编写 `onepress/opencode/commands/opsx-verify.md`（秒级静态门禁：tsc + Token 正则 + Hook TDD + 10 秒四态点检）
- [x] 2.6 编写 `onepress/opencode/skills/superpowers-tdd/SKILL.md`（frontmatter `name` 与目录名一致，`description` 1–1024 字符）

## 3. Qoder harness 资产（onepress-harness-integration）

- [x] 3.1 编写 `onepress/qoder/skills/onepress-discipline/SKILL.md`（铁律封装：Token 纯净度、四态、3 条无障碍铁律、破坏性操作防护）
- [x] 3.2 在 `.qoder/commands/opsx/` 相关命令头部添加 `onepress-discipline` 技能引用（不改写命令主体内容）
- [x] 3.3 比对 `.qoder` 与 `.opencode` 纪律要点（门禁项、红线条目）确认语义等价

## 4. 安装提示词（onepress-llm-installer）

- [x] 4.1 创建 `onepress/INSTALL_PROMPT.md` 骨架，固定五段结构标题顺序
- [x] 4.2 填写第①段前置检查（探测 `.qoder/`、`.opencode/`、`onePress.lock` 现状）
- [x] 4.3 填写第②段分层安装（harness 级逐字落盘 / 项目级 Protect Local）
- [x] 4.4 填写第③段幂等与升级（读写 `onePress.lock`、三档策略、lock 损坏降级）
- [x] 4.5 填写第④段验收自检（`.qoder` 与 `.opencode` 各 ≥5 项可执行检查）
- [x] 4.6 填写第⑤段收尾（写 lock、输出安装报告）+ 逐字写入约束与三条红线声明

## 5. 幂等安装语义落地（onepress-idempotent-install）

- [x] 5.1 定义 `onePress.lock` JSON 结构（`version` / `installedAt` / `harnesses` / `protectedAssets`）并在 INSTALL_PROMPT.md 给出示例
- [x] 5.2 固化 harness 核心资产全量覆盖规则（升级时移除旧版本残留文件）
- [x] 5.3 固化 Protect Local 规则（`docs/ui-components.md`、`openspec/changes/` 存在即跳过）
- [x] 5.4 固化本地未提交修改检测与默认跳过提示

## 6. 安装演练与回归验证（跨 capability）

- [x] 6.1 全新仓库安装演练：按 `INSTALL_PROMPT.md` 执行并通过双 harness 全部验收项
- [x] 6.2 已有 `.qoder` 仓库升级演练：验证既有 opsx 命令主体未被改写、本地修改提示生效
- [x] 6.3 superspec schema 注入完整性检查（`schema.yaml` + 9 模板共 10 文件）且 `openspec validate` 通过
- [x] 6.4 `docs/ui-components.md` 两种场景验证：不存在时初始化、已存在时跳过
- [x] 6.5 `onePress.lock` 损坏降级演练：非法 JSON 时不覆盖项目级资产
