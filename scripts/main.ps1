$helperPath = "$PSScriptRoot/helpers"
Get-ChildItem -Path $helperPath -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

# If test type is module, the code we ought to test is in the WorkingDirectory/outputs/module/Name folder,
# otherwise it's in the WorkingDirectory/src folder.

$moduleName = if ([string]::IsNullOrEmpty($env:PSMODULE_TEST_PSMODULE_INPUT_Name)) {
    $env:GITHUB_REPOSITORY_NAME
} else {
    $env:PSMODULE_TEST_PSMODULE_INPUT_Name
}
$settings = $env:PSMODULE_TEST_PSMODULE_INPUT_Settings
$testPath = Resolve-Path -Path "$PSScriptRoot/tests/$settings" | Select-Object -ExpandProperty Path

$localTestPath = Resolve-Path -Path 'tests' | Select-Object -ExpandProperty Path
switch ($settings) {
    'Module' {
        $codePath = Resolve-Path -Path "outputs/module/$moduleName" | Select-Object -ExpandProperty Path
        $manifestFilePath = Join-Path -Path $codePath "$moduleName.psd1"
        Write-Verbose " - Manifest file path: [$manifestFilePath]" -Verbose
        Resolve-PSModuleDependency -ManifestFilePath $manifestFilePath
        $PSModulePath = $env:PSModulePath -split [System.IO.Path]::PathSeparator | Select-Object -First 1
        $moduleInstallPath = New-Item -Path "$PSModulePath/$moduleName/999.0.0" -ItemType Directory -Force
        Copy-Item -Path $codePath -Destination $moduleInstallPath -Recurse -Force
        Get-ChildItem -Path $moduleInstallPath -Recurse | Select-Object FullName | Out-String
        Import-Module -Name $moduleName -Verbose
    }
    'SourceCode' {
        $codePath = Resolve-Path -Path 'src' | Select-Object -ExpandProperty Path
    }
    default {
        throw "Invalid test type: [$settings]"
    }
}

[pscustomobject]@{
    ModuleName    = $moduleName
    Settings      = $settings
    CodePath      = $moduleInstallPath
    LocalTestPath = $localTestPath
    TestPath      = $testPath
} | Format-List | Out-String

Set-GitHubOutput -Name ModuleName -Value $moduleName
Set-GitHubOutput -Name CodePath -Value $moduleInstallPath
Set-GitHubOutput -Name LocalTestPath -Value $localTestPath
Set-GitHubOutput -Name TestPath -Value $testPath
