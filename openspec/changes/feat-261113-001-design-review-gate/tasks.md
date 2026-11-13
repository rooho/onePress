## 1. UI 契约模板与 schema 注入

- [ ] 1.1 在 `openspec-schema/superspec/templates/ui-spec.md` 头注释与目录口径改为"七章节"，并在标题下第 3 行加入 `> Review-Status: PENDING`
- [ ] 1.2 更新 `ui-spec.md` 2.1 节：加入 `On *` → `*-foreground` 强制重命名规则、`.dark` 取值策略（#0F172A / #111827 / #CBD5E1 / #334155 / Ring ≥3:1）
- [ ] 1.3 在 `ui-spec.md` 2.1 节加入 Tailwind v4 `:root` + `.dark` + `@theme inline` 映射说明
- [ ] 1.4 在 `ui-spec.md` 第 5 节加入动效栈约束（150–250ms、缓动/交错、非 gsap 项目禁止引入）
- [ ] 1.5 在 `ui-spec.md` 第 7 节加入 `#sandbox-control-bar`、`data-set-state`、`data-set-theme`、`<main>` landmark、`data-review-id`、Pin-to-AI 要求
- [ ] 1.6 在 `openspec-schema/superspec/schema.yaml` 的 apply 块加入 `Review-Status: APPROVED` 前置校验
- [ ] 1.7 更新 `schema.yaml` 的 design UI CHANGE GATE 文案，引用七章节与 `Review-Status`
- [ ] 1.8 更新 `schema.yaml` 的 verify ONE PRESS GATES，使编号为 0–8 并注明 0.5 属编码前评审
- [ ] 1.9 将 1.1–1.8 同步到 `openspec/schemas/superspec/` 镜像目录，并以 `diff -r` 验证零差异（保留 `schema.yaml` 的 CRLF）

## 2. Carrier 纪律（Qoder / Trae / Cursor）

- [ ] 2.1 三份 `qoder|trae|cursor/skills/onepress-discipline/SKILL.md` 铁律 5 更新为七章节 + `Review-Status`
- [ ] 2.2 铁律 7 更新为英文 2–5 信号词查询、0 命中重试一次、`--json` 可选、MASTER Banner 重写与禁建 `pages/*.md`
- [ ] 2.3 铁律 7 将伴生技能/测试夹具清理写为"可选增强层启用后的手工 runbook"，明确禁止自动 `rm -rf`
- [ ] 2.4 铁律 8 加入沙箱控制栏契约、`data-review-id` 与 Pin-to-AI，并加入 GSAP 约束
- [ ] 2.5 铁律 9 更新为门禁 0–8 显式编号 + 门禁 0.5 + `/opsx:review` 入口
- [ ] 2.6 新增铁律 10：编码前三级评审（L1/L2/L3、`review.md`、证据强制、≤3 轮 ESCALATE、仅人类可签）
- [ ] 2.7 三份 skill 归一化（载体名/目录名替换后）逐字节一致

## 3. OpenCode 拆分载体

- [ ] 3.1 `opencode/agent/ux-architect.md` 更新检索 SOP：英文信号词、0 命中重试、MASTER Banner 重写、清理 runbook
- [ ] 3.2 `opencode/commands/opsx-new.md` Step 2 同步英文查询与 Banner 重写规则
- [ ] 3.3 `opencode/commands/opsx-apply.md` 加入动效栈约束与 `Review-Status` 前置校验
- [ ] 3.4 `opencode/` 合并集覆盖全部要点关键词（Token / 四态 / 无障碍 / 防呆 / ui_change / ui-spec.md / 双步 / sandbox-preview / 44×44 / 八项门禁 / Review-Status / review.md）

## 4. 评分表与四份 review 命令

- [ ] 4.1 新增 `openspec-schema/superspec/templates/review-rubric.md`：P0–P3 定义、Critique 10 项锚点、Audit 5 维锚点、认知负荷阈值、Slop 摘要、L1 断言清单与脚本附录
- [ ] 4.2 新增 `qoder/commands/opsx/review.md`（六段正文 + `onepress-discipline` 引用行 + Qoder frontmatter）
- [ ] 4.3 新增 `trae/commands/opsx-review.md`（同正文 + 引用行 + Trae frontmatter）
- [ ] 4.4 新增 `cursor/commands/opsx-review.md`（同正文 + 引用行 + Cursor frontmatter）
- [ ] 4.5 新增 `opencode/commands/opsx-review.md`（同正文 + `superpowers-tdd` 引用 + `description` frontmatter）
- [ ] 4.6 四份命令正文归一化后逐字节一致，且只引用 `review-rubric.md` 而不复制锚点表

## 5. L1 预检与 tooling 脚本

- [ ] 5.1 新增 `scripts/sandbox-preflight.spec.ts`：8 视图、axe WCAG 2.2 tags、44×44、四视口溢出、Hex/Emoji、CLS `PerformanceObserver`
- [ ] 5.2 `review-rubric.md` 附录内嵌同一脚本正文，并在文件头声明"唯一来源"
- [ ] 5.3 构造违规沙箱（32px 按钮 + 暗色低对比 + 375 溢出）验证 L1 非零退出并返回选择器
- [ ] 5.4 在无 Playwright 环境验证 L1 记 `SKIP` 且不中断评审

