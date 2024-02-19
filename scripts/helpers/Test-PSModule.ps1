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
    $containers = @()

    Install-Dependency -Name PSScriptAnalyzer, Pester

    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

    Write-Host 'Testing with:'
    Write-Host "   PowerShell       $($PSVersionTable.PSVersion.ToString())"
    Write-Host "   Pester           $($pesterModule.version)"
    Write-Host "   PSScriptAnalyzer $($PSSAModule.version)"

    #region Add test - PSScriptAnalyzer
    Start-LogGroup 'Add test - PSScriptAnalyzer'
    $PSSATestsPath = Join-Path $env:GITHUB_ACTION_PATH 'scripts' 'tests' 'PSScriptAnalyzer'
    $containerParams = @{
        Path = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.ps1'
        Data = @{
            Path             = $Path
            SettingsFilePath = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.psd1'
        }
    }
    Write-Host 'ContainerParams:'
    Write-Host "$($containerParams | ConvertTo-Json)"
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
    Write-Host 'ContainerParams:'
    Write-Host "$($containerParams | ConvertTo-Json)"
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
        Write-Host 'ContainerParams:'
        Write-Host "$($containerParams | ConvertTo-Json)"
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
    Write-Host 'PesterParams:'
    Write-Host "$($pesterParams | ConvertTo-Json -Depth 4 -WarningAction SilentlyContinue)"
    Stop-LogGroup
    #endregion

    #region Run tests
    Start-LogGroup 'Run tests'
    Invoke-Pester @pesterParams
    $failedTests = $LASTEXITCODE
    if ($failedTests -gt 0) {
        Write-Error "[$failedTests] tests failed"
    } else {
        Write-Host 'All tests passed'
    }
    Write-Host 'Done'
    Stop-LogGroup
    #endregion

    $failedTests
}
