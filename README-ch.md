# onePress

> OpenSpec × Superpowers × Tailwind/shadcn 的桥接方案包——让**无设计师、程序员主导**的团队，用一段提示词把整套前端工程纪律装进任意仓库。

onePress 把 v3.0 极简前端工程方案打包为可分发、可幂等安装、可升级的 harness 模板包：BMAD UX 自动推导（`ui_contract` YAML 契约）、沙箱即生产（UI 底座直出 + 浮动 State Bar 验收）、秒级静态门禁（tsc + Token 正则 + 纯逻辑 Hook TDD）、组件注册表（`docs/ui-components.md`）全链路闭环。

**首批支持两个 AI 编码环境**：`.qoder/` 与 `.opencode/`。安装零运行时依赖，任意具备文件读写能力的大模型都能执行。

---

## 前置要求

- （推荐）已安装 OpenSpec CLI：`npm install -g @fission-ai/openspec@latest`（Node 22.12+），用于后续 `/opsx:*` 工作流
- 一个 AI 编码助手（Qoder / OpenCode / 任意 Agent），具备文件读写与执行命令能力

---

## 快速开始（30 秒安装）

把下面这段提示词**完整粘贴**给目标仓库里的 AI 助手即可：

```text
请为当前仓库安装 onePress 前端工程方案（OpenSpec × Superpowers × Tailwind/shadcn 桥接包）：

1. 用 git 稀疏检出获取模板包到本地临时目录：
   git clone --depth 1 --filter=blob:none --sparse https://github.com/rooho/onePress.git <临时目录>
   然后在 <临时目录> 中执行：git sparse-checkout set onePress

2. 阅读 <临时目录>/onePress/INSTALL_PROMPT.md 全文，并严格按其五段步骤执行安装：
   ① 前置检查 → ② 分层安装 → ③ 幂等与升级 → ④ 验收自检 → ⑤ 收尾
   （模板包内文件必须逐字写入目标路径，红线：禁止覆盖项目级资产与业务代码）

3. 安装完成后输出验收自检结果与 onePress.lock 内容。
```

安装完成后，仓库中会新增：

| 位置 | 内容 |
|------|------|
| `.opencode/` | `opencode.json` + `agent/ux-architect.md` + `commands/opsx-{new,apply,verify}.md` + `skills/superpowers-tdd/` |
| `.qoder/skills/onepress-discipline/` | 四条铁律 + TDD 纪律（Qoder 载体） |
| `openspec/schemas/superspec/` | superspec schema（schema.yaml + 9 模板，共 10 文件） |
| `onePress.lock` | 版本与受保护资产清单 |
| `docs/ui-components.md` | 组件注册表（首次安装初始化；已存在则跳过） |

> 手动方式：也可以先把本仓库 `onePress/` 目录下载到本地，再把其中的 `INSTALL_PROMPT.md` 全文交给 AI 执行，效果相同。

---

## 安装后的日常使用

```text
/opsx:new my-feature      # 契约初始化：proposal/design + design.md 底部 ui_contract YAML（BMAD UX 自动推导）
/opsx:apply               # 沙箱即生产两阶段：UI 底座直出（浮动 State Bar 10 秒验收）→ Schema 接线
/opsx:verify              # 秒级静态门禁：tsc + Token 正则 + Hook TDD + 四态点检
/opsx:archive             # 归档并增量追加组件到 docs/ui-components.md
```

核心契约示例（`design.md` 底部，由 AI 自动生成）：

```yaml
ui_contract:
  archetype: "Standard-CRUD-Table"   # 5 选 1：Dashboard-Grid | Master-Detail | Standard-CRUD-Table | Step-Wizard | Settings-Split
  schema_mapping:
    - field: "user.role"
      widget: "Select"
      rule: "required | default: member"
  states_matrix:
    query: { loading: "Skeleton 等高", empty: "EmptyState + 重置", error: "Alert + 重试" }
    mutation: { submitting: "disabled + Loader2", destructive_guard: "AlertDialog 二次确认" }
  layout_tokens:
    container: "max-w-7xl mx-auto p-6 space-y-6"
```

---

## 资产分层与升级策略

| 层级 | 资产 | 升级行为 |
|------|------|---------|
| Harness 级（onePress 维护） | `commands/`、`skills/`、门禁脚本、`openspec/schemas/superspec/` | 全量覆盖（先删旧再写入，无残留） |
| 项目级（目标仓库独有） | `docs/ui-components.md`、`openspec/changes/` | 存在即跳过（Protect Local），永不覆盖 |
| 本地修改 | 目标仓库中未被提交的 harness 文件改动 | 检测到即提示并跳过该项 |

升级 = 用新版本号重新执行"快速开始"提示词；`onePress.lock` 记录版本与受保护资产，缺失/损坏时按全新安装处理（项目级资产仍受保护）。

---

## 模板包结构

```text
onePress/
├── README-ch.md            # 中文说明（默认）
├── README.md               # English README
├── VERSION                 # 版本号（升级判定基准）
├── ASSETS.md               # 资产清单（归属层级 + 覆盖策略）
├── INSTALL_PROMPT.md       # 安装提示词（唯一安装入口，五段结构）
├── opencode/               # OpenCode harness 资产
│   ├── opencode.json
│   ├── agent/ux-architect.md
│   ├── commands/opsx-{new,apply,verify}.md
│   └── skills/superpowers-tdd/SKILL.md
├── qoder/                  # Qoder harness 资产
│   └── skills/onepress-discipline/SKILL.md
└── openspec-schema/        # superspec schema（注入 openspec/schemas/superspec/）
    └── superspec/（10 文件）
```

---

## 卸载 / 回滚

删除 `onePress.lock` 中 `protectedAssets` 之外的安装产物即可回退：

```text
删除 .opencode/（如为 onePress 所建）、.qoder/skills/onepress-discipline/、
openspec/schemas/superspec/、onePress.lock；
保留 docs/ui-components.md 与 openspec/changes/（项目级资产）。
```

---

## FAQ

**Q: 目标仓库没有 OpenSpec，能用吗？**
A: 可以安装，但 `/opsx:*` 工作流与 `ui_contract` 解析需要 OpenSpec。建议先 `openspec init` 再安装。

**Q: 已有 `.qoder/` 会被破坏吗？**
A: 不会。onePress 只新增 `skills/onepress-discipline/`，并在既有命令头部加一行技能引用，命令主体零改动。

**Q: 重复安装会怎么样？**
A: 幂等。harness 资产全量覆盖到与模板一致；项目级资产存在即跳过；`onePress.lock` 刷新版本。

---

## License

MIT
