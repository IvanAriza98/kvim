Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Step = "bootstrap"
$script:RootDir = Join-Path $env:LOCALAPPDATA "kvim"
$script:StateFile = Join-Path $script:RootDir "install-state"
$script:ConfigDir = $script:RootDir
$script:BinDir = Join-Path $script:RootDir "bin"
$script:AssetsDir = Join-Path $script:RootDir "assets"
$script:LogsDir = Join-Path $script:RootDir "logs"
$script:ProgressFile = Join-Path $env:TEMP "kvim-uninstall.log"
$script:StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$script:ShortcutFile = Join-Path $script:StartMenuDir "KVIM.lnk"
$script:LauncherFile = Join-Path $script:BinDir "kvim.bat"
$script:IconFile = Join-Path $script:AssetsDir "kvim-logo.png"
$script:ShowHelp = $false
$script:NonInteractive = $false
$script:InstalledNeovim = $false
$script:InstalledNodejs = $false
$script:PathUpdated = $false

function Ensure-LogDirectory {
    $progressDir = Split-Path -Parent $script:ProgressFile
    if (-not (Test-Path -LiteralPath $progressDir)) {
        New-Item -ItemType Directory -Path $progressDir -Force | Out-Null
    }
}

function Write-ProgressLog {
    param([string]$Level, [string]$Message)

    Ensure-LogDirectory
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $script:ProgressFile -Value "[$timestamp] [step:$($script:Step)] [$Level] $Message"
}

function Set-Step {
    param([string]$Name)
    $script:Step = $Name
    Write-ProgressLog -Level "STEP" -Message $Name
}

function Write-Log {
    param([string]$Message)
    Write-Host "[kvim-windows-uninstall][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "INFO" -Message $Message
}

function Write-WarnLog {
    param([string]$Message)
    Write-Warning "[kvim-windows-uninstall][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "WARN" -Message $Message
}

function Fail {
    param([string]$Message)
    Write-Error "[kvim-windows-uninstall][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "ERROR" -Message $Message
    throw $Message
}

function Show-Usage {
    @"
KVIM Windows uninstaller

Usage:
  uninstall.ps1 [options]

Options:
  --yes       Run without confirmation prompts
  -h, --help  Show this help
"@ | Write-Host
}

function Parse-Args {
    param([string[]]$CliArgs)

    foreach ($arg in $CliArgs) {
        switch ($arg) {
            "--yes" { $script:NonInteractive = $true }
            "-h" { $script:ShowHelp = $true }
            "--help" { $script:ShowHelp = $true }
            default { Fail "Unknown option: $arg" }
        }
    }
}

function Load-InstallState {
    if (-not (Test-Path -LiteralPath $script:StateFile)) {
        Write-WarnLog "install-state not found; using best-effort cleanup under $($script:RootDir)"
        return
    }

    foreach ($line in (Get-Content -LiteralPath $script:StateFile)) {
        if ($line -notmatch "=") {
            continue
        }

        $parts = $line -split "=", 2
        $key = $parts[0]
        $value = $parts[1]
        switch -Regex ($key) {
            "^CONFIG_DIR$" { $script:ConfigDir = $value }
            "^BIN_DIR$" { $script:BinDir = $value }
            "^ASSETS_DIR$" { $script:AssetsDir = $value }
            "^LOGS_DIR$" { $script:LogsDir = $value }
            "^START_MENU_DIR$" { $script:StartMenuDir = $value }
            "^SHORTCUT_FILE$" { $script:ShortcutFile = $value }
            "^LAUNCHER_FILE$" { $script:LauncherFile = $value }
            "^ICON_FILE$" { $script:IconFile = $value }
            "^INSTALLED_NEOVIM$" { $script:InstalledNeovim = ($value -eq "true") }
            "^INSTALLED_NODEJS$" { $script:InstalledNodejs = ($value -eq "true") }
            "^PATH_UPDATED$" { $script:PathUpdated = ($value -eq "true") }
            "^STATE_FILE$" { $script:StateFile = $value }
        }
    }
}

function Print-Plan {
    Write-Host ""
    Write-Host "KVIM Windows uninstall plan:"
    Write-Host "  - $($script:LauncherFile)"
    Write-Host "  - $($script:ShortcutFile)"
    Write-Host "  - $($script:IconFile)"
    Write-Host "  - $($script:StateFile)"
    if ($script:InstalledNeovim) { Write-Host "  - Neovim via winget" }
    if ($script:InstalledNodejs) { Write-Host "  - Node.js LTS via winget" }
    if ($script:PathUpdated) { Write-Host "  - user PATH entry: $($script:BinDir)" }
    Write-Host "  - $($script:RootDir)"
}

function Remove-FileIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        Write-Log "Removed $Path"
    } else {
        Write-Log "Already absent: $Path"
    }
}

function Remove-DirIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $Path) {
            Write-WarnLog "Could not fully remove $Path"
        } else {
            Write-Log "Removed $Path"
        }
    } else {
        Write-Log "Already absent: $Path"
    }
}

function Remove-UserPath {
    if (-not $script:PathUpdated) {
        return
    }

    try {
        $current = [Environment]::GetEnvironmentVariable("Path", "User")
        if ([string]::IsNullOrWhiteSpace($current)) {
            return
        }

        $parts = @($current -split ";" | Where-Object { $_ -and $_ -ne $script:BinDir })
        [Environment]::SetEnvironmentVariable("Path", ($parts -join ";"), "User")
        Write-Log "Removed $($script:BinDir) from user PATH"
    } catch {
        Write-WarnLog "Could not remove $($script:BinDir) from user PATH automatically"
    }
}

function Ensure-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }

    return $true
}

function Remove-ManagedWingetPackage {
    param([bool]$Managed, [string]$WingetId, [string]$Label)

    if (-not $Managed) {
        return
    }

    if (-not (Ensure-WingetAvailable)) {
        Write-WarnLog "winget not found; cannot remove $Label automatically"
        return
    }

    & winget uninstall --id $WingetId -e --accept-source-agreements *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-WarnLog "Could not remove $Label automatically with winget"
        return
    }

    Write-Log "Removed $Label via winget"
}

function Print-Summary {
    Write-Host ""
    Write-Host "KVIM Windows uninstall completed."
    Write-Host ""
    Write-Host "Removed managed files under:"
    Write-Host "  $($script:RootDir)"
    Write-Host "  Log file: $($script:ProgressFile)"
}

try {
    Parse-Args -CliArgs $args
    if ($script:ShowHelp) {
        Show-Usage
        exit 0
    }

    Set-Step "load_install_state"
    Load-InstallState

    Set-Step "print_plan"
    Print-Plan

    Set-Step "remove_managed_files"
    Remove-FileIfExists -Path $script:LauncherFile
    Remove-FileIfExists -Path $script:ShortcutFile
    Remove-FileIfExists -Path $script:IconFile
    Remove-FileIfExists -Path $script:StateFile

    Set-Step "remove_managed_dependencies"
    Remove-ManagedWingetPackage -Managed $script:InstalledNeovim -WingetId "Neovim.Neovim" -Label "Neovim"
    Remove-ManagedWingetPackage -Managed $script:InstalledNodejs -WingetId "OpenJS.NodeJS.LTS" -Label "Node.js LTS"

    Set-Step "remove_user_path"
    Remove-UserPath

    Set-Step "remove_root_dir"
    Remove-DirIfExists -Path $script:RootDir

    Set-Step "print_summary"
    Print-Summary
    exit 0
} catch {
    exit 1
}
