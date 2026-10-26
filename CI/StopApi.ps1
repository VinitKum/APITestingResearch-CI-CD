    $workspace = $env:WORKSPACE
    $pidFile = Join-Path $workspace "target/ci-api-server.pid"

    if (Test-Path $pidFile) {
        $serverPid = 0
        $pidText = Get-Content $pidFile -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ([int]::TryParse("$pidText", [ref]$serverPid)) {
            Stop-Process -Id $serverPid -Force -ErrorAction SilentlyContinue
        }

        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        Write-Output "Demo API cleanup completed."
    }