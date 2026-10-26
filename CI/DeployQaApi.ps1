$ErrorActionPreference = "Stop"

# Jenkins sets WORKSPACE. PSScriptRoot fallback supports local manual testing.
$workspace = $env:WORKSPACE
if ([string]::IsNullOrWhiteSpace($workspace)) {
    $workspace = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$nodePath = "C:\Program Files\nodejs\node.exe"
$appPath = [System.IO.Path]::GetFullPath((Join-Path $workspace "qa-app\server.js"))
$stateDir = Join-Path $workspace ".ci-state"
$pidFile = Join-Path $stateDir "qa-api.pid"
$stdoutLog = Join-Path $stateDir "qa-api.stdout.log"
$stderrLog = Join-Path $stateDir "qa-api.stderr.log"
$port = 3001

if (-not (Test-Path -LiteralPath $nodePath)) {
    throw "Node.js executable not found at '$nodePath'. Update nodePath in CI\DeployQaApi.ps1."
}
if (-not (Test-Path -LiteralPath $appPath)) {
    throw "QA app not found at '$appPath'. Ensure qa-app\server.js is committed."
}

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

# Stop only a process previously started by this script and matching this exact app path.
if (Test-Path -LiteralPath $pidFile) {
    $pidText = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    $oldPid = 0
    if ([int]::TryParse($pidText, [ref]$oldPid)) {
        $oldProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $oldPid" -ErrorAction SilentlyContinue
        if (
            $oldProcess -and
            $oldProcess.Name -eq "node.exe" -and
            $oldProcess.CommandLine -and
            $oldProcess.CommandLine.IndexOf($appPath, [StringComparison]::OrdinalIgnoreCase) -ge 0
        ) {
            Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

# Never terminate an unrelated process on the deployment port.
$listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $listener) {
    throw "Port $port is already occupied by another process. Deployment stopped safely; no unrelated process was terminated."
}

Remove-Item -LiteralPath $stdoutLog, $stderrLog -Force -ErrorAction SilentlyContinue

$server = Start-Process `
    -FilePath $nodePath `
    -ArgumentList ('"{0}"' -f $appPath) `
    -WorkingDirectory (Split-Path -Parent $appPath) `
    -PassThru `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -WindowStyle Hidden

Set-Content -LiteralPath $pidFile -Value $server.Id

$deadline = (Get-Date).AddSeconds(25)
$healthy = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1
    $server.Refresh()
    if ($server.HasExited) { break }

    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:$port/health" -TimeoutSec 2
        if ($response.status -eq "UP" -and $response.environment -eq "QA") {
            $healthy = $true
            break
        }
    }
    catch {
        # The process may still be starting; retry until the health-check deadline.
    }
}

if (-not $healthy) {
    $server.Refresh()
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
    Get-Content -LiteralPath $stdoutLog, $stderrLog -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    throw "Deployment failed: QA health check did not pass within 25 seconds."
}

Write-Output "DEPLOYMENT SUCCESS: QA application is running on http://127.0.0.1:$port."
