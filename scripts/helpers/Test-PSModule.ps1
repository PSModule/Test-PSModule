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
        [ValidateSet('SourceCode', 'Module')]
        [string] $TestType = 'SourceCode'
    )

    $moduleName = Split-Path -Path $Path -Leaf
    $testSourceCode = $TestType -eq 'SourceCode'
    $testModule = $TestType -eq 'Module'
    $moduleTestsPath = Join-Path $env:GITHUB_WORKSPACE 'tests'

    #region Get test kit versions
    Start-LogGroup 'Get test kit versions'
    $PSSAModule = Get-PSResource -Name PSScriptAnalyzer -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

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
            Verbose          = $true
        }
    }
    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json)"
    $containers += New-PesterContainer @containerParams
    Stop-LogGroup
    #endregion

    #region Add test - Common - PSModule
    Start-LogGroup 'Add test - Common - PSModule'
    $containerParams = @{
        Path = Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts\tests\PSModule\Common.Tests.ps1'
        Data = @{
            Path    = $Path
            Verbose = $true
        }
    }
    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json)"
    $containers += New-PesterContainer @containerParams
    Stop-LogGroup
    #endregion

    #region Add test - Module - PSModule
    if ($testModule) {
        Start-LogGroup 'Add test - Module - PSModule'
        $containerParams = @{
            Path = Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts\tests\PSModule\Module.Tests.ps1'
            Data = @{
                Path    = $Path
                Verbose = $true
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
        Stop-LogGroup
    }
    #endregion

    #region Add test - SourceCode - PSModule
    if ($testSourceCode) {
        Start-LogGroup 'Add test - SourceCode - PSModule'
        $containerParams = @{
            Path = Join-Path -Path $env:GITHUB_ACTION_PATH -ChildPath 'scripts\tests\PSModule\SourceCode.Tests.ps1'
            Data = @{
                Path    = $Path
                Verbose = $true
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
        Stop-LogGroup
    }
    #endregion

    #region Add test - Module - $moduleName
    if ($testModule) {
        if (Test-Path -Path $moduleTestsPath) {
            Start-LogGroup "Add test - Module - $moduleName"
            $containerParams = @{
                Path = $moduleTestsPath
                Data = @{
                    Path    = $Path
                    Verbose = $true
                }
            }
            Write-Verbose 'ContainerParams:'
            Write-Verbose "$($containerParams | ConvertTo-Json)"
            $containers += New-PesterContainer @containerParams
            Stop-LogGroup
        } else {
            Write-Warning "⚠️ No tests found - [$moduleTestsPath]"
        }
    }
    #endregion

    #region Import module
    if ((Test-Path -Path $moduleTestsPath) -and $testModule) {
        Start-LogGroup "Importing module: $moduleName"
        $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
        Set-ModuleManifest -Path $moduleManifestPath -ModuleVersion '999.0.0'
        Add-PSModulePath -Path (Split-Path $Path -Parent)
        Get-Module -Name $moduleName -ListAvailable | Remove-Module -Force
        Import-Module -Name $moduleName -Force -RequiredVersion '999.0.0' -Global
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
                Enabled       = $testModule
                OutputFormat  = 'NUnitXml'
                OutputPath    = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\Test-Report.xml'
                TestSuiteName = 'Unit tests'
            }
            CodeCoverage = @{
                Enabled               = $testModule
                OutputPath            = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'outputs\CodeCoverage-Report.xml'
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
