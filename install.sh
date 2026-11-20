#!/usr/bin/env bash
# onePress installer for macOS / Linux (bash 3.2+).
#
# Installs the onePress pack (OpenSpec x Superpowers x Tailwind/shadcn) into a target repo.
# All checks run inside this script; any failure aborts with a reason.
#
# Run from the target repo root:
#   ./install.sh                     # source = this script's directory (pack already cloned)
#   ./install.sh --harness qoder     # install Qoder only (default: auto-detect)
#   ./install.sh --harness trae,cursor  # install Trae + Cursor only
#   ./install.sh --target ~/repo     # explicit target repo
#   ./install.sh --dry-run           # print the plan, write nothing
#
# When the source is not a local pack (e.g. script downloaded on its own):
#   ./install.sh --source "" --repo https://github.com/rooho/onePress.git --ref main
set -eo pipefail

HARNESS="auto"
SOURCE=""
TARGET=""
REPO="https://github.com/rooho/onePress.git"
REF="main"
DRY_RUN=0
ASSUME_YES=0
NO_INIT=0
TEMP_ROOT=""

SKILL_REF='> onepress: 执行本技能时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。'

SCHEMA_FILES="schema.yaml templates/apply.md templates/brainstorm.md templates/code-reviewer.md templates/design.md templates/finalize.md templates/plan.md templates/proposal.md templates/review-ledger.md templates/review-rubric.md templates/review.md templates/spec.md templates/tasks.md templates/ui-spec.md templates/verification.md templates/verify.md"

OPENCODE_FILES="opencode/opencode.json opencode/agent/ux-architect.md opencode/commands/openspec-review-change.md opencode/commands/one.md opencode/skills/superpowers-tdd/SKILL.md"

SKILL_SLUGS="apply-change archive-change bulk-archive-change continue-change explore ff-change new-change onboard propose sync-specs update-change verify-change"

QODER_FILES="qoder/skills/onepress-discipline/SKILL.md"

TRAE_FILES="trae/skills/onepress-discipline/SKILL.md"

CURSOR_FILES="cursor/skills/onepress-discipline/SKILL.md"

QODER_COMMAND_FILES="qoder/commands/openspec-review-change.md qoder/commands/one.md"

TRAE_COMMAND_FILES="trae/commands/openspec-review-change.md trae/commands/one.md"

CURSOR_COMMAND_FILES="cursor/commands/openspec-review-change.md cursor/commands/one.md"

TOOLING_FILES="scripts/onepress-evidence-lint.sh scripts/onepress-gate.sh scripts/onepress-plan-lint.sh scripts/onepress-review-lint.sh scripts/onepress-verify.sh scripts/sandbox-preflight.spec.ts"

WRITTEN=""
LOCK_FILES=""
SKIPPED=""
FAILURES=""
PROTECTED=""
MOUNT_SKIPPED=""

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------- output

step() { printf '\n== %s\n' "$1"; }
info() { printf '   %s\n' "$1"; }
ok()   { printf '   [OK]   %s\n' "$1"; WRITTEN="$WRITTEN$1"$'\n'; }
skip() { printf '   [SKIP] %s\n' "$1"; SKIPPED="$SKIPPED$1"$'\n'; }
warn() { printf '   [WARN] %s\n' "$1"; }
bad()  { printf '   [FAIL] %s\n' "$1"; FAILURES="$FAILURES$1"$'\n'; }

cleanup() {
  if [ -n "$TEMP_ROOT" ] && [ -d "$TEMP_ROOT" ]; then
    rm -rf "$TEMP_ROOT"
  fi
}

die() {
  printf '\n安装中止：%s\n' "$1" >&2
  cleanup
  exit 1
}

# ---------------------------------------------------------------- helpers

test_pack_root() {
  local path="$1"
  [ -n "$path" ] || return 1
  [ -f "$path/VERSION" ] || return 1
  [ -f "$path/opencode/opencode.json" ] || return 1
  [ -f "$path/qoder/skills/onepress-discipline/SKILL.md" ] || return 1
  [ -f "$path/trae/skills/onepress-discipline/SKILL.md" ] || return 1
  [ -f "$path/cursor/skills/onepress-discipline/SKILL.md" ] || return 1
  [ -f "$path/openspec-schema/superspec/schema.yaml" ] || return 1
  return 0
}

resolve_source() {
  local path="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [ -n "$path" ]; then
    if test_pack_root "$path"; then
      (cd "$path" && pwd)
      return 0
    fi
    warn "--source 指向的目录不是合法模板包根：$path"
  fi

  if test_pack_root "$script_dir"; then
    printf '%s\n' "$script_dir"
    return 0
  fi

  info "本地未找到模板包，开始浅克隆 $REPO ($REF)"
  TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/onepress-XXXXXX")"
  if ! git clone --depth 1 --branch "$REF" "$REPO" "$TEMP_ROOT/pack" >/dev/null 2>&1; then
    die "git clone 失败：$REPO ($REF)"
  fi
  if test_pack_root "$TEMP_ROOT/pack"; then
    printf '%s\n' "$TEMP_ROOT/pack"
    return 0
  fi
  if test_pack_root "$TEMP_ROOT/pack/onePress"; then
    printf '%s\n' "$TEMP_ROOT/pack/onePress"
    return 0
  fi
  die "克隆成功但未找到模板包根（VERSION / opencode/ / qoder/ / trae/ / cursor/ / openspec-schema/ 缺失），请核对仓库布局。"
}

