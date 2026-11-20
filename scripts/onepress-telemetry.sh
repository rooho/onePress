#!/usr/bin/env bash
# onepress-telemetry.sh — onePress 本地遥测（M1 基线）
#
#   bash scripts/onepress-telemetry.sh <subcommand> [args]
#
# 子命令：
#   emit <event> [--status <s>] [--step <name>] [--payload <json>] [--no-telemetry]
#   step <start|finish> <name> [--status <s>]
#   report [--format md|json] [--since <date>]
#   show [--last <n>]
#   prune [--keep 12m]
#   status
#   export --format otlp-json --out <file>
#
# 默认零网络、仅本地 JSONL（~/.onepress/telemetry/YYYY-MM.jsonl）。
# 测试接缝：ONEPRESS_TELEMETRY_NOW 覆盖当前时间，ONEPRESS_SESSION_ID 透传会话标识。
# 退出码：0 成功；2 参数或子命令错误。

set -uo pipefail

TELEMETRY_V=1
LINE_LIMIT=1800
MAX_BYTES=5242880
DEFAULT_KEEP_MONTHS=12
SUBCOMMANDS="emit step report show prune status export"
# 稳定事件目录（M1）：未知事件名必须拒绝，避免指标被脏名字污染。
EVENT_CATALOG="install.start install.finish gate.finish evidence.finish verify.finish step.start step.finish"

# payload 白名单：只允许元数据类标量字段。
PAYLOAD_KEYS="gate change harness mode scope stage round passed failed skipped total ok rate"

# heuristic_v1 加权参数：ASCII 每 4 B 一个 token，CJK 每 3 B（即每字）一个，标点每 2 B 一个。
TOKEN_ASCII_BYTES=4
TOKEN_CJK_BYTES=3
TOKEN_PUNCT_BYTES=2

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STORAGE_DIR="$HOME/.onepress"
TELEMETRY_DIR="$STORAGE_DIR/telemetry"
SPOOL_DIR="$TELEMETRY_DIR/spool"

ENVELOPE_MONTH=""
ENVELOPE_LINE=""
TELEMETRY_FLAG=0
TOKEN_IN_JSON="null"
TOKEN_OUT_JSON="null"
TOKEN_METHOD_JSON="null"
CURRENT_ROUND=""

usage() {
  cat <<'EOF'
Usage:
  bash scripts/onepress-telemetry.sh emit <event> [--status <s>] [--step <name>]
       [--payload <json>] [--duration-ms <n>] [--no-telemetry]
  bash scripts/onepress-telemetry.sh step <start|finish> <name> [--status <s>]
  bash scripts/onepress-telemetry.sh report [--format md|json] [--since <date>]
  bash scripts/onepress-telemetry.sh show [--last <n>]
  bash scripts/onepress-telemetry.sh prune [--keep 12m]
  bash scripts/onepress-telemetry.sh status
  bash scripts/onepress-telemetry.sh export --format otlp-json --out <file>
EOF
  printf '\nSubcommands: %s\n' "$SUBCOMMANDS"
}

is_subcommand() {
  case " $SUBCOMMANDS " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

is_event_name() {
  case " $EVENT_CATALOG " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# dispatch <sub> [args] —— 子命令注册表即 SUBCOMMANDS，实现函数名为 cmd_<sub>。
dispatch() {
  local sub="$1"
  shift
  if ! is_subcommand "$sub"; then
    printf 'unknown subcommand: %s\n' "$sub" >&2
    usage >&2
    return 2
  fi
  "cmd_$sub" "$@"
}

# ---------- 基础工具 ----------

# json_escape <text> —— 去控制字符并转义反斜杠与双引号。
json_escape() {
  printf '%s' "$1" | tr -d '\r\n\t' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

byte_len() {
  printf '%s' "$1" | wc -c | tr -d ' '
}

sha256_hex() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | cut -d' ' -f1
  else
    openssl dgst -sha256 | sed 's/^.*= //'
  fi
}

rand_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$1"
  else
    od -An -tx1 -N "$1" /dev/urandom | tr -d ' \n'
  fi
}

uuid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then
    tr 'A-Z' 'a-z' < /proc/sys/kernel/random/uuid | tr -d '\r\n'
  elif command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr 'A-Z' 'a-z'
  else
    local h
    h="$(rand_hex 16)"
    printf '%s-%s-%s-%s-%s\n' "${h:0:8}" "${h:8:4}" "${h:12:4}" "${h:16:4}" "${h:20:12}"
  fi
}