## 6. 门禁脚本 0.5 与自测

- [ ] 6.1 `scripts/onepress-gate.sh` 增加 `--require-review` 与 `--no-require-review` 参数解析
- [ ] 6.2 实现门禁 0.5：`^> Review-Status: (PENDING|APPROVED)$` 解析，非 APPROVED 即 FAIL；`UI Change: no` 记 SKIP；`--no-require-review` 记 `SKIP（legacy）`
- [ ] 6.3 调整门禁输出顺序为 0 → 0.5 → 2a → 2b → 4 → 5 → 6 → 7 → MANUAL，结论行仍按 FAIL 计数
- [ ] 6.4 `scripts/verify-gate.sh` 增加四组用例：PENDING 非零退出、APPROVED 通过、`UI Change: no` 跳过、legacy 跳过
- [ ] 6.5 运行 `bash scripts/verify-gate.sh` 全绿且无 Python/Node 依赖

## 7. 安装器（install.sh / install.ps1）

- [ ] 7.1 `install.sh` 增加 `QODER_COMMAND_FILES`、`TRAE_COMMAND_FILES`、`CURSOR_COMMAND_FILES`、`TOOLING_FILES` 清单，并在 `OPENCODE_FILES` 与 `SCHEMA_FILES` 追加 review 资产
- [ ] 7.2 `install.sh` 写入循环覆盖新清单；`build_will_write`、`remove_stale_files`、`write_lock` 均包含新文件
- [ ] 7.3 `install.sh` 的 `run_acceptance` 更新：schema 12 文件、rubric 逐字节一致、四份 review 命令存在且挂载、tooling 存在
- [ ] 7.4 `install.ps1` 做与 7.1–7.3 对等的清单、写入、lock 与验收修改
- [ ] 7.5 `bash install.sh --dry-run` 输出包含 4 命令 + rubric + 2 tooling，且不出现 1.0.7 的旧清单项
- [ ] 7.6 用临时目标仓库验证：全新安装 → 同版本重装（幂等）→ 模拟 1.0.7 lock 升级 → 回滚清单，四步均符合 design D11

## 8. 安装提示词与文档

- [ ] 8.1 `INSTALL_PROMPT.md` ② 增加四份 review 命令与两份 tooling 的表格行，并把"不得新建命令文件"改为"不得新建清单外命令文件"
- [ ] 8.2 `INSTALL_PROMPT.md` ② 红线允许写入清单加入 `scripts/onepress-gate.sh` 与 `scripts/sandbox-preflight.spec.ts`
- [ ] 8.3 `INSTALL_PROMPT.md` ③ 升级删除范围补充 `opsx-review` 命令与 `review-rubric.md`
- [ ] 8.4 `INSTALL_PROMPT.md` ④ 验收改为 schema 12 文件、rubric 逐字节、review 命令与挂载、tooling、L1 可选层 SKIP
- [ ] 8.5 `ASSETS.md` 增加 review/rubric/tooling 行，`onepress-gate.sh` 由 installer 改标 tooling，并保留自测脚本"不安装"
- [ ] 8.6 `README.md` / `README-ch.md` 同步命令数（12 原生 + 1 托管）、schema 12 文件、门禁 0–8 + 0.5 与 `/opsx:review` 用法
- [ ] 8.7 `VERSION` 从 1.0.7 改为 1.1.0

## 9. 跨 harness 回归

- [ ] 9.1 扩展 `scripts/verify-carriers.sh`：校验四份 review 命令存在、归一化一致、七关键词命中、rubric 存在
- [ ] 9.2 四 harness 安装矩阵：分别以 `qoder`、`opencode`、`trae`、`cursor` 安装到临时仓库，逐项记录写入与跳过
- [ ] 9.3 在 `qoder` 目标中确认 `.qoder/commands/opsx/review.md` 含引用行，且既有 `opsx/apply.md` 正文未变
- [ ] 9.4 在 `trae` 目标中确认 `openspec init` 生成的 12 命令保留，且 `opsx-review.md` 未被删除
- [ ] 9.5 运行 `openspec validate --all --strict` 通过
- [ ] 9.6 校验模板包根白名单无新增条目（`INSTALL_PROMPT.md` ④ 结构验收项）

## 10. 保护红线与收尾

- [ ] 10.1 在含 `docs/ui-components.md` 与 `docs/design-system/projectbaseline/MASTER.md` 的临时目标中安装，确认两文件逐字节不变
- [ ] 10.2 在含本地未提交修改的 harness 文件上安装，确认跳过并报告
- [ ] 10.3 校验 `onePress.lock` 的 `files` 含 4 命令 + rubric + 2 tooling，`harnesses` 四键与安装范围一致
- [ ] 10.4 更新本变更 `design.md` 的"Open Questions"为已裁决状态（如实现期出现偏差需回写）
- [ ] 10.5 汇总 verify 前检查：`review.md` 不适用于本变更（`UI Change: no`），确认未生成 `ui-spec.md` / `sandbox-preview.html`
