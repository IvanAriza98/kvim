Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ([System.Management.Automation.PSTypeName]'Kvim.NativeFonts').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

namespace Kvim {
    public static class NativeFonts {
        public const uint FR_PRIVATE = 0x10;
        public const uint WM_FONTCHANGE = 0x001D;
        public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);

        [DllImport("gdi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool RemoveFontResourceEx(string name, uint fl, IntPtr pdv);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    }
}
"@
}

$script:Step = "bootstrap"
$script:RootDir = Join-Path $env:LOCALAPPDATA "kvim"
$script:StateFile = Join-Path $script:RootDir "install-state"
$script:ConfigDir = $script:RootDir
$script:BinDir = Join-Path $script:RootDir "bin"
$script:AssetsDir = Join-Path $script:RootDir "assets"
$script:LogsDir = Join-Path $script:RootDir "logs"
$script:ProgressFile = Join-Path $env:TEMP "kvim-uninstall.log"
$script:WindowsFontDir = Join-Path $env:WINDIR "Fonts"
$script:StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$script:ShortcutFile = Join-Path $script:StartMenuDir "KVIM.lnk"
$script:LauncherFile = Join-Path $script:BinDir "kvim.bat"
$script:IconFile = Join-Path $script:AssetsDir "kvim-logo.png"
$script:WindowsTerminalFragmentFile = ""
$script:ShowHelp = $false
$script:NonInteractive = $false
$script:InstalledNeovim = $false
$script:InstalledNodejs = $false
$script:InstalledNeovide = $false
$script:FontsInstalled = $false
$script:PathUpdated = $false
$script:WindowsTerminalProfileConfigured = $false

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

function Ask-YesNo {
    param([string]$Prompt, [bool]$Default = $false)

    if ($script:NonInteractive) {
        return $Default
    }

    while ($true) {
        $suffix = if ($Default) { "[Y/n]" } else { "[y/N]" }
        $answer = Read-Host "$Prompt $suffix"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default
        }

        switch ($answer.ToLower()) {
            "y" { return $true }
            "yes" { return $true }
            "n" { return $false }
            "no" { return $false }
        }
    }
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
            "^WINDOWS_FONT_DIR$" { $script:WindowsFontDir = $value }
            "^START_MENU_DIR$" { $script:StartMenuDir = $value }
            "^SHORTCUT_FILE$" { $script:ShortcutFile = $value }
            "^WINDOWS_TERMINAL_FRAGMENT_FILE$" { $script:WindowsTerminalFragmentFile = $value }
            "^LAUNCHER_FILE$" { $script:LauncherFile = $value }
            "^ICON_FILE$" { $script:IconFile = $value }
            "^INSTALLED_NEOVIM$" { $script:InstalledNeovim = ($value -eq "true") }
            "^INSTALLED_NODEJS$" { $script:InstalledNodejs = ($value -eq "true") }
            "^INSTALLED_NEOVIDE$" { $script:InstalledNeovide = ($value -eq "true") }
            "^FONTS_INSTALLED$" { $script:FontsInstalled = ($value -eq "true") }
            "^PATH_UPDATED$" { $script:PathUpdated = ($value -eq "true") }
            "^WINDOWS_TERMINAL_PROFILE_CONFIGURED$" { $script:WindowsTerminalProfileConfigured = ($value -eq "true") }
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
    if ($script:FontsInstalled) { Write-Host "  - Managed KVIM fonts in $($script:WindowsFontDir)" }
    if ($script:WindowsTerminalProfileConfigured) { Write-Host "  - Windows Terminal KVIM profile: $($script:WindowsTerminalFragmentFile)" }
    if ($script:InstalledNeovim) { Write-Host "  - Neovim via winget" }
    if ($script:InstalledNodejs) { Write-Host "  - Node.js LTS via winget" }
    if ($script:InstalledNeovide) { Write-Host "  - Neovide via winget" }
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

function Get-ManagedWindowsFontDefinitions {
    return @(
        @{ File = "FiraCodeNerdFontMono-Light.ttf"; RegistryName = "FiraCode Nerd Font Mono Light (TrueType)" },
        @{ File = "FiraCodeNerdFontMono-Regular.ttf"; RegistryName = "FiraCode Nerd Font Mono (TrueType)" },
        @{ File = "FiraCodeNerdFontMono-Medium.ttf"; RegistryName = "FiraCode Nerd Font Mono Medium (TrueType)" },
        @{ File = "FiraCodeNerdFontMono-SemiBold.ttf"; RegistryName = "FiraCode Nerd Font Mono SemiBold (TrueType)" },
        @{ File = "FiraCodeNerdFontMono-Bold.ttf"; RegistryName = "FiraCode Nerd Font Mono Bold (TrueType)" },
        @{ File = "FiraCodeNerdFontMono-Retina.ttf"; RegistryName = "FiraCode Nerd Font Mono Retina (TrueType)" }
    )
}

function Broadcast-FontChange {
    [void][Kvim.NativeFonts]::SendMessage(
        [Kvim.NativeFonts]::HWND_BROADCAST,
        [Kvim.NativeFonts]::WM_FONTCHANGE,
        [IntPtr]::Zero,
        [IntPtr]::Zero
    )
}

function Remove-ManagedFonts {
    if (-not $script:FontsInstalled) {
        return
    }

    $fontRegistryPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    foreach ($font in (Get-ManagedWindowsFontDefinitions)) {
        $fontPath = Join-Path $script:WindowsFontDir $font.File
        if (Test-Path -LiteralPath $fontPath) {
            [void][Kvim.NativeFonts]::RemoveFontResourceEx($fontPath, 0, [IntPtr]::Zero)
            try {
                Remove-Item -LiteralPath $fontPath -Force -ErrorAction Stop
                Write-Log "Removed managed font $fontPath"
            } catch {
                Write-WarnLog "Could not remove global font $fontPath. Administrator privileges may be required."
            }
        }

        if (Get-ItemProperty -Path $fontRegistryPath -Name $font.RegistryName -ErrorAction SilentlyContinue) {
            try {
                Remove-ItemProperty -Path $fontRegistryPath -Name $font.RegistryName -ErrorAction Stop
            } catch {
                Write-WarnLog "Could not remove global font registry entry '$($font.RegistryName)'. Administrator privileges may be required."
            }
        }
    }

    Broadcast-FontChange
}

function Remove-WindowsTerminalProfileFragment {
    if (-not $script:WindowsTerminalProfileConfigured) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($script:WindowsTerminalFragmentFile)) {
        return
    }

