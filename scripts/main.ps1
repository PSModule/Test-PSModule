[CmdletBinding()]
param()
$Task = ($MyInvocation.MyCommand.Name).split('.')[0]

Write-Verbose "$Task`: Starting..."
#Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Verbose:$false
#Invoke-ScriptAnalyzer -Path .\src\Fonts -Recurse -Verbose
#Install-Module -Name Pester -Scope CurrentUser -Force -Verbose:$false

Write-Verbose "$Task`: Message: $Path"
Write-Verbose "$Task`: Run Pester tests"
Get-ChildItem -Recurse | Select-Object -ExpandProperty FullName | Sort-Object
Write-Verbose "$Task`: Run PSScriptAnalyzer"
Write-Verbose "$Task`: Run linter on docs files"
Write-Verbose "$Task`: Stopping..."
