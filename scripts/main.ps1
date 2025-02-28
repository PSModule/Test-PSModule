# If test type is module, the code we ought to test is in the WorkingDirectory/outputs/module/Name folder, otherwise it's in the WorkingDirectory/src folder.
$moduleName = if ([string]::IsNullOrEmpty($env:PSMODULE_TEST_PSMODULE_INPUT_Name)) {
    $env:GITHUB_REPOSITORY_NAME
} else {
    $env:PSMODULE_TEST_PSMODULE_INPUT_Name
}
$settings = $env:PSMODULE_TEST_PSMODULE_INPUT_Settings
$workingDirectory = Resolve-Path -Path . | Select-Object -ExpandProperty Path
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$settings" | Select-Object -ExpandProperty Path

# Check if the tests directory exists before attempting to resolve its path
$localTestsDir = Join-Path -Path $workingDirectory -ChildPath 'tests'
$localTestPath = if (Test-Path -Path $localTestsDir) {
    Resolve-Path -Path $localTestsDir | Select-Object -ExpandProperty Path
} else {
    # Return the path even though it doesn't exist, to avoid errors
    $localTestsDir
}

# Check if expected code paths exist before resolving them
$codePath = switch ($settings) {
    'Module' {
        $moduleDir = Join-Path -Path $workingDirectory -ChildPath "outputs/module/$moduleName"
        if (Test-Path -Path $moduleDir) {
            Resolve-Path -Path $moduleDir | Select-Object -ExpandProperty Path
        } else {
            Write-Warning "Module directory does not exist: $moduleDir"
            $moduleDir
        }
    }
    'SourceCode' {
        $srcDir = Join-Path -Path $workingDirectory -ChildPath 'src'
        if (Test-Path -Path $srcDir) {
            Resolve-Path -Path $srcDir | Select-Object -ExpandProperty Path
        } else {
            Write-Warning "Source directory does not exist: $srcDir"
            $srcDir
        }
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
