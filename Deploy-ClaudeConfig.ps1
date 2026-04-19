<#
.SYNOPSIS
    Deploys the correct CLAUDE.md to ~/.claude/CLAUDE.md based on which machine this is.

.DESCRIPTION
    Desktop: C:\Users\carucci_r is the real profile (no junction)
    Laptop:  C:\Users\RobertCarucci is the real profile; carucci_r is a junction

    Run from the dotclaude repo root on either machine.
#>

$repoRoot = $PSScriptRoot

# Detect machine by checking if carucci_r is a real directory or a junction
$carucci_r = "C:\Users\carucci_r"
$isJunction = (Get-Item $carucci_r -ErrorAction SilentlyContinue).LinkType -eq "Junction"

if ($isJunction) {
    $machine = "laptop"
    $source  = Join-Path $repoRoot "CLAUDE.laptop.md"
    $dest    = "C:\Users\RobertCarucci\.claude\CLAUDE.md"
} else {
    $machine = "desktop"
    $source  = Join-Path $repoRoot "CLAUDE.desktop.md"
    $dest    = "C:\Users\carucci_r\.claude\CLAUDE.md"
}

Write-Host "Machine detected: $machine" -ForegroundColor Cyan
Write-Host "Source : $source"
Write-Host "Dest   : $dest"

# Ensure .claude dir exists
$destDir = Split-Path $dest
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Created $destDir" -ForegroundColor Yellow
}

# Backup existing if present
if (Test-Path $dest) {
    $backup = "$dest.bak"
    Copy-Item $dest $backup -Force
    Write-Host "Backed up existing CLAUDE.md -> CLAUDE.md.bak" -ForegroundColor Yellow
}

Copy-Item $source $dest -Force
Write-Host "Deployed CLAUDE.md for $machine [OK]" -ForegroundColor Green

# Verify
$hash_src  = (Get-FileHash $source).Hash
$hash_dest = (Get-FileHash $dest).Hash
if ($hash_src -eq $hash_dest) {
    Write-Host "Hash verified [OK]" -ForegroundColor Green
} else {
    Write-Host "WARNING: Hash mismatch! Copy may have failed." -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# Deploy Mirror-ToPersonalOneDrive.ps1 to $env:USERPROFILE\Scripts\
# Portable across machines — the script itself uses $env:USERPROFILE and
# $env:COMPUTERNAME, so a single copy works on both desktop (carucci_r) and
# laptop (RobertCarucci). Skipped silently if repo doesn't carry the file.
# ---------------------------------------------------------------------------
$mirrorSrc = Join-Path $repoRoot "Scripts\Mirror-ToPersonalOneDrive.ps1"
$mirrorDst = Join-Path $env:USERPROFILE "Scripts\Mirror-ToPersonalOneDrive.ps1"

Write-Host ""
Write-Host "Mirror script deploy" -ForegroundColor Cyan
Write-Host "Source : $mirrorSrc"
Write-Host "Dest   : $mirrorDst"

if (Test-Path $mirrorSrc) {
    $mirrorDir = Split-Path $mirrorDst
    if (-not (Test-Path $mirrorDir)) {
        New-Item -ItemType Directory -Path $mirrorDir -Force | Out-Null
        Write-Host "Created $mirrorDir" -ForegroundColor Yellow
    }

    if (Test-Path $mirrorDst) {
        Copy-Item $mirrorDst "$mirrorDst.bak" -Force
        Write-Host "Backed up existing Mirror-ToPersonalOneDrive.ps1 -> .bak" -ForegroundColor Yellow
    }

    Copy-Item $mirrorSrc $mirrorDst -Force
    Write-Host "Deployed Mirror-ToPersonalOneDrive.ps1 [OK]" -ForegroundColor Green

    $hash_ms = (Get-FileHash $mirrorSrc).Hash
    $hash_md = (Get-FileHash $mirrorDst).Hash
    if ($hash_ms -eq $hash_md) {
        Write-Host "Hash verified [OK]" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Mirror script hash mismatch!" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "If the MirrorToPersonalOneDrive task is running the old script, restart it:" -ForegroundColor Yellow
    Write-Host "  schtasks /End /TN MirrorToPersonalOneDrive" -ForegroundColor Yellow
    Write-Host "  schtasks /Run /TN MirrorToPersonalOneDrive" -ForegroundColor Yellow
} else {
    Write-Host "Mirror script not in repo at $mirrorSrc -- skipped" -ForegroundColor DarkGray
}
