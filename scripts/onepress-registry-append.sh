#!/usr/bin/env bash
# 向 docs/ui-components.md 追加一行组件记录（只追加，不重排、不删历史）
#
#   bash scripts/onepress-registry-append.sh --root . \
#        --name DataTableToolbar --path "@/components/biz/data-table-toolbar" \
#        --archetype Standard-CRUD-Table \
#        --props "{ searchKey: string; onReset: () => void }" \
#        [--section domain|base] [--dry-run]
#
# 用途：OpenCode 没有 /opsx:archive，归档后用本脚本补记可复用组件。
# 退出码：0 写入成功或已存在（幂等）；1 参数或文件错误。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=""
CPATH=""
ARCH="通用"
PROPS=""
SECTION="domain"
DRY=0

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root)      ROOT="${2:-}"; shift 2 ;;
    --name)      NAME="${2:-}"; shift 2 ;;
    --path)      CPATH="${2:-}"; shift 2 ;;
    --archetype) ARCH="${2:-}"; shift 2 ;;
    --props)     PROPS="${2:-}"; shift 2 ;;
    --section)   SECTION="${2:-}"; shift 2 ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$NAME" ] || { printf 'missing --name\n' >&2; exit 1; }
[ -n "$CPATH" ] || { printf 'missing --path\n' >&2; exit 1; }
case "$SECTION" in
  base|domain) ;;
  *) printf -- '--section 只能是 base 或 domain\n' >&2; exit 1 ;;
esac

FILE="$ROOT/docs/ui-components.md"
if [ ! -f "$FILE" ]; then
  printf 'registry not found: %s\n请先运行 install.sh 初始化注册表\n' "$FILE" >&2
  exit 1
fi

if [ "$SECTION" = "base" ]; then
  SEC='## 基础组件（base）'
else
  SEC='## 业务组件（domain）'
fi

grep -qF "$SEC" "$FILE" || {
  printf 'section not found: %s\n' "$SEC" >&2
  exit 1
}

esc() { printf '%s' "$1" | sed 's/|/\\|/g'; }

if grep -qF '| `'"$NAME"'` |' "$FILE"; then
  printf '[SKIP] %s 已在注册表中\n' "$NAME"
  exit 0
fi

ROW="| \`$(esc "$NAME")\` | \`$(esc "$CPATH")\` | $(esc "$ARCH") | $(esc "${PROPS:--}") |"

if [ "$DRY" = 1 ]; then
  printf '[DRY] 将追加到 %s：\n%s\n' "$SEC" "$ROW"
  exit 0
fi

TMP="$(mktemp "$(dirname "$FILE")/.registry.XXXXXX")" || exit 1
trap 'rm -f "$TMP"' EXIT

awk -v SEC="$SEC" -v ROW="$ROW" '
  BEGIN { insec = 0; n = 0 }

  function flush() {
    i = n
    while (i > 0 && buf[i] ~ /^[[:space:]]*$/) i--
    for (j = 1; j <= i; j++) print buf[j]
    print ROW
    for (j = i + 1; j <= n; j++) print buf[j]
    n = 0
  }

  $0 == SEC { insec = 1; print; next }

  insec && /^## / {
    flush()
    insec = 0
    print
    next
  }

  insec { buf[++n] = $0; next }

  { print }

  END { if (insec) flush() }
' "$FILE" > "$TMP"

if ! cmp -s "$FILE" "$TMP"; then
  cat "$TMP" > "$FILE"
  printf '[OK] 已追加到 %s：%s\n' "$SEC" "$ROW"
else
  printf '[SKIP] 未发生变化（%s 段落可能为空或格式异常）\n' "$SEC"
  exit 1
fi
