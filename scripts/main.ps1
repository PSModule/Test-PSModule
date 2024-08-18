[CmdletBinding()]
param()

LogGroup 'Loading helper scripts' {
    Get-ChildItem -Path (Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts' 'helpers') -Filter '*.ps1' -Recurse |
        ForEach-Object { Write-Verbose "[$($_.FullName)]"; . $_.FullName }
}

Start-LogGroup 'Loading inputs'
$moduleName = if ($env:GITHUB_ACTION_INPUT_Name | IsNullOrEmpty) { $env:GITHUB_REPOSITORY_NAME } else { $env:GITHUB_ACTION_INPUT_Name }
Write-Verbose "Module name:       [$moduleName]"

$codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "$env:GITHUB_ACTION_INPUT_Path\$moduleName"
if (Test-Path -Path $codeToTest) {
    Write-Verbose "Code to test:      [$codeToTest]"
} else {
    $codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:GITHUB_ACTION_INPUT_Path
}

Write-Verbose "Code to test:      [$codeToTest]"
if (-not (Test-Path -Path $codeToTest)) {
    throw "Path [$codeToTest] does not exist."
}
Write-Verbose "Test type to run:  [$env:GITHUB_ACTION_INPUT_TestType]"

$testsPath = $env:GITHUB_ACTION_INPUT_TestsPath
Write-Verbose "Path to tests:    [$testsPath]"
if (-not (Test-Path -Path $testsPath)) {
    throw "Path [$testsPath] does not exist."
}

Stop-LogGroup

$params = @{
    Path      = $codeToTest
    TestType  = $env:GITHUB_ACTION_INPUT_TestType
    TestsPath = $testsPath
}
$results = Test-PSModule @params

Start-LogGroup 'Test results'
Write-Verbose ($results | Out-String)
Stop-LogGroup

$failedTests = $results.FailedCount

if ($failedTests -gt 0) {
    Write-Host '::error::❌ Some tests failed.'
    return $false
}
if ($results.Result -ne 'Passed') {
    Write-Host '::error::❌ Some tests failed.'
    return $false
}
if ($failedTests -eq 0) {
    Write-Host '::notice::✅ All tests passed.'
    return $true
}
