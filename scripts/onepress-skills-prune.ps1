#Requires -Version 5.1
<#
.SYNOPSIS
  onepress-skills-prune.ps1 — Windows 对等实现：安装前清理 onePress 自有技能与退役路径。

.DESCRIPTION
  判定规则与 onepress-skills-prune.sh 完全一致：
    1. frontmatter 含 metadata.onepress-version 且版本 < 当前版本 → 删除
    2. 含标记但版本 >= 当前版本 → 保留
    3. 无标记 → 保留并告警（绝不误伤用户技能）
    4. RETIRED_PATHS 枚举项 → 命中即删

.PARAMETER Root
  目标仓库根目录。

.PARAMETER Version
  当前模板包版本，如 2.4.0 或 2.4.0-alpha.1。

.PARAMETER Harness
  逗号分隔的启用 harness（qoder,opencode,trae,cursor）。

.PARAMETER DryRun
  只输出将要做的事，不删除任何文件。

.EXAMPLE
  pwsh -File onepress-skills-prune.ps1 -Root . -Version 2.4.0 -Harness qoder -DryRun

.NOTES
  退出码：0 成功；2 参数错误。PowerShell 错误统一转换为退出码 2。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Harness = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$PassHarnesses = @('qoder', 'opencode', 'trae', 'cursor')
$RetiredDirs = @('commands/opsx')
$RetiredFiles = @(
    'commands/opsx-new.md',
    'commands/opsx-apply.md',
    'commands/opsx-verify.md',
    'commands/opsx-review.md',
    'commands/one.md',
    'commands/o.md'
)

function ConvertTo-VersionParts {
    param([string]$Text)
    if ($null -eq $Text) { return @{ Core = @(0, 0, 0); Pre = '' } }
    $clean = $Text.Trim().Trim('"').Trim("'").TrimStart('v', 'V')
    $dash = $clean.IndexOf('-')
    if ($dash -ge 0) {
        $core = $clean.Substring(0, $dash)
        $pre = $clean.Substring($dash + 1)
    }
    else {
        $core = $clean
        $pre = ''
    }
    $nums = @(0, 0, 0)
    $parts = $core.Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        if ($i -lt $parts.Length) {
            $n = 0
            [void][int]::TryParse($parts[$i], [ref]$n)
            $nums[$i] = $n
        }
    }
    return @{ Core = $nums; Pre = $pre }
}

function Get-PreRank {
    param([string]$Pre)
    if ([string]::IsNullOrEmpty($Pre)) { return 9 }
    $head = ($Pre -split '\.')[0].ToLowerInvariant()
    switch ($head) {
        'alpha' { return 1 }
        'beta'  { return 2 }
        'rc'    { return 3 }
        default { return 4 }
    }
}

function Compare-OnePressVersion {
    param([string]$Left, [string]$Right)
    $a = ConvertTo-VersionParts $Left
    $b = ConvertTo-VersionParts $Right
    for ($i = 0; $i -lt 3; $i++) {
        if ($a.Core[$i] -gt $b.Core[$i]) { return 1 }
        if ($a.Core[$i] -lt $b.Core[$i]) { return -1 }
    }
    if ([string]::IsNullOrEmpty($a.Pre) -and [string]::IsNullOrEmpty($b.Pre)) { return 0 }
    if ([string]::IsNullOrEmpty($a.Pre)) { return 1 }
    if ([string]::IsNullOrEmpty($b.Pre)) { return -1 }
    $ra = Get-PreRank $a.Pre
    $rb = Get-PreRank $b.Pre
    if ($ra -ne $rb) { if ($ra -gt $rb) { return 1 } else { return -1 } }
    $ta = ($a.Pre -split '\.')
    $tb = ($b.Pre -split '\.')
    for ($i = 1; $i -lt 8; $i++) {
        $x = 0; $y = 0
        if ($i -lt $ta.Length) { [void][int]::TryParse($ta[$i], [ref]$x) }
        if ($i -lt $tb.Length) { [void][int]::TryParse($tb[$i], [ref]$y) }
        if ($x -gt $y) { return 1 }
        if ($x -lt $y) { return -1 }
    }
    return 0
}

function Get-SkillMarker {
    param([string]$SkillPath)
    if (-not (Test-Path -LiteralPath $SkillPath)) { return '' }
    $line = Select-String -LiteralPath $SkillPath -Pattern '^\s*onepress-version:\s*(.+)$' |
        Select-Object -First 1
    if ($null -eq $line) { return '' }
    return ($line.Matches[0].Groups[1].Value.Trim().Trim('"').Trim("'").Trim())
}

function Remove-RetiredPath {
    param([string]$RelPath, [string]$FullPath, [bool]$IsDir)
    if ($DryRun) {
        Write-Output ("would remove retired path: {0}" -f $RelPath)
        return
    }
    Write-Output ("removed retired path: {0}" -f $RelPath)
    if ($IsDir) { Remove-Item -LiteralPath $FullPath -Recurse -Force }
    else { Remove-Item -LiteralPath $FullPath -Force }
}

function Invoke-SkillPrune {
    param([string]$Prefix)
    $skillsDir = Join-Path (Join-Path $Root $Prefix) 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir)) { return }
    foreach ($entry in Get-ChildItem -LiteralPath $skillsDir -Directory) {
        $skillPath = Join-Path $entry.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillPath)) { continue }
        $old = Get-SkillMarker $skillPath
        if ([string]::IsNullOrEmpty($old)) {
            Write-Output ("keep unmarked skill: {0}/skills/{1}" -f $Prefix, $entry.Name)
            continue
        }
        if ((Compare-OnePressVersion $old $Version) -lt 0) {
            if ($DryRun) {
                Write-Output ("would prune skill: {0}/skills/{1} ({2} -> {3})" -f $Prefix, $entry.Name, $old, $Version)
            }
            else {
                Write-Output ("prune skill: {0}/skills/{1} ({2} -> {3})" -f $Prefix, $entry.Name, $old, $Version)
                Remove-Item -LiteralPath $entry.FullName -Recurse -Force
            }
        }
        else {
            Write-Output ("keep skill: {0}/skills/{1} ({2})" -f $Prefix, $entry.Name, $old)
        }
    }
}

function Invoke-RetiredPrune {
    param([string]$Prefix)
    $base = Join-Path $Root $Prefix
    if (-not (Test-Path -LiteralPath $base)) { return }
    foreach ($rel in $RetiredDirs) {
        $full = Join-Path $base $rel
        if (Test-Path -LiteralPath $full -PathType Container) {
            Remove-RetiredPath ("{0}/{1}" -f $Prefix, $rel) $full $true
        }
    }
    foreach ($rel in $RetiredFiles) {
        $full = Join-Path $base $rel
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            Remove-RetiredPath ("{0}/{1}" -f $Prefix, $rel) $full $false
        }
    }
}

try {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        Write-Error "onepress-skills-prune: --root 不是目录：$Root"
        exit 2
    }

    $enabled = @()
    foreach ($h in ($Harness -split ',')) {
        $name = $h.Trim()
        if ([string]::IsNullOrEmpty($name)) { continue }
        if ($PassHarnesses -notcontains $name) {
            Write-Error "onepress-skills-prune: 无效 harness：$name"
            exit 2
        }
        $enabled += $name
    }

    Invoke-SkillPrune '.agents'
    foreach ($h in $enabled) {
        Invoke-SkillPrune (".$h")
        Invoke-RetiredPrune (".$h")
    }

    exit 0
}
catch {
    Write-Error ("onepress-skills-prune: {0}" -f $_.Exception.Message)
    exit 2
}