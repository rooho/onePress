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
$SessionLimit = 128
$FieldLimit = 96
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

function ConvertTo-JsonString {
  param([string]$Value)
  return ($Value | ConvertTo-Json -Compress)
}

# 剔除 C0 控制字符与 DEL，与 bash 侧 json_escape 的口径一致。
function Remove-ControlChars {
  param([string]$Value)
  if (-not $Value) { return '' }
  return ($Value -replace '[\x00-\x1F\x7F]', '')
}

# 隐私闸：只放行标识符类字符串；任何路径分隔符、盘符、~、..、file: 或 URL 编码分隔符都拒绝。
function Test-SafePayloadString {
  param([string]$Value)
  if ($Value.Length -gt 4096) { return $false }
  if ($Value -match '[\\/]') { return $false }
  if ($Value -match '^~') { return $false }
  if ($Value -match '^[A-Za-z]:') { return $false }
  if ($Value -match '\.\.') { return $false }
  if ($Value -match '^file:') { return $false }
  if ($Value -match '(?i)%2f|%5c') { return $false }
  return $true
}

function Get-FilteredPayload {
  param([string]$Json)
  if (-not $Json) { return '' }
  try {
    $object = $Json | ConvertFrom-Json
  } catch {
    return ''
  }
  if ($null -eq $object -or $object -is [array]) { return '' }
  $pairs = New-Object System.Collections.Generic.List[string]
  foreach ($prop in $object.PSObject.Properties) {
    if ($AllowedPayloadKeys -notcontains $prop.Name) { continue }
    $value = $prop.Value
    if ($null -eq $value) { continue }
    if ($value -is [array] -or $value -is [System.Management.Automation.PSCustomObject] -or $value -is [hashtable]) { continue }
    if ($value -is [string]) {
      if (-not (Test-SafePayloadString -Value $value)) { continue }
    } elseif (-not ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal] -or $value -is [bool])) {
      continue
    }
    $pairs.Add(('"{0}":{1}' -f $prop.Name, ($value | ConvertTo-Json -Compress -Depth 1)))
  }
  if ($pairs.Count -eq 0) { return '' }
  return '{' + ($pairs -join ',') + '}'
}

function New-Envelope {
  $now = Get-Date
  $ts = $now.ToString("yyyy-MM-ddTHH:mm:sszzz")
  $month = $now.ToString('yyyy-MM')
  $version = 'unknown'
  $versionFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'VERSION'
  if (Test-Path -LiteralPath $versionFile) {
    $version = (Get-Content -LiteralPath $versionFile -TotalCount 1).Trim()
    if (-not $version) { $version = 'unknown' }
  }
  if ([Text.Encoding]::UTF8.GetByteCount($version) -gt 32) { $version = 'unknown' }
  $status = $Status
  if (-not $status -or [Text.Encoding]::UTF8.GetByteCount($status) -gt 40) { $status = 'unknown' }
  $step = $Step
  if ($step -and [Text.Encoding]::UTF8.GetByteCount($step) -gt $FieldLimit) { $step = '' }

  $sessionValue = $null
  $sessionDropped = $false
  if ($env:ONEPRESS_SESSION_ID) {
    if ([Text.Encoding]::UTF8.GetByteCount($env:ONEPRESS_SESSION_ID) -gt $SessionLimit -or
        -not (Test-SafePayloadString -Value $env:ONEPRESS_SESSION_ID)) {
      $sessionDropped = $true
    } else {
      $sessionValue = Remove-ControlChars $env:ONEPRESS_SESSION_ID
      if (-not $sessionValue) { $sessionValue = $null; $sessionDropped = $true }
    }
  }

  $installId = Get-InstallId
  if ([Text.Encoding]::UTF8.GetByteCount($installId) -gt 64 -or -not (Test-SafePayloadString -Value $installId)) { $installId = 'unknown' }
  $projectId = Get-ProjectId
  $filtered = Get-FilteredPayload -Json $Payload

  # 整行由 JSON 序列化器生成：不再手拼引号，避免转义遗漏。
  $build = {
    param([bool]$WithSession, [bool]$WithPayload, [bool]$Truncated)
    $envelope = [ordered]@{
      telemetry_v      = $TelemetryV
      event            = (Remove-ControlChars $EventName)
      ts               = $ts
      install_id       = (Remove-ControlChars $installId)
      project_id       = (Remove-ControlChars $projectId)
      session_id       = $(if ($WithSession) { Remove-ControlChars $sessionValue } else { $null })
      onepress         = (Remove-ControlChars $version)
      status           = (Remove-ControlChars $status)
      token_in_est     = $null
      token_out_est    = $null
      token_est_method = $null
    }
    if ($step) { $envelope['step'] = (Remove-ControlChars $step) }
    if ($DurationMs -ge 0) { $envelope['duration_ms'] = $DurationMs }
    if ($WithPayload -and $filtered) { $envelope['payload'] = ($filtered | ConvertFrom-Json) }
    if ($Truncated) { $envelope['truncated'] = $true }
    return ($envelope | ConvertTo-Json -Compress -Depth 10)
  }

  $hasSession = $null -ne $sessionValue
  $line = & $build $hasSession $true $sessionDropped
  if ([Text.Encoding]::UTF8.GetByteCount($line) -gt $LineLimit) {
    $line = & $build $hasSession $false $true
  }
  if ([Text.Encoding]::UTF8.GetByteCount($line) -gt $LineLimit) {
    $line = & $build $false $false $true
  }
  if ([Text.Encoding]::UTF8.GetByteCount($line) -gt $LineLimit) {
    $line = '{"telemetry_v":' + $TelemetryV + ',"event":"unknown","ts":"1970-01-01T00:00:00+00:00","install_id":"unknown","project_id":"unknown","session_id":null,"onepress":"unknown","status":"unknown","token_in_est":null,"token_out_est":null,"token_est_method":null,"truncated":true}'
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
