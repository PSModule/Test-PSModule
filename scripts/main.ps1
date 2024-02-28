#REQUIRES -Modules Utilities

[CmdletBinding()]
param()

Start-LogGroup 'Loading helper scripts'
Get-ChildItem -Path (Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts' 'helpers') -Filter '*.ps1' -Recurse |
    ForEach-Object { Write-Verbose "[$($_.FullName)]"; . $_.FullName }
Stop-LogGroup

Start-LogGroup 'Loading inputs'
$moduleName = ($env:GITHUB_ACTION_INPUT_Name | IsNullOrEmpty) ? $env:GITHUB_REPOSITORY_NAME : $env:GITHUB_ACTION_INPUT_Name
Write-Verbose "Module name:       [$moduleName]"

$codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:GITHUB_ACTION_INPUT_Path $moduleName
Write-Verbose "Code to test:      [$codeToTest]"
if (-not (Test-Path -Path $codeToTest)) {
    throw "Path [$codeToTest] does not exist."
}
Stop-LogGroup

$params = @{
    Path = $codeToTest
}
$results = Test-PSModule @params

Write-Verbose ($results | Out-String)

$failedTests = $results.FailedCount
if ($failedTests -eq 0) {
    Write-Output '::notice::✅ All tests passed.'
    Write-Verbose '✅ All tests passed.'
} else {
    Write-Output "::error::❌ Failed tests: [$failedTests]"
    Write-Warning "❌ Failed tests: [$failedTests]"
}
exit $failedTests
