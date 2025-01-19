<#
 	My Powershell Profile on Onedrive and using symbolic link.
#>

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis
#requires -Version 7.0

$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
# Function to install a PowerShell module if it is not already installed
function Install-ModuleAsNeeded {
	param (
		[string]$moduleName
	)
	if (-not (Get-Module -ListAvailable -Name $moduleName)) {
		try {
			Write-Host "Installing module $moduleName..."
			Install-Module -Name $moduleName -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
		}
		catch {
			Write-Error "Failed to install module $moduleName : $_"
		}
	}
}

# Ensure $ModulesToLoad is defined
if (-not $ModulesToLoad) {
	$ModulesToLoad = @('Terminal-Icons', 'PSReadLine', 'CompletionPredictor', 'PSScriptAnalyzer')
}

# Loop through each module in $ModulesToLoad and install if not available
foreach ($module in $ModulesToLoad) {
	if (-not (Get-Module -ListAvailable -Name $module)) {
		Install-ModuleAsNeeded -moduleName $module
	}
}

# Map PSDrives to other registry hives
$registryDrives = @(
	@{ Name = 'HKCR'; Root = 'HKEY_CLASSES_ROOT' },
	@{ Name = 'HKU'; Root = 'HKEY_USERS' }
)

foreach ($drive in $registryDrives) {
	if (!(Test-Path "$($drive.Name):")) {
		$null = New-PSDrive -Name $drive.Name -PSProvider Registry -Root $drive.Root
	}
}