    if (Test-Path -LiteralPath $script:WindowsTerminalFragmentFile) {
        Remove-Item -LiteralPath $script:WindowsTerminalFragmentFile -Force -ErrorAction SilentlyContinue
        Write-Log "Removed Windows Terminal KVIM profile fragment $($script:WindowsTerminalFragmentFile)"
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

    if (-not $script:NonInteractive) {
        if (-not (Ask-YesNo -Prompt "Continue with KVIM uninstall?" -Default $true)) {
            Write-Log "Uninstall cancelled"
            exit 0
        }
    }

    Set-Step "remove_managed_files"
    Remove-FileIfExists -Path $script:LauncherFile
    Remove-FileIfExists -Path $script:ShortcutFile
    Remove-FileIfExists -Path $script:IconFile
    Remove-FileIfExists -Path $script:StateFile

    Set-Step "remove_managed_dependencies"
    Remove-ManagedFonts
    Remove-WindowsTerminalProfileFragment
    Remove-ManagedWingetPackage -Managed $script:InstalledNeovim -WingetId "Neovim.Neovim" -Label "Neovim"
    Remove-ManagedWingetPackage -Managed $script:InstalledNodejs -WingetId "OpenJS.NodeJS.LTS" -Label "Node.js LTS"
    Remove-ManagedWingetPackage -Managed $script:InstalledNeovide -WingetId "Neovide.Neovide" -Label "Neovide"

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