onepress_version() {
  local v=""
  if [ -f "$ROOT/VERSION" ]; then
    v="$(head -n 1 "$ROOT/VERSION" | tr -d '\r\n')"
  fi
  [ -n "$v" ] || v="unknown"
  printf '%s\n' "$v"
}

now_ts() {
  if [ -n "${ONEPRESS_TELEMETRY_NOW:-}" ]; then
    printf '%s\n' "$ONEPRESS_TELEMETRY_NOW"
  else
    date +%Y-%m-%dT%H:%M:%S%z
  fi
}

# normalize_ts <ts> —— 把 +0800 形式补成 +08:00，其余原样返回。
normalize_ts() {
  case "$1" in
    ????-??-??T??:??:??[+-][0-9][0-9][0-9][0-9])
      local head="" off=""
      head="${1%?????}"
      off="${1#"$head"}"
      printf '%s%s:%s\n' "$head" "${off%??}" "${off#???}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# ts_month <ts> —— 从 ISO 时间取 YYYY-MM；无法识别时返回 1（调用方静默放弃）。
ts_month() {
  case "$1" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*)
      printf '%s\n' "${1:0:7}" ;;
    *) return 1 ;;
  esac
}

# ---------- 匿名标识 ----------

ensure_install_id() {
  local f="$STORAGE_DIR/install_id" id=""
  if [ -s "$f" ]; then
    id="$(tr -d '\r\n' < "$f")"
    printf '%s\n' "$id"
    return 0
  fi
  mkdir -p "$STORAGE_DIR" 2>/dev/null || return 1
  id="$(uuid)"
  [ -n "$id" ] || return 1
  printf '%s\n' "$id" > "$f" 2>/dev/null || return 1
  printf '%s\n' "$id"
}

ensure_salt() {
  local f="$STORAGE_DIR/salt" salt=""
  if [ -s "$f" ]; then
    salt="$(tr -d '\r\n' < "$f")"
    printf '%s\n' "$salt"
    return 0
  fi
  mkdir -p "$STORAGE_DIR" 2>/dev/null || return 1
  salt="$(rand_hex 32)"
  [ -n "$salt" ] || return 1
  printf '%s\n' "$salt" > "$f" 2>/dev/null || return 1
  printf '%s\n' "$salt"
}

project_id() {
  local salt=""
  salt="$(ensure_salt)" || return 1
  printf '%s:%s' "$salt" "$(pwd -P)" | sha256_hex | cut -c1-12
}

# ---------- Token 估算 ----------

# estimate_tokens <text> —— heuristic_v1：按 ASCII / CJK / 标点字节加权，零外部依赖。
estimate_tokens() {
  local text="$1" total="0" cjk_bytes="0" punct_bytes="0" ascii_bytes="0"
  total="$(printf '%s' "$text" | wc -c | tr -d ' ')"
  if [ "$total" -le 0 ]; then
    printf '0'
    return 0
  fi
  cjk_bytes="$(printf '%s' "$text" | LC_ALL=C tr -d '\000-\177' | wc -c | tr -d ' ')"
  punct_bytes="$(printf '%s' "$text" | LC_ALL=C tr -cd '[:punct:]' | wc -c | tr -d ' ')"
  ascii_bytes=$((total - cjk_bytes - punct_bytes))
  [ "$ascii_bytes" -ge 0 ] || ascii_bytes=0
  printf '%s' $((ascii_bytes / TOKEN_ASCII_BYTES + cjk_bytes / TOKEN_CJK_BYTES + punct_bytes / TOKEN_PUNCT_BYTES + 1))
}