# Check if I'm running with administration priviledge.
function Test-Administrator {
	return [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Set UTF-8 by default on all PowerShell version.
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF-8'


function Test-GitHubConnection {
	param (
		[string]$url = 'github.com'
	)
	# Initial GitHub.com connectivity check with 1 second timeout
	return Test-Connection $url -Count 1 -Quiet -TimeoutSeconds 1
}

function Get-LatestPowerShellVersion {
	param (
		[string]$apiUrl
	)
	try {
		$latestReleaseInfo = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 5
		return [Version]$latestReleaseInfo.tag_name.Trim('v')
	}
	catch {
		Write-Error "Failed to retrieve the latest PowerShell version. Error: $_"
		return $null
	}
}
function Update-PowerShell {
	if (-not (Test-GitHubConnection)) {
		Write-Host 'Skipping PowerShell update check due to GitHub.com not responding within 1 second.' -ForegroundColor Yellow
		return
	}

	Write-Host 'Checking for PowerShell updates...' -ForegroundColor Cyan
	$currentVersion = [Version]$PSVersionTable.PSVersion.ToString()
	$latestVersion = Get-LatestPowerShellVersion -apiUrl $gitHubApiUrl

	if ($null -eq $latestVersion) {
		Write-Host 'Could not determine the latest PowerShell version.' -ForegroundColor Red
		return
	}

	if ($latestVersion -gt $currentVersion) {
		Write-Host 'Updating PowerShell...' -ForegroundColor Yellow
		try {
			winget upgrade 'Microsoft.PowerShell' --accept-source-agreements --accept-package-agreements
			Write-Host 'PowerShell has been updated. Please restart your shell to reflect changes' -ForegroundColor Magenta
		}
		catch {
			Write-Error "Failed to update PowerShell. Error: $_"
		}
	}
	else {
		Write-Host 'Your PowerShell is up to date.' -ForegroundColor Green
	}
}

# Calling the Update-PowerShell function
Update-PowerShell

# Example usage of Test-Administrator function
if (!(Test-Administrator)) {
	$Host.UI.RawUI.WindowTitle = "User: "
	Start-Process PowerShell -Verb RunAsUser
}

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\blueish.omp.json" | Invoke-Expression

<#
The script first checks if the environment variable `$TERM_PROGRAM` is equal to 'VSCode' or if the environment variable `$WT_SESSION` is set. If either of these conditions is true, the script sets the value of the `$ansiesc` variable to the escape character used for ANSI escape sequences in the specific environment.
#>
if ($env:TERM_PROGRAM -eq 'VSCode' -or $env:WT_SESSION) {
	if ($psedition -eq 'core') {
		$ansiesc = "`e"
	}
 else {
		$ansiesc = [char]0x1b
	}

	# Most of this came from the Sample PSReadLineProfile.ps1 at GitHub, Microsoft, YouTube and Google searching.
	# The $PSROptions = @{} has helper in booting my Profile quicker.
	$PSReadLineOptions = @{
		ContinuationPrompt            = ' '
		Colors                        = @{
			Command            = "$($ansiesc)[93m"
			Comment            = "$($ansiesc)[32m"
			ContinuationPrompt = "$($ansiesc)[37m"
			Default            = "$($ansiesc)[37m"
			Emphasis           = "$($ansiesc)[96m"
			Error              = "$($ansiesc)[31m"
			Keyword            = "$($ansiesc)[35m"
			Member             = "$($ansiesc)[96m"
			Number             = "$($ansiesc)[35m"
			Operator           = "$($ansiesc)[37m"
			Parameter          = "$($ansiesc)[37m"
			Selection          = "$($ansiesc)[37;46m"
			String             = "$($ansiesc)[33m"
			Type               = "$($ansiesc)[34m"
			Variable           = "$($ansiesc)[96m"
		}
		PredictionSource              = "HistoryandPlugin"
		PredictionViewStyle           = "ListView"
		EditMode                      = "Windows"
		# PredictionViewCommand         = "Get-PSReadLinePrediction"
		HistorySaveStyle              = "SaveIncrementally"
		# PredictionSourceOptions       = @{
		#	Provider = "PSReadLinePredictionProvider"
		# }
		HistoryNoDuplicates           = $true
		HistorySearchCursorMovesToEnd = $true
		ShowToolTips                  = $true

		MaximumHistoryCount           = 4000
		BellStyle                     = "Audible"
		DingTone                      = 1234
		DingDuration                  = 100
		AddToHistoryHandler           = {
			param($line)
			if ($line -match '^\s*#') {
				return
			}
			$line
		}

	}
}

Set-PSReadLineOption @PSReadLineOptions
# Search for the previous item in the history that starts with the current input - like PreviousHistory if the input is empty.
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
# Search for the next item in the history that starts with the current input - like NextHistory if the input is empty.
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadLineKeyHandler -Key F7 `
	-BriefDescription History `
	-LongDescription 'Show command history' `
	-ScriptBlock {
	$pattern = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
	if ($pattern) {
		$pattern = [regex]::Escape($pattern)
	}

	$history = [System.Collections.ArrayList]@(
		$last = ''
		$lines = ''
		foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
			if ($line.EndsWith('`')) {
				$line = $line.Substring(0, $line.Length - 1)
				$lines = if ($lines) {
					"$lines`n$line"
				}
				else {
					$line
				}
				continue
			}

			if ($lines) {
				$line = "$lines`n$line"
				$lines = ''
			}

			if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
				$last = $line
				$line
			}
		}
	)
	$history.Reverse()

	$command = $history | Out-GridView -Title History -PassThru
	if ($command) {
		[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
	}
}

