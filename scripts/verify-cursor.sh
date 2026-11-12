#!/usr/bin/env bash
# 验证 Cursor harness 安装：用内置 openspec 桩生成命令，断言技能、挂载、锁文件与隔离性。
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

WORK="$(mktemp -d "${TMPDIR:-/tmp}/onepress-verify-cursor.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

git -C "$WORK" init -q
mkdir -p "$WORK/.cursor"

# openspec 桩：只生成 Cursor 命令，避免验证脚本依赖 npm / 网络
STUB_BIN="$WORK/.stub-bin"
mkdir -p "$STUB_BIN"
cat > "$STUB_BIN/openspec" <<'STUB'
#!/usr/bin/env bash
cmd="${1:-}"
shift || true
tool=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tools) tool="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
[ "$cmd" = "init" ] || exit 0
case "$tool" in
  cursor) dir=".cursor" ;;
  qoder)  dir=".qoder" ;;
  *) exit 0 ;;
esac
mkdir -p "$PWD/$dir/commands"
cat > "$PWD/$dir/commands/opsx-apply.md" <<'MD'
---
description: Apply a change (verification stub)
---

Apply the change.
MD
cat > "$PWD/$dir/commands/opsx-new.md" <<'MD'
---
description: Create a change (verification stub)
---

Create the change.
MD
STUB
chmod +x "$STUB_BIN/openspec"

printf '==> Cursor：首次安装\n'
if ! PATH="$STUB_BIN:$PATH" bash "$INSTALL_SH" --target "$WORK" --harness cursor >"$WORK/install.log" 2>&1; then
  sed 's/^/    /' "$WORK/install.log"
  fail '安装器退出码非 0'
  printf '\nCursor 安装验证：%d 通过，%d 失败\n' "$PASS" "$FAIL"
  exit 1
fi
ok '安装器退出码为 0'

SKILL="$WORK/.cursor/skills/onepress-discipline/SKILL.md"
assert_file "$SKILL" '.cursor/skills/onepress-discipline/SKILL.md'
assert_contains "$SKILL" 'ui-spec.md' '技能包含 ui-spec.md 契约'
assert_contains "$SKILL" 'sandbox-preview' '技能包含 sandbox-preview 沙箱'
assert_contains "$SKILL" 'prefers-reduced-motion' '技能包含减少动效降级'
assert_contains "$SKILL" '四态状态机' '技能包含四态状态机铁律'
assert_contains "$SKILL" '无障碍基线' '技能包含无障碍基线铁律'
assert_contains "$SKILL" '防呆与反馈闭环' '技能包含防呆与反馈闭环铁律'

for name in new apply; do
  CMD="$WORK/.cursor/commands/opsx-$name.md"
  assert_file "$CMD" ".cursor/commands/opsx-$name.md"
  assert_contains "$CMD" 'onepress-discipline' "opsx-$name 已挂载技能引用"
  assert_count "$CMD" 'onepress-discipline' 1 "opsx-$name 技能引用只有一行"
done

assert_contains "$WORK/.cursor/commands/opsx-apply.md" 'Apply the change.' '命令原有正文未被改写'
assert_contains "$WORK/.cursor/commands/opsx-new.md" 'Create the change.' '命令原有正文未被改写'

VER="$(tr -d '\r\n' < "$ROOT/VERSION")"
assert_contains "$WORK/onePress.lock" "\"version\": \"$VER\"" 'lock version 与模板包一致'
assert_contains "$WORK/onePress.lock" '"cursor": true' 'lock 记录 cursor=true'
assert_contains "$WORK/onePress.lock" '"trae": false' 'lock 记录 trae=false'
assert_contains "$WORK/onePress.lock" '.cursor/skills/onepress-discipline/SKILL.md' 'lock 记录 Cursor 技能文件'

for dir in .qoder .opencode .trae; do
  assert_absent "$WORK/$dir" "$dir 未被创建"
done

printf '==> Cursor：重复安装（幂等）\n'
if ! PATH="$STUB_BIN:$PATH" bash "$INSTALL_SH" --target "$WORK" --harness cursor >>"$WORK/install.log" 2>&1; then
  sed 's/^/    /' "$WORK/install.log"
  fail '重复安装退出码非 0'
else
  ok '重复安装退出码为 0'
fi
assert_count "$WORK/.cursor/commands/opsx-apply.md" 'onepress-discipline' 1 '重复安装未重复挂载'

printf '\nCursor 安装验证：%d 通过，%d 失败\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