# resolve_token <raw> <method> —— 返回 token 估算的 JSON 字面量。
resolve_token() {
  local raw="$1" method="$2"
  if [ -z "$raw" ]; then
    printf 'null'
    return 0
  fi
  if [ "$method" = "harness_native" ]; then
    case "$raw" in
      ''|*[!0-9]*) printf 'null' ;;
      *) printf '%s' "$raw" ;;
    esac
    return 0
  fi
  estimate_tokens "$raw"
}

# ---------- 关闭开关 ----------

# disabled_reason —— 按优先级返回关闭来源，开启时返回空串。
# 优先级：--no-telemetry > ONEPRESS_TELEMETRY=off > DO_NOT_TRACK=1 > CI=true|1。
# 显式 ONEPRESS_TELEMETRY=on 压过 DO_NOT_TRACK 与 CI。
disabled_reason() {
  if [ "$TELEMETRY_FLAG" = "1" ]; then
    printf 'flag'
    return 0
  fi
  case "${ONEPRESS_TELEMETRY:-}" in
    off|false|0) printf 'env'; return 0 ;;
    on|true|1)   printf '';    return 0 ;;
  esac
  case "${DO_NOT_TRACK:-}" in
    1|true) printf 'dnt'; return 0 ;;
  esac
  case "${CI:-}" in
    true|1) printf 'ci'; return 0 ;;
  esac
  printf ''
}

# ---------- 分片与轮转 ----------

# shard_files —— 按时间升序列出分片（YYYY-MM.jsonl 为当月最新，YYYY-MM.NNN.jsonl 为历史封存）。
shard_files() {
  [ -d "$TELEMETRY_DIR" ] || return 0
  ls -1 "$TELEMETRY_DIR" 2>/dev/null | LC_ALL=C sort | while IFS= read -r name; do
    case "$name" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9].jsonl|[0-9][0-9][0-9][0-9]-[0-9][0-9].[0-9][0-9][0-9].jsonl)
        printf '%s/%s\n' "$TELEMETRY_DIR" "$name" ;;
    esac
  done
}

# rotate_if_needed <YYYY-MM> —— 当月分片超 5 MB 时封存为下一个 NNN 序号，不动历史分片。
rotate_if_needed() {
  local month="$1" base="" n=1 shard=""
  base="$TELEMETRY_DIR/$month.jsonl"
  [ -f "$base" ] || return 0
  [ "$(wc -c < "$base" | tr -d ' ')" -gt "$MAX_BYTES" ] || return 0
  while :; do
    shard="$TELEMETRY_DIR/$month.$(printf '%03d' "$n").jsonl"
    [ -f "$shard" ] || break
    n=$((n + 1))
  done
  mv "$base" "$shard" 2>/dev/null || return 0
  return 0
}

# month_index <YYYY-MM> —— 转为可比较的月份序号。
month_index() {
  local month="$1" y="" m=""
  case "$month" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]) ;;
    *) return 1 ;;
  esac
  y="${month%%-*}"
  m="${month#*-}"
  m="${m#0}"
  [ -n "$m" ] || m=0
  printf '%s' $((y * 12 + m - 1))
}

# ---------- 信封 ----------

