## 1. 契约载体与分流锚点

- [x] 1.1 新建 `openspec-schema/superspec/templates/ui-spec.md`：六章节骨架（组件拆解 / Token 映射 / 四态矩阵 / 响应式排版 / 微动效 / 反模式），第 2 节含 16 通道色彩表与 `xs`–`3xl` 间距表
- [x] 1.2 同步 `openspec/schemas/superspec/templates/ui-spec.md`，`diff` 确认两处逐字节一致
- [x] 1.3 `schema.yaml` 的 `design` artifact instruction 增加 UI CHANGE GATE：`ui_change: yes` 时额外产出 `ui-spec.md`，`no` 时禁止创建
- [x] 1.4 `schema.yaml` 的 `apply` artifact instruction 增加沙箱即生产两阶段与"沙箱只作视觉参照、不从 HTML 转译"
- [x] 1.5 在 `templates/design.md` 移除对 `ui_contract` 的任何引用，改为指向 `ui-spec.md`

## 2. 三份 carrier skill 增补铁律 6–9

- [x] 2.1 铁律 6：需求分流——三条判定标准 + `**UI Change**: yes|no` 输出位置
- [x] 2.2 铁律 5 重写：`ui-spec.md` 六章节契约——六章节、16 通道、字体配对、密度表、反模式黑名单
- [x] 2.3 铁律 7：设计检索与降级——先 `--domain ux` 后 `--stack shadcn|html-tailwind`，缺失时 `SKIP`
- [x] 2.4 铁律 8：高保真沙箱 + 沙箱即生产两阶段——四态 + Light/Dark + Token 变量，Stage 1 直出受控组件，Stage 2 零改动接线
- [x] 2.5 铁律 9：八项门禁——门禁 1–8 清单 + `AUTO`/`MANUAL` 分级 + 门禁 0 契约存在性
- [x] 2.6 `qoder/` → `trae/` → `cursor/` 同步，逐个 `diff --strip-trailing-cr` 确认仅载体名不同
- [x] 2.7 三份统一 UTF-8 无 BOM + LF，增量控制在 60 行内

## 3. OpenCode 命令体与 ux-architect

- [x] 3.1 `opencode/commands/opsx-new.md`：Step 0 需求类型判定 + Step 1 读 `MASTER.md` + 双步检索 + 生成 `ui-spec.md`
- [x] 3.2 `opencode/commands/opsx-new.md`：生成 `sandbox-preview.html`（四态 + Light/Dark + 16 变量 + Google Fonts）
- [x] 3.3 `opencode/commands/opsx-apply.md`：Stage 1 直出受控组件（不从 HTML 转译）+ Stage 2 零改动接线，删除 State Bar 注入要求
- [x] 3.4 `opencode/commands/opsx-verify.md`：扩为八项门禁 + 门禁 0 + `AUTO`/`MANUAL` 记录 + CRITICAL 阻断归档
- [x] 3.5 `opencode/agent/ux-architect.md`：改输出为 `ui-spec.md` 六章节，前置条件 `ui_change: yes`，内联双步检索命令
- [x] 3.6 `opencode/skills/superpowers-tdd/SKILL.md`：追加"归档向注册表追加一行（四列）"与"门禁 4 只测纯逻辑状态机"

## 4. 门禁脚本与用例

- [x] 4.1 新建 `scripts/onepress-gate.sh`：参数（`--root` / `--base` / `--files` / `--ui-spec`）、`PASS/FAIL/SKIP/MANUAL` 输出、退出码约定
- [x] 4.2 门禁 2a：三条 Token 正则（内联 style / 硬编码色值 / 任意像素间距），输出 `文件:行号`
- [x] 4.3 门禁 2b：`awk` 实现 WCAG 对比度，校验 Background/Foreground、Card/Card Foreground、Muted/Muted Foreground 三对
- [x] 4.4 门禁 4：`npx --no-install vitest run`，缺失记 `SKIP`
- [x] 4.5 门禁 5：焦点环保留、`aria-label`、`aria-describedby`、装饰图标 `aria-hidden`
- [x] 4.6 门禁 6：`cursor-pointer`、`duration-*` 落在 150–250ms、`motion-reduce:`、`min-h-11`/`size-11` 热区近似
- [x] 4.7 门禁 7：Emoji 字符扫描 + 读 `ui-spec.md` 第 6 节禁用项
- [x] 4.8 门禁 1/3/8 输出 `MANUAL`，不输出 `PASS`
- [x] 4.9 新建 `scripts/verify-gate.sh`：三条用例（违规→非零、合规→零、空仓库→零且 SKIP）

