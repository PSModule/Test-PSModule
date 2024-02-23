#REQUIRES -Modules PSScriptAnalyzer, Pester, Utilities

function Test-PSModule {
    <#
        .SYNOPSIS
        Performs tests on a module.
    #>
    [OutputType([int])]
    [CmdletBinding()]
    param(
        # Name of the module to test.
        [Parameter(Mandatory)]
        [string] $Name,

        # Path to the folder where the code to test is located.
        [Parameter(Mandatory)]
        [string] $Path
    )

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

    #region Add test - PSScriptAnalyzer
    Start-LogGroup 'Add test - PSScriptAnalyzer'
    $containers = @()
    $PSSATestsPath = Join-Path $env:GITHUB_ACTION_PATH 'scripts' 'tests' 'PSScriptAnalyzer'
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

    #region Add test - PSModule
    Start-LogGroup 'Add test - PSModule'
    $PSModuleTestsPath = Join-Path $env:GITHUB_ACTION_PATH 'scripts' 'tests' 'PSModule'
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

    #region Add test - Module specific
    $ModuleTestsPath = Join-Path $env:GITHUB_WORKSPACE 'tests'
    if (Test-Path -Path $ModuleTestsPath) {
        Start-LogGroup 'Add test - Module specific'
        $containerParams = @{
            Path = $ModuleTestsPath
            Data = @{
                Path = $Path
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
        Stop-LogGroup
    } else {
        Write-Warning "[$ModuleTestsPath] - No tests found"
    }
    #endregion

    #region Import module
    if (Test-Path -Path $ModuleTestsPath) {
        Start-LogGroup "Importing module: $Name"
        Add-PSModulePath -Path (Split-Path $Path -Parent)
        Import-Module -Name $Name -Force -Verbose
        Get-Command -Module $Name | Select-Object -Property CommandType, Name, Version, Source | Format-Table -AutoSize
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
                PassThru  = $false
            }
            TestResult   = @{
                Enabled       = $true
                OutputFormat  = 'NUnitXml'
                OutputPath    = '.\outputs\PSModuleTest.Results.xml'
                TestSuiteName = 'PSModule Test'
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
    Invoke-Pester @pesterParams
    $failedTests = $LASTEXITCODE
    if ($failedTests -gt 0) {
        Write-Error "[$failedTests] tests failed"
    } else {
        Write-Verbose 'All tests passed'
    }
    Write-Verbose 'Done'
    Stop-LogGroup
    #endregion

    $failedTests
}
