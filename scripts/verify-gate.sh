#!/usr/bin/env bash
# onePress 门禁脚本自测：4 条用例，全部通过退出 0。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$ROOT/scripts/onepress-gate.sh"
WORK="${ONEPRESS_GATE_WORKDIR:-$ROOT/.gate-test}"
rm -rf "$WORK"
mkdir -p "$WORK"

PASS=0
FAIL=0

ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  [FAIL] %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

make_base() {
  local d="$1"
  mkdir -p "$d/openspec/changes/demo"
  printf '**UI Change**: yes\n\n## Why\n\nx\n' > "$d/openspec/changes/demo/proposal.md"
  printf '# UI Spec\n\n## 1. a\n\n## 6. 行业反模式黑名单（一票否决）\n\n- 禁用 #8b5cf6\n' \
    > "$d/openspec/changes/demo/ui-spec.md"
  printf '<!doctype html><html></html>\n' > "$d/openspec/changes/demo/sandbox-preview.html"
}

# ---------- 用例 A：违规代码 → 非零退出 ----------
A="$WORK/a"
make_base "$A"
mkdir -p "$A/src"
cat > "$A/src/bad.tsx" <<'EOF'
export function Bad() {
  const s = { color: '#3b82f6' };
  return <div style={{ padding: 8 }} className="w-[317px]">x</div>;
}
EOF
outA="$(bash "$GATE" --root "$A" --change openspec/changes/demo 2>&1)"
codeA=$?
if [ "$codeA" -ne 0 ]; then ok "用例 A 退出码非 0（$codeA）"; else bad "用例 A 期望非 0，实际 0"; fi
for kw in '内联样式' '硬编码色值' '任意像素间距'; do
  if printf '%s' "$outA" | grep -q "$kw"; then ok "用例 A 命中 $kw"; else bad "用例 A 未命中 $kw"; fi
done
for ln in ':2:' ':3:'; do
  if printf '%s' "$outA" | grep -q "$ln"; then ok "用例 A 报出 $ln 行号"; else bad "用例 A 未报出 $ln 行号"; fi
done

# ---------- 用例 B：合规代码 → 退出 0 ----------
B="$WORK/b"
make_base "$B"
mkdir -p "$B/src" "$B/styles"
cat > "$B/styles/globals.css" <<'EOF'
:root {
  --background: #ffffff;
  --foreground: #111111;
  --card: #ffffff;
  --card-foreground: #111111;
  --muted: #f4f4f5;
  --muted-foreground: #52525b;
}
.dark {
  --background: #09090b;
  --foreground: #fafafa;
  --card: #18181b;
  --card-foreground: #fafafa;
  --muted: #27272a;
  --muted-foreground: #d4d4d8;
}
EOF
cat > "$B/src/good.tsx" <<'EOF'
import { Button } from '@/components/ui/button';

export function GoodView({ status }: { status: string }) {
  return (
    <div className="p-4 space-y-2">
      <Button className="cursor-pointer duration-200 motion-reduce:transition-none" aria-label="刷新">
        <svg aria-hidden="true" />
      </Button>
      <p className="break-words min-w-0">{status}</p>
    </div>
  );
}
EOF
outB="$(bash "$GATE" --root "$B" --change openspec/changes/demo 2>&1)"
codeB=$?
if [ "$codeB" -eq 0 ]; then ok '用例 B 退出码 0'; else bad "用例 B 期望 0，实际 $codeB"; printf '%s\n' "$outB" | sed 's/^/    /'; fi
if printf '%s' "$outB" | grep -q '\[MANUAL\]'; then ok '用例 B 输出 MANUAL 项'; else bad '用例 B 缺少 MANUAL 项'; fi
if printf '%s' "$outB" | grep -q '对比度'; then ok '用例 B 执行了对比度检查'; else bad '用例 B 未执行对比度检查'; fi

# ---------- 用例 C：空仓库 → 退出 0 且有三项 MANUAL ----------
C="$WORK/c"
mkdir -p "$C"
outC="$(bash "$GATE" --root "$C" 2>&1)"
codeC=$?
if [ "$codeC" -eq 0 ]; then ok '用例 C 退出码 0'; else bad "用例 C 期望 0，实际 $codeC"; fi
if [ "$(printf '%s' "$outC" | grep -c '\[MANUAL\]')" -ge 3 ]; then
  ok '用例 C 输出 3 项 MANUAL'
else
  bad '用例 C MANUAL 项不足 3'
fi
if printf '%s' "$outC" | grep -q 'scanned files: 0'; then ok '用例 C 空文件集合'; else bad '用例 C 未报告空文件集合'; fi

# ---------- 用例 D：对比度不足 → 非零退出 ----------
D="$WORK/d"
make_base "$D"
mkdir -p "$D/src" "$D/styles"
cat > "$D/styles/globals.css" <<'EOF'
:root {
  --background: #ffffff;
  --foreground: #777777;
  --card: #ffffff;
  --card-foreground: #111111;
  --muted: #ffffff;
  --muted-foreground: #111111;
}
EOF
cat > "$D/src/good.tsx" <<'EOF'
import { Button } from '@/components/ui/button';

export function GoodView() {
  return (
    <div className="p-4">
      <Button className="cursor-pointer duration-200 motion-reduce:transition-none" aria-label="刷新">
        刷新
      </Button>
    </div>
  );
}
EOF
outD="$(bash "$GATE" --root "$D" --change openspec/changes/demo 2>&1)"
codeD=$?
if [ "$codeD" -ne 0 ]; then ok "用例 D 退出码非 0（$codeD）"; else bad '用例 D 期望非 0，实际 0'; fi
if printf '%s' "$outD" | grep -q '< 4.5:1'; then ok '用例 D 报出对比度不足'; else bad '用例 D 未报出对比度不足'; fi

# ---------- 用例 E：注册表追加（分区 + 幂等） ----------
E="$WORK/e"
mkdir -p "$E"
bash "$ROOT/install.sh" --target "$E" --harness qoder --no-init >/dev/null 2>&1
REG="$E/docs/ui-components.md"
bash "$ROOT/scripts/onepress-registry-append.sh" --root "$E" --name CompA --path "@/a" --archetype Standard-CRUD-Table >/dev/null 2>&1
codeE1=$?
bash "$ROOT/scripts/onepress-registry-append.sh" --root "$E" --name CompA --path "@/a" >/dev/null 2>&1
codeE2=$?
bash "$ROOT/scripts/onepress-registry-append.sh" --root "$E" --section base --name CompB --path "@/b" >/dev/null 2>&1

if [ "$codeE1" -eq 0 ] && grep -q 'CompA' "$REG"; then ok '用例 E 首次追加成功'; else bad '用例 E 首次追加失败'; fi
if [ "$codeE2" -eq 0 ] && [ "$(grep -c 'CompA' "$REG")" -eq 1 ]; then ok '用例 E 幂等（未重复追加）'; else bad '用例 E 幂等失败'; fi
if awk '/^## 基础组件/{f=1;next} /^## 业务组件/{f=0} f && /CompA/{found=1} END{exit found?1:0}' "$REG"; then
  ok '用例 E 未写错分区'
else
  bad '用例 E 分区错乱'
fi
if grep -q 'CompB' "$REG" && awk '/^## 基础组件/{f=1;next} /^## 业务组件/{f=0} f && /CompB/{found=1} END{exit found?0:1}' "$REG"; then
  ok '用例 E base 分区写入正确'
else
  bad '用例 E base 分区写入失败'
fi

rm -rf "$WORK"

printf '\ngate tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
