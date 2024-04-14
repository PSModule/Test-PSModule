Describe 'Module' {
    It 'Function: Get-InternalPSModule' {
        Get-InternalPSModule -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: Set-InternalPSModule' {
        Set-InternalPSModule -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: Get-PSModuleTest' {
        Get-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: New-PSModuleTest' {
        New-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: Set-PSModuleTest' {
        Set-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
    It 'Function: Test-PSModuleTest' {
        Test-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
}