# This is an example of a macro that you might use to execute a command.
# This will add the command to history.
Set-PSReadLineKeyHandler -Key Ctrl+b `
	-BriefDescription "BuildCurrentDirectory" `
	-LongDescription "Build the current directory" `
	-ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert("msbuild")
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# Key Bindings for Tab Completion.
Set-PSReadLineKeyHandler -Key Ctrl+q -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Ctrl+Q -Function TabCompletePrevious

# Key bindings for Clipboard Interaction.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

# Key binding for Capturing Screen.
Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen

# Key bindings for Word Movement.
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord

#region Smart Insert/Delete

# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.

Set-PSReadLineKeyHandler -Key '"', "'" `
	-BriefDescription SmartInsertQuote `
	-LongDescription "Insert paired quotes if not already on a quote" `
	-ScriptBlock {
	param($key, $arg)

	$quote = $key.KeyChar

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	# If text is selected, just quote it without any smarts
	if ($selectionStart -ne -1) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
		return
	}

	function FindToken {
		param($tokens, $cursor)

		foreach ($token in $tokens) {
			if ($cursor -lt $token.Extent.StartOffset) {
				continue
			}
			if ($cursor -lt $token.Extent.EndOffset) {
				$result = $token
				$token = $token -as [StringExpandableToken]
				if ($token) {
					$nested = FindToken $token.NestedTokens $cursor
					if ($nested) {
						$result = $nested
					}
				}

				return $result
			}
		}
		return $null
	}

	$token = FindToken $tokens $cursor

	# If we're on or inside a **quoted** string token (so not generic), we need to be smarter
	if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
		# If we're at the start of the string, assume we're inserting a new string
		if ($token.Extent.StartOffset -eq $cursor) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}

		# If we're at the end of the string, move over the closing quote if present.
		if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
			return
		}
	}

	if ($null -eq $token -or
		$token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
		if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
			# Odd number of quotes before the cursor, insert a single quote
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
		}
		else {
			# Insert matching quotes, move cursor to be in between the quotes
			[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
		}
		return
	}

	# If cursor is at the start of a token, enclose it in quotes.
	if ($token.Extent.StartOffset -eq $cursor) {
		if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or
			$token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
			$end = $token.Extent.EndOffset
			$len = $end - $cursor
			[Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
			[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
			return
		}
	}

	# We failed to be smart, so just insert a single quote
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(', '{', '[' `
	-BriefDescription InsertPairedBraces `
	-LongDescription "Insert matching braces" `
	-ScriptBlock {
	param($key, $arg)

	$closeChar = switch ($key.KeyChar) {
		<#case#> '(' {
			[char]')'; break
		}
		<#case#> '{' {
			[char]'}'; break
		}
		<#case#> '[' {
			[char]']'; break
		}
	}

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($selectionStart -ne -1) {
		# Text is selected, wrap it in brackets
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	}
 else {
		# No text is selected, insert a pair
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
	-BriefDescription SmartCloseBraces `
	-LongDescription "Insert closing brace or skip" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($line[$cursor] -eq $key.KeyChar) {
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
	}
}

Set-PSReadLineKeyHandler -Key Backspace `
	-BriefDescription SmartBackspace `
	-LongDescription "Delete previous character or matching quotes/parens/braces" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -gt 0) {
		$toMatch = $null
		if ($cursor -lt $line.Length) {
			switch ($line[$cursor]) {
				<#case#> '"' {
					$toMatch = '"'; break
				}
				<#case#> "'" {
					$toMatch = "'"; break
				}
				<#case#> ')' {
					$toMatch = '('; break
				}
				<#case#> ']' {
					$toMatch = '['; break
				}
				<#case#> '}' {
					$toMatch = '{'; break
				}
			}
		}

		if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
			[Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
		}
		else {
			[Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
		}
	}
}

#endregion Smart Insert/Delete

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.
Set-PSReadLineKeyHandler -Key Alt+w `
	-BriefDescription SaveInHistory `
	-LongDescription "Save current line in history but do not execute" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
	-BriefDescription PasteAsHereString `
	-LongDescription "Paste the clipboard text as a here string" `
	-ScriptBlock {
	param($key, $arg)

	Add-Type -Assembly PresentationCore
	if ([System.Windows.Clipboard]::ContainsText()) {
		# Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
		$text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Ding()
	}
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
	-BriefDescription ParenthesizeSelection `
	-LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
	-ScriptBlock {
	param($key, $arg)

	$selectionStart = $null
	$selectionLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	if ($selectionStart -ne -1) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
		[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	}
	else {
		[Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
		[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
	}
}

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.
Set-PSReadLineKeyHandler -Key "Alt+'" `
	-BriefDescription ToggleQuoteArgument `
	-LongDescription "Toggle quotes on the argument under the cursor" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$tokenToChange = $null
	foreach ($token in $tokens) {
		$extent = $token.Extent
		if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
			$tokenToChange = $token

			# If the cursor is at the end (it's really 1 past the end) of the previous token,
			# we only want to change the previous token if there is no token under the cursor
			if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
				$nextToken = $foreach.Current
				if ($nextToken.Extent.StartOffset -eq $cursor) {
					$tokenToChange = $nextToken
				}
			}
			break
		}
	}

	if ($tokenToChange -ne $null) {
		$extent = $tokenToChange.Extent
		$tokenText = $extent.Text
		if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
			# Switch to no quotes
			$replacement = $tokenText.Substring(1, $tokenText.Length - 2)
		}
		elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
			# Switch to double quotes
			$replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
		}
		else {
			# Add single quotes
			$replacement = "'" + $tokenText + "'"
		}

		[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
			$extent.StartOffset,
			$tokenText.Length,
			$replacement)
	}
}

