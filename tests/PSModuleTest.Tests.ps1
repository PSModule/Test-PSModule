Describe "PSModuleTest.Tests.ps1" {
    It "Should be able to import the module" {
        Import-Module -Name PSModuleTest -Force | Should -Be $true
    }
    It "Should be able to call the function" {
        $result = Get-PSModuleTest
        $result | Should -Be "Hello, World!"
    }
}
