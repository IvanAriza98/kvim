Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Step = "bootstrap"
$script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$script:ConfigDir = Join-Path $env:LOCALAPPDATA "kvim"
$script:StateDir = $script:ConfigDir
$script:BinDir = Join-Path $script:ConfigDir "bin"
$script:AssetsDir = Join-Path $script:ConfigDir "assets"
$script:LogsDir = Join-Path $script:ConfigDir "logs"
$script:StateFile = Join-Path $script:StateDir "install-state"
$script:ProgressFile = Join-Path $script:LogsDir "install.log"
$script:StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$script:ShortcutFile = Join-Path $script:StartMenuDir "KVIM.lnk"
$script:IconSourceFile = Join-Path $script:RepoRoot "assets\kvim-logo.png"
$script:IconFile = Join-Path $script:AssetsDir "kvim-logo.png"
$script:LocalConfigFile = Join-Path $script:ConfigDir "lua\kvim\local.lua"
$script:LauncherFile = Join-Path $script:BinDir "kvim.bat"
$script:MinNvimVersion = [Version]"0.10.0"

$script:EnableWorkspaces = $true
$script:EnableGit = $false
$script:EnableSvn = $false
$script:EnableConnections = $false
$script:NonInteractive = $false
$script:ShowHelp = $false
$script:NeovideFound = $false
$script:InstalledNeovim = $false
$script:InstalledNodejs = $false
$script:PathUpdated = $false
$script:NvimCmd = "nvim"
$script:NodeCmd = "node"
$script:NpmCmd = "npm"
$script:NvimVersion = $null

function Format-Bool {
    param([bool]$Value)

    return $Value.ToString().ToLower()
}

function Ensure-LogDirectory {
    if (-not (Test-Path -LiteralPath $script:LogsDir)) {
        New-Item -ItemType Directory -Path $script:LogsDir -Force | Out-Null
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

    Write-Host "[kvim-windows-installer][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "INFO" -Message $Message
}

function Write-WarnLog {
    param([string]$Message)

    Write-Warning "[kvim-windows-installer][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "WARN" -Message $Message
}

function Show-FailureContext {
    Write-Host "[kvim-windows-installer][context] repo_root=$($script:RepoRoot)"
    Write-Host "[kvim-windows-installer][context] config_dir=$($script:ConfigDir)"
    Write-Host "[kvim-windows-installer][context] state_dir=$($script:StateDir)"
    Write-Host "[kvim-windows-installer][context] launcher_file=$($script:LauncherFile)"
    Write-Host "[kvim-windows-installer][context] state_file=$($script:StateFile)"
    Write-Host "[kvim-windows-installer][context] progress_file=$($script:ProgressFile)"
    Write-Host "[kvim-windows-installer][context] nvim_cmd=$($script:NvimCmd)"
    Write-Host "[kvim-windows-installer][context] node_cmd=$($script:NodeCmd)"
    Write-Host "[kvim-windows-installer][context] npm_cmd=$($script:NpmCmd)"
    Write-Host "[kvim-windows-installer][context] config_dir_status=$(((Test-Path -LiteralPath $script:ConfigDir).ToString().ToLower()))"
    Write-Host "[kvim-windows-installer][context] last_step=$($script:Step)"
    Write-Host "[kvim-windows-installer][context] If winget already installed a dependency, KVIM may still stop before creating %LOCALAPPDATA%\kvim when that dependency is not usable yet in the current session."
}

function Fail {
    param([string]$Message)

    Write-Error "[kvim-windows-installer][step:$($script:Step)] $Message"
    Write-ProgressLog -Level "ERROR" -Message $Message
    Show-FailureContext
    throw $Message
}

function Show-Usage {
    @"
KVIM Windows installer

Usage:
  install.ps1 [options]

Options:
  --yes                  Use default module selection without prompts
  --enable-workspaces    Enable workspaces module
  --disable-workspaces   Disable workspaces module
  --enable-git           Enable git module
  --disable-git          Disable git module
  --enable-svn           Enable svn module
  --disable-svn          Disable svn module
  --enable-connections   Enable connections module
  --disable-connections  Disable connections module
  -h, --help             Show this help
"@ | Write-Host
}

function Parse-Args {
    param([string[]]$CliArgs)

    foreach ($arg in $CliArgs) {
        switch ($arg) {
            "--yes" { $script:NonInteractive = $true }
            "--enable-workspaces" { $script:EnableWorkspaces = $true }
            "--disable-workspaces" { $script:EnableWorkspaces = $false }
            "--enable-git" { $script:EnableGit = $true }
            "--disable-git" { $script:EnableGit = $false }
            "--enable-svn" { $script:EnableSvn = $true }
            "--disable-svn" { $script:EnableSvn = $false }
            "--enable-connections" { $script:EnableConnections = $true }
            "--disable-connections" { $script:EnableConnections = $false }
            "-h" { $script:ShowHelp = $true }
            "--help" { $script:ShowHelp = $true }
            default { Fail "Unknown option: $arg" }
        }
    }
}

function Refresh-SessionPath {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($source in @(
        $env:Path,
        [Environment]::GetEnvironmentVariable("Path", "User"),
        [Environment]::GetEnvironmentVariable("Path", "Machine")
    )) {
        if ([string]::IsNullOrWhiteSpace($source)) {
            continue
        }

        foreach ($item in ($source -split ";")) {
            $trimmed = $item.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed)) {
                continue
            }

            if (-not $parts.Contains($trimmed)) {
                $parts.Add($trimmed)
            }
        }
    }

    if ($parts.Count -eq 0) {
        Write-WarnLog "Could not merge current, user and machine PATH entries; keeping current session PATH"
        return
    }

    $env:Path = ($parts -join ";")
    Write-Log "Session PATH refreshed without discarding current entries"
}