# filter_payload <json> —— 按白名单裁剪 payload：未知键、嵌套对象、含路径的值一律丢弃。
# 纯 awk 实现，不依赖 jq；嵌套结构整段丢弃而非展开，保证输出保持合法 JSON。
filter_payload() {
  printf '%s' "$1" | awk -v wl="$PAYLOAD_KEYS" '
    function emit_pair(p,   i, k, v, key) {
      if (p == "") return
      i = index(p, ":")
      if (i == 0) return
      k = substr(p, 1, i - 1)
      v = substr(p, i + 1)
      gsub(/^[ \t]+/, "", k); gsub(/[ \t]+$/, "", k)
      gsub(/^[ \t]+/, "", v); gsub(/[ \t]+$/, "", v)
      key = k
      gsub(/"/, "", key)
      if (!(key in allowed)) return
      if (v ~ /[\[\{]/) return
      if (v ~ /\//) return
      if (out != "") out = out ","
      out = out "\"" key "\":" v
    }
    BEGIN {
      n = split(wl, wk, " ")
      for (i = 1; i <= n; i++) allowed[wk[i]] = 1
      depth = 0; instr = 0; esc = 0; pair = ""; out = ""
    }
    {
      line = $0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (instr) {
          pair = pair c
          if (esc) esc = 0
          else if (c == "\\") esc = 1
          else if (c == "\"") instr = 0
          continue
        }
        if (c == "\"") { instr = 1; pair = pair c; continue }
        if (c == "{") { depth++; if (depth > 1) pair = pair c; continue }
        if (c == "[") { if (depth >= 1) pair = pair c; depth++; continue }
        if (c == "]") { if (depth > 1) pair = pair c; depth--; continue }
        if (c == "}") {
          if (depth == 1) { emit_pair(pair); pair = "" }
          else if (depth > 1) pair = pair c
          depth--
          continue
        }
        if (c == "," && depth == 1) { emit_pair(pair); pair = ""; continue }
        if (depth >= 1) pair = pair c
      }
    }
    END { if (out != "") printf "{%s}", out }
  '
}

# build_envelope <event> <status> [step] [duration_ms] [payload]
# 成功时把单行 JSON 写入 $ENVELOPE_LINE、分片月份写入 $ENVELOPE_MONTH。
# 不用命令替换：子 shell 会丢掉这两个全局变量。
build_envelope() {
  local event="$1" status="${2:-unknown}" step="${3:-}" duration="${4:-}" payload="${5:-}"
  local ts="" month="" install_id="" pid="" session_json="null" base="" extra="" line=""
  ts="$(normalize_ts "$(now_ts)")"
  month="$(ts_month "$ts")" || return 1
  install_id="$(ensure_install_id)" || return 1
  pid="$(project_id)" || return 1
  if [ -n "${ONEPRESS_SESSION_ID:-}" ]; then
    session_json="\"$(json_escape "$ONEPRESS_SESSION_ID")\""
  fi
  case "$duration" in
    ''|*[!0-9]*) duration="" ;;
  esac
  [ -n "$step" ] && extra="$extra,\"step\":\"$(json_escape "$step")\""
  [ -n "$duration" ] && extra="$extra,\"duration_ms\":$duration"
  [ -n "$CURRENT_ROUND" ] && extra="$extra,\"round\":$CURRENT_ROUND"
  base="$(printf '{"telemetry_v":%s,"event":"%s","ts":"%s","install_id":"%s","project_id":"%s","session_id":%s,"onepress":"%s","status":"%s","token_in_est":%s,"token_out_est":%s,"token_est_method":%s' \
    "$TELEMETRY_V" "$(json_escape "$event")" "$ts" "$install_id" "$pid" \
    "$session_json" "$(onepress_version)" "$(json_escape "$status")" \
    "$TOKEN_IN_JSON" "$TOKEN_OUT_JSON" "$TOKEN_METHOD_JSON")"
  # 单行硬上限：能整体放下才写 payload，否则丢弃 payload 并标 truncated。
  if [ -n "$payload" ]; then
    payload="$(filter_payload "$payload")"
  fi
  if [ -n "$payload" ]; then
    if [ "$(byte_len "$base$extra,\"payload\":$payload}")" -le "$LINE_LIMIT" ]; then
      extra="$extra,\"payload\":$payload"
    else
      extra="$extra,\"truncated\":true"
    fi
  fi
  line="$base$extra}"
  if [ "$(byte_len "$line")" -gt "$LINE_LIMIT" ]; then
    line="$base,\"truncated\":true}"
  fi
  ENVELOPE_MONTH="$month"
  ENVELOPE_LINE="$line"
  return 0
}

# emit_event <event> <status> [step] [duration_ms] [payload]
# 任何写入失败都静默返回 0：遥测 MUST NOT 阻断主流程。
emit_event() {
  local reason=""
  reason="$(disabled_reason)"
  [ -z "$reason" ] || return 0
  build_envelope "$@" || return 0
  [ -n "$ENVELOPE_LINE" ] || return 0
  [ -n "$ENVELOPE_MONTH" ] || return 0
  mkdir -p "$TELEMETRY_DIR" 2>/dev/null || return 0
  [ -w "$TELEMETRY_DIR" ] || return 0
  rotate_if_needed "$ENVELOPE_MONTH"
  printf '%s\n' "$ENVELOPE_LINE" >> "$TELEMETRY_DIR/$ENVELOPE_MONTH.jsonl" 2>/dev/null || return 0
  return 0
}

# ---------- 子命令 ----------

cmd_emit() {
  local event="" status="unknown" step="" duration="" payload="" round=""
  local token_in="" token_out="" token_method="heuristic_v1"
  TOKEN_IN_JSON="null"
  TOKEN_OUT_JSON="null"
  TOKEN_METHOD_JSON="null"
  CURRENT_ROUND=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --status)      status="${2:-}"; shift 2 ;;
      --step)        step="${2:-}"; shift 2 ;;
      --round)       round="${2:-}"; shift 2 ;;
      --duration-ms) duration="${2:-}"; shift 2 ;;
      --payload)     payload="${2:-}"; shift 2 ;;
      --token-in)    token_in="${2:-}"; shift 2 ;;
      --token-out)   token_out="${2:-}"; shift 2 ;;
      --token-method) token_method="${2:-}"; shift 2 ;;
      --no-telemetry) shift ;;
      -h|--help) usage; return 0 ;;
      -*) printf 'emit: unknown option: %s\n' "$1" >&2; return 2 ;;
      *) event="$1"; shift ;;
    esac
  done
  case "$round" in
    ''|*[!0-9]*) round="" ;;
  esac
  CURRENT_ROUND="$round"
  if [ -z "$event" ]; then
    printf 'emit: missing event name\n' >&2
    usage >&2
    return 2
  fi
  if ! is_event_name "$event"; then
    printf 'emit: unknown event: %s\n' "$event" >&2
    printf 'emit: legal events: %s\n' "$EVENT_CATALOG" >&2
    return 2
  fi
  if [ -n "$token_in" ] || [ -n "$token_out" ]; then
    TOKEN_IN_JSON="$(resolve_token "$token_in" "$token_method")"
    TOKEN_OUT_JSON="$(resolve_token "$token_out" "$token_method")"
    if [ "$token_method" = "harness_native" ]; then
      TOKEN_METHOD_JSON="\"harness_native\""
    else
      TOKEN_METHOD_JSON="\"heuristic_v1\""
    fi
  fi
  emit_event "$event" "$status" "$step" "$duration" "$payload"
}

