# ============================================================
#  Python Complete Uninstaller
#  Open source tool to cleanly remove Python from Windows
#  
#  This script helps you remove Python installations and
#  clean up leftover files, folders, and registry entries
#  that the standard uninstaller sometimes misses.
#
#  Nothing in this script is destructive beyond Python-related
#  files. It will NOT touch your personal files, documents,
#  or any other installed software.
#
#  Run as Administrator (required to modify system PATH
#  and remove files from Program Files)
# ============================================================

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [ERROR] This script needs to run as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Why? Removing Python requires permission to:" -ForegroundColor Yellow
    Write-Host "    - Delete files from Program Files" -ForegroundColor Gray
    Write-Host "    - Modify the system PATH environment variable" -ForegroundColor Gray
    Write-Host "    - Remove registry entries" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Right-click this file and select:" -ForegroundColor Yellow
    Write-Host "  'Run with PowerShell as Administrator'" -ForegroundColor White
    Write-Host ""
    pause
    exit
}

# ── MENU ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   Python Complete Uninstaller" -ForegroundColor Cyan
Write-Host "   Safely removes Python and cleans up leftover files" -ForegroundColor DarkGray
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Choose what you want to clean up:" -ForegroundColor White
Write-Host ""
Write-Host "  [1]  Remove a specific Python version" -ForegroundColor Yellow
Write-Host "       Uninstalls Python and removes its files, folders," -ForegroundColor DarkGray
Write-Host "       registry entries, and PATH references." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [2]  Remove Microsoft Store Python shortcut" -ForegroundColor Yellow
Write-Host "       Windows sometimes installs a fake Python that just" -ForegroundColor DarkGray
Write-Host "       opens the Store. This removes that shortcut." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [3]  Clean pip cache" -ForegroundColor Yellow
Write-Host "       pip (Python's package installer) stores downloaded" -ForegroundColor DarkGray
Write-Host "       packages in a cache folder. This frees up disk space." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [4]  Clean Python AppData folders" -ForegroundColor Yellow
Write-Host "       Removes leftover Python folders from AppData that" -ForegroundColor DarkGray
Write-Host "       the uninstaller sometimes leaves behind." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [5]  Clean PATH environment variable" -ForegroundColor Yellow
Write-Host "       PATH tells Windows where to find programs. Old Python" -ForegroundColor DarkGray
Write-Host "       entries can cause 'wrong version' issues. This cleans them." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [6]  Disable App Execution Aliases" -ForegroundColor Yellow
Write-Host "       Disables the built-in Windows shortcuts for python.exe" -ForegroundColor DarkGray
Write-Host "       that redirect to the Microsoft Store." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [7]  Full clean - do everything above" -ForegroundColor Red
Write-Host "       Runs all 6 steps in order. Recommended if you want" -ForegroundColor DarkGray
Write-Host "       a completely fresh Python install." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  [Q]  Quit - don't change anything" -ForegroundColor DarkGray
Write-Host ""

$menuChoice = Read-Host "  Enter your choice"
$menuChoice = $menuChoice.Trim().ToUpper()

if ($menuChoice -eq "Q") {
    Write-Host ""
    Write-Host "  No changes made. Exiting." -ForegroundColor Gray
    pause
    exit
}

# ── FUNCTIONS ─────────────────────────────────────────────────

