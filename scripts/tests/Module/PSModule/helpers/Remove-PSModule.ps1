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
        Write-Host " - Found [$($importedModule.Count)] modules to remove"
        foreach ($module in $importedModule) {
            Write-Host " - Removing module [$($module.Name)]"
            $module | Remove-Module -Force
        }
        $commands = Get-ChildItem -Path Function: | Where-Object { $_.Source -eq $Name }
        Write-Host " - Found [$($commands.Count)] commands to remove"
        foreach ($command in $commands) {
            Write-Host " - Removing command [$($command.Name)]"
            $command | Remove-Item -Force
        }
        $installedModule = Get-InstalledPSResource -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $Name }
        Write-Host " - Found [$($installedModule.Count)] installed modules to remove"
        foreach ($module in $installedModule) {
            Write-Host " - Uninstalling module [$($module.Name)]"
            $module | Uninstall-PSResource -SkipDependencyCheck
        }
        Get-Command -Module $Name | Format-Table -AutoSize
    }
}
