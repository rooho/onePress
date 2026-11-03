#Requires -Version 5.1
<#
.SYNOPSIS
    onePress 安装器（Windows PowerShell 5.1+ / PowerShell 7+）。

.DESCRIPTION
    把 OpenSpec × Superpowers × Tailwind/shadcn 方案包装进目标仓库。
    脚本自带全部校验，无需人工核对；任一步失败即中止并给出原因。

    在目标仓库根目录执行：
        .\install.ps1                        # 源 = 本脚本所在目录（已克隆模板包）
        .\install.ps1 -Harness qoder         # 只装 Qoder（auto 为默认，按目录探测）
        .\install.ps1 -Target D:\repo        # 指定目标仓库（默认当前目录）
        .\install.ps1 -DryRun                # 只打印计划，不落盘

    源不是本地包时（例如只想下载脚本），脚本会自动浅克隆：
        .\install.ps1 -Source '' -Repo https://github.com/rooho/onePress.git -Ref main

.PARAMETER Harness
    auto（默认，按 .qoder/ 与 .opencode/ 探测）/ qoder / opencode / both。

.PARAMETER Source
    模板包根目录。留空则先取本脚本所在目录，再回退到浅克隆。

.PARAMETER Target
    目标仓库根目录，默认当前工作目录。

.PARAMETER DryRun
    只输出将要执行的动作，不写任何文件。

.PARAMETER Yes
    无人值守：harness 无法探测时直接失败而不是交互询问。
#>
[CmdletBinding()]
param(
    [ValidateSet('auto', 'qoder', 'opencode', 'both')]
    [string]$Harness = 'auto',

    [string]$Source = '',

    [string]$Target = '',

    [string]$Repo = 'https://github.com/rooho/onePress.git',

    [string]$Ref = 'main',

    [switch]$DryRun,

    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Written = New-Object System.Collections.ArrayList
$script:Skipped = New-Object System.Collections.ArrayList
$script:Failures = New-Object System.Collections.ArrayList
$script:Protected = @{}
$script:MountSkipped = @{}
$script:TempRoot = $null

$script:SkillRefLine = '> onepress: 执行本命令时 MUST 先加载技能 `onepress-discipline`（Token 纯净度、四态状态机、无障碍基线、破坏性操作防呆铁律）。'

# 模板包内需要安装的文件（显式清单，避免递归拷贝带入意外文件）
$script:SchemaFiles = @(
    'schema.yaml',
    'templates/apply.md',
    'templates/brainstorm.md',
    'templates/design.md',
    'templates/finalize.md',
    'templates/plan.md',
    'templates/proposal.md',
    'templates/spec.md',
    'templates/tasks.md',
    'templates/verify.md'
)

$script:OpenCodeFiles = @(
    'opencode/opencode.json',
    'opencode/agent/ux-architect.md',
    'opencode/commands/opsx-new.md',
    'opencode/commands/opsx-apply.md',
    'opencode/commands/opsx-verify.md',
    'opencode/skills/superpowers-tdd/SKILL.md'
)

$script:QoderFiles = @(
    'qoder/skills/onepress-discipline/SKILL.md'
)

$script:UiComponentsTemplate = @'
# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/opsx:archive` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/opsx:new` 起草 `ui_contract` 前 MUST 先检索本表，可复用的组件写入 `reuse_components`，不得重复造轮子。
2. 新增组件必须补齐：组件名、文件路径、用途、关键 Props、状态覆盖（loading / empty / error / submitting）。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名 | 文件路径 | 用途 | 关键 Props | 状态覆盖 | 首次引入 |
|--------|----------|------|-----------|----------|----------|

## 业务组件（domain）

| 组件名 | 文件路径 | 用途 | 关键 Props | 状态覆盖 | 首次引入 |
|--------|----------|------|-----------|----------|----------|
'@

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host "== $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "   $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "   [OK]   $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "   [SKIP] $Message" -ForegroundColor Yellow
    [void]$script:Skipped.Add($Message)
}

