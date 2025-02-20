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
        Write-Host "Removing module [$Name]"
        Get-Module -Name $Name -ListAvailable | Remove-Module -Force
        Get-InstalledPSResource -Name $Name | Uninstall-PSResource -SkipDependencyCheck
    }
}
