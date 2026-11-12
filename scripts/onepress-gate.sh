#!/usr/bin/env bash
# onePress 八项门禁 —— 在任意目标仓库根目录执行
#
#   bash scripts/onepress-gate.sh --root . \
#        --change openspec/changes/<change> \
#        [--files "src/a.tsx src/b.tsx"] [--base HEAD~1] [--quiet]
#
# 自动实现门禁 2 / 4 / 5 / 6 / 7；门禁 0 依赖 --change 或 --ui-spec；
# 门禁 1 / 3 / 8 只输出 MANUAL 提示，不产生 PASS。
# 退出码：存在 FAIL → 1；否则 0。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGE_DIR=""
UI_SPEC=""
FILES_ARG=""
BASE=""
QUIET=0

FAIL_COUNT=0
NOTE_COUNT=0
declare -a FILE_LIST=()

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)    ROOT="${2:-}"; shift 2 ;;
    --change)  CHANGE_DIR="${2:-}"; shift 2 ;;
    --ui-spec) UI_SPEC="${2:-}"; shift 2 ;;
    --files)   FILES_ARG="${2:-}"; shift 2 ;;
    --base)    BASE="${2:-}"; shift 2 ;;
    --quiet)   QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
done

[ -d "$ROOT" ] || { printf 'root not found: %s\n' "$ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

if [ -n "$CHANGE_DIR" ] && [ -z "$UI_SPEC" ]; then
  case "$CHANGE_DIR" in
    /*) UI_SPEC="$CHANGE_DIR/ui-spec.md" ;;
    *)  UI_SPEC="$ROOT/$CHANGE_DIR/ui-spec.md" ;;
  esac
fi
[ -n "$CHANGE_DIR" ] || { [ -n "$UI_SPEC" ] && CHANGE_DIR="$(dirname "$UI_SPEC")"; }

hr() { [ "$QUIET" = 1 ] || printf '\n== %s\n' "$1"; }
pass() { printf '  [PASS]   %s\n' "$1"; }
fail() { printf '  [FAIL]   %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
skip() { printf '  [SKIP]   %s\n' "$1"; }
manual() { printf '  [MANUAL] %s\n' "$1"; }
note() { NOTE_COUNT=$((NOTE_COUNT + 1)); [ "$QUIET" = 1 ] || printf '           %s\n' "$1"; }

# ---------- 文件集合 ----------

collect_files() {
  if [ -n "$FILES_ARG" ]; then
    # shellcheck disable=SC2206
    FILE_LIST=($FILES_ARG)
    return
  fi
  if [ -n "$BASE" ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    while IFS= read -r f; do
      [ -n "$f" ] && FILE_LIST+=("$ROOT/$f")
    done < <(git -C "$ROOT" diff --name-only "$BASE" -- '*.tsx' '*.vue' 2>/dev/null)
    return
  fi
  while IFS= read -r f; do
    FILE_LIST+=("$f")
  done < <(find "$ROOT" -type f \( -name '*.tsx' -o -name '*.vue' \) \
             -not -path '*/node_modules/*' -not -path '*/.next/*' \
             -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null)
}

existing_files() {
  local f
  for f in "${FILE_LIST[@]:-}"; do
    [ -n "$f" ] && [ -f "$f" ] && printf '%s\n' "$f"
  done
}

# ---------- 门禁 0：契约存在性 ----------

gate0() {
  hr '门禁 0：契约存在性（AUTO）'
  local proposal="" line="" ui=""
  if [ -n "$CHANGE_DIR" ] && [ -f "$CHANGE_DIR/proposal.md" ]; then
    proposal="$CHANGE_DIR/proposal.md"
  elif [ -n "$CHANGE_DIR" ] && [ -f "$ROOT/$CHANGE_DIR/proposal.md" ]; then
    proposal="$ROOT/$CHANGE_DIR/proposal.md"
  fi

  if [ -z "$proposal" ]; then
    skip '未提供 --change，无法定位 proposal.md'
    return
  fi

  line="$(grep -m1 -oE '\*\*UI Change\*\*:[[:space:]]*(yes|no)' "$proposal" 2>/dev/null | grep -oE '(yes|no)$')"
  if [ -z "$line" ]; then
    fail "$proposal 缺少 **UI Change**: yes|no 判定行"
    return
  fi
  note "$proposal → UI Change: $line"

  if [ "$line" = "no" ]; then
    pass '无 UI 变更，跳过门禁 1–8'
    return
  fi

  local miss=0
  [ -f "$UI_SPEC" ] || { fail "缺少契约：$UI_SPEC"; miss=1; }
  local sandbox
  sandbox="$(dirname "$UI_SPEC")/sandbox-preview.html"
  [ -f "$sandbox" ] || { fail "缺少沙箱：$sandbox"; miss=1; }
  [ "$miss" = 0 ] && pass 'ui-spec.md 与 sandbox-preview.html 均存在'
}

ui_change_is_no() {
  local proposal="" line=""
  if [ -n "$CHANGE_DIR" ] && [ -f "$CHANGE_DIR/proposal.md" ]; then
    proposal="$CHANGE_DIR/proposal.md"
  elif [ -n "$CHANGE_DIR" ] && [ -f "$ROOT/$CHANGE_DIR/proposal.md" ]; then
    proposal="$ROOT/$CHANGE_DIR/proposal.md"
  fi
  [ -n "$proposal" ] || return 1
  line="$(grep -m1 -oE '\*\*UI Change\*\*:[[:space:]]*(yes|no)' "$proposal" 2>/dev/null | grep -oE '(yes|no)$')"
  [ "$line" = "no" ]
}

# ---------- 门禁 2a：Token 正则 ----------

scan_rule() {
  local pattern="$1" label="$2" hits
  # shellcheck disable=SC2046
  hits="$(grep -nHE "$pattern" $(existing_files) 2>/dev/null | grep -vE '<svg|fill=|stroke=' || true)"
  if [ -n "$hits" ]; then
    fail "$label（命中：$(printf '%s\n' "$hits" | wc -l | tr -d ' ') 处）"
    printf '%s\n' "$hits" | head -20 | sed 's/^/           /'
  else
    pass "$label 0 命中"
  fi
}

gate2a() {
  hr '门禁 2a：Token 纯净度（AUTO，行级近似）'
  if [ "${#FILE_LIST[@]}" -eq 0 ]; then
    skip '无 .tsx/.vue 变更文件'
    return
  fi
  scan_rule 'style=\{\{' '内联样式'
  scan_rule '#[0-9a-fA-F]{3,8}([^0-9a-zA-Z]|$)|rgb\(|hsl\(' '硬编码色值'
  scan_rule '(p|m|w|h|gap|space|inset|top|left|right|bottom)-\[[0-9]+px\]' '任意像素间距'
}

# ---------- 门禁 2b：对比度 ----------

hex_to_rgb() {
  local h="$1"
  h="${h#\#}"
  case "${#h}" in
    3) printf '%d %d %d\n' "0x${h:0:1}${h:0:1}" "0x${h:1:1}${h:1:1}" "0x${h:2:1}${h:2:1}" ;;
    6) printf '%d %d %d\n' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}" ;;
    *) return 1 ;;
  esac
}

contrast_ratio() {
  awk -v a="$1" -v b="$2" '
    function lin(c) { c = c / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
    BEGIN {
      split(a, A, " "); split(b, B, " ")
      LA = lum(A[1], A[2], A[3]); LB = lum(B[1], B[2], B[3])
      if (LA < LB) { t = LA; LA = LB; LB = t }
      printf "%.2f", (LA + 0.05) / (LB + 0.05)
    }'
}

# 从 CSS 中按 ":root" / ".dark" 区块取变量值
css_var() {
  local file="$1" var="$2" mode="$3"
  awk -v V="--$var:" -v MODE="$mode" '
    /:root/ { cur = "light" }
    /\.dark/ { cur = "dark" }
    index($0, V) > 0 && cur == MODE {
      if (match($0, /#[0-9a-fA-F]{3,8}/)) { print substr($0, RSTART, RLENGTH); exit }
    }' "$file"
}

gate2b() {
  hr '门禁 2b：Light/Dark 对比度（AUTO，WCAG 相对亮度）'
  local css="" f
  while IFS= read -r f; do
    if grep -qE '^\s*(:root|\.dark)' "$f" 2>/dev/null; then css="$f"; break; fi
  done < <(find "$ROOT" -type f -name '*.css' -not -path '*/node_modules/*' -not -path '*/.next/*' 2>/dev/null | head -50)

  if [ -z "$css" ]; then
    skip '未找到含 :root/.dark 的 CSS 文件'
    return
  fi
  note "变量来源：${css#"$ROOT"/}"

  local pair mode bg fg rb rf ratio
  for pair in 'background:foreground' 'card:card-foreground' 'muted:muted-foreground'; do
    for mode in light dark; do
      bg="$(css_var "$css" "${pair%%:*}" "$mode")"
      fg="$(css_var "$css" "${pair##*:}" "$mode")"
      if [ -z "$bg" ] || [ -z "$fg" ]; then
        skip "$pair ($mode) 变量缺失"
        continue
      fi
      rb="$(hex_to_rgb "$bg")" || { skip "$pair ($mode) 非 hex：$bg"; continue; }
      rf="$(hex_to_rgb "$fg")" || { skip "$pair ($mode) 非 hex：$fg"; continue; }
      ratio="$(contrast_ratio "$rb" "$rf")"
      if awk -v r="$ratio" 'BEGIN { exit !(r >= 4.5) }'; then
        pass "$pair ($mode) $bg / $fg → $ratio:1"
      else
        fail "$pair ($mode) $bg / $fg → $ratio:1（< 4.5:1）"
      fi
    done
  done
}

# ---------- 门禁 4：纯逻辑状态机单测 ----------

gate4() {
  hr '门禁 4：状态机单测（AUTO）'
  if [ ! -f "$ROOT/package.json" ]; then
    skip '无 package.json'
    return
  fi
  local rtl
  rtl="$(grep -rlE "from ['\"]@testing-library/react|render\(" \
           $(existing_files) 2>/dev/null || true)"
  if [ -n "$rtl" ]; then
    fail "检测到 RTL / DOM 渲染测试（门禁 4 禁止）：$(printf '%s' "$rtl" | tr '\n' ' ')"
  fi
  if ! command -v npx >/dev/null 2>&1; then
    skip 'npx 不可用'
    return
  fi
  local out
  if out="$(cd "$ROOT" && npx --no-install vitest run --reporter=dot 2>&1)"; then
    pass 'vitest run 通过'
  else
    if printf '%s' "$out" | grep -qiE 'could not|not found|missing script|command not found'; then
      skip 'vitest 不可用'
    else
      fail 'vitest run 失败'
      printf '%s\n' "$out" | tail -15 | sed 's/^/           /'
    fi
  fi
}

# ---------- 门禁 5：A11y ----------

gate5() {
  hr '门禁 5：A11y CRITICAL（AUTO，启发式）'
  if [ "${#FILE_LIST[@]}" -eq 0 ]; then skip '无变更文件'; return; fi
  local f problems=0

  for f in $(existing_files); do
    if grep -q 'outline-none' "$f" && ! grep -q 'focus-visible:ring' "$f"; then
      fail "$f：用了 outline-none 但没有 focus-visible:ring"; problems=1
    fi
    if grep -q 'size="icon"' "$f" && ! grep -q 'aria-label' "$f"; then
      fail "$f：存在纯图标按钮但全文件无 aria-label"; problems=1
    fi
    if grep -q 'aria-invalid' "$f" && ! grep -q 'aria-describedby' "$f"; then
      fail "$f：表单错误未用 aria-describedby 关联"; problems=1
    fi
    if grep -q '<svg' "$f" && ! grep -q 'aria-hidden' "$f"; then
      fail "$f：存在原生 <svg> 但无 aria-hidden"; problems=1
    fi
  done

  [ "$problems" = 0 ] && pass '焦点环 / 图标语义 / 表单关联 / 装饰图标均合规'
}

# ---------- 门禁 6：热区与微动效 ----------

gate6() {
  hr '门禁 6：热区与微交互（AUTO，启发式）'
  if [ "${#FILE_LIST[@]}" -eq 0 ]; then skip '无变更文件'; return; fi
  local f problems=0 durations bad

  for f in $(existing_files); do
    if grep -qE '<Button|onClick=' "$f"; then
      if ! grep -qE 'cursor-pointer|size-11|h-11|min-h-11' "$f"; then
        fail "$f：交互元素缺少 cursor-pointer 或 ≥44px 热区标记"; problems=1
      fi
      if ! grep -q 'motion-reduce:' "$f"; then
        note "$f：未发现 motion-reduce: 降级"
      fi
    fi

    durations="$(grep -oE 'duration-\[?[0-9]+' "$f" | sed 's/duration-\[*//' | sort -u)"
    for bad in $durations; do
      if [ "$bad" -lt 150 ] || [ "$bad" -gt 250 ]; then
        fail "$f：过渡时长 duration-${bad} 不在 150–250ms"; problems=1
      fi
    done
  done

  [ "$problems" = 0 ] && pass '热区标记与过渡时长合规'
}

