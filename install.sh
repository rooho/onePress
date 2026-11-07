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

SKILL_REF='> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。'

SCHEMA_FILES="schema.yaml templates/apply.md templates/brainstorm.md templates/design.md templates/finalize.md templates/plan.md templates/proposal.md templates/spec.md templates/tasks.md templates/verify.md"

OPENCODE_FILES="opencode/opencode.json opencode/agent/ux-architect.md opencode/commands/opsx-new.md opencode/commands/opsx-apply.md opencode/commands/opsx-verify.md opencode/skills/superpowers-tdd/SKILL.md"

QODER_FILES="qoder/skills/onepress-discipline/SKILL.md"

TRAE_FILES="trae/skills/onepress-discipline/SKILL.md"

CURSOR_FILES="cursor/skills/onepress-discipline/SKILL.md"

WRITTEN=""
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
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  ok "$dst_rel"
}

mount_skill_reference() {
  local target="$1"
  local harness_dir="$2"
  local cmd_dir="$target/$harness_dir/commands"

  if [ ! -d "$cmd_dir" ]; then
    skip "$harness_dir/commands/ 不存在，跳过技能挂载（不新建命令文件）"
    return 0
  fi

  local found=0
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    found=1
    local rel="${file#"$target"/}"

    if grep -q 'onepress-discipline' "$file" 2>/dev/null; then
      skip "$rel（已含技能引用）"
      continue
    fi
    if in_list "$rel" "$MODIFIED"; then
      skip "$rel（已跟踪文件存在未提交修改，保持原样）"
      continue
    fi
    if [ "$(head -n 1 "$file" | tr -d '\r')" != "---" ] && [ "$(head -n 1 "$file" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//')" != "---" ]; then
      warn "$rel 无 YAML frontmatter，跳过技能挂载"
      MOUNT_SKIPPED="$MOUNT_SKIPPED$rel"$'\n'
      continue
    fi

    if [ "$DRY_RUN" = 1 ]; then
      info "would mount $rel (+1 line)"
      WRITTEN="$WRITTEN$rel (+1 line)"$'\n'
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
    ok "$rel（+1 行技能引用）"
  done < <(find "$cmd_dir" -type f -name '*.md' | sort)

  [ "$found" = 1 ] || skip "$harness_dir/commands/ 下没有命令文件，跳过技能挂载"
}