cmd_step() {
  local phase="${1:-}" name="${2:-}"
  [ $# -ge 2 ] && shift 2
  case "$phase" in
    start|finish) ;;
    *) printf 'step: expected start|finish\n' >&2; return 2 ;;
  esac
  if [ -z "$name" ]; then
    printf 'step: missing step name\n' >&2
    return 2
  fi
  cmd_emit "step.$phase" --step "$name" "$@"
}

# ---------- 聚合 ----------

# all_main_lines —— 按时间序输出全部分片内容。
all_main_lines() {
  local f=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    cat "$f"
  done <<EOF
$(shard_files)
EOF
}

# spool_lines —— 输出 spool 目录下所有未合并的事件。
spool_lines() {
  [ -d "$SPOOL_DIR" ] || return 0
  local f=""
  for f in "$SPOOL_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    cat "$f"
  done
}

# event_key —— 从 stdin 事件行提取去重键 install_id|ts|event|step。
event_key() {
  awk '
    function key(line,   id, ts, ev, st) {
      id = ""; ts = ""; ev = ""; st = ""
      if (match(line, /"install_id":"[^"]*"/)) id = substr(line, RSTART + 14, RLENGTH - 15)
      if (match(line, /"ts":"[^"]*"/)) ts = substr(line, RSTART + 6, RLENGTH - 7)
      if (match(line, /"event":"[^"]*"/)) ev = substr(line, RSTART + 9, RLENGTH - 10)
      if (match(line, /"step":"[^"]*"/)) st = substr(line, RSTART + 8, RLENGTH - 9)
      return id "|" ts "|" ev "|" st
    }
    { print key($0) }'
}

# dedupe_by_key —— 按去重键只保留首次出现的事件行。
dedupe_by_key() {
  awk '
    function key(line,   id, ts, ev, st) {
      id = ""; ts = ""; ev = ""; st = ""
      if (match(line, /"install_id":"[^"]*"/)) id = substr(line, RSTART + 14, RLENGTH - 15)
      if (match(line, /"ts":"[^"]*"/)) ts = substr(line, RSTART + 6, RLENGTH - 7)
      if (match(line, /"event":"[^"]*"/)) ev = substr(line, RSTART + 9, RLENGTH - 10)
      if (match(line, /"step":"[^"]*"/)) st = substr(line, RSTART + 8, RLENGTH - 9)
      return id "|" ts "|" ev "|" st
    }
    {
      k = key($0)
      if (k in seen) next
      seen[k] = 1
      print
    }'
}

# line_month <line> —— 从事件行取 YYYY-MM。
line_month() {
  local ts=""
  ts="$(printf '%s\n' "$1" | awk '{ if (match($0, /"ts":"[^"]+"/)) print substr($0, RSTART + 6, RLENGTH - 7) }')"
  [ -n "$ts" ] || return 1
  ts_month "$ts"
}

# compact_spool —— 把 spool 事件合并进对应月分片（按去重键去重），成功后清空 spool。
compact_spool() {
  [ -d "$SPOOL_DIR" ] || return 0
  local keyfile="$TELEMETRY_DIR/.spool-keys" f="" line="" key="" month=""
  : > "$keyfile" 2>/dev/null || return 0
  all_main_lines | event_key | sort -u > "$keyfile" 2>/dev/null || return 0
  for f in "$SPOOL_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      key="$(printf '%s\n' "$line" | event_key)"
      [ -n "$key" ] || continue
      if grep -Fxq "$key" "$keyfile" 2>/dev/null; then continue; fi
      printf '%s\n' "$key" >> "$keyfile"
      month="$(line_month "$line")" || continue
      printf '%s\n' "$line" >> "$TELEMETRY_DIR/$month.jsonl" 2>/dev/null || true
    done < "$f"
    rm -f "$f"
  done
  rm -f "$keyfile"
  rmdir "$SPOOL_DIR" 2>/dev/null || true
  return 0
}

# report_events <since> —— 输出通过 since 过滤的本地事件行（spool 合并见 2.11）。
report_events() {
  local since="$1"
  {
    all_main_lines
    spool_lines
  } | dedupe_by_key | awk -v since="$since" '
      {
        if (since != "") {
          if (!match($0, /"ts":"[^"]+"/)) next
          ts = substr($0, RSTART + 6, RLENGTH - 7)
          if (ts < since) next
        }
        print
      }'
}

# report_metrics —— 从 stdin 事件行聚合 M1 指标，每行输出「键 值」。
# M2 指标（冷审轮次 / churn / TDD 覆盖率）不在此计算，由调用方输出 n/a (M2)。
report_metrics() {
  awk '
    function pct(k, n) {
      if (n == 0) return "null"
      return sprintf("%.1f", k * 100 / n)
    }
    {
      ev = ""; st = ""; rd = ""
      if (match($0, /"event":"[^"]*"/)) ev = substr($0, RSTART + 9, RLENGTH - 10)
      if (match($0, /"status":"[^"]*"/)) st = substr($0, RSTART + 10, RLENGTH - 11)
      if (match($0, /"round":[0-9]+/)) rd = substr($0, RSTART + 8, RLENGTH - 8)
      total++
      if (ev == "install.finish") { ni++; if (st == "pass") ni_ok++ }
      else if (ev == "gate.finish") { ng++; if (st != "pass") ng_bad++ }
      else if (ev == "evidence.finish" && rd == "1") { ne++; if (st == "pass") ne_ok++ }
      else if (ev == "step.finish" && match($0, /"duration_ms":[0-9]+/)) {
        d[++nd] = substr($0, RSTART + 14, RLENGTH - 14) + 0
      }
    }
    END {
      for (i = 2; i <= nd; i++) {
        v = d[i]; j = i - 1
        while (j >= 1 && d[j] > v) { d[j + 1] = d[j]; j-- }
        d[j + 1] = v
      }
      p50 = "null"; p90 = "null"
      if (nd > 0) {
        if (nd % 2 == 1) p50 = sprintf("%.1f", d[(nd + 1) / 2])
        else p50 = sprintf("%.1f", (d[nd / 2] + d[nd / 2 + 1]) / 2)
        idx = int((9 * nd + 9) / 10)
        if (idx < 1) idx = 1
        if (idx > nd) idx = nd
        p90 = sprintf("%.1f", d[idx])
      }
      printf "events %d\ninstall_finish %d\ngate_finish %d\nevidence_finish_round1 %d\nstep_finish %d\ninstall_success_rate %s\ngate_failure_rate %s\nevidence_first_pass_rate %s\nstep_duration_p50_ms %s\nstep_duration_p90_ms %s\n", \
        total, ni, ng, ne, nd, pct(ni_ok, ni), pct(ng_bad, ng), pct(ne_ok, ne), p50, p90
    }'
}

cmd_report() {
  local format="md" since="" key="" val=""
  local r_events=0 r_install=0 r_gate=0 r_evidence=0 r_step=0
  local r_install_rate="null" r_gate_rate="null" r_evidence_rate="null"
  local r_p50="null" r_p90="null" since_json="null"
  while [ $# -gt 0 ]; do
    case "$1" in
      --format) format="${2:-}"; shift 2 ;;
      --since)  since="${2:-}"; shift 2 ;;
      -h|--help) usage; return 0 ;;
      *) printf 'report: unknown option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  case "$format" in
    md|json) ;;
    *) printf 'report: expected --format md|json\n' >&2; return 2 ;;
  esac
  if [ -n "$since" ]; then
    since_json="\"$(json_escape "$since")\""
  fi
  while read -r key val; do
    [ -n "$key" ] || continue
    case "$key" in
      events)                  r_events="$val" ;;
      install_finish)          r_install="$val" ;;
      gate_finish)             r_gate="$val" ;;
      evidence_finish_round1)  r_evidence="$val" ;;
      step_finish)             r_step="$val" ;;
      install_success_rate)    r_install_rate="$val" ;;
      gate_failure_rate)       r_gate_rate="$val" ;;
      evidence_first_pass_rate) r_evidence_rate="$val" ;;
      step_duration_p50_ms)    r_p50="$val" ;;
      step_duration_p90_ms)    r_p90="$val" ;;
    esac
  done <<EOF
