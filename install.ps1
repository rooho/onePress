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
        .\install.ps1 -Harness trae,cursor   # 只装 Trae + Cursor
        .\install.ps1 -Target D:\repo        # 指定目标仓库（默认当前目录）
        .\install.ps1 -DryRun                # 只打印计划，不落盘

    源不是本地包时（例如只想下载脚本），脚本会自动浅克隆：
        .\install.ps1 -Source '' -Repo https://github.com/rooho/onePress.git -Ref main

.PARAMETER Harness
    auto（默认，按 .qoder/ .opencode/ .trae/ .cursor/ 探测）/ qoder / opencode / trae / cursor / both / all，或用逗号组合多个。

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
    [string]$Harness = 'auto',

    [string]$Source = '',

    [string]$Target = '',

    [string]$Repo = 'https://github.com/rooho/onePress.git',

    [string]$Ref = 'main',

    [switch]$DryRun,

    [switch]$Yes,

    [switch]$NoInit
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
    'templates/ui-spec.md',
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

$script:TraeFiles = @(
    'trae/skills/onepress-discipline/SKILL.md'
)

$script:CursorFiles = @(
    'cursor/skills/onepress-discipline/SKILL.md'
)

$script:OpenSpecConfigTemplate = @'
schema: superspec

context: |
  rules:
    specs:
      - 每条需求 MUST 使用 RFC 2119 关键词（SHALL/MUST/SHOULD/MAY）
      - 每条需求 MUST 至少包含一个 GIVEN/WHEN/THEN 场景，且场景具体可测试
    design:
      - UI 变更 MUST 在 proposal.md 首行给出 **UI Change**: yes|no；yes 时必须产出 ui-spec.md（六章节）与 sandbox-preview.html，且不得把契约写回 design.md
    tasks:
      - 每个任务为原子工作单元，可独立验证（跑测试、产生输出或肉眼点检）
'@

