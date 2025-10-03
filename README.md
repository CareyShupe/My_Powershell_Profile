# My PowerShell 7 Profile

Version: 1.0 • Status: Work in progress

This is a personal PowerShell 7 profile that customizes the prompt, improves shell ergonomics, and configures useful modules such as 'PSScriptAnalyzer', 'Pester', 'PowerShellGet', 'PackageManagement', 'Terminal-Icons', 'PSReadLine'. The repository contains a single entry point: `profile.ps1`, plus notes on installation, customization, and troubleshooting.

## Table of contents

- Quickstart
- Install (detailed)
- What's in `profile.ps1`
- Configuration & customization
- PowerShell 7.x (pwsh)
- Windows 10/11 supported; should work on macOS/Linux with minor path/module tweaks
- Administrator privileges are not required for `-Scope CurrentUser` installs

1. Backup your current profile

```powershell
if (Test-Path $PROFILE) { Copy-Item -Path $PROFILE -Destination "$PROFILE.bak" -Force }
```

1. Install recommended modules (run as an elevated prompt only if you need system-wide install)

```powershell
Install-Module -Name PSReadLine -Scope CurrentUser -Force
Install-Module -Name posh-git -Scope CurrentUser -Force
Install-Module -Name oh-my-posh -Scope CurrentUser -Force
```

Notes on ExecutionPolicy

- If the profile fails to load due to ExecutionPolicy, run:

```powershell
Get-ExecutionPolicy -List
# To allow running local scripts for current user (safer than changing machine policy):
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

1. Install / apply this profile

```powershell
Copy-Item -Path .\profile.ps1 -Destination $PROFILE -Force
```

1. Reload PowerShell (start a new session) or dot-source to apply immediately

```powershell
# Start a new pwsh session
pwsh

# or in current session (temporary until next restart)
. $PROFILE
```

1. Restore your previous profile if needed

```powershell
if (Test-Path "$PROFILE.bak") { Copy-Item -Path "$PROFILE.bak" -Destination $PROFILE -Force }
```

## What's in `profile.ps1`

- Prompt customization: a compact, information-dense prompt showing git status, current directory, and exit code when non-zero
- PSReadLine configuration: history size, completion settings, and key bindings
- Aliases and helper functions: frequently used shortcuts for productivity
- Module imports: conditional loading of `posh-git`, `oh-my-posh`, and other optional modules
- Config toggles: simple boolean variables near the top of the file to enable/disable sections

Open `profile.ps1` to find short, well-documented sections and easy-to-edit toggles.

## Configuration & customization

This profile uses a few boolean toggles near the top of `profile.ps1` so you can enable or disable features quickly. Example variables you may see and adjust:

```powershell
$EnablePoshGit = $true
$EnableOhMyPosh = $false
$PromptShowExitCode = $true
$CustomPromptTheme = 'paradox' # if oh-my-posh is enabled
```

To customize colors or prompt elements, edit the relevant section in `profile.ps1`. Most functions include short comments that explain available variables and options.

If you prefer to keep your own additions, consider sourcing this profile from your existing `$PROFILE` instead of overwriting it. Example merge snippet:

```powershell
# Append this repo's profile at the end of your existing profile
Add-Content -Path $PROFILE -Value "`n# Source personal profile from repo`n. 'C:\path\to\repo\profile.ps1'"
```

## Examples

- Useful aliases (examples that may exist in `profile.ps1`):

```text
gco -> git checkout
gs  -> git status
ll  -> ls -Force -File -Directory -ErrorAction SilentlyContinue
```

- Example helper function (copy from profile for real usage):

```powershell
function Quick-Run { param($Script) pwsh -NoProfile -Command $Script }
```

- Example prompt (ASCII representation):

```text
[user@machine] C:\Projects\Repo (main ✗) >
```

Replace the icons or git symbols if your terminal/font does not support them.

## Troubleshooting

- Profile doesn't load?

  - Verify the profile path exists:

      ```powershell
      Test-Path $PROFILE
      Get-Content $PROFILE -ErrorAction SilentlyContinue
      ```

  - Check execution policy and set it for the current user if required:

      ```powershell
      Get-ExecutionPolicy -List
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
      ```

- Module install failures:

  - Ensure PackageManagement and PowerShellGet are updated, then retry:

      ```powershell
      Install-Module -Name PowerShellGet -Force -Scope CurrentUser
      Update-Module -Name PowerShellGet -Force -Scope CurrentUser
      ```

- Prompt looks broken (weird characters / missing icons):

  - Install a Nerd Font or change symbols to plain text in `profile.ps1`.

- Want to revert quickly?

  - Restore from backup created earlier:

      ```powershell
      if (Test-Path "$PROFILE.bak") { Copy-Item -Path "$PROFILE.bak" -Destination $PROFILE -Force }
      ```

If a section of `profile.ps1` causes problems, you can temporarily disable it by setting the toggle variable to `$false` and starting a new session.

## Contributing

Contributions and suggestions are welcome. A simple workflow:

1. Fork the repo and create a feature branch.
2. Make small, focused commits and include explanations in the PR description.
3. If you add new functionality, include a short usage example in `README.md`.

Coding style notes:

- Keep functions small and well-documented with parameter validation where appropriate.
- Avoid global state where possible; use clearly named toggle variables for user-facing options.

## License & changelog

This repository is licensed under the MIT License — see the `LICENSE` file for details.

Changelog: Keep a `CHANGELOG.md` or use GitHub releases to track major changes.

---

If you'd like, I can also:

- Add a short screenshot or animated GIF showing the prompt in action.
- Add a `LICENSE` file (MIT) and a short `CONTRIBUTING.md` with a PR template.

Would you like me to apply this README update now (I can commit the change), or make additional changes (add a LICENSE file, screenshots, or tweak wording)?
