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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseDeclaredVarsMoreThanAssignments', 'moduleName',
        Justification = 'moduleName is used in the test.'
    )]
    $moduleName = Split-Path -Path $Path -Leaf
}

Describe 'PSModule - Module tests' {
    Context "Module Manifest" {
        BeforeAll {
            $moduleManifestPath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
        }
        It 'Module Manifest exists' {
            Write-Verbose "Module Manifest Path: [$moduleManifestPath]"
            $result = Test-Path -Path $moduleManifestPath
            Write-Verbose $result
            $result | Should -Be $true
        }
        It 'Module Manifest is valid' {
            $result = Test-ModuleManifest -Path $moduleManifestPath
            Write-Verbose $result
            $result | Should -Not -Be $null
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
