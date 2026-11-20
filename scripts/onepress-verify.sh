#!/usr/bin/env bash
# onepress-verify.sh — evidence orchestration for a superspec change.
#
#   bash scripts/onepress-verify.sh --change openspec/changes/<name> \
#        [--scope files|package|all] [--base <ref>] [--legacy]
#   bash scripts/onepress-verify.sh --change <name> --range
#   bash scripts/onepress-verify.sh --change <name> --final --base <BASE_SHA>
#   bash scripts/onepress-verify.sh --change <name> --churn
#
# Row states (boundary matrix):
#   RUN      exit code 0..n   executed, counted in run/pass/fail
#   FALLBACK exit code 0..n   executed without a resolvable path, never a pass
#   SKIP     exit code "-"    not executed (out of scope), still recorded
#
# Command source: the change's plan.md `## Evidence Map` table. No other
# command list is read, and no default command set is built in.
#
# Evidence ownership: this script rewrites `## 1. Commands` up to the
# `## 4. Cold-Context Review` sentinel and never touches sections 4, 5 or
# Overall Decision.
#
# Exit codes: 0 all executed rows passed and lint (when present) passed;
# 1 a row failed, a block was refused, or lint failed; 2 usage, missing
# plan, empty map, unresolved placeholder, invalid --scope, or missing ledger.
set -uo pipefail

CHANGE=""
SCOPE="all"
BASE=""
LEGACY=0
MODE=""
FINAL=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/onepress-verify.sh --change openspec/changes/<name> \
       [--scope files|package|all] [--base <ref>] [--legacy]
  bash scripts/onepress-verify.sh --change <name> --range
  bash scripts/onepress-verify.sh --change <name> --final --base <BASE_SHA>
  bash scripts/onepress-verify.sh --change <name> --churn

Runs the rows of plan.md's `## Evidence Map`, rewrites evidence sections 1-3,
and calls onepress-evidence-lint.sh when it is available. --range prints the
review span and regression surface; --churn fails when one file appears in
three or more ledger rounds.
EOF
}

err() { printf '[onepress-verify] %s\n' "$1" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --change) [ $# -ge 2 ] && [ -n "$2" ] || { err 'missing value for --change'; exit 2; }; CHANGE="$2"; shift 2 ;;
    --scope)  [ $# -ge 2 ] && [ -n "$2" ] || { err 'missing value for --scope'; exit 2; };  SCOPE="$2";  shift 2 ;;
    --base)   [ $# -ge 2 ] && [ -n "$2" ] || { err 'missing value for --base'; exit 2; };   BASE="$2";   shift 2 ;;
    --range)  MODE="range"; shift ;;
    --final)  MODE="range"; FINAL=1; shift ;;
    --churn)  MODE="churn"; shift ;;
    --legacy) LEGACY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

# 遥测埋点：任何退出路径都写 1 条事件；失败静默，不改变退出码。
_telemetry_on_exit() {
  local rc=$?
  local status=pass
  [ "$rc" -eq 0 ] || status=fail
  bash "${BASH_SOURCE[0]%/*}/onepress-telemetry.sh" emit verify.finish \
    --status "$status" --duration-ms "$((SECONDS * 1000))" >/dev/null 2>&1 || true
}
trap _telemetry_on_exit EXIT

[ -n "$CHANGE" ] || { usage >&2; exit 2; }
CHANGE="${CHANGE%/}"
[ -d "$CHANGE" ] || { err "change directory not found: $CHANGE"; exit 2; }

case "$SCOPE" in
  files|package|all) ;;
  *) err "invalid --scope '$SCOPE' (valid: files|package|all)"; exit 2 ;;
esac

LEDGER="$CHANGE/review-ledger.md"
ROOT="$(git -C "$CHANGE" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || ROOT="$(cd "$CHANGE" && pwd)"