# ---------- 门禁 7：反模式 ----------

gate7() {
  hr '门禁 7：反模式清零（AUTO）'
  if [ "${#FILE_LIST[@]}" -eq 0 ]; then skip '无变更文件'; return; fi
  local emoji problems=0 f

  if command -v grep >/dev/null 2>&1 && echo 'x' | grep -qP 'x'; then
    emoji="$(grep -nHP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' $(existing_files) 2>/dev/null || true)"
    if [ -n "$emoji" ]; then
      fail '检测到 Emoji 充当图标'
      printf '%s\n' "$emoji" | head -10 | sed 's/^/           /'
      problems=1
    fi
  else
    note '当前 grep 不支持 -P，Emoji 扫描降级为跳过'
  fi

  if [ -n "$UI_SPEC" ] && [ -f "$UI_SPEC" ]; then
    local sect hex
    sect="$(awk '/^## 6\./{f=1;next} /^## [0-9]+\./{f=0} f' "$UI_SPEC")"
    for hex in $(printf '%s\n' "$sect" | grep -oE '#[0-9a-fA-F]{3,8}' | sort -u); do
      for f in $(existing_files); do
        if grep -qi -- "$hex" "$f"; then
          fail "$f：命中反模式禁用色 $hex"; problems=1
        fi
      done
    done
    if printf '%s' "$sect" | grep -q '渐变'; then
      for f in $(existing_files); do
        if grep -qE 'gradient' "$f"; then
          fail "$f：命中反模式「禁用渐变」"; problems=1
        fi
      done
    fi
    note '第 6 节其余条目需人工对照（MANUAL）'
  else
    skip '未提供 ui-spec.md，反模式黑名单无法比对'
  fi

  [ "$problems" = 0 ] && pass '零 Emoji 图标，未命中黑名单禁用项'
}

