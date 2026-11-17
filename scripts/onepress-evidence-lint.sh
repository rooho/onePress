#!/usr/bin/env bash
# onePress verification evidence lint (no runtime dependencies).
#
# Usage:
#   bash scripts/onepress-evidence-lint.sh --change openspec/changes/<name>
#   bash scripts/onepress-evidence-lint.sh <path/to/verification-evidence.md>
#
# Checks the V3.2 evidence contract: required sections, fresh command
# output blocks with exit codes, an evidence table, zero Critical /
# Important findings, no speculative wording, and UI gate evidence when
# ui-spec.md exists. Exit 0 when there is no FAIL; otherwise 1.
set -uo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/onepress-evidence-lint.sh --change openspec/changes/<name>
  bash scripts/onepress-evidence-lint.sh <path/to/verification-evidence.md>

Checks the V3.2 verification evidence contract. Exit 0 when there is no
FAIL; otherwise 1.
EOF
}

CHANGE_DIR=""
REPORT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --change)
      [ $# -ge 2 ] && [ -n "$2" ] || { printf 'missing value for --change\n' >&2; exit 2; }
      CHANGE_DIR="$2"
      shift 2
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
      REPORT="$1"
      shift
      ;;
  esac
done

if [ -n "$CHANGE_DIR" ]; then
  CHANGE_DIR="${CHANGE_DIR%/}"
  REPORT="$CHANGE_DIR/verification-evidence.md"
fi
if [ -z "$REPORT" ]; then
  usage >&2
  exit 2
fi
if [ -d "$REPORT" ]; then
  REPORT="${REPORT%/}/verification-evidence.md"
fi
if [ -z "$CHANGE_DIR" ]; then
  CHANGE_DIR="$(dirname "$REPORT")"
fi
if [ ! -f "$REPORT" ]; then
  printf '[FAIL] verification-evidence.md not found: %s\n' "$REPORT" >&2
  exit 1
fi

TEXT="$(tr -d '\r' < "$REPORT")"
if [ -z "${TEXT//[[:space:]]/}" ]; then
  printf '[FAIL] verification-evidence.md is empty: %s\n' "$REPORT" >&2
  exit 1
fi

PASS=0
FAIL=0

ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  [FAIL] %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
skip() { printf '  [SKIP] %s\n' "$1"; }

printf 'evidence-lint: %s\n' "$REPORT"

echo '== required sections =='
for section in '1\. Commands' '2\. Fresh Command Results' '3\. Evidence Table' '4\. Cold-Context Review' 'Overall Decision'; do
  if printf '%s\n' "$TEXT" | grep -qE "^##[[:space:]]+${section}[[:space:]]*$"; then
    ok "section: ## $section"
  else
    bad "missing section: ## $section"
  fi
done

echo '== fresh command output blocks =='
BLOCK_STATS="$(printf '%s\n' "$TEXT" | awk '
  /^```text[[:space:]]*$/ { in_block = 1; code = -1; next }
  /^```[[:space:]]*$/ {
    if (in_block && code >= 0) { n++; if (code == 0) z++; else nz++ }
    in_block = 0
    next
  }
  in_block && match($0, /exit code: [0-9]+/) {
    code = substr($0, RSTART + 11, RLENGTH - 11) + 0
  }
  END { print n + 0, z + 0, nz + 0 }
')"
read -r BLOCK_COUNT ZERO_BLOCKS NONZERO_BLOCKS <<< "$BLOCK_STATS"
if [ "${BLOCK_COUNT:-0}" -ge 2 ]; then
  ok "text blocks with exit code: $BLOCK_COUNT (>= 2)"
else
  bad "text blocks with exit code: ${BLOCK_COUNT:-0} (need at least 2)"
fi
if [ "${ZERO_BLOCKS:-0}" -ge 1 ]; then
  ok "text blocks with exit code 0: $ZERO_BLOCKS"
else
  bad 'no text block shows a successful (exit code 0) command'
fi

EXCLUSION_BLOCK="$(printf '%s\n' "$TEXT" | awk '
  /^\*\*Warnings \/ exclusions\*\*/ { f = 1; next }
  f && /^##[[:space:]]/ { exit }
  f { print }
')"
HAS_EXCLUSION=0
if printf '%s\n' "$EXCLUSION_BLOCK" | grep -qE '^[[:space:]]*[-*][[:space:]]+'; then
  if ! printf '%s\n' "$EXCLUSION_BLOCK" | grep -qiE 'none'; then
    HAS_EXCLUSION=1
  fi
fi
if [ "${NONZERO_BLOCKS:-0}" -gt 0 ] && [ "$HAS_EXCLUSION" = 0 ]; then
  bad "$NONZERO_BLOCKS text block(s) have a non-zero exit code with no exclusion rule"
else
  ok "non-zero exit blocks: ${NONZERO_BLOCKS:-0} (exclusion: $HAS_EXCLUSION)"
fi

echo '== evidence table =='
TABLE_STATS="$(printf '%s\n' "$TEXT" | awk -F'|' '
  /^\|/ {
    e = $4
    gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", e)
    if (e ~ /^[0-9]+$/) { n++; if (e == 0) z++; else nz++ }
  }
  END { print n + 0, z + 0, nz + 0 }
')"
read -r TABLE_ROWS ZERO_ROWS NONZERO_ROWS <<< "$TABLE_STATS"
if [ "${ZERO_ROWS:-0}" -ge 1 ]; then
  ok "evidence table rows with exit code 0: $ZERO_ROWS (of ${TABLE_ROWS:-0})"
else
  bad 'evidence table has no row with exit code 0'
fi
if [ "${NONZERO_ROWS:-0}" -gt 0 ] && [ "$HAS_EXCLUSION" = 0 ]; then
  bad "$NONZERO_ROWS evidence table row(s) have a non-zero exit code with no exclusion rule"
else
  ok "non-zero evidence rows: ${NONZERO_ROWS:-0} (exclusion: $HAS_EXCLUSION)"
fi

echo '== speculative wording =='
BANNED="$(printf '%s\n' "$TEXT" | grep -nE '应该能通过|看起来正确|看起来没问题|理论上(能|可以|应该)|probably|should pass|looks (good|correct)|I think it works' || true)"
if [ -n "$BANNED" ]; then
  bad 'speculative wording found'
  printf '%s\n' "$BANNED" | head -10 | sed 's/^/           /'
else
  ok 'no speculative wording'
fi

echo '== unresolved template placeholders =='
if printf '%s\n' "$TEXT" | grep -qE '<change-name>|<exact command>|exit code: <'; then
  bad 'unresolved template placeholders found'
else
  ok 'no unresolved placeholders'
fi

echo '== cold-context review =='
if printf '%s\n' "$TEXT" | grep -qE '^- ?\**Mode\**[[:space:]]*:[[:space:]]*`?(subagent|human-fresh-session)`?[[:space:]]*$'; then
  ok 'Mode: subagent|human-fresh-session'
else
  bad 'missing or invalid Mode (expected subagent|human-fresh-session)'
fi
CRIT="$(printf '%s\n' "$TEXT" | grep -m1 -oE '^- ?\**Critical\**[[:space:]]*:[[:space:]]*`?[0-9]+`?' | grep -oE '[0-9]+' || true)"
IMP="$(printf '%s\n' "$TEXT" | grep -m1 -oE '^- ?\**Important\**[[:space:]]*:[[:space:]]*`?[0-9]+`?' | grep -oE '[0-9]+' || true)"
if [ -z "$CRIT" ]; then
  bad 'missing "- **Critical**: <n>" line'
elif [ "$CRIT" = "0" ]; then
  ok 'Critical: 0'
else
  bad "Critical: $CRIT (must be 0)"
fi
if [ -z "$IMP" ]; then
  bad 'missing "- **Important**: <n>" line'
elif [ "$IMP" = "0" ]; then
  ok 'Important: 0'
else
  bad "Important: $IMP (must be 0)"
fi

if printf '%s\n' "$TEXT" | grep -qE '^\*\*Validation Level\*\*:'; then
  ok 'Validation Level present'
  if printf '%s\n' "$TEXT" | grep -qE '^\*\*Validation Level\*\*:.*downgraded'; then
    if printf '%s\n' "$TEXT" | grep -qiE 'alternative|替代证据'; then
      ok 'downgraded report lists alternative evidence'
    else
      bad 'downgraded report must list alternative evidence'
    fi
  fi
else
  bad 'missing **Validation Level**: line'
fi

echo '== UI gate evidence =='
if [ -f "$CHANGE_DIR/ui-spec.md" ]; then
  if printf '%s\n' "$(tr -d '\r' < "$CHANGE_DIR/ui-spec.md")" | grep -qE '^> Review-Status: APPROVED[[:space:]]*$'; then
    ok 'ui-spec.md Review-Status: APPROVED'
  else
    bad 'ui-spec.md Review-Status is not APPROVED'
  fi
  if printf '%s\n' "$TEXT" | awk '
    /^```text[[:space:]]*$/ { in_block = 1; has_cmd = 0; has_ok = 0; next }
    /^```[[:space:]]*$/ { if (in_block && has_cmd && has_ok) found = 1; in_block = 0; next }
    in_block && /onepress-gate\.sh/ { has_cmd = 1 }
    in_block && /exit code: 0/ { has_ok = 1 }
    END { exit(found ? 0 : 1) }
  '; then
    ok 'onepress-gate.sh ran with exit code 0'
  else
    bad 'missing onepress-gate.sh output block with exit code 0'
  fi
else
  skip 'no ui-spec.md (non-UI change)'
fi

echo '== overall decision =='
if printf '%s\n' "$TEXT" | grep -qE '^- \[[xX]\] .*FAIL'; then
  bad 'Overall Decision is FAIL'
elif printf '%s\n' "$TEXT" | grep -qE '^- \[[xX]\] .*PASS'; then
  ok 'Overall Decision is PASS'
else
  bad 'Overall Decision has no checked PASS/FAIL item'
fi

printf '\nRESULT: %d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
