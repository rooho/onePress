# onePress 资产清单（ASSETS.md）

> 本清单是模板包（SSOT）的归属声明，安装时按此执行覆盖策略。

| 路径 | 归属层级 | 覆盖策略 |
|------|---------|---------|
| `install.ps1` / `install.sh` | installer | 不安装（在模板包侧执行，产出下表的安装件） |
| `INSTALL_PROMPT.md` | installer | 不安装（无脚本时的 AI 等价入口） |
| `install-plan.tsv` | installer | 不安装（由 `manifest.json` 派生，安装器据此写 `onePress.lock.files` 与派生子集；`dev/scripts/gen-install-plan.sh` 生成） |
| `VERSION` | harness | 全量覆盖（随版本升级） |
| `opencode/opencode.json` | harness | 全量覆盖 |
| `opencode/agent/ux-architect.md` | harness | 全量覆盖 |
| `opencode/commands/openspec-review-change.md` | harness | 全量覆盖（编码前三级评审命令；`description` 以 `[internal]` 开头，用户入口为 `/op-review`） |
| `opencode/commands/openspec-finish-change.md` | harness | 全量覆盖（组合收尾：verify-report → verify → finalize；`description` 以 `[internal]` 开头，用户入口为 `/op-finish`） |
| `opencode/skills/superpowers-tdd/SKILL.md` | harness | 全量覆盖 |
| `qoder/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `qoder/commands/openspec-review-change.md` | harness | 全量覆盖（onePress 内部命令，安装器直投；用户入口为 `/op-review`） |
| `qoder/commands/openspec-finish-change.md` | harness | 全量覆盖（onePress 内部组合收尾命令；用户入口为 `/op-finish`） |
| `trae/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `trae/commands/openspec-review-change.md` | harness | 全量覆盖（onePress 内部命令；用户入口为 `/op-review`） |
| `trae/commands/openspec-finish-change.md` | harness | 全量覆盖（onePress 内部组合收尾命令；用户入口为 `/op-finish`） |
| `cursor/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `cursor/commands/openspec-review-change.md` | harness | 全量覆盖（onePress 内部命令；用户入口为 `/op-review`） |
| `cursor/commands/openspec-finish-change.md` | harness | 全量覆盖（onePress 内部组合收尾命令；用户入口为 `/op-finish`） |
| `qoder|trae|cursor|opencode/commands/op-<key>.md`（四端各 14 个） | harness | 全量覆盖（用户层扁平入口 `/op-<key>`，键集合固定为 propose / explore / new / continue / ff / update / apply / verify / finish / sync / archive / bulk-archive / onboard / review；每个文件只转发一个目标，同名文件四端逐字节一致；`commands/one.md` 与 `commands/o.md` 已退役，由清理阶段删除） |
| `openspec-schema/superspec/**`（16 文件，含 `templates/ui-spec.md`、`templates/review.md`、`templates/review-ledger.md`、`templates/review-rubric.md`、`templates/verification.md` 与 `templates/code-reviewer.md`） | harness | 全量覆盖 |
| `scripts/onepress-gate.sh` | tooling | 安装到目标仓库 `scripts/`（门禁 0.5 执行体；用户自建同名文件跳过） |
| `scripts/onepress-plan-lint.sh` | tooling | 安装到目标仓库 `scripts/`（`plan.md` + `design.md` + `tasks.md` 结构门禁；plan 生成后运行） |
| `scripts/onepress-evidence-lint.sh` | tooling | 安装到目标仓库 `scripts/`（`verification-evidence.md` 证据门禁；verify-report 阶段运行） |
| `scripts/onepress-review-lint.sh` | tooling | 安装到目标仓库 `scripts/`（`review.md` 回执与契约哈希门禁；apply 前运行） |
| `scripts/onepress-skills-prune.sh` | tooling | 安装到目标仓库 `scripts/`（安装前清理旧版 onePress 技能与退役路径；无标记技能只告警不删） |
| `scripts/onepress-skills-prune.ps1` | tooling | 安装到目标仓库 `scripts/`（Windows 对等实现；与 `.sh` 计同一逻辑项） |
| `scripts/sandbox-preflight.spec.ts` | tooling | 安装到目标仓库 `scripts/`（L1 可选层；缺 Playwright 记 SKIP） |
| `scripts/onepress-verify.sh` | tooling | 安装到目标仓库 `scripts/`（证据编排：Evidence Map 驱动、scope 分级、`--range`/`--churn`） |
| `scripts/onepress-telemetry.sh` | tooling | 安装到目标仓库 `scripts/`（本地 JSONL 遥测：信封 / 四级关闭 / `report` / `spool`） |
| `scripts/onepress-telemetry.ps1` | tooling | 安装到目标仓库 `scripts/`（Windows 对等实现：锁冲突 3×30 ms 退避后降级 spool；与 `.sh` 计同一逻辑项） |
| `scripts/onepress-registry-append.sh` | installer | 不安装（归档后补记注册表，供无 `/openspec-archive-change` 的环境使用；仍随发布包分发） |
| `README-ch.md` / `README.md` | docs | 不安装（仅仓库说明，不写入目标仓库） |
| `docs/ui-components.md`（注册表模板） | project | 存在即跳过（Protect Local） |
| `openspec/changes/`（业务变更契约） | project | 永不触碰 |

**安装条件（按 harness 判定，见 INSTALL_PROMPT ①）**：

- `install.ps1`、`install.sh`、`INSTALL_PROMPT.md`、`ASSETS.md`、`README*.md` 属 installer / docs 层，一律不写入目标仓库；
- `opencode/**` 仅在 `HARNESS_SET` 含 `opencode` 时写入；`qoder/**` 仅在含 `qoder` 时写入；`trae/**` 仅在含 `trae` 时写入；`cursor/**` 仅在含 `cursor` 时写入；
- `openspec-schema/**`（16 文件，含 `templates/ui-spec.md`、`templates/review.md`、`templates/review-ledger.md`、`templates/review-rubric.md`、`templates/verification.md` 与 `templates/code-reviewer.md`）、`onePress.lock`、`docs/ui-components.md` 与 harness 无关，始终处理；
- `scripts/onepress-gate.sh`、`scripts/onepress-plan-lint.sh`、`scripts/onepress-evidence-lint.sh`、`scripts/onepress-review-lint.sh`、`scripts/onepress-skills-prune.sh`、`scripts/onepress-verify.sh`、`scripts/onepress-telemetry.sh` 与 `scripts/sandbox-preflight.spec.ts` 属 tooling 层，始终安装到目标仓库 `scripts/`；其余 `scripts/*` 仅模板包自用；
- tooling 逻辑项共 **8** 项（`.ps1` 与同名 `.sh` 不重复计数，`onepress-registry-append.sh` 属辅助脚本不计入）；件数唯一真相源为 `manifest.json` 的 `counts.tooling`，`dev/scripts/verify-manifest.sh` 校验文档与本表是否漂移；
- `docs/design-system/projectbaseline/MASTER.md` 属项目级，存在即跳过（Protect Local）。
- `.agents/skills/openspec-*`（12 个）由 OpenSpec CLI 生成并归其所有；安装器仅在 `SKILL.md` 的 frontmatter 后插入一行 `onepress-discipline` 引用，不纳入 `onePress.lock` 的 `files`。
- 发布包 `VERSION` = `2.4.0`（`/op-*` 扁平入口、安装计划派生与可选增强层开关；要求 OpenSpec >= 2.0.0）；1.x 环境请使用 onePress v1.1.0。
- 遥测运行期数据落在 `~/.onepress/telemetry/`（`YYYY-MM.jsonl` 月度分片 + `spool/` 降级目录），属用户数据、**不进** `onePress.lock`，安装与升级均不清理；`prune --keep 12m` 按 12 个月保留。
- 未选中的 harness：不创建目录、不写文件、不挂载引用；lock 中对应项记 `false`。