# ---------- 人工门禁 ----------

gate_manual() {
  hr '门禁 1 / 3 / 8：人工确认（MANUAL）'
  manual '门禁 1：四态一致性与防抖（含 CLS < 0.1）'
  manual '门禁 3：断点零横向滚动、长串折行、Chip/Badge 展开'
  manual '门禁 8：实现与 sandbox-preview.html 无显著视觉偏差（Light + Dark）'
}

# ---------- main ----------

printf 'onePress gate · root=%s\n' "$ROOT"
collect_files
if [ "${#FILE_LIST[@]}" -gt 0 ]; then
  printf 'scanned files: %s\n' "${#FILE_LIST[@]}"
else
  printf 'scanned files: 0\n'
fi

gate0
if ui_change_is_no; then
  printf '\n== 结论\n'
  printf '  无 UI 变更，门禁 1–8 跳过（SKIP）\n'
  exit 0
fi

gate2a
gate2b
gate4
gate5
gate6
gate7
gate_manual

printf '\n== 结论\n'
if [ "$FAIL_COUNT" -gt 0 ]; then
  printf '  FAIL（%d 项失败，%d 条提示）\n' "$FAIL_COUNT" "$NOTE_COUNT"
  exit 1
fi
printf '  PASS WITH MANUAL ITEMS（0 项失败，%d 条提示）\n' "$NOTE_COUNT"
exit 0