# 输出 qoder / opencode / trae / cursor 的启用状态到全局变量
resolve_harness() {
  local choice="$1"
  local target="$2"
  local has_qoder=0
  local has_opencode=0
  local has_trae=0
  local has_cursor=0

  [ -d "$target/.qoder" ] && has_qoder=1
  [ -d "$target/.opencode" ] && has_opencode=1
  [ -d "$target/.trae" ] && has_trae=1
  [ -d "$target/.cursor" ] && has_cursor=1

  USE_QODER=0
  USE_OPENCODE=0
  USE_TRAE=0
  USE_CURSOR=0

  case "$choice" in
    qoder)    USE_QODER=1 ;;
    opencode) USE_OPENCODE=1 ;;
    trae)     USE_TRAE=1 ;;
    cursor)   USE_CURSOR=1 ;;
    both)     USE_QODER=1; USE_OPENCODE=1 ;;
    all)      USE_QODER=1; USE_OPENCODE=1; USE_TRAE=1; USE_CURSOR=1 ;;
    auto)
      if [ "$has_qoder" = 1 ] || [ "$has_opencode" = 1 ] || [ "$has_trae" = 1 ] || [ "$has_cursor" = 1 ]; then
        USE_QODER=$has_qoder
        USE_OPENCODE=$has_opencode
        USE_TRAE=$has_trae
        USE_CURSOR=$has_cursor
      else
        if [ "$ASSUME_YES" = 1 ]; then
          die "目标仓库未检测到 .qoder/、.opencode/、.trae/ 或 .cursor/，无法自动判定安装范围；请显式指定 --harness qoder|opencode|trae|cursor|both|all。"
        fi
        printf '\n目标仓库未检测到受支持的 AI 编码环境，请选择要安装的环境：\n' >&2
        printf '  1) Qoder\n  2) OpenCode\n  3) Trae\n  4) Cursor\n  5) 全部\n' >&2
        printf '输入 1 / 2 / 3 / 4 / 5（可用逗号组合多个，如 3,4）: ' >&2
        read -r answer
        local token
        for token in $(printf '%s' "$answer" | tr ',+ ' '  '); do
          case "$token" in
            1) USE_QODER=1 ;;
            2) USE_OPENCODE=1 ;;
            3) USE_TRAE=1 ;;
            4) USE_CURSOR=1 ;;
            5) USE_QODER=1; USE_OPENCODE=1; USE_TRAE=1; USE_CURSOR=1 ;;
            *) die "无效选择：$answer" ;;
          esac
        done
        [ "$USE_QODER$USE_OPENCODE$USE_TRAE$USE_CURSOR" != "0000" ] || die "无效选择：$answer"
      fi
      ;;
    *)
      local item
      for item in $(printf '%s' "$choice" | tr ',+ ' '  '); do
        case "$item" in
          qoder)    USE_QODER=1 ;;
          opencode) USE_OPENCODE=1 ;;
          trae)     USE_TRAE=1 ;;
          cursor)   USE_CURSOR=1 ;;
          *) die "无效 --harness：$choice（可选 auto|qoder|opencode|trae|cursor|both|all，或用逗号组合）" ;;
        esac
      done
      [ "$USE_QODER$USE_OPENCODE$USE_TRAE$USE_CURSOR" != "0000" ] || die "无效 --harness：$choice"
      ;;
  esac
}

# 已跟踪文件存在未提交修改的路径（每行一个，正斜杠）；未跟踪文件不算修改
modified_paths() {
  local target="$1"
  [ -d "$target/.git" ] || return 0
  (cd "$target" && git status --porcelain 2>/dev/null) | while IFS= read -r line; do
    [ "${#line}" -gt 3 ] || continue
    local status="${line:0:2}"
    local path="${line:3}"
    [ "$status" = "??" ] && continue
    case "$path" in
      *" -> "*) path="${path##* -> }" ;;
    esac
    printf '%s\n' "$path"
  done
}

# 未跟踪文件的路径（每行一个，正斜杠）
untracked_paths() {
  local target="$1"
  [ -d "$target/.git" ] || return 0
  (cd "$target" && git status --porcelain 2>/dev/null) | while IFS= read -r line; do
    [ "${#line}" -gt 3 ] || continue
    local status="${line:0:2}"
    local path="${line:3}"
    [ "$status" = "??" ] || continue
    case "$path" in
      *" -> "*) path="${path##* -> }" ;;
    esac
    printf '%s\n' "$path"
  done
}

in_list() {
  local needle="$1"
  local list="$2"
  [ -n "$list" ] || return 1
  printf '%s\n' "$list" | grep -Fxq -- "$needle"
}

# ---------------------------------------------------------------- install steps

copy_file() {
  local pack="$1"
  local target="$2"
  local src_rel="$3"
  local dst_rel="$4"
  local src="$pack/$src_rel"
  local dst="$target/$dst_rel"

  if [ ! -f "$src" ]; then
    bad "模板缺失：$src_rel"
    return 0
  fi

  if in_list "$dst_rel" "$MODIFIED"; then
    PROTECTED="$PROTECTED$dst_rel"$'\n'
    skip "$dst_rel（已跟踪文件存在未提交修改，保持原样）"
    return 0
  fi

  if [ -f "$dst" ] && in_list "$dst_rel" "$UNTRACKED" && ! in_list "$dst_rel" "$MANAGED"; then
    PROTECTED="$PROTECTED$dst_rel"$'\n'
    skip "$dst_rel（已存在且不受 onePress 管理，保持原样）"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would write $dst_rel"
    WRITTEN="$WRITTEN$dst_rel"$'\n'
    LOCK_FILES="$LOCK_FILES$dst_rel"$'\n'
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  LOCK_FILES="$LOCK_FILES$dst_rel"$'\n'
  ok "$dst_rel"
}

# 拷贝 onePress 托管命令（qoder/trae/cursor），在 openspec init 之后调用
copy_command_files() {
  local target="$1"
  local files="$2"
  local rel head rest
  for rel in $files; do
    head="${rel%%/*}"
    rest="${rel#*/}"
    copy_file "$PACK_ROOT" "$target" "$rel" ".$head/$rest"
  done
}

