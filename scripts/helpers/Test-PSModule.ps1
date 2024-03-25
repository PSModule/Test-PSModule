#REQUIRES -Modules Utilities, PSScriptAnalyzer, Pester

function Test-PSModule {
    <#
        .SYNOPSIS
        Performs tests on a module.
    #>
    [OutputType([int])]
    [CmdletBinding()]
    param(
        # Path to the folder where the code to test is located.
        [Parameter(Mandatory)]
        [string] $Path,

        # Run module tests.
        [Parameter()]
        [switch] $RunModuleTests
    )

    $moduleName = Split-Path -Path $Path -Leaf

    #region Test Module Manifest
    Start-LogGroup 'Test Module Manifest'
    $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
    if (Test-Path -Path $moduleManifestPath) {
        try {
            Test-ModuleManifest -Path $moduleManifestPath
        } catch {
            Write-Warning "⚠️ Test-ModuleManifest failed: $moduleManifestPath"
            throw $_.Exception.Message
        }
    } else {
        Write-Warning "⚠️ Module manifest not found: $moduleManifestPath"
    }
    Stop-LogGroup
    #endregion

    #region Get test kit versions
    Start-LogGroup 'Get test kit versions'
    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

    Write-Verbose 'Testing with:'
    Write-Verbose "   PowerShell       $($PSVersionTable.PSVersion.ToString())"
    Write-Verbose "   Pester           $($pesterModule.version)"
    Write-Verbose "   PSScriptAnalyzer $($PSSAModule.version)"
    Stop-LogGroup
    #endregion

    #region Add test - Common - PSScriptAnalyzer
    Start-LogGroup 'Add test - Common - PSScriptAnalyzer'
    $containers = @()
    $PSSATestsPath = Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts\tests\PSScriptAnalyzer'
    $containerParams = @{
        Path = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.ps1'
        Data = @{
            Path             = $Path
            SettingsFilePath = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.psd1'
        }
    }
    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json)"
    $containers += New-PesterContainer @containerParams
    Stop-LogGroup
    #endregion

    #region Add test - Common - PSModule
    Start-LogGroup 'Add test - Common - PSModule'
    $PSModuleTestsPath = Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts\tests\PSModule'
    $containerParams = @{
        Path = $PSModuleTestsPath
        Data = @{
            Path = $Path
        }
    }
    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json)"
    $containers += New-PesterContainer @containerParams
    Stop-LogGroup
    #endregion

    #region Add test - Specific - $moduleName
    $moduleTestsPath = Join-Path $env:GITHUB_WORKSPACE 'tests'
    if ((Test-Path -Path $moduleTestsPath) -and $RunModuleTests) {
        Start-LogGroup "Add test - Specific - $moduleName"
        $containerParams = @{
            Path = $moduleTestsPath
            Data = @{
                Path = $Path
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
        Stop-LogGroup
    } else {
        if (-not $RunModuleTests) {
            Write-Warning "⚠️ Module tests are disabled - [$moduleName]"
        } else {
            Write-Warning "⚠️ No tests found - [$moduleTestsPath]"
        }
    }
    #endregion

    #region Import module
    if ((Test-Path -Path $moduleTestsPath) -and $RunModuleTests) {
        Start-LogGroup "Importing module: $moduleName"
        Add-PSModulePath -Path (Split-Path $Path -Parent)
        Get-Module -Name $moduleName -ListAvailable | Remove-Module -Force
        Import-Module -Name $moduleName -Force -RequiredVersion 999.0.0 -Global
        Stop-LogGroup
    }
    #endregion

    #region Pester config
    Start-LogGroup 'Pester config'
    $pesterParams = @{
        Configuration = @{
            Run          = @{
                Path      = $Path
                Container = $containers
                PassThru  = $true
            }
            TestResult   = @{
                Enabled       = $true
                OutputFormat  = 'NUnitXml'
                OutputPath    = '.\outputs\PSModuleTest.Results.xml'
                TestSuiteName = 'PSModule Tests'
            }
            CodeCoverage = @{
                Enabled               = $true
                OutputPath            = '.\outputs\CodeCoverage.xml'
                OutputFormat          = 'JaCoCo'
                OutputEncoding        = 'UTF8'
                CoveragePercentTarget = 75
            }
            Output       = @{
                CIFormat            = 'Auto'
                StackTraceVerbosity = 'None'
                Verbosity           = 'Detailed'
            }
        }
        Verbose       = $false
    }
    Write-Verbose 'PesterParams:'
    Write-Verbose "$($pesterParams | ConvertTo-Json -Depth 4 -WarningAction SilentlyContinue)"
    Stop-LogGroup
    #endregion

    #region Run tests
    Start-LogGroup 'Run tests'
    $verbosepref = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    $results = Invoke-Pester @pesterParams
    $VerbosePreference = $verbosepref
    Write-Verbose 'Done'
    Stop-LogGroup
    #endregion

    $results
}
