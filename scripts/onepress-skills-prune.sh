#!/usr/bin/env bash
# onepress-skills-prune.sh — 安装前清理 onePress 自有技能与退役路径。
#
# 判定（只删可证明属于 onePress 的资产）：
#   1. SKILL.md frontmatter 含 metadata.onepress-version 且版本 < 当前版本 → 删
#   2. 含标记但版本 >= 当前版本 → 保留
#   3. 无标记 → 保留并告警（绝不误伤用户技能）
#   4. RETIRED_PATHS 枚举项 → 命中即删
# 扫描面：<root>/.agents/skills（共享）+ 每个启用 harness 的 <root>/.<harness>/skills。
#
# 用法：
#   onepress-skills-prune.sh --root <repo> --version <ver> [--harness qoder,trae]
#                            [--dry-run]
# 退出码：0 成功；1 删除失败；2 参数错误。
set -u

ROOT=""
VERSION=""
HARNESS=""
DRY_RUN=0
VERCMP_ARGS=""

RETIRED_DIRS="commands/opsx"
RETIRED_FILES="commands/opsx-new.md commands/opsx-apply.md commands/opsx-verify.md commands/opsx-review.md commands/one.md commands/o.md"

PASS_HARNESSES="qoder opencode trae cursor"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

die_args() {
  printf 'onepress-skills-prune: %s\n' "$1" >&2
  exit 2
}

# ---------------------------------------------------------------- version

vercmp() {
  awk -v a="$1" -v b="$2" '
    function rank(p,   t, n) {
      n = split(p, t, ".")
      if (t[1] == "alpha") return 1
      if (t[1] == "beta") return 2
      if (t[1] == "rc") return 3
      return 4
    }
    function tail(p,   t, n, i, x, y) {
      n = split(p, t, ".")
      for (i = 2; i <= n; i++) { printf "%d ", t[i] + 0 }
      return n
    }
    BEGIN {
      sub(/^v/, "", a); sub(/^v/, "", b)
      na = split(a, ap, "-"); nb = split(b, bp, "-")
      ca = ap[1]; cb = bp[1]
      prea = (na > 1) ? substr(a, length(ca) + 2) : ""
      preb = (nb > 1) ? substr(b, length(cb) + 2) : ""
      n = split(ca, c1, "."); m = split(cb, c2, ".")
      for (i = 1; i <= 3; i++) {
        x = (i <= n) ? c1[i] + 0 : 0
        y = (i <= m) ? c2[i] + 0 : 0
        if (x > y) { print 1; exit }
        if (x < y) { print -1; exit }
      }
      if (prea == "" && preb == "") { print 0; exit }
      if (prea == "") { print 1; exit }
      if (preb == "") { print -1; exit }
      ra = rank(prea); rb = rank(preb)
      if (ra != rb) { print (ra > rb) ? 1 : -1; exit }
      ta = tail(prea); tb = tail(preb)
      va = split(prea, pa, "."); vb = split(preb, pb, ".")
      for (i = 2; i <= 8; i++) {
        x = (i <= va) ? pa[i] + 0 : 0
        y = (i <= vb) ? pb[i] + 0 : 0
        if (x > y) { print 1; exit }
        if (x < y) { print -1; exit }
      }
      print 0
    }'
}

# ---------------------------------------------------------------- helpers

marker_of() { # skill.md -> version or empty
  sed -n 's/^[[:space:]]*onepress-version:[[:space:]]*//p' "$1" 2>/dev/null \
    | head -n 1 | tr -d "\"' \r"
}

harness_enabled() {
  case " $HARNESS " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

report_remove() { # rel
  if [ "$DRY_RUN" = 1 ]; then
    printf 'would remove retired path: %s\n' "$1"
  else
    printf 'removed retired path: %s\n' "$1"
  fi
}

prune_retired_in() { # harness dir rel-prefix e.g. ".qoder"
  local base="$ROOT/$1"
  [ -d "$base" ] || return 0
  local rel
  for rel in $RETIRED_DIRS; do
    if [ -d "$base/$rel" ]; then
      report_remove "$1/$rel"
      [ "$DRY_RUN" = 1 ] || rm -rf "$base/$rel"
    fi
  done
  for rel in $RETIRED_FILES; do
    if [ -f "$base/$rel" ]; then
      report_remove "$1/$rel"
      [ "$DRY_RUN" = 1 ] || rm -f "$base/$rel"
    fi
  done
}

prune_skills_in() { # rel-prefix e.g. ".qoder" (skills dir inside)
  local dir="$ROOT/$1/skills"
  [ -d "$dir" ] || return 0
  local entry name skill old cmp
  for entry in "$dir"/*; do
    [ -d "$entry" ] || continue
    skill="$entry/SKILL.md"
    [ -f "$skill" ] || continue
    name="$(basename "$entry")"
    old="$(marker_of "$skill")"
    if [ -z "$old" ]; then
      printf 'keep unmarked skill: %s/skills/%s\n' "$1" "$name"
      continue
    fi
    cmp="$(vercmp "$old" "$VERSION")"
    if [ "$cmp" = "-1" ]; then
      if [ "$DRY_RUN" = 1 ]; then
        printf 'would prune skill: %s/skills/%s (%s -> %s)\n' "$1" "$name" "$old" "$VERSION"
      else
        printf 'prune skill: %s/skills/%s (%s -> %s)\n' "$1" "$name" "$old" "$VERSION"
        rm -rf "$entry" || exit 1
      fi
    else
      printf 'keep skill: %s/skills/%s (%s)\n' "$1" "$name" "$old"
    fi
  done
}

# ---------------------------------------------------------------- args

[ $# -gt 0 ] || { usage >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --harness) HARNESS="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --vercmp) VERCMP_ARGS="$2 $3"; shift 3 ;;
    -h|--help) usage; exit 0 ;;
    *) die_args "未知参数：$1" ;;
  esac
done

if [ -n "$VERCMP_ARGS" ]; then
  # shellcheck disable=SC2086
  set -- $VERCMP_ARGS
  vercmp "$1" "$2"
  exit 0
fi

[ -n "$ROOT" ] || die_args '缺少 --root'
[ -n "$VERSION" ] || die_args '缺少 --version'
[ -d "$ROOT" ] || die_args "--root 不是目录：$ROOT"

HARNESS="$(printf '%s' "$HARNESS" | tr ',' ' ')"
for h in $HARNESS; do
  case " $PASS_HARNESSES " in
    *" $h "*) ;;
    *) die_args "无效 harness：$h" ;;
  esac
done

# ---------------------------------------------------------------- run

prune_skills_in ".agents"
for h in $HARNESS; do
  harness_enabled "$h" || continue
  prune_skills_in ".$h"
  prune_retired_in ".$h"
done

exit 0