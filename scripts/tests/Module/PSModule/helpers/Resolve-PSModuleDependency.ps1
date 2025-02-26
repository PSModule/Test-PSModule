﻿function Resolve-PSModuleDependency {
    <#
        .SYNOPSIS
        Resolve dependencies for a module based on the manifest file.

        .DESCRIPTION
        Resolve dependencies for a module based on the manifest file, following PSModuleInfo structure

        .EXAMPLE
        Resolve-PSModuleDependency -Path 'C:\MyModule\MyModule.psd1'

        Installs all modules defined in the manifest file, following PSModuleInfo structure.

        .NOTES
        Should later be adapted to support both pre-reqs, and dependencies.
        Should later be adapted to take 4 parameters sets: specific version ("requiredVersion" | "GUID"), latest version ModuleVersion,
        and latest version within a range MinimumVersion - MaximumVersion.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost', '', Scope = 'Function',
        Justification = 'Want to just write to the console, not the pipeline.'
    )]
    [CmdletBinding()]
    param(
        # The path to the manifest file.
        [Parameter(Mandatory)]
        [string] $ManifestFilePath
    )

    Write-Host 'Resolving dependencies'

    $manifest = Import-PowerShellDataFile -Path $ManifestFilePath
    Write-Host " - Reading [$ManifestFilePath]"
    Write-Host " - Found [$($manifest.RequiredModules.Count)] modules to install"

    foreach ($requiredModule in $manifest.RequiredModules) {
        $installParams = @{}

        if ($requiredModule -is [string]) {
            $installParams.Name = $requiredModule
        } else {
            $installParams.Name = $requiredModule.ModuleName
            $installParams.MinimumVersion = $requiredModule.ModuleVersion
            $installParams.RequiredVersion = $requiredModule.RequiredVersion
            $installParams.MaximumVersion = $requiredModule.MaximumVersion
        }
        $installParams.Force = $true
        $installParams.Verbose = $false

        $VerbosePreferenceOriginal = $VerbosePreference
        $VerbosePreference = 'SilentlyContinue'
        Write-Host " - [$($installParams.Name)] - Installing module"
        $Count = 5
        $Delay = 10
        for ($i = 0; $i -lt $Count; $i++) {
            try {
                Install-Module @installParams
                break
            } catch {
                Write-Warning 'The command:'
                Write-Warning $Run.ToString()
                Write-Warning "failed with error: $_"
                if ($i -eq $Count - 1) {
                    throw
                }
                Write-Warning "Retrying in $Delay seconds..."
                Start-Sleep -Seconds $Delay
            }
        }
        $VerbosePreference = $VerbosePreferenceOriginal
        Write-Host " - [$($installParams.Name)] - Importing module"
        $VerbosePreferenceOriginal = $VerbosePreference
        $VerbosePreference = 'SilentlyContinue'
        Import-Module @installParams
        $VerbosePreference = $VerbosePreferenceOriginal
        Write-Host " - [$($installParams.Name)] - Done"
    }
    Write-Host ' - Resolving dependencies - Done'
}
