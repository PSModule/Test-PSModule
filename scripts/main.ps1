$helperPath = "$PSScriptRoot/../../../helpers"
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
        $localRepo = @{
            Name     = 'Local'
            Uri      = New-Item -Path $PSScriptRoot -Name '.localpsmodulerepo' -ItemType Directory
            Trusted  = $true
            Priority = 100
        }
        Register-PSResourceRepository @localRepo
        $manifestFilePath = Join-Path -Path $codePath "$moduleName.psd1"
        Write-Verbose " - Manifest file path: [$manifestFilePath]" -Verbose
        Resolve-PSModuleDependency -ManifestFilePath $manifestFilePath
        Publish-PSResource -Path $codePath -Repository Local
        Install-PSResource -Name $moduleName -Repository Local
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
    CodePath      = $codePath
    LocalTestPath = $localTestPath
    TestPath      = $testPath
} | Format-List | Out-String

Set-GitHubOutput -Name ModuleName -Value $moduleName
Set-GitHubOutput -Name CodePath -Value $codePath
Set-GitHubOutput -Name LocalTestPath -Value $localTestPath
Set-GitHubOutput -Name TestPath -Value $testPath
