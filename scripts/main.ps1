# If test type is module, the code we ought to test is in the path/name folder, otherwise it's in the path folder.
$moduleName = if ([string]::IsNullOrEmpty($env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name)) {
    $env:GITHUB_REPOSITORY_NAME
} else {
    $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Name
}
$settings = $env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Settings
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$settings" | Select-Object -ExpandProperty Path
$codePath = switch ($settings) {
    'Module' {
        Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path/outputs/modules/$moduleName" | Select-Object -ExpandProperty Path
    }
    'SourceCode' {
        Resolve-Path -Path "$env:GITHUB_ACTION_INPUT_TEST_PSMODULE_Path/src" | Select-Object -ExpandProperty Path
    }
    default {
        throw "Invalid test type: [$settings]"
    }
}

[pscustomobject]@{
    ModuleName = $moduleName
    Settings   = $settings
    CodePath   = $codePath
    TestPath   = $testPath
} | Format-List

Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name TestPath -Value $testPath
