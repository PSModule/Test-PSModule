# If test type is module, the code we ought to test is in the path/name folder, otherwise it's in the path folder.
$moduleName = [string]::IsNullOrEmpty($env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name) ? $env:GITHUB_REPOSITORY_NAME : $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name
$testType = $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_TestType
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$testType" | Select-Object -ExpandProperty Path
$codePath = $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path
# switch ($testType) {
#     'Module' {
#         Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path/outputs/modules/$moduleName" | Select-Object -ExpandProperty Path
#     }
#     'SourceCode' {
#         Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path/src" | Select-Object -ExpandProperty Path
#     }
#     default {
#         throw "Invalid test type: [$testType]"
#     }
# }

[pscustomobject]@{
    ModuleName = $moduleName
    TestType   = $testType
    CodePath   = $codePath
    TestPath   = $testPath
} | Format-List

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