$(report_events "$since" | report_metrics)
EOF
  if [ "$format" = "json" ]; then
    printf '{\n'
    printf '  "events": %s,\n' "$r_events"
    printf '  "since": %s,\n' "$since_json"
    printf '  "counts": {\n'
    printf '    "install_finish": %s,\n' "$r_install"
    printf '    "gate_finish": %s,\n' "$r_gate"
    printf '    "evidence_finish_round1": %s,\n' "$r_evidence"
    printf '    "step_finish": %s\n' "$r_step"
    printf '  },\n'
    printf '  "install_success_rate": %s,\n' "$r_install_rate"
    printf '  "gate_failure_rate": %s,\n' "$r_gate_rate"
    printf '  "evidence_first_pass_rate": %s,\n' "$r_evidence_rate"
    printf '  "step_duration_p50_ms": %s,\n' "$r_p50"
    printf '  "step_duration_p90_ms": %s,\n' "$r_p90"
    printf '  "review_rounds": null,\n'
    printf '  "churn_rate": null,\n'
    printf '  "tdd_coverage": null,\n'
    printf '  "m2_metrics": "n/a (M2)"\n'
    printf '}\n'
  else
    printf '# onePress telemetry report\n\n'
    printf '| 指标 | 值 |\n|---|---|\n'
    printf '| 事件总数 | %s |\n' "$r_events"
    printf '| 安装成功数 / 总数 | %s%% / %s |\n' "$r_install_rate" "$r_install"
    printf '| 门禁失败率 | %s%% |\n' "$r_gate_rate"
    printf '| 证据首轮通过率 | %s%% |\n' "$r_evidence_rate"
    printf '| 步骤耗时 p50 | %s ms |\n' "$r_p50"
    printf '| 步骤耗时 p90 | %s ms |\n' "$r_p90"
    printf '| 冷审轮次 | n/a (M2) |\n'
    printf '| churn | n/a (M2) |\n'
    printf '| TDD 覆盖率 | n/a (M2) |\n'
  fi
  return 0
}

