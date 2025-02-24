# If test type is module, the code we ought to test is in the path/name folder, otherwise it's in the path folder.
$moduleName = if ([string]::IsNullOrEmpty($env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name)) {
    $env:GITHUB_REPOSITORY_NAME
} else {
    $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name
}
$settings = $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Settings
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$settings" | Select-Object -ExpandProperty Path
$codePath = Resolve-Path -Path $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path | Select-Object -ExpandProperty Path

[pscustomobject]@{
    ModuleName = $moduleName
    Settings   = $settings
    CodePath   = $codePath
    TestPath   = $testPath
} | Format-List

Set-GitHubOutput -Name ModuleName -Value $moduleName
Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
