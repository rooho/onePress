# onePress 安装演练与回归验证报告（e2e-report.md）

**演练时间**: 2026-11-03
**演练目录**: `%TEMP%\onepress-e2e-new`（已清理）

## 演练结果总览

| 场景 | 结果 |
|------|------|
| 6.1 全新仓库安装 | ✅ 通过（opencode 6 文件 + qoder 1 文件 + schema 10 文件，双 harness 验收项全过） |
| 6.2 升级演练 | ✅ 通过（旧版本残留文件 old-deprecated.md / legacy.txt 全量覆盖后清除） |
| 6.2 主仓库命令主体保护 | ✅ 通过（.qoder/commands/opsx/ 仅头部新增一行技能引用，主体零改动；该目录未被 git 跟踪，无 diff 可对比，以编辑 diff 为准） |
| 6.3 superspec schema 注入 | ✅ 通过（演练仓库 10 文件齐全；主仓库 `openspec validate` 通过） |
| 6.4 注册表两态 | ✅ 通过（全新仓库初始化注册表模板；已存在时 Protect Local：本地追加的 `LocalBizCard` 行在升级后存活） |
| 6.5 lock 损坏降级 | ✅ 通过（写入非法 JSON 后按全新安装处理，项目级资产未被覆盖） |

## 关键验证细节

1. **全量覆盖残留清除**：升级时先删除受管目录再重写，旧版独有文件（`old-deprecated.md`、`legacy.txt`）不复存在。
2. **Protect Local**：升级重跑后 `docs/ui-components.md` 中用户本地追加行原样保留。
3. **lock 损坏降级**：`not-json{{` 无法解析 → 安装器按全新安装处理，`docs/ui-components.md` 未被触碰。
4. **语义等价**：`.qoder` 与 `.opencode` 纪律技能 13/13 要点一致（铁律 1–4 + TDD 纪律）。
5. **静态资产校验**：INSTALL_PROMPT.md 五段标题有序、无 `{{ }}` 渲染占位符、lock JSON 示例可解析。

## 已知说明

- 本演练由脚本模拟"大模型按 INSTALL_PROMPT.md 执行安装"的文件操作序列，等价于提示词驱动安装的落盘行为。
- 主仓库 `.qoder/` 因 `.gitignore` 规则（`.*`）未被 git 跟踪，本地修改检测依赖目标仓库已纳入 git 的前提（INSTALL_PROMPT.md 第①段已声明）。
