# Mirror-ToPersonalOneDrive.ps1
# Continuously mirrors selected business OneDrive folders to personal OneDrive.
# Runs robocopy /MIR every 5 minutes in a loop.

$source = Join-Path $env:USERPROFILE "OneDrive - City of Hackensack"
$dest   = Join-Path $env:USERPROFILE "OneDrive - Personal"
$log    = Join-Path $env:USERPROFILE "Scripts\mirror-sync-$env:COMPUTERNAME.log"

$folders = @(
    "00_dev",
    "01_DataSources",
    "01_Raw_Source_Data",
    "02_ETL_Scripts",
    "03_Staging",
    "04_PowerBI",
    "05_EXPORTS",
    "06_Workspace_Management",
    "08_Templates",
    "09_Reference",
    "10_Projects",
    "13_PROCESSED_DATA",
    "14_Workspace",
    "15_Themes",
    "16_Reports",
    "17_Requests",
    "Action Folder",
    "Email",
    "In Progress",
    "InBox",
    "RAC",
    "Shared Folder",
    "SSOCC",
    "TEMP"
)

function Write-Log {
    param([string]$msg)
    $ts = [DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss') + 'Z'
    "$ts  [$env:COMPUTERNAME]  $msg" | Tee-Object -FilePath $log -Append | Out-Null
}

Write-Log "=== Mirror sync started ==="

while ($true) {
    $cycleStart = Get-Date
    Write-Log "--- Cycle begin ---"

    foreach ($folder in $folders) {
        $src = Join-Path $source $folder
        $dst = Join-Path $dest   $folder

        if (-not (Test-Path $src)) {
            Write-Log "SKIP (source missing): $folder"
            continue
        }

        # /MIR  = mirror (adds new, updates changed, removes deleted)
        # /Z    = restartable mode for large files
        # /R:3  = retry 3 times on error
        # /W:5  = wait 5s between retries
        # /NP   = no per-file progress (keeps log readable)
        # /NDL  = no directory list in output
        # /FFT  = use FAT timestamps (avoids false deltas with OneDrive)
        # /XA:SH = skip System + Hidden files
        $result = robocopy $src $dst /MIR /Z /R:3 /W:5 /NP /NDL /FFT /XA:SH 2>&1
        $rc = $LASTEXITCODE

        # robocopy exit codes: 0=no change, 1=files copied, 2=extras deleted,
        # 4=mismatches, 8+=errors
        if ($rc -le 3) {
            Write-Log "OK  (rc=$rc): $folder"
        } else {
            Write-Log "ERR (rc=$rc): $folder"
            $result | Select-String "ERROR|FAILED" | ForEach-Object {
                Write-Log "    $_"
            }
        }
    }

    $elapsed = [int]((Get-Date) - $cycleStart).TotalSeconds
    Write-Log "--- Cycle done in ${elapsed}s. Sleeping 5 min. ---"
    Start-Sleep -Seconds 300
}
