#!/usr/bin/env bash
# onePress plan.md structural lint (no runtime dependencies).
#
# Usage:
#   bash scripts/onepress-plan-lint.sh --change openspec/changes/<name>
#   bash scripts/onepress-plan-lint.sh <path/to/plan.md> [--strict] [--only-plan]
#
# Exit 0 when there is no FAIL. With --strict, WARN also fails the run.
# --only-plan skips the sibling design.md / tasks.md contract checks (use it
# for changes created before the V2.2 contract).
# The lint is intentionally structural: it checks that the plan carries the
# onePress contract (Spec, Global Constraints, Review Focus, File Structure,
# per-task Files/Interfaces, verification, commit, and Self-Review), not
# that the plan's prose is good.
set -uo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/onepress-plan-lint.sh --change openspec/changes/<name>
  bash scripts/onepress-plan-lint.sh <path/to/plan.md> [--strict] [--only-plan]

Checks the onePress plan.md contract. Exit 0 when there is no FAIL;
--strict also fails on WARN. --only-plan skips sibling design.md /
tasks.md checks.
EOF
}

CHANGE=""
PLAN=""
STRICT=0
ONLY_PLAN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --change)
      [ $# -ge 2 ] && [ -n "$2" ] || { printf 'missing value for --change\n' >&2; exit 2; }
      CHANGE="$2"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --only-plan)
      ONLY_PLAN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      PLAN="$1"
      shift
      ;;
  esac
done

# 遥测埋点：任何退出路径都写 1 条事件；失败静默，不改变退出码。
_telemetry_on_exit() {
  local rc=$?
  local status=pass
  [ "$rc" -eq 0 ] || status=fail
  bash "${BASH_SOURCE[0]%/*}/onepress-telemetry.sh" emit step.finish \
    --status "$status" --step plan-lint \
    --duration-ms "$((SECONDS * 1000))" \
    --payload "{\"passed\":${PASS:-0},\"failed\":${FAIL:-0}}" >/dev/null 2>&1 || true
}
trap _telemetry_on_exit EXIT

if [ -n "$CHANGE" ]; then
  PLAN="${CHANGE%/}/plan.md"
fi
if [ -z "$PLAN" ]; then
  usage >&2
  exit 2
fi
if [ -d "$PLAN" ]; then
  PLAN="${PLAN%/}/plan.md"
fi
if [ ! -f "$PLAN" ]; then
  printf '[FAIL] plan.md not found: %s\n' "$PLAN" >&2
  exit 1
fi

TEXT="$(tr -d '\r' < "$PLAN")"
PLAN_DIR="$(dirname "$PLAN")"
if [ -z "${TEXT//[[:space:]]/}" ]; then
  printf '[FAIL] plan.md is empty: %s\n' "$PLAN" >&2
  exit 1
fi

PASS=0
FAIL=0
WARN=0

ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  [FAIL] %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
warn() { printf '  [WARN] %s\n' "$1" >&2; WARN=$((WARN + 1)); }

field_value() {
  printf '%s\n' "$TEXT" | sed -n "s/^\*\*$1:\*\*[[:space:]]*//p" | head -n 1
}

printf 'plan-lint: %s\n' "$PLAN"

echo '== plan header =='
for field in Goal Architecture 'Tech Stack' Spec; do
  value="$(field_value "$field")"
  case "$value" in
    ''|'<!--'*|*'<change>'*)
      bad "**$field:** is missing or still a placeholder"
      ;;
    *)
      ok "**$field:** present"
      ;;
  esac
done

echo '== required sections =='
for section in 'Global Constraints' 'Review Focus' 'Evidence Map' 'File Structure' 'Self-Review'; do
  if printf '%s\n' "$TEXT" | grep -qE "^##[[:space:]]+${section}[[:space:]]*$"; then
    ok "section: ## $section"
  else
    bad "missing section: ## $section"
  fi
done

echo '== tasks =='
TASK_COUNT="$(printf '%s\n' "$TEXT" | grep -cE '^#{2,3}[[:space:]]+Task[[:space:]]+[0-9]+:' || true)"
if [ "${TASK_COUNT:-0}" -ge 1 ]; then
  ok "task headings: $TASK_COUNT"
else
  bad "no task heading (expected '## Task 1:' or '### Task 1:')"
fi