cmd_show() {
  local last=20 f=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --last) last="${2:-}"; shift 2 ;;
      -h|--help) usage; return 0 ;;
      *) printf 'show: unknown option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  case "$last" in
    ''|*[!0-9]*) printf 'show: --last expects a positive integer\n' >&2; return 2 ;;
  esac
  [ "$last" -gt 0 ] || { printf 'show: --last expects a positive integer\n' >&2; return 2; }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    cat "$f"
  done <<EOF | tail -n "$last"
$(shard_files)
EOF
  return 0
}

cmd_prune() {
  local keep="${DEFAULT_KEEP_MONTHS}m" months="" current_idx=0 cutoff=0 f="" name="" idx=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --keep) keep="${2:-}"; shift 2 ;;
      -h|--help) usage; return 0 ;;
      *) printf 'prune: unknown option: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  case "$keep" in
    *m) months="${keep%m}" ;;
    *) months="" ;;
  esac
  case "$months" in
    ''|*[!0-9]*) printf 'prune: --keep expects <n>m\n' >&2; return 2 ;;
  esac
  [ "$months" -gt 0 ] || { printf 'prune: --keep expects <n>m\n' >&2; return 2; }
  current_idx="$(month_index "$(ts_month "$(normalize_ts "$(now_ts)")")")" || return 0
  cutoff=$((current_idx - months + 1))
  compact_spool
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    name="${f##*/}"
    idx="$(month_index "${name:0:7}")" || continue
    if [ "$idx" -lt "$cutoff" ]; then rm -f "$f"; fi
  done <<EOF
$(shard_files)
EOF
  return 0
}

cmd_status() {
  local reason=""
  reason="$(disabled_reason)"
  if [ -n "$reason" ]; then
    printf 'telemetry: disabled (%s)\n' "$reason"
  else
    printf 'telemetry: enabled\n'
  fi
  return 0
}

cmd_export() { return 0; }

main() {
  local sub="${1:-}" arg=""
  for arg in "$@"; do
    if [ "$arg" = "--no-telemetry" ]; then TELEMETRY_FLAG=1; fi
  done
  case "$sub" in
    -h|--help|help) usage; return 0 ;;
    "") usage >&2; return 2 ;;
    *) dispatch "$@" ;;
  esac
}

main "$@"
exit $?