ledger_field() {
  sed -n "s/^\*\*$1\*\*:[[:space:]]*\`\{0,1\}\([^\`]*\)\`\{0,1\}.*/\1/p" "$LEDGER" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//' | tr -d '\r'
}

# ledger_rows — emit "file<TAB>round<TAB>status" for each findings row
ledger_rows() {
  awk -F'|' '
    /^\|/ {
      if ($0 ~ /^\|[[:space:]]*:?-{3,}/) next
      if ($0 ~ /Fingerprint/) next
      file = $5; round = $6; status = $7
      gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", file)
      gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", round)
      gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", status)
      if (file == "" || round == "") next
      printf "%s\t%s\t%s\n", file, round, status
    }' "$LEDGER" 2>/dev/null
}

if [ "$MODE" = "range" ] || [ "$MODE" = "churn" ]; then
  if [ ! -f "$LEDGER" ]; then
    err "review-ledger.md not found in $CHANGE: --range/--churn need a ledger; --legacy only covers evidence collection for changes created before v8"
    exit 2
  fi
fi

if [ "$MODE" = "range" ]; then
  last="$(ledger_field last_reviewed_sha)"
  if [ "$FINAL" = 1 ]; then
    [ -n "$BASE" ] || { err "--final needs --base <BASE_SHA> to describe the full span"; exit 2; }
    printf 'full %s..HEAD\n' "$BASE"
  elif [ -z "$last" ] || [ "$last" = "none" ]; then
    err "last_reviewed_sha is '$last': pass --base <BASE_SHA>, or use --final on the round that declares PASS"
    exit 2
  else
    printf 'incremental %s..HEAD\n' "$last"
  fi
  surface="$(ledger_rows | awk -F'\t' '
    $3 == "fixed" {
      f = $1
      sub(/:[0-9]+(-[0-9]+)?$/, "", f)
      printf "%s\t%s\n", $2, f
    }' \
    | sort -t "$(printf '\t')" -k1,1nr \
    | awk -F'\t' '!seen[$1]++ { c++ } c <= 2 { print $2 }' | sort -u)"
  printf 'regression surface (%s files): %s\n' \
    "$(printf '%s' "$surface" | grep -c . || true)" \
    "$(printf '%s' "$surface" | tr '\n' ' ')"
  exit 0
fi

if [ "$MODE" = "churn" ]; then
  hot="$(ledger_rows | awk -F'\t' '{ f = $1; sub(/:[0-9]+(-[0-9]+)?$/, "", f); seen[f SUBSEP $2] = 1; file[f] = 1 }
    END {
      for (f in file) {
        n = 0; rounds = ""
        for (k in seen) { split(k, p, SUBSEP); if (p[1] == f) { n++; rounds = rounds (rounds == "" ? "" : ",") p[2] } }
        if (n >= 3) printf "%s\t%d\t%s\n", f, n, rounds
      }
    }' | sort)"
  if [ -n "$hot" ]; then
    while IFS=$'\t' read -r f n rounds; do
      err "churn: $f appears in $n rounds ($rounds); stop patching and rewrite the module with a boundary matrix"
    done <<< "$hot"
    exit 1
  fi
  printf 'churn: no file reaches 3 rounds\n'
  exit 0
fi

PLAN="$CHANGE/plan.md"
if [ ! -f "$PLAN" ]; then
  err "plan.md not found: $PLAN"
  exit 2
fi

# CRLF safety: plans authored on Windows must parse identically.
TEXT="$(tr -d '\r' < "$PLAN")"

MAP="$(printf '%s\n' "$TEXT" | awk '
  /^##[[:space:]]+Evidence Map[[:space:]]*$/ { f = 1; next }
  f && /^##[[:space:]]/ { exit }
  f { print }')"

if [ -z "$(printf '%s' "$MAP" | tr -d '[:space:]')" ]; then
  err "Evidence Map is empty or missing: add the table to plan.md and re-run"
  exit 2
fi