function Write-Warn {
    param([string]$Message)
    Write-Host "   [WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "   [FAIL] $Message" -ForegroundColor Red
    [void]$script:Failures.Add($Message)
}

function Stop-Install {
    param([string]$Message)
    Write-Host ''
    Write-Host "安装中止：$Message" -ForegroundColor Red
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

function Join-Rel {
    param([string]$Root, [string]$Rel)
    return (Join-Path $Root ($Rel -replace '/', [System.IO.Path]::DirectorySeparatorChar))
}

function Convert-ToRel {
    param([string]$Root, [string]$FullPath)
    $rootNorm = $Root.TrimEnd('\', '/')
    return ($FullPath.Substring($rootNorm.Length + 1) -replace '\\', '/')
}

function Test-PackRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    foreach ($rel in @('VERSION', 'opencode/opencode.json', 'qoder/skills/onepress-discipline/SKILL.md', 'openspec-schema/superspec/schema.yaml')) {
        if (-not (Test-Path -LiteralPath (Join-Rel $Path $rel))) { return $false }
    }
    return $true
}

function Resolve-PackSource {
    param([string]$Path)

    if ($Path) {
        $expanded = [System.IO.Path]::GetFullPath($Path)
        if (Test-PackRoot $expanded) { return $expanded }
        Write-Warn "-Source 指向的目录不是合法模板包根：$Path"
    }

    if ($PSScriptRoot -and (Test-PackRoot $PSScriptRoot)) { return $PSScriptRoot }

    Write-Info "本地未找到模板包，开始浅克隆 $Repo ($Ref)"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('onepress-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    $script:TempRoot = $tmp
    & git clone --depth 1 --branch $Ref $Repo $tmp 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Stop-Install "git clone 失败：$Repo ($Ref)" }

    if (Test-PackRoot $tmp) { return $tmp }
    $sub = Join-Path $tmp 'onePress'
    if (Test-PackRoot $sub) { return $sub }
    Stop-Install '克隆成功但未找到模板包根（VERSION / opencode/ / qoder/ / openspec-schema/ 缺失），请核对仓库布局。'
}

function Resolve-Harness {
    param([string]$Choice, [string]$TargetRoot, [switch]$AssumeYes)

    $hasQoder = Test-Path -LiteralPath (Join-Path $TargetRoot '.qoder')
    $hasOpenCode = Test-Path -LiteralPath (Join-Path $TargetRoot '.opencode')

    $set = $null
    switch ($Choice) {
        'qoder' { $set = @{ qoder = $true; opencode = $false } }
        'opencode' { $set = @{ qoder = $false; opencode = $true } }
        'both' { $set = @{ qoder = $true; opencode = $true } }
        default {
            if ($hasQoder -and $hasOpenCode) { $set = @{ qoder = $true; opencode = $true } }
            elseif ($hasQoder) { $set = @{ qoder = $true; opencode = $false } }
            elseif ($hasOpenCode) { $set = @{ qoder = $false; opencode = $true } }
        }
    }

    if (-not $set) {
        if ($AssumeYes) {
            Stop-Install '目标仓库既无 .qoder/ 也无 .opencode/，无法自动判定安装范围；请显式指定 -Harness qoder|opencode|both。'
        }
        Write-Host ''
        Write-Host '目标仓库未检测到 .qoder/ 或 .opencode/，请选择要安装的环境：' -ForegroundColor Yellow
        Write-Host '  1) Qoder'
        Write-Host '  2) OpenCode'
        Write-Host '  3) 两者都装'
        $answer = Read-Host '输入 1 / 2 / 3'
        $set = switch ($answer.Trim()) {
            '1' { @{ qoder = $true; opencode = $false } }
            '2' { @{ qoder = $false; opencode = $true } }
            '3' { @{ qoder = $true; opencode = $true } }
            default { Stop-Install "无效选择：$answer" }
        }
    }

    return $set
}

function Get-GitStatusPaths {
    param([string]$TargetRoot)

    $result = @{ modified = @{}; untracked = @{} }
    if (-not (Test-Path -LiteralPath (Join-Path $TargetRoot '.git'))) { return $result }

    Push-Location -LiteralPath $TargetRoot
    try {
        $out = & git status --porcelain 2>$null
    } finally {
        Pop-Location
    }

    foreach ($line in @($out)) {
        $text = [string]$line
        if ($text.Length -le 3) { continue }
        $status = $text.Substring(0, 2)
        $path = $text.Substring(3).Trim()
        if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1] }
        $path = ($path.Trim('"') -replace '\\', '/')

        if ($status -eq '??') { $result.untracked[$path] = $true }
        else { $result.modified[$path] = $true }
    }
    return $result
}

