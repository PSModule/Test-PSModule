function Invoke-PSScriptAnalyzerTest {
    <#
        .SYNOPSIS
        Invokes the PSScriptAnalyzer tests for the module.

        .DESCRIPTION
        This function will invoke the PSScriptAnalyzer tests for the module.

        .EXAMPLE
        Invoke-PSScriptAnalyzerTest -ModuleFolder 'C:\MyModule\

        .NOTES
        The function will use the latest version of PSScriptAnalyzer and Pester available on the system.
    #>
    [OutputType([int])]
    [CmdLetBinding()]
    param(
        # Path to the folder where the built modules are outputted.
        [Parameter(Mandatory)]
        [string] $ModuleFolder
    )

    $modules = Get-Module -ListAvailable
    $PSSAModule = $modules | Where-Object Name -EQ PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
    $pesterModule = $modules | Where-Object Name -EQ Pester | Sort-Object Version -Descending | Select-Object -First 1

    Write-Verbose 'Testing with:' -Verbose
    Write-Verbose "   PowerShell       $($PSVersionTable.PSVersion.ToString())" -Verbose
    Write-Verbose "   Pester           $($pesterModule.version)" -Verbose
    Write-Verbose "   PSScriptAnalyzer $($PSSAModule.version)" -Verbose

    $containerParams = @{
        Path = (Join-Path -Path $PSScriptRoot -ChildPath 'tests' 'PSScriptAnalyzer' 'PSScriptAnalyzer.Tests.ps1')
        Data = @{
            Path             = $ModuleFolder
            SettingsFilePath = (Join-Path -Path $PSScriptRoot -ChildPath 'tests' 'PSScriptAnalyzer' 'PSScriptAnalyzer.Settings.psd1')
        }
    }

    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json -Depth 5)"

    $pesterParams = @{
        Configuration = @{
            Run          = @{
                Container = New-PesterContainer @containerParams
                PassThru  = $false
            }
            TestResult   = @{
                TestSuiteName = 'PSScriptAnalyzer'
                OutputPath    = '.\outputs\PSScriptAnalyzer.Results.xml'
                OutputFormat  = 'NUnitXml'
                Enabled       = $true
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
                Verbosity           = 'Detailed'
                StackTraceVerbosity = 'None'
            }
        }
        ErrorAction   = 'Stop'
    }
    Write-Verbose 'PesterParams:'
    Write-Verbose "$($pesterParams | ConvertTo-Json -Depth 5)"

    Invoke-Pester @pesterParams
    return $LASTEXITCODE
}