BAD_ROWS="$(printf '%s\n' "$MAP" | awk -F'|' 'NF > 5 { printf "%d ", NR }')"
if [ -n "$BAD_ROWS" ]; then
  err "Evidence Map row(s) $BAD_ROWS contain a raw '|' inside a cell; it splits the table and truncates the command. Escape or avoid pipes in the command column."
  exit 2
fi

ROWS="$(printf '%s\n' "$MAP" | awk -F'|' '
  /^\|/ {
    if ($0 ~ /^\|[[:space:]]*:?-{3,}/) next
    if ($0 ~ /Command that proves it/) next
    task = $2; cmd = $3; sig = $4
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", task)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", cmd)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", sig)
    # Strip only the wrapping backticks; inner ones belong to the command.
    sub(/^`/, "", task); sub(/`$/, "", task)
    sub(/^`/, "", cmd);  sub(/`$/, "", cmd)
    sub(/^`/, "", sig);  sub(/`$/, "", sig)
    if (cmd == "") next
    printf "%s\t%s\t%s\n", task, cmd, sig
  }')"

if [ -z "$ROWS" ]; then
  err "Evidence Map is empty: the table has no data rows"
  exit 2
fi

line_no=0
while IFS=$'\t' read -r task cmd sig; do
  [ -n "${task:-}" ] || continue
  line_no=$((line_no + 1))
  case "$cmd" in
    *'<exact command>'*|*'<'*'>'*)
      err "placeholder left in Evidence Map row $line_no ('$task'): replace '$cmd' with a real command"
      exit 2
      ;;
  esac
done <<< "$ROWS"

CHANGED=""
if [ "$SCOPE" = "files" ] || [ "$SCOPE" = "package" ]; then
  [ -n "$BASE" ] || BASE="HEAD"
  # Tracked changes plus untracked files: implementation work is usually
  # uncommitted while the evidence is collected.
  CHANGED="$(
    { git -C "$ROOT" diff --name-only "$BASE" 2>/dev/null || true
      git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null || true
    } | sed '/^$/d' | sort -u
  )"
  if [ -z "$CHANGED" ]; then
    err "no changed or untracked files against '$BASE' under $ROOT; pass --base <ref> or use --scope all"
    exit 2
  fi
  if [ "$SCOPE" = "package" ]; then
    PKG_PREFIX="$(printf '%s\n' "$CHANGED" | awk -F/ 'NF>1 { print $1"/"$2 }' | sed '/^$/d' | sort -u)"
    EXTRA=""
    for p in $PKG_PREFIX; do
      EXTRA="$EXTRA
$(git -C "$ROOT" ls-files -- "$p" 2>/dev/null || true)
$(git -C "$ROOT" ls-files --others --exclude-standard -- "$p" 2>/dev/null || true)"
    done
    CHANGED="$(printf '%s\n%s\n' "$CHANGED" "$EXTRA" | sed '/^$/d' | sort -u)"
  fi
fi

paths_of() {
  printf '%s' "$1" | grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,8}' || true
}

in_scope() {
  local cmd="$1" p
  for p in $(paths_of "$cmd"); do
    p="${p#./}"
    printf '%s\n' "$CHANGED" | grep -qxF -- "$p" && return 0
  done
  return 1
}

# counts_of <log> — the last "n passed / m failed" pair in a log, else n/a
counts_of() {
  local log="$1" p f
  [ -f "$log" ] || { printf 'n/a'; return; }
  p="$(grep -oE '[0-9]+ passed' "$log" 2>/dev/null | tail -1 | grep -oE '[0-9]+')"
  f="$(grep -oE '[0-9]+ failed' "$log" 2>/dev/null | tail -1 | grep -oE '[0-9]+')"
  if [ -n "$p" ] || [ -n "$f" ]; then
    printf '%s passed, %s failed' "${p:-0}" "${f:-0}"
  else
    printf 'n/a'
  fi
}