function Resolve-CommandPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
            return $command.Source
        }
    }

    return $null
}

function Resolve-NvimCommand {
    $resolved = Resolve-CommandPath -Candidates @("nvim")
    if ($resolved) {
        $script:NvimCmd = $resolved
        Write-Log "Resolved Neovim command from PATH: $($script:NvimCmd)"
        return $true
    }

    foreach ($path in @(
        (Join-Path $env:ProgramFiles "Neovim\bin\nvim.exe"),
        $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} "Neovim\bin\nvim.exe" })
    )) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            $script:NvimCmd = $path
            Write-Log "Resolved Neovim command from standard location: $($script:NvimCmd)"
            return $true
        }
    }

    $script:NvimCmd = "nvim"
    return $false
}

function Resolve-NodeCommands {
    $nodeResolved = Resolve-CommandPath -Candidates @("node")
    $npmResolved = Resolve-CommandPath -Candidates @("npm", "npm.cmd")

    if ($nodeResolved -and $npmResolved) {
        $script:NodeCmd = $nodeResolved
        $script:NpmCmd = $npmResolved
        Write-Log "Resolved Node.js commands from PATH: $($script:NodeCmd) / $($script:NpmCmd)"
        return $true
    }

    foreach ($root in @(
        (Join-Path $env:ProgramFiles "nodejs"),
        $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} "nodejs" })
    )) {
        if (-not $root) {
            continue
        }

        $nodeCandidate = Join-Path $root "node.exe"
        $npmCandidate = Join-Path $root "npm.cmd"
        if ((Test-Path -LiteralPath $nodeCandidate) -and (Test-Path -LiteralPath $npmCandidate)) {
            $script:NodeCmd = $nodeCandidate
            $script:NpmCmd = $npmCandidate
            Write-Log "Resolved Node.js commands from standard location: $($script:NodeCmd) / $($script:NpmCmd)"
            return $true
        }
    }

    if ($nodeResolved) {
        Write-WarnLog "Detected node command but could not resolve npm in this session: $nodeResolved"
    }

    if ($npmResolved) {
        Write-WarnLog "Detected npm command but could not resolve node in this session: $npmResolved"
    }

    $script:NodeCmd = "node"
    $script:NpmCmd = "npm"
    return $false
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail "winget not found; cannot provision dependencies automatically"
    }

    Write-Log "Found required dependency manager: winget"
}

function Get-NvimVersion {
    try {
        $line = & $script:NvimCmd --version 2>$null | Select-Object -First 1
        if (-not $line) {
            return $null
        }

        $versionString = ($line -replace '^NVIM\s+', '') -replace '^v', ''
        return [Version]$versionString
    } catch {
        return $null
    }
}

function Install-NvimWithWinget {
    Write-Log "Installing Neovim with winget"
    & winget install --id Neovim.Neovim -e --accept-package-agreements --accept-source-agreements --force
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $script:InstalledNeovim = $true
    return $true
}

function Upgrade-NvimWithWinget {
    Write-Log "Upgrading Neovim with winget"
    & winget upgrade --id Neovim.Neovim -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    Write-WarnLog "winget upgrade failed or package was not upgradeable; trying install --force"
    return (Install-NvimWithWinget)
}

