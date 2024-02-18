function Invoke-PSCustomTest {
    <#
        .SYNOPSIS
        Invokes the custom tests for the module.

        .DESCRIPTION
        This function will invoke the custom tests for the module.
        The location of the tests is defined by the TestFolderPath parameter.

        .EXAMPLE
        Invoke-PSCustomTests -ModuleFolder 'C:\MyModule\build\MyModule' -TestFolderPath 'C:\MyModule\test\MyModule'
    #>
    [OutputType([int])]
    [Alias('Invoke-PSModuleTests')]
    [CmdletBinding()]
    param(
        # Path to the folder where the built modules are outputted.
        [Parameter(Mandatory)]
        [string] $ModuleFolder,

        # Path to the folder where the built modules are outputted.
        [Parameter(Mandatory)]
        [string] $TestFolderPath
    )

    $containerParams = @{
        Path = $TestFolderPath
        Data = @{
            Path = $ModuleFolder
        }
    }
    Write-Verbose 'ContainerParams:'
    Write-Verbose "$($containerParams | ConvertTo-Json -Depth 5)"


    $pesterParams = @{
        Configuration = @{
            Run        = @{
                Container = New-PesterContainer @containerParams # Can hold an array of Containers
                PassThru  = $false
            }
            TestResult = @{
                TestSuiteName = 'CustomTest'
                OutputPath    = '.\outputs\CustomTest.Results.xml'
                OutputFormat  = 'NUnitXml'
                Enabled       = $true
            }
            Output     = @{
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
