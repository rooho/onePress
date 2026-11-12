#!/usr/bin/env bash
# 校验三份 carrier skill 语义等价、编码一致，并检查 OpenCode 拆分载体覆盖同一要点集合。
#
#   bash scripts/verify-carriers.sh
#
# 等价判定口径：把载体名（Qoder/Trae/Cursor）与目录名（.qoder/.trae/.cursor）
# 归一化后逐行比对；同时校验 UTF-8 无 BOM + LF、要点关键词命中。
# 退出码：0 全部通过；1 存在差异或缺失。

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok()  { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  [FAIL] %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

Q="$ROOT/qoder/skills/onepress-discipline/SKILL.md"
T="$ROOT/trae/skills/onepress-discipline/SKILL.md"
C="$ROOT/cursor/skills/onepress-discipline/SKILL.md"

# 十项最小要点（spec: 多 harness 语义等价）对应的可检索关键词
KEYS='Token 四态 无障碍 防呆 ui_change ui-spec.md 双步 sandbox-preview 44×44 八项门禁'

echo "== 文件存在性 =="
for f in "$Q" "$T" "$C"; do
  if [ -f "$f" ]; then ok "存在 ${f#"$ROOT"/}"; else bad "缺失 ${f#"$ROOT"/}"; fi
done
for f in opencode/opencode.json opencode/agent/ux-architect.md \
         opencode/commands/opsx-new.md opencode/commands/opsx-apply.md \
         opencode/commands/opsx-verify.md opencode/skills/superpowers-tdd/SKILL.md; do
  if [ -f "$ROOT/$f" ]; then ok "存在 $f"; else bad "缺失 $f"; fi
done

echo
echo "== 三份 carrier 归一化等价 =="
norm() { sed -e "s/$1/__CARRIER__/g" -e "s/\.$2/__DIR__/g" "$3"; }

if [ -f "$Q" ] && [ -f "$T" ] && [ -f "$C" ]; then
  if diff -q <(norm Qoder qoder "$Q") <(norm Trae trae "$T") >/dev/null 2>&1; then
    ok 'qoder ≡ trae（仅载体名/目录名不同）'
  else
    bad 'qoder ≠ trae'
    diff <(norm Qoder qoder "$Q") <(norm Trae trae "$T") | head -10 | sed 's/^/           /'
  fi
  if diff -q <(norm Qoder qoder "$Q") <(norm Cursor cursor "$C") >/dev/null 2>&1; then
    ok 'qoder ≡ cursor（仅载体名/目录名不同）'
  else
    bad 'qoder ≠ cursor'
    diff <(norm Qoder qoder "$Q") <(norm Cursor cursor "$C") | head -10 | sed 's/^/           /'
  fi
fi

echo
echo "== 编码一致（UTF-8 无 BOM + LF） =="
for f in "$Q" "$T" "$C"; do
  rel="${f#"$ROOT"/}"
  [ -f "$f" ] || continue
  if head -c 3 "$f" | od -An -tx1 | tr -d ' \n' | grep -q '^efbbbf'; then
    bad "$rel 含 BOM"
  else
    ok "$rel 无 BOM"
  fi
  if LC_ALL=C grep -q $'\r' "$f"; then
    bad "$rel 含 CRLF"
  else
    ok "$rel 为 LF"
  fi
done

echo
echo "== 要点关键词（三份 carrier） =="
for f in "$Q" "$T" "$C"; do
  rel="${f#"$ROOT"/}"
  [ -f "$f" ] || continue
  miss=""
  for k in $KEYS; do
    grep -q -- "$k" "$f" || miss="$miss $k"
  done
  if [ -z "$miss" ]; then
    ok "$rel 覆盖全部要点"
  else
    bad "$rel 缺少：$miss"
  fi
done

echo
echo "== 要点关键词（OpenCode 合并集） =="
miss=""
for k in $KEYS; do
  grep -rq -- "$k" "$ROOT/opencode" 2>/dev/null || miss="$miss $k"
done
if [ -z "$miss" ]; then
  ok 'opencode/ 合并集覆盖全部要点（agent + commands + skill）'
else
  bad "opencode/ 合并集缺少：$miss"
fi

printf '\ncarrier checks: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