function Ensure-Nvim {
    if (-not (Resolve-NvimCommand)) {
        Write-WarnLog "Neovim not found; installing with winget"
        Ensure-Winget
        if (-not (Install-NvimWithWinget)) {
            Fail "Failed to install Neovim with winget"
        }

        Refresh-SessionPath
        [void](Resolve-NvimCommand)
    } else {
        try {
            & $script:NvimCmd --version *> $null
        } catch {
            Write-WarnLog "Neovim was found but could not start correctly; attempting reinstall with winget"
            Ensure-Winget
            if (-not (Install-NvimWithWinget)) {
                Fail "Neovim is present but unusable, and reinstall with winget failed"
            }

            Refresh-SessionPath
            [void](Resolve-NvimCommand)
        }
    }

    $script:NvimVersion = Get-NvimVersion
    if (-not $script:NvimVersion) {
        Write-WarnLog "Could not determine Neovim version; attempting reinstall with winget"
        Ensure-Winget
        if (-not (Install-NvimWithWinget)) {
            Fail "Failed to reinstall Neovim with winget"
        }

        Refresh-SessionPath
        [void](Resolve-NvimCommand)
        $script:NvimVersion = Get-NvimVersion
    }

    if (-not $script:NvimVersion) {
        Fail "Could not determine Neovim version after winget install/upgrade. The binary was found but could not be validated."
    }

    if ($script:NvimVersion -lt $script:MinNvimVersion) {
        Write-WarnLog "Neovim $($script:MinNvimVersion)+ required, found $($script:NvimVersion); upgrading with winget"
        Ensure-Winget
        if (-not (Upgrade-NvimWithWinget)) {
            Fail "Failed to upgrade Neovim with winget"
        }

        Refresh-SessionPath
        [void](Resolve-NvimCommand)
        $script:NvimVersion = Get-NvimVersion
    }

    if (-not $script:NvimVersion) {
        Fail "Could not determine Neovim version after winget install/upgrade. The binary was found but could not be validated."
    }

    if ($script:NvimVersion -lt $script:MinNvimVersion) {
        Fail "Neovim $($script:MinNvimVersion)+ is required, found $($script:NvimVersion) after winget install/upgrade"
    }

    try {
        & $script:NvimCmd --version *> $null
    } catch {
        Fail "Neovim installation is still not usable after winget install/upgrade. winget may have completed, but KVIM stops before creating $($script:ConfigDir). Try opening a new terminal and re-running the installer."
    }

    Write-Log "Neovim ready: $($script:NvimVersion)"
}

function Test-NodeCommands {
    if (-not (Resolve-NodeCommands)) {
        Write-WarnLog "Node.js commands could not be resolved from PATH or standard install locations"
        return $false
    }

    try {
        & $script:NodeCmd --version *> $null
    } catch {
        Write-WarnLog "Resolved node command is not usable: $($script:NodeCmd)"
        return $false
    }

    try {
        & $script:NpmCmd --version *> $null
    } catch {
        Write-WarnLog "Resolved npm command is not usable: $($script:NpmCmd)"
        return $false
    }

    Write-Log "Validated Node.js commands successfully: $($script:NodeCmd) / $($script:NpmCmd)"
    return $true
}

function Install-NodejsWithWinget {
    Write-Log "Installing Node.js LTS with winget"
    & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --force
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $script:InstalledNodejs = $true
    return $true
}

function Ensure-Nodejs {
    if (Test-NodeCommands) {
        Write-Log "Node.js and npm are available"
        return
    }

    Write-WarnLog "Node.js or npm not found; installing Node.js LTS with winget"
    Ensure-Winget
    if (-not (Install-NodejsWithWinget)) {
        Fail "Failed to install Node.js with winget"
    }

    Refresh-SessionPath
    if (-not (Test-NodeCommands)) {
        Fail "Node.js installation is still not usable after winget install. KVIM stops before finishing profile creation. Try opening a new terminal and re-running the installer."
    }

    Write-Log "Node.js ready"
}

function Check-RequiredDependency {
    param([string]$CommandName)

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Fail "Required dependency not found: $CommandName. KVIM cannot continue yet and the local profile may not have been created."
    }

    Write-Log "Found required dependency: $CommandName"
}

function Check-OptionalDependency {
    param([string]$CommandName)

    $found = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-WarnLog "Optional dependency missing: $CommandName"
        return
    }

    if ($CommandName -eq "neovide") {
        $script:NeovideFound = $true
    }

    Write-Log "Found optional dependency: $CommandName"
}

function Prepare-Directories {
    Write-Log "Preparing Windows user directories"
    foreach ($path in @($script:ConfigDir, $script:BinDir, $script:AssetsDir, (Split-Path -Parent $script:LocalConfigFile), $script:LogsDir)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        if (-not (Test-Path -LiteralPath $path)) {
            Fail "Failed to create directory: $path"
        }
    }

    Write-Log "Windows user directories are ready"
}