TASK_REPORT="$(printf '%s\n' "$TEXT" | awk '
  function emit() {
    if (in_task) {
      printf "%s|%d|%d|%d|%d|%d\n", name, has_files, has_interfaces, has_step, has_run, has_commit
    }
  }
  /^#{2,3}[[:space:]]+Task[[:space:]]+[0-9]+:/ {
    emit()
    in_task = 1
    name = $0
    has_files = 0
    has_interfaces = 0
    has_step = 0
    has_run = 0
    has_commit = 0
    next
  }
  in_task {
    if ($0 ~ /^\*\*Files:\*\*/) has_files = 1
    if ($0 ~ /^\*\*Interfaces:\*\*/) has_interfaces = 1
    if ($0 ~ /^- \[[ xX]\]/) has_step = 1
    if ($0 ~ /(Run:|Expected:)/) has_run = 1
    if ($0 ~ /(Commit|git commit)/) has_commit = 1
  }
  END { emit() }
')"

if [ -n "$TASK_REPORT" ]; then
  while IFS='|' read -r name files interfaces steps run commit; do
    [ -n "$name" ] || continue
    [ "$files" = 1 ] || bad "$name: missing **Files:**"
    [ "$interfaces" = 1 ] || warn "$name: missing **Interfaces:** (write 'None' if N/A)"
    [ "$steps" = 1 ] || bad "$name: no checkbox steps"
    [ "$run" = 1 ] || bad "$name: no Run:/Expected: verification"
    [ "$commit" = 1 ] || bad "$name: no commit point"
  done <<< "$TASK_REPORT"
fi

echo '== placeholders =='
if printf '%s\n' "$TEXT" | grep -qE '<!--[[:space:]]*(micro-step|Component Name|files|message|exact command|exact failure|test name|responsibility|exact signatures|exact names|exact signature)|\[Feature Name\]|exact/path/to/'; then
  bad 'template placeholders left (Component Name / exact/path / exact command / files / message / responsibility / signatures / [Feature Name])'
else
  ok 'no template placeholders'
fi
if printf '%s\n' "$TEXT" | grep -qE 'TBD|TODO|handle edge cases|add appropriate validation|write tests for the above'; then
  warn 'placeholder phrases found (TBD / TODO / handle edge cases / ...)'
else
  ok 'no placeholder phrases'
fi

echo '== boundary matrix =='
SEMANTIC_RE='归一化|抽取|单位换算|舍入|parser|normalize|extract'
REVIEW_FOCUS="$(printf '%s\n' "$TEXT" | awk '
  /^##[[:space:]]+Review Focus[[:space:]]*$/ { f = 1; next }
  f && /^##[[:space:]]/ { exit }
  f { print }')"
TASK_LINES=""
if [ -f "$PLAN_DIR/tasks.md" ]; then
  TASK_LINES="$(grep -E '^- \[[ xX]\] [0-9]+\.[0-9]+ ' "$PLAN_DIR/tasks.md" 2>/dev/null || true)"
fi
SEMANTIC_TEXT="$REVIEW_FOCUS
$TASK_LINES"
MATRIX="$(printf '%s\n' "$TEXT" | awk '
  /^##[[:space:]]+Boundary Matrix[[:space:]]*$/ { f = 1; next }
  f && /^##[[:space:]]/ { exit }
  f { print }')"
if printf '%s\n' "$SEMANTIC_TEXT" | grep -qE "$SEMANTIC_RE"; then
  if [ -z "$MATRIX" ]; then
    bad 'semantic task detected (归一化/抽取/单位换算/舍入/parser/normalize/extract) but ## Boundary Matrix is missing'
  else
    MATRIX_STATS="$(printf '%s\n' "$MATRIX" | awk -F'|' '
      /^\|/ {
        if ($0 ~ /^\|[[:space:]]*:?-{3,}/) next
        cat = $2
        gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", cat)
        if (cat == "" || tolower(cat) ~ /^(类别|分类|category)$/) next
        n++; cnt[cat]++
        if ($0 ~ /反例|拒绝|reject/) rev[cat] = 1
      }
      END {
        cats = 0; badcat = 0
        for (c in cnt) { cats++; if (cnt[c] < 3 || !rev[c]) badcat++ }
        printf "%d\t%d\t%d\n", n + 0, cats + 0, badcat + 0
      }')"
    IFS=$'\t' read -r m_total m_cats m_bad <<< "$MATRIX_STATS"
    if [ "${m_total:-0}" -ge 20 ] && [ "${m_cats:-0}" -ge 6 ] && [ "${m_bad:-1}" -eq 0 ]; then
      ok "boundary matrix: $m_total rows, $m_cats categories"
    else
      bad "boundary matrix too thin: rows=$m_total (need >=20), categories=$m_cats (need >=6), failing-categories=$m_bad (need 0; each category needs >=3 rows and one 反例)"
    fi
    MISSING_CATS=""
    for pat in '抽取|extraction|extract' '单位|unit' '舍入|rounding' '区间|range' '名称|name' '日期|date'; do
      printf '%s\n' "$MATRIX" | grep -qiE "^\|[[:space:]]*($pat)[[:space:]]*\|" || MISSING_CATS="$MISSING_CATS ${pat%%|*}"
    done
    if [ -z "$MISSING_CATS" ]; then
      ok 'boundary matrix covers extraction/unit/rounding/range/name/date'
    else
      bad "boundary matrix missing required categories:$MISSING_CATS"
    fi
  fi
