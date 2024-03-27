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
    $moduleName = Split-Path -Path $Path -Leaf
}

Describe 'PSModule - Module tests' {
    Context "Module Manifest" {
        BeforeAll {
            $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
            Write-Verbose "Module Manifest Path: [$moduleManifestPath]"
        }
        It 'Module Manifest exists' {
            Test-Path -Path $moduleManifestPath | Should -Be $true
        }
        It 'Module Manifest is valid' {
            Test-ModuleManifest -Path $moduleManifestPath | Should -Be $null
        }
        # It 'has a valid license URL' {}
        # It 'has a valid project URL' {}
        # It 'has a valid icon URL' {}
        # It 'has a valid help URL' {}
    }
    # Context "Root module file" {
    #     It 'has a root module file' {}
    # }
}