LOGDIR="$ROOT/temp/logs"
[ "${ONEPRESS_VERIFY_SKIP_LOG:-0}" = "1" ] || mkdir -p "$LOGDIR" 2>/dev/null || true

WORKDIR="$(mktemp -d 2>/dev/null || printf '%s' "$CHANGE/.verify-tmp")"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
RESULTS="$WORKDIR/results.tsv"
printf '' > "$RESULTS"

RUN=0; SKIP=0; FALLBACK=0; FAILED=0; EXIT_CODE=0
idx=0
printf 'onepress-verify: change=%s scope=%s base=%s\n' "$CHANGE" "$SCOPE" "${BASE:-none}"

while IFS=$'\t' read -r task cmd sig; do
  [ -n "${task:-}" ] || continue
  idx=$((idx + 1))

  FB=0
  if [ "$SCOPE" != "all" ]; then
    if [ -z "$(paths_of "$cmd")" ]; then
      FALLBACK=$((FALLBACK + 1))
      FB=1
      printf 'scope: fallback (no file path in command) — %s\n' "$task"
    elif ! in_scope "$cmd"; then
      SKIP=$((SKIP + 1))
      printf 'SKIP %s (out of scope)\n' "$task"
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$task" "$cmd" "SKIP" "-" "" >> "$RESULTS"
      continue
    fi
  fi

  label="$(printf '%s' "$task" | tr -c 'A-Za-z0-9_.-' '_' | sed 's/_*$//')"
  [ -n "$label" ] || label="row"
  log="$LOGDIR/${idx}-${label}.log"

  if [ "${ONEPRESS_VERIFY_SKIP_LOG:-0}" = "1" ]; then
    out="$( cd "$ROOT" && bash -c "$cmd" 2>&1 )"
    code=$?
    nlines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
    if [ "$nlines" -gt 40 ]; then
      err "refusing result block for '$task': $nlines lines without a log: path"
      EXIT_CODE=1
      printf 'REFUSED %s (%s lines, no log path)\n' "$task" "$nlines"
      continue
    fi
    printf '%s\n' "$out" > "$WORKDIR/${idx}.inline"
    logrel=""
  else
    ( cd "$ROOT" && bash -c "$cmd" ) >"$log" 2>&1
    code=$?
    logrel="${log#"$ROOT"/}"
  fi

  [ "$FB" = 1 ] || RUN=$((RUN + 1))
  status="PASS"
  if [ "$code" -ne 0 ]; then
    FAILED=$((FAILED + 1))
    EXIT_CODE=1
    status="FAIL"
  fi
  if [ "$FB" = 1 ]; then
    status="FALLBACK"
    printf 'RUN %s -> exit %s [scope fallback, not counted as a pass]%s\n' "$task" "$code" "${logrel:+ (log: $logrel)}"
  else
    printf 'RUN %s -> exit %s%s\n' "$task" "$code" "${logrel:+ (log: $logrel)}"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$idx" "$task" "$cmd" "$status" "$code" "$logrel" >> "$RESULTS"
done <<< "$ROWS"

printf 'summary: run=%d failed=%d skipped=%d fallback=%d\n' "$RUN" "$FAILED" "$SKIP" "$FALLBACK"

EVIDENCE="$CHANGE/verification-evidence.md"
SENTINEL='^##[[:space:]]+4\. Cold-Context Review[[:space:]]*$'

if [ -f "$EVIDENCE" ] && ! grep -qE "$SENTINEL" "$EVIDENCE"; then
  err "refusing to write: $EVIDENCE has no '## 4. Cold-Context Review' sentinel"
  exit 1
fi

