# onePress 资产清单（ASSETS.md）

> 本清单是模板包（SSOT）的归属声明，安装时按此执行覆盖策略。

| 路径 | 归属层级 | 覆盖策略 |
|------|---------|---------|
| `install.ps1` / `install.sh` | installer | 不安装（在模板包侧执行，产出下表的安装件） |
| `INSTALL_PROMPT.md` | installer | 不安装（无脚本时的 AI 等价入口） |
| `VERSION` | harness | 全量覆盖（随版本升级） |
| `opencode/opencode.json` | harness | 全量覆盖 |
| `opencode/agent/ux-architect.md` | harness | 全量覆盖 |
| `opencode/commands/opsx-new.md` | harness | 全量覆盖 |
| `opencode/commands/opsx-apply.md` | harness | 全量覆盖 |
| `opencode/commands/opsx-verify.md` | harness | 全量覆盖 |
| `opencode/skills/superpowers-tdd/SKILL.md` | harness | 全量覆盖 |
| `qoder/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `trae/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `trae/commands/opsx-new.md` | harness | 全量覆盖 |
| `trae/commands/opsx-apply.md` | harness | 全量覆盖 |
| `trae/commands/opsx-verify.md` | harness | 全量覆盖 |
| `cursor/skills/onepress-discipline/SKILL.md` | harness | 全量覆盖 |
| `openspec-schema/superspec/**`（10 文件） | harness | 全量覆盖 |
| `README-ch.md` / `README.md` | docs | 不安装（仅仓库说明，不写入目标仓库） |
| `openspec/**`（自托管工作区） | self-host | 不安装（本方案自身的 config、CHANGE_NAMING、specs 与变更归档） |
| `docs/ui-components.md`（注册表模板） | project | 存在即跳过（Protect Local） |
| `openspec/changes/`（业务变更契约） | project | 永不触碰 |

**安装条件（按 harness 判定，见 INSTALL_PROMPT ①）**：

- `install.ps1`、`install.sh`、`INSTALL_PROMPT.md`、`ASSETS.md`、`README*.md` 属 installer / docs 层，一律不写入目标仓库；
- `opencode/**` 仅在 `HARNESS_SET` 含 `opencode` 时写入；`qoder/**` 仅在含 `qoder` 时写入；`trae/**` 仅在含 `trae` 时写入；`cursor/**` 仅在含 `cursor` 时写入；
- `openspec-schema/**`、`onePress.lock`、`docs/ui-components.md` 与 harness 无关，始终处理；
- 未选中的 harness：不创建目录、不写文件、不挂载引用；lock 中对应项记 `false`。
