$ErrorActionPreference = "Stop"

$workspace = $env:WORKSPACE
$targetDir = Join-Path $workspace "target"

New-Item -ItemType Directory -Path $targetDir -Force |
    Out-Null

$pidFile = Join-Path $targetDir "ci-api-server.pid"
$outFile = Join-Path $targetDir "ci-api-server.log"
$errFile = Join-Path $targetDir "ci-api-server-error.log"

# Clean up a server left by a previous build.
if (Test-Path $pidFile) {
    $oldPid = 0
    $pidText = Get-Content $pidFile -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ([int]::TryParse("$pidText", [ref]$oldPid)) {
        $oldProcess = Get-CimInstance Win32_Process `
            -Filter "ProcessId = $oldPid" `
            -ErrorAction SilentlyContinue

        if ($oldProcess -and $oldProcess.CommandLine -match "server.js") {
            Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
        }
    }

    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

Remove-Item $outFile, $errFile -Force -ErrorAction SilentlyContinue

$server = Start-Process `
    -FilePath "node.exe" `
    -ArgumentList "server.js" `
    -WorkingDirectory $workspace `
    -PassThru `
    -RedirectStandardOutput $outFile `
    -RedirectStandardError $errFile

Set-Content -Path $pidFile -Value $server.Id

$deadline = (Get-Date).AddSeconds(30)
$healthy = $false

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1
    $server.Refresh()

    if ($server.HasExited) {
        break
    }

    try {
        $response = Invoke-WebRequest `
            -Uri "http://127.0.0.1:3000/health" `
            -TimeoutSec 2 `
            -UseBasicParsing

        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    }
    catch {
        # The API may still be starting.
    }
}

if (-not $healthy) {
    Get-Content $outFile, $errFile -ErrorAction SilentlyContinue

    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }

    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    throw "API deployment failed: health check did not pass."
}

Write-Output "Deployment successful: API is healthy on port 3000."