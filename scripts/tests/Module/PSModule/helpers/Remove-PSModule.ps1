filter Remove-PSModule {
    <#
        .SYNOPSIS
        Removes and uninstalls a PowerShell module.


        .EXAMPLE
        Remove-PSModule -ModuleName 'Utilities'

        Removes a module 'Utilities' from the session then from the system.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost', '', Scope = 'Function',
        Justification = 'Want to just write to the console, not the pipeline.'
    )]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Name of the module.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Name
    )

    if ($PSCmdlet.ShouldProcess('Target', "Remove module [$Name]")) {
        Write-Host "[$Name] - Remove module"
        $importedModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq $Name }
        $commands = Get-ChildItem -Path Function: | Where-Object { $_.Source -eq $Name }
        foreach ($command in $commands) {
            $command | Remove-Item -Force
        }
        foreach ($module in $importedModule) {
            $module | Remove-Module -Force
        }
        $installedModule = Get-InstalledPSResource | Where-Object { $_.Name -eq $Name }
        foreach ($module in $installedModule) {
            $module | Uninstall-PSResource -SkipDependencyCheck
        }
    }
}
