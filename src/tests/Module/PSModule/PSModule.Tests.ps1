[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is used to specify the path to the module to test.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Log outputs to GitHub Actions logs.'
)]
[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    $moduleName = Split-Path -Path (Split-Path -Path $Path -Parent) -Leaf
    $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
    $moduleRootPath = Join-Path -Path $Path -ChildPath "$moduleName.psm1"
    Write-Verbose "Module Manifest Path: [$moduleManifestPath]"
    Write-Verbose "Module Root Path: [$moduleRootPath]"

    # Discover public classes and enums from the compiled module source.
    # The class exporter region is injected by Build-PSModule when classes/public contains types.
    $moduleContent = if (Test-Path -Path $moduleRootPath) { Get-Content -Path $moduleRootPath -Raw } else { '' }
    $hasClassExporter = $moduleContent -match '#region\s+Class exporter'

    # Extract expected class and enum names from the class exporter block.
    $expectedClassNames = @()
    $expectedEnumNames = @()
    if ($hasClassExporter) {
        # Match $ExportableClasses = @( ... ) block
        if ($moduleContent -match '\$ExportableClasses\s*=\s*@\(([\s\S]*?)\)') {
            $expectedClassNames = [regex]::Matches($Matches[1], '\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }
        }
        # Match $ExportableEnums = @( ... ) block
        if ($moduleContent -match '\$ExportableEnums\s*=\s*@\(([\s\S]*?)\)') {
            $expectedEnumNames = [regex]::Matches($Matches[1], '\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }
        }
    }
    Write-Host "Has class exporter: $hasClassExporter"
    Write-Host "Expected classes: $($expectedClassNames -join ', ')"
    Write-Host "Expected enums: $($expectedEnumNames -join ', ')"
}

Describe 'PSModule - Module tests' {
    Context 'Module' {
        It 'The module should be importable' {
            { Import-Module -Name $moduleName -Force } | Should -Not -Throw
        }
    }

    Context 'Module Manifest' {
        It 'Module Manifest exists' {
            $result = Test-Path -Path $moduleManifestPath
            $result | Should -Be $true
            Write-Host "$($result | Format-List | Out-String)"
        }
        It 'Module Manifest is valid' {
            $result = Test-ModuleManifest -Path $moduleManifestPath
            $result | Should -Not -Be $null
            Write-Host "$($result | Format-List | Out-String)"
        }
    }

    Context 'Framework - IsWindows compatibility shim' {
        It 'Should have $IsWindows defined in the module scope' {
            # The framework injects "$IsWindows = $true" for PowerShell 5.1 (Desktop edition).
            # On PS 7+ (Core), $IsWindows is a built-in automatic variable.
            # The variable is set inside the module scope and is not exported, so we must check from within the module.
            $isWindowsDefined = & (Get-Module $moduleName) { Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue }
            $isWindowsDefined | Should -Not -BeNullOrEmpty -Because 'the framework injects a compatibility shim for PS 5.1'
        }
    }

    Context 'Framework - Type accelerator registration' -Skip:(-not $hasClassExporter) {
        It 'Should register public enum [<_>] as a type accelerator' -ForEach $expectedEnumNames {
            $registered = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
            $registered.Keys | Should -Contain $_ -Because 'the framework registers public enums as type accelerators'
        }

        It 'Should register public class [<_>] as a type accelerator' -ForEach $expectedClassNames {
            $registered = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
            $registered.Keys | Should -Contain $_ -Because 'the framework registers public classes as type accelerators'
        }
    }

    Context 'Framework - Module OnRemove cleanup' -Skip:(-not $hasClassExporter) {
        It 'Should clean up type accelerators when the module is removed' {
            # Capture type names before removal
            $typeNames = @(@($expectedEnumNames) + @($expectedClassNames) | Where-Object { $_ })
            $typeNames | Should -Not -BeNullOrEmpty -Because 'there should be types to verify cleanup for'

            # Remove the module to trigger the OnRemove hook
            Remove-Module -Name $moduleName -Force

            # Verify type accelerators are cleaned up
            $typeAccelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
            foreach ($typeName in $typeNames) {
                $typeAccelerators.Keys | Should -Not -Contain $typeName -Because "the OnRemove hook should remove type accelerator [$typeName]"
            }

            # Re-import the module for any subsequent tests
            Import-Module -Name $moduleName -Force
        }
    }
}
