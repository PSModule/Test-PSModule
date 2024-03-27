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
            Write-Verbose "Module Manifest Path: [$moduleManifestPath]" -Verbose
        }
        It 'Module Manifest exists' {
            $result = Test-Path -Path $moduleManifestPath
            $result | Should -Be $true
            Write-Verbose $result -Verbose
        }
        It 'Module Manifest is valid' {
            $result = Test-ModuleManifest -Path $moduleManifestPath
            $result | Should -Not -Be $null
            Write-Verbose $result -Verbose
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
