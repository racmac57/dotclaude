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
