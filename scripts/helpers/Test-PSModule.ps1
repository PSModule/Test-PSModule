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
    param(
        # Path to the folder where the code to test is located.
        [Parameter(Mandatory)]
        [string] $Path,

        # Run module tests.
        [Parameter()]
        [ValidateSet('SourceCode', 'Module')]
        [string] $TestType = 'SourceCode',

        # Path to the folder where the tests are located.
        [Parameter()]
        [string] $TestsPath = 'tests',

        # Verbosity level of the stack trace.
        [Parameter()]
        [ValidateSet('None', 'FirstLine', 'Filtered', 'Full')]
        [string] $StackTraceVerbosity = 'Filtered',

        # Verbosity level of the test output.
        [Parameter()]
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string] $Verbosity = 'Detailed'
    )

    $moduleName = Split-Path -Path $Path -Leaf
    $testSourceCode = $TestType -eq 'SourceCode'
    $testModule = $TestType -eq 'Module'
    $moduleTestsPath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath $TestsPath

    LogGroup 'Get test kit versions' {
        $PSSAModule = Get-PSResource -Name PSScriptAnalyzer -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1
        $pesterModule = Get-PSResource -Name Pester -Verbose:$false | Sort-Object Version -Descending | Select-Object -First 1

        Write-Verbose 'Testing with:'
        Write-Verbose "   PowerShell       $($PSVersionTable.PSVersion.ToString())"
        Write-Verbose "   Pester           $($pesterModule.version)"
        Write-Verbose "   PSScriptAnalyzer $($PSSAModule.version)"
    }

    LogGroup 'Add test - Common - PSScriptAnalyzer' {
        $containers = @()
        $PSSATestsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSScriptAnalyzer'
        $settingsFileName = if ($testModule) { 'Settings.Module.psd1' } else { 'Settings.SourceCode.psd1' }
        $settingsFilePath = Join-Path -Path $PSSATestsPath -ChildPath $settingsFileName
        $containerParams = @{
            Path = Join-Path $PSSATestsPath 'PSScriptAnalyzer.Tests.ps1'
            Data = @{
                Path             = $Path
                SettingsFilePath = $settingsFilePath
                Verbose          = $true
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
    }

    LogGroup 'Add test - Common - PSModule' {
        $containerParams = @{
            Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\Common.Tests.ps1'
            Data = @{
                Path    = $Path
                Verbose = $true
            }
        }
        Write-Verbose 'ContainerParams:'
        Write-Verbose "$($containerParams | ConvertTo-Json)"
        $containers += New-PesterContainer @containerParams
    }

    if ($testModule) {
        LogGroup 'Add test - Module - PSModule' {
            $containerParams = @{
                Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\Module.Tests.ps1'
                Data = @{
                    Path    = $Path
                    Verbose = $true
                }
            }
            Write-Verbose 'ContainerParams:'
            Write-Verbose "$($containerParams | ConvertTo-Json)"
            $containers += New-PesterContainer @containerParams
        }
    }

    if ($testSourceCode) {
        LogGroup 'Add test - SourceCode - PSModule' {
            $containerParams = @{
                Path = Join-Path -Path $PSScriptRoot -ChildPath '..\tests\PSModule\SourceCode.Tests.ps1'
                Data = @{
                    Path      = $Path
                    TestsPath = $moduleTestsPath
                    Verbose   = $true
                }
            }
            Write-Verbose 'ContainerParams:'
            Write-Verbose "$($containerParams | ConvertTo-Json)"
            $containers += New-PesterContainer @containerParams
        }
    }

    if ($testModule) {
        if (Test-Path -Path $moduleTestsPath) {
            LogGroup "Add test - Module - $moduleName" {
                $containerParams = @{
                    Path = $moduleTestsPath
                }
                Write-Verbose 'ContainerParams:'
                Write-Verbose "$($containerParams | ConvertTo-Json)"
                $containers += New-PesterContainer @containerParams
            }
        } else {
            Write-Warning "⚠️ No tests found - [$moduleTestsPath]"
        }
    }

    if ((Test-Path -Path $moduleTestsPath) -and $testModule) {
        LogGroup 'Install module dependencies' {
            $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
            Resolve-PSModuleDependency -ManifestFilePath $moduleManifestPath
        }

        LogGroup "Importing module: $moduleName" {
            Add-PSModulePath -Path (Split-Path $Path -Parent)
            Get-Module -Name $moduleName -ListAvailable | Remove-Module -Force
            Import-Module -Name $moduleName -Force -RequiredVersion '999.0.0' -Global
        }
    }

    LogGroup 'Pester config' {
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
                    StackTraceVerbosity = $StackTraceVerbosity
                    Verbosity           = $Verbosity
                }
            }
        }
        Write-Verbose 'PesterParams:'
        Write-Verbose "$($pesterParams | ConvertTo-Json -Depth 4 -WarningAction SilentlyContinue)"
    }

    #region Run tests
    $verbosepref = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    $results = Invoke-Pester @pesterParams
    $VerbosePreference = $verbosepref
    #endregion

    $results
}
