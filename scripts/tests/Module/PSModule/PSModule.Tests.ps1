[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'Path',
    Justification = 'Path is used to specify the path to the module to test.'
)]
[CmdLetBinding()]
Param(
    [Parameter(Mandatory)]
    [string] $Path
)

BeforeAll {
    $moduleName = Split-Path -Path (Split-Path -Path $Path -Parent) -Leaf
    $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
    Write-Verbose "Module Manifest Path: [$moduleManifestPath]"
}

Describe 'PSModule - Module tests' {
    Context 'Module' {
        It 'The module should be importable' {
            {
                LogGroup 'Importing Module' {
                    Import-Module -Name $moduleName -Force -Verbose -Debug
                } -Verbose -Debug
            } | Should -Not -Throw
        }
    }

    Context 'Module Manifest' {
        It 'Module Manifest exists' {
            LogGroup 'Module manifest' {
                $result = Test-Path -Path $moduleManifestPath
                $result | Should -Be $true
                Write-Verbose $result
            }
        }
        It 'Module Manifest is valid' {
            LogGroup 'Validating Module Manifest' {
                $result = Test-ModuleManifest -Path $moduleManifestPath
                $result | Should -Not -Be $null
                Write-Verbose $result
            }
        }
        # It 'has a valid license URL' {}
        # It 'has a valid project URL' {}
        # It 'has a valid icon URL' {}
        # It 'has a valid help URL' {}
    }
}