function Remove-PythonVersions {

    Write-Host ""
    Write-Host "  Scanning your system for Python installations..." -ForegroundColor Yellow
    Write-Host "  (Checking registry, Program Files, and AppData)" -ForegroundColor DarkGray
    Write-Host ""

    $foundVersions = @()

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($regPath in $regPaths) {
        $entries = Get-ItemProperty $regPath -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like "Python 3*" -or $_.DisplayName -like "Python 2*" }
        foreach ($entry in $entries) {
            $alreadyFound = $foundVersions | Where-Object { $_.DisplayName -eq $entry.DisplayName }
            if (-not $alreadyFound -and $entry.DisplayName) {
                $foundVersions += [PSCustomObject]@{
                    DisplayName     = $entry.DisplayName
                    Version         = $entry.DisplayVersion
                    InstallLocation = $entry.InstallLocation
                    UninstallString = $entry.UninstallString
                    PSChildName     = $entry.PSChildName
                }
            }
        }
    }

    $pyRegRoots = @(
        "HKLM:\SOFTWARE\Python\PythonCore",
        "HKCU:\SOFTWARE\Python\PythonCore",
        "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore"
    )
    foreach ($root in $pyRegRoots) {
        if (Test-Path $root) {
            Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
                $ver = $_.PSChildName
                $alreadyFound = $foundVersions | Where-Object { $_.Version -like "$ver*" }
                if (-not $alreadyFound) {
                    $installPath = (Get-ItemProperty "$($_.PSPath)\InstallPath" -ErrorAction SilentlyContinue).'(default)'
                    if ($installPath -and (Test-Path $installPath)) {
                        $foundVersions += [PSCustomObject]@{
                            DisplayName     = "Python $ver (registry only)"
                            Version         = $ver
                            InstallLocation = $installPath
                            UninstallString = ""
                            PSChildName     = $ver
                        }
                    }
                }
            }
        }
    }

    if ($foundVersions.Count -eq 0) {
        Write-Host "  [OK] No Python installations found on this system." -ForegroundColor Green
        return
    }

    Write-Host "  Found $($foundVersions.Count) Python installation(s):" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    for ($i = 0; $i -lt $foundVersions.Count; $i++) {
        $v = $foundVersions[$i]
        $loc = if ($v.InstallLocation) { $v.InstallLocation } else { "Unknown location" }
        Write-Host "  │  [$($i + 1)]  $($v.DisplayName)" -ForegroundColor White
        Write-Host "  │       Installed at: $loc" -ForegroundColor DarkGray
    }
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  │  [A]  Remove ALL versions listed above" -ForegroundColor Red
    Write-Host "  │  [Q]  Cancel — go back" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""

    $sel = Read-Host "  Enter number to remove, A for all, or Q to cancel"
    $sel = $sel.Trim().ToUpper()

    if ($sel -eq "Q") { return }

    $toRemove = @()
    if ($sel -eq "A") {
        $toRemove = $foundVersions
    } elseif ($sel -match "^\d+$") {
        $idx = [int]$sel - 1
        if ($idx -ge 0 -and $idx -lt $foundVersions.Count) {
            $toRemove = @($foundVersions[$idx])
        } else {
            Write-Host "  [ERROR] Invalid selection." -ForegroundColor Red
            return
        }
    } else {
        Write-Host "  [ERROR] Invalid input." -ForegroundColor Red
        return
    }

    foreach ($v in $toRemove) {
        $shortVer = ""
        if ($v.Version -match "^(\d+\.\d+)") { $shortVer = $Matches[1] }
        elseif ($v.PSChildName -match "^(\d+\.\d+)") { $shortVer = $Matches[1] }
        $verNoDot = $shortVer -replace "\.", ""

        Write-Host ""
        Write-Host "  ── Removing: $($v.DisplayName) ──" -ForegroundColor Cyan

        # Step 1: Run the official Windows uninstaller
        if ($v.UninstallString -and $v.UninstallString -ne "") {
            Write-Host "    [1/4] Running the official Windows uninstaller..." -ForegroundColor Yellow
            Write-Host "          (Same as uninstalling via Settings > Apps)" -ForegroundColor DarkGray
            $ResultCode = 0
            if ($v.UninstallString -like "MsiExec*" -or $v.UninstallString -like "msiexec*") {
                $msiCode = ($v.UninstallString -split " ")[1] -replace "/I", "/X"
                Start-Process "msiexec.exe" -ArgumentList "$msiCode /quiet /norestart" -Wait -ErrorAction SilentlyContinue
            } else {
                $uninstExe = ($v.UninstallString -split '"')[1]
                if ($uninstExe -and (Test-Path $uninstExe)) {
                    Start-Process $uninstExe -ArgumentList "/uninstall /quiet" -Wait -ErrorAction SilentlyContinue
                }
            }
            Write-Host "    [OK] Uninstaller completed" -ForegroundColor Green
        }

        # Step 2: Delete leftover folders the uninstaller missed
        Write-Host "    [2/4] Removing leftover folders..." -ForegroundColor Yellow
        Write-Host "          (The official uninstaller sometimes leaves these behind)" -ForegroundColor DarkGray
        $foldersToTry = @()
        if ($v.InstallLocation) { $foldersToTry += $v.InstallLocation }
        if ($verNoDot) {
            $foldersToTry += "$env:LOCALAPPDATA\Programs\Python\Python$verNoDot"
            $foldersToTry += "$env:LOCALAPPDATA\Programs\Python\Python$verNoDot-32"
            $foldersToTry += "$env:LOCALAPPDATA\Python\pythoncore-$shortVer-64"
            $foldersToTry += "$env:LOCALAPPDATA\Python\pythoncore-$shortVer-32"
            $foldersToTry += "$env:APPDATA\Python\Python$verNoDot"
        }
        foreach ($folder in $foldersToTry) {
            if ($folder -and (Test-Path $folder)) {
                Write-Host "       Removing: $folder" -ForegroundColor DarkGray
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Host "    [OK] Leftover folders removed" -ForegroundColor Green

        # Step 3: Clean PATH
        Write-Host "    [3/4] Cleaning PATH environment variable..." -ForegroundColor Yellow
        Write-Host "          (Removes old Python entries so other programs find the right version)" -ForegroundColor DarkGray
        foreach ($scope in @("User","Machine")) {
            $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
            if ($currentPath) {
                $cleaned = ($currentPath -split ";") | Where-Object {
                    $_ -notmatch "Python$verNoDot" -and
                    $_ -notmatch "Python\\$shortVer" -and
                    $_ -notmatch "python-$shortVer" -and
                    $_ -notmatch "pythoncore-$shortVer"
                }
                [Environment]::SetEnvironmentVariable("Path", ($cleaned -join ";"), $scope)
            }
        }
        Write-Host "    [OK] PATH cleaned" -ForegroundColor Green

        # Step 4: Remove registry entries
        Write-Host "    [4/4] Removing registry entries..." -ForegroundColor Yellow
        Write-Host "          (The registry is Windows' settings database — these are just Python's own entries)" -ForegroundColor DarkGray
        $regKeysToDelete = @(
            "HKLM:\SOFTWARE\Python\PythonCore\$shortVer",
            "HKCU:\SOFTWARE\Python\PythonCore\$shortVer",
            "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore\$shortVer"
        )
        foreach ($key in $regKeysToDelete) {
            if (Test-Path $key) {
                Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "       Removed: $key" -ForegroundColor DarkGray
            }
        }
        Write-Host "    [OK] Registry entries removed" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  [DONE] Selected version(s) removed successfully." -ForegroundColor Green
}

function Remove-StoreAlias {
    Write-Host ""
    Write-Host "  Removing Microsoft Store Python shortcut..." -ForegroundColor Yellow
    Write-Host "  (This is a fake placeholder Windows installs by default." -ForegroundColor DarkGray
    Write-Host "   When you type 'python' it opens the Store instead of running Python." -ForegroundColor DarkGray
    Write-Host "   Removing it lets the real Python take over.)" -ForegroundColor DarkGray
    Write-Host ""
    try {
        Get-AppxPackage *Python* | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage *PythonSoftwareFoundation* | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Host "  [OK] Microsoft Store Python removed" -ForegroundColor Green
    } catch {
        Write-Host "  [INFO] No Store Python found or already removed" -ForegroundColor Gray
    }

    $storeFolder = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    @("python.exe","python3.exe","pip.exe","pip3.exe") | ForEach-Object {
        $f = Join-Path $storeFolder $_
        if (Test-Path $f) {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed Store alias: $_" -ForegroundColor Green
        }
    }
}

function Clean-PipCache {
    Write-Host ""
    Write-Host "  Cleaning pip cache..." -ForegroundColor Yellow
    Write-Host "  (pip saves downloaded packages here so it doesn't re-download them." -ForegroundColor DarkGray
    Write-Host "   Clearing it is safe — packages will just re-download if needed.)" -ForegroundColor DarkGray
    Write-Host ""
    $pipCache = "$env:LOCALAPPDATA\pip\cache"
    if (Test-Path $pipCache) {
        $sizeBefore = (Get-ChildItem $pipCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [Math]::Round($sizeBefore / 1MB, 1)
        Remove-Item -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] pip cache cleared — freed approximately $sizeMB MB" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] No pip cache found — nothing to clean" -ForegroundColor Gray
    }
}

function Clean-AppDataFolders {
    Write-Host ""
    Write-Host "  Cleaning leftover Python AppData folders..." -ForegroundColor Yellow
    Write-Host "  (These are folders Python leaves in your user profile." -ForegroundColor DarkGray
    Write-Host "   They are safe to delete — only Python-related data is removed.)" -ForegroundColor DarkGray
    Write-Host ""
    $foldersToCheck = @(
        "$env:LOCALAPPDATA\Programs\Python",
        "$env:LOCALAPPDATA\Python",
        "$env:APPDATA\Python",
        "$env:LOCALAPPDATA\pip"
    )
    $found = $false
    foreach ($folder in $foldersToCheck) {
        if (Test-Path $folder) {
            $found = $true
            Write-Host "    Removing: $folder" -ForegroundColor DarkGray
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] Removed" -ForegroundColor Green
        }
    }
    if (-not $found) {
        Write-Host "  [INFO] No leftover folders found — already clean!" -ForegroundColor Gray
    }
}

function Clean-PathEntries {
    Write-Host ""
    Write-Host "  Cleaning Python entries from PATH..." -ForegroundColor Yellow
    Write-Host "  (PATH is a list Windows uses to find programs." -ForegroundColor DarkGray
    Write-Host "   Old Python entries can cause 'wrong version' errors." -ForegroundColor DarkGray
    Write-Host "   Only Python-related entries are removed — nothing else is touched.)" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($scope in @("User","Machine")) {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
        if ($currentPath) {
            $before = ($currentPath -split ";").Count
            $cleaned = ($currentPath -split ";") | Where-Object {
                $_ -notmatch "Python3\d*" -and
                $_ -notmatch "Python2\d*" -and
                $_ -notmatch "\\Python\\" -and
                $_ -notmatch "pythoncore" -and
                $_ -notmatch "WindowsApps.*python" -and
                $_ -notmatch "\\pip\\"
            }
            $after = $cleaned.Count
            $removed = $before - $after
            [Environment]::SetEnvironmentVariable("Path", ($cleaned -join ";"), $scope)
            Write-Host "  [OK] $scope PATH — removed $removed Python entries" -ForegroundColor Green
        }
    }
}

function Disable-AppAliases {
    Write-Host ""
    Write-Host "  Disabling Python App Execution Aliases..." -ForegroundColor Yellow
    Write-Host "  (Windows has built-in shortcuts for python.exe that redirect to the" -ForegroundColor DarkGray
    Write-Host "   Microsoft Store. Even with Python installed, these can interfere." -ForegroundColor DarkGray
    Write-Host "   Disabling them lets your real Python installation take priority.)" -ForegroundColor DarkGray
    Write-Host ""
    $aliasPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    $aliases = @("python.exe","python3.exe","pip.exe","pip3.exe")
    $found = $false
    foreach ($alias in $aliases) {
        $fullPath = Join-Path $aliasPath $alias
        if (Test-Path $fullPath) {
            $found = $true
            Rename-Item $fullPath "$fullPath.disabled" -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Disabled: $alias" -ForegroundColor Green
        }
    }
    if (-not $found) {
        Write-Host "  [INFO] No active aliases found — already disabled or not present" -ForegroundColor Gray
    }
}

# ── RUN SELECTED OPTION ───────────────────────────────────────

switch ($menuChoice) {
    "1" { Remove-PythonVersions }
    "2" { Remove-StoreAlias }
    "3" { Clean-PipCache }
    "4" { Clean-AppDataFolders }
    "5" { Clean-PathEntries }
    "6" { Disable-AppAliases }
    "7" {
        Write-Host ""
        Write-Host "  Running full clean — this will take a moment..." -ForegroundColor Yellow
        Write-Host "  (Each step is explained as it runs)" -ForegroundColor DarkGray
        Write-Host ""
        Remove-PythonVersions
        Remove-StoreAlias
        Clean-PipCache
        Clean-AppDataFolders
        Clean-PathEntries
        Disable-AppAliases
    }
    default {
        Write-Host "  [ERROR] Invalid choice — nothing was changed." -ForegroundColor Red
        pause
        exit
    }
}

# ── VERIFY ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Checking results..." -ForegroundColor Yellow
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$remaining = Get-Command python -ErrorAction SilentlyContinue
if ($remaining) {
    $ver = & python --version 2>&1
    if ($ver -like "*Python*") {
        Write-Host "  [INFO] Python is still detected: $ver" -ForegroundColor Yellow
        Write-Host "         Location: $($remaining.Source)" -ForegroundColor DarkGray
        Write-Host "         This may be a version you chose to keep, or a restart is needed." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [OK] No Python found in PATH — clean!" -ForegroundColor Green
}

# ── FINAL STEP: App Execution Aliases reminder ────────────────
Write-Host ""
Write-Host "  ──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  One more thing — disable Python in App execution aliases." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Windows has a separate setting that redirects python.exe" -ForegroundColor Gray
Write-Host "  to the Microsoft Store. This can cause problems even after" -ForegroundColor Gray
Write-Host "  uninstalling Python. Here is how to turn it off:" -ForegroundColor Gray
Write-Host ""
Write-Host "  1. Press  Win + I  to open Settings" -ForegroundColor White
Write-Host "  2. Go to: Apps  →  Apps & Features (or Installed Apps)" -ForegroundColor White
Write-Host "  3. Click: App execution aliases" -ForegroundColor White
Write-Host "  4. Toggle OFF: App Installer - python.exe" -ForegroundColor White
Write-Host "  5. Toggle OFF: App Installer - python3.exe" -ForegroundColor White
Write-Host ""
Write-Host "  This is safe — it only stops the Store redirect." -ForegroundColor DarkGray
Write-Host "  ──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$openSettings = Read-Host "  Open App execution aliases settings now? (Y/N)"
if ($openSettings.Trim().ToUpper() -eq "Y") {
    Start-Process "ms-settings:appsfeatures-app"
    Write-Host ""
    Write-Host "  Settings opened — scroll down to find python.exe and toggle it OFF." -ForegroundColor Green
    Write-Host "  Then come back here and press any key." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   All done! Restart your PC to finish the cleanup." -ForegroundColor Green
Write-Host ""
Write-Host "   After restarting, install the Python version you want" -ForegroundColor White
Write-Host "   from python.org and check 'Add Python to PATH'" -ForegroundColor White
Write-Host "   during installation." -ForegroundColor White
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
pause


if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [ERROR] Run this script as Administrator." -ForegroundColor Red
    Write-Host "  Right-click and select 'Run with PowerShell as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

# ── MENU ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   Python Complete Uninstaller" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  What would you like to do?" -ForegroundColor White
Write-Host ""
Write-Host "  [1]  Remove specific Python version(s)" -ForegroundColor Yellow
Write-Host "  [2]  Remove Microsoft Store Python alias" -ForegroundColor Yellow
Write-Host "  [3]  Clean pip cache" -ForegroundColor Yellow
Write-Host "  [4]  Clean all Python AppData folders" -ForegroundColor Yellow
Write-Host "  [5]  Clean PATH of all Python entries" -ForegroundColor Yellow
Write-Host "  [6]  Disable App Execution Aliases (python.exe / python3.exe)" -ForegroundColor Yellow
Write-Host "  [7]  Full nuke - do ALL of the above" -ForegroundColor Red
Write-Host "  [Q]  Quit" -ForegroundColor DarkGray
Write-Host ""

$menuChoice = Read-Host "  Enter choice"
$menuChoice = $menuChoice.Trim().ToUpper()

if ($menuChoice -eq "Q") {
    Write-Host "  Cancelled." -ForegroundColor Gray
    pause
    exit
}

# ── FUNCTIONS ─────────────────────────────────────────────────

function Remove-PythonVersions {

    Write-Host ""
    Write-Host "  Scanning for installed Python versions..." -ForegroundColor Yellow
    Write-Host ""

    $foundVersions = @()

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($regPath in $regPaths) {
        $entries = Get-ItemProperty $regPath -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like "Python 3*" -or $_.DisplayName -like "Python 2*" }
        foreach ($entry in $entries) {
            $alreadyFound = $foundVersions | Where-Object { $_.DisplayName -eq $entry.DisplayName }
            if (-not $alreadyFound -and $entry.DisplayName) {
                $foundVersions += [PSCustomObject]@{
                    DisplayName     = $entry.DisplayName
                    Version         = $entry.DisplayVersion
                    InstallLocation = $entry.InstallLocation
                    UninstallString = $entry.UninstallString
                    PSChildName     = $entry.PSChildName
                }
            }
        }
    }

    # Also check Python registry core keys
    $pyRegRoots = @(
        "HKLM:\SOFTWARE\Python\PythonCore",
        "HKCU:\SOFTWARE\Python\PythonCore",
        "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore"
    )
    foreach ($root in $pyRegRoots) {
        if (Test-Path $root) {
            Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
                $ver = $_.PSChildName
                $alreadyFound = $foundVersions | Where-Object { $_.Version -like "$ver*" }
                if (-not $alreadyFound) {
                    $installPath = (Get-ItemProperty "$($_.PSPath)\InstallPath" -ErrorAction SilentlyContinue).'(default)'
                    if ($installPath -and (Test-Path $installPath)) {
                        $foundVersions += [PSCustomObject]@{
                            DisplayName     = "Python $ver (registry only)"
                            Version         = $ver
                            InstallLocation = $installPath
                            UninstallString = ""
                            PSChildName     = $ver
                        }
                    }
                }
            }
        }
    }

    if ($foundVersions.Count -eq 0) {
        Write-Host "  [INFO] No Python installations found." -ForegroundColor Green
        return
    }

    Write-Host "  Found $($foundVersions.Count) Python installation(s):" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    for ($i = 0; $i -lt $foundVersions.Count; $i++) {
        $v = $foundVersions[$i]
        $loc = if ($v.InstallLocation) { $v.InstallLocation } else { "Unknown location" }
        Write-Host "  │  [$($i + 1)]  $($v.DisplayName)" -ForegroundColor White
        Write-Host "  │       Location: $loc" -ForegroundColor DarkGray
    }
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  │  [A]  Remove ALL versions" -ForegroundColor Red
    Write-Host "  │  [Q]  Cancel" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""

    $sel = Read-Host "  Enter number, A for all, or Q to cancel"
    $sel = $sel.Trim().ToUpper()

    if ($sel -eq "Q") { return }

    $toRemove = @()
    if ($sel -eq "A") {
        $toRemove = $foundVersions
    } elseif ($sel -match "^\d+$") {
        $idx = [int]$sel - 1
        if ($idx -ge 0 -and $idx -lt $foundVersions.Count) {
            $toRemove = @($foundVersions[$idx])
        } else {
            Write-Host "  [ERROR] Invalid selection." -ForegroundColor Red
            return
        }
    } else {
        Write-Host "  [ERROR] Invalid input." -ForegroundColor Red
        return
    }

    foreach ($v in $toRemove) {
        $shortVer = ""
        if ($v.Version -match "^(\d+\.\d+)") { $shortVer = $Matches[1] }
        elseif ($v.PSChildName -match "^(\d+\.\d+)") { $shortVer = $Matches[1] }
        $verNoDot = $shortVer -replace "\.", ""

        Write-Host ""
        Write-Host "  ── Removing: $($v.DisplayName) ──" -ForegroundColor Cyan

        # 1. Run uninstaller
        if ($v.UninstallString -and $v.UninstallString -ne "") {
            Write-Host "    Running Windows uninstaller..." -ForegroundColor Yellow
            $ResultCode = 0
            if ($v.UninstallString -like "MsiExec*" -or $v.UninstallString -like "msiexec*") {
                $msiCode = ($v.UninstallString -split " ")[1] -replace "/I", "/X"
                Start-Process "msiexec.exe" -ArgumentList "$msiCode /quiet /norestart" -Wait -ErrorAction SilentlyContinue
            } else {
                $uninstExe = ($v.UninstallString -split '"')[1]
                if ($uninstExe -and (Test-Path $uninstExe)) {
                    Start-Process $uninstExe -ArgumentList "/uninstall /quiet" -Wait -ErrorAction SilentlyContinue
                }
            }
            Write-Host "    [OK] Uninstaller ran" -ForegroundColor Green
        }

        # 2. Delete folders
        Write-Host "    Deleting install folders..." -ForegroundColor Yellow
        $foldersToTry = @()
        if ($v.InstallLocation) { $foldersToTry += $v.InstallLocation }
        if ($verNoDot) {
            $foldersToTry += "$env:LOCALAPPDATA\Programs\Python\Python$verNoDot"
            $foldersToTry += "$env:LOCALAPPDATA\Programs\Python\Python$verNoDot-32"
            $foldersToTry += "$env:LOCALAPPDATA\Python\pythoncore-$shortVer-64"
            $foldersToTry += "$env:LOCALAPPDATA\Python\pythoncore-$shortVer-32"
            $foldersToTry += "$env:APPDATA\Python\Python$verNoDot"
        }
        foreach ($folder in $foldersToTry) {
            if ($folder -and (Test-Path $folder)) {
                Write-Host "       Deleting: $folder" -ForegroundColor DarkGray
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Host "    [OK] Folders cleaned" -ForegroundColor Green

        # 3. Clean PATH
        Write-Host "    Cleaning PATH..." -ForegroundColor Yellow
        foreach ($scope in @("User","Machine")) {
            $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
            if ($currentPath) {
                $cleaned = ($currentPath -split ";") | Where-Object {
                    $_ -notmatch "Python$verNoDot" -and
                    $_ -notmatch "Python\\$shortVer" -and
                    $_ -notmatch "python-$shortVer" -and
                    $_ -notmatch "pythoncore-$shortVer"
                }
                [Environment]::SetEnvironmentVariable("Path", ($cleaned -join ";"), $scope)
            }
        }
        Write-Host "    [OK] PATH cleaned" -ForegroundColor Green

        # 4. Clean registry
        Write-Host "    Cleaning registry..." -ForegroundColor Yellow
        $regKeysToDelete = @(
            "HKLM:\SOFTWARE\Python\PythonCore\$shortVer",
            "HKCU:\SOFTWARE\Python\PythonCore\$shortVer",
            "HKLM:\SOFTWARE\WOW6432Node\Python\PythonCore\$shortVer"
        )
        foreach ($key in $regKeysToDelete) {
            if (Test-Path $key) {
                Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "       Removed: $key" -ForegroundColor DarkGray
            }
        }
        Write-Host "    [OK] Registry cleaned" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  [DONE] Selected version(s) removed." -ForegroundColor Green
}

function Remove-StoreAlias {
    Write-Host ""
    Write-Host "  Removing Microsoft Store Python alias..." -ForegroundColor Yellow
    try {
        Get-AppxPackage *Python* | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage *PythonSoftwareFoundation* | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Host "  [OK] Microsoft Store Python removed" -ForegroundColor Green
    } catch {
        Write-Host "  [INFO] No Store Python found or already removed" -ForegroundColor Gray
    }

    # Also remove leftover WindowsApps python folders
    $storeFolder = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    @("python.exe","python3.exe","pip.exe","pip3.exe") | ForEach-Object {
        $f = Join-Path $storeFolder $_
        if (Test-Path $f) {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed store alias: $f" -ForegroundColor Green
        }
    }
}

function Clean-PipCache {
    Write-Host ""
    Write-Host "  Cleaning pip cache..." -ForegroundColor Yellow
    $pipCache = "$env:LOCALAPPDATA\pip\cache"
    if (Test-Path $pipCache) {
        Remove-Item -Path $pipCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] pip cache cleared: $pipCache" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] No pip cache found" -ForegroundColor Gray
    }
}

function Clean-AppDataFolders {
    Write-Host ""
    Write-Host "  Cleaning Python AppData folders..." -ForegroundColor Yellow
    $foldersToCheck = @(
        "$env:LOCALAPPDATA\Programs\Python",
        "$env:LOCALAPPDATA\Python",
        "$env:APPDATA\Python",
        "$env:LOCALAPPDATA\pip"
    )
    foreach ($folder in $foldersToCheck) {
        if (Test-Path $folder) {
            Write-Host "    Deleting: $folder" -ForegroundColor DarkGray
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    [OK] Deleted" -ForegroundColor Green
        }
    }
}

function Clean-PathEntries {
    Write-Host ""
    Write-Host "  Cleaning all Python entries from PATH..." -ForegroundColor Yellow
    foreach ($scope in @("User","Machine")) {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
        if ($currentPath) {
            $cleaned = ($currentPath -split ";") | Where-Object {
                $_ -notmatch "Python3\d*" -and
                $_ -notmatch "Python2\d*" -and
                $_ -notmatch "\\Python\\" -and
                $_ -notmatch "pythoncore" -and
                $_ -notmatch "WindowsApps.*python" -and
                $_ -notmatch "\\pip\\"
            }
            [Environment]::SetEnvironmentVariable("Path", ($cleaned -join ";"), $scope)
            Write-Host "  [OK] $scope PATH cleaned" -ForegroundColor Green
        }
    }
}

function Disable-AppAliases {
    Write-Host ""
    Write-Host "  Disabling App Execution Aliases for python.exe and python3.exe..." -ForegroundColor Yellow
    $aliasPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    $aliases = @("python.exe","python3.exe","pip.exe","pip3.exe")
    foreach ($alias in $aliases) {
        $fullPath = Join-Path $aliasPath $alias
        if (Test-Path $fullPath) {
            # Rename to disable without deleting
            Rename-Item $fullPath "$fullPath.disabled" -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Disabled: $alias" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "  NOTE: You can also disable these manually in:" -ForegroundColor DarkGray
    Write-Host "  Settings → Apps → Advanced app settings → App execution aliases" -ForegroundColor DarkGray
}

# ── RUN SELECTED OPTIONS ──────────────────────────────────────

switch ($menuChoice) {
    "1" { Remove-PythonVersions }
    "2" { Remove-StoreAlias }
    "3" { Clean-PipCache }
    "4" { Clean-AppDataFolders }
    "5" { Clean-PathEntries }
    "6" { Disable-AppAliases }
    "7" {
        Write-Host ""
        Write-Host "  !! FULL NUKE MODE — removing everything Python related !!" -ForegroundColor Red
        Write-Host ""
        Remove-PythonVersions
        Remove-StoreAlias
        Clean-PipCache
        Clean-AppDataFolders
        Clean-PathEntries
        Disable-AppAliases
    }
    default {
        Write-Host "  [ERROR] Invalid choice." -ForegroundColor Red
        pause
        exit
    }
}

# ── VERIFY ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Verifying..." -ForegroundColor Yellow
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$remaining = Get-Command python -ErrorAction SilentlyContinue
if ($remaining) {
    $ver = & python --version 2>&1
    Write-Host "  [INFO] Python still detected: $ver at $($remaining.Source)" -ForegroundColor Yellow
    Write-Host "         This may be a different version or needs a restart." -ForegroundColor Gray
} else {
    Write-Host "  [OK] No Python found in PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   Done! Restart your PC to finish the cleanup." -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""

# ── PROMPT: Disable App Execution Aliases manually ───────────
Write-Host "  ──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  IMPORTANT: Disable the Python app aliases in Windows too." -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Press  Win + I  to open Settings" -ForegroundColor White
Write-Host "  2. Go to:  Apps  →  Apps & Features" -ForegroundColor White
Write-Host "  3. Click:  App execution aliases" -ForegroundColor White
Write-Host "  4. Toggle OFF:  python.exe" -ForegroundColor White
Write-Host "  5. Toggle OFF:  python3.exe" -ForegroundColor White
Write-Host ""
Write-Host "  Without doing this, Windows may still redirect python" -ForegroundColor DarkGray
Write-Host "  commands to the Microsoft Store instead of your install." -ForegroundColor DarkGray
Write-Host "  ──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$openSettings = Read-Host "  Open App execution aliases now? (Y/N)"
if ($openSettings.Trim().ToUpper() -eq "Y") {
    Start-Process "ms-settings:appsfeatures-app"
    Write-Host ""
    Write-Host "  Settings opened — scroll down to find python.exe and toggle it OFF." -ForegroundColor Green
}

Write-Host ""
pause
