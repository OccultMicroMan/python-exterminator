# 🐍 Python Exterminator

> Cleanly remove Python from Windows — no leftovers, no confusion.

A free and open source PowerShell tool that completely uninstalls Python from Windows, cleaning up everything the standard uninstaller misses — leftover folders, PATH entries, registry keys, pip cache, and Microsoft Store redirects.

---

## Why does this exist?

Uninstalling Python on Windows is messier than it should be. The standard uninstaller often leaves behind:

- Orphaned folders in `AppData` and `Program Files`
- Stale entries in the system `PATH` that cause "wrong version" errors
- Registry keys that confuse other tools
- A Microsoft Store redirect that intercepts `python` commands even after Python is removed
- pip cache taking up disk space

Python Exterminator handles all of it — with plain English explanations at every step so you always know what's happening and why.

---

## Features

- 🔍 **Auto-detects** all Python versions installed on your system
- 🎯 **Targeted removal** — pick one version or remove all
- 🏪 **Removes Microsoft Store Python alias** — the fake redirect that opens the Store instead of running Python
- 🧹 **Cleans pip cache** — frees up disk space from cached package downloads
- 📁 **Cleans AppData folders** — removes leftover Python folders the uninstaller misses
- 🛤️ **Cleans PATH** — removes stale Python entries that cause version conflicts
- 🔒 **Disables App Execution Aliases** — stops Windows redirecting `python.exe` to the Store
- 💬 **Plain English explanations** — every action is explained before it runs
- 🔄 **Opens App Execution Aliases settings** automatically at the end
- ✅ **Verifies** the cleanup worked before closing

---

## Usage

### Step 1 — Download

Download `python_exterminator.ps1` from the [Releases](../../releases) page.

### Step 2 — Run as Administrator

Right-click the file → **Run with PowerShell as Administrator**

> Administrator is required to remove files from Program Files, clean the system PATH, and remove registry entries. The script will not run without it and will explain why if you forget.

### Step 3 — Pick what to clean

```
  [1]  Remove a specific Python version
  [2]  Remove Microsoft Store Python shortcut
  [3]  Clean pip cache
  [4]  Clean Python AppData folders
  [5]  Clean PATH environment variable
  [6]  Disable App Execution Aliases
  [7]  Full clean — do everything above
  [Q]  Quit
```

Type a number and press Enter. Option `7` is recommended if you want a completely fresh start.

---

## What does it actually do?

Every action is explained inside the script as it runs. Here's a summary:

| Option | What it does |
|---|---|
| **Remove version** | Runs the official Windows uninstaller silently, then removes any leftover folders, PATH entries, and registry keys for that specific version |
| **Store alias** | Removes the Microsoft Store Python package that shows up when you type `python` without Python installed |
| **pip cache** | Deletes `%LOCALAPPDATA%\pip\cache` — safe to delete, packages re-download if needed |
| **AppData folders** | Removes `%LOCALAPPDATA%\Programs\Python`, `%LOCALAPPDATA%\Python`, `%APPDATA%\Python` |
| **PATH cleanup** | Strips all Python-related entries from both User and System PATH — nothing else is touched |
| **App Execution Aliases** | Renames `python.exe` and `python3.exe` in the WindowsApps folder to `.disabled` and opens Settings for manual toggle |

---

## What it does NOT touch

- ❌ Your personal files or documents
- ❌ Other installed software
- ❌ Virtual environments in your project folders (`.venv`, `venv`, etc.)
- ❌ Any non-Python PATH entries
- ❌ Any registry keys outside of `SOFTWARE\Python`

---

## After running

1. **Restart your PC** — some changes only take full effect after a restart
2. Open Settings → Apps → **App execution aliases** → toggle OFF `python.exe` and `python3.exe` if still present
3. Download a fresh Python from [python.org](https://python.org) and check **"Add Python to PATH"** during install

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.0 or later (built into Windows — no install needed)
- Run as Administrator

---

## Security

This script is fully open source — every line is visible and readable. It makes no network requests, installs nothing, and only touches Python-related files and registry entries.

If you're not sure about running a PowerShell script, you can open it in any text editor (Notepad, VS Code, etc.) and read exactly what it does before running it.

---

## Contributing

Pull requests are welcome. Ideas for improvement:

- Support for detecting Python installed via Chocolatey, Scoop, or winget
- GUI wrapper
- Support for Linux/macOS (pyenv cleanup, etc.)
- Detection and cleanup of Anaconda/Miniconda installs

1. Fork the repo
2. Create your branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

MIT License — free to use, modify, and redistribute.

```
MIT License

Copyright (c) 2026 occult from ohio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Disclaimer

Python Exterminator modifies system settings including PATH, the registry, and installed packages. While it is designed to be safe and only removes Python-related data, use it at your own risk. Always make sure you have a backup if you are unsure.

The authors are not responsible for any issues that arise from use of this tool.

---

*Made with love, caffeine, and zyns by occult from ohio ❤️*