mount_skill_reference() {
  local target="$1"
  local skills_dir="$target/.agents/skills"
  local found=0 mounted=0 skipped=0

  if [ ! -d "$skills_dir" ]; then
    skip ".agents/skills/ 不存在，跳过技能挂载（由 openspec init 创建）"
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    found=$((found + 1))
    local rel="${file#"$target"/}"

    if grep -q 'onepress-discipline' "$file" 2>/dev/null; then
      skipped=$((skipped + 1))
      skip "$rel（已含技能引用）"
      continue
    fi
    if in_list "$rel" "$MODIFIED"; then
      skipped=$((skipped + 1))
      skip "$rel（已跟踪文件存在未提交修改，保持原样）"
      continue
    fi
    if [ "$(head -n 1 "$file" | tr -d '\r')" != "---" ] && [ "$(head -n 1 "$file" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//')" != "---" ]; then
      warn "$rel 无 YAML frontmatter，跳过技能挂载"
      MOUNT_SKIPPED="$MOUNT_SKIPPED$rel"$'\n'
      skipped=$((skipped + 1))
      continue
    fi

    if [ "$DRY_RUN" = 1 ]; then
      info "would mount $rel (+1 line)"
      WRITTEN="$WRITTEN$rel (+1 line)"$'\n'
      mounted=$((mounted + 1))
      continue
    fi

    local tmp="$file.onepress-tmp"
    local body="$file.onepress-body"
    local has_bom=0

    # 分离 UTF-8 BOM：awk 判断 frontmatter 时不能带前缀字节
    if [ "$(head -c 3 "$file" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]; then
      has_bom=1
      tail -c +4 "$file" > "$body"
    else
      cp "$file" "$body"
    fi

    awk -v ref="$SKILL_REF" '
      BEGIN { fm = 0; done = 0 }
      {
        line = $0
        cr = ""
        if (line ~ /\r$/) { cr = "\r"; sub(/\r$/, "", line) }
        if (fm == 0 && line ~ /^---[ \t]*$/) { fm = 1; print line cr; next }
        if (fm == 1 && done == 0 && line ~ /^---[ \t]*$/) {
          print line cr
          print cr
          print ref cr
          print cr
          done = 1
          next
        }
        print line cr
      }
    ' "$body" > "$tmp"

    if [ "$has_bom" = 1 ]; then
      printf '\357\273\277' > "$tmp.bom"
      cat "$tmp" >> "$tmp.bom"
      mv -f "$tmp.bom" "$tmp"
    fi

    rm -f "$body"
    mv -f "$tmp" "$file"
    mounted=$((mounted + 1))
    ok "$rel（+1 行技能引用）"
  done < <(find "$skills_dir" -type f -path '*/openspec-*/SKILL.md' | sort)

  if [ "$found" = 0 ]; then
    skip ".agents/skills/openspec-*/SKILL.md 不存在，跳过技能挂载"
    return 0
  fi
  info "技能挂载：mounted $mounted / skipped $skipped（共 $found 个技能）"
}

init_ui_components() {
  local target="$1"
  local rel="docs/ui-components.md"
  local path="$target/$rel"

  if [ -f "$path" ]; then
    if ! grep -qE '^\|.*适用骨架' "$path"; then
      warn "$rel 为旧版表结构（缺「适用骨架」列），建议手工迁移表头为："
      info '  | 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |'
    fi
    skip "$rel（已存在，Protect Local 不覆盖）"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would create $rel"
    WRITTEN="$WRITTEN$rel"$'\n'
    LOCK_FILES="$LOCK_FILES$rel"$'\n'
    return 0
  fi

  mkdir -p "$target/docs"
  cat > "$path" <<'UI_EOF'
# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/openspec-archive-change` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/openspec-new-change` 起草 `ui-spec.md` 前 MUST 先检索本表，可复用的组件写入第 1 节复用表，不得重复造轮子。
2. 新增组件必须补齐：组件名称、路径、适用骨架 (Archetype)、核心 Props 签名。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. `适用骨架` 列取值：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`；通用组件填 `通用`。
5. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|

## 业务组件（domain）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|
UI_EOF
  LOCK_FILES="$LOCK_FILES$rel"$'\n'
  ok "$rel（首装初始化）"
}

probe_uiux() {
  local target="$1"
  local py=0 skill=0 d h
  command -v python3 >/dev/null 2>&1 && py=1
  for d in .qoder/skills .opencode/skills .trae/skills .cursor/skills; do
    if [ -f "$target/$d/ui-ux-pro-max/scripts/search.py" ]; then skill=1; break; fi
  done
  if [ "$py" = 1 ] && [ "$skill" = 1 ]; then
    info 'ui-ux-pro-max：enabled（python3 与技能目录均就绪）'
    return 0
  fi
  if [ "$py" != 1 ]; then
    info 'ui-ux-pro-max：SKIP（未检测到 python3；检索步骤降级为手工填写 ui-spec.md）'
  else
    info 'ui-ux-pro-max：SKIP（未检测到技能目录；检索步骤降级为手工填写 ui-spec.md）'
  fi
  info '  启用设计检索（可选，需 Node.js + Python3）：'
  info '    npm install -g ui-ux-pro-max-cli'
  for h in $(printf '%s' "$SCOPE" | tr '+' ' '); do
    info "    uipro init --ai $h --offline    # 只保留 .$h/skills/ui-ux-pro-max 目录，其余 6 个伴生技能可删"
  done
}

# 2.0.0 config 将 rules 缩进在 context 块内；提升为顶层并保留其余内容。
detect_eol() {
  if LC_ALL=C grep -q $'\r' "$1" 2>/dev/null; then
    printf 'crlf'
  else
    printf 'lf'
  fi
}

normalize_eol() {
  local file="$1" style="$2" tmp="$file.ops-tmp"
  if [ "$style" = "crlf" ]; then
    awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$file" > "$tmp"
  else
    awk '{ sub(/\r$/, ""); printf "%s\n", $0 }' "$file" > "$tmp"
  fi
  mv -f "$tmp" "$file"
}

migrate_nested_rules() {
  local cfg="$1" tmp="$cfg.ops-tmp" start ctx_end rules_end total style
  start="$(grep -nE '^[[:space:]]+rules:[[:space:]]*$' "$cfg" | head -n 1 | cut -d: -f1)"
  [ -n "$start" ] || return 0
  total="$(wc -l < "$cfg" | tr -d ' ')"
  ctx_end="$(awk -v s="$start" 'NR > s && /^[^[:space:]]/ { print NR; exit }' "$cfg")"
  [ -n "$ctx_end" ] || ctx_end="$((total + 1))"
  rules_end="$(awk -v s="$start" -v e="$ctx_end" 'NR > s && NR < e && $0 !~ /^[[:space:]]*$/ && $0 !~ /^    / { print NR; exit }' "$cfg")"
  [ -n "$rules_end" ] || rules_end="$ctx_end"
  style="$(detect_eol "$cfg")"

  head -n "$((start - 1))" "$cfg" > "$tmp"
  # Keep context text that follows the nested rules inside the context block.
  awk -v a="$rules_end" -v b="$ctx_end" 'NR >= a && NR < b { print }' "$cfg" >> "$tmp"
  printf '\nrules:\n' >> "$tmp"
  # Rules content is indented 4 spaces under the nested rules; dedent 2.
  awk -v s="$start" -v e="$rules_end" 'NR > s && NR < e { sub(/^  /, ""); print }' "$cfg" >> "$tmp"
  # Preserve top-level keys after the context block.
  awk -v e="$ctx_end" 'NR >= e { print }' "$cfg" >> "$tmp"
  mv -f "$tmp" "$cfg"
  normalize_eol "$cfg" "$style"
}

ensure_rule_key() {
  local cfg="$1" key="$2" rule="$3" tmp="$cfg.ops-tmp" style
  grep -qE "^  ${key}:[[:space:]]*$" "$cfg" && return 0
  grep -qE '^rules:[[:space:]]*$' "$cfg" || return 0
  style="$(detect_eol "$cfg")"
  awk -v key="$key" -v rule="$rule" '
    { print }
    /^rules:[[:space:]]*$/ && !done {
      print "  " key ":"
      print "    - " rule
      done = 1
    }
  ' "$cfg" > "$tmp"
  mv -f "$tmp" "$cfg"
  normalize_eol "$cfg" "$style"
}

ensure_rule_keys() {
  local cfg="$1"
  ensure_rule_key "$cfg" proposal "注明涉及的 harness 与资产归属层级（harness 级 / tooling 级 / project 级）"
  ensure_rule_key "$cfg" specs "每条需求 MUST 使用 RFC 2119 关键词（SHALL/MUST/SHOULD/MAY）"
  ensure_rule_key "$cfg" design "必须包含至少一条 ADR（Context / Decision / Alternatives considered / Rationale / Consequences）"
  ensure_rule_key "$cfg" tasks "每个任务 MUST 为 2–5 分钟认知粒度"
  ensure_rule_key "$cfg" plan "每个 Task MUST 包含 Files / Interfaces / TDD 步骤 / Run 与 Expected"
  ensure_rule_key "$cfg" apply "TDD 铁律：没有先失败的测试，绝不编写生产代码"
  ensure_rule_key "$cfg" verify-report "必须执行一次冷上下文代码盲审，Critical 与 Important 必须为 0"
}

confirm_openspec_schema() {
  local target="$1"
  local cfg="$target/openspec/config.yaml"

  if [ ! -f "$cfg" ]; then
    if [ "$DRY_RUN" = 1 ]; then
      info 'would create openspec/config.yaml (schema: superspec)'
      return 0
    fi
    mkdir -p "$target/openspec"
    cat > "$cfg" <<'CFG_EOF'
schema: superspec

context: |
  Tech stack: <以实际项目为准>
  Workflow Methodology: Strict TDD (RED → GREEN → REFACTOR) for all logic changes.
  Validation Principle: Evidence Before Claims — no completion claim without fresh terminal output.

rules:
  proposal:
    - 注明涉及的 harness 与资产归属层级（harness 级 / tooling 级 / project 级）
    - 注明受影响的安装场景（全新安装 / 升级 / 回滚）
  specs:
    - 每条需求 MUST 使用 RFC 2119 关键词（SHALL/MUST/SHOULD/MAY）
    - 每条需求 MUST 至少包含一个 GIVEN/WHEN/THEN 场景，且场景具体可测试
  design:
    - 必须包含至少一条 ADR（Context / Decision / Alternatives considered / Rationale / Consequences）
    - 必须列出 3–5 条 Non-Goals（YAGNI）
    - 必须列出 Risks / Trade-offs 与缓解措施
    - "UI 变更 MUST 在 proposal.md 首行给出 **UI Change**: yes|no；yes 时必须产出 ui-spec.md 与 sandbox-preview.html"
  tasks:
    - 每个任务 MUST 为 2–5 分钟认知粒度
    - 每个任务 MUST 用反引号标注精确文件路径与验证命令
    - 含逻辑修改的任务 MUST 内嵌 RED / GREEN / REFACTOR 勾选
    - "文档/配置任务 MUST 写 TDD: N/A (<reason>)"
  plan:
    - 每个 Task MUST 包含 Files / Interfaces / TDD 步骤 / Run 与 Expected
    - 写完后 MUST 运行 scripts/onepress-plan-lint.sh 并修复所有 FAIL
  apply:
    - TDD 铁律：没有先失败的测试，绝不编写生产代码
    - 根因调试铁律：连续两次修复无效必须停止补丁并按四阶段溯源
    - 每个任务完成后 MUST 在 apply.md 粘贴真实命令输出与退出码
  verify-report:
    - 必须在终端重新运行测试/构建/lint/UI 门禁，禁止复用历史结果
    - 必须执行一次冷上下文代码盲审，Critical 与 Important 必须为 0
    - 必须运行 scripts/onepress-evidence-lint.sh 并修复所有 FAIL
CFG_EOF
    ok 'openspec/config.yaml（新建，schema=superspec）'
    return 0
  fi

  local current
  current="$(grep -E '^schema:' "$cfg" | head -n 1 | sed 's/^schema:[[:space:]]*//' | tr -d '\r')"

  if [ -z "$current" ]; then
    warn 'openspec/config.yaml 未找到顶层 schema 行，未改动'
    return 0
  fi

  if [ "$current" = "superspec" ]; then
    if ! grep -qE '^rules:' "$cfg" && grep -qE '^[[:space:]]+rules:[[:space:]]*$' "$cfg"; then
      if [ "$DRY_RUN" = 1 ]; then
        info 'would migrate openspec/config.yaml rules: nested(context) -> top-level'
        return 0
      fi
      migrate_nested_rules "$cfg"
      ok 'openspec/config.yaml rules: nested(context) → top-level'
    else
      info 'openspec/config.yaml schema=superspec ... OK'
    fi
    if [ "$DRY_RUN" = 0 ] && grep -qE '^rules:' "$cfg"; then
      ensure_rule_keys "$cfg"
    fi
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would set openspec/config.yaml schema: $current -> superspec"
    return 0
  fi

  local tmp="$cfg.ops-tmp"
  awk '
    BEGIN { done = 0 }
    !done && /^schema:/ {
      cr = ""
      line = $0
      if (line ~ /\r$/) cr = "\r"
      print "schema: superspec" cr
      done = 1
      next
    }
    { print }
  ' "$cfg" > "$tmp"
  mv -f "$tmp" "$cfg"
  info "openspec/config.yaml schema: $current → superspec（保留原换行与其余字段）"
}

# OpenSpec CLI 版本门控：主版本 >= 2 才允许安装
check_openspec_version() {
  local out major

  if ! command -v openspec >/dev/null 2>&1; then
    die '未检测到 openspec CLI（要求 >= 2.0.0）。安装：npm install -g @fission-ai/openspec@latest；或改用 onePress v1.1.0。'
  fi

  out="$(openspec --version 2>/dev/null | head -n 1)"
  major="$(printf '%s' "$out" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | cut -d. -f1 || true)"

  if [ -z "$major" ] || [ "$major" -lt 2 ]; then
    die "OpenSpec CLI 版本不满足：当前 '${out:-未知}'，要求 >= 2.0.0。升级：npm install -g @fission-ai/openspec@latest；或改用 onePress v1.1.0。"
  fi
  info "OpenSpec CLI：$out（>= 2.0.0）... OK"
}

# 12 个 OpenSpec 2.0 技能是否齐全
skills_complete() {
  local target="$1"
  local slug
  for slug in $SKILL_SLUGS; do
    [ -f "$target/.agents/skills/openspec-$slug/SKILL.md" ] || return 1
  done
  return 0
}

# 缺失时用 openspec init 补齐 .agents/skills（2.0 唯一工作流载体）
ensure_skills() {
  local target="$1"
  local tools_csv="$2"

  if skills_complete "$target"; then
    info ".agents/skills/openspec-*（12 个）齐全 ... OK"
    return 0
  fi

  if [ "$NO_INIT" = 1 ]; then
    warn ".agents/skills 不完整且指定了 --no-init：技能将\"存在但永不加载\"，需手动 openspec init 后重跑"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would run: openspec init --tools $tools_csv --no-animation"
    return 0
  fi

  local out
  if ! out="$(cd "$target" && openspec init --tools "$tools_csv" --no-animation 2>&1)"; then
    warn "openspec init 失败：$(printf '%s' "$out" | tail -n 3)"
    return 0
  fi

  if skills_complete "$target"; then
    info "openspec init 生成 .agents/skills/openspec-*（12 个）"
  else
    warn ".agents/skills 仍不完整，请检查 openspec init 输出"
  fi
}

# 清理 OpenSpec 1.x 遗留命令（仅限已启用 harness；未提交修改受保护）
remove_legacy_commands() {
  local target="$1"
  local harness_dir="$2"
  local rel path

  case "$harness_dir" in
    .qoder)
      [ -d "$target/.qoder/commands/opsx" ] || return 0
      for path in "$target/.qoder/commands/opsx"/*.md; do
        [ -f "$path" ] || continue
        rel=".qoder/commands/opsx/$(basename "$path")"
        if in_list "$rel" "$MODIFIED"; then
          warn "保留未提交修改，不清理 1.x 命令：$rel"
          continue
        fi
        if [ "$DRY_RUN" = 1 ]; then
          info "would remove legacy $rel"
          continue
        fi
        rm -f "$path"
        info "清理 1.x 命令：$rel"
      done
      [ "$DRY_RUN" = 1 ] || rmdir "$target/.qoder/commands/opsx" 2>/dev/null || true
      ;;
    *)
      for rel in "$harness_dir/commands/opsx-new.md" "$harness_dir/commands/opsx-apply.md" "$harness_dir/commands/opsx-verify.md" "$harness_dir/commands/opsx-review.md"; do
        path="$target/$rel"
        [ -f "$path" ] || continue
        if in_list "$rel" "$MODIFIED"; then
          warn "保留未提交修改，不清理 1.x 命令：$rel"
          continue
        fi
        if [ "$DRY_RUN" = 1 ]; then
          info "would remove legacy $rel"
          continue
        fi
        rm -f "$path"
        info "清理 1.x 命令：$rel"
      done
      ;;
  esac
}

lock_files() {
  local lock="$1"
  [ -f "$lock" ] || return 0
  awk '
    /"files"[[:space:]]*:/ { infiles = 1; next }
    infiles && /\]/ { infiles = 0 }
    infiles && match($0, /"[^"]+"/) { print substr($0, RSTART + 1, RLENGTH - 2) }
  ' "$lock"
}

lock_value() {
  local lock="$1"
  local key="$2"
  [ -f "$lock" ] || return 0
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",]*\)\"\{0,1\}.*/\1/p" "$lock" | head -n 1
}

# 生成本次会写入的目标路径清单（每行一个）
build_will_write() {
  local rel
  WILL_WRITE=""
  for rel in $SCHEMA_FILES; do
    WILL_WRITE="${WILL_WRITE}openspec/schemas/superspec/$rel"$'\n'
  done
  if [ "$USE_OPENCODE" = 1 ]; then
    for rel in $OPENCODE_FILES; do
      WILL_WRITE="$WILL_WRITE.opencode/${rel#opencode/}"$'\n'
    done
  fi
  if [ "$USE_QODER" = 1 ]; then
    for rel in $QODER_FILES; do
      WILL_WRITE="$WILL_WRITE.qoder/${rel#qoder/}"$'\n'
    done
    for rel in $QODER_COMMAND_FILES; do
      WILL_WRITE="$WILL_WRITE.${rel%%/*}/${rel#*/}"$'\n'
    done
  fi
  if [ "$USE_TRAE" = 1 ]; then
    for rel in $TRAE_FILES; do
      WILL_WRITE="$WILL_WRITE.trae/${rel#trae/}"$'\n'
    done
    for rel in $TRAE_COMMAND_FILES; do
      WILL_WRITE="$WILL_WRITE.${rel%%/*}/${rel#*/}"$'\n'
    done
  fi
  if [ "$USE_CURSOR" = 1 ]; then
    for rel in $CURSOR_FILES; do
      WILL_WRITE="$WILL_WRITE.cursor/${rel#cursor/}"$'\n'
    done
    for rel in $CURSOR_COMMAND_FILES; do
      WILL_WRITE="$WILL_WRITE.${rel%%/*}/${rel#*/}"$'\n'
    done
  fi
  for rel in $TOOLING_FILES; do
    WILL_WRITE="$WILL_WRITE$rel"$'\n'
  done
  WILL_WRITE="$WILL_WRITE""docs/ui-components.md"$'\n'
}

remove_stale_files() {
  local target="$1"
  local lock="$2"
  local rel

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    # 本次仍会写入的文件由 copy_file 负责覆盖，绝不能在这里先删
    in_list "$rel" "$WILL_WRITE" && continue
    case "$rel" in
      .opencode/*) [ "$USE_OPENCODE" = 1 ] || continue ;;
      .qoder/*)    [ "$USE_QODER" = 1 ] || continue ;;
      .trae/*)     [ "$USE_TRAE" = 1 ] || continue ;;
      .cursor/*)   [ "$USE_CURSOR" = 1 ] || continue ;;
      docs/*|openspec/changes/*) continue ;;
    esac
    [ -f "$target/$rel" ] || continue
    if in_list "$rel" "$MODIFIED"; then
      warn "保留未提交修改，不清理：$rel"
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      info "would remove stale $rel"
      continue
    fi
    rm -f "$target/$rel"
    info "清理旧版本残留：$rel"
  done < <(lock_files "$lock")
}

write_lock() {
  local target="$1"
  local version="$2"
  local qoder_bool opencode_bool trae_bool cursor_bool files_json

  [ "$USE_QODER" = 1 ] && qoder_bool="true" || qoder_bool="false"
  [ "$USE_OPENCODE" = 1 ] && opencode_bool="true" || opencode_bool="false"
  [ "$USE_TRAE" = 1 ] && trae_bool="true" || trae_bool="false"
  [ "$USE_CURSOR" = 1 ] && cursor_bool="true" || cursor_bool="false"

  files_json="$(printf '%s' "$LOCK_FILES" | grep -v '^$' | grep -v '^\.agents/skills/' | sort -u | sed 's/.*/    "&",/' | sed '$ s/,$//')"

  if [ "$DRY_RUN" = 1 ]; then
    info 'would write onePress.lock'
    return 0
  fi

  cat > "$target/onePress.lock" <<LOCK_EOF
{
  "version": "$version",
  "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "harnesses": {
    "qoder": $qoder_bool,
    "opencode": $opencode_bool,
    "trae": $trae_bool,
    "cursor": $cursor_bool
  },
  "protectedAssets": [
    "docs/ui-components.md",
    "openspec/changes/"
  ],
  "files": [
$files_json
  ]
}
LOCK_EOF
  ok 'onePress.lock'
}

# 验收以技能 + 命令引用为载体的 harness（qoder / trae / cursor）
accept_skill_harness() {
  local pack="$1"
  local target="$2"
  local harness_dir="$3"
  local tool="$4"
  local files="$5"
  local rel dst_rel kw

  for rel in $files; do
    dst_rel="$harness_dir/${rel#$tool/}"
    if in_list "$dst_rel" "$PROTECTED"; then
      skip "$dst_rel（受保护跳过，不计入失败）"
      continue
    fi
    [ -f "$target/$dst_rel" ] || bad "缺失目标文件：$dst_rel"
    cmp -s "$pack/$rel" "$target/$dst_rel" || bad "内容不一致：$dst_rel"
  done

  if [ -f "$target/$harness_dir/skills/onepress-discipline/SKILL.md" ]; then
    for kw in ui-spec.md ui_change sandbox-preview 44×44 prefers-reduced-motion 四态 无障碍 防呆 RED GREEN REFACTOR verification-evidence Root-Cause Critical; do
      grep -q "$kw" "$target/$harness_dir/skills/onepress-discipline/SKILL.md" || bad "$harness_dir/skills/onepress-discipline/SKILL.md 缺少铁律关键词：$kw"
    done
  fi
}

# 验收 .agents/skills 挂载面（四 harness 共享）
accept_skills_mount() {
  local target="$1"
  local slug rel count=0 legacy h

  for slug in $SKILL_SLUGS; do
    rel=".agents/skills/openspec-$slug/SKILL.md"
    if [ ! -f "$target/$rel" ]; then
      bad "缺失技能文件：$rel"
      continue
    fi
    grep -q 'onepress-discipline' "$target/$rel" || bad "未挂载技能引用：$rel"
    count=$((count + 1))
  done

  [ "$count" = 12 ] && info ".agents/skills 挂载面：12/12 技能含引用行 ... OK"

  if [ "$USE_QODER" = 1 ] && [ -d "$target/.qoder/commands/opsx" ]; then
    while IFS= read -r legacy; do
      [ -n "$legacy" ] || continue
      legacy="${legacy#"$target"/}"
      if in_list "$legacy" "$MODIFIED"; then
        skip "$legacy（未提交修改，受保护保留，不计入失败）"
      else
        bad "1.x 命令残留：$legacy"
      fi
    done < <(find "$target/.qoder/commands/opsx" -type f -name '*.md' 2>/dev/null)
  fi

  for h in .trae .cursor .opencode; do
    case "$h" in
      .trae)    [ "$USE_TRAE" = 1 ] || continue ;;
      .cursor)  [ "$USE_CURSOR" = 1 ] || continue ;;
      .opencode) [ "$USE_OPENCODE" = 1 ] || continue ;;
    esac
    for rel in "$h/commands/opsx-new.md" "$h/commands/opsx-apply.md" "$h/commands/opsx-verify.md" "$h/commands/opsx-review.md"; do
      [ -f "$target/$rel" ] || continue
      if in_list "$rel" "$MODIFIED"; then
        skip "$rel（未提交修改，受保护保留，不计入失败）"
      else
        bad "1.x 命令残留：$rel"
      fi
    done
  done
}

run_acceptance() {
  local pack="$1"
  local target="$2"
  local version="$3"

  step '④ 验收自检'

  local count=0 expected=0
  # shellcheck disable=SC2086
  set -- $SCHEMA_FILES
  expected=$#
  if [ -d "$target/openspec/schemas/superspec" ]; then
    count="$(find "$target/openspec/schemas/superspec" -type f | wc -l | tr -d ' ')"
  fi
  if [ "$count" = "$expected" ]; then
    info "openspec/schemas/superspec 共 $expected 文件（含 ui-spec.md / review.md / review-rubric.md / verification.md / code-reviewer.md）... OK"
  else
    bad "openspec/schemas/superspec 文件数应为 $expected，实际 $count"
  fi

  if [ -f "$target/openspec/schemas/superspec/schema.yaml" ]; then
    local fb_count
    fb_count="$(grep -c 'SKILL FALLBACK' "$target/openspec/schemas/superspec/schema.yaml" 2>/dev/null || true)"
    if [ "${fb_count:-0}" -ge 4 ]; then
      info "schema.yaml 技能兜底：$fb_count 处 SKILL FALLBACK ... OK"
    else
      bad "schema.yaml 只有 ${fb_count:-0} 处 SKILL FALLBACK（brainstorm/plan/apply/finalize 应各 1 处）"
    fi
    grep -q 'onepress-plan-lint.sh' "$target/openspec/schemas/superspec/schema.yaml" \
      || bad 'schema.yaml plan 指令未引用 onepress-plan-lint.sh'
    grep -q 'Execution: OpenSpec apply' "$target/openspec/schemas/superspec/schema.yaml" \
      || bad 'schema.yaml plan 指令缺少 Execution: OpenSpec apply 适配'
  fi

  local plan_template="$target/openspec/schemas/superspec/templates/plan.md"
  if [ -f "$plan_template" ]; then
    local plan_ok=1 kw
    for kw in '**Spec:**' '## Global Constraints' '## Review Focus' '## Evidence Map' '## File Structure' '**Files:**' '**Interfaces:**' '## Self-Review'; do
      if ! grep -qF "$kw" "$plan_template"; then
        bad "plan.md 模板缺少 $kw"
        plan_ok=0
      fi
    done
    [ "$plan_ok" = 1 ] && info 'plan.md 模板结构完整（Spec/Constraints/Review Focus/Evidence Map/File Structure/Files/Interfaces/Self-Review）... OK'
  fi

  local src_rel dst_rel rel
  for rel in $SCHEMA_FILES; do
    src_rel="openspec-schema/superspec/$rel"
    dst_rel="openspec/schemas/superspec/$rel"
    if in_list "$dst_rel" "$PROTECTED"; then
      skip "$dst_rel（受保护跳过，不计入失败）"
      continue
    fi
    [ -f "$target/$dst_rel" ] || bad "缺失目标文件：$dst_rel"
    cmp -s "$pack/$src_rel" "$target/$dst_rel" || bad "内容不一致：$dst_rel"
  done

  if [ "$USE_OPENCODE" = 1 ]; then
    for rel in $OPENCODE_FILES; do
      dst_rel=".opencode/${rel#opencode/}"
      if in_list "$dst_rel" "$PROTECTED"; then
        skip "$dst_rel（受保护跳过，不计入失败）"
        continue
      fi
      [ -f "$target/$dst_rel" ] || bad "缺失目标文件：$dst_rel"
      cmp -s "$pack/$rel" "$target/$dst_rel" || bad "内容不一致：$dst_rel"
    done
    if [ -f "$target/.opencode/opencode.json" ]; then
      grep -q '"' "$target/.opencode/opencode.json" || bad '.opencode/opencode.json 不像合法 JSON'
    fi
  fi

  if [ "$USE_QODER$USE_OPENCODE$USE_TRAE$USE_CURSOR" != "0000" ]; then
    accept_skills_mount "$target"
  fi

  if [ "$USE_QODER" = 1 ]; then
    accept_skill_harness "$pack" "$target" .qoder qoder "$QODER_FILES"
    [ -f "$target/.qoder/commands/openspec-review-change.md" ] || bad '缺失 .qoder/commands/openspec-review-change.md'
    cmp -s "$pack/qoder/commands/openspec-review-change.md" "$target/.qoder/commands/openspec-review-change.md" || bad '内容不一致：.qoder/commands/openspec-review-change.md'
  fi

  if [ "$USE_TRAE" = 1 ]; then
    accept_skill_harness "$pack" "$target" .trae trae "$TRAE_FILES"
    [ -f "$target/.trae/commands/openspec-review-change.md" ] || bad '缺失 .trae/commands/openspec-review-change.md'
    cmp -s "$pack/trae/commands/openspec-review-change.md" "$target/.trae/commands/openspec-review-change.md" || bad '内容不一致：.trae/commands/openspec-review-change.md'
  fi

  if [ "$USE_CURSOR" = 1 ]; then
    accept_skill_harness "$pack" "$target" .cursor cursor "$CURSOR_FILES"
    [ -f "$target/.cursor/commands/openspec-review-change.md" ] || bad '缺失 .cursor/commands/openspec-review-change.md'
    cmp -s "$pack/cursor/commands/openspec-review-change.md" "$target/.cursor/commands/openspec-review-change.md" || bad '内容不一致：.cursor/commands/openspec-review-change.md'
  fi

  for rel in $TOOLING_FILES; do
    if in_list "$rel" "$PROTECTED"; then
      skip "$rel（受保护跳过，不计入失败）"
      continue
    fi
    [ -f "$target/$rel" ] || bad "缺失目标文件：$rel"
    cmp -s "$pack/$rel" "$target/$rel" || bad "内容不一致：$rel"
  done

  if [ -f "$target/scripts/onepress-plan-lint.sh" ]; then
    bash -n "$target/scripts/onepress-plan-lint.sh" || bad 'onepress-plan-lint.sh 语法错误'
  fi
  if [ -f "$target/scripts/onepress-evidence-lint.sh" ]; then
    bash -n "$target/scripts/onepress-evidence-lint.sh" || bad 'onepress-evidence-lint.sh 语法错误'
  fi
  if [ -f "$target/scripts/onepress-review-lint.sh" ]; then
    bash -n "$target/scripts/onepress-review-lint.sh" || bad 'onepress-review-lint.sh 语法错误'
  fi
  if [ -f "$target/scripts/onepress-verify.sh" ]; then
    bash -n "$target/scripts/onepress-verify.sh" || bad 'onepress-verify.sh 语法错误'
  fi
  if grep -q 'id: verify-report' "$target/openspec/schemas/superspec/schema.yaml" 2>/dev/null; then
    info 'schema.yaml verify-report 工件 ... OK'
  else
    bad 'schema.yaml 缺少 verify-report 工件'
  fi
  if grep -q 'id: review' "$target/openspec/schemas/superspec/schema.yaml" 2>/dev/null; then
    info 'schema.yaml review 工件 ... OK'
  else
    bad 'schema.yaml 缺少 review 工件'
  fi

  if [ -f "$target/openspec/config.yaml" ]; then
    if tr -d '\r' < "$target/openspec/config.yaml" | grep -qE '^schema:[[:space:]]*superspec[[:space:]]*$'; then
      info 'openspec/config.yaml schema=superspec ... OK'
    else
      bad 'openspec/config.yaml 的 schema 不是 superspec（十一工件序列 brainstorm→…→plan→review→apply→verify-report→verify→finalize 不可用）'
    fi
    if tr -d '\r' < "$target/openspec/config.yaml" | grep -qE '^rules:'; then
      local missing="" rule_key
      for rule_key in proposal specs design tasks plan apply verify-report; do
        tr -d '\r' < "$target/openspec/config.yaml" | grep -qE "^  ${rule_key}:[[:space:]]*$" || missing="$missing $rule_key"
      done
      if [ -z "$missing" ]; then
        info 'openspec/config.yaml 顶层 rules 七键齐全 ... OK'
      else
        bad "openspec/config.yaml 顶层 rules 缺少：$missing"
      fi
    else
      bad 'openspec/config.yaml 缺少顶层 rules（规则不会按工件注入；请重装或按 2.2.1 模板重建 rules）'
    fi
  else
    bad 'openspec/config.yaml 缺失（安装器应已创建）'
  fi

  if [ -f "$target/onePress.lock" ]; then
    local lock_version
    lock_version="$(lock_value "$target/onePress.lock" version)"
    [ "$lock_version" = "$version" ] || bad "lock version 应为 $version，实际 $lock_version"
    if grep -q '\.agents/skills/' "$target/onePress.lock"; then
      bad 'onePress.lock 不应记录 .agents/skills 文件'
    fi
  else
    bad 'onePress.lock 缺失'
  fi

  [ -z "$FAILURES" ] && info '全部验收项通过 ... OK'
}

# ---------------------------------------------------------------- main

while [ $# -gt 0 ]; do
  case "$1" in
    --harness) HARNESS="${2:-}"; shift 2 ;;
    --source) SOURCE="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ref) REF="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    --no-init) NO_INIT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1（--help 查看用法）" ;;
  esac
done

trap cleanup EXIT

printf '\nonePress 安装器\n'

step '① 前置检查'

TARGET_ROOT="$(cd "${TARGET:-.}" && pwd)" || die "目标目录不存在：${TARGET:-.}"
[ -d "$TARGET_ROOT/.git" ] || warn '目标目录不是 git 仓库（无 .git/）：本地未提交修改保护将不可用'

PACK_ROOT="$(resolve_source "$SOURCE")" || exit 1
VERSION="$(tr -d '\r\n' < "$PACK_ROOT/VERSION")"
info "模板包：$PACK_ROOT（v$VERSION）"
info "目标仓库：$TARGET_ROOT"

check_openspec_version

resolve_harness "$HARNESS" "$TARGET_ROOT"
SCOPE=""
[ "$USE_QODER" = 1 ] && SCOPE="qoder"
[ "$USE_OPENCODE" = 1 ] && SCOPE="${SCOPE:+$SCOPE+}opencode"
[ "$USE_TRAE" = 1 ] && SCOPE="${SCOPE:+$SCOPE+}trae"
[ "$USE_CURSOR" = 1 ] && SCOPE="${SCOPE:+$SCOPE+}cursor"
printf '   [OK]   安装范围 harnesses：%s\n' "$SCOPE"

LOCK="$TARGET_ROOT/onePress.lock"
OLD_VERSION=""
if [ -f "$LOCK" ]; then
  OLD_VERSION="$(lock_value "$LOCK" version)"
fi
if [ -n "$OLD_VERSION" ]; then
  if [ "$OLD_VERSION" = "$VERSION" ]; then
    INSTALL_KIND='重装（同版本幂等）'
  else
    INSTALL_KIND="升级（$OLD_VERSION → $VERSION）"
  fi
else
  INSTALL_KIND='全新安装'
fi
info "安装类型：$INSTALL_KIND"

MODIFIED="$(modified_paths "$TARGET_ROOT")"
UNTRACKED="$(untracked_paths "$TARGET_ROOT")"
MANAGED="$(lock_files "$LOCK")"
if [ -n "$MODIFIED" ]; then
  warn "检测到 $(printf '%s\n' "$MODIFIED" | grep -c .) 个已跟踪文件存在未提交修改，命中的 harness 文件将被跳过"
fi

step '② 分层安装'

build_will_write
if [ -n "$OLD_VERSION" ]; then
  remove_stale_files "$TARGET_ROOT" "$LOCK"
fi

for rel in $SCHEMA_FILES; do
  copy_file "$PACK_ROOT" "$TARGET_ROOT" "openspec-schema/superspec/$rel" "openspec/schemas/superspec/$rel"
done

if [ "$USE_OPENCODE" = 1 ]; then
  for rel in $OPENCODE_FILES; do
    copy_file "$PACK_ROOT" "$TARGET_ROOT" "$rel" ".opencode/${rel#opencode/}"
  done
fi

if [ "$USE_QODER" = 1 ]; then
  for rel in $QODER_FILES; do
    copy_file "$PACK_ROOT" "$TARGET_ROOT" "$rel" ".qoder/${rel#qoder/}"
  done
fi

if [ "$USE_TRAE" = 1 ]; then
  for rel in $TRAE_FILES; do
    copy_file "$PACK_ROOT" "$TARGET_ROOT" "$rel" ".trae/${rel#trae/}"
  done
fi

if [ "$USE_CURSOR" = 1 ]; then
  for rel in $CURSOR_FILES; do
    copy_file "$PACK_ROOT" "$TARGET_ROOT" "$rel" ".cursor/${rel#cursor/}"
  done
fi

for rel in $TOOLING_FILES; do
  copy_file "$PACK_ROOT" "$TARGET_ROOT" "$rel" "$rel"
done

init_ui_components "$TARGET_ROOT"

confirm_openspec_schema "$TARGET_ROOT"

TOOLS_CSV=""
[ "$USE_QODER" = 1 ] && TOOLS_CSV="${TOOLS_CSV:+$TOOLS_CSV,}qoder"
[ "$USE_OPENCODE" = 1 ] && TOOLS_CSV="${TOOLS_CSV:+$TOOLS_CSV,}opencode"
[ "$USE_TRAE" = 1 ] && TOOLS_CSV="${TOOLS_CSV:+$TOOLS_CSV,}trae"
[ "$USE_CURSOR" = 1 ] && TOOLS_CSV="${TOOLS_CSV:+$TOOLS_CSV,}cursor"
ensure_skills "$TARGET_ROOT" "$TOOLS_CSV"

if [ "$USE_QODER" = 1 ]; then
  remove_legacy_commands "$TARGET_ROOT" .qoder
  copy_command_files "$TARGET_ROOT" "$QODER_COMMAND_FILES"
fi

if [ "$USE_TRAE" = 1 ]; then
  remove_legacy_commands "$TARGET_ROOT" .trae
  copy_command_files "$TARGET_ROOT" "$TRAE_COMMAND_FILES"
fi

if [ "$USE_CURSOR" = 1 ]; then
  remove_legacy_commands "$TARGET_ROOT" .cursor
  copy_command_files "$TARGET_ROOT" "$CURSOR_COMMAND_FILES"
fi

if [ "$USE_OPENCODE" = 1 ]; then
  remove_legacy_commands "$TARGET_ROOT" .opencode
fi

if [ -n "$TOOLS_CSV" ]; then
  mount_skill_reference "$TARGET_ROOT"
fi

step '③ 写入 onePress.lock'
write_lock "$TARGET_ROOT" "$VERSION"

if [ "$DRY_RUN" != 1 ]; then
  run_acceptance "$PACK_ROOT" "$TARGET_ROOT" "$VERSION"
fi

step '⑤ 可选增强层探测'
probe_uiux "$TARGET_ROOT"

step '⑥ 报告'
info "安装范围：harnesses: $SCOPE"
info "安装类型：$INSTALL_KIND"
WRITTEN_COUNT="$(printf '%s' "$WRITTEN" | grep -c . || true)"
SKIPPED_COUNT="$(printf '%s' "$SKIPPED" | grep -c . || true)"
FAILED_COUNT="$(printf '%s' "$FAILURES" | grep -c . || true)"
info "写入 $WRITTEN_COUNT 项，跳过 $SKIPPED_COUNT 项，失败 $FAILED_COUNT 项"

if [ -n "$SKIPPED" ]; then
  printf '   跳过项：\n'
  printf '%s' "$SKIPPED" | sed 's/^/     - /'
fi

printf '\n'
if [ -n "$FAILURES" ]; then
  printf 'onePress v%s 安装失败（harnesses: %s）\n' "$VERSION" "$SCOPE" >&2
  exit 1
fi
printf 'onePress v%s 安装完成（harnesses: %s）\n' "$VERSION" "$SCOPE"
exit 0