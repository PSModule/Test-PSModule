[CmdletBinding(SupportsShouldProcess)]
param()
$task = New-Object System.Collections.Generic.List[string]
#region Test-Module
$task.Add('Test-Module')
Write-Output "::group::[$($task -join '] - [')] - Starting..."



#region Install-Prerequisites
$task.Add('Install-Prerequisites')
Write-Output "::group::[$($task -join '] - [')]"

$prereqModuleNames = 'Pester', 'PSScriptAnalyzer'
Write-Verbose "[$($task -join '] - [')] - Found $($prereqModuleNames.Count) modules"
$prereqModuleNames | ForEach-Object { Write-Verbose "[$($task -join '] - [')] - [$_]" }

foreach ($prereqModuleName in $prereqModuleNames) {
    $task.Add($prereqModuleName)
    Write-Output "::group::[$($task -join '] - [')]"

    $availableModule = Find-Module -Name $prereqModuleName | Sort-Object -Property Version -Descending | Select-Object -First 1
    $isAvailable = $availableModule.count -gt 0
    Write-Output "::group::[$($task -join '] - [')] - Available - [$isAvailable]"
    $availableModuleVersion = $availableModule.Version
    Write-Output "::group::[$($task -join '] - [')] - Available - Version - [$availableModuleVersion]"

    $installedPrereqModule = Get-Module -ListAvailable -Name $prereqModuleName | Sort-Object -Property Version -Descending | Select-Object -First 1
    $isInstalled = $installedPrereqModule.count -gt 0
    Write-Output "::group::[$($task -join '] - [')] - Installed - [$isInstalled]"
    $installedPrereqModuleVersion = $installedPrereqModule.Version
    Write-Output "::group::[$($task -join '] - [')] - Installed - Version - [$installedPrereqModuleVersion]"

    if ($isInstalled) {
        if ($installedPrereqModuleVersion -lt $availableModuleVersion) {
            Write-Output "::group::[$($task -join '] - [')] - Updating - Version - [$installedPrereqModuleVersion] -> [$availableModuleVersion]"
            Install-Module -Name $prereqModuleName -Scope CurrentUser -Force
        }
    } else {
        Write-Output "::group::[$($task -join '] - [')] - Installing - Version - [$availableModuleVersion]"
        $availableModule | Install-Module -Scope CurrentUser -Force
    }

    $isLoaded = (Get-Module | Where-Object -Property Name -EQ $prereqModuleName).count -gt 0
    if ($isLoaded) {
        Write-Output "::group::[$($task -join '] - [')] - Imported"
    } else {
        Write-Output "::group::[$($task -join '] - [')] - Importing to session"

        try {
            Import-Module -Name $prereqModuleName -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Output "::group::[$($task -join '] - [')] - Done"
    $task.RemoveAt($task.Count - 1)
    Write-Output '::endgroup::'
}

Write-Output "::group::[$($task -join '] - [')] - Done"
Get-InstalledModule | Select-Object Name, Version, Author | Sort-Object -Property Name | Format-Table -AutoSize

$task.RemoveAt($task.Count - 1)
Write-Output '::endgroup::'
#endregion Install-Prerequisites



#region Run-ScriptAnalyzer
$task.Add('Run-ScriptAnalyzer')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Invoke-ScriptAnalyzer"

#Invoke-ScriptAnalyzer -Path .\src\Fonts -Recurse -Verbose

Write-Verbose "[$($task -join '] - [')] - [] - Doing something"
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Run-ScriptAnalyzer



#region Module
$task.Add('Module')
Write-Output "::group::[$($task -join '] - [')]"

#region Pester
$task.Add('Pester')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Do something"
<#
Run tests from ".\tests\$moduleName.Tests.ps1"
# Import the module using Import-Module $moduleManifestFilePath,
# Do not not just add the outputted module file to the PATH of the runner (current context is enough) $env:PATH += ";.\outputs\$moduleName" as the import-module will actually test that the module is importable.
#>
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Pester

Write-Verbose "[$($task -join '] - [')] - [] - Doing something"
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Module



#region Manifest
$task.Add('Manifest')
Write-Output "::group::[$($task -join '] - [')]"

#region Pester
$task.Add('Pester')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Do something"

<#
Run tests from ".\tests\$moduleName.Tests.ps1"
#>

Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Pester

#region Test-ModuleManifest
$task.Add('Test-ModuleManifest')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Do something"

<#
Test-ModuleManifest -Path $Path
#>

Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Test-ModuleManifest

Write-Verbose "[$($task -join '] - [')] - [] - Doing something"
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Manifest



#region Test-Docs
$task.Add('Test-Docs')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Do something"

#region Linter
$task.Add('Linter')
Write-Output "::group::[$($task -join '] - [')]"
Write-Output "::group::[$($task -join '] - [')] - Do something"

<#
Might have to use super-linter instead of this.
#>

Write-Verbose "[$($task -join '] - [')] - [] - Doing something"
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Linter

Write-Verbose "[$($task -join '] - [')] - [] - Doing something"
Write-Output "::group::[$($task -join '] - [')] - Done"
$task.RemoveAt($task.Count - 1)
#endregion Test-Docs



$task.RemoveAt($task.Count - 1)
Write-Output "::group::[$($task -join '] - [')] - Stopping..."
Write-Output '::endgroup::'
#endregion Test-Module
