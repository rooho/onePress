#!/usr/bin/env bash
# onepress-review-lint.sh — 校验 review 工件与契约哈希
#
#   bash scripts/onepress-review-lint.sh --change openspec/changes/<change> [--quiet]
#
# 规则：
#   - UI Change: no  → review.md 必须存在且 Result: SKIP
#   - UI Change: yes → review.md 必须 Result: PASS、P0: 0、P1: 0、L3: APPROVED，
#                      且 ui-spec / sandbox / plan 的 SHA-256 与 review.md 记录一致
# 退出码：0 通过；1 失败；2 参数错误。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGE=""
QUIET=0

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --change) CHANGE="${2:-}"; shift 2 ;;
    --quiet)  QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$CHANGE" ] || { usage >&2; exit 2; }
case "$CHANGE" in
  /*) DIR="$CHANGE" ;;
  *)  DIR="$ROOT/$CHANGE" ;;
esac
DIR="${DIR%/}"
[ -d "$DIR" ] || { printf 'change directory not found: %s\n' "$DIR" >&2; exit 2; }

FAILURES=0
fail() { printf '  [FAIL] %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
pass() { [ "$QUIET" = 1 ] || printf '  [PASS] %s\n' "$1"; }
note() { [ "$QUIET" = 1 ] || printf '         %s\n' "$1"; }

hash_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | sed -E 's/^.*= //'
  fi
}

field_hash() {
  sed -nE "s/^- \*\*$1\*\*:[[:space:]]*\`?([0-9a-fA-F]{64})\`?.*$/\1/p" "$DIR/review.md" | head -1
}

[ -f "$DIR/proposal.md" ] || fail '缺少 proposal.md'

UI_CHANGE="$(grep -m1 -oE '\*\*UI Change\*\*:[[:space:]]*(yes|no)' "$DIR/proposal.md" 2>/dev/null | grep -oE '(yes|no)$' || true)"
[ -n "$UI_CHANGE" ] || fail 'proposal.md 缺少 **UI Change**: yes|no'

if [ "$UI_CHANGE" = "no" ]; then
  if [ -f "$DIR/review.md" ]; then
    pass 'review.md 存在'
  else
    fail '非 UI 变更缺少 review.md（Result: SKIP）'
  fi
  if [ -f "$DIR/review.md" ] && grep -qE '^- \*\*Result\*\*:[[:space:]]*`?SKIP' "$DIR/review.md"; then
    pass 'Result: SKIP'
  else
    fail 'review.md 的 Result 不是 SKIP'
  fi
  printf '\nreview-lint: %d failed\n' "$FAILURES"
  [ "$FAILURES" -eq 0 ]
  exit $?
fi

[ "$UI_CHANGE" = "yes" ] || { printf '\nreview-lint: %d failed\n' "$FAILURES"; exit 1; }

for f in ui-spec.md sandbox-preview.html plan.md review.md; do
  [ -f "$DIR/$f" ] || fail "缺少 $f"
done

if [ -f "$DIR/ui-spec.md" ]; then
  if grep -qE '^> Review-Status: APPROVED[[:space:]]*$' "$DIR/ui-spec.md"; then
    pass 'Review-Status: APPROVED'
  else
    fail 'ui-spec.md 的 Review-Status 不是 APPROVED（需由人类签署）'
  fi
fi

if [ -f "$DIR/review.md" ]; then
  if grep -qE '^- \*\*Result\*\*:[[:space:]]*`?PASS' "$DIR/review.md"; then
    pass 'Result: PASS'
  else
    fail 'review.md 的 Result 不是 PASS'
  fi
  if grep -qE '\*\*P0\*\*:[[:space:]]*`?0`?([^0-9]|$)' "$DIR/review.md"; then
    pass 'P0: 0'
  else
    fail 'review.md 的 P0 不是 0'
  fi
  if grep -qE '\*\*P1\*\*:[[:space:]]*`?0`?([^0-9]|$)' "$DIR/review.md"; then
    pass 'P1: 0'
  else
    fail 'review.md 的 P1 不是 0'
  fi
  if grep -qE '^- \*\*L3\*\*:[[:space:]]*`?APPROVED' "$DIR/review.md"; then
    pass 'L3: APPROVED'
  else
    fail 'review.md 的 L3 不是 APPROVED'
  fi
fi

check_hash() {
  local file="$1" field="$2" recorded expected
  [ -f "$DIR/review.md" ] || return 0
  [ -f "$DIR/$file" ] || return 0
  recorded="$(field_hash "$field")"
  expected="$(hash_of "$DIR/$file")"
  if [ -z "$recorded" ]; then
    fail "review.md 缺少 $field"
  elif [ "$recorded" != "$expected" ]; then
    fail "$file 已变化（review.md 过期）：记录 ${recorded:0:12}…，当前 ${expected:0:12}…"
  else
    pass "$field 与 $file 一致"
  fi
}

check_hash ui-spec.md ui-spec-sha256
check_hash sandbox-preview.html sandbox-sha256
check_hash plan.md plan-sha256

printf '\nreview-lint: %d failed\n' "$FAILURES"
[ "$FAILURES" -eq 0 ]