# v8 header fields: backfill when the report predates the template change.
if [ -f "$EVIDENCE" ] && ! grep -q '^\*\*Validation Level\*\*:' "$EVIDENCE"; then
  HDR="$WORKDIR/header.md"
  {
    printf '**Change**: `%s`\n' "$(basename "$CHANGE")"
    printf '**Iteration**: `%s`\n' "$(ledger_field review_round 2>/dev/null | grep . || echo 1)"
    printf '**Review Round**: `0`\n'
    printf '**Reviewed Range**: `none (recorded by the reviewer)`\n'
    printf '**Ledger**: `review-ledger.md`\n'
    printf '**BASE_SHA**: `uncommitted (working tree)`\n'
    printf '**HEAD_SHA**: `working-tree`\n'
    printf '**Captured at**: `%s`\n' "$(date '+%Y-%m-%d %H:%M')"
    printf '**Environment**: `%s / %s`\n' "$(uname -s)" "$(bash --version | head -1 | awk '{print $4}')"
    printf '**Validation Level**: `strict`\n'
  } > "$HDR"
  awk -v hdr="$HDR" '
    NR == 1 { print; while ((getline line < hdr) > 0) print line; print ""; next }
    { print }
  ' "$EVIDENCE" > "$WORKDIR/withheader.md"
  mv "$WORKDIR/withheader.md" "$EVIDENCE"
fi

# pick_fence <file> — a backtick fence longer than any leading run in <file>,
# so a log line made of backticks cannot close the block early.
pick_fence() {
  local n
  n="$(awk '{ line = $0; sub(/[^`].*/, "", line); if (length(line) > m) m = length(line) } END { print m + 0 }' "$1")"
  if [ "$n" -lt 3 ]; then n=3; else n=$((n + 1)); fi
  awk -v n="$n" 'BEGIN { for (i = 0; i < n; i++) printf "`"; printf "\n" }'
}

# row_state <status> — single mapping from row status to the evidence table columns.
row_state() {
  case "$1" in
    SKIP) printf 'skipped' ;;
    *) printf 'ran' ;;
  esac
}

REGION="$WORKDIR/region.md"
{
  printf '## 1. Commands\n\n'
  printf '| # | Claim to prove | Command | Required? |\n|---|---|---|---|\n'
  awk -F'\t' '{ printf "| %s | `%s` | `%s` | `yes` |\n", $1, $2, $3 }' "$RESULTS"
  printf '\n## 2. Fresh Command Results\n\n'
  while IFS=$'\t' read -r i task cmd status code logrel; do
    if [ "$status" = "SKIP" ]; then
      printf '### 2.%s %s\n\n```text\n$ %s\nskipped: out of scope\nexit code: not run\n```\n\n' "$i" "$task" "$cmd"
      continue
    fi
    if [ -n "$logrel" ] && [ -f "$ROOT/$logrel" ]; then src="$ROOT/$logrel"; else src="$WORKDIR/$i.inline"; fi
    EXCERPT="$WORKDIR/$i.excerpt"
    {
      printf '$ %s\n' "$cmd"
      [ -f "$src" ] && tail -n 15 "$src" | cut -c1-200
      printf 'counts: %s\n' "$(counts_of "$src")"
      [ -n "$logrel" ] && printf 'log: %s\n' "$logrel"
      printf 'exit code: %s\n' "$code"
    } > "$EXCERPT"
    fence="$(pick_fence "$EXCERPT")"
    printf '### 2.%s %s\n\n%stext\n' "$i" "$task" "$fence"
    cat "$EXCERPT"
    printf '%s\n\n' "$fence"
  done < "$RESULTS"
  printf '## 3. Evidence Table\n\n'
  printf '| # | Command | Exit code | Pass / fail counts | Run at | Fresh? |\n|---|---|---|---|---|---|\n'
  now="$(date +%H:%M)"
  while IFS=$'\t' read -r i task cmd status code logrel; do
    if [ "$(row_state "$status")" = "skipped" ]; then
      printf '| %s | `%s` | `—` | `skipped (out of scope)` | `n/a` | `no` |\n' "$i" "$cmd"
      continue
    fi
    if [ -n "$logrel" ] && [ -f "$ROOT/$logrel" ]; then counts="$(counts_of "$ROOT/$logrel")"
    elif [ -f "$WORKDIR/$i.inline" ]; then counts="$(counts_of "$WORKDIR/$i.inline")"
    else counts="n/a"
    fi
    printf '| %s | `%s` | `%s` | `%s` | `%s` | `yes` |\n' "$i" "$cmd" "$code" "$counts" "$now"
  done < "$RESULTS"
} > "$REGION"

