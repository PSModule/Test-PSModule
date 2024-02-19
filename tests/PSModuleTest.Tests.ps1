Describe "PSModuleTest.Tests.ps1" {
    It "Should be able to call the function" {
        Test-PSModuleTest | Should -Be "Hello, World!"
    }
}
