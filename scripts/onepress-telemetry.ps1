<#
onepress-telemetry.ps1 — onePress 本地遥测（Windows 对等实现）

  pwsh -File scripts/onepress-telemetry.ps1 emit <event> [-Status pass|fail]
       [-Step name] [-DurationMs n] [-Payload json] [-NoTelemetry]
  pwsh -File scripts/onepress-telemetry.ps1 status [-NoTelemetry]
  pwsh -File scripts/onepress-telemetry.ps1 show [-Last n]

写入 ~/.onepress/telemetry/YYYY-MM.jsonl。共享锁冲突时最多重试 3 次、
每次退避 30 ms（总预算 ≤200 ms），仍失败则降级写入 spool 并退出 0。
退出码：0 成功（含静默降级）；2 参数错误。
#>
param(
  [Parameter(Position = 0)][string]$Command = '',
  [Parameter(Position = 1)][string]$EventName = '',
  [string]$Status = 'unknown',
  [string]$Step = '',
  [int]$DurationMs = -1,
  [string]$Payload = '',
  [int]$Last = 20,
  [switch]$NoTelemetry
)

$ErrorActionPreference = 'Stop'

$TelemetryV = 1
$LineLimit = 1800
$MaxAttempts = 3
$RetryDelayMs = 30

$StorageDir = Join-Path $HOME '.onepress'
$TelemetryDir = Join-Path $StorageDir 'telemetry'
$SpoolDir = Join-Path $TelemetryDir 'spool'

$AllowedPayloadKeys = @(
  'gate', 'change', 'harness', 'mode', 'scope', 'stage',
  'round', 'passed', 'failed', 'skipped', 'total', 'ok', 'rate'
)

# 稳定事件目录（M1）：未知事件名必须拒绝。
$EventCatalog = @(
  'install.start', 'install.finish', 'gate.finish', 'evidence.finish',
  'verify.finish', 'step.start', 'step.finish'
)

function Get-DisabledReason {
  if ($NoTelemetry) { return 'flag' }
  if ($env:ONEPRESS_TELEMETRY -in @('off', 'false', '0')) { return 'env' }
  if ($env:ONEPRESS_TELEMETRY -in @('on', 'true', '1')) { return '' }
  if ($env:DO_NOT_TRACK -in @('1', 'true')) { return 'dnt' }
  if ($env:CI -in @('true', '1')) { return 'ci' }
  return ''
}

function Get-InstallId {
  $path = Join-Path $StorageDir 'install_id'
  if (Test-Path -LiteralPath $path) {
    $value = Get-Content -LiteralPath $path -TotalCount 1
    if ($value) { return $value.Trim() }
  }
  New-Item -ItemType Directory -Force -Path $StorageDir | Out-Null
  $value = [guid]::NewGuid().ToString()
  [System.IO.File]::WriteAllText($path, $value + "`n")
  return $value
}

function Get-Salt {
  $path = Join-Path $StorageDir 'salt'
  if (Test-Path -LiteralPath $path) {
    $value = Get-Content -LiteralPath $path -TotalCount 1
    if ($value) { return $value.Trim() }
  }
  New-Item -ItemType Directory -Force -Path $StorageDir | Out-Null
  $bytes = New-Object 'System.Byte[]' 32
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $rng.GetBytes($bytes)
  $rng.Dispose()
  $value = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
  [System.IO.File]::WriteAllText($path, $value + "`n")
  return $value
}

function Get-ProjectId {
  $salt = Get-Salt
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($salt + ':' + (Get-Location).Path)
    $hash = $sha.ComputeHash($bytes)
    return (($hash | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 12)
  } finally {
    $sha.Dispose()
  }
}

function Get-FilteredPayload {
  param([string]$Json)
  if (-not $Json) { return '' }
  try {
    $object = $Json | ConvertFrom-Json
  } catch {
    return ''
  }
  $pairs = New-Object System.Collections.Generic.List[string]
  foreach ($prop in $object.PSObject.Properties) {
    if ($AllowedPayloadKeys -notcontains $prop.Name) { continue }
    $value = $prop.Value
    if ($null -eq $value) { continue }
    if ($value -is [array] -or $value -is [System.Management.Automation.PSCustomObject]) { continue }
    if ($value -is [string] -and $value.Contains('/')) { continue }
    $pairs.Add(('"{0}":{1}' -f $prop.Name, ($value | ConvertTo-Json -Compress -Depth 1)))
  }
  if ($pairs.Count -eq 0) { return '' }
  return '{' + ($pairs -join ',') + '}'
}

