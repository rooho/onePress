#!/usr/bin/env bash
# 验证 Trae harness 安装：用内置 openspec 桩生成 10 个命令，断言技能、挂载、锁文件与隔离性。
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

# openspec 桩：模拟 OpenSpec CLI 在 .trae/commands/ 生成 10 个命令
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
  trae)   dir=".trae" ;;
  qoder)  dir=".qoder" ;;
  cursor) dir=".cursor" ;;
  *) exit 0 ;;
esac
mkdir -p "$PWD/$dir/commands"
for id in new continue ff propose explore apply verify sync archive bulk-archive; do
  cat > "$PWD/$dir/commands/opsx-$id.md" <<MD
---
name: opsx-$id
description: OpenSpec $id workflow (verification stub)
---

Run the $id workflow.
MD
done
STUB
chmod +x "$STUB_BIN/openspec"

printf '==> Trae：首次安装\n'
if ! PATH="$STUB_BIN:$PATH" bash "$INSTALL_SH" --target "$WORK" --harness trae >"$WORK/install.log" 2>&1; then
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

CMD_COUNT="$(find "$WORK/.trae/commands" -type f -name '*.md' | wc -l | tr -d ' ')"
if [ "$CMD_COUNT" -eq 10 ]; then ok '生成 10 个 Trae 命令'; else fail "Trae 命令数应为 10，实际 $CMD_COUNT"; fi
for id in new continue ff propose explore apply verify sync archive bulk-archive; do
  CMD="$WORK/.trae/commands/opsx-$id.md"
  assert_file "$CMD" ".trae/commands/opsx-$id.md"
  assert_contains "$CMD" 'onepress-discipline' "opsx-$id 已挂载技能引用"
  assert_count "$CMD" 'onepress-discipline' 1 "opsx-$id 技能引用只有一行"
done
assert_contains "$WORK/.trae/commands/opsx-apply.md" 'Run the apply workflow.' '命令原有正文未被改写'

VER="$(tr -d '\r\n' < "$ROOT/VERSION")"
assert_contains "$WORK/onePress.lock" "\"version\": \"$VER\"" 'lock version 与模板包一致'
assert_contains "$WORK/onePress.lock" '"trae": true' 'lock 记录 trae=true'
assert_contains "$WORK/onePress.lock" '"cursor": false' 'lock 记录 cursor=false'
assert_contains "$WORK/onePress.lock" '.trae/skills/onepress-discipline/SKILL.md' 'lock 记录 Trae 技能文件'

for dir in .qoder .opencode .cursor; do
  assert_absent "$WORK/$dir" "$dir 未被创建"
done

printf '==> Trae：重复安装（幂等）\n'
if ! PATH="$STUB_BIN:$PATH" bash "$INSTALL_SH" --target "$WORK" --harness trae >>"$WORK/install.log" 2>&1; then
  sed 's/^/    /' "$WORK/install.log"
  fail '重复安装退出码非 0'
else
  ok '重复安装退出码为 0'
fi
assert_count "$WORK/.trae/commands/opsx-apply.md" 'onepress-discipline' 1 '重复安装未重复挂载'

printf '==> Trae：旧版 3 命令残留修复（lock 未记录 files）\n'
WORK2="$(mktemp -d "${TMPDIR:-/tmp}/onepress-verify-trae-legacy.XXXXXX")"
git -C "$WORK2" init -q
mkdir -p "$WORK2/.trae/commands" "$WORK2/.trae/skills/onepress-discipline"
for id in new apply verify; do
  cat > "$WORK2/.trae/commands/opsx-$id.md" <<MD
---
name: opsx-$id
description: Legacy pack command
---

Run the $id workflow.
MD
done
cat > "$WORK2/onePress.lock" <<'LOCK'
{
  "version": "1.0.5",
  "installedAt": "2026-11-05T00:00:00Z",
  "harnesses": {
    "qoder": false,
    "opencode": false,
    "trae": true,
    "cursor": false
  },
  "protectedAssets": [
    "docs/ui-components.md",
    "openspec/changes/"
  ]
}
LOCK

if ! PATH="$STUB_BIN:$PATH" bash "$INSTALL_SH" --target "$WORK2" --harness trae >"$WORK2/install.log" 2>&1; then
  sed 's/^/    /' "$WORK2/install.log"
  fail '旧版残留修复安装退出码非 0'
else
  ok '旧版残留修复安装退出码为 0'
fi
LEGACY_COUNT="$(find "$WORK2/.trae/commands" -type f -name '*.md' | wc -l | tr -d ' ')"
if [ "$LEGACY_COUNT" -eq 10 ]; then ok '旧版 3 命令被清理并补齐为 10 个命令'; else fail "修复后命令数应为 10，实际 $LEGACY_COUNT"; fi
for id in continue ff propose explore archive bulk-archive; do
  assert_contains "$WORK2/.trae/commands/opsx-$id.md" 'onepress-discipline' "修复后 opsx-$id 已挂载技能引用"
done
rm -rf "$WORK2"

printf '\nTrae 安装验证：%d 通过，%d 失败\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
