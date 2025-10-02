# My PowerShell 7 Profile

Version: 1.0 • Status: Work in progress

A personal PowerShell 7 profile that customizes the prompt, improves shell ergonomics, and configures useful modules (for example, PSReadLine). This repository contains my `profile.ps1` and notes on installation and customization.

## Goals

- Improve prompt readability and useful information at a glance
- Add helpful aliases and functions for faster workflows
- Configure PSReadLine for better editing (history, completion, key bindings)
- Keep configuration modular and easy to tweak

## Contents

- `profile.ps1` — main PowerShell profile loaded on shell start
- `README.md` — this file with usage and notes

## Requirements

- PowerShell 7.x
- Windows (tested on Windows 10/11) — should work on other OSes with minor tweaks
- Optional modules: PSReadLine, posh-git, oh-my-posh (install as needed)

## Install / Apply

1. Backup your current profile (if any):

   ```powershell
   Copy-Item $PROFILE $PROFILE.bak -Force
   ```