function New-Envelope {
  $now = Get-Date
  $ts = $now.ToString("yyyy-MM-ddTHH:mm:sszzz")
  $month = $now.ToString('yyyy-MM')
  $session = if ($env:ONEPRESS_SESSION_ID) { '"' + $env:ONEPRESS_SESSION_ID + '"' } else { 'null' }
  $version = 'unknown'
  $versionFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'VERSION'
  if (Test-Path -LiteralPath $versionFile) {
    $version = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()
    if (-not $version) { $version = 'unknown' }
  }
  $extra = ''
  if ($Step) { $extra += ',"step":"' + $Step + '"' }
  if ($DurationMs -ge 0) { $extra += ',"duration_ms":' + $DurationMs }
  $filtered = Get-FilteredPayload -Json $Payload
  if ($filtered) { $extra += ',"payload":' + $filtered }

  $head = '{"telemetry_v":' + $TelemetryV +
    ',"event":"' + $EventName +
    '","ts":"' + $ts +
    '","install_id":"' + (Get-InstallId) +
    '","project_id":"' + (Get-ProjectId) +
    '","session_id":' + $session +
    ',"onepress":"' + $version +
    '","status":"' + $Status +
    '","token_in_est":null,"token_out_est":null,"token_est_method":null'

  $line = $head + $extra + '}'
  $bytes = [Text.Encoding]::UTF8.GetBytes($line)
  if ($bytes.Length -gt $LineLimit) {
    $line = $head + ',"truncated":true}'
  }
  return @{ Line = $line; Month = $month }
}

function Write-Spool {
  param([string]$Line)
  New-Item -ItemType Directory -Force -Path $SpoolDir | Out-Null
  $name = '{0}-{1}.jsonl' -f $PID, [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $path = Join-Path $SpoolDir $name
  [System.IO.File]::AppendAllText($path, $Line + "`n", [Text.Encoding]::UTF8)
}

function Write-OnePressEvent {
  param([string]$Line, [string]$Month)
  New-Item -ItemType Directory -Force -Path $TelemetryDir | Out-Null
  $path = Join-Path $TelemetryDir ($Month + '.jsonl')
  $bytes = [Text.Encoding]::UTF8.GetBytes($Line + "`n")
  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $stream = $null
    try {
      $stream = [System.IO.FileStream]::new(
        $path,
        [System.IO.FileMode]::Append,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::Read
      )
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Flush()
      $stream.Dispose()
      return 'primary'
    } catch {
      if ($stream) { $stream.Dispose() }
      Start-Sleep -Milliseconds $RetryDelayMs
    }
  }
  Write-Spool -Line $Line
  return 'spool'
}

function Invoke-Emit {
  if (-not $EventName) {
    [Console]::Error.WriteLine('emit: missing event name')
    exit 2
  }
  if ($EventCatalog -notcontains $EventName) {
    [Console]::Error.WriteLine('emit: unknown event: ' + $EventName)
    [Console]::Error.WriteLine('emit: legal events: ' + ($EventCatalog -join ' '))
    exit 2
  }
  $reason = Get-DisabledReason
  if ($reason) { exit 0 }
  $envelope = New-Envelope
  Write-OnePressEvent -Line $envelope.Line -Month $envelope.Month | Out-Null
  exit 0
}

function Invoke-Status {
  $reason = Get-DisabledReason
  if ($reason) {
    Write-Output ('telemetry: disabled (' + $reason + ')')
  } else {
    Write-Output 'telemetry: enabled'
  }
  exit 0
}

function Invoke-Show {
  if ($Last -le 0) {
    [Console]::Error.WriteLine('show: -Last expects a positive integer')
    exit 2
  }
  if (-not (Test-Path -LiteralPath $TelemetryDir)) { exit 0 }
  $files = Get-ChildItem -LiteralPath $TelemetryDir -Filter '*.jsonl' | Sort-Object Name
  if ($files.Count -eq 0) { exit 0 }
  $lines = @()
  foreach ($file in $files) {
    $lines += Get-Content -LiteralPath $file.FullName
  }
  $tail = $lines | Select-Object -Last $Last
  foreach ($line in $tail) { Write-Output $line }
  exit 0
}

switch ($Command) {
  'emit' { Invoke-Emit }
  'status' { Invoke-Status }
  'show' { Invoke-Show }
  '-h' { Write-Output 'Usage: onepress-telemetry.ps1 emit|status|show'; exit 0 }
  '--help' { Write-Output 'Usage: onepress-telemetry.ps1 emit|status|show'; exit 0 }
  '' {
    [Console]::Error.WriteLine('Usage: onepress-telemetry.ps1 emit|status|show')
    exit 2
  }
  default {
    [Console]::Error.WriteLine('unknown subcommand: ' + $Command)
    exit 2
  }
}