if [ -f "$EVIDENCE" ]; then
  if grep -qE '^##[[:space:]]+1\. Commands[[:space:]]*$' "$EVIDENCE"; then
    awk -v region="$REGION" '
      BEGIN { while ((getline line < region) > 0) R = R line "\n" }
      /^##[[:space:]]+1\. Commands[[:space:]]*$/ { printf "%s", R; skip = 1; next }
      skip && /^##[[:space:]]+4\. Cold-Context Review[[:space:]]*$/ { skip = 0 }
      skip { next }
      { print }
    ' "$EVIDENCE" > "$WORKDIR/new.md"
  else
    awk -v region="$REGION" '
      BEGIN { while ((getline line < region) > 0) R = R line "\n" }
      /^##[[:space:]]+4\. Cold-Context Review[[:space:]]*$/ && !done { printf "%s\n", R; done = 1 }
      { print }
    ' "$EVIDENCE" > "$WORKDIR/new.md"
  fi
  mv "$WORKDIR/new.md" "$EVIDENCE"
else
  {
    printf '# Verification Evidence — `%s`\n\n' "$(basename "$CHANGE")"
    printf '**Change**: `%s`\n' "$(basename "$CHANGE")"
    printf '**Iteration**: `%s`\n' "$(ledger_field review_round 2>/dev/null | grep . || echo 1)"
    printf '**Review Round**: `0`\n'
    printf '**Reviewed Range**: `none (recorded by the reviewer)`\n'
    printf '**Ledger**: `review-ledger.md`\n'
    printf '**BASE_SHA**: `uncommitted (working tree)`\n'
    printf '**HEAD_SHA**: `working-tree`\n'
    printf '**Captured at**: `%s`\n' "$(date '+%Y-%m-%d %H:%M')"
    printf '**Environment**: `%s / %s`\n' "$(uname -s)" "$(bash --version | head -1 | awk '{print $4}')"
    printf '**Validation Level**: `strict`\n\n'
    cat "$REGION"
    printf '\n## 4. Cold-Context Review\n\n- **Mode**: `subagent`\n- **Critical**: `0`\n- **Important**: `0`\n- **Debatable**: `0`\n- **Minor**: `0`\n'
    printf '\n## 5. Spec Coverage and Task Completion\n\n- **Tasks**: `0` of `0` complete\n'
    printf '\n## Overall Decision\n\n- [ ] PASS\n- [ ] FAIL\n'
  } > "$EVIDENCE"
fi

LINT=""
for candidate in "$ROOT/scripts/onepress-evidence-lint.sh" "$ROOT/pack/scripts/onepress-evidence-lint.sh"; do
  if [ -f "$candidate" ]; then LINT="$candidate"; break; fi
done
if [ -n "$LINT" ]; then
  if bash "$LINT" --change "$CHANGE" >/dev/null 2>&1; then
    printf 'lint: pass\n'
  else
    printf 'lint: FAIL (evidence report not yet complete)\n'
    EXIT_CODE=1
  fi
else
  printf 'lint: skipped (onepress-evidence-lint.sh not found)\n'
fi

if [ "$LEGACY" = 1 ] && [ ! -f "$LEDGER" ]; then
  printf 'ledger: absent (legacy)\n'
fi

[ -d "$WORKDIR" ] && rm -rf "$WORKDIR"
exit "$EXIT_CODE"
