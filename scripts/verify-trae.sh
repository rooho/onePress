#!/usr/bin/env bash
# 验证 Trae harness 安装：在临时仓库执行 install.sh，断言技能、命令、锁文件与隔离性。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="$ROOT/install.sh"
PASS=0
FAIL=0

ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  [FAIL] %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

assert_file() {
  if [ -f "$1" ]; then ok "存在 $2"; else fail "缺失 $2"; fi
}

assert_absent() {
  if [ -e "$1" ]; then fail "不应创建 $2"; else ok "未创建 $2"; fi
}

assert_contains() {
  if grep -q -- "$2" "$1"; then ok "$3"; else fail "$3"; fi
}

assert_count() {
  local n
  n="$(grep -c -- "$2" "$1" || true)"
  if [ "$n" -eq "$3" ]; then ok "$4（$n 次）"; else fail "$4（期望 $3 次，实际 $n 次）"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/onepress-verify-trae.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

git -C "$WORK" init -q
mkdir -p "$WORK/.trae"

printf '==> Trae：首次安装\n'
if ! bash "$INSTALL_SH" --target "$WORK" --harness trae >"$WORK/install.log" 2>&1; then
  sed 's/^/    /' "$WORK/install.log"
  fail '安装器退出码非 0'
  printf '\nTrae 安装验证：%d 通过，%d 失败\n' "$PASS" "$FAIL"
  exit 1
fi
ok '安装器退出码为 0'

SKILL="$WORK/.trae/skills/onepress-discipline/SKILL.md"
assert_file "$SKILL" '.trae/skills/onepress-discipline/SKILL.md'
assert_contains "$SKILL" 'ui_contract' '技能包含 ui_contract 契约'
assert_contains "$SKILL" '四态状态机' '技能包含四态状态机铁律'
assert_contains "$SKILL" '无障碍基线' '技能包含无障碍基线铁律'
assert_contains "$SKILL" '防呆与反馈闭环' '技能包含防呆与反馈闭环铁律'

for name in new apply verify; do
  CMD="$WORK/.trae/commands/opsx-$name.md"
  assert_file "$CMD" ".trae/commands/opsx-$name.md"
  assert_contains "$CMD" "name: opsx-$name" "opsx-$name 命令名正确"
  assert_contains "$CMD" 'onepress-discipline' "opsx-$name 自带技能引用"
done

VER="$(tr -d '\r\n' < "$ROOT/VERSION")"
assert_contains "$WORK/onePress.lock" "\"version\": \"$VER\"" 'lock version 与模板包一致'
assert_contains "$WORK/onePress.lock" '"trae": true' 'lock 记录 trae=true'
assert_contains "$WORK/onePress.lock" '"cursor": false' 'lock 记录 cursor=false'
assert_contains "$WORK/onePress.lock" '.trae/commands/opsx-apply.md' 'lock 记录 Trae 命令文件'

for dir in .qoder .opencode .cursor; do
  assert_absent "$WORK/$dir" "$dir 未被创建"
done

printf '==> Trae：重复安装（幂等）\n'
if ! bash "$INSTALL_SH" --target "$WORK" --harness trae >>"$WORK/install.log" 2>&1; then
  sed 's/^/    /' "$WORK/install.log"
  fail '重复安装退出码非 0'
else
  ok '重复安装退出码为 0'
fi
assert_count "$WORK/.trae/commands/opsx-apply.md" 'onepress-discipline' 1 '命令技能引用仍只有一行'

printf '\nTrae 安装验证：%d 通过，%d 失败\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
