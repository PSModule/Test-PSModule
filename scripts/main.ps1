[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Message
)
$Task = ($MyInvocation.MyCommand.Name).split('.')[0]

Write-Verbose "$Task`: Starting..."

Write-Verbose "$Task`: Message: $Message"
Write-Verbose "$Task`: Run Pester tests"
Write-Verbose "$Task`: Run PSScriptAnalyzer"
Write-Verbose "$Task`: Run linter on docs files"

Write-Verbose "$Task`: Stopping..."
