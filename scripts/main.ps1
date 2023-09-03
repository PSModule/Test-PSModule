[CmdletBinding()]
param()
$Task = 'Test-Module'

Write-Verbose "$Task`: Starting..."
#Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Verbose:$false
#Invoke-ScriptAnalyzer -Path .\src\Fonts -Recurse -Verbose
#Install-Module -Name Pester -Scope CurrentUser -Force -Verbose:$false

Write-Verbose "$Task`: Message: $Path"
# Import the module using Import-Module $moduleManifestFilePath,
# Do not not just add the outputted module file to the PATH of the runner (current context is enough) $env:PATH += ";.\outputs\$moduleName" as the import-module will actually test that the module is importable.
Write-Verbose "$Task`: Test module manifest"
# Run tests from "".\tests\$moduleName.Tests.ps1"
Test-ModuleManifest -Path $Path
Write-Verbose "$Task`: Run Pester tests"
Get-ChildItem -Recurse | Select-Object -ExpandProperty FullName | Sort-Object
Write-Verbose "$Task`: Run PSScriptAnalyzer"
Write-Verbose "$Task`: Run linter on docs files"
Write-Verbose "$Task`: Stopping..."
