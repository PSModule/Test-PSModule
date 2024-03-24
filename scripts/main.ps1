#REQUIRES -Modules Utilities

[CmdletBinding()]
param()

Start-LogGroup 'Loading helper scripts'
Get-ChildItem -Path (Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts/helpers') -Filter '*.ps1' -Recurse |
    ForEach-Object { Write-Verbose "[$($_.FullName)]"; . $_.FullName }
Stop-LogGroup

Start-LogGroup 'Loading inputs'
$moduleName = if ($env:GITHUB_ACTION_INPUT_Name | IsNullOrEmpty) { $env:GITHUB_REPOSITORY_NAME } else { $env:GITHUB_ACTION_INPUT_Name }
Write-Verbose "Module name:       [$moduleName]"

$codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:GITHUB_ACTION_INPUT_Path $moduleName
Write-Verbose "Code to test:      [$codeToTest]"
if (-not (Test-Path -Path $codeToTest)) {
    throw "Path [$codeToTest] does not exist."
}
$runModuleTests = $env:GITHUB_ACTION_INPUT_RunModuleTests -eq 'true'
Write-Verbose "Run module tests:  [$runModuleTests]"

Stop-LogGroup

$params = @{
    Path           = $codeToTest
    RunModuleTests = $runModuleTests
}
$results = Test-PSModule @params

Start-LogGroup 'Test results'
Write-Verbose ($results | Out-String)
Stop-LogGroup

$failedTests = $results.FailedCount

if ($failedTests -gt 0) {
    Write-Output '::error::❌ Some tests failed.'
    exit $failedTests
}
if ($results.Result -ne 'Passed') {
    Write-Output '::error::❌ Some tests failed.'
    exit 1
}
if ($failedTests -eq 0) {
    Write-Output '::notice::✅ All tests passed.'
}