# This example will replace any aliases on the command line with the resolved commands.
Set-PSReadLineKeyHandler -Key "Alt+%" `
	-BriefDescription ExpandAliases `
	-LongDescription "Replace all aliases with the full command" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$startAdjustment = 0
	foreach ($token in $tokens) {
		if ($token.TokenFlags -band [TokenFlags]::CommandName) {
			$alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
			if ($alias -ne $null) {
				$resolvedCommand = $alias.ResolvedCommandName
				if ($resolvedCommand -ne $null) {
					$extent = $token.Extent
					$length = $extent.EndOffset - $extent.StartOffset
					[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
						$extent.StartOffset + $startAdjustment,
						$length,
						$resolvedCommand)

					# Our copy of the tokens won't have been updated, so we need to
					# adjust by the difference in length
					$startAdjustment += ($resolvedCommand.Length - $length)
				}
			}
		}
	}
}

# F1 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F1 `
	-BriefDescription CommandHelp `
	-LongDescription "Open the help window for the current command" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$tokens = $null
	$errors = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

	$commandAst = $ast.FindAll( {
			$node = $args[0]
			$node -is [CommandAst] -and
			$node.Extent.StartOffset -le $cursor -and
			$node.Extent.EndOffset -ge $cursor
		}, $true) | Select-Object -Last 1

	if ($commandAst -ne $null) {
		$commandName = $commandAst.GetCommandName()
		if ($commandName -ne $null) {
			$command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
			if ($command -is [AliasInfo]) {
				$commandName = $command.ResolvedCommandName
			}

			if ($commandName -ne $null) {
				Get-Help $commandName -ShowWindow
			}
		}
	}
}


#
# Ctrl+Shift+j then type a key to mark the current directory.
# Ctrj+j then the same key will change back to that directory without
# needing to type cd and won't change the command line.

#
$global:PSReadLineMarks = @{}

Set-PSReadLineKeyHandler -Key Ctrl+J `
	-BriefDescription MarkDirectory `
	-LongDescription "Mark the current directory" `
	-ScriptBlock {
	param($key, $arg)

	$key = [Console]::ReadKey($true)
	$global:PSReadLineMarks[$key.KeyChar] = $pwd
}