function Get-BuildPlan {
    param([hashtable]$HarnessSet)

    $plan = New-Object System.Collections.ArrayList

    foreach ($file in $script:SchemaFiles) {
        [void]$plan.Add([pscustomobject]@{
                Source = "openspec-schema/superspec/$file"
                Target = "openspec/schemas/superspec/$file"
                Layer  = 'harness(common)'
            })
    }

    if ($HarnessSet.opencode) {
        foreach ($file in $script:OpenCodeFiles) {
            $dest = $file -replace '^opencode/', '.opencode/'
            [void]$plan.Add([pscustomobject]@{ Source = $file; Target = $dest; Layer = 'harness(opencode)' })
        }
    }

    if ($HarnessSet.qoder) {
        foreach ($file in $script:QoderFiles) {
            $dest = $file -replace '^qoder/', '.qoder/'
            [void]$plan.Add([pscustomobject]@{ Source = $file; Target = $dest; Layer = 'harness(qoder)' })
        }
    }

    return $plan
}

function Copy-PackFile {
    param(
        [string]$PackRoot,
        [string]$TargetRoot,
        [hashtable]$GitStatus,
        [hashtable]$ManagedFiles,
        [pscustomobject]$Item
    )

    $srcPath = Join-Rel $PackRoot $Item.Source
    $dstPath = Join-Rel $TargetRoot $Item.Target

    if (-not (Test-Path -LiteralPath $srcPath)) {
        Write-Fail "模板缺失：$($Item.Source)"
        return
    }

    if ($GitStatus.modified.ContainsKey($Item.Target)) {
        $script:Protected[$Item.Target] = $true
        Write-Skip "$($Item.Target)（已跟踪文件存在未提交修改，保持原样）"
        return
    }

    if ((Test-Path -LiteralPath $dstPath) -and
        $GitStatus.untracked.ContainsKey($Item.Target) -and
        -not $ManagedFiles.ContainsKey($Item.Target)) {
        $script:Protected[$Item.Target] = $true
        Write-Skip "$($Item.Target)（已存在且不受 onePress 管理，保持原样）"
        return
    }

    if ($DryRun) {
        Write-Info "would write $($Item.Target)"
        [void]$script:Written.Add($Item.Target)
        return
    }

    $dstDir = Split-Path -Parent $dstPath
    if (-not (Test-Path -LiteralPath $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force
    Write-Ok $Item.Target
    [void]$script:Written.Add($Item.Target)
}

function Mount-QoderReference {
    param([string]$TargetRoot, [hashtable]$GitStatus)

    $cmdDir = Join-Path $TargetRoot '.qoder\commands'
    if (-not (Test-Path -LiteralPath $cmdDir)) {
        Write-Skip '.qoder/commands/ 不存在，跳过技能挂载（不新建命令文件）'
        return
    }

    $files = Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md'
    if (-not $files) {
        Write-Skip '.qoder/commands/ 下没有命令文件，跳过技能挂载'
        return
    }

    foreach ($file in $files) {
        $rel = Convert-ToRel -Root $TargetRoot -FullPath $file.FullName
        $text = [System.IO.File]::ReadAllText($file.FullName, $script:Utf8NoBom)

        if ($text -match 'onepress-discipline') {
            Write-Skip "$rel（已含技能引用）"
            continue
        }
        if ($GitStatus.modified.ContainsKey($rel)) {
            Write-Skip "$rel（已跟踪文件存在未提交修改，保持原样）"
            continue
        }

        $match = [regex]::Match($text, '^(?<bom>\uFEFF)?---[ \t]*\r?\n[\s\S]*?\r?\n---[ \t]*(?<eol>\r?\n|$)')
        if (-not $match.Success) {
            Write-Warn "$rel 无 YAML frontmatter，跳过技能挂载"
            $script:MountSkipped[$rel] = $true
            continue
        }

        $eol = $match.Groups['eol'].Value
        if (-not $eol) { $eol = "`n" }

        $insertAt = $match.Index + $match.Length
        $insert = $eol + $script:SkillRefLine + $eol

        if ($DryRun) {
            Write-Info "would mount $rel (+1 line)"
            [void]$script:Written.Add("$rel (+1 line)")
            continue
        }

        [System.IO.File]::WriteAllText($file.FullName, $text.Insert($insertAt, $insert), $script:Utf8NoBom)
        Write-Ok "$rel（+1 行技能引用）"
        [void]$script:Written.Add("$rel (+1 line)")
    }
}

function Initialize-UiComponents {
    param([string]$TargetRoot)

    $rel = 'docs/ui-components.md'
    $path = Join-Rel $TargetRoot $rel

    if (Test-Path -LiteralPath $path) {
        Write-Skip "$rel（已存在，Protect Local 不覆盖）"
        return
    }

    if ($DryRun) {
        Write-Info "would create $rel"
        [void]$script:Written.Add($rel)
        return
    }

    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($path, ($script:UiComponentsTemplate + "`n"), $script:Utf8NoBom)
    Write-Ok "$rel（首装初始化）"
    [void]$script:Written.Add($rel)
}

function Read-Lock {
    param([string]$TargetRoot)
    $path = Join-Path $TargetRoot 'onePress.lock'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        Write-Warn 'onePress.lock 无法解析，按全新安装处理（项目级资产仍受保护）'
        return $null
    }
}

function Remove-StaleFiles {
    param(
        [string]$TargetRoot,
        $OldLock,
        [hashtable]$HarnessSet,
        [hashtable]$WillWrite,
        [hashtable]$GitStatus
    )

    if (-not $OldLock -or -not $OldLock.files) { return }

    foreach ($rel in @($OldLock.files)) {
        $text = [string]$rel
        if (-not $text) { continue }

        # 本次仍会写入的文件由 Copy-PackFile 负责覆盖，绝不能在这里先删
        if ($WillWrite.ContainsKey($text)) { continue }

        $isOpenCode = $text -like '.opencode/*'
        $isQoder = $text -like '.qoder/*'
        if ($isOpenCode -and -not $HarnessSet.opencode) { continue }
        if ($isQoder -and -not $HarnessSet.qoder) { continue }
        if ($text -like 'docs/*' -or $text -like 'openspec/changes/*') { continue }

        $path = Join-Rel $TargetRoot $text
        if (-not (Test-Path -LiteralPath $path)) { continue }

        if ($GitStatus -and $GitStatus.modified.ContainsKey($text)) {
            Write-Warn "保留未提交修改，不清理：$text"
            continue
        }

        if ($DryRun) {
            Write-Info "would remove stale $text"
            continue
        }
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        Write-Info "清理旧版本残留：$text"
    }
}

function Write-LockFile {
    param([string]$TargetRoot, [string]$Version, [hashtable]$HarnessSet)

    $lock = [ordered]@{
        version         = $Version
        installedAt     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        harnesses       = [ordered]@{ qoder = [bool]$HarnessSet.qoder; opencode = [bool]$HarnessSet.opencode }
        protectedAssets = @('docs/ui-components.md', 'openspec/changes/')
        files           = @($script:Written | Where-Object { $_ -notlike '*(+1 line)*' -and $_ -ne 'onePress.lock' })
    }

    $json = ($lock | ConvertTo-Json -Depth 5) + "`n"

    if ($DryRun) {
        Write-Info 'would write onePress.lock'
        return
    }

    [System.IO.File]::WriteAllText((Join-Path $TargetRoot 'onePress.lock'), $json, $script:Utf8NoBom)
    Write-Ok 'onePress.lock'
}

function Test-Acceptance {
    param([string]$PackRoot, [string]$TargetRoot, [hashtable]$HarnessSet, [string]$Version)

    Write-Step '④ 验收自检'

    $schemaDir = Join-Rel $TargetRoot 'openspec/schemas/superspec'
    $schemaCount = 0
    if (Test-Path -LiteralPath $schemaDir) {
        $schemaCount = @(Get-ChildItem -LiteralPath $schemaDir -Recurse -File).Count
    }
    if ($schemaCount -eq 10) { Write-Ok 'openspec/schemas/superspec 共 10 文件' }
    else { Write-Fail "openspec/schemas/superspec 文件数应为 10，实际 $schemaCount" }

    $plan = Get-BuildPlan -HarnessSet $HarnessSet
    foreach ($item in $plan) {
        $dstPath = Join-Rel $TargetRoot $item.Target
        $srcPath = Join-Rel $PackRoot $item.Source
        if ($script:Protected.ContainsKey($item.Target)) {
            Write-Skip "$($item.Target)（受保护跳过，不计入失败）"
            continue
        }
        if (-not (Test-Path -LiteralPath $dstPath)) {
            Write-Fail "缺失目标文件：$($item.Target)"
            continue
        }
        $srcHash = (Get-FileHash -LiteralPath $srcPath -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $dstPath -Algorithm SHA256).Hash
        if ($srcHash -ne $dstHash) { Write-Fail "内容不一致：$($item.Target)" }
    }

    if ($HarnessSet.qoder) {
        $cmdDir = Join-Path $TargetRoot '.qoder\commands'
        if (Test-Path -LiteralPath $cmdDir) {
            foreach ($file in Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md') {
                $rel = Convert-ToRel -Root $TargetRoot -FullPath $file.FullName
                if ($script:MountSkipped.ContainsKey($rel)) {
                    Write-Skip "$rel（无 frontmatter，挂载跳过，不计入失败）"
                    continue
                }
                $text = [System.IO.File]::ReadAllText($file.FullName, $script:Utf8NoBom)
                if ($text -notmatch 'onepress-discipline') { Write-Fail "未挂载技能引用：$rel" }
            }
        }
        $skill = Join-Rel $TargetRoot '.qoder/skills/onepress-discipline/SKILL.md'
        if (Test-Path -LiteralPath $skill) {
            $skillText = [System.IO.File]::ReadAllText($skill, $script:Utf8NoBom)
            foreach ($rule in @('Token', '四态', '无障碍', '防呆')) {
                if ($skillText -notmatch $rule) { Write-Fail "SKILL.md 缺少铁律关键词：$rule" }
            }
        }
    }

    if ($HarnessSet.opencode) {
        $json = Join-Rel $TargetRoot '.opencode/opencode.json'
        if (Test-Path -LiteralPath $json) {
            try { Get-Content -LiteralPath $json -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
            catch { Write-Fail '.opencode/opencode.json 不是合法 JSON' }
        }
    }

    $lockPath = Join-Path $TargetRoot 'onePress.lock'
    if (Test-Path -LiteralPath $lockPath) {
        try {
            $lock = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($lock.version -ne $Version) { Write-Fail "lock version 应为 $Version，实际 $($lock.version)" }
            if ([bool]$lock.harnesses.qoder -ne [bool]$HarnessSet.qoder) { Write-Fail 'lock.harnesses.qoder 与安装范围不一致' }
            if ([bool]$lock.harnesses.opencode -ne [bool]$HarnessSet.opencode) { Write-Fail 'lock.harnesses.opencode 与安装范围不一致' }
        } catch {
            Write-Fail 'onePress.lock 无法解析'
        }
    } else {
        Write-Fail 'onePress.lock 缺失'
    }

    if ($script:Failures.Count -eq 0) { Write-Ok '全部验收项通过' }
}

# ---------------------------------------------------------------- main

Write-Host ''
Write-Host 'onePress 安装器' -ForegroundColor Cyan

Write-Step '① 前置检查'

$targetRoot = if ($Target) { [System.IO.Path]::GetFullPath($Target) } else { (Get-Location).Path }
if (-not (Test-Path -LiteralPath $targetRoot)) { Stop-Install "目标目录不存在：$targetRoot" }
if (-not (Test-Path -LiteralPath (Join-Path $targetRoot '.git'))) {
    Write-Warn '目标目录不是 git 仓库（无 .git/）：本地未提交修改保护将不可用'
}

$packRoot = Resolve-PackSource -Path $Source
$version = (Get-Content -LiteralPath (Join-Path $packRoot 'VERSION') -Raw -Encoding UTF8).Trim()
Write-Info "模板包：$packRoot（v$version）"
Write-Info "目标仓库：$targetRoot"

$harnessSet = Resolve-Harness -Choice $Harness -TargetRoot $targetRoot -AssumeYes:$Yes
$scope = (@('qoder', 'opencode') | Where-Object { $harnessSet[$_] }) -join '+'
Write-Ok "安装范围 harnesses：$scope"

$oldLock = Read-Lock -TargetRoot $targetRoot
$installKind = if ($oldLock) {
    if ($oldLock.version -eq $version) { '重装（同版本幂等）' } else { "升级（$($oldLock.version) → $version）" }
} else { '全新安装' }
Write-Info "安装类型：$installKind"

$gitStatus = Get-GitStatusPaths -TargetRoot $targetRoot
$managedFiles = @{}
if ($oldLock -and $oldLock.files) {
    foreach ($file in @($oldLock.files)) {
        if ($file) { $managedFiles[[string]$file] = $true }
    }
}
if ($gitStatus.modified.Count -gt 0) {
    Write-Warn "检测到 $($gitStatus.modified.Count) 个已跟踪文件存在未提交修改，命中的 harness 文件将被跳过"
}

Write-Step '② 分层安装'

$plan = Get-BuildPlan -HarnessSet $harnessSet
$willWrite = @{}
foreach ($item in $plan) { $willWrite[$item.Target] = $true }

if ($oldLock) {
    Remove-StaleFiles -TargetRoot $targetRoot -OldLock $oldLock -HarnessSet $harnessSet -WillWrite $willWrite -GitStatus $gitStatus
}

foreach ($item in $plan) {
    Copy-PackFile -PackRoot $packRoot -TargetRoot $targetRoot -GitStatus $gitStatus -ManagedFiles $managedFiles -Item $item
}

if ($harnessSet.qoder) { Mount-QoderReference -TargetRoot $targetRoot -GitStatus $gitStatus }

Initialize-UiComponents -TargetRoot $targetRoot

Write-Step '③ 写入 onePress.lock'
Write-LockFile -TargetRoot $targetRoot -Version $version -HarnessSet $harnessSet

if (-not $DryRun) { Test-Acceptance -PackRoot $packRoot -TargetRoot $targetRoot -HarnessSet $harnessSet -Version $version }

Write-Step '⑤ 报告'
Write-Info "安装范围：harnesses: $scope"
Write-Info "安装类型：$installKind"
Write-Info "写入 $($script:Written.Count) 项，跳过 $($script:Skipped.Count) 项，失败 $($script:Failures.Count) 项"

if ($script:Skipped.Count -gt 0) {
    Write-Host '   跳过项：' -ForegroundColor Yellow
    foreach ($item in $script:Skipped) { Write-Host "     - $item" -ForegroundColor Yellow }
}

if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
    Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Failures.Count -gt 0) {
    Write-Host 'onePress v' -NoNewline
    Write-Host "$version 安装失败（harnesses: $scope）" -ForegroundColor Red
    exit 1
}

Write-Host "onePress v$version 安装完成（harnesses: $scope）" -ForegroundColor Green
exit 0