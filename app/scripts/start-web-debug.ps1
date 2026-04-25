[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[start-web-debug] $Message"
}

function Assert-CommandAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [Parameter(Mandatory = $true)]
        [string]$VersionArgs,
        [Parameter(Mandatory = $true)]
        [string]$InstallHint
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "$CommandName not found. $InstallHint"
    }

    Write-Step "Checking $CommandName availability"
    $versionTokens = $VersionArgs -split '\s+'
    & $command.Source @versionTokens | Out-Null
}

function Get-ProxyProcesses {
    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -match '^dart(\.exe)?$' -and
            $_.CommandLine -match 'tool\\panel_web_debug_proxy\.dart'
        }
}

function Stop-ProxyProcesses {
    $proxyProcesses = @(Get-ProxyProcesses)
    if ($proxyProcesses.Count -eq 0) {
        Write-Step 'No existing proxy process found'
        return
    }

    foreach ($process in $proxyProcesses) {
        Write-Step "Stopping existing proxy process PID=$($process.ProcessId)"
        Stop-Process -Id $process.ProcessId -Force
    }

    Start-Sleep -Seconds 1
}

function Get-PortOwners {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $owners = @()

    try {
        $tcpConnections = Get-NetTCPConnection -LocalPort $Port -ErrorAction Stop
        $ownerPids = $tcpConnections |
            Select-Object -ExpandProperty OwningProcess -Unique |
            Where-Object { $_ -and $_ -gt 0 }

        foreach ($ownerPid in $ownerPids) {
            try {
                $process = Get-Process -Id $ownerPid -ErrorAction Stop
                $owners += [PSCustomObject]@{
                    Id          = $process.Id
                    Name        = $process.ProcessName
                    Description = $process.Path
                }
            } catch {
                $owners += [PSCustomObject]@{
                    Id          = $ownerPid
                    Name        = 'Unknown'
                    Description = ''
                }
            }
        }
    } catch {
        $netstatLines = netstat -ano -p tcp |
            Select-String -Pattern "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING\s+\d+\s*$"
        foreach ($line in $netstatLines) {
            $parts = ($line.ToString() -replace '\s+', ' ').Trim().Split(' ')
            if ($parts.Length -lt 5) {
                continue
            }
            $ownerPid = [int]$parts[-1]
            try {
                $process = Get-Process -Id $ownerPid -ErrorAction Stop
                $owners += [PSCustomObject]@{
                    Id          = $process.Id
                    Name        = $process.ProcessName
                    Description = $process.Path
                }
            } catch {
                $owners += [PSCustomObject]@{
                    Id          = $ownerPid
                    Name        = 'Unknown'
                    Description = ''
                }
            }
        }
    }

    $owners | Sort-Object Id -Unique
}

function Clear-PortIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $owners = @(Get-PortOwners -Port $Port)
    if ($owners.Count -eq 0) {
        Write-Step "Port $Port is available"
        return
    }

    foreach ($owner in $owners) {
        Write-Step "Port $Port occupied by PID=$($owner.Id) Name=$($owner.Name)"
        try {
            Stop-Process -Id $owner.Id -Force
        } catch {
            throw "Port $Port is occupied by PID=$($owner.Id) Name=$($owner.Name), and it could not be stopped automatically."
        }
    }

    Start-Sleep -Seconds 1

    $remainingOwners = @(Get-PortOwners -Port $Port)
    if ($remainingOwners.Count -gt 0) {
        $ownerSummary = $remainingOwners |
            ForEach-Object { "PID=$($_.Id) Name=$($_.Name)" }
        throw "Port $Port is still occupied after cleanup: $ownerSummary"
    }

    Write-Step "Port $Port has been cleared"
}

function Start-NamedWindow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $escapedDirectory = $WorkingDirectory.Replace("'", "''")
    $escapedCommand = $Command.Replace("'", "''")
    $windowCommand = "Set-Location '$escapedDirectory'; `$Host.UI.RawUI.WindowTitle = '$Title'; $escapedCommand"

    Start-Process powershell.exe -ArgumentList @(
        '-NoLogo',
        '-NoProfile',
        '-NoExit',
        '-ExecutionPolicy', 'Bypass',
        '-Command', $windowCommand
    ) -WorkingDirectory $WorkingDirectory -PassThru
}

function Wait-ForPortReady {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [int]$TimeoutSeconds = 15
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if ((@(Get-PortOwners -Port $Port)).Count -gt 0) {
            return $true
        }
        Start-Sleep -Milliseconds 500
    }

    return $false
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDirectory = Split-Path -Parent $scriptDirectory
$proxyPort = 8787
$proxyOrigin = "http://127.0.0.1:$proxyPort"
$proxyCommand = 'dart run tool/panel_web_debug_proxy.dart'
$flutterCommand = "flutter run -d chrome --dart-define=PANEL_WEB_PROXY_ORIGIN=$proxyOrigin"

Write-Step "Working directory: $appDirectory"

Assert-CommandAvailable -CommandName 'dart' -VersionArgs '--version' -InstallHint 'Install Flutter SDK first, or make sure dart is available in PATH.'
Assert-CommandAvailable -CommandName 'flutter' -VersionArgs '--version' -InstallHint 'Install Flutter SDK first, or make sure flutter is available in PATH.'

Stop-ProxyProcesses
Clear-PortIfNeeded -Port $proxyPort

Write-Step 'Starting proxy window'
$proxyProcess = Start-NamedWindow -Title '1Panel Proxy' -WorkingDirectory $appDirectory -Command $proxyCommand

if (-not (Wait-ForPortReady -Port $proxyPort)) {
    throw 'The local proxy did not start successfully. Flutter Web launch was cancelled. Check the proxy window output.'
}

Write-Step 'Starting Flutter Web window'
$flutterProcess = Start-NamedWindow -Title '1Panel Flutter Web' -WorkingDirectory $appDirectory -Command $flutterCommand

Write-Host ''
Write-Step 'Web debug environment started'
Write-Host "  Proxy origin : $proxyOrigin"
Write-Host "  Proxy window : 1Panel Proxy"
Write-Host "  Flutter window : 1Panel Flutter Web"
Write-Host "  Proxy PID : $($proxyProcess.Id)"
Write-Host "  Flutter launcher PID : $($flutterProcess.Id)"
Write-Host ''
Write-Host "Keep using the real 1Panel address in the UI. Browser requests will be routed through the local proxy automatically."
Write-Host "If something fails, check the proxy window first, then the Flutter Web window."