Set-PSReadLineKeyHandler -Key Ctrl+j `
	-BriefDescription JumpDirectory `
	-LongDescription "Goto the marked directory" `
	-ScriptBlock {
	param($key, $arg)

	$key = [Console]::ReadKey()
	$dir = $global:PSReadLineMarks[$key.KeyChar]
	if ($dir) {
		Set-Location $dir
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
	}
}

Set-PSReadLineKeyHandler -Key Alt+j `
	-BriefDescription ShowDirectoryMarks `
	-LongDescription "Show the currently marked directories" `
	-ScriptBlock {
	param($key, $arg)

	$global:PSReadLineMarks.GetEnumerator() | ForEach-Object {
		[PSCustomObject]@{Key = $_.Key; Dir = $_.Value } } |
	Format-Table -AutoSize | Out-Host

	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# Auto correct 'git cmt' to 'git commit'
Set-PSReadLineOption -CommandValidationHandler {
	param([CommandAst]$CommandAst)

	switch ($CommandAst.GetCommandName()) {
		'git' {
			$gitCmd = $CommandAst.CommandElements[1].Extent
			switch ($gitCmd.Text) {
				'cmt' {
					[Microsoft.PowerShell.PSConsoleReadLine]::Replace(
						$gitCmd.StartOffset, $gitCmd.EndOffset - $gitCmd.StartOffset, 'commit')
				}
			}
		}
	}
}

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
	-BriefDescription ForwardCharAndAcceptNextSuggestionWord `
	-LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
	-ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -lt $line.Length) {
		[Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
	}
 else {
		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
	}
}

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line.
Set-PSReadLineKeyHandler -Key Alt+a `
	-BriefDescription SelectCommandArguments `
	-LongDescription "Set current selection to next command argument in the command line. Use of digit argument selects argument by position" `
	-ScriptBlock {
	param($key, $arg)

	$ast = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)

	$asts = $ast.FindAll( {
			$args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
			$args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
			$args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
		}, $true)

	if ($asts.Count -eq 0) {
		[Microsoft.PowerShell.PSConsoleReadLine]::Ding()
		return
	}

	$nextAst = $null

	if ($null -ne $arg) {
		$nextAst = $asts[$arg - 1]
	}
	else {
		foreach ($ast in $asts) {
			if ($ast.Extent.StartOffset -ge $cursor) {
				$nextAst = $ast
				break
			}
		}

		if ($null -eq $nextAst) {
			$nextAst = $asts[0]
		}
	}

	$startOffsetAdjustment = 0
	$endOffsetAdjustment = 0

	if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
		$nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
		$startOffsetAdjustment = 1
		$endOffsetAdjustment = 2
	}

	[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
	[Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
	[Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
}

# Allow you to type a Unicode code point, then pressing `Alt+x` to transform it into a Unicode char.
Set-PSReadLineKeyHandler -Chord 'Alt+x' `
	-BriefDescription ToUnicodeChar `
	-LongDescription "Transform Unicode code point into a UTF-16 encoded string" `
	-ScriptBlock {
	$buffer = $null
	$cursor = 0
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $buffer, [ref] $cursor)
	if ($cursor -lt 4) {
		return
	}

	$number = 0
	$isNumber = [int]::TryParse(
		$buffer.Substring($cursor - 4, 4),
		[System.Globalization.NumberStyles]::AllowHexSpecifier,
		$null,
		[ref] $number)

	if (-not $isNumber) {
		return
	}

	try {
		$unicode = [char]::ConvertFromUtf32($number)
	}
 catch {
		return
	}

	[Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 4, 4)
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert($unicode)
}

# Move the cursor to the next line without attempting to execute the input
Set-PSReadLineKeyHandler -Chord Shift+Enter -Function AddLine
# Move the cursor forward to the end of the current word, or if between words, to the end of the next word.
Set-PSReadLineKeyHandler -Chord Ctrl+f -Function ForwardWord
# Accept the input or move to the next line if input is missing a closing token.
# If there are other parse errors, unresolved commands, or incorrect parameters, show the error and continue editing.
Set-PSReadLineKeyHandler -Chord Enter -Function ValidateAndAcceptLine
$scriptblock = {
	param($wordToComplete, $commandAst, $cursorPosition)
	dotnet Complete --positioon $cursorPosition $commandAst.ToString() |
	ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompleteNext

# Complete the input if there is a single completion, otherwise complete the input by selecting from a menu of possible completions.
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# This function Test-CommandExists is used to check for editor is available or not.
function Test-CommandExists {
	param (
		[string]$command
	)
	# By placing `$null` on the left side, you ensure that the comparison is always valid, even if the command does not exist.
	return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}
# This is an array that containing a list of editor names.
$editors = @('nvim', 'pvim', 'vim', 'vi', 'code', 'notepad++', 'sublime_text', 'notepad')

# $EDITOR is a variable that will store the editor name.
$EDITOR = $null

# Loop through the list of editors and check if the command exists.
foreach ($editor in $editors) {
	# If the command exists, set the $EDITOR variable to the editor name and break the loop.
	if (Test-CommandExists $editor) {
		# Set the $EDITOR variable to the editor name and break the loop.
		$EDITOR = $editor
		break
	}
}
# If the $EDITOR variable is still null, set it to 'notepad'.
if (-not $EDITOR) {
	$EDITOR = 'notepad'
}

# The Edit-Profile use $PROFILE variable to the path of the current user's profile to edit the script.
function Edit-Profile {
	vim $PROFILE
}

function Sync-Profile {
	try {
		# The dot operator is used to source the profile script.
		. $profile
		# Writes to the console to indicate that the profile has been reloaded successfully or not.

		Write-Output "Profile reloaded successfully."
	}
 catch {
		Write-Output "Failed to reload profile: $_"
	}
}

function unzip ($file) {
	try {
		Write-Output("Extracting $file to $pwd")
		$fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }

		if (-not $fullFile) {
			throw "File '$file' not found in the current directory."
		}

		Expand-Archive -Path $fullFile -DestinationPath $pwd
		Write-Output("Extraction completed successfully.")
	}
 catch {
		Write-Output("Failed to extract $file $_")
	}
}
function Clear-Cache {
	try {
		Write-Host "Starting Cache Clearing..." -ForegroundColor Green

		# Clear Windows Prefetch
		Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
		Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

		# Clear Windows Temp
		Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
		Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear User Temp
		Write-Host "Clearing User Temp..." -ForegroundColor Yellow
		Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear Internet Explorer Cache
		Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
		Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear Recycle Bin
		Write-Host "Clearing Recycle Bin..." -ForegroundColor Yellow
		Clear-RecycleBin -Force

		# Clear Google Chrome Caches
		Write-Host "Clearing Google Caches..." -ForegroundColor Yellow
		Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
		Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue

		Write-Host "Cache clearing completed successfully." -ForegroundColor Green
	}
 catch {
		Write-Error "Failed to clear cache: $_"
	}
}

# Git Shortcuts
function Get-GitWhoami {
	$author = git config --get user.name
	$email = git config --get user.email

	[PSCustomObject]@{
		Arthur = $author
		Email  = $email
	}
}
Set-Alias -Name GWhoami -Value Get-GitWhoami
function gs {
 git status
}

function Get-GitLog {
	git log --oneline --graph --decorate
}
Set-Alias -Name GGL -Value Get-GitLog

function ga {
 git add .
}

function gc {
 param($m) git commit -m "$m"
}

function gp {
 git push
}

function g {
 __zoxide_z github
}

function gcl {
 git clone "$args"
}

function gcom {
	git add .
	git commit -m "$args"
}
function lazyg {
	git add .
	git commit -m "$args"
	git push
}

# Quick Access to System Information
function sysinfo {
 Get-ComputerInfo
}

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Aliases
Set-Alias open Invoke-Item
Set-Alias -Name vim -Value $EDITOR
Set-Alias -Name ep -Value Edit-Profile
Set-Alias -Name Reload-Profile -Value Sync-Profile
Set-Alias -Name reload -Value Sync-Profile
Set-Alias -Name reset -Value Sync-Profile

# Aliases function
function ll() {
 Get-ChildItem | Format-Table
}
function la() {
 Get-ChildItem | Format-Wide
}
function lb() {
 Get-ChildItem | Format-List
}
function which($name) {
	Get-Command $name | Select-Object -ExpandProperty Definition
}
# Set Aliases to the functions la, lb.
Set-Alias ls la
Set-Alias l lb