## 5. 安装器改造

- [x] 5.1 `install.sh`：`SCHEMA_FILES` 增加 `templates/ui-spec.md`，文件数检查改为由清单长度推导
- [x] 5.2 `install.ps1`：同步 5.1
- [x] 5.3 `install.sh` / `install.ps1`：注册表模板改四列 `组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名`
- [x] 5.4 `install.sh` / `install.ps1`：既有注册表表头不含"适用骨架"时输出迁移 `WARN`，不改写
- [x] 5.5 `install.sh` / `install.ps1`：探测 `python3` 与 `ui-ux-pro-max` 技能目录，结果写入报告（`enabled` / `SKIP`），不执行 `uipro init`
- [x] 5.6 `accept_skill_harness` 关键词集扩为 `ui_change`、`ui-spec.md`、`sandbox-preview`、`44×44`、`prefers-reduced-motion`

## 6. 安装提示词、清单与文档

- [x] 6.1 `INSTALL_PROMPT.md`：内联注册表四列逐字模板与 `ui-spec.md` 模板正文
- [x] 6.2 `INSTALL_PROMPT.md`：验收项增加 11 文件计数、`ui-spec.md` 哈希一致性、`ui-ux-pro-max` 探测结论
- [x] 6.3 `ASSETS.md`：新增 `templates/ui-spec.md`（harness）、`scripts/onepress-gate.sh` / `verify-gate.sh`（installer，不安装）
- [x] 6.4 `README.md` / `README-ch.md`：Step 1 改为 `ui-spec.md`、Step 2 改为沙箱、Step 4 改为八门禁，补 `ui-ux-pro-max` 可选说明
- [x] 6.5 `README.md` / `README-ch.md`：requirement 计数与命令矩阵说明同步

## 7. 终验

- [x] 7.1 `openspec validate feat-261112-001-v3-discipline-parity --strict` 通过
- [x] 7.2 `bash scripts/verify-gate.sh` 三条用例全绿
- [x] 7.3 `bash scripts/verify-trae.sh` 与 `bash scripts/verify-cursor.sh` 全绿
- [x] 7.4 `diff -r openspec/schemas/superspec openspec-schema/superspec` 无差异
- [x] 7.5 自举复核：本变更 `proposal.md` 含 `**UI Change**: no`，且变更目录无 `ui-spec.md` 与 `sandbox-preview.html`

## 8. 补完性修补（Iteration 3）

- [x] 8.1 `probe_uiux` / `Probe-UiUx` 在 SKIP 时输出可复制的 `uipro init --ai <harness> --offline` 提示，按实际 harness 范围逐条展开
- [x] 8.2 新增 `scripts/onepress-registry-append.sh`：按分区追加、幂等、不改动其它分区，供无 `/opsx:archive` 的环境使用
- [x] 8.3 补齐 4 个主规格的 `## Purpose`，`openspec validate --all` 不再产生占位符警告
- [x] 8.4 `verify-gate.sh` 增加用例 E（首次追加 / 幂等 / 分区正确），共 18 项断言
- [x] 8.6 `INSTALL_PROMPT.md` 补齐「可选增强层探测」小节与独立验收项，明确 MUST NOT 安装/联网，并修正 schema 计数 10→11 与模板包白名单（补 `scripts/`、`BLUEPRINT-V3.0.md`）
- [x] 8.5 新增 `scripts/verify-carriers.sh`：三份 carrier 归一化等价 + UTF-8/LF + 10 项要点关键词 + OpenCode 合并集覆盖，共 21 项断言
