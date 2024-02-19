Describe "PSModuleTest.Tests.ps1" {
    It "Should be able to import the module" {
        Import-Module -Name 'PSModuleTest'
        Write-Verbose (Get-Module -Name 'PSModuleTest' | Out-String) -Verbose
        Get-Module -Name 'PSModuleTest' | Should -Not -BeNullOrEmpty
    }
    It "Should be able to call the function" {
        Write-Verbose (Test-PSModuleTest -Name 'World' | Out-String) -Verbose
        Test-PSModuleTest -Name 'World' | Should -Be "Hello, World!"
    }
}
