function Test-PSModule {
    <#
        .SYNOPSIS
        Performs tests on a module.
    #>
    [OutputType([int])]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', '', Scope = 'Function',
        Justification = 'Parameters are used in nested ScriptBlocks'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost', '', Scope = 'Function',
        Justification = 'Want to just write to the console, not the pipeline.'
    )]
    param(
        # Path to the folder where the code to test is located.
        [Parameter(Mandatory)]
        [string] $Path,

        # Path to the folder where the tests are located.
        [Parameter()]
        [string] $TestsPath = 'tests'
    )

    $moduleName = Split-Path -Path $Path -Leaf
    $testSourceCode = $TestType -eq 'SourceCode'
    $testModule = $TestType -eq 'Module'
    $moduleTestsPath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $TestsPath

    if ($testModule) {
        if (Test-Path -Path $moduleTestsPath) {
            LogGroup "Add test - Module - $moduleName" {
                $containerParams = @{
                    Path = $moduleTestsPath
                }
                Write-Host ($containerParams | ConvertTo-Json)
                $containers += New-PesterContainer @containerParams
            }
        } else {
            Write-GitHubWarning "⚠️ No tests found - [$moduleTestsPath]"
        }
    }

    if ((Test-Path -Path $moduleTestsPath) -and $testModule) {
        LogGroup 'Install module dependencies' {
            $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
            Resolve-PSModuleDependency -ManifestFilePath $moduleManifestPath
        }

        LogGroup "Importing module: $moduleName" {
            Add-PSModulePath -Path (Split-Path $Path -Parent)
            $existingModule = Get-Module -Name $ModuleName -ListAvailable
            $existingModule | Remove-Module -Force
            $existingModule.RequiredModules | ForEach-Object { $_ | Remove-Module -Force -ErrorAction SilentlyContinue }
            $existingModule.NestedModules | ForEach-Object { $_ | Remove-Module -Force -ErrorAction SilentlyContinue }
            Import-Module -Name $moduleName -Force -RequiredVersion '999.0.0' -Global
        }
    }

}
