function Test-PSModule {
    <#
        .SYNOPSIS
        Test a module.

        .DESCRIPTION
        Test a module using PSModule tests based on Pester and PSScriptAnalyzer.
        Can also run custom tests defined in a module's tests folder.

        .EXAMPLE
        Test-PSModule -Name 'PSModule.FX' -Path 'outputs'

        Searches the 'outputs' folder for a module named 'PSModule.FX' and runs tests on it.

        .EXAMPLE
    #>
    [OutputType([int])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Name of the module to process.
        [Parameter()]
        [string] $Name = '*',

        # Path to the folder where the built modules are outputted.
        [Parameter()]
        [string] $Path,

        # Path to the folder where the custom tests are located.
        [Parameter()]
        [string] $CustomTestsPath
    )

    Start-LogGroup 'Starting...'

    $moduleFolders = Get-PSModuleFolders -Path $Path | Where-Object { $_.Name -like $Name }
    Write-Verbose "Found $($moduleFolders.Count) module(s) with name like [$Name]"
    $moduleFolders | ForEach-Object {
        Write-Verbose "[$($_.Name)]"
    }
    Stop-LogGroup

    $failedTests = 0
    foreach ($moduleFolder in $moduleFolders) {
        $moduleCustomTestsPath = [string]::IsNullOrEmpty($CustomTestsPath) ? '' : (Join-Path $CustomTestsPath $moduleFolder.Name)
        try {
            $params = @{
                ModuleFolderPath = $moduleFolder.FullName
                CustomTestsPath  = (Test-Path -Path $moduleCustomTestsPath) ? $moduleCustomTestsPath : $null
            }
            $failedTests += Invoke-PSModuleTest @params
        } catch {
            throw "$($_.Exception.Message)"
        }
    }
    $failedTests
}
