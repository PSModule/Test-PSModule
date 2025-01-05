[CmdletBinding()]
param()

$path = (Join-Path -Path $PSScriptRoot -ChildPath 'helpers')
LogGroup "Loading helper scripts from [$path]" {
    Get-ChildItem -Path $path -Filter '*.ps1' -Recurse | ForEach-Object {
        Write-Host "[$($_.FullName)]"
        . $_.FullName
    }
}

LogGroup 'Loading inputs' {
    $moduleName = if ($env:GITHUB_ACTION_INPUT_Name | IsNullOrEmpty) { $env:GITHUB_REPOSITORY_NAME } else { $env:GITHUB_ACTION_INPUT_Name }
    $codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "$env:GITHUB_ACTION_INPUT_Path\$moduleName"
    if (-not (Test-Path -Path $codeToTest)) {
        $codeToTest = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $env:GITHUB_ACTION_INPUT_Path
    }
    if (-not (Test-Path -Path $codeToTest)) {
        throw "Path [$codeToTest] does not exist."
    }

    $testsPath = $env:GITHUB_ACTION_INPUT_TestsPath
    if (-not (Test-Path -Path $testsPath)) {
        throw "Path [$testsPath] does not exist."
    }

    $StackTraceVerbosity = $env:GITHUB_ACTION_INPUT_StackTraceVerbosity
    $Verbosity = $env:GITHUB_ACTION_INPUT_Verbosity

    [pscustomobject]@{
        ModuleName          = $moduleName
        CodeToTest          = $codeToTest
        TestType            = $env:GITHUB_ACTION_INPUT_TestType
        TestsPath           = $testsPath
        StackTraceVerbosity = $StackTraceVerbosity
        Verbosity           = $Verbosity
    } | Format-List
}

$params = @{
    Path                = $codeToTest
    TestType            = $env:GITHUB_ACTION_INPUT_TestType
    TestsPath           = $testsPath
    StackTraceVerbosity = $StackTraceVerbosity
    Verbosity           = $Verbosity
}
$testResults = Test-PSModule @params

LogGroup 'Test results' {
    $testResults | Format-List
}

$failedTests = [int]$testResults.FailedCount

if (($failedTests -gt 0) -or ($testResults.Result -ne 'Passed')) {
    Write-GitHubError "❌ Some [$failedTests] tests failed."
}
if ($failedTests -eq 0) {
    Write-GitHubNotice '✅ All tests passed.'
}

Set-GitHubOutput -Name 'passed' -Value ($failedTests -eq 0)
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
exit $failedTests
