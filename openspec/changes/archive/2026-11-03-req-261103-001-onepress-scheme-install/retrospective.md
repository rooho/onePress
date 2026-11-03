# Retrospective（req-261103-001-onepress-scheme-install）

> finalize 前的非阻塞回溯，证据优先、观点其次。

## Wins

- 模板包 `onepress/` 成为唯一事实源（22 文件：5 功能条目 + 3 文档条目 + harness 资产），四级校验可复现：`openspec validate --all` 1 passed / 包内 `{{` = 0 / 包根白名单 8 项 / 双 harness 纪律 13/13 语义等价。
- 幂等语义经 e2e 实测落地：全新安装计数、升级残留清除、Protect Local 本地行存活、lock 损坏降级四类场景全部通过（`e2e-report.md`）。
- `/opsx:verify` 一轮内发现并修掉 1 CRITICAL + 4 WARNING + 2 SUGGESTION，未进入第二轮迭代。
- GitHub 分发链路打通：稀疏检出 → 只拉 `onepress/` → 执行 INSTALL_PROMPT 五段，README 中可直接复制的提示词即完成安装。

## Misses

- **Qoder 命令头部技能引用**在 apply 阶段只做了 dogfood（手工给本仓库 `.qoder/commands/opsx/{apply,verify}.md` 加行），却漏进 INSTALL_PROMPT 安装步骤——分发出去等于技能不生效，属典型的"实现存在但装不出来"。
- 规范与实现漂移未在 apply 收尾自查：`VERSION` 升到 1.0.0 后，lock 示例与 `tasks.md` 任务 1.1 仍写 0.1.0。
- 项目名大小写来回摆动一次（`onePress` → `onepress` → `onePress`），期间产生 8 个文件的无效改动与两份 README 副本。

## Plan deviations

- 计划中的 6 组 31 微步骤按"直接工作区落盘"执行（用户偏好），未使用隔离 worktree；后续为发布另建了 `.worktree/v1.0.0`，与计划假设不同。
- `superpowers:writing-plans` / `finishing-a-development-branch` 技能在本环境不可用，按 schema 兜底改为手工循环，finalize 亦走 escape hatch。
- 外层 `onepress/`（0.1.0）与 worktree（1.0.0）曾并存为两份分叉实现，最终删除外层，保留 worktree 为唯一源。

## Skill / workflow compliance

- 九工件序列完整：brainstorm → proposal → design → specs → tasks → plan → apply → verify → finalize。
- tasks 28/28 勾选，验证命令均为可复现的实跑结果，无"声称通过"。
- 全程未做 git 提交与推送（用户要求确认后再提交），故 finalize 的 canonical closeout 不适用。

## Surprises

- OpenSpec `validateChangeName` 强制全小写，导致"展示层大写 FEAT / 工具层小写 feat"的双层命名成为唯一可行解。
- PowerShell `-ne` 大小写不敏感，使 `onePress → onepress` 批量替换静默跳过（无报错、无输出），只能用 `-cne` / `-creplace`。
- 包内"禁止内联样式"的代码示例字面写了 `style={{`，恰好触发规范里"无 `{{` 占位符"的扫描红线——规范与示例互相踩脚。

## Promote candidates

- 把"安装步骤必须与 dogfood 改动一一对应"写进 apply 的自查项：凡本仓库手工做过的一次性配置，都必须能在 INSTALL_PROMPT 中找到对应步骤。
- 模板包自检做成可执行清单（包根白名单、`{{` 扫描、schema 10 文件、双 harness 要点数），在 verify 前一次跑完。
- `openspec/CHANGE_NAMING.md` 冻结后，把命名正则纳入 `/opsx:new` 生成步骤，避免继续产生 `req-` 旧前缀变更。