init_ui_components() {
  local target="$1"
  local rel="docs/ui-components.md"
  local path="$target/$rel"

  if [ -f "$path" ]; then
    skip "$rel（已存在，Protect Local 不覆盖）"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would create $rel"
    WRITTEN="$WRITTEN$rel"$'\n'
    return 0
  fi

  mkdir -p "$target/docs"
  cat > "$path" <<'UI_EOF'
# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/opsx:archive` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/opsx:new` 起草 `ui_contract` 前 MUST 先检索本表，可复用的组件写入 `reuse_components`，不得重复造轮子。
2. 新增组件必须补齐：组件名、文件路径、用途、关键 Props、状态覆盖（loading / empty / error / submitting）。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名 | 文件路径 | 用途 | 关键 Props | 状态覆盖 | 首次引入 |
|--------|----------|------|-----------|----------|----------|

## 业务组件（domain）

| 组件名 | 文件路径 | 用途 | 关键 Props | 状态覆盖 | 首次引入 |
|--------|----------|------|-----------|----------|----------|
UI_EOF
  ok "$rel（首装初始化）"
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
  rules:
    specs:
      - 每条需求 MUST 使用 RFC 2119 关键词（SHALL/MUST/SHOULD/MAY）
      - 每条需求 MUST 至少包含一个 GIVEN/WHEN/THEN 场景，且场景具体可测试
    design:
      - 涉及页面与交互的变更 MUST 在 design.md 底部给出 ui_contract（archetype / reuse_components / schema_mapping / states_matrix / layout_tokens）
    tasks:
      - 每个任务为原子工作单元，可独立验证（跑测试、产生输出或肉眼点检）
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
    info 'openspec/config.yaml schema=superspec ... OK'
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

# 判断 commands/ 是否已是 openspec 生成的完整命令集（缺任一标准命令即视为不完整）
harness_command_set_complete() {
  local cmd_dir="$1"
  local id
  for id in continue ff propose archive; do
    [ -f "$cmd_dir/opsx-$id.md" ] || return 1
  done
  return 0
}

# 清理旧版本随包直出的命令（会阻塞 openspec init，导致只剩 3 个命令）
remove_legacy_commands() {
  local target="$1"
  local harness_dir="$2"
  local rel path

  for rel in opsx-new.md opsx-apply.md opsx-verify.md; do
    path="$target/$harness_dir/commands/$rel"
    [ -f "$path" ] || continue
    if in_list "$harness_dir/commands/$rel" "$MODIFIED"; then
      warn "保留未提交修改，不清理旧版命令：$harness_dir/commands/$rel"
      continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      info "would remove legacy $harness_dir/commands/$rel"
      continue
    fi
    rm -f "$path"
    info "清理旧版随包命令：$harness_dir/commands/$rel"
  done
}

init_harness_commands() {
  local target="$1"
  local harness_dir="$2"
  local tool="$3"
  local cmd_dir="$target/$harness_dir/commands"
  local count=0

  if [ -d "$cmd_dir" ]; then
    count="$(find "$cmd_dir" -type f -name '*.md' | wc -l | tr -d ' ')"
  fi
  if [ "$count" -gt 0 ]; then
    # qoder 的命令集在 commands/opsx/ 子目录，不能用扁平文件名判断完整性
    if [ "$tool" = "qoder" ] || harness_command_set_complete "$cmd_dir"; then
      info "$harness_dir/commands/ 已有 $count 个命令文件 ... OK"
      return 0
    fi
    warn "$harness_dir/commands/ 仅 $count 个命令且命令集不完整，按旧版残留处理"
    remove_legacy_commands "$target" "$harness_dir"
    if [ "$DRY_RUN" != 1 ]; then
      count="$(find "$cmd_dir" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
    fi
    if [ "$count" -gt 0 ]; then
      info "$harness_dir/commands/ 保留 $count 个既有命令，仅补齐 openspec 标准命令"
    fi
  fi

  if [ "$NO_INIT" = 1 ]; then
    warn "$harness_dir/commands/ 命令集不完整且指定了 --no-init：技能将\"存在但永不加载\"，需手动 openspec init 后重跑"
    return 0
  fi

  if ! command -v openspec >/dev/null 2>&1; then
    warn "$harness_dir/commands/ 命令集不完整且未检测到 openspec CLI：技能将\"存在但永不加载\"。请先安装 OpenSpec CLI 并执行 openspec init --tools $tool 后重跑本脚本"
    return 0
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "would run: openspec init --tools $tool --no-animation"
    return 0
  fi

  local out
  if ! out="$(cd "$target" && openspec init --tools "$tool" --no-animation 2>&1)"; then
    warn "openspec init 失败：$(printf '%s' "$out" | tail -n 3)"
    return 0
  fi

  count="$(find "$cmd_dir" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  info "openspec init 生成 $count 个 $harness_dir/commands 命令（config.yaml 已存在，未被 init 覆盖）"
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
    WILL_WRITE="$WILL_WRITEopenspec/schemas/superspec/$rel"$'\n'
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
  fi
  if [ "$USE_TRAE" = 1 ]; then
    for rel in $TRAE_FILES; do
      WILL_WRITE="$WILL_WRITE.trae/${rel#trae/}"$'\n'
    done
  fi
  if [ "$USE_CURSOR" = 1 ]; then
    for rel in $CURSOR_FILES; do
      WILL_WRITE="$WILL_WRITE.cursor/${rel#cursor/}"$'\n'
    done
  fi
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

  files_json="$(printf '%s' "$WRITTEN" | grep -v '(+1 line)' | grep -v '^$' | sed 's/.*/    "&",/' | sed '$ s/,$//')"

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
  local rel dst_rel file frel kw cmd_count

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
    for kw in ui_contract Token 四态 无障碍 防呆; do
      grep -q "$kw" "$target/$harness_dir/skills/onepress-discipline/SKILL.md" || bad "$harness_dir/skills/onepress-discipline/SKILL.md 缺少铁律关键词：$kw"
    done
  fi

  if [ -d "$target/$harness_dir/commands" ]; then
    cmd_count="$(find "$target/$harness_dir/commands" -type f -name '*.md' | wc -l | tr -d ' ')"
    [ "$cmd_count" -gt 0 ] || bad "$harness_dir/commands/ 为空：/opsx:* 命令不可用（技能存在但无挂载点）"
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      frel="${file#"$target"/}"
      if in_list "$frel" "$MOUNT_SKIPPED"; then
        skip "$frel（无 frontmatter，挂载跳过，不计入失败）"
        continue
      fi
      grep -q 'onepress-discipline' "$file" || bad "未挂载技能引用：$frel"
    done < <(find "$target/$harness_dir/commands" -type f -name '*.md')
  fi
}

run_acceptance() {
  local pack="$1"
  local target="$2"
  local version="$3"

  step '④ 验收自检'

  local count=0
  if [ -d "$target/openspec/schemas/superspec" ]; then
    count="$(find "$target/openspec/schemas/superspec" -type f | wc -l | tr -d ' ')"
  fi
  if [ "$count" = "10" ]; then
    info 'openspec/schemas/superspec 共 10 文件 ... OK'
  else
    bad "openspec/schemas/superspec 文件数应为 10，实际 $count"
  fi

  if [ -f "$target/openspec/schemas/superspec/schema.yaml" ]; then
    local fb_count
    fb_count="$(grep -c 'SKILL FALLBACK' "$target/openspec/schemas/superspec/schema.yaml" 2>/dev/null || true)"
    if [ "${fb_count:-0}" -ge 4 ]; then
      info "schema.yaml 技能兜底：$fb_count 处 SKILL FALLBACK ... OK"
    else
      bad "schema.yaml 只有 ${fb_count:-0} 处 SKILL FALLBACK（brainstorm/plan/apply/finalize 应各 1 处）"
    fi
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

  if [ "$USE_QODER" = 1 ]; then
    accept_skill_harness "$pack" "$target" .qoder qoder "$QODER_FILES"
  fi

  if [ "$USE_TRAE" = 1 ]; then
    accept_skill_harness "$pack" "$target" .trae trae "$TRAE_FILES"
  fi

  if [ "$USE_CURSOR" = 1 ]; then
    accept_skill_harness "$pack" "$target" .cursor cursor "$CURSOR_FILES"
  fi

  if [ -f "$target/openspec/config.yaml" ]; then
    if tr -d '\r' < "$target/openspec/config.yaml" | grep -qE '^schema:[[:space:]]*superspec[[:space:]]*$'; then
      info 'openspec/config.yaml schema=superspec ... OK'
    else
      bad 'openspec/config.yaml 的 schema 不是 superspec（九工件序列不可用）'
    fi
  else
    bad 'openspec/config.yaml 缺失（安装器应已创建）'
  fi

  if [ -f "$target/onePress.lock" ]; then
    local lock_version
    lock_version="$(lock_value "$target/onePress.lock" version)"
    [ "$lock_version" = "$version" ] || bad "lock version 应为 $version，实际 $lock_version"
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

init_ui_components "$TARGET_ROOT"

confirm_openspec_schema "$TARGET_ROOT"

if [ "$USE_QODER" = 1 ]; then
  init_harness_commands "$TARGET_ROOT" .qoder qoder
  mount_skill_reference "$TARGET_ROOT" .qoder
fi

if [ "$USE_TRAE" = 1 ]; then
  init_harness_commands "$TARGET_ROOT" .trae trae
  mount_skill_reference "$TARGET_ROOT" .trae
fi

if [ "$USE_CURSOR" = 1 ]; then
  init_harness_commands "$TARGET_ROOT" .cursor cursor
  mount_skill_reference "$TARGET_ROOT" .cursor
fi

step '③ 写入 onePress.lock'
write_lock "$TARGET_ROOT" "$VERSION"

if [ "$DRY_RUN" != 1 ]; then
  run_acceptance "$PACK_ROOT" "$TARGET_ROOT" "$VERSION"
fi

step '⑤ 报告'
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