else
  printf '  [SKIP] no semantic task detected\n'
fi

echo '== scale threshold =='
FS_COUNT="$(printf '%s\n' "$TEXT" | awk '
  /^##[[:space:]]+File Structure[[:space:]]*$/ { f = 1; next }
  f && /^##[[:space:]]/ { exit }
  f && /^- `/ { n++ }
  END { print n + 0 }')"
TASK_TOTAL=0
if [ -f "$PLAN_DIR/tasks.md" ]; then
  TASK_TOTAL="$(grep -cE '^- \[[ xX]\] [0-9]+\.[0-9]+ ' "$PLAN_DIR/tasks.md" 2>/dev/null || true)"
fi
if [ "${FS_COUNT:-0}" -gt 30 ] || [ "${TASK_TOTAL:-0}" -gt 40 ]; then
  if printf '%s\n' "$TEXT" | grep -qE '^\*\*Subsystems:\*\*'; then
    SUBS="$(printf '%s\n' "$TEXT" | sed -n 's/^\*\*Subsystems:\*\*[[:space:]]*//p' | head -1)"
    SUBS_N="$(printf '%s' "$SUBS" | sed 's/、/\n/g; s/，/\n/g; s/,/\n/g' | grep -c '[^[:space:]]' || true)"
    if [ "${SUBS_N:-0}" -ge 2 ]; then
      ok "scale: files=$FS_COUNT tasks=$TASK_TOTAL, $SUBS_N subsystems declared"
    else
      bad "scale: files=$FS_COUNT tasks=$TASK_TOTAL needs **Subsystems:** with >=2 names (got $SUBS_N)"
    fi
  else
    bad "scale: files=$FS_COUNT (>30) or tasks=$TASK_TOTAL (>40) requires a **Subsystems:** declaration"
  fi
else
  ok "scale: files=$FS_COUNT tasks=$TASK_TOTAL within thresholds"
fi

echo '== self-review =='
for kw in 'Spec coverage' 'Step scan' 'Type consistency' 'Review Focus' 'Proportion'; do
  if printf '%s\n' "$TEXT" | grep -qi "$kw"; then
    ok "self-review: $kw"
  else
    warn "self-review missing: $kw"
  fi
done

SELF_BLOCK="$(printf '%s\n' "$TEXT" | awk '
  /^##[[:space:]]+Self-Review[[:space:]]*$/ { in_self = 1; next }
  /^##[[:space:]]/ { if (in_self) exit }
  in_self { print }
')"
if printf '%s\n' "$TEXT" | grep -qE '^##[[:space:]]+Self-Review[[:space:]]*$'; then
  if printf '%s\n' "$SELF_BLOCK" | grep -qE '^- \[ \]'; then
    warn 'self-review has unchecked items'
  else
    ok 'self-review items checked'
  fi
fi

echo '== design contract (sibling design.md) =='
if [ "$ONLY_PLAN" = 1 ]; then
  printf '  [SKIP] --only-plan (sibling design.md checks disabled)\n'
elif [ -f "$PLAN_DIR/design.md" ]; then
  DESIGN_TEXT="$(tr -d '\r' < "$PLAN_DIR/design.md")"
  if printf '%s\n' "$DESIGN_TEXT" | grep -qE '^##[[:space:]]+Goals[[:space:]]*/[[:space:]]*Non-Goals[[:space:]]*$'; then
    ok 'design: ## Goals / Non-Goals present'
  else
    bad 'design: missing ## Goals / Non-Goals'
  fi
  NG_COUNT="$(printf '%s\n' "$DESIGN_TEXT" | awk '
    /^\*\*Non-Goals:\*\*/ { in_ng = 1; next }
    in_ng && /^##[[:space:]]/ { exit }
    in_ng && /^[[:space:]]*([0-9]+\.|-)[[:space:]]+/ { n++ }
    END { print n + 0 }
  ')"
  if [ "${NG_COUNT:-0}" -ge 3 ] && [ "${NG_COUNT:-0}" -le 5 ]; then
    ok "design: $NG_COUNT Non-Goals (3-5 required)"
  else
    bad "design: $NG_COUNT Non-Goals (3-5 required)"
  fi
  DECISIONS="$(printf '%s\n' "$DESIGN_TEXT" | awk '
    /^##[[:space:]]+Decisions[[:space:]]*$/ { f = 1; next }
    f && /^##[[:space:]]/ { exit }
    f { print }
  ')"
  if printf '%s\n' "$DECISIONS" | grep -qiE 'ADR|Alternatives[[:space:]]+considered'; then
    ok 'design: ADR / alternatives present'
  else
    bad 'design: missing ADR or Alternatives considered'
  fi
  if printf '%s\n' "$DESIGN_TEXT" | grep -qE '^##[[:space:]]+Risks([[:space:]]*/[[:space:]]*Trade-offs)?[[:space:]]*$'; then
    ok 'design: Risks / Trade-offs present'
  else
    bad 'design: missing Risks / Trade-offs'
  fi
else
  printf '  [SKIP] no sibling design.md\n'
fi

echo '== tasks contract (sibling tasks.md) =='
if [ "$ONLY_PLAN" = 1 ]; then
  printf '  [SKIP] --only-plan (sibling tasks.md checks disabled)\n'
elif [ -f "$PLAN_DIR/tasks.md" ]; then
  TASK_REPORT="$(awk '
    function emit() {
      if (in_task) {
        rgb = (rgb_red && rgb_green && rgb_ref) ? 1 : 0
        conflict = (logic && has_na && !doc_config) ? 1 : 0
        printf "%s\t%d\t%d\t%d\t%d\t%d\n", name, has_path, has_verify, rgb, has_na, conflict
      }
    }
    /^- \[[ xX]\] [0-9]+\.[0-9]+ / {
      emit()
      in_task = 1
      name = $0
      has_path = ($0 ~ /`[^`]+`/) ? 1 : 0
      has_verify = ($0 ~ /verify:/) ? 1 : 0
      desc = $0
      sub(/[[:space:]]*—[[:space:]]*verify:.*$/, "", desc)
      lower = tolower(desc)
      logic = (lower ~ /实现|implement|logic|refactor|修复|add|update|migrate|support|新增|修正/) ? 1 : 0
      doc_config = (lower ~ /docs|readme|注释|说明|配置|模板|清单|报告|索引|同步|归档|schema|spec\.md|plan\.md|验收|安装器/) ? 1 : 0
      rgb_red = 0
      rgb_green = 0
      rgb_ref = 0
      has_na = 0
      next
    }
    in_task {
      if ($0 ~ /^[[:space:]]+- (\[[ xX]\] )?RED:/) rgb_red = 1
      if ($0 ~ /^[[:space:]]+- (\[[ xX]\] )?GREEN:/) rgb_green = 1
      if ($0 ~ /^[[:space:]]+- (\[[ xX]\] )?REFACTOR:/) rgb_ref = 1
      if ($0 ~ /TDD:[[:space:]]*N\/A/) has_na = 1
    }
    END { emit() }
  ' "$PLAN_DIR/tasks.md")"

  if [ -n "$TASK_REPORT" ]; then
    while IFS=$'\t' read -r tname tpath tverify trgb tna tconflict; do
      [ -n "$tname" ] || continue
      [ "$tpath" = 1 ] || bad "tasks: ${tname%% —*}: missing backticked file path"
      [ "$tverify" = 1 ] || bad "tasks: ${tname%% —*}: missing verify: command"
      if [ "$trgb" = 0 ] && [ "$tna" = 0 ]; then
        bad "tasks: ${tname%% —*}: needs RED/GREEN/REFACTOR or TDD: N/A"
      fi
      if [ "$tconflict" = 1 ]; then
        bad "tasks: ${tname%% —*}: logic task may not use TDD: N/A"
      fi
    done <<< "$TASK_REPORT"
    ok "tasks: $(printf '%s\n' "$TASK_REPORT" | wc -l | tr -d ' ') top-level tasks parsed"
  else
    bad "tasks: no top-level checkbox ('- [ ] X.Y ...')"
  fi
else
  printf '  [SKIP] no sibling tasks.md\n'
fi

echo '== totals / execution =='
TOTALS="$(printf '%s\n' "$TEXT" | sed -n 's/^\*\*Totals:\*\*[[:space:]]*//p' | head -n 1)"
case "$TOTALS" in
  ''|'<!--'*)
    warn 'missing **Totals:** (task count + estimated commits)'
    ;;
  *)
    ok '**Totals:** present'
    ;;
esac

if printf '%s\n' "$TEXT" | grep -qiE 'Execution:.*OpenSpec apply'; then
  ok 'Execution: OpenSpec apply phase'
else
  warn "missing 'Execution: OpenSpec apply phase' (do not pause for subagent/native choice)"
fi

printf '\nRESULT: %d passed, %d warnings, %d failed\n' "$PASS" "$WARN" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
if [ "$STRICT" = 1 ] && [ "$WARN" -gt 0 ]; then
  exit 1
fi
exit 0
