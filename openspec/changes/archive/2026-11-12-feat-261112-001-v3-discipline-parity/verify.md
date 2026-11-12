# Verify Report

**Change**: `feat-261112-001-v3-discipline-parity`
**Verified at**: `2026-11-12 17:10`（Iteration 3）
**UI Change**: `no`（读自 `proposal.md` 首行）

---

## 门禁结论

| 门禁 | 结论 | 方式 | 证据 |
|------|------|------|------|
| 0 契约存在性 | PASS | AUTO | `proposal.md` 首行为 `**UI Change**: no`；变更目录无 `ui-spec.md`、无 `sandbox-preview.html` |
| 1 四态一致性与防抖 | SKIP | — | 无 UI 变更 |
| 2 Token 纯净度与对比度 | SKIP | — | 无 UI 变更 |
| 3 断点与防破版 | SKIP | — | 无 UI 变更 |
| 4 状态机单测 | SKIP | — | 无 UI 变更 |
| 5 A11y CRITICAL | SKIP | — | 无 UI 变更 |
| 6 热区与微交互 | SKIP | — | 无 UI 变更 |
| 7 反模式清零 | SKIP | — | 无 UI 变更 |
| 8 沙箱高保真对齐 | SKIP | — | 无 UI 变更 |

`SKIP` 原因统一为"本变更判定为纯工具链变更，不含前端 UI 行为"。

---

## 非 UI 校验

| 检查 | 结论 | 证据 |
|------|------|------|
| `openspec validate --strict` | PASS | `Change 'feat-261112-001-v3-discipline-parity' is valid` |
| 两处 schema 目录一致 | PASS | `diff -r openspec/schemas/superspec openspec-schema/superspec` 无输出 |
| 门禁脚本自测 | PASS | `gate tests: 18 passed, 0 failed`（A 违规 / B 合规 / C 空仓库 / D 低对比度 / E 注册表分区与幂等） |
| Trae 安装回归 | PASS | `Trae 安装验证：63 通过，0 失败`（桩对齐 12 命令） |
| Cursor 安装回归 | PASS | `Cursor 安装验证：25 通过，0 失败` |
| 安装端到端（qoder） | PASS | 退出码 0；`openspec/schemas/superspec` 共 11 文件；注册表四列；`ui-ux-pro-max：SKIP` |
| 旧表迁移保护 | PASS | 输出 `WARN` 并附目标表头，文件 md5 前后一致 |
| 三份 carrier 等价 | PASS | `diff --strip-trailing-cr` 除载体名与目录名外无差异 |
| 载体等价脚本 | PASS | `carrier checks: 21 passed, 0 failed`（等价 + 无 BOM/LF + 10 项关键词 + OpenCode 合并集） |
| 四 harness 端到端 | PASS | 各自 `openspec init` + `install.sh`：命令 12、schema 11、技能 14，均退出 0 |
| OpenCode 技能引用 | PASS | `opsx-apply.md` 头部含 `superpowers-tdd` MUST 加载行 |
| schema 内建八门禁 | PASS | `verify` artifact 含 ONE PRESS GATES 段，两处 schema 一致 |
| `validate --all` | PASS | `5 passed, 0 failed`，4 个主规格 Purpose 占位符警告已消除 |
| 安装报告提示 | PASS | trae,cursor 场景输出两条 `uipro init --ai <h> --offline` 提示 |
| 提示词安装路径 | PASS | `INSTALL_PROMPT.md` 新增探测小节 + 独立验收项，明确禁止安装/联网；schema 计数与白名单已对齐 |
| 注册表追加脚本 | PASS | 首次追加 / 幂等跳过 / base 与 domain 分区互不影响 |

---

## 缺陷与偏差

| 项 | 说明 | 处置 |
|----|------|------|
| BLUEPRINT §四.3 门禁 4 写 "Vitest / RTL" | 与 v3_0.md §一.3 "不写 DOM 单测" 冲突 | 按 D5 取纯逻辑状态机测试，`scripts/onepress-gate.sh` 检测到 RTL 直接判 `FAIL` |
| gate 2a 颜色规则为行级近似 | 多行 `<svg>` 块内的色值可能误报 | 已在脚本输出标注"行级近似"；`ui-spec.md` 第 2 节变量块本身不被扫描 |
| gate 6 热区判定为启发式 | 依赖 `size-11` / `min-h-11` / `cursor-pointer` 标记 | 已在 skill 铁律 9 中标注为 AUTO 启发式，MANUAL 仍需人工确认 |
| `ui-ux-pro-max` 未随包分发 | 开箱为 `SKIP`，需用户自行 `uipro init` | 已在 README 标注为可选加速器；`probe_uiux` 在报告里显式输出结论 |

---

## 结论

**PASS**（无 UI 变更：门禁 1–8 全部 SKIP；非 UI 校验项全绿，无 CRITICAL）

允许进入 `/opsx:archive`。