function Copy-KvimConfig {
    $sourceInit = Join-Path $script:RepoRoot "nvim\init.lua"
    if (-not (Test-Path -LiteralPath $sourceInit)) {
        Fail "Repository configuration source not found: $sourceInit"
    }

    Write-Log "Copying KVIM configuration into $($script:ConfigDir)"
    Copy-Item -Path (Join-Path $script:RepoRoot "nvim\*") -Destination $script:ConfigDir -Recurse -Force

    $targetInit = Join-Path $script:ConfigDir "init.lua"
    if (-not (Test-Path -LiteralPath $targetInit)) {
        Fail "KVIM configuration copy did not produce $targetInit"
    }

    Write-Log "KVIM configuration copied successfully"
}

function Write-LocalOverride {
    Write-Log "Writing local module override to $($script:LocalConfigFile)"
    $content = @"
return {
    modules = {
        workspaces = { enabled = $(Format-Bool $script:EnableWorkspaces) },
        git = { enabled = $(Format-Bool $script:EnableGit) },
        svn = { enabled = $(Format-Bool $script:EnableSvn) },
        connections = { enabled = $(Format-Bool $script:EnableConnections) },
    },
}
"@

    Set-Content -LiteralPath $script:LocalConfigFile -Value $content -NoNewline
    if (-not (Test-Path -LiteralPath $script:LocalConfigFile)) {
        Fail "Failed to write local module override to $($script:LocalConfigFile)"
    }

    Write-Log "Local module override written"
}

function Copy-Icon {
    if (-not (Test-Path -LiteralPath $script:IconSourceFile)) {
        Write-WarnLog "KVIM icon source not found: $($script:IconSourceFile)"
        return
    }

    Write-Log "Copying KVIM icon into $($script:IconFile)"
    Copy-Item -LiteralPath $script:IconSourceFile -Destination $script:IconFile -Force
    if (-not (Test-Path -LiteralPath $script:IconFile)) {
        Fail "KVIM icon copy did not produce $($script:IconFile)"
    }

    Write-Log "KVIM icon copied successfully"
}

