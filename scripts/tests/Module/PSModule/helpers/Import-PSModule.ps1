function Import-PSModule {
    <#
    .SYNOPSIS
    Imports a build PS module.

    .DESCRIPTION
    Imports a build PS module.

    .EXAMPLE
    Import-PSModule -SourceFolderPath $ModuleFolderPath -ModuleName $ModuleName

    Imports a module located at $ModuleFolderPath with the name $ModuleName.
    #>
    [CmdletBinding()]
    #Requires -Modules Utilities
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost', '', Scope = 'Function',
        Justification = 'Want to just write to the console, not the pipeline.'
    )]
    param(
        # Path to the folder where the module source code is located.
        [Parameter(Mandatory)]
        [string] $Path,

        # Name of the module.
        [Parameter(Mandatory)]
        [string] $ModuleName
    )

    $moduleName = Split-Path -Path $Path -Leaf
    $manifestFileName = "$moduleName.psd1"
    $manifestFilePath = Join-Path -Path $Path $manifestFileName
    $manifestFile = Get-ModuleManifest -Path $manifestFilePath -As FileInfo -Verbose

    Write-Host "Manifest file path: [$($manifestFile.FullName)]" -Verbose
    Remove-PSModule -Name $ModuleName
    Resolve-PSModuleDependency -ManifestFilePath $manifestFile
    Import-Module -Name $ModuleName -RequiredVersion '999.0.0'

    Write-Host 'List loaded modules'
    $availableModules = Get-Module -ListAvailable -Refresh -Verbose:$false
    $availableModules | Select-Object Name, Version, Path | Sort-Object Name | Format-Table -AutoSize
    Write-Host 'List commands'
    Write-Host (Get-Command -Module $moduleName -ListImported | Format-Table -AutoSize | Out-String)

    if ($ModuleName -notin $availableModules.Name) {
        throw 'Module not found'
    }
}
