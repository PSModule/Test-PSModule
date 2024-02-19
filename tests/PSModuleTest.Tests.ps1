Describe "PSModuleTest.Tests.ps1" {
    It "Should be able to import the module" {
        Import-Module -Name 'PSModuleTest' -Force | Should -Be $true
    }
    It "Should be able to call the function" {
        Test-PSModuleTest -Name 'World' | Should -Be "Hello, World!"
    }
}