function Write-Launcher {
    Write-Log "Writing Windows launcher to $($script:LauncherFile)"
    $launcher = @'
@echo off
setlocal EnableExtensions
set "NVIM_APPNAME=kvim"
if "%~1"=="--help" goto help
if "%~1"=="--gui" goto gui
nvim %*
exit /b %errorlevel%
:gui
shift
where neovide >nul 2>nul
if errorlevel 1 (
    echo KVIM launcher: neovide not found, falling back to terminal mode
    nvim %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
neovide %1 %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 (
    echo KVIM launcher: neovide failed to start, falling back to terminal mode
    nvim %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %errorlevel%
)
exit /b %errorlevel%
:help
echo Usage: kvim [--gui^|--help] [files...]
echo.
echo Modes:
echo   kvim        Run KVIM in terminal with nvim
echo   kvim --gui  Run KVIM with neovide
exit /b 0
'@

    Set-Content -LiteralPath $script:LauncherFile -Value $launcher -Encoding ASCII -NoNewline
    if (-not (Test-Path -LiteralPath $script:LauncherFile)) {
        Fail "Failed to write Windows launcher to $($script:LauncherFile)"
    }

    Write-Log "Windows launcher written successfully"
}

function Ensure-UserPath {
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $parts = @($current -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    if ($parts -contains $script:BinDir) {
        Write-Log "User PATH already contains $($script:BinDir)"
        return
    }

    $newPath = if ($parts.Count -gt 0) { ($parts + $script:BinDir) -join ";" } else { $script:BinDir }

    try {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $script:PathUpdated = $true
        Write-Log "Added $($script:BinDir) to user PATH"
    } catch {
        Write-WarnLog "Could not add $($script:BinDir) to user PATH automatically. The launcher may exist but 'kvim' may not be available until PATH is updated manually."
    }
}

function Create-StartMenuShortcut {
    Write-Log "Creating Start Menu shortcut at $($script:ShortcutFile)"
    New-Item -ItemType Directory -Force -Path $script:StartMenuDir | Out-Null

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($script:ShortcutFile)
        $shortcut.TargetPath = $script:LauncherFile
        $shortcut.Arguments = "--gui"
        $shortcut.WorkingDirectory = $script:ConfigDir
        if (Test-Path -LiteralPath $script:IconFile) {
            $shortcut.IconLocation = $script:IconFile
        }
        $shortcut.Save()
        Write-Log "Start Menu shortcut created"
    } catch {
        Write-WarnLog "Could not create Start Menu shortcut. KVIM may still be usable through $($script:LauncherFile)."
    }
}

function Write-InstallState {
    Write-Log "Writing install state to $($script:StateFile)"
    $state = @(
        "CONFIG_DIR=$($script:ConfigDir)",
        "BIN_DIR=$($script:BinDir)",
        "ASSETS_DIR=$($script:AssetsDir)",
        "LOGS_DIR=$($script:LogsDir)",
        "START_MENU_DIR=$($script:StartMenuDir)",
        "SHORTCUT_FILE=$($script:ShortcutFile)",
        "STATE_FILE=$($script:StateFile)",
        "PROGRESS_FILE=$($script:ProgressFile)",
        "LOCAL_CONFIG_FILE=$($script:LocalConfigFile)",
        "LAUNCHER_FILE=$($script:LauncherFile)",
        "ICON_FILE=$($script:IconFile)",
        "NEOVIDE_FOUND=$(Format-Bool $script:NeovideFound)",
        "INSTALLED_NEOVIM=$(Format-Bool $script:InstalledNeovim)",
        "INSTALLED_NODEJS=$(Format-Bool $script:InstalledNodejs)",
        "PATH_UPDATED=$(Format-Bool $script:PathUpdated)",
        "ENABLE_WORKSPACES=$(Format-Bool $script:EnableWorkspaces)",
        "ENABLE_GIT=$(Format-Bool $script:EnableGit)",
        "ENABLE_SVN=$(Format-Bool $script:EnableSvn)",
        "ENABLE_CONNECTIONS=$(Format-Bool $script:EnableConnections)"
    )
    Set-Content -LiteralPath $script:StateFile -Value $state

    if (-not (Test-Path -LiteralPath $script:StateFile)) {
        Fail "Failed to write install state to $($script:StateFile)"
    }

    Write-Log "Install state written successfully"
}

function Print-Summary {
    Write-Host ""
    Write-Host "KVIM Windows profile prepared successfully."
    Write-Host ""
    Write-Host "Installed paths:"
    Write-Host "  Config:       $($script:ConfigDir)"
    Write-Host "  Launcher:     $($script:LauncherFile)"
    Write-Host "  Start Menu:   $($script:ShortcutFile)"
    Write-Host "  Local config: $($script:LocalConfigFile)"
    Write-Host "  Icon:         $($script:IconFile)"
    Write-Host "  State file:   $($script:StateFile)"
    Write-Host "  Log file:     $($script:ProgressFile)"
    Write-Host ""
    Write-Host "Selected modules:"
    Write-Host "  workspaces:  $(Format-Bool $script:EnableWorkspaces)"
    Write-Host "  git:         $(Format-Bool $script:EnableGit)"
    Write-Host "  svn:         $(Format-Bool $script:EnableSvn)"
    Write-Host "  connections: $(Format-Bool $script:EnableConnections)"
    Write-Host ""
    Write-Host "Optional dependencies:"
    Write-Host "  neovide: $(Format-Bool $script:NeovideFound)"
    Write-Host "  neovim installed by KVIM: $(Format-Bool $script:InstalledNeovim)"
    Write-Host "  nodejs installed by KVIM: $(Format-Bool $script:InstalledNodejs)"
    Write-Host "  path updated: $(Format-Bool $script:PathUpdated)"
    Write-Host ""
    Write-Host "Run KVIM with:"
    Write-Host "  $($script:LauncherFile)"
    Write-Host "  $($script:LauncherFile) --gui"
}

try {
    Parse-Args -CliArgs $args
    if ($script:ShowHelp) {
        Show-Usage
        exit 0
    }

    Set-Step "ensure_nvim"
    Ensure-Nvim

    Set-Step "ensure_nodejs"
    Ensure-Nodejs

    Set-Step "check_git"
    Check-RequiredDependency -CommandName "git"

    Set-Step "check_optional_neovide"
    Check-OptionalDependency -CommandName "neovide"

    Set-Step "prepare_directories"
    Prepare-Directories

    Set-Step "copy_kvim_config"
    Copy-KvimConfig

    Set-Step "write_local_override"
    Write-LocalOverride

    Set-Step "copy_icon"
    Copy-Icon

    Set-Step "write_launcher"
    Write-Launcher

    Set-Step "ensure_user_path"
    Ensure-UserPath

    Set-Step "create_start_menu_shortcut"
    Create-StartMenuShortcut

    Set-Step "write_install_state"
    Write-InstallState

    Set-Step "print_summary"
    Print-Summary
    exit 0
} catch {
    exit 1
}
