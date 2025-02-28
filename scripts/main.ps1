# If test type is module, the code we ought to test is in the path/name folder, otherwise it's in the path folder.
$moduleName = if ([string]::IsNullOrEmpty($env:PSMODULE_TEST_PSMODULE_INPUT_Name)) {
    $env:GITHUB_REPOSITORY_NAME
} else {
    $env:PSMODULE_TEST_PSMODULE_INPUT_Name
}
$settings = $env:PSMODULE_TEST_PSMODULE_INPUT_Settings
$workingDirectory = $env:PSMODULE_TEST_PSMODULE_INPUT_WorkingDirectory
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$settings" | Select-Object -ExpandProperty Path
$localTestPath = Resolve-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'tests') | Select-Object -ExpandProperty Path
$codePath = switch ($settings) {
    'Module' {
        Resolve-Path -Path (Join-Path -Path $workingDirectory -ChildPath "outputs/module/$moduleName") | Select-Object -ExpandProperty Path
    }
    'SourceCode' {
        Resolve-Path -Path (Join-Path -Path $workingDirectory -ChildPath 'src') | Select-Object -ExpandProperty Path
    }
    default {
        throw "Invalid test type: [$settings]"
    }
}
[pscustomobject]@{
    ModuleName       = $moduleName
    Settings         = $settings
    CodePath         = $codePath
    LocalTestPath    = $localTestPath
    TestPath         = $testPath
    WorkingDirectory = $workingDirectory
} | Format-List

Set-GitHubOutput -Name ModuleName -Value $moduleName
Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name LocalTestPath -Value $localTestPath
Set-GitHubOutput -Name TestPath -Value $testPath
Set-GitHubOutput -Name WorkingDirectory -Value $workingDirectory