$script:UiComponentsTemplate = @'
# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/opsx:archive` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/opsx:new` 起草 `ui-spec.md` 前 MUST 先检索本表，可复用的组件写入第 1 节复用表，不得重复造轮子。
2. 新增组件必须补齐：组件名称、路径、适用骨架 (Archetype)、核心 Props 签名。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. `适用骨架` 列取值：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`；通用组件填 `通用`。
5. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|

## 业务组件（domain）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|
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
    foreach ($rel in @('VERSION', 'opencode/opencode.json', 'qoder/skills/onepress-discipline/SKILL.md', 'trae/skills/onepress-discipline/SKILL.md', 'cursor/skills/onepress-discipline/SKILL.md', 'openspec-schema/superspec/schema.yaml')) {
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
    Stop-Install '克隆成功但未找到模板包根（VERSION / opencode/ / qoder/ / trae/ / cursor/ / openspec-schema/ 缺失），请核对仓库布局。'
}

function Resolve-Harness {
    param([string]$Choice, [string]$TargetRoot, [switch]$AssumeYes)

    $hasQoder = Test-Path -LiteralPath (Join-Path $TargetRoot '.qoder')
    $hasOpenCode = Test-Path -LiteralPath (Join-Path $TargetRoot '.opencode')
    $hasTrae = Test-Path -LiteralPath (Join-Path $TargetRoot '.trae')
    $hasCursor = Test-Path -LiteralPath (Join-Path $TargetRoot '.cursor')

    $set = @{ qoder = $false; opencode = $false; trae = $false; cursor = $false }

    switch ($Choice) {
        'qoder' { $set.qoder = $true }
        'opencode' { $set.opencode = $true }
        'trae' { $set.trae = $true }
        'cursor' { $set.cursor = $true }
        'both' { $set.qoder = $true; $set.opencode = $true }
        'all' { $set.qoder = $true; $set.opencode = $true; $set.trae = $true; $set.cursor = $true }
        'auto' {
            if ($hasQoder -or $hasOpenCode -or $hasTrae -or $hasCursor) {
                $set.qoder = $hasQoder
                $set.opencode = $hasOpenCode
                $set.trae = $hasTrae
                $set.cursor = $hasCursor
            } else {
                $set = $null
            }
        }
        default {
            $tokens = @($Choice -split '[,+]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($tokens.Count -eq 0) {
                Stop-Install "无效 -Harness：$Choice（可选 auto|qoder|opencode|trae|cursor|both|all，或用逗号组合）"
            }
            $any = $false
            foreach ($token in $tokens) {
                switch ($token) {
                    'qoder' { $set.qoder = $true; $any = $true }
                    'opencode' { $set.opencode = $true; $any = $true }
                    'trae' { $set.trae = $true; $any = $true }
                    'cursor' { $set.cursor = $true; $any = $true }
                    default { Stop-Install "无效 -Harness：$Choice（可选 auto|qoder|opencode|trae|cursor|both|all，或用逗号组合）" }
                }
            }
            if (-not $any) {
                Stop-Install "无效 -Harness：$Choice（可选 auto|qoder|opencode|trae|cursor|both|all，或用逗号组合）"
            }
        }
    }

    if (-not $set) {
        if ($AssumeYes) {
            Stop-Install '目标仓库未检测到 .qoder/、.opencode/、.trae/ 或 .cursor/，无法自动判定安装范围；请显式指定 -Harness qoder|opencode|trae|cursor|both|all。'
        }
        Write-Host ''
        Write-Host '目标仓库未检测到受支持的 AI 编码环境，请选择要安装的环境：' -ForegroundColor Yellow
        Write-Host '  1) Qoder'
        Write-Host '  2) OpenCode'
        Write-Host '  3) Trae'
        Write-Host '  4) Cursor'
        Write-Host '  5) 全部'
        $answer = Read-Host '输入 1 / 2 / 3 / 4 / 5（可用逗号组合多个，如 3,4）'
        $set = @{ qoder = $false; opencode = $false; trae = $false; cursor = $false }
        $tokens = @($answer -split '[,+ ]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        foreach ($token in $tokens) {
            switch ($token) {
                '1' { $set.qoder = $true }
                '2' { $set.opencode = $true }
                '3' { $set.trae = $true }
                '4' { $set.cursor = $true }
                '5' { $set.qoder = $true; $set.opencode = $true; $set.trae = $true; $set.cursor = $true }
                default { Stop-Install "无效选择：$answer" }
            }
        }
        if (-not ($set.qoder -or $set.opencode -or $set.trae -or $set.cursor)) {
            Stop-Install "无效选择：$answer"
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

    if ($HarnessSet.trae) {
        foreach ($file in $script:TraeFiles) {
            $dest = $file -replace '^trae/', '.trae/'
            [void]$plan.Add([pscustomobject]@{ Source = $file; Target = $dest; Layer = 'harness(trae)' })
        }
    }

    if ($HarnessSet.cursor) {
        foreach ($file in $script:CursorFiles) {
            $dest = $file -replace '^cursor/', '.cursor/'
            [void]$plan.Add([pscustomobject]@{ Source = $file; Target = $dest; Layer = 'harness(cursor)' })
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

function Mount-SkillReference {
    param([string]$TargetRoot, [string]$HarnessDir, [hashtable]$GitStatus)

    $cmdDir = Join-Path (Join-Path $TargetRoot $HarnessDir) 'commands'
    if (-not (Test-Path -LiteralPath $cmdDir)) {
        Write-Skip "$HarnessDir/commands/ 不存在，跳过技能挂载（不新建命令文件）"
        return
    }

    $files = Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md'
    if (-not $files) {
        Write-Skip "$HarnessDir/commands/ 下没有命令文件，跳过技能挂载"
        return
    }

    foreach ($file in $files) {
        $rel = Convert-ToRel -Root $TargetRoot -FullPath $file.FullName
        $text = [System.IO.File]::ReadAllText($file.FullName, $script:Utf8NoBom)
        $head = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBom = ($head.Length -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF)

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

        $outEnc = if ($hasBom) { New-Object System.Text.UTF8Encoding($true) } else { $script:Utf8NoBom }
        [System.IO.File]::WriteAllText($file.FullName, $text.Insert($insertAt, $insert), $outEnc)
        Write-Ok "$rel（+1 行技能引用）"
        [void]$script:Written.Add("$rel (+1 line)")
    }
}

function Confirm-OpenSpecSchema {
    param([string]$TargetRoot)

    $path = Join-Rel $TargetRoot 'openspec/config.yaml'

    if (-not (Test-Path -LiteralPath $path)) {
        if ($DryRun) {
            Write-Info 'would create openspec/config.yaml (schema: superspec)'
            return
        }
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        [System.IO.File]::WriteAllText($path, $script:OpenSpecConfigTemplate, $script:Utf8NoBom)
        Write-Ok 'openspec/config.yaml（新建，schema=superspec）'
        return
    }

    $text = [System.IO.File]::ReadAllText($path, $script:Utf8NoBom)
    # 注意 $ 在 .NET 里只落在 \n 之前，CRLF 文件必须用 \r? 吃掉回车，否则整行匹配失败
    $match = [regex]::Match($text, '(?m)^\uFEFF?schema:[ \t]*(?<v>\S*)[ \t]*(?<eol>\r?)$')
    if (-not $match.Success) {
        Write-Warn 'openspec/config.yaml 未找到顶层 schema 行，未改动'
        return
    }

    $current = $match.Groups['v'].Value
    if ($current -eq 'superspec') {
        Write-Ok 'openspec/config.yaml schema=superspec'
        return
    }

    if ($DryRun) {
        Write-Info "would set openspec/config.yaml schema: $current -> superspec"
        return
    }

    $eol = $match.Groups['eol'].Value
    $updated = $text.Remove($match.Index, $match.Length).Insert($match.Index, 'schema: superspec' + $eol)
    [System.IO.File]::WriteAllText($path, $updated, $script:Utf8NoBom)
    Write-Ok "openspec/config.yaml schema: $current → superspec（保留原换行与其余字段）"
}

function Test-HarnessCommandSetComplete {
    param([string]$CmdDir)

    foreach ($id in @('continue', 'ff', 'propose', 'archive')) {
        if (-not (Test-Path -LiteralPath (Join-Path $CmdDir "opsx-$id.md"))) { return $false }
    }
    return $true
}

function Remove-LegacyCommands {
    param([string]$TargetRoot, [string]$HarnessDir, $ModifiedFiles)

    foreach ($name in @('opsx-new.md', 'opsx-apply.md', 'opsx-verify.md')) {
        $rel = "$HarnessDir/commands/$name"
        $path = Join-Rel $TargetRoot $rel
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if ($ModifiedFiles -and $ModifiedFiles.ContainsKey($rel)) {
            Write-Warn "保留未提交修改，不清理旧版命令：$rel"
            continue
        }
        if ($DryRun) {
            Write-Info "would remove legacy $rel"
            continue
        }
        Remove-Item -LiteralPath $path -Force
        Write-Info "清理旧版随包命令：$rel"
    }
}

function Initialize-HarnessCommands {
    param([string]$TargetRoot, [string]$HarnessDir, [string]$Tool, $ModifiedFiles = @{})

    $cmdDir = Join-Path (Join-Path $TargetRoot $HarnessDir) 'commands'
    $existing = @()
    if (Test-Path -LiteralPath $cmdDir) {
        $existing = @(Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)
    }

    if ($existing.Count -gt 0) {
        # qoder 的命令集在 commands/opsx/ 子目录，不能用扁平文件名判断完整性
        if ($Tool -eq 'qoder' -or (Test-HarnessCommandSetComplete $cmdDir)) {
            Write-Ok "$HarnessDir/commands/ 已有 $($existing.Count) 个命令文件"
            return
        }
        Write-Warn "$HarnessDir/commands/ 仅 $($existing.Count) 个命令且命令集不完整，按旧版残留处理"
        Remove-LegacyCommands -TargetRoot $TargetRoot -HarnessDir $HarnessDir -ModifiedFiles $ModifiedFiles
        if ($DryRun) {
            Write-Info "would run: openspec init --tools $Tool --no-animation"
            return
        }
        $existing = @(Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)
        if ($existing.Count -gt 0) {
            Write-Info "$HarnessDir/commands/ 保留 $($existing.Count) 个既有命令，仅补齐 openspec 标准命令"
        }
    }

    if ($NoInit) {
        Write-Warn "$HarnessDir/commands/ 命令集不完整且指定了 -NoInit：技能将`"存在但永不加载`"，需手动 openspec init 后重跑"
        return
    }

    if (-not (Get-Command openspec -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Warn "$HarnessDir/commands/ 命令集不完整且未检测到 openspec CLI：技能将`"存在但永不加载`"。请先安装 OpenSpec CLI 并执行 openspec init --tools $Tool 后重跑本脚本"
        return
    }

    if ($DryRun) {
        Write-Info "would run: openspec init --tools $Tool --no-animation"
        return
    }

    Push-Location -LiteralPath $TargetRoot
    $logPath = Join-Path ([System.IO.Path]::GetTempPath()) ('onepress-init-' + [Guid]::NewGuid().ToString('N').Substring(0, 6) + '.log')
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # openspec 会把 node 警告写到 stderr；在 Stop 策略下会被当成终止错误，故整体重定向到文件
        & openspec init --tools $Tool --no-animation *> $logPath
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousEap
        Pop-Location
    }

    $output = ''
    if (Test-Path -LiteralPath $logPath) {
        $output = (Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue)
        Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
    }

    if ($code -ne 0) {
        $summary = ([string]$output).Trim()
        Write-Warn "openspec init 失败（exit $code）：$summary"
        return
    }

    $created = @(Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue)
    Write-Ok "openspec init 生成 $($created.Count) 个 $HarnessDir/commands 命令（config.yaml 已存在，未被 init 覆盖）"
}

function Initialize-UiComponents {
    param([string]$TargetRoot)

    $rel = 'docs/ui-components.md'
    $path = Join-Rel $TargetRoot $rel

    if (Test-Path -LiteralPath $path) {
        $head = [System.IO.File]::ReadAllText($path, $script:Utf8NoBom)
        if ($head -notmatch '(?m)^\|.*适用骨架') {
            Write-Warn "$rel 为旧版表结构（缺「适用骨架」列），建议手工迁移表头为："
            Write-Info '  | 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |'
        }
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
        $isTrae = $text -like '.trae/*'
        $isCursor = $text -like '.cursor/*'
        if ($isOpenCode -and -not $HarnessSet.opencode) { continue }
        if ($isQoder -and -not $HarnessSet.qoder) { continue }
        if ($isTrae -and -not $HarnessSet.trae) { continue }
        if ($isCursor -and -not $HarnessSet.cursor) { continue }
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
        harnesses       = [ordered]@{
            qoder    = [bool]$HarnessSet.qoder
            opencode = [bool]$HarnessSet.opencode
            trae     = [bool]$HarnessSet.trae
            cursor   = [bool]$HarnessSet.cursor
        }
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

function Test-SkillHarness {
    param([string]$TargetRoot, [string]$HarnessDir)

    $cmdDir = Join-Path (Join-Path $TargetRoot $HarnessDir) 'commands'
    if (Test-Path -LiteralPath $cmdDir) {
        $cmdFiles = @(Get-ChildItem -LiteralPath $cmdDir -Recurse -File -Filter '*.md')
        if ($cmdFiles.Count -eq 0) {
            Write-Fail "$HarnessDir/commands/ 为空：/opsx:* 命令不可用（技能存在但无挂载点）"
        }
        foreach ($file in $cmdFiles) {
            $rel = Convert-ToRel -Root $TargetRoot -FullPath $file.FullName
            if ($script:MountSkipped.ContainsKey($rel)) {
                Write-Skip "$rel（无 frontmatter，挂载跳过，不计入失败）"
                continue
            }
            $text = [System.IO.File]::ReadAllText($file.FullName, $script:Utf8NoBom)
            if ($text -notmatch 'onepress-discipline') { Write-Fail "未挂载技能引用：$rel" }
        }
    }

    $skill = Join-Rel $TargetRoot "$HarnessDir/skills/onepress-discipline/SKILL.md"
    if (Test-Path -LiteralPath $skill) {
        $skillText = [System.IO.File]::ReadAllText($skill, $script:Utf8NoBom)
        foreach ($rule in @('ui-spec.md', 'ui_change', 'sandbox-preview', '44×44', 'prefers-reduced-motion', '四态', '无障碍', '防呆')) {
            if ($skillText -notmatch $rule) { Write-Fail "$HarnessDir/skills/onepress-discipline/SKILL.md 缺少铁律关键词：$rule" }
        }
    }
}

function Probe-UiUx {
    param([string]$TargetRoot)

    $hasPy = $null -ne (Get-Command python3 -ErrorAction SilentlyContinue)
    $hasSkill = $false
    foreach ($d in @('.qoder/skills', '.opencode/skills', '.trae/skills', '.cursor/skills')) {
        if (Test-Path -LiteralPath (Join-Rel $TargetRoot "$d/ui-ux-pro-max/scripts/search.py")) { $hasSkill = $true; break }
    }
    if ($hasPy -and $hasSkill) {
        Write-Info 'ui-ux-pro-max：enabled（python3 与技能目录均就绪）'
        return
    }
    if (-not $hasPy) {
        Write-Info 'ui-ux-pro-max：SKIP（未检测到 python3；检索步骤降级为手工填写 ui-spec.md）'
    } else {
        Write-Info 'ui-ux-pro-max：SKIP（未检测到技能目录；检索步骤降级为手工填写 ui-spec.md）'
    }
    Write-Info '  启用设计检索（可选，需 Node.js + Python3）：'
    Write-Info '    npm install -g ui-ux-pro-max-cli'
    foreach ($h in ($scope -split '\+')) {
        Write-Info "    uipro init --ai $h --offline    # 只保留 .$h/skills/ui-ux-pro-max 目录，其余 6 个伴生技能可删"
    }
}

function Test-Acceptance {
    param([string]$PackRoot, [string]$TargetRoot, [hashtable]$HarnessSet, [string]$Version)

    Write-Step '④ 验收自检'

    $schemaDir = Join-Rel $TargetRoot 'openspec/schemas/superspec'
    $schemaCount = 0
    if (Test-Path -LiteralPath $schemaDir) {
        $schemaCount = @(Get-ChildItem -LiteralPath $schemaDir -Recurse -File).Count
    }
    $schemaExpected = $script:SchemaFiles.Count
    if ($schemaCount -eq $schemaExpected) { Write-Ok "openspec/schemas/superspec 共 $schemaExpected 文件（含 ui-spec.md）" }
    else { Write-Fail "openspec/schemas/superspec 文件数应为 $schemaExpected，实际 $schemaCount" }

    $schemaYaml = Join-Rel $TargetRoot 'openspec/schemas/superspec/schema.yaml'
    if (Test-Path -LiteralPath $schemaYaml) {
        $schemaText = [System.IO.File]::ReadAllText($schemaYaml, $script:Utf8NoBom)
        $fallbackCount = ([regex]::Matches($schemaText, 'SKILL FALLBACK')).Count
        if ($fallbackCount -ge 4) {
            Write-Ok "schema.yaml 技能兜底：$fallbackCount 处 SKILL FALLBACK"
        } else {
            Write-Fail "schema.yaml 只有 $fallbackCount 处 SKILL FALLBACK（brainstorm/plan/apply/finalize 应各 1 处）"
        }
    }

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

    if ($HarnessSet.qoder) { Test-SkillHarness -TargetRoot $TargetRoot -HarnessDir '.qoder' }
    if ($HarnessSet.trae) { Test-SkillHarness -TargetRoot $TargetRoot -HarnessDir '.trae' }
    if ($HarnessSet.cursor) { Test-SkillHarness -TargetRoot $TargetRoot -HarnessDir '.cursor' }

    if ($HarnessSet.opencode) {
        $json = Join-Rel $TargetRoot '.opencode/opencode.json'
        if (Test-Path -LiteralPath $json) {
            try { Get-Content -LiteralPath $json -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
            catch { Write-Fail '.opencode/opencode.json 不是合法 JSON' }
        }
    }

    $configPath = Join-Rel $TargetRoot 'openspec/config.yaml'
    if (Test-Path -LiteralPath $configPath) {
        $configText = [System.IO.File]::ReadAllText($configPath, $script:Utf8NoBom)
        if ($configText -notmatch '(?m)^\uFEFF?schema:[ \t]*superspec[ \t]*\r?$') {
            Write-Fail 'openspec/config.yaml 的 schema 不是 superspec（九工件序列不可用）'
        } else {
            Write-Ok 'openspec/config.yaml schema=superspec'
        }
    } else {
        Write-Fail 'openspec/config.yaml 缺失（安装器应已创建）'
    }

    $lockPath = Join-Path $TargetRoot 'onePress.lock'
    if (Test-Path -LiteralPath $lockPath) {
        try {
            $lock = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($lock.version -ne $Version) { Write-Fail "lock version 应为 $Version，实际 $($lock.version)" }
            if ([bool]$lock.harnesses.qoder -ne [bool]$HarnessSet.qoder) { Write-Fail 'lock.harnesses.qoder 与安装范围不一致' }
            if ([bool]$lock.harnesses.opencode -ne [bool]$HarnessSet.opencode) { Write-Fail 'lock.harnesses.opencode 与安装范围不一致' }
            if ([bool]$lock.harnesses.trae -ne [bool]$HarnessSet.trae) { Write-Fail 'lock.harnesses.trae 与安装范围不一致' }
            if ([bool]$lock.harnesses.cursor -ne [bool]$HarnessSet.cursor) { Write-Fail 'lock.harnesses.cursor 与安装范围不一致' }
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
$scope = (@('qoder', 'opencode', 'trae', 'cursor') | Where-Object { $harnessSet[$_] }) -join '+'
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

Initialize-UiComponents -TargetRoot $targetRoot

Confirm-OpenSpecSchema -TargetRoot $targetRoot

if ($harnessSet.qoder) {
    Initialize-HarnessCommands -TargetRoot $targetRoot -HarnessDir '.qoder' -Tool 'qoder' -ModifiedFiles $gitStatus.modified
    Mount-SkillReference -TargetRoot $targetRoot -HarnessDir '.qoder' -GitStatus $gitStatus
}

if ($harnessSet.trae) {
    Initialize-HarnessCommands -TargetRoot $targetRoot -HarnessDir '.trae' -Tool 'trae' -ModifiedFiles $gitStatus.modified
    Mount-SkillReference -TargetRoot $targetRoot -HarnessDir '.trae' -GitStatus $gitStatus
}

if ($harnessSet.cursor) {
    Initialize-HarnessCommands -TargetRoot $targetRoot -HarnessDir '.cursor' -Tool 'cursor' -ModifiedFiles $gitStatus.modified
    Mount-SkillReference -TargetRoot $targetRoot -HarnessDir '.cursor' -GitStatus $gitStatus
}

Write-Step '③ 写入 onePress.lock'
Write-LockFile -TargetRoot $targetRoot -Version $version -HarnessSet $harnessSet

if (-not $DryRun) { Test-Acceptance -PackRoot $packRoot -TargetRoot $targetRoot -HarnessSet $harnessSet -Version $version }

Write-Step '⑤ 可选增强层探测'
Probe-UiUx -TargetRoot $targetRoot

Write-Step '⑥ 报告'
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